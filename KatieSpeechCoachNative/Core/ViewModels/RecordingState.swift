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

    init(
        isRecording: Bool = false,
        recorderStatusLine: String = "Ready to record one real rep on this iPhone.",
        latestScratchRecordingDuration: TimeInterval? = nil,
        currentlyPlayingSessionID: UUID? = nil
    ) {
        self.isRecording = isRecording
        self.recorderStatusLine = recorderStatusLine
        self.latestScratchRecordingDuration = latestScratchRecordingDuration
        self.currentlyPlayingSessionID = currentlyPlayingSessionID
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
}
