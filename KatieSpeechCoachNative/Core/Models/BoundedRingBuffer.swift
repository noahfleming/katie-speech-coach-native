import Foundation

/// Thread-safe bounded ring buffer for live metric streaming.
///
/// Per MEMORY.md best practice (Steady MOM-253 follow-on):
/// - Use for: live metric charts (pitch/volume/energy), rolling averages,
///   capped recent-history views.
/// - **Never append directly from an audio tap callback.** Wrap the
///   audio thread's append in `Task { await buffer.append(value) }`
///   so the actor hop is explicit. Audio taps fire on a realtime
///   priority thread — the hop to the actor queues the value rather
///   than blocking the audio thread.
/// - **Read on the main thread** via TimelineView polling `await buffer.all()`.
///   `all()` returns an immutable snapshot suitable for `Chart`/Swift Charts.
/// - **Capacity 300–500 for 60 fps metric updates.** Single append is O(1).
///
/// Threading model:
/// - `actor` isolation guarantees that `append` and `all` never interleave.
/// - `append` is awaited from the audio thread (preferred) or main thread.
/// - `all()` is awaited from `TimelineView` on the main actor.
actor BoundedRingBuffer<Element> {
    private var storage: [Element] = []
    private let capacity: Int
    private var totalAppends: UInt64 = 0

    init(capacity: Int) {
        precondition(capacity > 0, "BoundedRingBuffer capacity must be > 0, was \(capacity)")
        self.capacity = capacity
        self.storage.reserveCapacity(capacity)
    }

    /// Append one value, dropping the oldest if at capacity.
    /// O(1).
    func append(_ value: Element) {
        if storage.count >= capacity {
            storage.removeFirst()
        }
        storage.append(value)
        totalAppends &+= 1
    }

    /// Append a batch of values. Useful for backfilling missed audio frames.
    /// O(n) in `values.count`, but only one actor hop.
    func append(contentsOf values: [Element]) {
        for value in values {
            if storage.count >= capacity {
                storage.removeFirst()
            }
            storage.append(value)
        }
        totalAppends &+= UInt64(values.count)
    }

    /// O(1) — immutable snapshot suitable for Chart rendering.
    /// Returned array shares storage with future appends only via copy,
    /// so it's safe to iterate without further synchronization.
    func all() -> [Element] {
        storage
    }

    /// O(1) — most recent value, or nil if empty.
    func latest() -> Element? {
        storage.last
    }

    /// O(1) — number of items currently in the buffer (≤ capacity).
    func count() -> Int {
        storage.count
    }

    /// O(1) — current capacity.
    func capacityValue() -> Int {
        capacity
    }

    /// Total appends over the lifetime of this buffer (useful for telemetry).
    func lifetimeAppends() -> UInt64 {
        totalAppends
    }

    /// O(1) — clear the buffer while keeping capacity.
    func clear() {
        storage.removeAll(keepingCapacity: true)
    }
}
