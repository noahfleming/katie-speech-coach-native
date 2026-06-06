import Foundation
import AVFoundation
import Speech

/// Unified audio capture that simultaneously:
/// - Records to a scratch file (for replay)
/// - Streams to a FillerWordDetector for real-time Speech framework analysis
/// - Reports duration in real-time
final class AudioCaptureEngine: ObservableObject {
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isCapturing = false

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var captureStartTime: Date?
    private var durationTimer: Timer?

    var inputNode: AVAudioInputNode? {
        audioEngine?.inputNode
    }

    func startCapture() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        // Scratch file URL for replay
        let url = makeScratchRecordingURL()
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        self.audioFile = file

        // Mix buffer to file (recording) while keeping input available for Speech tap
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            try? self?.audioFile?.write(from: buffer)
        }

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

        return url
    }

    func stopCapture() -> TimeInterval {
        durationTimer?.invalidate()
        durationTimer = nil

        let finalDuration = duration

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        audioFile = nil
        isCapturing = false
        captureStartTime = nil

        return finalDuration
    }

    private func makeScratchRecordingURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
    }
}