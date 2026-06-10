import Foundation
import Speech
import AVFoundation
import Combine

/// Detects filler words (um, uh, like, you know, etc.) in real-time speech using the Speech framework.
final class FillerWordDetector: ObservableObject {
    // MARK: - Configuration

    /// Configurable filler words per language. Default English list covers the most common patterns.
    static let defaultFillerWords: [String: [String]] = [
        "en-US": ["um", "uh", "like", "you know", "basically", "literally", "actually", "honestly", "so", "right"]
    ]

    // MARK: - Published state

    @Published private(set) var sessionFillerWordCount: Int = 0
    @Published private(set) var sessionFillerWordBreakdown: [String: Int] = [:]
    @Published private(set) var lastDetectedFillerWord: String?
    @Published private(set) var isDetecting = false
    @Published private(set) var transcriptSoFar: String = ""

    // MARK: - Private state

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// Last computed per-word counts, so we can tell which word just appeared.
    private var previousBreakdown: [String: Int] = [:]

    private let fillerWords: [String]
    private let locale: Locale

    // MARK: - Init

    init(
        locale: Locale = .current,
        fillerWords: [String]? = nil
    ) {
        self.locale = locale
        self.fillerWords = fillerWords ?? Self.defaultFillerWords[locale.identifier] ?? Self.defaultFillerWords["en-US"]!
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Public API

    /// Begin real-time filler word detection. Audio is delivered separately via
    /// `append(_:)` — the detector does not touch the microphone or install a
    /// tap, so it can share the single capture tap owned by `AudioCaptureEngine`.
    /// Call this when recording starts.
    func startDetecting() throws {
        guard !isDetecting else { return }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw FillerWordDetectorError.recognizerUnavailable
        }

        // Cancel any prior task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Reset session state
        sessionFillerWordCount = 0
        sessionFillerWordBreakdown = [:]
        previousBreakdown = [:]
        lastDetectedFillerWord = nil
        transcriptSoFar = ""

        // Build recognition request for real-time transcription
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw FillerWordDetectorError.requestCreationFailed
        }

        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.transcriptSoFar = text
                self.processTranscript(text)
            }
        }

        isDetecting = true
    }

    /// Feed a captured audio buffer to the recognizer. Called from the single
    /// `AudioCaptureEngine` tap.
    func append(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    /// Stop detection and clean up resources. Call when recording stops.
    func stopDetecting() {
        guard isDetecting else { return }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isDetecting = false
    }

    /// Reset session counters without stopping detection.
    func resetSession() {
        sessionFillerWordCount = 0
        sessionFillerWordBreakdown = [:]
        previousBreakdown = [:]
        lastDetectedFillerWord = nil
        transcriptSoFar = ""
    }

    // MARK: - Private

    /// Recompute filler counts from the full cumulative transcript. The Speech
    /// framework delivers the whole transcript each callback, so the totals are
    /// derived directly from it rather than diffed against a moving baseline
    /// (which is fragile — an earlier version compared the transcript against
    /// itself and never counted anything).
    private func processTranscript(_ transcript: String) {
        var breakdown: [String: Int] = [:]
        var total = 0

        for word in fillerWords {
            let count = countOccurrences(of: word, in: transcript)
            guard count > 0 else { continue }
            breakdown[word] = count
            total += count
        }

        // Surface whichever word just grew since the last callback.
        for word in fillerWords where (breakdown[word] ?? 0) > (previousBreakdown[word] ?? 0) {
            lastDetectedFillerWord = word
        }

        previousBreakdown = breakdown
        sessionFillerWordBreakdown = breakdown
        sessionFillerWordCount = total
    }

    /// Count whole-word occurrences using word boundaries, so "so" does not
    /// match inside "something" and "actually" does not match a longer word.
    /// Handles multi-word fillers ("you know") correctly.
    private func countOccurrences(of word: String, in text: String) -> Int {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word.lowercased()) + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }

        let lowercased = text.lowercased()
        let range = NSRange(lowercased.startIndex..., in: lowercased)
        return regex.numberOfMatches(in: lowercased, options: [], range: range)
    }
}

// MARK: - Errors

enum FillerWordDetectorError: Error, LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available for this locale."
        case .requestCreationFailed:
            return "Could not create speech recognition request."
        case .notAuthorized:
            return "Speech recognition is not authorized."
        }
    }
}

// MARK: - Permission helper

extension FillerWordDetector {
    /// Request speech recognition authorization. Call before startDetecting.
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}