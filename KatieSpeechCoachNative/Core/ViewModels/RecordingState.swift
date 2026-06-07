import Foundation
import AVFoundation
import Combine

/// KAT-206: Recording state extracted from AppViewModel.
///
/// First slice owns the four reactive recording flags (`isRecording`,
/// `recorderStatusLine`, `latestScratchRecordingDuration`,
/// `currentlyPlayingSessionID`). Recording lifecycle methods (`startRecording`,
/// `stopRecording`, `playSession`, `stopPlayback`, `toggleRecording`,
/// `discardScratchRecording`, etc.) intentionally stay on `AppViewModel` for
/// the next careful slice — they reach into audio file URLs, the AudioCaptureEngine,
/// and the scenario histories (for replay lookup), and pulling them out cleanly
/// is a multi-step arc. Moving state first keeps the public API
/// (`appViewModel.isRecording`, `appViewModel.recorderStatusLine`, …) stable
/// and the build green.
final class RecordingState: ObservableObject, Codable {
    @Published var isRecording: Bool
    @Published var recorderStatusLine: String
    @Published var latestScratchRecordingDuration: TimeInterval?
    @Published var currentlyPlayingSessionID: UUID?
    /// File URL of the most recent scratch recording on disk. Not persisted.
    var scratchRecordingURL: URL?

    init(
        isRecording: Bool = false,
        recorderStatusLine: String = "Ready to record one real rep on this iPhone.",
        latestScratchRecordingDuration: TimeInterval? = nil,
        currentlyPlayingSessionID: UUID? = nil,
        scratchRecordingURL: URL? = nil
    ) {
        self.isRecording = isRecording
        self.recorderStatusLine = recorderStatusLine
        self.latestScratchRecordingDuration = latestScratchRecordingDuration
        self.currentlyPlayingSessionID = currentlyPlayingSessionID
        self.scratchRecordingURL = scratchRecordingURL
    }

    private enum CodingKeys: String, CodingKey {
        case isRecording
        case recorderStatusLine
        case latestScratchRecordingDuration
        case currentlyPlayingSessionID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isRecording = try container.decodeIfPresent(Bool.self, forKey: .isRecording) ?? false
        recorderStatusLine = try container.decodeIfPresent(String.self, forKey: .recorderStatusLine) ?? "Ready to record one real rep on this iPhone."
        latestScratchRecordingDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .latestScratchRecordingDuration)
        currentlyPlayingSessionID = try container.decodeIfPresent(UUID.self, forKey: .currentlyPlayingSessionID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isRecording, forKey: .isRecording)
        try container.encode(recorderStatusLine, forKey: .recorderStatusLine)
        try container.encodeIfPresent(latestScratchRecordingDuration, forKey: .latestScratchRecordingDuration)
        try container.encodeIfPresent(currentlyPlayingSessionID, forKey: .currentlyPlayingSessionID)
    }

    // MARK: - State-local mutators (no AVFoundation side effects yet)

    /// Clear the active session pointer. Used when playback finishes or
    /// the user stops it manually.
    func clearActivePlayback() {
        currentlyPlayingSessionID = nil
    }

    /// Update the human-readable status line that the recording card shows.
    func setStatusLine(_ line: String) {
        recorderStatusLine = line
    }

    /// Append a "loaded a starter into the draft" status update.
    func setStarterLoadedStatus(title: String) {
        recorderStatusLine = title
    }

    // MARK: - File storage (per-device, non-persisted)

    /// Directory that holds local on-device recordings (transcript-only
    /// reps are not stored; recorded reps persist in this folder).
    func recordingsDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = documents.appendingPathComponent("KatieRecordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path()) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    /// Build a unique scratch-recording file URL inside the recordings dir.
    func makeScratchRecordingURL() -> URL {
        recordingsDirectory().appendingPathComponent("scratch-\(UUID().uuidString).m4a")
    }

    /// Resolve a stored session's audio file to an on-disk URL (nil if missing
    /// or the file was deleted from under us).
    func audioURL(for session: PracticeSession) -> URL? {
        guard let audioFileName = session.audioFileName else { return nil }
        let url = recordingsDirectory().appendingPathComponent(audioFileName)
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }

    /// True if the session has a backing audio file we can play back.
    func hasPlayback(for session: PracticeSession) -> Bool {
        audioURL(for: session) != nil
    }

    // MARK: - Practice screen status lines (read by AppViewModel)

    /// True if a scratch recording has been captured and not yet saved or discarded.
    var hasScratchRecording: Bool {
        scratchRecordingURL != nil
    }

    /// Remove every file in the recordings directory. Used by
    /// `deleteAllOnDeviceData`.
    func clearAllLocalRecordings() {
        let directory = recordingsDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: - Practice screen status lines (read by AppViewModel)

    /// Truth line for the Practice screen, given the current recording state.
    /// `hasSavedReplay` is whether any prior rep has a backing audio file
    /// (caller supplies the predicate to keep this VM file-URL-free).
    func replayTruthLine(hasSavedReplay: Bool, savedReplayFreshnessLabel: String?) -> String {
        if isRecording {
            return "Local audio is recording on this iPhone now. Release and save when you want replay-ready proof."
        }
        if hasScratchRecording, let latestScratchRecordingDuration {
            return "A \(Int(latestScratchRecordingDuration.rounded())) second scratch clip is waiting on this iPhone. Save it to keep replay attached in Review and Progress."
        }
        if hasSavedReplay, let label = savedReplayFreshnessLabel {
            return "Your latest saved proof can replay here from \(label.lowercased()), but this draft still needs a fresh local clip if you want the next compare to stay listenable."
        }
        return "No fresh local clip is attached to this draft yet. Katie keeps the transcript path visible instead of implying replay exists."
    }

    /// Honesty line about whether saving will attach replay or stay text-only.
    /// `hasSavedReplay` is whether any prior rep has a backing audio file.
    func captureHonestyLine(hasSavedReplay: Bool) -> String {
        if hasScratchRecording {
            return "Save now to keep transcript + local replay together."
        }
        if hasSavedReplay {
            return "You already have saved replay in this pack, but the next compare stays transcript-first until you record again."
        }
        return "First wins still count without audio, but replay only appears after a real on-device recording."
    }
}
