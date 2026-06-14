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
    private var audioEngine: AVAudioEngine?

    private let fillerWords: [String]
    private let locale: Locale

    // MARK: - Init

    init(
        locale: Locale = .current,
        fillerWords: [String]? = nil
    ) {
        self.locale = locale
        let englishFallback = Self.defaultFillerWords["en-US"] ?? ["um", "uh", "like", "you know"]
        self.fillerWords = fillerWords ?? Self.defaultFillerWords[locale.identifier] ?? englishFallback
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Public API

    /// Begin real-time filler word detection on the given audio engine's input node.
    /// Call this when recording starts.
    func startDetecting(from inputNode: AVAudioInputNode) throws {
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
        lastDetectedFillerWord = nil
        transcriptSoFar = ""

        // Build recognition request for real-time transcription
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw FillerWordDetectorError.requestCreationFailed
        }

        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        // Install tap on input node to stream audio to recognition request
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.processTranscript(text)
                self.transcriptSoFar = text
            }

            if error != nil || result?.isFinal == true {
                // Recognition completed or errored — tap stays until stopDetecting
            }
        }

        isDetecting = true
    }

    /// Stop detection and clean up resources. Call when recording stops.
    func stopDetecting() {
        guard isDetecting else { return }

        audioEngine?.stop()
        audioEngine = nil

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
        lastDetectedFillerWord = nil
        transcriptSoFar = ""
    }

    // MARK: - Private

    /// Process transcript text and count new filler words by comparing against prior transcript.
    private func processTranscript(_ newTranscript: String) {
        let priorTranscript = transcriptSoFar

        for word in fillerWords {
            // Count occurrences of this filler word in the new transcript portion
            let priorCount = countOccurrences(of: word, in: priorTranscript)
            let newCount = countOccurrences(of: word, in: newTranscript)

            if newCount > priorCount {
                let delta = newCount - priorCount
                sessionFillerWordCount += delta
                sessionFillerWordBreakdown[word, default: 0] += delta
                lastDetectedFillerWord = word
            }
        }
    }

    private func countOccurrences(of word: String, in text: String) -> Int {
        let escapedTokens = word
            .split(whereSeparator: \.isWhitespace)
            .map { NSRegularExpression.escapedPattern(for: String($0)) }
        guard !escapedTokens.isEmpty else { return 0 }

        let pattern = "(?<![\\p{L}\\p{N}_])\(escapedTokens.joined(separator: "\\s+"))(?![\\p{L}\\p{N}_])"
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return 0
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.numberOfMatches(in: text, range: range)
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
