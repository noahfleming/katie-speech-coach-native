import Foundation
import Speech
import AVFoundation
import Combine

/// Detects filler words (um, uh, like, you know, etc.) in real-time speech during
/// practice sessions, and surfaces a running session total plus per-word breakdown.
///
/// Hybrid transcription strategy:
/// - **iOS 26+** primary path uses `SpeechAnalyzer` + `SpeechTranscriber`. This gives
///   long-form support (no 1-minute buffer cap that plagued `SFSpeechRecognizer`),
///   lower first-audio latency via `prepareToAnalyze(in:)`, and full on-device
///   transcription. Vocabulary bias (`contextualStrings`) is not yet exposed by
///   the new framework, so filler accuracy on this path relies on the underlying
///   model's general English coverage.
/// - **iOS 17–25** fallback path keeps `SFSpeechRecognizer` +
///   `SFSpeechAudioBufferRecognitionRequest`. This is the only OS-level path that
///   still offers `contextualStrings` for vocabulary bias toward filler words.
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

    // MARK: - Private state — legacy (SFSpeechRecognizer, iOS 17–25)

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Private state — iOS 26+ (SpeechAnalyzer)

    /// Strong reference to the iOS 26+ analyzer session. Held as `AnyObject?` so the
    /// outer class remains compilable on the iOS 17 deployment target — the concrete
    /// `AnalyzerSession` type is `@available(iOS 26.0, *)` and only resolved inside
    /// `#available` branches.
    private var analyzerSession: AnyObject?

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

    /// Begin real-time filler word detection on the given audio engine's input node.
    /// Call this when recording starts.
    func startDetecting(from inputNode: AVAudioInputNode) throws {
        guard !isDetecting else { return }

        // Tear down any prior session before starting a new one.
        cancelInFlightSession()

        // Reset session state.
        sessionFillerWordCount = 0
        sessionFillerWordBreakdown = [:]
        lastDetectedFillerWord = nil
        transcriptSoFar = ""

        if #available(iOS 26.0, *) {
            try startAnalyzerPath(from: inputNode)
        } else {
            try startLegacyPath(from: inputNode)
        }

        isDetecting = true
    }

    /// Stop detection and clean up resources. Call when recording stops.
    func stopDetecting() {
        guard isDetecting else { return }
        cancelInFlightSession()
        isDetecting = false
    }

    /// Reset session counters without stopping detection.
    func resetSession() {
        sessionFillerWordCount = 0
        sessionFillerWordBreakdown = [:]
        lastDetectedFillerWord = nil
        transcriptSoFar = ""
    }

    // MARK: - Private — teardown

    private func cancelInFlightSession() {
        // Legacy teardown.
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // iOS 26+ teardown.
        if #available(iOS 26.0, *), let session = analyzerSession as? AnalyzerSession {
            session.stop()
            analyzerSession = nil
        }
    }

    // MARK: - Private — legacy path (iOS 17–25)

    private func startLegacyPath(from inputNode: AVAudioInputNode) throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw FillerWordDetectorError.recognizerUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw FillerWordDetectorError.requestCreationFailed
        }

        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        // Vocabulary bias toward filler words — only available on the legacy framework.
        request.contextualStrings = fillerWords

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.transcriptSoFar = text
                self.processTranscript(text)
            }

            if error != nil || result?.isFinal == true {
                // Tap stays installed until stopDetecting runs.
            }
        }
    }

    // MARK: - Private — iOS 26+ path (SpeechAnalyzer)

    @available(iOS 26.0, *)
    private func startAnalyzerPath(from inputNode: AVAudioInputNode) throws {
        let session = AnalyzerSession(locale: locale)
        try session.start(from: inputNode) { [weak self] text in
            // Bridge the analyzer's async results back onto the main actor so the
            // @Published state mutations land on the right thread for SwiftUI.
            self?.transcriptSoFar = text
            self?.processTranscript(text)
        }
        self.analyzerSession = session
    }

    // MARK: - Private — transcript processing

    /// Process transcript text and count new filler words by comparing against prior transcript.
    private func processTranscript(_ newTranscript: String) {
        let priorTranscript = transcriptSoFar

        for word in fillerWords {
            // Count occurrences of this filler word in the new transcript portion.
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
        let lowercased = text.lowercased()
        var count = 0
        var searchRange = lowercased.startIndex..<lowercased.endIndex

        while let range = lowercased.range(of: word.lowercased(), range: searchRange) {
            count += 1
            searchRange = range.upperBound..<lowercased.endIndex
        }

        return count
    }
}

// MARK: - iOS 26+ analyzer session

/// Encapsulates the iOS 26+ `SpeechAnalyzer` + `SpeechTranscriber` pipeline so all
/// references to those iOS 26-only types live inside one `@available`-gated class.
/// The outer `FillerWordDetector` only ever sees this through an `AnyObject?`.
@available(iOS 26.0, *)
private final class AnalyzerSession {
    private let transcriber: SpeechTranscriber
    private let analyzer: SpeechAnalyzer
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var task: Task<Void, Never>?

    init(locale: Locale) {
        self.transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        self.analyzer = SpeechAnalyzer(modules: [transcriber])
    }

    func start(
        from inputNode: AVAudioInputNode,
        onResult: @escaping (String) -> Void
    ) throws {
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // AsyncStream of audio frames for the analyzer to consume.
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream(
            of: AnalyzerInput.self,
            bufferingPolicy: .unbounded
        )
        self.inputContinuation = continuation

        // Tap the input node and yield each PCM buffer into the analyzer stream.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.inputContinuation?.yield(AnalyzerInput(buffer: buffer))
        }

        let analyzer = self.analyzer
        let transcriber = self.transcriber
        task = Task {
            do {
                // Prewarm the analyzer with the actual audio format before the first frame.
                try await analyzer.prepareToAnalyze(in: recordingFormat)
                try await analyzer.start(inputSequence: stream)

                for try await result in transcriber.results {
                    if Task.isCancelled { break }
                    let text = String(result.text.characters)
                    await MainActor.run {
                        onResult(text)
                    }
                }
            } catch is CancellationError {
                // Normal teardown — ignore.
            } catch {
                NSLog("FillerWordDetector SpeechAnalyzer error: %@", String(describing: error))
            }
        }
    }

    func stop() {
        inputContinuation?.finish()
        inputContinuation = nil
        task?.cancel()
        task = nil
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
    /// Request speech recognition authorization. Call before `startDetecting`.
    /// Both `SFSpeechRecognizer` and `SpeechAnalyzer` share the same
    /// `NSSpeechRecognitionUsageDescription` privacy surface, so the legacy
    /// authorization request covers both paths.
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}