import SwiftUI

struct InterviewPracticeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: InterviewCategory = .aboutYou
    @State private var currentQuestionIndex: Int = 0
    @State private var isAnswering = false
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?
    @State private var recordedSessions: [RecordedAnswer] = []
    @State private var showingFeedback = false

    private let timerDuration: Int = 120 // 2 minutes per question

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categorySelector
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                if isAnswering {
                    questionView
                } else if showingFeedback {
                    feedbackView
                } else {
                    prepView
                }
            }
            .background(KatieColors.appBackgroundTop)
            .navigationTitle("Interview mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        cleanupInterviewSession()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                cleanupInterviewSession()
            }
        }
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(InterviewCategory.allCases) { category in
                    KatieChip(
                        title: category.title,
                        isSelected: selectedCategory == category,
                        accent: KatieColors.gold
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            cleanupInterviewSession()
                            selectedCategory = category
                            currentQuestionIndex = 0
                            recordedSessions = []
                            showingFeedback = false
                            isAnswering = false
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Prep View

    private var prepView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(KatieColors.gold)

            VStack(spacing: 8) {
                Text(categoryTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text(categoryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                prepRow(icon: "clock.fill", text: "\(selectedCategory.questions.count) questions")
                prepRow(icon: "timer", text: "\(timerDuration / 60) min per answer")
                prepRow(icon: "text.alignleft", text: "Filler words tracked")
                prepRow(icon: "star.fill", text: "Clarity + coherence feedback")
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)

            Spacer()

            Button {
                startAnswering()
            } label: {
                Label("Begin practice", systemImage: "mic.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KatieColors.gold)
                    .foregroundStyle(KatieColors.textOnAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func prepRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.gold)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            // Timer bar
            GeometryReader { geometry in
                let progress = max(0, CGFloat(timeRemaining) / CGFloat(timerDuration))
                Rectangle()
                    .fill(KatieColors.gold)
                    .frame(width: geometry.size.width * progress, height: 3)
                    .animation(.linear(duration: 1), value: timeRemaining)
            }
            .frame(height: 3)

            // Progress
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(selectedCategory.questions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(timeRemaining < 30 ? KatieColors.blush : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 20) {
                Text(currentQuestion)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)

                if appViewModel.isPreparingRecording {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.badge.plus")
                            .font(.caption.weight(.semibold))
                        Text("Preparing microphone")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(KatieColors.gold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(KatieColors.gold.opacity(0.12), in: Capsule())
                } else if appViewModel.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(KatieColors.blush)
                            .frame(width: 10, height: 10)
                        Text("Recording")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.blush)

                        if appViewModel.fillerWordCount > 0 {
                            Text("· \(appViewModel.fillerWordCount) filler word\(appViewModel.fillerWordCount == 1 ? "" : "s")")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.gold)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(KatieColors.blush.opacity(0.12), in: Capsule())
                }
            }

            Spacer()

            // Recording controls
            VStack(spacing: 16) {
                if appViewModel.isPreparingRecording {
                    VStack(spacing: 6) {
                        SwiftUI.ProgressView()
                            .tint(KatieColors.gold)
                        Text("Opening mic")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 92, height: 92)
                    .padding(.bottom, 8)
                } else if !appViewModel.isRecording {
                    Button {
                        appViewModel.startRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(KatieColors.gold)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(KatieColors.blush)
                                .frame(width: 56, height: 56)
                        }
                    }
                    .padding(.bottom, 8)
                } else {
                    Button {
                        stopAndSave()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 72, height: 72)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                            }
                            Text("Done")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Feedback View

    private var feedbackView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Session complete")
                    .font(.title3.weight(.bold))
                    .padding(.top, 24)

                ForEach(Array(recordedSessions.enumerated()), id: \.element.id) { index, answer in
                    interviewFeedbackCard(answer: answer, questionNumber: index + 1)
                }

                Button {
                    // Restart
                    recordedSessions = []
                    currentQuestionIndex = 0
                    showingFeedback = false
                    isAnswering = false
                } label: {
                    Text("Practice again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KatieColors.gold)
                        .foregroundStyle(KatieColors.textOnAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func interviewFeedbackCard(answer: RecordedAnswer, questionNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Q\(questionNumber): \(answer.question)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let score = answer.clarityScore {
                    KatieScoreBadge(score: score, label: "clarity")
                }
            }

            Text(answer.transcript)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            HStack(spacing: 16) {
                if answer.fillerWordCount > 0 {
                    Label("\(answer.fillerWordCount) filler", systemImage: "text.bubble.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.gold)
                }

                Label(answer.formattedDuration, systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var currentQuestion: String {
        guard currentQuestionIndex < selectedCategory.questions.count else {
            return "All questions complete!"
        }
        return selectedCategory.questions[currentQuestionIndex]
    }

    private var categoryTitle: String {
        selectedCategory.title
    }

    private var categoryDescription: String {
        selectedCategory.description
    }

    private func startAnswering() {
        currentQuestionIndex = 0
        recordedSessions = []
        isAnswering = true
        showQuestion()
    }

    private func showQuestion() {
        timeRemaining = timerDuration
        stopQuestionTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    stopQuestionTimer()
                    // Auto-stop recording when time runs out
                    if appViewModel.isRecording {
                        stopAndSave()
                    }
                }
            }
        }
        // Auto-start recording
        appViewModel.startRecording()
    }

    private func stopAndSave() {
        appViewModel.stopRecording()
        let answerTranscript = appViewModel.draftTranscript
        let answerFillerWordCount = appViewModel.fillerWordCount
        let answerDuration = appViewModel.latestScratchRecordingDuration ?? 0

        let answer = RecordedAnswer(
            question: currentQuestion,
            transcript: answerTranscript,
            fillerWordCount: answerFillerWordCount,
            duration: answerDuration,
            clarityScore: nil // Would be filled by AI analysis
        )

        recordedSessions.append(answer)
        appViewModel.discardScratchRecording(
            statusLine: "Interview answer saved for this practice session.",
            clearDraft: true,
            playWarningHaptic: false
        )

        stopQuestionTimer()

        if currentQuestionIndex + 1 < selectedCategory.questions.count {
            currentQuestionIndex += 1
            showQuestion()
        } else {
            // All done
            isAnswering = false
            showingFeedback = true
        }
    }

    private func stopQuestionTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func cleanupInterviewSession() {
        stopQuestionTimer()
        guard isAnswering || appViewModel.isRecording || appViewModel.isPreparingRecording else { return }

        appViewModel.discardScratchRecording(
            statusLine: "Interview practice stopped. No scratch recording was kept.",
            clearDraft: true,
            playWarningHaptic: false
        )
        isAnswering = false
    }
}

// MARK: - Supporting Types

struct RecordedAnswer: Identifiable {
    let id = UUID()
    let question: String
    let transcript: String
    let fillerWordCount: Int
    let duration: TimeInterval
    let clarityScore: Int?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

enum InterviewCategory: String, CaseIterable, Identifiable {
    case aboutYou
    case behavioral
    case situational
    case technical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aboutYou: return "About you"
        case .behavioral: return "Behavioral"
        case .situational: return "Situational"
        case .technical: return "Technical"
        }
    }

    var description: String {
        switch self {
        case .aboutYou:
            return "Tell me about yourself, your background, and why you're here."
        case .behavioral:
            return "Use the STAR method to structure your answers to past experience questions."
        case .situational:
            return "Handle real-world hypotheticals with clear, structured responses."
        case .technical:
            return "Break down complex concepts clearly for a general audience."
        }
    }

    var questions: [String] {
        switch self {
        case .aboutYou:
            return [
                "Tell me about yourself — who you are, what you do, and what brought you here.",
                "What's the most important thing you'd want someone to know about your work style?",
                "Where do you see yourself in five years, and how does this role fit?",
                "What's a professional strength you're proud of, and what's a weakness you're working on?"
            ]
        case .behavioral:
            return [
                "Tell me about a time you had to navigate a difficult conversation at work.",
                "Describe a moment when you received critical feedback. How did you respond?",
                "Walk me through a project that didn't go as planned. What did you learn?",
                "Tell me about a time you had to convince a skeptical team to try something new.",
                "Describe a situation where you had to prioritize multiple urgent things at once."
            ]
        case .situational:
            return [
                "Your manager asks you to deliver something impossible by end of day. What do you do?",
                "Two team members are in conflict and it's affecting the work. How do you handle it?",
                "You discover a significant mistake in work you already shipped. Walk me through your response.",
                "Your project is falling behind schedule. What's your first move?",
                "You disagree with a technical decision your team is making. How do you approach it?"
            ]
        case .technical:
            return [
                "Explain a complex technical concept to someone without a technical background.",
                "Describe how you would approach debugging a system you've never seen before.",
                "Walk me through how you would design a system to handle scale from 100 to 1 million users.",
                "Explain a trade-off you had to make in a recent project and how you evaluated your options."
            ]
        }
    }
}

// KatieTheme and KatieColors are defined in Core/DesignSystem/KatieTheme.swift

#Preview {
    InterviewPracticeView()
        .preferredColorScheme(.dark)
}
// MARK: - Local Helper Views

fileprivate struct KatieChip: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? accent.opacity(0.18)
                        : Color.white.opacity(0.06)
                )
                .foregroundStyle(isSelected ? accent : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? accent.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

fileprivate struct KatieScoreBadge: View {
    let score: Int
    let label: String

    private var color: Color {
        switch score {
        case 8...10: return .green
        case 5..<8: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(score)")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}
