import Foundation
import Combine

/// KAT-206: Filler-word detection state extracted from AppViewModel.
///
/// Owns the two reactive flags that mirror the `FillerWordDetector` stream:
/// `fillerWordCount` (total count for the active session) and
/// `fillerWordBreakdown` (per-filler tally used by the live feedback UI).
///
/// The `FillerWordDetector` service itself already lives at
/// `Core/Services/FillerWordDetector.swift` — this is just the surface for
/// surfacing its output to views. Wiring up the detector from the recording
/// lifecycle is the next careful slice.
final class FillerState: ObservableObject, Codable {
    @Published var fillerWordCount: Int
    @Published var fillerWordBreakdown: [String: Int]

    init(
        fillerWordCount: Int = 0,
        fillerWordBreakdown: [String: Int] = [:]
    ) {
        self.fillerWordCount = fillerWordCount
        self.fillerWordBreakdown = fillerWordBreakdown
    }

    private enum CodingKeys: String, CodingKey {
        case fillerWordCount
        case fillerWordBreakdown
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fillerWordCount = try container.decodeIfPresent(Int.self, forKey: .fillerWordCount) ?? 0
        fillerWordBreakdown = try container.decodeIfPresent([String: Int].self, forKey: .fillerWordBreakdown) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fillerWordCount, forKey: .fillerWordCount)
        try container.encode(fillerWordBreakdown, forKey: .fillerWordBreakdown)
    }

    // MARK: - Mutators

    func reset() {
        fillerWordCount = 0
        fillerWordBreakdown = [:]
    }
}
