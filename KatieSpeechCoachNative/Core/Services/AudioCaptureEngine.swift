import Foundation
import AVFoundation
import Speech

/// Single audio authority for a recording session. One `AVAudioEngine` with one
/// tap on the input node that simultaneously:
/// - Records to a scratch `.m4a` file (for replay)
/// - Forwards every buffer to an optional handler (for live Speech analysis)
/// - Reports duration in real-time
///
/// This is the *only* object that touches the microphone or the
/// `AVAudioSession` during a take, so there is exactly one session activation
/// and one tap — no competing `AVAudioRecorder`, no second tap.
final class AudioCaptureEngine: ObservableObject {
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isCapturing = false

    /// Set if a buffer write to the scratch file failed (e.g. disk full). The
    /// caller can surface this instead of shipping a silently truncated file.
    private(set) var lastWriteError: Error?

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var captureStartTime: Date?
    private var durationTimer: Timer?
    private var bufferHandler: ((AVAudioPCMBuffer) -> Void)?
    private var onInterruption: (() -> Void)?
    private var interruptionObserver: NSObjectProtocol?

    /// Start capturing.
    /// - Parameters:
    ///   - onBuffer: Receives every captured buffer (for live recognition).
    ///   - onInterruption: Fires when the session is interrupted (phone call,
    ///     Siri) so the caller can stop the take cleanly instead of letting the
    ///     duration timer run on against dead audio.
    /// - Returns: The scratch file URL the take is being written to.
    func startCapture(
        onBuffer: ((AVAudioPCMBuffer) -> Void)? = nil,
        onInterruption: (() -> Void)? = nil
    ) throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let input = engine.inputNode

        // Prepare the engine before reading the input format. On some routes
        // (e.g. a Bluetooth HFP headset that is still connecting) the format is
        // not finalised until prepare(), and an unfinalised format can report
        // 0 channels — which would make AVAudioFile/installTap throw with no
        // useful diagnostic. Guard explicitly so the failure is legible.
        engine.prepare()
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            throw AudioCaptureEngineError.invalidInputFormat
        }

        // Write AAC m4a so the scratch file matches what the rest of the app
        // replays via AVAudioPlayer. The file's processing format is PCM at the
        // input's sample rate/channel count, so the tap buffers write directly.
        let url = makeScratchRecordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        self.audioFile = file
        self.bufferHandler = onBuffer
        self.onInterruption = onInterruption
        self.lastWriteError = nil

        // Single tap: write to file AND forward the buffer for recognition.
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                // Capture the first write error rather than swallowing it; the
                // caller can decide whether to discard the take.
                if self.lastWriteError == nil {
                    self.lastWriteError = error
                }
            }
            self.bufferHandler?(buffer)
        }

        registerInterruptionObserver(on: session)

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
        bufferHandler = nil
        onInterruption = nil
        isCapturing = false
        captureStartTime = nil

        removeInterruptionObserver()

        // Release the session so other apps (Music, phone) can reclaim the mic.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return finalDuration
    }

    // MARK: - Interruptions

    private func registerInterruptionObserver(on session: AVAudioSession) {
        removeInterruptionObserver()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let info = notification.userInfo,
                let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                AVAudioSession.InterruptionType(rawValue: raw) == .began
            else { return }
            // An interruption (call/Siri) stops audio delivery. Hand control
            // back to the caller so it can stop the take instead of letting the
            // duration timer run on against silence.
            self.onInterruption?()
        }
    }

    private func removeInterruptionObserver() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        interruptionObserver = nil
    }

    private func makeScratchRecordingURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
    }
}

// MARK: - Errors

enum AudioCaptureEngineError: Error, LocalizedError {
    case invalidInputFormat

    var errorDescription: String? {
        switch self {
        case .invalidInputFormat:
            return "The microphone input format was unavailable. Try again once the audio route settles."
        }
    }
}
