import Foundation
import AVFoundation
import Speech

/// Drives live microphone input for Speech analysis while AVAudioRecorder owns replay capture.
/// Also reports duration in real time for UI and saved-session metadata.
final class AudioCaptureEngine: ObservableObject {
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isCapturing = false

    private var audioEngine: AVAudioEngine?
    private var captureStartTime: Date?
    private var durationTimer: Timer?

    var inputNode: AVAudioInputNode? {
        audioEngine?.inputNode
    }

    func startCapture(configureInput: ((AVAudioInputNode) throws -> Void)? = nil) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let input = engine.inputNode
        try configureInput?(input)

        try engine.start()
        self.audioEngine = engine
        self.captureStartTime = Date()
        self.isCapturing = true

        // Timer-based duration updates (avoids lock/step issues)
        self.durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let start = self?.captureStartTime else { return }
            DispatchQueue.main.async {
                self?.duration = Date().timeIntervalSince(start)
            }
        }

    }

    func stopCapture() -> TimeInterval {
        durationTimer?.invalidate()
        durationTimer = nil

        let finalDuration = duration

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        isCapturing = false
        captureStartTime = nil

        return finalDuration
    }
}
