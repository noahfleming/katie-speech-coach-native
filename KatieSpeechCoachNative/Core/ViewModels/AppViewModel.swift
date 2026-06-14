import Foundation
import AVFoundation
import UserNotifications
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct PremiumRestoreMessage: Equatable {
    enum Tone {
        case success
        case neutral
        case warning
    }

    let title: String
    let body: String
    let tone: Tone
}

struct PracticeReturnCue: Equatable {
    let title: String
    let body: String
}

struct ReminderFlowMessage: Equatable {
    let title: String
    let body: String
}

enum QuickRepRunwayAccent: Equatable {
    case gold
    case accent
    case mint
}

struct QuickRepRunwayStepDescriptor: Identifiable, Equatable {
    let title: String
    let detail: String
    let systemImage: String
    let accent: QuickRepRunwayAccent

    var id: String { title }
}

struct AudioCaptureLane: Equatable {
    let title: String
    let detail: String
    let systemImage: String
    let actionTitle: String
}

struct PremiumExperimentSurface: Identifiable, Equatable {
    let title: String
    let badge: String
    let detail: String
    let bullets: [String]

    var id: String { title }
}

enum FirstWinPrimaryAction {
    case recordBaseline
    case saveTextBaseline
    case openLatestProof
    case enableReminder
    case openNotificationSettings
    case practiceNextRep
}

private enum KatieHaptic {
    case selection
    case softImpact
    case success
    case warning

    func play() {
        #if canImport(UIKit)
        switch self {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .softImpact:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    enum AppTab: String, Codable, Hashable {
        case today, practice, progress, coach
    }

    private static let persistenceKey = "katie.native.persisted-state.v1"
    private static let reminderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · h:mm a"
        return formatter
    }()
    private static let pocketCopyFilenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()

    @Published var hasCompletedOnboarding = false
    @Published private(set) var hasDismissedFirstBaselineGate = false
    @Published var selectedTab: AppTab = .today
    @Published var learnerProfile = LearnerProfile()
    @Published var currentMission: PracticeScenario = .weeklyUpdate
    @Published var availableScenarios: [PracticeScenario] = PracticeScenario.allCases
    @Published var premiumAccessState: PremiumAccessState = .locked
    @Published private(set) var premiumStoreStatus: PremiumStoreStatus = .idle
    @Published private(set) var reminderPlan: ReminderPlan?
    @Published private(set) var reminderPermissionState: ReminderPermissionState = .unknown
    @Published private(set) var microphonePermissionState: MicrophonePermissionState = .unknown
    @Published private(set) var scenarioHistories: [PracticeScenario: [PracticeSession]] = [:]
    @Published private var selectedAnchorByScenario: [PracticeScenario: UUID] = [:]
    @Published private(set) var isRecording = false
    @Published private(set) var isPreparingRecording = false
    @Published var draftTranscript = ""
    @Published var draftReflectionListenerCatchScore = 3
    @Published var draftReflectionPaceControlScore = 3
    @Published var draftReflectionConfidenceScore = 3
    @Published var draftReflectionStickyMoment = "Opening line"
    @Published private(set) var activePracticeStep = 0
    @Published private(set) var recorderStatusLine = "Ready to record one real rep on this iPhone."
    @Published private(set) var latestScratchRecordingDuration: TimeInterval?
    @Published private(set) var currentlyPlayingSessionID: UUID?
    @Published var isPremiumPreviewPresented = false
    @Published var isReviewPresented = false
    /// Shared sheet state for the structured interview mode view. Both the Coach
    /// tab CTA and the Practice tab's "Try interview mode" cross-link flip this
    /// to true; RootView listens and presents the sheet.
    @Published var isInterviewModePresented = false
    @Published var reminderTone: ReminderTone = .workday
    @Published private(set) var premiumRestoreMessage: PremiumRestoreMessage?
    @Published private(set) var pocketCopyStatusLine: String?
    @Published private(set) var practiceReturnCue: PracticeReturnCue?
    @Published private(set) var reminderFlowMessage: ReminderFlowMessage?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var reminderNotificationObserver: NSObjectProtocol?
    private var scratchRecordingURL: URL?
    private var fillerWordDetector: FillerWordDetector?
    private var audioCaptureEngine: AudioCaptureEngine?
    private var fillerCountCancellable: AnyCancellable?
    private var fillerBreakdownCancellable: AnyCancellable?
    private var recordingStartRequestID: UUID?

    @Published var fillerWordCount: Int = 0
    @Published var fillerWordBreakdown: [String: Int] = [:]
    private let premiumStore: PremiumStore

    init(premiumStore: PremiumStore? = nil) {
        self.premiumStore = premiumStore ?? PremiumStore.shared
        if !restorePersistedState() {
            scenarioHistories = Self.buildScenarioHistories()
            currentMission = .weeklyUpdate
        }
        ensureAnchorSelection(for: currentMission)
        prepareDraftReflection()
        refreshReminderPermissionState()
        observeReminderNotificationTaps()
        refreshMicrophonePermissionState()
        syncPremiumStoreStatus()

        Task {
            await preparePremiumStore()
        }
    }

    deinit {
        if let reminderNotificationObserver {
            NotificationCenter.default.removeObserver(reminderNotificationObserver)
        }
    }

    var isPremiumUnlocked: Bool {
        premiumAccessState.allowsPremiumExperience
    }

    var remindersEnabled: Bool {
        reminderPlan?.scenario == currentMission
    }

    var reminderDraftDate: Date {
        reminderPlan?.fireDate ?? Self.defaultReminderDate(from: .now)
    }

    var reminderDraftTimeLabel: String {
        Self.reminderFormatter.string(from: reminderDraftDate)
    }

    var reminderQuickPresets: [ReminderQuickPreset] {
        [
            ReminderQuickPreset(title: "In 2 hours", fireDate: reminderDate(hoursFromNow: 2)),
            ReminderQuickPreset(title: "Tomorrow 9 AM", fireDate: reminderDateTomorrow(hour: 9, minute: 0)),
            ReminderQuickPreset(title: "Next workday 9 AM", fireDate: reminderDateNextWorkday(hour: 9, minute: 0))
        ]
    }

    var localReplayCount: Int {
        scenarioHistories.values
            .flatMap { $0 }
            .filter { hasPlayback(for: $0) }
            .count
    }

    var recordedHistoryCount: Int {
        scenarioHistories.values
            .flatMap { $0 }
            .filter { $0.captureSource == .recorded }
            .count
    }

    var importedHistoryCount: Int {
        scenarioHistories.values
            .flatMap { $0 }
            .filter { $0.captureSource == .imported }
            .count
    }

    var seededHistoryCount: Int {
        scenarioHistories.values
            .flatMap { $0 }
            .filter { $0.captureSource == .seeded }
            .count
    }

    var exportSummaryLine: String {
        "\(localReplayCount) replay-ready clips on this iPhone · \(recordedHistoryCount) recorded here · \(importedHistoryCount) imported continuity reps · \(seededHistoryCount) seeded starter reps"
    }

    var exportPayload: String {
        let bundle = KatiePocketCopyBundle(
            exportedAt: .now,
            currentMission: currentMission,
            reminderPlan: reminderPlan,
            isPremiumUnlocked: isPremiumUnlocked,
            learnerProfile: learnerProfile,
            scenarioHistories: scenarioHistories,
            selectedAnchorByScenario: selectedAnchorByScenario,
            notes: [
                "This export preserves text history, compare metadata, and reminder continuity state.",
                "Replay works only for audio files that still exist on the exporting device unless a future bundled export ships local clips too.",
                "Seeded and imported reps stay labeled so prototype history does not pose as fresh user recordings."
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(bundle),
              let json = String(data: data, encoding: .utf8) else {
            return "{\n  \"error\": \"Katie could not generate the pocket copy export.\"\n}"
        }

        return json
    }

    var pocketCopyExport: KatiePocketCopyExport {
        let sanitizedPack = currentMission.title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let stamp = Self.pocketCopyFilenameFormatter.string(from: .now)

        return KatiePocketCopyExport(
            json: exportPayload,
            filename: "katie-pocket-copy-\(sanitizedPack)-\(stamp).json"
        )
    }

    var currentScenarioHistory: [PracticeSession] {
        scenarioHistories[currentMission] ?? []
    }

    var currentScenarioUserHistory: [PracticeSession] {
        currentScenarioHistory.filter(\.isUserOwned)
    }

    var currentScenarioStarterHistory: [PracticeSession] {
        currentScenarioHistory.filter { !$0.isUserOwned }
    }

    var latestSession: PracticeSession {
        currentScenarioUserHistory.first ?? currentScenarioStarterHistory.first ?? sampleSession(for: currentMission)
    }

    var latestSelfReflection: SessionSelfReflection {
        latestSession.selfReflection ?? SessionSelfReflection(
            listenerCatchScore: 3,
            paceControlScore: 3,
            confidenceScore: 3,
            stickyMoment: stickyMomentOptions(for: currentMission).first ?? "Opening line"
        )
    }

    var latestStarterSession: PracticeSession? {
        currentScenarioStarterHistory.first
    }

    var activeScenarioUserRepCount: Int {
        userOwnedSessionCount(for: currentMission)
    }

    var hasEarnedFirstWin: Bool {
        activeScenarioUserRepCount >= 1
    }

    var hasEarnedCompare: Bool {
        activeScenarioUserRepCount >= 2
    }

    var compareCandidates: [PracticeSession] {
        guard hasEarnedCompare else { return [] }
        return Array(currentScenarioUserHistory.dropFirst())
    }

    var hasSecondSession: Bool {
        hasEarnedCompare
    }

    var isSecondSessionSaved: Bool {
        hasEarnedCompare
    }

    var selectedCompareAnchor: PracticeSession? {
        guard let selectedId = selectedAnchorByScenario[currentMission] else {
            return compareCandidates.first
        }
        return compareCandidates.first(where: { $0.id == selectedId }) ?? compareCandidates.first
    }

    var selectedAnchorSelfReflection: SessionSelfReflection? {
        selectedCompareAnchor?.selfReflection
    }

    var scenarioPreviewLine: String {
        availableScenarios
            .map { "\($0.title) (\($0.categoryLabel))" }
            .joined(separator: ", ")
    }

    var goalPresets: [GoalPreset] {
        [
            GoalPreset(title: "Clearer, calmer work communication", detail: "Sound steadier in day-to-day updates, check-ins, and work conversations."),
            GoalPreset(title: "Stronger meeting updates", detail: "Land the headline, blocker, and next step without sounding scattered."),
            GoalPreset(title: "More confident presentations", detail: "Open clearly, slow the listener down, and make the takeaway stick."),
            GoalPreset(title: "Warmer customer communication", detail: "Repair tension, restate clearly, and keep trust intact under pressure.")
        ]
    }

    var communicationEnvironmentTitle: String {
        learnerProfile.communicationEnvironment.title
    }

    var communicationEnvironmentDetail: String {
        learnerProfile.communicationEnvironment.detail
    }

    var listenerPressureTitle: String {
        learnerProfile.listenerPressure.title
    }

    var listenerPressureDetail: String {
        learnerProfile.listenerPressure.detail
    }

    var listenerFrictionPointTitle: String {
        learnerProfile.listenerFrictionPoint.title
    }

    var listenerFrictionPointDetail: String {
        learnerProfile.listenerFrictionPoint.detail
    }

    var profileContextHeadline: String {
        "\(communicationEnvironmentTitle) · \(listenerPressureTitle)"
    }

    var profileContextBody: String {
        "Katie starts with \(languageAssessmentSnapshot.title.lowercased()) for \(communicationEnvironmentTitle.lowercased()) moments, protects where listeners first lose the thread (\(listenerFrictionPointTitle.lowercased())), and keeps the first rep honest for a \(listenerPressureTitle.lowercased()) instead of making a generic diagnosis claim."
    }

    var selectedGoalPreset: GoalPreset? {
        goalPresets.first(where: { $0.title == learnerProfile.firstGoal })
    }

    var goalFocusTitle: String {
        selectedGoalPreset?.title ?? learnerProfile.firstGoal
    }

    var goalFocusDetail: String {
        selectedGoalPreset?.detail ?? "Katie keeps the speaking plan tied to this communication goal instead of treating practice like a generic drill."
    }

    var languageAssessmentSnapshot: LanguageAssessmentSnapshot {
        Self.languageAssessmentSnapshot(firstLanguage: learnerProfile.firstLanguage, otherLanguages: learnerProfile.otherLanguages)
    }

    var transferHypothesisFeedback: TransferHypothesisFeedback {
        learnerProfile.transferHypothesisFeedback
    }

    var transferHypothesisStatusTitle: String {
        switch (transferHypothesisFeedback, hasEarnedFirstWin) {
        case (.soundsLikeMe, false):
            return "Confirmed starting cue"
        case (.soundsLikeMe, true):
            return "Saved reps keep checking it"
        case (.notSureYet, false):
            return "Waiting on first saved rep"
        case (.notSureYet, true):
            return "Saved reps decide next"
        case (.notMyMainIssue, false):
            return "Profile cue only for now"
        case (.notMyMainIssue, true):
            return "Profile cue only"
        }
    }

    var transferHypothesisFollowThroughLine: String {
        switch (transferHypothesisFeedback, hasEarnedFirstWin) {
        case (.soundsLikeMe, false):
            return "Katie will start with this listening cue, then verify it against your first saved rep before widening the plan."
        case (.soundsLikeMe, true):
            return "Katie keeps this cue in play, but your saved reps now decide whether it stays the main pattern for this pack."
        case (.notSureYet, false):
            return "Katie will keep this cue visible but wait for your first saved rep before acting like it is the main pattern."
        case (.notSureYet, true):
            return "Katie keeps this cue light and checks your saved reps before treating it like the main pattern for this pack."
        case (.notMyMainIssue, false):
            return "Katie will treat language background as context only and let your first saved rep decide what needs the most coaching."
        case (.notMyMainIssue, true):
            return "Katie keeps language background as context only, while your saved reps decide what needs the most coaching in this pack."
        }
    }

    var transferHypothesisPracticeBridgeLine: String {
        switch (transferHypothesisFeedback, hasEarnedFirstWin) {
        case (.soundsLikeMe, false):
            return "Start here, then let your first saved rep in this pack confirm or correct it."
        case (.soundsLikeMe, true):
            return "This started as the cue, but your saved reps in this pack can still confirm or correct it."
        case (.notSureYet, false):
            return "Keep this cue light until your first saved rep in this pack confirms or corrects it."
        case (.notSureYet, true):
            return "Keep this cue light while saved reps in this pack confirm or correct it."
        case (.notMyMainIssue, false):
            return "Use this as background context until your first saved rep in this pack sets the real plan."
        case (.notMyMainIssue, true):
            return "Use this as background context while saved reps in this pack keep steering the real plan."
        }
    }

    var transferHypothesisPreviewLine: String {
        switch transferHypothesisFeedback {
        case .soundsLikeMe:
            return "Hypothesis status: confirmed starting cue until your first saved rep proves otherwise"
        case .notSureYet:
            return "Hypothesis status: keep visible, but verify it against your first saved rep"
        case .notMyMainIssue:
            return "Hypothesis status: hold lightly and let your first recording lead"
        }
    }

    private func recommendedScenario(
        for environment: CommunicationEnvironment,
        listenerPressure: ListenerPressure
    ) -> PracticeScenario {
        switch environment {
        case .oneOnOne:
            return .managerOneOnOne
        case .teamMeeting:
            return .weeklyUpdate
        case .presentationRoom:
            return .presentationOpening
        case .customerCall:
            return .customerRepair
        case .hybridRoom:
            return listenerPressure == .supportive ? .weeklyUpdate : .presentationOpening
        }
    }

    var recommendedScenarioForCurrentContext: PracticeScenario {
        recommendedScenario(
            for: learnerProfile.communicationEnvironment,
            listenerPressure: learnerProfile.listenerPressure
        )
    }

    var recommendedScenarioReason: String {
        switch recommendedScenarioForCurrentContext {
        case .interviewIntro:
            return "This context needs a calm opener fast, so Katie should protect your first 20–30 seconds before anything more decorative."
        case .weeklyUpdate:
            return "This context rewards decision-first clarity, so the decision pack is the quickest honest rep to keep warm."
        case .managerOneOnOne:
            return "This context needs a low-drama pattern read and one answerable ask, so Katie should bias toward a concrete 1:1 rep before polishing anything wider."
        case .presentationOpening:
            return "This context needs room-level clarity and sentence landing, so the opener pack best matches the listener load."
        case .customerRepair:
            return "This context depends on calm repair and clean restatement, so Katie should bias toward trust-preserving correction reps."
        }
    }

    var recommendedScenarioLaneLine: String {
        "Recommended lane: \(recommendedScenarioForCurrentContext.title)"
    }

    var isRecommendedScenarioAlignedForToday: Bool {
        currentMission == recommendedScenarioForCurrentContext
    }

    var isRecommendedScenarioAlignedForStartingPack: Bool {
        learnerProfile.focusScenario == recommendedScenarioForCurrentContext
    }

    var recommendedScenarioAlignmentLine: String {
        switch (isRecommendedScenarioAlignedForStartingPack, isRecommendedScenarioAlignedForToday) {
        case (true, true):
            return "Your starting pack and Today already match this speaking context, so Katie can keep the next rep focused without extra setup."
        case (true, false):
            return "Your starting pack matches this context, but Today is protecting a different pack right now."
        case (false, true):
            return "Today is already protecting the right pack for this context, but onboarding still points to a different starting pack."
        case (false, false):
            return "Neither the starting pack nor Today matches this context yet, so Katie is still one tap away from the cleanest first rep."
        }
    }

    var recommendedScenarioCoachOrderLine: String {
        "Start with \(recommendedScenarioForCurrentContext.stepLabels.first ?? recommendedScenarioForCurrentContext.title.lowercased()), protect one listener-critical line, and leave prosody polish for the second pass."
    }

    var coachingFrameAdjustmentLine: String {
        "For a \(communicationEnvironmentTitle.lowercased()) with \(listenerPressureTitle.lowercased()), Katie should stabilize the listener-critical words first, keep transfer framing hypothesis-only, and only polish prosody after the wording is easy to catch."
    }

    var currentSoundPatternRadar: SoundPatternRadar {
        let evidenceLine: String
        if let reflection = currentScenarioUserHistory.first?.selfReflection {
            evidenceLine = "Latest self-check · listener \(reflection.listenerCatchScore)/5 · pace \(reflection.paceControlScore)/5 · confidence \(reflection.confidenceScore)/5"
        } else {
            evidenceLine = "Starter hypothesis · no saved self-check yet, so Katie keeps this as a first-pass coaching guess."
        }

        return SoundPatternRadar(
            title: "Speech focus radar",
            summary: "Protect \(listenerFrictionPointTitle.lowercased()) inside your \(currentMission.title.lowercased()) before adding extra polish.",
            evidenceLine: evidenceLine,
            bullets: [
                "Language-transfer cue: \(languageAssessmentSnapshot.transferPattern)",
                "Sound first: \(languageAssessmentSnapshot.soundFocus)",
                "Prosody second: \(languageAssessmentSnapshot.prosodyFocus)"
            ]
        )
    }

    var currentConversationTransferPlan: ConversationTransferPlan {
        ConversationTransferPlan(
            title: "Real-world transfer plan",
            summary: "Katie shifts from isolated practice to the exact moment where \(currentMission.listenerOutcome.lowercased()).",
            beforeYouSpeak: "Before you speak: glance at the protected line and pick one listener-critical word to over-articulate first.",
            whileSpeaking: "While speaking: keep \(currentMission.stepLabels.first?.lowercased() ?? "the first step") steady, then shorten the sentence if pace starts to run.",
            repairMove: "If the listener misses it: restate the key phrase with calmer pace and a clearer ending instead of adding more words."
        )
    }

    var coachingEvidencePulse: CoachingEvidencePulse {
        let recorded = activeScenarioRecordedCount
        let replayReady = activeScenarioReplayReadyCount
        let userOwned = activeScenarioUserRepCount
        let textOnly = max(userOwned - replayReady, 0)

        return CoachingEvidencePulse(
            title: "Evidence ladder",
            summary: "Katie shows how much of this pack is grounded in your own saved speech instead of dressing up prototype content as proof.",
            points: [
                "Saved reps in this pack: \(userOwned)",
                "Replay-ready local audio: \(replayReady)",
                "Text-only coaching captures: \(textOnly)",
                "Recorded on this device: \(recorded)"
            ]
        )
    }

    var currentGoalProgressSnapshot: GoalProgressSnapshot {
        let steps = ["First proof", "Compare live", "Protected lane"]
        let completedSteps: Int

        if reminderPlan?.scenario == currentMission {
            completedSteps = 3
        } else if hasEarnedCompare {
            completedSteps = 2
        } else if hasEarnedFirstWin {
            completedSteps = 1
        } else {
            completedSteps = 0
        }

        let nextMilestoneLine: String
        switch completedSteps {
        case 0:
            nextMilestoneLine = "Next milestone: save one real rep in \(currentMission.packTitle) so this goal stops living as theory."
        case 1:
            nextMilestoneLine = "Next milestone: save one calmer retake so Katie can show a real before/after story for this goal."
        case 2:
            nextMilestoneLine = reminderPlan?.scenario == currentMission
                ? "Milestone live: this goal already has replay, compare, and reminder protection in the same lane."
                : "Next milestone: protect this pack with a reminder so the strongest version stays easy to revisit before a real conversation."
        default:
            nextMilestoneLine = "Goal loop is active: replay, compare, and reminder continuity are all protecting this pack."
        }

        let scenarioLine: String
        if isRecommendedScenarioAlignedForToday {
            scenarioLine = "Today is already protecting \(currentMission.packTitle.lowercased()) for this context."
        } else {
            scenarioLine = "Recommended next pack: \(recommendedScenarioForCurrentContext.packTitle). \(recommendedScenarioReason)"
        }

        let focusPackLine = hasEarnedFirstWin
            ? "Current proof lane: \(currentMission.packTitle) is carrying your goal with \(activeScenarioUserRepCount) user-owned save\(activeScenarioUserRepCount == 1 ? "" : "s")."
            : "Current proof lane: \(currentMission.packTitle) still needs the first user-owned save before Katie should claim measurable progress."

        return GoalProgressSnapshot(
            title: goalFocusTitle,
            detail: goalFocusDetail,
            focusPackLine: focusPackLine,
            scenarioLine: scenarioLine,
            nextMilestoneLine: nextMilestoneLine,
            progressLabel: "\(completedSteps)/\(steps.count) goal milestones live",
            steps: steps,
            completedSteps: completedSteps
        )
    }

    var progressAchievements: [ProgressAchievement] {
        let activePackCount = availableScenarios.filter { userOwnedSessionCount(for: $0) > 0 }.count
        let replayReadyCount = currentScenarioUserHistory.filter { hasPlayback(for: $0) }.count

        return [
            // KAT-157: personified names per MOM-145. Internal `proof*` / `compare*` identifiers
            // kept on purpose (code names, not display text). Voice per MOM-143.
            ProgressAchievement(
                title: "Saved your own voice",
                detail: hasEarnedFirstWin
                    ? "Your real rep is now anchoring \(currentMission.packTitle.lowercased()). Starter copy stepped back."
                    : "Save one real rep so this pack starts from your own voice, not the starter.",
                systemImage: "mic.fill",
                tone: .mint,
                isUnlocked: hasEarnedFirstWin
            ),
            ProgressAchievement(
                title: "Heard the difference",
                detail: hasEarnedCompare
                    ? "A before-and-after story lives in this pack now. Replay it when you want to feel the shift."
                    : "One calmer retake unlocks a real before/after for this pack.",
                systemImage: "arrow.triangle.2.circlepath",
                tone: .accent,
                isUnlocked: hasEarnedCompare
            ),
            ProgressAchievement(
                title: "Saved for replay",
                detail: replayReadyCount > 0
                    ? "\(replayReadyCount) saved clip\(replayReadyCount == 1 ? "" : "s") ready to replay on this iPhone for this pack."
                    : "Record one local clip so progress can coach from your real sound.",
                systemImage: replayReadyCount > 0 ? "waveform.circle.fill" : "speaker.slash.fill",
                tone: .gold,
                isUnlocked: replayReadyCount > 0
            ),
            ProgressAchievement(
                title: "Today on the right lane",
                detail: isRecommendedScenarioAlignedForToday
                    ? "Today is already protecting the pack that fits this moment."
                    : "Switching Today to \(recommendedScenarioForCurrentContext.packTitle) would better match the current listener load.",
                systemImage: isRecommendedScenarioAlignedForToday ? "checkmark.seal.fill" : "arrowshape.turn.up.right.fill",
                tone: .mint,
                isUnlocked: isRecommendedScenarioAlignedForToday
            ),
            ProgressAchievement(
                title: "A reminder is set",
                detail: reminderPlan?.scenario == currentMission
                    ? "A reminder is set for this pack so it stays warm before the next real conversation."
                    : "Add a reminder to keep this pack warm after the compare unlocks.",
                systemImage: reminderPlan?.scenario == currentMission ? "bell.badge.fill" : "bell.badge",
                tone: .accent,
                isUnlocked: reminderPlan?.scenario == currentMission
            ),
            ProgressAchievement(
                title: "Working across packs",
                detail: activePackCount >= 2
                    ? "\(activePackCount) packs now have user-owned proof. Katie feels more like a reusable coach now."
                    : "Warm one more pack so Progress shows momentum across real situations.",
                systemImage: activePackCount >= 2 ? "square.stack.3d.up.fill" : "square.stack.3d.up",
                tone: .gold,
                isUnlocked: activePackCount >= 2
            )
        ]
    }

    var currentScenarioAnalyticsSummary: ScenarioAnalyticsSummary {
        let sessions = Array(currentScenarioUserHistory.prefix(5).reversed())
        let points = sessions.enumerated().map { index, session in
            let reflection = session.selfReflection ?? SessionSelfReflection()
            let overall = Int(round(Double(reflection.listenerCatchScore + reflection.paceControlScore + reflection.confidenceScore) / 3.0))

            return ScenarioAnalyticsPoint(
                label: sessions.count == 1 ? "Rep 1" : "Rep \(index + 1)",
                listenerScore: reflection.listenerCatchScore,
                paceScore: reflection.paceControlScore,
                confidenceScore: reflection.confidenceScore,
                overallScore: overall,
                hasReplay: hasPlayback(for: session)
            )
        }

        guard !points.isEmpty else {
            return ScenarioAnalyticsSummary(
                title: "Pack analytics",
                subtitle: "Save one real rep to unlock the first graph for \(currentMission.packTitle.lowercased()).",
                strongestLane: "Strongest lane appears after the first self-check.",
                momentumLine: "Katie waits for real saved proof before drawing trend lines.",
                playbackLine: "Replay coverage appears after you save local audio on this iPhone.",
                listenerAverage: 0,
                paceAverage: 0,
                confidenceAverage: 0,
                overallAverage: 0,
                points: []
            )
        }

        func average(_ values: [Int]) -> Int {
            Int(round(Double(values.reduce(0, +)) / Double(values.count)))
        }

        let listenerAverage = average(points.map(\.listenerScore))
        let paceAverage = average(points.map(\.paceScore))
        let confidenceAverage = average(points.map(\.confidenceScore))
        let overallAverage = average(points.map(\.overallScore))
        let replayReadyCount = points.filter(\.hasReplay).count

        let strongestLane: String
        switch max(listenerAverage, paceAverage, confidenceAverage) {
        case listenerAverage:
            strongestLane = "Strongest lane right now: listener catch is landing best."
        case paceAverage:
            strongestLane = "Strongest lane right now: pace control is staying steadier."
        default:
            strongestLane = "Strongest lane right now: confidence is reading more settled."
        }

        let momentumLine: String
        if let first = points.first, let last = points.last, points.count > 1 {
            let delta = last.overallScore - first.overallScore
            switch delta {
            case let value where value > 0:
                momentumLine = "Momentum: overall self-check is up \(value) point\(value == 1 ? "" : "s") from the first saved rep in this graph."
            case let value where value < 0:
                momentumLine = "Momentum: overall self-check dipped \(abs(value)) point\(abs(value) == 1 ? "" : "s"); keep the next rep shorter and calmer before adding polish."
            default:
                momentumLine = "Momentum: overall self-check is holding steady across the recent saved reps."
            }
        } else {
            momentumLine = "Momentum: save one more rep to turn this first benchmark into a real trend."
        }

        let playbackLine = replayReadyCount == 0
            ? "Replay coverage: no recent point in this graph can replay on this iPhone yet."
            : replayReadyCount == points.count
            ? "Replay coverage: every point in this graph can replay on this iPhone."
            : "Replay coverage: \(replayReadyCount) of \(points.count) recent points can replay on this iPhone."

        return ScenarioAnalyticsSummary(
            title: "Pack analytics",
            subtitle: "A small, honest graph for \(currentMission.packTitle.lowercased()) built from your last \(points.count) saved rep\(points.count == 1 ? "" : "s").",
            strongestLane: strongestLane,
            momentumLine: momentumLine,
            playbackLine: playbackLine,
            listenerAverage: listenerAverage,
            paceAverage: paceAverage,
            confidenceAverage: confidenceAverage,
            overallAverage: overallAverage,
            points: points
        )
    }

    var reflectionDeltaSummary: String {
        guard let anchor = selectedAnchorSelfReflection else {
            return "Save two user-owned reps to compare how the listener, pace, and confidence scores move across real practice."
        }

        let latest = latestSelfReflection
        let listenerDelta = latest.listenerCatchScore - anchor.listenerCatchScore
        let paceDelta = latest.paceControlScore - anchor.paceControlScore
        let confidenceDelta = latest.confidenceScore - anchor.confidenceScore

        func deltaLine(_ label: String, _ value: Int) -> String {
            switch value {
            case let amount where amount > 0:
                return "\(label) up \(amount)"
            case let amount where amount < 0:
                return "\(label) down \(abs(amount))"
            default:
                return "\(label) steady"
            }
        }

        return [
            deltaLine("Listener catch", listenerDelta),
            deltaLine("pace control", paceDelta),
            deltaLine("confidence", confidenceDelta)
        ].joined(separator: " · ")
    }

    func alignRecommendedScenarioAcrossExperience() {
        updateFocusScenario(recommendedScenarioForCurrentContext)
    }

    static func languageAssessmentSnapshot(firstLanguage: String, otherLanguages: String) -> LanguageAssessmentSnapshot {
        let languageText = [firstLanguage, otherLanguages]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            .lowercased()

        if languageText.contains("spanish") {
            return LanguageAssessmentSnapshot(
                title: "Spanish-English listening plan",
                transferPattern: "Watch for final consonants and linked-word pacing to blur when the sentence speeds up.",
                soundFocus: "Keep clear consonant endings on /t/, /d/, /s/, and /z/ before the next word takes over.",
                prosodyFocus: "Use a small pause before the main stress so the sentence does not run too evenly.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("mandarin") || languageText.contains("cantonese") {
            return LanguageAssessmentSnapshot(
                title: "Tone-language listening plan",
                transferPattern: "Watch for vowel length and word stress to matter more than they do in a tone language.",
                soundFocus: "Separate nearby consonants cleanly, especially contrasts like /l/ and /r/ or voiced and voiceless stops.",
                prosodyFocus: "Give the stressed word a little more lift and a clear pitch change on the key phrase.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("arabic") {
            return LanguageAssessmentSnapshot(
                title: "Arabic-English listening plan",
                transferPattern: "Watch for short function words to blur when English rhythm speeds up.",
                soundFocus: "Check mid-vowel clarity and consonant clusters, especially at the start or end of words.",
                prosodyFocus: "Let the sentence fall at the end so the listener hears the completion clearly.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("japanese") {
            return LanguageAssessmentSnapshot(
                title: "Japanese-English listening plan",
                transferPattern: "Watch for English stress timing and consonant contrasts to flatten when the sentence speeds up.",
                soundFocus: "Protect listener-critical contrasts like /l/ vs /r/, word-final consonants, and short function words that can disappear under pressure.",
                prosodyFocus: "Use one clearer stress peak and a more definite sentence landing before adding broader melody work.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie starts with language-transfer possibilities, then checks your own recordings for what actually repeats."
            )
        }

        if languageText.contains("korean") {
            return LanguageAssessmentSnapshot(
                title: "Korean-English listening plan",
                transferPattern: "Watch for tense/lax consonant contrasts and reduced function words to blur when English rhythm gets compressed.",
                soundFocus: "Protect word-final consonants, cluster clarity, and the exact consonant contrast that changes the listener’s meaning load.",
                prosodyFocus: "Add one cleaner stress target and sentence ending before trying to widen pitch movement across the whole line.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie uses language background as a starting guess, then checks your own speech for repeated listener friction."
            )
        }

        if languageText.contains("hindi") || languageText.contains("urdu") || languageText.contains("hinglish") {
            return LanguageAssessmentSnapshot(
                title: "South Asian English listening plan",
                transferPattern: "Watch for dental/alveolar contrasts and unstressed function words to blur when the sentence speeds up.",
                soundFocus: "Keep listener-critical endings and contrasts like /w/ vs /v/ or /t/ vs /th/ distinct only where they change meaning for the listener.",
                prosodyFocus: "Protect one clear stress peak and a cleaner sentence landing before adding extra melody work.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie starts from your language background, then checks what your own recordings actually repeat."
            )
        }

        if languageText.contains("portuguese") {
            return LanguageAssessmentSnapshot(
                title: "Portuguese-English listening plan",
                transferPattern: "Watch for vowel reduction and word-final consonants to soften when English gets faster.",
                soundFocus: "Keep the key content word crisp, especially the ending consonant and the vowel contrast that carries the meaning.",
                prosodyFocus: "Use one deliberate pause before the main point so the sentence does not feel equally stressed all the way through.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks repeated patterns in your own speech instead of making a broad accent claim."
            )
        }

        if languageText.contains("french") {
            return LanguageAssessmentSnapshot(
                title: "French-English listening plan",
                transferPattern: "Watch for nasal vowels and syllable timing to carry over into English rhythm.",
                soundFocus: "Keep the English vowel contrast a little wider so key words do not collapse together.",
                prosodyFocus: "Add a clearer stress peak on the listener-critical word, not every word equally.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        return LanguageAssessmentSnapshot(
            title: "General listening plan",
            transferPattern: "Katie will listen for the patterns your own recordings repeat, instead of assuming a one-size-fits-all accent issue.",
            soundFocus: "Look for the sounds that most often blur, drop, or change when you are under pressure.",
            prosodyFocus: "Notice where a pause, stress, or sentence ending would make the listener work less.",
            caveat: "This is a coaching hypothesis, not a diagnosis. Katie uses your profile as a starting point, then listens to your own speech."
        )
    }

    func applyGoalPreset(_ preset: GoalPreset) {
        guard learnerProfile.firstGoal != preset.title else { return }
        learnerProfile.firstGoal = preset.title
        KatieHaptic.selection.play()
        persistState()
    }

    func updateGoalFocus(_ goal: String) {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, learnerProfile.firstGoal != trimmed else { return }
        learnerProfile.firstGoal = trimmed
        KatieHaptic.selection.play()
        persistState()
    }

    func updateFirstLanguage(_ language: String) {
        guard learnerProfile.firstLanguage != language else { return }
        learnerProfile.firstLanguage = language
        persistState()
    }

    func updateOtherLanguages(_ languages: String) {
        guard learnerProfile.otherLanguages != languages else { return }
        learnerProfile.otherLanguages = languages
        persistState()
    }

    private func alignStartingPackWithRecommendationIfNeeded(previousRecommended: PracticeScenario) {
        guard learnerProfile.focusScenario == previousRecommended else { return }

        let nextRecommended = recommendedScenarioForCurrentContext
        guard learnerProfile.focusScenario != nextRecommended else { return }
        learnerProfile.focusScenario = nextRecommended
    }

    func updateCommunicationEnvironment(_ environment: CommunicationEnvironment) {
        guard learnerProfile.communicationEnvironment != environment else { return }
        let previousRecommended = recommendedScenarioForCurrentContext
        learnerProfile.communicationEnvironment = environment
        alignStartingPackWithRecommendationIfNeeded(previousRecommended: previousRecommended)
        KatieHaptic.selection.play()
        persistState()
    }

    func updateListenerPressure(_ pressure: ListenerPressure) {
        guard learnerProfile.listenerPressure != pressure else { return }
        let previousRecommended = recommendedScenarioForCurrentContext
        learnerProfile.listenerPressure = pressure
        alignStartingPackWithRecommendationIfNeeded(previousRecommended: previousRecommended)
        KatieHaptic.selection.play()
        persistState()
    }

    func updateListenerFrictionPoint(_ frictionPoint: ListenerFrictionPoint) {
        guard learnerProfile.listenerFrictionPoint != frictionPoint else { return }
        learnerProfile.listenerFrictionPoint = frictionPoint
        KatieHaptic.selection.play()
        persistState()
    }

    func updateFocusScenario(_ scenario: PracticeScenario) {
        let didChangeStoredFocus = learnerProfile.focusScenario != scenario
        learnerProfile.focusScenario = scenario
        selectScenario(scenario)
        if !didChangeStoredFocus {
            persistState()
        }
    }

    var currentScenarioSnapshot: ScenarioProgressSnapshot {
        let scenario = currentMission
        let completedSessions = userOwnedSessionCount(for: scenario)
        let unlocked = latestSession.unlockedStepCount
        let nextUnlock = scenario.stepLabels.dropFirst(unlocked).first ?? "Pack complete — protect the strongest benchmark"

        let streakLabel: String
        switch completedSessions {
        case 0...1: streakLabel = "First saved benchmark"
        case 2: streakLabel = "2-take compare ritual"
        default: streakLabel = "\(completedSessions)-session continuity trail"
        }

        return ScenarioProgressSnapshot(
            completedSessions: completedSessions,
            bestStreakLabel: streakLabel,
            nextUnlockLabel: nextUnlock,
            reminderCadenceLabel: reminderPlanLabel(for: currentMission),
            portableProofLabel: selectedCompareAnchor.map(displayCompareReadinessDetail(for:)) ?? displayCompareReadinessDetail(for: latestSession)
        )
    }

    var firstSpeakingScan: FirstSpeakingScan {
        switch currentMission {
        case .interviewIntro:
            return FirstSpeakingScan(
                strongestMove: "Your role lands quickly, so the listener is not hunting for context.",
                listenerRisk: "The fit line still rushes, which is where confidence can feel thinner than the substance.",
                firstWinPlan: "Save one grounded opener, then retake once with a cleaner breath before the fit sentence.",
                savedLine: latestSession.protectedLine
            )
        case .weeklyUpdate:
            return FirstSpeakingScan(
                strongestMove: "You already land the decision early, which lowers listener effort.",
                listenerRisk: "The tradeoff and next move can blur together if the pause disappears.",
                firstWinPlan: "Protect the decision line, then give the next move one clean beat so the recommendation sounds owned.",
                savedLine: latestSession.protectedLine
            )
        case .managerOneOnOne:
            return FirstSpeakingScan(
                strongestMove: "You name the recurring signal early, which keeps the 1:1 from starting in self-blame or fog.",
                listenerRisk: "The concrete ask can disappear if the friction sentence grows faster than the decision you need.",
                firstWinPlan: "Protect the pattern line, then retake once with one smaller ask your manager can answer on the spot.",
                savedLine: latestSession.protectedLine
            )
        case .presentationOpening:
            return FirstSpeakingScan(
                strongestMove: "The topic is easy to catch, so the room knows where you are going.",
                listenerRisk: "Why this matters can get lost if the idea arrives before the setup breath.",
                firstWinPlan: "Keep the opening topic line, then retake once with a stronger why-it-matters beat before detail.",
                savedLine: latestSession.protectedLine
            )
        case .customerRepair:
            return FirstSpeakingScan(
                strongestMove: "Your repair tone stays warm, which protects trust right away.",
                listenerRisk: "The corrected step can still arrive a little late if the apology gets too much airtime.",
                firstWinPlan: "Shorten the repair phrase, then protect one crisp corrected line the listener can repeat back.",
                savedLine: latestSession.protectedLine
            )
        }
    }

    var packProgressCard: PackProgressCard {
        let unlockedIndex = max(0, min(latestSession.unlockedStepCount - 1, currentMission.stepLabels.count - 1))
        let currentStep = currentMission.stepLabels[unlockedIndex]

        let whyItMatters: String
        switch currentMission {
        case .interviewIntro:
            whyItMatters = "The first 20 seconds decide whether you sound settled or still searching."
        case .weeklyUpdate:
            whyItMatters = "A busy listener should catch the decision, the tradeoff, and the next move in one pass."
        case .managerOneOnOne:
            whyItMatters = "A manager can only help quickly if the pattern, friction, and ask arrive before the emotion spiral."
        case .presentationOpening:
            whyItMatters = "The room listens harder when the stakes are clear before the explanation starts."
        case .customerRepair:
            whyItMatters = "Trust recovers faster when the correction arrives sooner than the apology spiral."
        }

        let continueLine: String
        if activeScenarioUserRepCount == 0 {
            continueLine = "Save your first rep to make this pack yours."
        } else if activeScenarioUserRepCount == 1 {
            continueLine = "Retake once to turn this into a real before/after story."
        } else {
            continueLine = "Replay the saved line, then keep the next rep shorter and calmer."
        }

        return PackProgressCard(
            title: currentMission.packTitle,
            stepLabel: currentStep,
            whyItMatters: whyItMatters,
            nextUnlock: currentScenarioSnapshot.nextUnlockLabel,
            continueLine: continueLine
        )
    }

    var improvementHeadline: String {
        switch currentMission {
        case .interviewIntro:
            return "You sound more grounded in the opening."
        case .weeklyUpdate:
            return "This decision update lands faster for a busy listener."
        case .managerOneOnOne:
            return "This 1:1 now lands as a concrete support ask instead of a stress dump."
        case .presentationOpening:
            return "The opener now gives the audience a cleaner reason to listen."
        case .customerRepair:
            return "The correction feels calmer and easier to trust."
        }
    }

    var comparisonSummary: String {
        guard let anchor = selectedCompareAnchor else {
            return displayCompareReadinessDetail(for: latestSession)
        }

        switch currentMission {
        case .interviewIntro:
            return "Compared with \(anchor.title.lowercased()), this version protects the opening and lands the fit close with less rush."
        case .weeklyUpdate:
            return "Compared with \(anchor.title.lowercased()), the tradeoff and next move separate more cleanly."
        case .managerOneOnOne:
            return "Compared with \(anchor.title.lowercased()), the pattern lands earlier and the manager-facing ask sounds easier to answer."
        case .presentationOpening:
            return "Compared with \(anchor.title.lowercased()), the why-it-matters beat is easier to hear before the detail arrives."
        case .customerRepair:
            return "Compared with \(anchor.title.lowercased()), the reset lands with less apology and a cleaner corrected step."
        }
    }

    var growthThemes: [String] {
        switch currentMission {
        case .interviewIntro:
            return ["Openings are steadier", "Strength lines are more concrete", "Fit closes feel cleaner"]
        case .weeklyUpdate:
            return ["Decision lines reach the point faster", "Tradeoffs sound more concrete", "Next moves sound more owned"]
        case .managerOneOnOne:
            return ["Signals land earlier", "Friction sounds more observed", "Asks feel easier to answer"]
        case .presentationOpening:
            return ["Topic setup is clearer", "Why-it-matters is stronger", "Takeaways arrive earlier"]
        case .customerRepair:
            return ["Repairs stay warm", "Corrections are shorter", "Check-backs protect trust"]
        }
    }

    var featuredWin: FeaturedWin? {
        let latestProof = latestSession

        guard hasEarnedCompare,
              let anchor = selectedCompareAnchor else {
            return FeaturedWin(
                scenario: currentMission,
                beforeText: latestStarterSession?.protectedLine ?? latestProof.transcript,
                afterText: latestProof.protectedLine,
                deltaHint: latestProof.carryoverLine,
                readiness: displayCompareReadiness(for: latestProof),
                sourceTag: hasEarnedFirstWin ? "First benchmark saved" : "Starter sample loaded",
                latestSession: latestProof,
                anchorSession: nil
            )
        }

        return FeaturedWin(
            scenario: currentMission,
            beforeText: anchor.protectedLine,
            afterText: latestProof.protectedLine,
            deltaHint: latestProof.carryoverLine,
            readiness: displayCompareReadiness(for: latestProof),
            sourceTag: compareCeremonyLabel,
            latestSession: latestProof,
            anchorSession: anchor
        )
    }

    var todayRepConfidence: Double {
        Double(latestSelfReflection.confidenceScore) / 5.0
    }

    var compareLibraryEntries: [CompareLibraryEntry] {
        availableScenarios.compactMap { scenario in
            let history = scenarioHistories[scenario] ?? []
            let selectedAnchorID = selectedAnchorByScenario[scenario]
            let userOwnedHistory = history.filter(\.isUserOwned)
            let anchorCandidates = Array(userOwnedHistory.dropFirst())

            guard let latest = history.first(where: \.isUserOwned),
                  let anchor = anchorCandidates.first(where: { $0.id == selectedAnchorID }) ?? anchorCandidates.first else {
                return nil
            }

            return CompareLibraryEntry(
                scenario: scenario,
                latest: latest,
                anchor: anchor
            )
        }
        .sorted { $0.latest.date > $1.latest.date }
    }

    var hasAnyUserProof: Bool {
        availableScenarios.contains { userOwnedSessionCount(for: $0) > 0 }
    }

    var todayQueue: [TodayQueueEntry] {
        availableScenarios
            .map { scenario in
                let ownedCount = userOwnedSessionCount(for: scenario)
                let history = scenarioHistories[scenario] ?? []
                let latest = history.first(where: \.isUserOwned) ?? history.first
                let replayReadyCount = history.filter { $0.isUserOwned && hasPlayback(for: $0) }.count
                let reminderProtected = reminderPlan?.scenario == scenario

                let emphasisLine: String
                if ownedCount == 0 {
                    emphasisLine = latest == nil
                        ? "Record your first try — Katie will remember it."
                        : scenarioStatusDetail(for: scenario)
                } else if reminderProtected {
                    emphasisLine = "Protected for your next real conversation · \(scenarioReminderLine(for: scenario))"
                } else if ownedCount >= 2 {
                    emphasisLine = replayReadyCount > 0
                        ? "Before and after saved."
                        : "History saved. Next recording unlocks full compare."
                } else {
                    emphasisLine = replayReadyCount > 0
                        ? "Replay ready."
                        : "One recording saved. Record again for full compare."
                }

                let action: TodayQueueEntry.Action
                if ownedCount == 0 {
                    action = .recordFirstRep
                } else if ownedCount == 1 {
                    action = replayReadyCount > 0 ? .openProof : .recordFreshProof
                } else if !reminderProtected {
                    action = .enableReminder
                } else if replayReadyCount > 0 {
                    action = .keepWarm
                } else {
                    action = .openCompare
                }

                return TodayQueueEntry(
                    scenario: scenario,
                    statusLabel: scenarioStatusLabel(for: scenario),
                    emphasisLine: emphasisLine,
                    nextStepLine: scenarioNextStepLine(for: scenario),
                    freshnessLabel: latest.map(freshnessLabel(for:)),
                    action: action,
                    reminderCue: todayReminderCue(for: scenario)
                )
            }
            .sorted { todayQueuePriority(for: $0) < todayQueuePriority(for: $1) }
    }

    var compareCeremonyLabel: String {
        if activeScenarioUserRepCount <= 0 {
            return "Sample proof only"
        }
        if activeScenarioUserRepCount == 1 {
            return "Your first saved proof"
        }
        return "Your before/after compare"
    }

    var latestReviewStatusLabel: String {
        if activeScenarioUserRepCount <= 0 {
            return "Starter sample"
        }
        if activeScenarioUserRepCount == 1 {
            return "Latest proof"
        }
        return "Latest compare"
    }

    var latestReviewActionTitle: String {
        if activeScenarioUserRepCount <= 0 {
            return "Open starter proof"
        }
        if activeScenarioUserRepCount == 1 {
            return "Open latest proof"
        }
        return "Open latest compare"
    }

    var latestReviewSummaryLine: String {
        let freshness = freshnessLabel(for: latestSession).lowercased()

        if activeScenarioUserRepCount <= 0 {
            return "Katie is still showing the starter example here. Save your first rep and this review block will switch to your own \(freshness) proof."
        }

        if activeScenarioUserRepCount == 1 {
            return "Your \(freshness) proof is ready to replay against the next rep. Review it now, then return on \(recommendedPracticeStepLabel.lowercased()) to sharpen the next save."
        }

        return "Your \(freshness) compare is ready. Review the latest delta, then keep practicing on \(recommendedPracticeStepLabel.lowercased()) so the next retake stays focused."
    }

    var starterProofStatusLine: String {
        if activeScenarioUserRepCount > 0 {
            return "Starter proof is now secondary. Katie should center your own saved reps first."
        }
        if activeScenarioPrototypeSeedCount > 0 {
            return "This pack opens with starter proof so the flow is visible before you record your own rep."
        }
        return "This pack has no starter proof loaded. Your next save becomes the benchmark."
    }

    var firstWinHeadline: String {
        if activeScenarioUserRepCount <= 0 {
            return activeScenarioPrototypeSeedCount > 0 ? "Starter proof loaded → make it yours" : "Start your first proof"
        }
        if activeScenarioUserRepCount == 1 {
            return "First proof saved → protect the benchmark"
        }
        if activeScenarioUserRepCount == 2 {
            return isPremiumUnlocked ? "Benchmark saved → compare unlocked" : "Benchmark saved → compare ready"
        }
        return isPremiumUnlocked ? "Premium continuity is warming up" : "First-win continuity is live"
    }

    var firstWinMessage: String {
        if activeScenarioUserRepCount == 0 {
            if activeScenarioPrototypeSeedCount > 0 {
                return "Katie is keeping Today on one simple path: read the quick scan, record your own proof, and let the starter sample move into the background."
            }
            return "Katie is keeping Today on one simple path: read the quick scan, record one proof, and let the queue wake up after the save."
        }
        if activeScenarioUserRepCount == 1 {
            return "You saved your own first proof in this pack. Today now pushes one calmer retake so the compare ritual becomes honestly yours, while your latest proof stays ready to review below."
        }
        if isPremiumUnlocked {
            return "Your protected benchmark, retake memory, and reminder continuity now live in one calmer loop for this pack."
        }
        return "You now have a protected benchmark and a retake to compare. Replay both on the next rep and keep this scenario warm."
    }

    var momentumRail: [MomentumMilestone] {
        let hasBenchmark = activeScenarioUserRepCount >= 1
        let hasCompare = activeScenarioUserRepCount >= 2 && displayCompareReadiness(for: latestSession) != .missingAudio

        return [
            MomentumMilestone(
                title: "Benchmark saved",
                detail: hasBenchmark ? "Done" : "Next",
                isActive: hasBenchmark
            ),
            MomentumMilestone(
                title: "First compare live",
                detail: hasCompare ? "Ready" : "Pending",
                isActive: hasCompare
            ),
            MomentumMilestone(
                title: "Retake memory",
                detail: "Built from this pack",
                isActive: activeScenarioUserRepCount >= 2
            ),
            MomentumMilestone(
                title: "Reminder continuity",
                detail: reminderPlan == nil ? "Off" : remindersEnabled ? "On" : (reminderPlan?.scenario.packTitle ?? "Off"),
                isActive: reminderPlan != nil
            )
        ]
    }

    var reminderSummaryLine: String {
        guard let reminderPlan else {
            return "Set a reminder for \(currentMission.packTitle) so Katie nudges the exact line you want before the next real conversation."
        }

        let scheduledPack = reminderPlan.scenario.packTitle
        let scheduleLine = Self.reminderFormatter.string(from: reminderPlan.fireDate)

        if reminderPlan.scenario == currentMission {
            return "Reminder active for \(scheduledPack): \(scheduleLine)\nThis reminder is tied to \(scheduledPack)."
        }

        return "Reminder active for \(scheduledPack): \(scheduleLine)\nThis pack's live reminder currently belongs to \(scheduledPack), not \(currentMission.packTitle)."
    }

    var reminderButtonTitle: String {
        if reminderPermissionState == .denied {
            return "Open notification settings"
        }
        if let reminderPlan {
            return reminderPlan.scenario == currentMission
                ? "Pause reminder for this pack"
                : "Move reminder here"
        }
        return "Enable reminder for this pack"
    }

    var reminderCallToActionLine: String {
        if let reminderPlan, reminderPlan.scenario == currentMission {
            return "Reminder for \(currentMission.packTitle) · fires \(Self.reminderFormatter.string(from: reminderPlan.fireDate))"
        }

        if let reminderPlan {
            return "Reminder for \(currentMission.packTitle) is currently scheduled on \(reminderPlan.scenario.packTitle)."
        }

        return "Remind me on \(currentMission.packTitle)"
    }

    var trustCapsuleLine: String {
        let replayable = activeScenarioReplayReadyCount
        let recorded = activeScenarioRecordedCount

        if replayable > 0 {
            return "Replayable here: \(replayable) local clip\(replayable == 1 ? "" : "s") · recorded here: \(recorded)"
        }

        if activeScenarioPrototypeSeedCount > 0 {
            return "Replayable here: none yet · this pack still leans on seeded prototype proof"
        }

        return "Replayable here: none yet · save one on-device retake to create honest before/after proof"
    }

    var trustBoundaryLine: String {
        "Katie is an SLP-informed speaking coach, not therapy or diagnosis. It starts with sound-pattern coaching for your \(communicationEnvironmentTitle.lowercased()) moments, keeps language-transfer framing hypothesis-only, and treats prosody as a second pass."
    }

    var trustMethodLine: String {
        "Current calibration: \(listenerFrictionPointTitle) in a \(communicationEnvironmentTitle.lowercased()) with \(listenerPressureTitle.lowercased()). Katie uses that context to choose the next rep, then checks your saved audio and self-ratings before escalating the plan."
    }

    var profileContextTrustLine: String {
        "Current framing: \(communicationEnvironmentTitle) · \(listenerPressureTitle) · \(goalFocusTitle)."
    }

    var currentContinuityStrip: KatieContinuityStrip {
        continuityTruthStrip(for: currentMission)
    }

    func continuityTruthStrip(for scenario: PracticeScenario) -> KatieContinuityStrip {
        let history = scenarioHistories[scenario] ?? []
        let userOwnedHistory = history.filter(\.isUserOwned)
        let userOwnedCount = userOwnedHistory.count
        let replayReadyCount = userOwnedHistory.filter { hasPlayback(for: $0) }.count
        let localRecordedCount = userOwnedHistory.filter { $0.captureSource == .recorded }.count
        let nextMove = continuityNextMoveLine(for: scenario, userOwnedCount: userOwnedCount, replayReadyCount: replayReadyCount)

        if let reminderPlan, reminderPlan.scenario != scenario {
            let reminderTime = Self.reminderFormatter.string(from: reminderPlan.fireDate)
            return KatieContinuityStrip(
                title: "Reminder owner: \(reminderPlan.scenario.packTitle)",
                message: "This pack stays visible here, but the next nudge is protecting \(reminderPlan.scenario.packTitle) at \(reminderTime), not this one. Move the reminder back when this is the conversation you want to protect.",
                systemImage: "bell.badge.fill",
                accent: .gold
            )
        }

        if replayReadyCount > 0 {
            let recordedLine = localRecordedCount > 0
                ? " \(localRecordedCount) clip\(localRecordedCount == 1 ? " is" : "s are") recorded on this iPhone."
                : ""
            let reminderLine = continuityReminderLine(for: scenario, userOwnedCount: userOwnedCount)

            return KatieContinuityStrip(
                title: "Replay ready on this iPhone",
                message: "\(replayReadyCount) local clip\(replayReadyCount == 1 ? " can" : "s can") replay here.\(recordedLine)\(reminderLine) Next move: \(nextMove)",
                systemImage: "waveform.badge.checkmark",
                accent: .mint
            )
        }

        if !userOwnedHistory.isEmpty {
            return KatieContinuityStrip(
                title: "Transcript-first for now",
                message: "This pack already has your own saved proof, but replay is not attached on this iPhone yet. Katie keeps the transcript trail visible instead of pretending audio is here.\(continuityReminderLine(for: scenario, userOwnedCount: userOwnedCount)) Next move: \(nextMove)",
                systemImage: "text.quote",
                accent: .accent
            )
        }

        if history.contains(where: { $0.captureSource == .seeded || $0.captureSource == .imported }) {
            return KatieContinuityStrip(
                title: "Starter proof is visible, not final",
                message: "This pack can show sample or carried-over proof, but your own first saved sample is what makes Today, Review, and reminders feel honestly yours. Next move: \(nextMove)",
                systemImage: "sparkles.rectangle.stack.fill",
                accent: .accent
            )
        }

        return KatieContinuityStrip(
            title: "This pack wakes up after your first sample",
            message: "Save one short sample here and Katie can turn it into replay, compare, and reminder follow-through without losing the thread. Next move: \(nextMove)",
            systemImage: "mic.badge.plus",
            accent: .accent
        )
    }

    private func continuityReminderLine(for scenario: PracticeScenario, userOwnedCount: Int) -> String {
        if let reminderPlan, reminderPlan.scenario == scenario {
            return " The next reminder is already tied to this pack for \(Self.reminderFormatter.string(from: reminderPlan.fireDate))."
        }

        if userOwnedCount > 0 {
            return " Add a reminder when you want Katie to protect this exact line next."
        }

        return ""
    }

    private func continuityNextMoveLine(for scenario: PracticeScenario, userOwnedCount: Int, replayReadyCount: Int) -> String {
        if userOwnedCount == 0 {
            return "Save your own first rep so starter proof stops carrying this pack."
        }

        if replayReadyCount == 0 {
            if userOwnedCount == 1 {
                return "Record one fresh local clip in Practice on this iPhone so Review can replay this first proof here."
            }

            return "Open Review's transcript trail, then record one fresh local clip in Practice on this iPhone to restore compare replay."
        }

        if userOwnedCount == 1 {
            return "Open Review replay-ready proof, then save one calmer retake so this pack turns into a real before/after compare."
        }

        if reminderPlan?.scenario != scenario {
            return "Move the next reminder back to this pack so the replay-ready line you built stays protected."
        }

        return "Replay the latest proof once in Review, then save one tighter retake before the next real conversation."
    }

    var premiumCTAButtonTitle: String {
        switch premiumAccessState {
        case .entitled:
            return "Katie Plus active"
        case .preview:
            return "Katie Plus preview is on"
        case .locked:
            return "See Katie Plus preview"
        }
    }

    var premiumActionButtonTitle: String {
        switch premiumAccessState {
        case .entitled:
            return "Katie Plus active"
        case .preview:
            return "Keep preview mode"
        case .locked:
            return premiumStoreStatus.ctaTitle
        }
    }

    var premiumActionButtonDisabled: Bool {
        switch premiumAccessState {
        case .entitled:
            return true
        case .preview:
            return false
        case .locked:
            return premiumStoreStatus.isBusy
        }
    }

    var premiumCTASecondaryLine: String {
        switch premiumAccessState {
        case .locked:
            return premiumStoreStatus.detailLine
        case .preview:
            return "Preview mode is active on this iPhone. Keep copy honest until a real App Store entitlement is confirmed."
        case .entitled:
            return "Katie Plus is backed by a real entitlement on this build, so compare continuity can stop pretending a local toggle is a purchase."
        }
    }

    var premiumHeroSummary: String {
        isPremiumUnlocked
            ? "Unlimited compare history, reminder continuity, and scenario-pack follow-through stay warm in this prototype shell."
            : "Unlock the calmer follow-through layer after your first believable win: compare memory, reminders, and richer progress across packs."
    }

    var premiumFeaturePreview: [String] {
        [
            "Unlimited retakes with compare memory that stays attached to the same scenario pack.",
            "Reminder continuity tied to one protected benchmark line instead of generic motivation.",
            "A richer Progress view that keeps proof warm across interviews, decision moments, presentations, and customer repairs."
        ]
    }

    var premiumStatusLine: String {
        switch premiumAccessState {
        case .entitled:
            return "Katie Plus is active through StoreKit on this build. Keep trust copy explicit about what still stays local-first on this iPhone."
        case .preview:
            return "This is still preview mode on this iPhone, not a purchased entitlement. Katie should stay explicit about that until StoreKit confirms access."
        case .locked:
            return premiumStoreStatus.detailLine
        }
    }

    var audioCaptureLane: AudioCaptureLane {
        if isPreparingRecording {
            return AudioCaptureLane(
                title: "Preparing the microphone",
                detail: "Katie is waiting on iPhone audio access before this take can become a real local clip.",
                systemImage: "mic.badge.plus",
                actionTitle: "Preparing local replay"
            )
        }

        if isRecording {
            return AudioCaptureLane(
                title: "Recording live on this iPhone",
                detail: "Katie is capturing a real local clip now, so the next save can stay replay-ready instead of transcript-only.",
                systemImage: "waveform.circle.fill",
                actionTitle: "Finish and save this proof"
            )
        }

        if hasScratchRecording {
            return AudioCaptureLane(
                title: "Scratch clip is ready",
                detail: "A fresh local clip is attached to the draft right now. Save it to keep Review and Progress honest on this iPhone.",
                systemImage: "mic.badge.checkmark",
                actionTitle: "Save replay-ready proof"
            )
        }

        switch microphonePermissionState {
        case .granted:
            return AudioCaptureLane(
                title: "Replay-ready capture is available",
                detail: "The microphone path is ready when you want it, but Katie still keeps text-only saves available for low-pressure reps.",
                systemImage: "mic.fill",
                actionTitle: "Record one real rep"
            )
        case .unknown:
            return AudioCaptureLane(
                title: "Ask later, not upfront",
                detail: "Katie waits until the moment of need before asking for microphone access, which keeps onboarding calmer and more trustworthy.",
                systemImage: "mic.badge.plus",
                actionTitle: "Start with one short rep"
            )
        case .denied:
            return AudioCaptureLane(
                title: "Text-only fallback stays honest",
                detail: "Microphone access is off, so Katie keeps the transcript path visible without pretending replay exists on this device.",
                systemImage: "mic.slash.fill",
                actionTitle: "Use text-only proof"
            )
        }
    }

    var premiumExperimentSurfaces: [PremiumExperimentSurface] {
        [
            PremiumExperimentSurface(
                title: "First-win premium",
                badge: hasEarnedFirstWin ? "Proof-led" : "Starter-led",
                detail: "The paywall opens off a believable win instead of generic pressure, closer to the calmer subscription apps that let the user feel value first.",
                bullets: [
                    firstWinTrustLine,
                    premiumHeroSummary,
                    currentMission.premiumExperimentHook
                ]
            ),
            PremiumExperimentSurface(
                title: "Cross-pack continuity",
                badge: "Work-life breadth",
                detail: "Premium framing should sell continuity across real speaking moments, not just more repetitions of one interview drill.",
                bullets: [
                    "Current pack: \(currentMission.packTitle)",
                    "Also visible: \(availableScenarios.filter { $0 != currentMission }.prefix(2).map(\.packTitle).joined(separator: " · "))",
                    "Reminder continuity follows one protected line, not generic motivation."
                ]
            ),
            PremiumExperimentSurface(
                title: "Calm App Store framing",
                badge: premiumAccessState == .entitled ? "StoreKit-backed" : "Preview copy",
                detail: "The premium surface stays polished and benefit-led, while the trust note keeps the prototype honest about preview mode versus a real entitlement.",
                bullets: [
                    premiumCTASecondaryLine,
                    premiumStatusLine,
                    audioCaptureLane.detail
                ]
            )
        ]
    }

    var canManageSubscription: Bool {
        premiumAccessState == .entitled && premiumStore.hasActiveEntitlement
    }

    var manageSubscriptionURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    private var currentReminderPreviewPlan: ReminderPlan {
        if let reminderPlan, reminderPlan.scenario == currentMission {
            return reminderPlan
        }

        return ReminderPlan(scenario: currentMission, fireDate: reminderDraftDate)
    }

    var reminderPreviewTitle: String {
        reminderNotificationTitle(for: currentReminderPreviewPlan)
    }

    var reminderPreviewBody: String {
        reminderNotificationBody(for: currentReminderPreviewPlan)
    }

    var reminderPreviewScheduleLine: String {
        let plan = currentReminderPreviewPlan
        let ownershipLine = if let reminderPlan, reminderPlan.scenario == currentMission {
            "This scheduled nudge already belongs to this pack."
        } else if reminderPlan != nil {
            "Another pack currently owns the live reminder, so this is the draft Katie would send if you move it here."
        } else {
            "This is the draft Katie would send when you protect this pack."
        }

        return "\(Self.reminderFormatter.string(from: plan.fireDate)) · \(reminderTone.title) tone. \(ownershipLine)"
    }

    var reminderPreviewCopy: String {
        let line = latestSession.protectedLine
        let pack = currentMission.packTitle

        if let reminderPlan, reminderPlan.scenario == currentMission {
            return "Replay \"\(line)\" before your next \(pack.lowercased()) window. Katie will keep the same saved line protected."
        }

        if let reminderPlan {
            return "Katie will move the live reminder from \(reminderPlan.scenario.packTitle) to \(pack) and keep the same protected line, \"\(line)\"."
        }

        return "When \(pack) earns a reminder, Katie will nudge the saved line, \"\(line)\", instead of generic motivation."
    }

    var reminderToneLine: String {
        switch reminderTone {
        case .calm:
            return "Calm tone keeps the nudge soft: one breath, one saved line, no extra pressure."
        case .workday:
            return "Workday tone keeps the nudge brisk and practical for normal team rhythm."
        case .beforeMeeting:
            return "Before-meeting tone frames the reminder like a quick pocket reset right before a live moment."
        }
    }

    var reminderClinicalBoundaryLine: String {
        "Reminders are clinician-informed coaching support, not therapy, diagnosis, or emergency guidance."
    }

    var momentumSummaryLine: String {
        switch activeScenarioUserRepCount {
        case 0:
            return "Day 0 of this pack — earn the first saved proof."
        case 1:
            return "Day 1 feel — one benchmark is protected, now make the compare visible."
        case 2:
            return "Two-touch momentum — the compare ritual is alive."
        default:
            return "This pack is warming into a repeatable speaking routine."
        }
    }

    var trustWhyKatieLine: String {
        "Katie helps you sound clearer in real work conversations. It focuses on patterns in your own speech, keeps replay honest on this iPhone, and stays clear about what is coaching versus diagnosis."
    }

    var currentPackWarmthLabel: String {
        switch activeScenarioUserRepCount {
        case 0...1:
            return "First proof"
        case 2:
            return "Live compare"
        case 3...4:
            return "Warm"
        default:
            return "Sustained"
        }
    }

    var activeScenarioRecordedCount: Int {
        currentScenarioUserHistory.filter { $0.captureSource == .recorded }.count
    }

    var activeScenarioReplayReadyCount: Int {
        currentScenarioUserHistory.filter { hasPlayback(for: $0) }.count
    }

    var activeScenarioPrototypeSeedCount: Int {
        currentScenarioHistory.filter { $0.captureSource == .seeded }.count
    }

    var firstWinTrustLine: String {
        if activeScenarioRecordedCount > 0 {
            return "This pack already includes \(activeScenarioRecordedCount) real recording\(activeScenarioRecordedCount == 1 ? "" : "s") saved on this iPhone."
        }
        if activeScenarioUserRepCount > 0 {
            return "This pack now includes your own saved proof, even if replay is still text-first for some reps."
        }
        if activeScenarioReplayReadyCount > 0 {
            return "Replay is available for \(activeScenarioReplayReadyCount) clip\(activeScenarioReplayReadyCount == 1 ? "" : "s") on this iPhone, but the active trail still leans on starter or transferred proof."
        }
        if activeScenarioPrototypeSeedCount > 0 {
            return "This pack is still showing seeded prototype reps until you save your own recording."
        }
        return "This pack is text-first right now — save one on-device recording to make the compare ritual feel truly yours."
    }

    var firstWinPrimaryAction: FirstWinPrimaryAction {
        if activeScenarioUserRepCount == 0 {
            return microphonePermissionState == .denied ? .saveTextBaseline : .recordBaseline
        }
        if activeScenarioUserRepCount == 1 {
            return .practiceNextRep
        }
        if reminderPlan?.scenario != currentMission {
            return reminderPermissionState == .denied ? .openNotificationSettings : .enableReminder
        }
        return .practiceNextRep
    }

    var firstWinPrimaryActionTitle: String {
        switch firstWinPrimaryAction {
        case .recordBaseline:
            return "Record your own first proof"
        case .saveTextBaseline:
            return "Microphone blocked — save text-only for now"
        case .openLatestProof:
            return latestReviewActionTitle
        case .enableReminder:
            return reminderPlan == nil ? "Turn on reminder continuity" : "Move reminder to this pack"
        case .openNotificationSettings:
            return "Fix reminders in Settings"
        case .practiceNextRep:
            return activeScenarioUserRepCount == 1 ? "Practice the next retake" : "Practice next step"
        }
    }

    func performFirstWinPrimaryAction(openSettings: () -> Void = {}) {
        switch firstWinPrimaryAction {
        case .recordBaseline:
            openPractice(for: currentMission)
        case .saveTextBaseline:
            saveFirstWinFallbackIfNeeded()
        case .openLatestProof:
            openReview(for: currentMission, anchor: selectedCompareAnchor)
        case .enableReminder:
            scheduleOrDismissReminder()
        case .openNotificationSettings:
            openSettings()
        case .practiceNextRep:
            openPractice(for: currentMission)
        }
    }

    var currentPackNextStepLabel: String {
        groundedNextStepLine(for: currentMission, includePrefix: false)
    }

    var retakeMemorySessions: [PracticeSession] {
        currentScenarioUserHistory.isEmpty ? currentScenarioStarterHistory : currentScenarioUserHistory
    }

    func proofLabel(for session: PracticeSession, placement: ProofPlacement) -> String {
        switch session.captureSource {
        case .seeded:
            return placement == .baseline ? "Starter continuity" : "Starter compare"
        case .recorded, .syntheticRetake:
            return placement == .baseline ? "Your earlier proof" : "Your latest proof"
        case .imported:
            return placement == .baseline ? "Imported continuity" : "Imported latest proof"
        }
    }

    func compactCaptureSourceLabel(for session: PracticeSession) -> String {
        switch session.captureSource {
        case .seeded:
            return "Starter continuity"
        case .recorded:
            return "Recorded here"
        case .imported:
            return "Imported continuity"
        case .syntheticRetake:
            return "Text retake"
        }
    }

    func transcriptWordCountLabel(for session: PracticeSession) -> String {
        let count = session.transcript
            .split { $0.isWhitespace || $0.isNewline }
            .count

        return count == 1 ? "1 word" : "\(count) words"
    }

    func compactReplayLabel(for session: PracticeSession) -> String {
        if let duration = session.durationSeconds, hasPlayback(for: session) {
            return "\(Int(duration.rounded()))s clip"
        }

        switch displayCompareReadiness(for: session) {
        case .audioReady:
            return "Replay ready"
        case .transcriptOnly:
            return "Transcript only"
        case .transferredWithoutAudio:
            return "Transferred proof"
        case .missingAudio:
            return "Audio missing"
        }
    }

    func speakingPaceLabel(for session: PracticeSession) -> String {
        guard let duration = session.durationSeconds,
              duration > 0,
              hasPlayback(for: session) else {
            return "Pace unavailable"
        }

        let words = session.transcript
            .split { $0.isWhitespace || $0.isNewline }
            .count
        let wordsPerMinute = Int(((Double(words) / duration) * 60).rounded())

        return "\(wordsPerMinute) wpm"
    }

    enum ProofPlacement {
        case baseline
        case latest
    }

    func displayCompareReadiness(for session: PracticeSession) -> CompareReadiness {
        if session.audioFileName != nil {
            return hasPlayback(for: session) ? .audioReady : .missingAudio
        }
        return session.compareReadiness
    }

    func displayCompareReadinessTitle(for session: PracticeSession) -> String {
        displayCompareReadiness(for: session).title
    }

    func displayCompareReadinessDetail(for session: PracticeSession) -> String {
        if session.audioFileName != nil && !hasPlayback(for: session) {
            if session.captureSource == .seeded {
                return "This is starter continuity from the prototype. Katie keeps the compare trail visible, but this iPhone does not currently have the bundled audio attached for playback."
            }
            return "This rep carries replay metadata, but the local audio file is not attached on this iPhone right now. Katie keeps the compare trail visible without pretending playback still works."
        }
        return displayCompareReadiness(for: session).detail
    }

    func displayCompareReadinessSystemImage(for session: PracticeSession) -> String {
        displayCompareReadiness(for: session).systemImage
    }

    func compareTruthLine(anchor: PracticeSession?, latest: PracticeSession) -> String {
        guard let anchor else {
            return "This review is centered on \(compactCaptureSourceLabel(for: latest).lowercased()) from \(freshnessLabel(for: latest).lowercased()). The compare trail stays honest about whether replay is actually attached on this iPhone. \(replayAvailabilityLine(for: [latest]))"
        }

        return "This compare opens \(compactCaptureSourceLabel(for: anchor).lowercased()) from \(freshnessLabel(for: anchor).lowercased()) against \(compactCaptureSourceLabel(for: latest).lowercased()) from \(freshnessLabel(for: latest).lowercased()). \(replayAvailabilityLine(for: [anchor, latest]))"
    }

    struct CompareReplayRecoveryPrompt {
        let title: String
        let message: String
        let actionTitle: String
    }

    private func replayAvailabilityLine(for sessions: [PracticeSession]) -> String {
        let replayReadyCount = sessions.filter { hasPlayback(for: $0) }.count

        switch replayReadyCount {
        case 0:
            return "Replay is not attached for these clips on this iPhone, so Katie keeps the transcript trail visible instead."
        case 1 where sessions.count == 1:
            return "Replay is attached for this clip on this iPhone."
        case 1:
            if let replayReadySession = sessions.first(where: { hasPlayback(for: $0) }) {
                let role = replayReadySession.id == sessions.first?.id ? "Only the earlier proof" : "Only the latest proof"
                return "\(role) can replay on this iPhone right now."
            }
            return "Only one clip can replay on this iPhone right now."
        default:
            return "Both clips can replay on this iPhone right now."
        }
    }

    func compareLibraryReplayLine(for entry: CompareLibraryEntry) -> String {
        let anchorHasReplay = entry.anchor.map(hasPlayback(for:)) ?? false
        let latestHasReplay = hasPlayback(for: entry.latest)

        switch (anchorHasReplay, latestHasReplay) {
        case (true, true):
            return "Both clips replay locally on this iPhone."
        case (true, false):
            return "Earlier proof replays locally, latest proof is transcript-only."
        case (false, true):
            return "Latest proof replays locally, earlier proof is transcript-only."
        default:
            return entry.anchor == nil
                ? "This proof is transcript-first until you record a local clip."
                : "This compare is transcript-first until one side gets local audio back."
        }
    }

    func compareReplayRecoveryPrompt(anchor: PracticeSession?, latest: PracticeSession) -> CompareReplayRecoveryPrompt? {
        let latestHasReplay = hasPlayback(for: latest)

        guard let anchor else {
            guard !latestHasReplay else { return nil }

            if latest.captureSource == .seeded {
                return CompareReplayRecoveryPrompt(
                    title: "Starter audio is elsewhere",
                    message: "Record one real rep and Katie will swap the sample for replay-ready proof on this iPhone.",
                    actionTitle: "Record your own proof"
                )
            }

            return CompareReplayRecoveryPrompt(
                title: "Replay needs a fresh clip",
                message: "The proof trail stayed visible, but replay is missing on this iPhone. Record one fresh rep and Katie will bring the clip back without losing the coaching trail.",
                actionTitle: "Restore replay"
            )
        }

        let anchorHasReplay = hasPlayback(for: anchor)
        guard !(anchorHasReplay && latestHasReplay) else { return nil }

        switch (anchorHasReplay, latestHasReplay) {
        case (true, false):
            return CompareReplayRecoveryPrompt(
                title: "Latest replay needs a fresh clip",
                message: "The earlier proof still replays here, but the newest retake is transcript-only on this iPhone. Save one fresh local retake to hear the full compare again.",
                actionTitle: "Record to restore full compare"
            )
        case (false, true):
            return CompareReplayRecoveryPrompt(
                title: "Earlier replay needs a fresh clip",
                message: "The newest retake still replays here, but the earlier proof is transcript-only on this iPhone. Save one fresh local retake and Katie rebuilds the audible before/after pair without losing the compare trail.",
                actionTitle: "Record to restore full compare"
            )
        case (false, false):
            return CompareReplayRecoveryPrompt(
                title: "Compare replay needs a fresh clip",
                message: "Neither side can replay on this iPhone right now. Save one fresh local retake to start rebuilding the compare while Katie keeps the transcript trail honest.",
                actionTitle: "Restore compare replay"
            )
        case (true, true):
            return nil
        }
    }

    func compareLibraryActionTitle(anchor: PracticeSession?, latest: PracticeSession) -> String {
        let anchorHasReplay = anchor.map(hasPlayback(for:)) ?? false
        let latestHasReplay = hasPlayback(for: latest)

        guard anchor != nil else {
            return latestHasReplay ? "Review replay-ready proof" : "Review transcript-only proof"
        }

        switch (anchorHasReplay, latestHasReplay) {
        case (true, true):
            return "Review replay-ready pair"
        case (false, false):
            return "Review transcript-only pair"
        default:
            return anchorHasReplay ? "Review earlier replay proof" : "Review latest replay proof"
        }
    }

    func compareLibraryActionTitle(for entry: CompareLibraryEntry) -> String {
        compareLibraryActionTitle(anchor: entry.anchor, latest: entry.latest)
    }

    func comparePracticeActionTitle(for session: PracticeSession?) -> String {
        guard let session else {
            return "Practice transcript-only proof"
        }
        return hasPlayback(for: session) ? "Practice replay-ready proof" : "Practice transcript-only proof"
    }

    var reminderStatusLine: String {
        switch reminderPermissionState {
        case .unknown:
            return "Katie will ask for notification permission only when you choose a reminder."
        case .granted:
            if remindersEnabled {
                return "Next nudge is scheduled on this iPhone for \(reminderDraftTimeLabel)."
            }
            if let reminderPlan {
                return "A reminder is already protecting \(reminderPlan.scenario.packTitle.lowercased()) on this iPhone."
            }
            return "Notifications are allowed. Turn on a reminder when this pack earns one."
        case .denied:
            return "Notifications are blocked, so Katie keeps the reminder plan visible here without pretending the nudge will fire."
        }
    }

    var localStorageSummaryLine: String {
        "Local-first on this iPhone: \(localReplayCount) replay-ready clips, \(recordedHistoryCount) recorded here, \(currentScenarioUserHistory.count) user-owned reps in the active pack, reminder \(remindersEnabled ? "armed" : "visible only")."
    }

    var microphoneStatusLine: String {
        switch microphonePermissionState {
        case .unknown:
            return "Katie asks for microphone access only when you start a real recording."
        case .granted:
            return "Microphone access is available for replay-ready retakes on this iPhone."
        case .denied:
            return "Microphone access is blocked, so Katie can still save text-only retakes without pretending replay exists."
        }
    }

    var scratchCaptureTruthTitle: String {
        if isPreparingRecording {
            return "Preparing local recording"
        }
        if isRecording {
            return "Recording locally on this iPhone"
        }
        if scratchRecordingURL != nil {
            return "Local scratch clip is ready"
        }
        return "Transcript-only until you record"
    }

    var scratchCaptureTruthBody: String {
        if isPreparingRecording {
            return "Katie is opening the microphone lane now. Stay on this pack so the local clip attaches to the right proof trail."
        }
        if isRecording {
            return "This pass is capturing a real local clip right now. Keep the draft short so the replay feels honest when you compare it later."
        }
        if scratchRecordingURL != nil {
            return "A local scratch clip is attached to this draft on this iPhone. Save now to keep replay with the retake in Review and Progress."
        }
        return "Your draft text is visible, but replay only appears after you record on this iPhone. Katie keeps that line explicit instead of implying audio exists."
    }

    var hasScratchRecording: Bool {
        scratchRecordingURL != nil
    }

    var quickRepHintLine: String {
        switch currentMission {
        case .interviewIntro:
            return "Quick rep: one calm 60-second intro with your name, role, and fit line."
        case .weeklyUpdate:
            return "Quick rep: one 60-second update with headline, blocker, and next step."
        case .managerOneOnOne:
            return "Quick rep: one honest 60-second 1:1 with the pattern, friction, and one answerable ask."
        case .presentationOpening:
            return "Quick rep: one 60-90 second opening with topic, key idea, and takeaway."
        case .customerRepair:
            return "Quick rep: one short repair with reset, corrected detail, and clean close."
        }
    }

    var quickChallengeScenario: PracticeScenario {
        recommendedScenarioForCurrentContext
    }

    var quickChallengeHeadline: String {
        "1-minute challenge"
    }

    var quickChallengeDetailLine: String {
        "Run \(quickChallengeScenario.title) once, keep \(recommendedPracticeStepLabel.lowercased()) in focus, and stop while it still feels clean."
    }

    var quickChallengeDurationLabel: String {
        "≈60 sec"
    }

    var quickChallengeStarterLine: String {
        quickRepStarterLine(for: quickChallengeScenario)
    }

    var practiceTranscriptTruthLine: String {
        let transcript = draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines)

        if !transcript.isEmpty {
            return "Transcript draft is live for this rep. Katie will keep the wording visible even if you do not save audio yet."
        }

        return "No fresh transcript draft yet. Katie will fall back to your latest saved wording until you edit or record a new pass."
    }

    var practiceReplayTruthLine: String {
        if isPreparingRecording {
            return "Katie is preparing the microphone lane. Once access is ready, this draft can become replay-ready on this iPhone."
        }

        if isRecording {
            return "Local audio is recording on this iPhone now. Release and save when you want replay-ready proof."
        }

        if hasScratchRecording, let latestScratchRecordingDuration {
            return "A \(Int(latestScratchRecordingDuration.rounded())) second scratch clip is waiting on this iPhone. Save it to keep replay attached in Review and Progress."
        }

        if let latestRecorded = currentScenarioUserHistory.first(where: { hasPlayback(for: $0) }) {
            return "Your latest saved proof can replay here from \(freshnessLabel(for: latestRecorded).lowercased()), but this draft still needs a fresh local clip if you want the next compare to stay listenable."
        }

        return "No fresh local clip is attached to this draft yet. Katie keeps the transcript path visible instead of implying replay exists."
    }

    var practiceCaptureHonestyLine: String {
        if isPreparingRecording {
            return "Katie is opening the microphone lane before deciding whether this proof can carry local replay."
        }

        if hasScratchRecording {
            return "Save now to keep transcript + local replay together."
        }

        if currentScenarioUserHistory.contains(where: { hasPlayback(for: $0) }) {
            return "You already have saved replay in this pack, but the next compare stays transcript-first until you record again."
        }

        return "First wins still count without audio, but replay only appears after a real on-device recording."
    }

    var practiceSaveOutcomeTitle: String {
        if isPreparingRecording {
            return "Wait for the microphone before saving"
        }

        if isRecording {
            return "Finish this rep before saving"
        }

        if hasScratchRecording {
            return "Saving now creates replay-ready proof"
        }

        return "Saving now creates transcript-only proof"
    }

    var practiceSaveOutcomeBody: String {
        if isPreparingRecording {
            return "Katie has not attached a local clip yet. Let the microphone finish opening before you decide whether this proof should save with replay."
        }

        if isRecording {
            return "Katie has not attached the fresh local clip yet. Stop recording first so Review and Progress can keep this rep listenable on this iPhone."
        }

        if hasScratchRecording {
            return "This save keeps your transcript and fresh local audio together, so Review and Progress can replay the latest rep on this iPhone right away."
        }

        return "Katie will keep the new wording and self-check, but this rep stays clearly text-only in Review and Progress until you record a fresh on-device pass."
    }

    var practiceSaveButtonTitle: String {
        if isPreparingRecording {
            return "Preparing microphone"
        }

        if isRecording {
            return "Stop recording before saving"
        }

        return hasScratchRecording ? "Save replay-ready proof" : "Save transcript-only proof"
    }

    var practiceSaveReviewOutcomeLine: String {
        if isPreparingRecording {
            return "Review waits until the microphone lane resolves before replay can attach."
        }

        if isRecording {
            return "Review waits for the finished clip before replay can attach."
        }

        return hasScratchRecording
            ? "Review opens with the latest rep ready to replay on this iPhone."
            : "Review keeps the latest rep labeled transcript-only instead of implying replay exists."
    }

    var practiceSaveProgressOutcomeLine: String {
        if isPreparingRecording {
            return "Progress stays on the earlier proof until this recording is ready or canceled."
        }

        if isRecording {
            return "Progress will stay on the earlier saved proof until this recording finishes."
        }

        return hasScratchRecording
            ? "Progress can treat this as the latest replay-ready proof for the pack."
            : "Progress keeps the new rep visible but marks it as transcript-only proof."
    }

    var currentScenarioRemainsProtected: String {
        currentScenarioUserHistory.first?.protectedLine ?? latestStarterSession?.protectedLine ?? "Keep a protected line for this scenario."
    }

    var shouldShowFirstBaselineGate: Bool {
        hasCompletedOnboarding && !hasDismissedFirstBaselineGate && activeScenarioUserRepCount == 0
    }

    var firstBaselineHeadline: String {
        microphonePermissionState == .denied ? "Save your first sample anyway" : "Save your first personal sample"
    }

    var firstBaselineBody: String {
        if microphonePermissionState == .denied {
            return "Microphone access is blocked right now, so Katie should still let you save a text-first sample in \(currentMission.title.lowercased()) instead of dropping you into a demo-heavy shell."
        }
        return "Before Katie shows the full shell, save one real sample in \(currentMission.title.lowercased()). That first save becomes the honest anchor for compare, reminders, and your next real work rep."
    }

    var firstBaselinePrimaryActionTitle: String {
        microphonePermissionState == .denied ? "Use text-only sample" : "Record first sample"
    }

    var firstBaselineSecondaryActionTitle: String {
        "Continue with starter proof only"
    }

    func completeOnboarding() {
        currentMission = learnerProfile.focusScenario
        selectedTab = .today
        ensureAnchorSelection(for: learnerProfile.focusScenario)
        hasCompletedOnboarding = true
        hasDismissedFirstBaselineGate = false
        persistState()
    }

    func persistOnboardingProfileDraft() {
        persistState()
    }

    func unlockPremiumPreview() {
        premiumAccessState = .preview
        persistState()
    }

    func unlockPremiumFlow() {
        unlockPremiumPreview()
    }

    func continuePastFirstBaselineGate() {
        hasDismissedFirstBaselineGate = true
        selectedTab = .today
        practiceReturnCue = nil
        persistState()
    }

    func setReminderTone(_ tone: ReminderTone) {
        guard reminderTone != tone else { return }

        reminderTone = tone
        KatieHaptic.selection.play()

        if let reminderPlan {
            switch reminderPermissionState {
            case .granted:
                reminderFlowMessage = ReminderFlowMessage(
                    title: "Reminder tone updated",
                    body: "Same reminder time, now in a \(tone.title.lowercased()) tone."
                )
                Task {
                    await scheduleReminder(reminderPlan)
                }
            case .denied:
                reminderFlowMessage = ReminderFlowMessage(
                    title: "Tone saved for later",
                    body: "\(tone.title) tone saved. iPhone notifications are still off, so nothing can fire yet."
                )
            case .unknown:
                reminderFlowMessage = ReminderFlowMessage(
                    title: "Tone saved for the next reminder",
                    body: "Katie will use the \(tone.title.lowercased()) tone the next time you arm this pack."
                )
            }
        }

        persistState()
    }

    func updateReminderTime(_ date: Date) {
        guard var reminderPlan, reminderPlan.scenario == currentMission else { return }
        reminderPlan.fireDate = date
        self.reminderPlan = reminderPlan
        persistState()

        Task {
            await scheduleReminder(reminderPlan)
        }
    }

    func preparePremiumStore() async {
        await premiumStore.prepare()
        syncPremiumStoreStatus()
        await syncPremiumAccessFromStore()
    }

    func refreshPremiumStore() async {
        await premiumStore.refreshProductsIfNeeded(force: true)
        syncPremiumStoreStatus()
        await syncPremiumAccessFromStore()
    }

    func clearPremiumRestoreMessage() {
        premiumRestoreMessage = nil
    }

    func clearPocketCopyStatusLine() {
        pocketCopyStatusLine = nil
    }

    func clearReminderFlowMessage() {
        reminderFlowMessage = nil
    }

    func importPocketCopy(from url: URL) async {
        let startedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: url)
            let bundle = try decoder.decode(KatiePocketCopyBundle.self, from: data)

            stopPlayback()
            audioRecorder?.stop()
            isRecording = false
            latestScratchRecordingDuration = nil
            scratchRecordingURL = nil
            clearAllLocalRecordings()

            learnerProfile = bundle.learnerProfile
            currentMission = bundle.currentMission
            availableScenarios = PracticeScenario.allCases
            scenarioHistories = normalizedImportedHistories(from: bundle.scenarioHistories)
            selectedAnchorByScenario = sanitizedImportedAnchors(bundle.selectedAnchorByScenario, histories: scenarioHistories)
            hasCompletedOnboarding = true
            hasDismissedFirstBaselineGate = true
            premiumAccessState = premiumStore.hasActiveEntitlement ? .entitled : .locked
            premiumRestoreMessage = nil

            if let reminderPlan = bundle.reminderPlan {
                clearAllReminderRequests(except: reminderPlan.requestIdentifier)
                self.reminderPlan = reminderPlan
                if reminderPermissionState == .granted {
                    await scheduleReminder(reminderPlan)
                }
            } else {
                clearAllReminderRequests()
                reminderPlan = nil
            }

            ensureAnchorSelection(for: currentMission)
            persistState()

            pocketCopyStatusLine = bundle.reminderPlan == nil
                ? "Pocket copy restored. Katie kept the coaching trail, but replay stays local-only and premium still needs a real App Store entitlement on this iPhone."
                : "Pocket copy restored. Katie carried over the reminder plan and coaching trail, but replay stays local-only and premium still needs a real App Store entitlement on this iPhone."
            recorderStatusLine = "Pocket copy restored as transcript-first continuity. Replay will return only after you record fresh audio on this iPhone."
            KatieHaptic.success.play()
        } catch {
            pocketCopyStatusLine = "Katie couldn’t restore that pocket copy. Use a Katie export JSON so continuity comes back without pretending audio survived the move."
            KatieHaptic.warning.play()
        }
    }

    func restorePremiumPurchases() async {
        let outcome = await premiumStore.restorePurchases()
        syncPremiumStoreStatus()
        await syncPremiumAccessFromStore()

        switch outcome {
        case .restored:
            premiumAccessState = .entitled
            premiumRestoreMessage = PremiumRestoreMessage(
                title: "Katie Plus restored",
                body: "This iPhone found an active Katie Plus entitlement, so the premium layer can stop acting like preview mode.",
                tone: .success
            )
        case .noActiveSubscription:
            premiumRestoreMessage = PremiumRestoreMessage(
                title: "No purchase found to restore",
                body: "Katie checked the App Store, but there is no active Katie Plus subscription tied to this Apple account right now.",
                tone: .neutral
            )
        case .failed(let message):
            premiumRestoreMessage = PremiumRestoreMessage(
                title: "Restore did not finish",
                body: message,
                tone: .warning
            )
        }

        persistState()
    }

    func purchasePremiumIfAvailable() async {
        do {
            let outcome = try await premiumStore.purchase()

            switch outcome {
            case .purchased:
                premiumAccessState = .entitled
                premiumRestoreMessage = PremiumRestoreMessage(
                    title: "Katie Plus unlocked",
                    body: "Your App Store purchase finished on this iPhone, so Katie Plus can now stay explicit about real entitled access instead of preview mode.",
                    tone: .success
                )
            case .pendingApproval:
                premiumRestoreMessage = PremiumRestoreMessage(
                    title: "Purchase is pending",
                    body: "The App Store accepted the request, but Katie Plus is still waiting for approval before access can unlock on this iPhone.",
                    tone: .neutral
                )
            case .userCancelled:
                premiumRestoreMessage = PremiumRestoreMessage(
                    title: "Purchase was not completed",
                    body: "Katie Plus stayed locked because the App Store purchase was cancelled or dismissed before entitlement was confirmed.",
                    tone: .neutral
                )
            case .fallbackPreview:
                premiumRestoreMessage = PremiumRestoreMessage(
                    title: "Katie Plus is not purchasable on this build yet",
                    body: "StoreKit still could not load a live Katie Plus product, so Katie stayed honest about preview-mode fallback instead of pretending purchase succeeded.",
                    tone: .warning
                )
            }
        } catch {
            syncPremiumStoreStatus()
            premiumRestoreMessage = PremiumRestoreMessage(
                title: "Purchase did not finish",
                body: premiumStoreStatus.detailLine,
                tone: .warning
            )
        }
        syncPremiumStoreStatus()
        await syncPremiumAccessFromStore()
        persistState()
    }

    var activePracticeStepLabel: String {
        currentMission.stepLabels[activePracticeStep]
    }

    var recordingLockLine: String {
        if isPreparingRecording {
            return "Wait for the microphone to finish preparing before switching scenario packs so this take stays attached to \(currentMission.title)."
        }

        return "Finish or stop the current recording before switching scenario packs so this take stays attached to \(currentMission.title)."
    }

    var activePracticeStepPrompt: String {
        currentMission.stepCoachingPrompts[activePracticeStep]
    }

    var activePracticeStepProgressLabel: String {
        "Step \(activePracticeStep + 1) of \(currentMission.stepLabels.count)"
    }

    var recommendedPracticeStep: Int {
        min(latestSession.unlockedStepCount, currentMission.stepLabels.count - 1)
    }

    var recommendedPracticeStepLabel: String {
        currentMission.stepLabels[recommendedPracticeStep]
    }

    var recommendedPracticeStepPrompt: String {
        currentMission.stepCoachingPrompts[recommendedPracticeStep]
    }

    var retakeDraftStarterChips: [String] {
        let protectedLine = latestSession.protectedLine
        let carryover = latestSession.carryoverLine

        switch currentMission {
        case .interviewIntro:
            switch activePracticeStep {
            case 0:
                return [
                    "I'm [name], and I lead [role/context].",
                    "Right now I'm focused on \(protectedLine)",
                    "The work I want to bring here is \(carryover.lowercased())."
                ]
            case 1:
                return [
                    "One strength I bring is \(carryover.lowercased()).",
                    "The strongest signal from my recent work is \(protectedLine.lowercased())",
                    "People usually trust me to \(carryover.lowercased())."
                ]
            default:
                return [
                    "That's why this role feels like the right next step for me.",
                    "It's a fit because I can keep \(protectedLine.lowercased())",
                    "I'm excited to bring that same calm to this team."
                ]
            }
        case .weeklyUpdate:
            switch activePracticeStep {
            case 0:
                return [
                    "Decision: \(protectedLine)",
                    "Quick call: \(protectedLine)",
                    "In one line: \(protectedLine)"
                ]
            case 1:
                return [
                    "The tradeoff is \(carryover.lowercased()).",
                    "The tension to name clearly is \(carryover.lowercased()).",
                    "Right now the constraint is \(carryover.lowercased())."
                ]
            default:
                return [
                    "My next move is to close that gap today.",
                    "I'm handling the next move by \(carryover.lowercased()).",
                    "Next I will send the clean recommendation and confirm timing."
                ]
            }
        case .managerOneOnOne:
            switch activePracticeStep {
            case 0:
                return [
                    "The pattern this week is [clear signal].",
                    "I'm noticing [observed friction] across [specific work moment].",
                    "The recurring signal is \(protectedLine.lowercased())"
                ]
            case 1:
                return [
                    "What is getting sticky is \(carryover.lowercased()).",
                    "I already tightened [one concrete thing], but the friction is still [specific].",
                    "The part I want to name clearly is \(protectedLine.lowercased())"
                ]
            default:
                return [
                    "The help I need is one decision about [scope / support / priority].",
                    "Could we choose between [option A] and [option B] so I can move this cleanly?",
                    "The most useful next move from you is \(carryover.lowercased())."
                ]
            }
        case .presentationOpening:
            switch activePracticeStep {
            case 0:
                return [
                    "Today we're looking at \(protectedLine.lowercased())",
                    "The topic here is simple: \(protectedLine)",
                    "I want to start with one clear idea: \(protectedLine)"
                ]
            case 1:
                return [
                    "The key idea is \(carryover.lowercased()).",
                    "What matters most is \(carryover.lowercased()).",
                    "If you remember one thing, make it this: \(carryover)"
                ]
            default:
                return [
                    "That's the takeaway I want you to leave with.",
                    "So the point to keep is \(protectedLine.lowercased())",
                    "That matters because it changes the next decision you make."
                ]
            }
        case .customerRepair:
            switch activePracticeStep {
            case 0:
                return [
                    "You're right to flag that — let me reset it clearly.",
                    "Thanks for catching that. Here's the cleaner version.",
                    "Let me fix that in one short sentence."
                ]
            case 1:
                return [
                    "The correct detail is \(protectedLine.lowercased())",
                    "What I should have said is \(carryover.lowercased()).",
                    "To restate it clearly: \(protectedLine)"
                ]
            default:
                return [
                    "Does that reset feel clear on your side?",
                    "Can you confirm that version works for you?",
                    "I want to make sure the corrected next step feels clean now."
                ]
            }
        }
    }

    var canMoveToPreviousPracticeStep: Bool {
        activePracticeStep > 0
    }

    var canMoveToNextPracticeStep: Bool {
        activePracticeStep < currentMission.stepLabels.count - 1
    }

    func setActivePracticeStep(_ step: Int) {
        let clampedStep = max(0, min(step, currentMission.stepLabels.count - 1))
        guard activePracticeStep != clampedStep else { return }

        activePracticeStep = clampedStep
        KatieHaptic.selection.play()
        if activePracticeStep != recommendedPracticeStep {
            practiceReturnCue = nil
        }
    }

    func applyRetakeDraftStarter(_ starter: String) {
        draftTranscript = starter
        recorderStatusLine = "Loaded a step starter into the draft. Shape it into your own calmer rep before saving."
        KatieHaptic.selection.play()
    }

    func focusRecommendedPracticeStep() {
        setActivePracticeStep(recommendedPracticeStep)
    }

    func moveToPreviousPracticeStep() {
        setActivePracticeStep(activePracticeStep - 1)
    }

    func moveToNextPracticeStep() {
        setActivePracticeStep(activePracticeStep + 1)
    }

    func continuePracticeFromReview() {
        focusRecommendedPracticeStep()
        practiceReturnCue = PracticeReturnCue(
            title: "Review handoff restored",
            body: "Katie brought you back on \(recommendedPracticeStepLabel.lowercased()) so the next rep keeps the newest unlocked step in focus."
        )
        selectedTab = .practice
        isReviewPresented = false
    }

    func openProgressFromReview() {
        selectedTab = .progress
        isReviewPresented = false
    }

    func toggleRecording() {
        guard !isPreparingRecording else { return }

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    let minimumQuickRepDuration: TimeInterval = 0.35

    func beginPressToRecord() {
        guard !isRecording && !isPreparingRecording else { return }
        startRecording()
    }

    func endPressToRecord() {
        completePressToRecord(after: minimumQuickRepDuration)
    }

    func completePressToRecord(after duration: TimeInterval) {
        guard isRecording else { return }

        if duration < minimumQuickRepDuration {
            discardScratchRecording(statusLine: "Quick rep was too short to keep. Hold for a beat longer so Katie saves an honest local clip.")
            return
        }

        stopRecording()
    }

    func clearDraftRetake() {
        draftTranscript = ""
        latestScratchRecordingDuration = nil
        scratchRecordingURL.flatMap { try? FileManager.default.removeItem(at: $0) }
        scratchRecordingURL = nil
        prepareDraftReflection(resetScores: false)
        recorderStatusLine = "Draft cleared. Ready to record another rep."
    }

    func dismissPracticeReturnCue() {
        practiceReturnCue = nil
    }

    var draftSelfReflection: SessionSelfReflection {
        SessionSelfReflection(
            listenerCatchScore: draftReflectionListenerCatchScore,
            paceControlScore: draftReflectionPaceControlScore,
            confidenceScore: draftReflectionConfidenceScore,
            stickyMoment: draftReflectionStickyMoment
        )
    }

    func stickyMomentOptions(for scenario: PracticeScenario) -> [String] {
        switch scenario {
        case .interviewIntro:
            return ["Opening line", "Role summary", "Fit close", "Final sentence landing"]
        case .weeklyUpdate:
            return ["Decision line", "Tradeoff phrase", "Next-move ask", "Transition between beats"]
        case .managerOneOnOne:
            return ["Pattern line", "Friction sentence", "Support ask", "Decision close"]
        case .presentationOpening:
            return ["First sentence", "Why-it-matters phrase", "Audience handoff", "Ending the opener"]
        case .customerRepair:
            return ["Reset phrase", "Apology line", "Corrected next step", "Confidence in the close"]
        }
    }

    func prepareDraftReflection(resetScores: Bool = false) {
        let defaults = currentScenarioUserHistory.first?.selfReflection ?? SessionSelfReflection(
            listenerCatchScore: 3,
            paceControlScore: 3,
            confidenceScore: 3,
            stickyMoment: stickyMomentOptions(for: currentMission).first ?? "Opening line"
        )

        if resetScores || currentScenarioUserHistory.isEmpty {
            draftReflectionListenerCatchScore = defaults.listenerCatchScore
            draftReflectionPaceControlScore = defaults.paceControlScore
            draftReflectionConfidenceScore = defaults.confidenceScore
        }

        let options = stickyMomentOptions(for: currentMission)
        draftReflectionStickyMoment = options.contains(defaults.stickyMoment) ? defaults.stickyMoment : (options.first ?? "Opening line")
    }

    func saveCurrentRetake() {
        if scratchRecordingURL != nil {
            saveRecordedRetake()
        } else {
            saveDemoRetake(customTranscript: draftTranscript)
            recorderStatusLine = "Saved a text-only retake. Record on-device next to unlock honest replay."
        }
        KatieHaptic.success.play()
        isReviewPresented = true
    }

    func playSession(_ session: PracticeSession) {
        guard let url = audioURL(for: session) else {
            recorderStatusLine = "Audio is not attached for this saved rep on this iPhone."
            currentlyPlayingSessionID = nil
            return
        }

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentlyPlayingSessionID = session.id
            recorderStatusLine = "Playing \(session.title.lowercased())."
        } catch {
            recorderStatusLine = "Playback failed. Katie kept the compare note instead of pretending replay exists."
            currentlyPlayingSessionID = nil
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlayingSessionID = nil
    }

    func scheduleOrDismissReminder() {
        Task {
            if remindersEnabled {
                clearReminderForCurrentScenario()
            } else {
                await enableReminderForCurrentScenario()
            }
        }
    }

    func saveDemoRetake(customTranscript: String? = nil) {
        guard let first = latestSessionOptional else { return }

        let transcript = (customTranscript ?? first.transcript).trimmingCharacters(in: .whitespacesAndNewlines)

        let nextVersion = PracticeSession(
            scenario: currentMission,
            title: "Retake \(currentScenarioUserHistory.count + 1) · momentum follow-through",
            date: .now,
            transcript: transcript.isEmpty ? first.transcript : transcript,
            benchmarkCue: "Replay the cleaner breath before your \(currentMission.title.lowercased()) close.",
            listenerOutcome: currentMission.listenerOutcome,
            structurePrompt: currentMission.structurePrompt,
            highlights: [
                PracticeHighlight(title: "Keep · scenario clarity", detail: "This rep keeps the same scenario structure, so comparison stays honest."),
                PracticeHighlight(title: "Sharpen · opening beat", detail: "One short pause before your key sentence now lands cleaner."),
                PracticeHighlight(title: "Keep · close outcome", detail: "Close now points to one clear next action.")
            ],
            compareReadiness: .transcriptOnly,
            reminderLine: reminderPlanLabel(for: currentMission),
            carryoverLine: first.carryoverLine,
            protectedLine: first.protectedLine,
            unlockedStepCount: min(first.unlockedStepCount + 1, currentMission.stepLabels.count),
            transcriptFootnote: "Synthetic retake created to keep first-win momentum visible in the compare ritual.",
            audioFileName: nil,
            durationSeconds: nil,
            captureSource: .syntheticRetake,
            selfReflection: draftSelfReflection
        )

        let previousUserAnchor = currentScenarioUserHistory.first?.id

        var newHistory = scenarioHistories[currentMission] ?? []
        newHistory.insert(nextVersion, at: 0)
        scenarioHistories[currentMission] = newHistory

        if let previousUserAnchor {
            selectedAnchorByScenario[currentMission] = previousUserAnchor
        } else {
            selectedAnchorByScenario.removeValue(forKey: currentMission)
        }

        ensureAnchorSelection(for: currentMission)
        focusRecommendedPracticeStep()
        prepareDraftReflection()
        persistState()
    }

    func startRecording() {
        guard !isRecording && !isPreparingRecording else { return }

        let requestID = UUID()
        recordingStartRequestID = requestID
        isPreparingRecording = true

        Task {
            defer {
                if recordingStartRequestID == requestID {
                    isPreparingRecording = false
                    recordingStartRequestID = nil
                }
            }

            let permissionGranted = await requestMicrophoneAccessIfNeeded()
            guard recordingStartRequestID == requestID else { return }
            guard permissionGranted else {
                recorderStatusLine = "Microphone access is blocked. Katie keeps the text-only fallback visible instead of pretending replay will save."
                KatieHaptic.warning.play()
                return
            }

            // Request speech recognition auth (needed for filler word detection)
            let speechStatus = await FillerWordDetector.requestAuthorization()
            guard recordingStartRequestID == requestID else { return }

            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
                try session.setActive(true)

                let url = makeScratchRecordingURL()
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44_100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                let recorder = try AVAudioRecorder(url: url, settings: settings)
                recorder.prepareToRecord()
                recorder.record()

                audioRecorder = recorder
                microphonePermissionState = .granted
                scratchRecordingURL = url
                latestScratchRecordingDuration = nil
                isPreparingRecording = false
                isRecording = true
                draftTranscript = latestSession.transcript
                recorderStatusLine = "Recording live on this iPhone. Follow the step rail, then save the retake with replay attached."
                KatieHaptic.softImpact.play()

                // Start real-time filler word detection if speech recognition is authorized.
                // AVAudioRecorder keeps the saved replay file; AudioCaptureEngine owns the single
                // input-node tap used by Speech so live detection does not collide with recording.
                if speechStatus == .authorized {
                    let detector = FillerWordDetector()
                    self.fillerWordDetector = detector

                    self.fillerCountCancellable = detector.$sessionFillerWordCount
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] count in self?.fillerWordCount = count }
                    self.fillerBreakdownCancellable = detector.$sessionFillerWordBreakdown
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] breakdown in self?.fillerWordBreakdown = breakdown }

                    let capture = AudioCaptureEngine()
                    do {
                        try capture.startCapture { inputNode in
                            try detector.startDetecting(from: inputNode)
                        }
                        self.audioCaptureEngine = capture
                    } catch {
                        detector.stopDetecting()
                        self.fillerWordDetector = nil
                        self.fillerCountCancellable = nil
                        self.fillerBreakdownCancellable = nil
                    }
                }
            } catch {
                recordingStartRequestID = nil
                isPreparingRecording = false
                isRecording = false
                refreshMicrophonePermissionState()
                recorderStatusLine = "Microphone capture could not start. Katie keeps the draft path honest instead of faking a recording."
                KatieHaptic.warning.play()
            }
        }
    }

    func stopRecording() {
        recordingStartRequestID = nil
        isPreparingRecording = false
        audioRecorder?.stop()
        latestScratchRecordingDuration = audioRecorder?.currentTime
        audioRecorder = nil
        isRecording = false

        if let capture = audioCaptureEngine {
            latestScratchRecordingDuration = capture.stopCapture()
        }
        audioCaptureEngine = nil
        fillerWordDetector?.stopDetecting()
        fillerWordDetector = nil
        fillerCountCancellable = nil
        fillerBreakdownCancellable = nil

        if draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftTranscript = latestSession.transcript
        }

        if let latestScratchRecordingDuration {
            recorderStatusLine = "Recorded \(String(format: "%.0f", latestScratchRecordingDuration))s on this iPhone. Save to add honest replay to Review and Progress."
        } else {
            recorderStatusLine = "Recording stopped. Save the retake to keep replay attached."
        }
        KatieHaptic.softImpact.play()
    }

    func discardScratchRecording(
        statusLine: String,
        clearDraft: Bool = false,
        playWarningHaptic: Bool = true
    ) {
        recordingStartRequestID = nil
        isPreparingRecording = false
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        latestScratchRecordingDuration = nil
        if let capture = audioCaptureEngine {
            _ = capture.stopCapture()
        }
        audioCaptureEngine = nil
        fillerWordDetector?.stopDetecting()
        fillerWordDetector = nil
        fillerCountCancellable = nil
        fillerBreakdownCancellable = nil

        if let scratchRecordingURL {
            try? FileManager.default.removeItem(at: scratchRecordingURL)
        }
        scratchRecordingURL = nil
        fillerWordCount = 0
        fillerWordBreakdown = [:]
        if clearDraft {
            draftTranscript = ""
        }
        recorderStatusLine = statusLine
        if playWarningHaptic {
            KatieHaptic.warning.play()
        }
    }

    private func saveRecordedRetake() {
        guard let scratchRecordingURL else {
            saveDemoRetake(customTranscript: draftTranscript)
            return
        }
        guard let first = latestSessionOptional else { return }

        let permanentFileName = "\(currentMission.rawValue)-\(UUID().uuidString).m4a"
        let permanentURL = recordingsDirectory().appendingPathComponent(permanentFileName)

        do {
            if FileManager.default.fileExists(atPath: permanentURL.path()) {
                try FileManager.default.removeItem(at: permanentURL)
            }
            try FileManager.default.moveItem(at: scratchRecordingURL, to: permanentURL)
        } catch {
            recorderStatusLine = "Katie could not save the recording file, so the retake stayed out of compare history."
            KatieHaptic.warning.play()
            return
        }

        let transcript = draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextVersion = PracticeSession(
            scenario: currentMission,
            title: "Recorded retake \(currentScenarioUserHistory.count + 1) · replay-ready",
            date: .now,
            transcript: transcript.isEmpty ? first.transcript : transcript,
            benchmarkCue: "Replay the cleaner breath before your \(currentMission.title.lowercased()) close.",
            listenerOutcome: currentMission.listenerOutcome,
            structurePrompt: currentMission.structurePrompt,
            highlights: [
                PracticeHighlight(title: "Keep · real playback attached", detail: "This saved retake keeps an on-device recording, so before/after compare can stay honest."),
                PracticeHighlight(title: "Sharpen · shorter proof line", detail: "Keep the protected line compact so your replay difference is easier to feel."),
                PracticeHighlight(title: "Keep · scenario continuity", detail: "This retake stays attached to the same scenario rail and reminder story.")
            ],
            compareReadiness: .audioReady,
            reminderLine: reminderPlanLabel(for: currentMission),
            carryoverLine: first.carryoverLine,
            protectedLine: first.protectedLine,
            unlockedStepCount: min(first.unlockedStepCount + 1, currentMission.stepLabels.count),
            transcriptFootnote: "Recorded on this iPhone with local replay saved for compare.",
            audioFileName: permanentFileName,
            durationSeconds: latestScratchRecordingDuration,
            captureSource: .recorded,
            selfReflection: draftSelfReflection
        )

        let previousUserAnchor = currentScenarioUserHistory.first?.id

        var newHistory = scenarioHistories[currentMission] ?? []
        newHistory.insert(nextVersion, at: 0)
        scenarioHistories[currentMission] = newHistory

        if let previousUserAnchor {
            selectedAnchorByScenario[currentMission] = previousUserAnchor
        } else {
            selectedAnchorByScenario.removeValue(forKey: currentMission)
        }

        ensureAnchorSelection(for: currentMission)
        focusRecommendedPracticeStep()
        draftTranscript = ""
        latestScratchRecordingDuration = nil
        self.scratchRecordingURL = nil
        prepareDraftReflection()
        recorderStatusLine = "Saved a replay-ready retake for \(currentMission.title.lowercased())."
        persistState()
    }

    func selectScenario(_ scenario: PracticeScenario) {
        guard (!isRecording && !isPreparingRecording) || scenario == currentMission else {
            recorderStatusLine = recordingLockLine
            KatieHaptic.warning.play()
            return
        }
        let didChangeScenario = currentMission != scenario
        currentMission = scenario
        ensureAnchorSelection(for: scenario)
        focusRecommendedPracticeStep()
        prepareDraftReflection(resetScores: false)
        practiceReturnCue = nil
        if didChangeScenario {
            KatieHaptic.selection.play()
        }
        persistState()
    }

    var quickRepRail: [QuickRepPrompt] {
        PracticeScenario.allCases
            .sorted { lhs, rhs in
                let recommended = recommendedScenarioForCurrentContext
                if lhs == recommended { return true }
                if rhs == recommended { return false }
                if lhs == currentMission { return true }
                if rhs == currentMission { return false }
                return lhs.title < rhs.title
            }
            .map { scenario in
                let starter = sampleSession(for: scenario).protectedLine
                let isRecommended = scenario == recommendedScenarioForCurrentContext
                let history = scenarioHistories[scenario] ?? []
                let userOwnedHistory = history.filter(\.isUserOwned)
                let ownedCount = userOwnedHistory.count
                let latestOwned = userOwnedHistory.first
                let replayReadyCount = userOwnedHistory.filter { hasPlayback(for: $0) }.count

                let hasStarterProof = history.contains(where: { $0.captureSource == .seeded || $0.captureSource == .imported })

                let statusLabel: String
                if ownedCount == 0 {
                    statusLabel = hasStarterProof ? "Starter proof, not final" : "First save sets benchmark"
                } else if ownedCount == 1 {
                    statusLabel = replayReadyCount > 0 ? "1 proof · replay ready" : "1 proof · transcript first"
                } else if replayReadyCount > 0 {
                    statusLabel = "\(ownedCount) reps · compare warm"
                } else {
                    statusLabel = "\(ownedCount) reps · transcript trail"
                }

                let proofLine = quickRepProofRunwayLine(for: scenario, latestOwned: latestOwned)

                let hypothesisStatusLabel = transferHypothesisStatusTitle
                let hypothesisDetailLine = quickRepHypothesisDetailLine(latestOwned: latestOwned)

                let continuityLine: String
                if let reminderPlan, reminderPlan.scenario == scenario {
                    continuityLine = "Reminder on · \(Self.reminderFormatter.string(from: reminderPlan.fireDate))"
                } else if let reminderPlan {
                    continuityLine = "Reminder is protecting \(reminderPlan.scenario.packTitle)."
                } else if ownedCount > 0 {
                    continuityLine = "No reminder yet. Add one when this conversation needs a protected line."
                } else {
                    continuityLine = "Save one rep first, then Katie can pin a real reminder line here."
                }

                return QuickRepPrompt(
                    scenario: scenario,
                    title: scenario.title,
                    detail: isRecommended
                        ? "Best match for today’s context · 60–90 sec · one clean rep"
                        : "60–90 sec · one clean rep with no setup",
                    durationLabel: "60–90 sec",
                    starterLine: starter,
                    statusLabel: statusLabel,
                    hypothesisStatusLabel: hypothesisStatusLabel,
                    hypothesisDetailLine: hypothesisDetailLine,
                    proofLine: proofLine,
                    continuityLine: continuityLine
                )
            }
    }

    func quickRepRunwaySteps(for scenario: PracticeScenario) -> [QuickRepRunwayStepDescriptor] {
        let history = scenarioHistories[scenario] ?? []
        let userOwnedHistory = history.filter(\.isUserOwned)
        let replayReadyCount = userOwnedHistory.filter { hasPlayback(for: $0) }.count
        let hasStarterProof = history.contains { $0.captureSource == .seeded || $0.captureSource == .imported }
        let reminderProtected = reminderPlan?.scenario == scenario

        if userOwnedHistory.isEmpty {
            return [
                QuickRepRunwayStepDescriptor(
                    title: "Save one real line",
                    detail: hasStarterProof
                        ? "Replace the starter proof with your own benchmark for this pack."
                        : "Create the first benchmark so this pack stops reading like a placeholder.",
                    systemImage: "1.circle.fill",
                    accent: .gold
                ),
                QuickRepRunwayStepDescriptor(
                    title: "Katie switches to your proof",
                    detail: "\(quickRepSharedRunwaySurfaceList) start following your saved line instead of starter or carried-over proof.",
                    systemImage: "arrow.triangle.branch",
                    accent: .accent
                ),
                QuickRepRunwayStepDescriptor(
                    title: reminderProtected ? "Reminder reuses that line" : "Then protect it with a reminder",
                    detail: reminderProtected
                        ? "The next reminder already points back to this exact conversation line."
                        : "If this conversation matters again soon, pin the benchmark so Katie brings back the same line later.",
                    systemImage: reminderProtected ? "bell.badge.fill" : "bell.fill",
                    accent: .mint
                )
            ]
        }

        if userOwnedHistory.count == 1 {
            return [
                QuickRepRunwayStepDescriptor(
                    title: "Your benchmark is live",
                    detail: replayReadyCount > 0
                        ? "\(quickRepSharedRunwaySurfaceList) are already following a replay-ready benchmark saved on this iPhone."
                        : "\(quickRepSharedRunwaySurfaceList) are already following your saved benchmark, even while replay stays transcript-first here.",
                    systemImage: "checkmark.circle.fill",
                    accent: .mint
                ),
                QuickRepRunwayStepDescriptor(
                    title: "One more rep unlocks compare",
                    detail: "Stay with this same pack and Katie can show the before-vs-now shift honestly.",
                    systemImage: "2.circle.fill",
                    accent: .gold
                ),
                QuickRepRunwayStepDescriptor(
                    title: reminderProtected ? "Reminder is already keeping it warm" : "Optional next step: add one reminder",
                    detail: reminderProtected
                        ? "The next reminder is already protecting this benchmark for the live conversation."
                        : "Once this is the line you want in the real moment, add one reminder to keep it easy to revisit.",
                    systemImage: reminderProtected ? "bell.badge.fill" : "bell",
                    accent: .accent
                )
            ]
        }

        return [
            QuickRepRunwayStepDescriptor(
                title: "Compare story is already warm",
                detail: replayReadyCount > 0
                    ? "\(quickRepSharedRunwaySurfaceList) already share enough replay-ready proof to keep the contrast grounded and quick."
                    : "\(quickRepSharedRunwaySurfaceList) already share an honest retake trail, even while replay remains transcript-first on this iPhone.",
                systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                accent: .mint
            ),
            QuickRepRunwayStepDescriptor(
                title: "Use the next rep to sharpen",
                detail: "Keep one calmer version of the same line so the next live conversation feels easier to land.",
                systemImage: "sparkles",
                accent: .gold
            ),
            QuickRepRunwayStepDescriptor(
                title: reminderProtected ? "Reminder keeps the protected line live" : "Add a reminder only if this line matters again soon",
                detail: reminderProtected
                    ? "Katie already has a reminder tied to this conversation, so the same line comes back at the right time."
                    : "You do not need more scaffolding unless this exact line needs to come back before a real conversation.",
                systemImage: reminderProtected ? "bell.badge.fill" : "bell",
                accent: .accent
            )
        ]
    }

    private func quickRepProofRunwayLine(for scenario: PracticeScenario, latestOwned: PracticeSession?) -> String {
        let history = scenarioHistories[scenario] ?? []

        if let latestOwned {
            let freshness = freshnessLabel(for: latestOwned)
            if hasPlayback(for: latestOwned) {
                return "Latest proof: \(freshness), replay-ready on this iPhone, so \(quickRepSharedRunwaySurfaceList) are all grounding the same benchmark before Review compares it."
            }

            return "Latest proof: \(freshness), so \(quickRepSharedRunwaySurfaceList) already follow your own benchmark even while replay stays transcript-first here."
        }

        if history.contains(where: { $0.captureSource == .seeded || $0.captureSource == .imported }) {
            return "Starter proof is still visible. Save one real rep so \(quickRepSharedBenchmarkSurfaceList) can point to your own benchmark."
        }

        return "This pack wakes up after your first sample. Save one short rep so \(quickRepSharedBenchmarkSurfaceList) can follow a real line instead of a placeholder."
    }

    private var quickRepSharedRunwaySurfaceList: String {
        "Today, Practice, and Coach"
    }

    private var quickRepSharedBenchmarkSurfaceList: String {
        "Today, Practice, Coach, and reminders"
    }

    private func quickRepHypothesisDetailLine(latestOwned: PracticeSession?) -> String {
        if let reflection = latestOwned?.selfReflection {
            return "Latest self-check here · listener \(reflection.listenerCatchScore)/5 · pace \(reflection.paceControlScore)/5 · confidence \(reflection.confidenceScore)/5"
        }

        switch transferHypothesisFeedback {
        case .soundsLikeMe:
            return "Starting cue stays visible, but this pack still needs one saved rep to keep or correct it."
        case .notSureYet:
            return "Keep this cue light until this pack has one saved rep to confirm or correct it."
        case .notMyMainIssue:
            return "Use this as background context until this pack has one saved rep to set the real plan."
        }
    }

    func openPractice(for scenario: PracticeScenario? = nil) {
        if let scenario {
            selectScenario(scenario)
        }
        prepareDraftReflection(resetScores: false)
        selectedTab = .practice
    }

    private func observeReminderNotificationTaps() {
        reminderNotificationObserver = NotificationCenter.default.addObserver(
            forName: .katieReminderTapped,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleReminderNotificationTap(notification)
            }
        }
    }

    private func handleReminderNotificationTap(_ notification: Notification) {
        let scenario: PracticeScenario

        if let scenarioID = notification.userInfo?["scenarioID"] as? String,
           let matchedScenario = availableScenarios.first(where: { $0.rawValue == scenarioID }) {
            scenario = matchedScenario
        } else if let reminderScenario = reminderPlan?.scenario {
            scenario = reminderScenario
        } else {
            scenario = currentMission
        }

        openPractice(for: scenario)
        practiceReturnCue = PracticeReturnCue(
            title: "Reminder handoff restored",
            body: "Katie opened \(scenario.packTitle) from the reminder, so the next rep stays on the protected pack with \(recommendedPracticeStepLabel.lowercased()) in focus."
        )
    }

    func launchQuickChallenge() {
        let scenario = quickChallengeScenario
        selectScenario(scenario)
        focusRecommendedPracticeStep()
        applyRetakeDraftStarter(quickRepStarterLine(for: scenario))
        prepareDraftReflection(resetScores: false)
        practiceReturnCue = PracticeReturnCue(
            title: "1-minute challenge loaded",
            body: "Katie loaded \(scenario.title) with \(recommendedPracticeStepLabel.lowercased()) in focus. Give one calm pass, protect one listener-critical line, then stop."
        )
        selectedTab = .practice
        recorderStatusLine = "1-minute challenge loaded. One calm pass, one protected line, then save or retake."
    }

    func launchQuickRep(for scenario: PracticeScenario) {
        selectScenario(scenario)
        applyRetakeDraftStarter(quickRepStarterLine(for: scenario))
        prepareDraftReflection(resetScores: false)
        selectedTab = .practice
        recorderStatusLine = "Quick rep loaded. Take one short pass, then decide if you want to record it."
    }

    func openProgress(for scenario: PracticeScenario? = nil) {
        if let scenario {
            selectScenario(scenario)
        }
        selectedTab = .progress
    }

    func openReview(for scenario: PracticeScenario? = nil, anchor: PracticeSession? = nil) {
        if let scenario {
            selectScenario(scenario)
        }
        if let anchor {
            selectedAnchorByScenario[currentMission] = anchor.id
        }
        selectedTab = .progress
        isReviewPresented = true
        persistState()
    }

    func presentReview() {
        practiceReturnCue = nil
        isReviewPresented = true
    }

    func persistSelectedTab() {
        persistState()
    }

    func selectCompareAnchor(_ session: PracticeSession) {
        selectedAnchorByScenario[currentMission] = session.id
        persistState()
    }

    func saveFirstWinFallbackIfNeeded() {
        guard activeScenarioUserRepCount == 0 else { return }
        let suggestedTranscript = draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? latestSession.transcript : draftTranscript
        saveDemoRetake(customTranscript: suggestedTranscript)
        recorderStatusLine = "Saved your first proof as text-only because microphone access is blocked on this iPhone. Record here later to attach honest replay."
    }

    func isSelectedAnchor(_ session: PracticeSession) -> Bool {
        selectedCompareAnchor?.id == session.id
    }

    func userOwnedSessionCount(in scenario: PracticeScenario) -> Int {
        userOwnedSessionCount(for: scenario)
    }

    private func todayQueuePriority(for entry: TodayQueueEntry) -> Int {
        switch entry.action {
        case .recordFirstRep, .recordFreshProof:
            return entry.scenario == learnerProfile.focusScenario ? 0 : 1
        case .enableReminder:
            return entry.scenario == learnerProfile.focusScenario ? 2 : 3
        case .openProof:
            return entry.scenario == learnerProfile.focusScenario ? 4 : 5
        case .keepWarm:
            return entry.scenario == learnerProfile.focusScenario ? 6 : 7
        case .openCompare:
            return entry.scenario == learnerProfile.focusScenario ? 8 : 9
        }
    }

    func scenarioStatusLabel(for scenario: PracticeScenario) -> String {
        let ownedCount = userOwnedSessionCount(for: scenario)
        switch ownedCount {
        case 0:
            return "First proof"
        case 1:
            return "Benchmark saved"
        case 2:
            return "Live compare"
        default:
            return "Warm"
        }
    }

    func scenarioStatusDetail(for scenario: PracticeScenario) -> String {
        let history = scenarioHistories[scenario] ?? []
        let latest = history.first(where: \.isUserOwned) ?? history.first
        let recordedCount = history.filter { $0.captureSource == .recorded }.count
        let replayReadyCount = history.filter { $0.isUserOwned && hasPlayback(for: $0) }.count
        let seededCount = history.filter { $0.captureSource == .seeded }.count
        let importedCount = history.filter { $0.captureSource == .imported }.count
        let textRetakeCount = history.filter { $0.captureSource == .syntheticRetake }.count

        func countLabel(_ count: Int, singular: String) -> String {
            "\(count) \(singular)\(count == 1 ? "" : "s")"
        }

        if recordedCount > 0 {
            let localTruth = "\(countLabel(recordedCount, singular: "recording")) on this iPhone · \(replayReadyCount) replay-ready"

            guard importedCount > 0 else {
                return localTruth
            }

            return "\(localTruth) · \(countLabel(importedCount, singular: "imported continuity rep")) secondary"
        }

        if textRetakeCount > 0 {
            let textTruth = "\(countLabel(textRetakeCount, singular: "text retake")) saved here"

            if importedCount > 0 {
                return "\(textTruth) · \(countLabel(importedCount, singular: "imported continuity rep")) still carrying the pack until you record"
            }

            if seededCount > 0 {
                return "\(textTruth) · starter proof is still visible until you record a fresh clip"
            }

            return "\(textTruth) · replay still needs one fresh local clip"
        }

        if importedCount > 0 {
            let importedTruth = "\(countLabel(importedCount, singular: "imported continuity rep")) carried over here"

            if seededCount > 0 {
                return "\(importedTruth) · starter proof stays secondary until you record"
            }

            return "\(importedTruth) · replay still needs one fresh local recording"
        }

        if userOwnedSessionCount(for: scenario) == 0 {
            if seededCount > 0 {
                return "Starter proof is still leading this pack until you save your own rep."
            }
            return "Save one rep to make this pack yours."
        }

        return latest.map(displayCompareReadinessDetail(for:)) ?? scenario.continuityPromise
    }

    func scenarioReminderLine(for scenario: PracticeScenario) -> String {
        guard let reminderPlan else {
            return "No reminder tied to this pack yet"
        }

        if reminderPlan.scenario == scenario {
            return "Reminder set · \(Self.reminderFormatter.string(from: reminderPlan.fireDate))"
        }

        return "Reminder is protecting \(reminderPlan.scenario.packTitle)"
    }

    func todayReminderCue(for scenario: PracticeScenario) -> TodayReminderCue {
        let line = latestSession(in: scenario)?.protectedLine ?? sampleSession(for: scenario).protectedLine

        if let reminderPlan, reminderPlan.scenario == scenario {
            return TodayReminderCue(
                eyebrow: "Next nudge · \(Self.reminderFormatter.string(from: reminderPlan.fireDate))",
                title: reminderNotificationTitle(for: reminderPlan),
                body: reminderNotificationBody(for: reminderPlan),
                systemImage: reminderPermissionState == .granted ? "bell.badge.fill" : "bell.slash.fill",
                isActive: reminderPermissionState == .granted
            )
        }

        if let reminderPlan {
            return TodayReminderCue(
                eyebrow: "Protected elsewhere · \(reminderPlan.scenario.packTitle)",
                title: "This pack is warm, but another one owns the next reminder",
                body: "If this becomes the live priority, move the nudge here so Katie can reuse: \"\(line)\"",
                systemImage: "arrow.triangle.branch",
                isActive: false
            )
        }

        return TodayReminderCue(
            eyebrow: userOwnedSessionCount(for: scenario) > 0 ? "Lock Screen preview" : "First save unlocks a cue",
            title: userOwnedSessionCount(for: scenario) > 0
                ? "Protect this pack with one glanceable cue"
                : "Save one real rep before Katie nudges this pack",
            body: userOwnedSessionCount(for: scenario) > 0
                ? "Katie can nudge your saved line on the lock screen: \"\(line)\""
                : "Your first owned benchmark gives Katie a real line to pin, not generic motivation.",
            systemImage: userOwnedSessionCount(for: scenario) > 0 ? "bell.and.waves.left.and.right" : "sparkles",
            isActive: false
        )
    }

    func scenarioNextStepLine(for scenario: PracticeScenario) -> String {
        groundedNextStepLine(for: scenario, includePrefix: true)
    }

    private func groundedNextStepLine(for scenario: PracticeScenario, includePrefix: Bool) -> String {
        let prefix = includePrefix ? "Next: " : ""
        let history = scenarioHistories[scenario] ?? []
        let userOwnedHistory = history.filter(\.isUserOwned)
        let ownedCount = userOwnedHistory.count
        let latestOwned = userOwnedHistory.first
        let latestOwnedHasReplay = latestOwned.map(hasPlayback(for:)) ?? false
        let hasAnyReplayReady = userOwnedHistory.contains { hasPlayback(for: $0) }

        if ownedCount == 0 {
            if microphonePermissionState == .denied {
                return "\(prefix)save one text-only rep so starter proof stops leading this pack, then record here later to attach honest replay."
            }

            return "\(prefix)save one rep so starter proof stops leading this pack and your own benchmark can take the lead."
        }

        if ownedCount == 1 {
            if latestOwnedHasReplay {
                return "\(prefix)retake once so this becomes a real before/after compare with your own voice on both sides."
            }

            if microphonePermissionState == .denied {
                return "\(prefix)retake once so this becomes a real before/after transcript trail, then record here later when you want replay on both sides."
            }

            return "\(prefix)record one fresh local retake so this becomes a real before/after compare and starts restoring replay on this iPhone."
        }

        if reminderPlan?.scenario != scenario {
            return "\(prefix)tie one reminder to this benchmark so the real conversation gets the same protected line back."
        }

        if latestOwnedHasReplay {
            return "\(prefix)replay the latest saved line, then record one tighter follow-through."
        }

        if microphonePermissionState == .denied {
            return "\(prefix)keep this pack warm with one shorter text-first retake. Review and Progress will stay honest about replay until you record here again."
        }

        if hasAnyReplayReady {
            return "\(prefix)record one fresh local retake so the newest proof can replay here again, then tighten the follow-through."
        }

        return "\(prefix)record one fresh local retake so this pack stops reading transcript-first and regains honest replay on this iPhone."
    }

    func freshnessLabel(for session: PracticeSession) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(session.date) {
            return "Today"
        }
        if calendar.isDateInYesterday(session.date) {
            return "Yesterday"
        }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), session.date >= weekAgo {
            return "This week"
        }
        return "Older"
    }

    func hasPlayback(for session: PracticeSession) -> Bool {
        audioURL(for: session) != nil
    }

    func deleteAllOnDeviceData() {
        stopPlayback()
        recordingStartRequestID = nil
        audioRecorder?.stop()
        isPreparingRecording = false
        isRecording = false
        latestScratchRecordingDuration = nil
        draftTranscript = ""
        scratchRecordingURL = nil

        clearAllLocalRecordings()

        if let reminderPlan {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderPlan.requestIdentifier])
        }

        UserDefaults.standard.removeObject(forKey: Self.persistenceKey)
        reminderPlan = nil
        hasCompletedOnboarding = false
        hasDismissedFirstBaselineGate = false
        learnerProfile = LearnerProfile()
        currentMission = .weeklyUpdate
        availableScenarios = PracticeScenario.allCases
        premiumAccessState = .locked
        scenarioHistories = Self.buildScenarioHistories()
        selectedAnchorByScenario = [:]
        activePracticeStep = 0
        currentlyPlayingSessionID = nil
        recorderStatusLine = "All local Katie data was cleared from this iPhone. Seeded starter reps remain so the product shell still demonstrates the compare loop honestly."
        pocketCopyStatusLine = nil
        ensureAnchorSelection(for: currentMission)
        refreshReminderPermissionState()
        refreshMicrophonePermissionState()
    }

    private func clearAllLocalRecordings() {
        let directory = recordingsDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func ensureAnchorSelection(for scenario: PracticeScenario) {
        guard selectedAnchorByScenario[scenario] == nil else { return }
        if let defaultAnchor = scenarioHistories[scenario]?.dropFirst().first {
            selectedAnchorByScenario[scenario] = defaultAnchor.id
        }
    }

    private func enableReminderForCurrentScenario() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        let previousPlan = reminderPlan

        if granted == true {
            reminderPermissionState = .granted

            let plan: ReminderPlan
            if let previousPlan, previousPlan.scenario != currentMission {
                plan = ReminderPlan(scenario: currentMission, fireDate: previousPlan.fireDate)
                reminderFlowMessage = ReminderFlowMessage(
                    title: "Reminder moved to \(currentMission.packTitle)",
                    body: "Same time kept, now protecting this pack instead of \(previousPlan.scenario.packTitle.lowercased())."
                )
            } else {
                let fireDate = previousPlan?.scenario == currentMission
                    ? (previousPlan?.fireDate ?? Self.defaultReminderDate(from: .now))
                    : Self.defaultReminderDate(from: .now)
                plan = ReminderPlan(scenario: currentMission, fireDate: fireDate)
                reminderFlowMessage = ReminderFlowMessage(
                    title: "Reminder protecting this pack",
                    body: "Katie will nudge this pack on \(Self.reminderFormatter.string(from: fireDate)) with your saved line."
                )
            }

            clearAllReminderRequests(except: plan.requestIdentifier)
            reminderPlan = plan
            await scheduleReminder(plan)
            KatieHaptic.success.play()
            persistState()
            return
        }

        reminderPermissionState = .denied
        reminderPlan = previousPlan
        reminderFlowMessage = ReminderFlowMessage(
            title: "Reminders still need permission",
            body: "The plan stays visible here, but iPhone notifications are off so no nudge can fire yet."
        )
        KatieHaptic.warning.play()
        persistState()
    }

    private func clearReminderForCurrentScenario() {
        guard let reminderPlan, reminderPlan.scenario == currentMission else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderPlan.requestIdentifier])
        self.reminderPlan = nil
        reminderFlowMessage = ReminderFlowMessage(
            title: "Reminder paused",
            body: "The saved line stays with this pack, ready to arm again anytime."
        )
        KatieHaptic.selection.play()
        persistState()
    }

    private func scheduleReminder(_ plan: ReminderPlan) async {
        let content = UNMutableNotificationContent()
        content.title = reminderNotificationTitle(for: plan)
        content.body = reminderNotificationBody(for: plan)
        content.sound = .default
        content.userInfo = [
            "scenarioID": plan.scenario.rawValue,
            "protectedLine": latestSession.protectedLine
        ]

        let interval = max(plan.fireDate.timeIntervalSinceNow, 5)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: plan.requestIdentifier, content: content, trigger: trigger)

        clearAllReminderRequests(except: plan.requestIdentifier)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func clearAllReminderRequests(except retainedIdentifier: String? = nil) {
        let identifiers: [String] = PracticeScenario.allCases
            .map { "katie.reminder.\($0.rawValue)" }
            .filter { identifier in
                guard let retainedIdentifier else { return true }
                return identifier != retainedIdentifier
            }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func refreshReminderPermissionState() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                reminderPermissionState = .granted
            case .denied:
                reminderPermissionState = .denied
            case .notDetermined:
                reminderPermissionState = .unknown
            @unknown default:
                reminderPermissionState = .unknown
            }
        }
    }

    private func refreshMicrophonePermissionState() {
        microphonePermissionState = microphonePermissionStateFromSystem()
    }

    private func microphonePermissionStateFromSystem() -> MicrophonePermissionState {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private func requestMicrophoneAccessIfNeeded() async -> Bool {
        let currentState = microphonePermissionStateFromSystem()
        microphonePermissionState = currentState

        switch currentState {
        case .granted:
            return true
        case .denied:
            return false
        case .unknown:
            break
        }

        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { isGranted in
                    continuation.resume(returning: isGranted)
                }
            }
        } else {
            granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { isGranted in
                    continuation.resume(returning: isGranted)
                }
            }
        }

        microphonePermissionState = granted ? .granted : .denied
        return granted
    }

    private func syncPremiumStoreStatus() {
        premiumStoreStatus = premiumStore.status
    }

    private func syncPremiumAccessFromStore() async {
        await premiumStore.refreshEntitlements()
        syncPremiumStoreStatus()

        if premiumStore.hasActiveEntitlement {
            premiumAccessState = .entitled
            return
        }
        if case .pendingApproval = premiumStore.status {
            if premiumAccessState == .entitled {
                premiumAccessState = .locked
            }
            return
        }
        if case .ready = premiumStore.status {
            if premiumAccessState == .entitled {
                premiumAccessState = .locked
            }
            return
        }
        if premiumAccessState == .entitled {
            premiumAccessState = .locked
        }
    }

    private func reminderPlanLabel(for scenario: PracticeScenario) -> String {
        guard let reminderPlan, reminderPlan.scenario == scenario else {
            return latestSession(in: scenario)?.reminderLine ?? sampleSession(for: scenario).reminderLine
        }
        return "\(Self.reminderFormatter.string(from: reminderPlan.fireDate)) · \(reminderTone.detail)"
    }

    private func reminderNotificationTitle(for plan: ReminderPlan) -> String {
        switch reminderTone {
        case .calm:
            return "Take one breath, then replay your \(plan.scenario.packTitle.lowercased()) line"
        case .workday:
            return "Replay your \(plan.scenario.packTitle.lowercased()) line"
        case .beforeMeeting:
            return "Pocket reset before your \(plan.scenario.packTitle.lowercased())"
        }
    }

    private func quickRepStarterLine(for scenario: PracticeScenario) -> String {
        let sample = sampleSession(for: scenario)
        return switch scenario {
        case .interviewIntro:
            "Quick rep: \(sample.protectedLine)"
        case .weeklyUpdate:
            "Quick rep: \(sample.protectedLine)"
        case .managerOneOnOne:
            "Quick rep: \(sample.protectedLine)"
        case .presentationOpening:
            "Quick rep: \(sample.protectedLine)"
        case .customerRepair:
            "Quick rep: \(sample.protectedLine)"
        }
    }

    private func reminderNotificationBody(for plan: ReminderPlan) -> String {
        let line = latestSession(in: plan.scenario)?.protectedLine ?? sampleSession(for: plan.scenario).protectedLine

        switch reminderTone {
        case .calm:
            return "One calm rep is enough today: \"\(line)\""
        case .workday:
            return "Use this saved line: \"\(line)\""
        case .beforeMeeting:
            return "Quick pre-call cue: \"\(line)\""
        }
    }

    private func userOwnedSessionCount(for scenario: PracticeScenario) -> Int {
        (scenarioHistories[scenario] ?? []).filter(\.isUserOwned).count
    }

    private var latestSessionOptional: PracticeSession? {
        currentScenarioUserHistory.first ?? currentScenarioStarterHistory.first
    }

    private func latestSession(in scenario: PracticeScenario) -> PracticeSession? {
        let history = scenarioHistories[scenario] ?? []
        return history.first(where: \.isUserOwned) ?? history.first
    }

    private func restorePersistedState() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey),
              let decoded = try? JSONDecoder().decode(PersistedKatieState.self, from: data) else {
            return false
        }

        hasCompletedOnboarding = decoded.hasCompletedOnboarding
        hasDismissedFirstBaselineGate = decoded.hasDismissedFirstBaselineGate
        learnerProfile = decoded.learnerProfile
        currentMission = decoded.currentMission
        selectedTab = decoded.selectedTab
        premiumAccessState = decoded.premiumAccessState
        reminderPlan = decoded.reminderPlan
        reminderTone = decoded.reminderTone
        scenarioHistories = decoded.scenarioHistories
        selectedAnchorByScenario = decoded.selectedAnchorByScenario
        return true
    }

    private func persistState() {
        let state = PersistedKatieState(
            hasCompletedOnboarding: hasCompletedOnboarding,
            hasDismissedFirstBaselineGate: hasDismissedFirstBaselineGate,
            learnerProfile: learnerProfile,
            currentMission: currentMission,
            selectedTab: selectedTab,
            premiumAccessState: premiumAccessState,
            reminderPlan: reminderPlan,
            reminderTone: reminderTone,
            scenarioHistories: scenarioHistories,
            selectedAnchorByScenario: selectedAnchorByScenario
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: Self.persistenceKey)
    }

    private func normalizedImportedHistories(from histories: [PracticeScenario: [PracticeSession]]) -> [PracticeScenario: [PracticeSession]] {
        var normalized: [PracticeScenario: [PracticeSession]] = [:]

        for scenario in PracticeScenario.allCases {
            let imported = (histories[scenario] ?? []).map { session in
                normalizedImportedSession(session)
            }
            normalized[scenario] = imported.isEmpty ? (Self.buildScenarioHistories()[scenario] ?? []) : imported.sorted(by: { $0.date > $1.date })
        }

        return normalized
    }

    private func normalizedImportedSession(_ session: PracticeSession) -> PracticeSession {
        var normalized = session
        normalized.audioFileName = nil

        switch session.captureSource {
        case .seeded:
            normalized.compareReadiness = .transcriptOnly
        case .recorded, .imported:
            normalized.captureSource = .imported
            normalized.compareReadiness = .transferredWithoutAudio
        case .syntheticRetake:
            normalized.captureSource = .imported
            normalized.compareReadiness = .transcriptOnly
        }

        normalized.transcriptFootnote = "Pocket copy restored on this iPhone. Coaching continuity came over, but replay audio did not."
        return normalized
    }

    private func sanitizedImportedAnchors(_ anchors: [PracticeScenario: UUID], histories: [PracticeScenario: [PracticeSession]]) -> [PracticeScenario: UUID] {
        var sanitized: [PracticeScenario: UUID] = [:]

        for scenario in PracticeScenario.allCases {
            let sessions = histories[scenario] ?? []
            if let anchor = anchors[scenario], sessions.contains(where: { $0.id == anchor }) {
                sanitized[scenario] = anchor
            } else if let fallback = sessions.dropFirst().first?.id {
                sanitized[scenario] = fallback
            }
        }

        return sanitized
    }

    private func sampleSession(for scenario: PracticeScenario) -> PracticeSession {
        if let session = scenarioHistories[scenario]?.first {
            return session
        }

        let seededHistories = Self.buildScenarioHistories()
        if let session = seededHistories[scenario]?.first {
            return session
        }

        if let fallback = seededHistories[.weeklyUpdate]?.first {
            return fallback
        }

        return Self.placeholderSampleSession(for: scenario)
    }

    private static func placeholderSampleSession(for scenario: PracticeScenario) -> PracticeSession {
        PracticeSession(
            scenario: scenario,
            title: "Starter proof",
            date: .now,
            transcript: scenario.missionPrompt,
            benchmarkCue: "Keep the line short enough to replay and compare later.",
            listenerOutcome: scenario.listenerOutcome,
            structurePrompt: scenario.structurePrompt,
            highlights: [
                PracticeHighlight(title: "Keep · starter line", detail: "Katie keeps this fallback visible without pretending it is earned proof."),
                PracticeHighlight(title: "Sharpen · local replay", detail: "Record one fresh pass on this iPhone when you want replay-ready proof.")
            ],
            compareReadiness: .transcriptOnly,
            reminderLine: "Record one fresh local pass when you are ready.",
            carryoverLine: "Use one calm breath before the key line.",
            protectedLine: scenario.missionPrompt,
            unlockedStepCount: 1,
            transcriptFootnote: "Fallback starter text only; no replay audio is attached.",
            audioFileName: nil,
            durationSeconds: nil,
            captureSource: .seeded
        )
    }

    private static func defaultReminderDate(from date: Date) -> Date {
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextDay) ?? nextDay
    }

    private func reminderDate(hoursFromNow hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: .now) ?? .now
    }

    private func reminderDateTomorrow(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) ?? tomorrow
    }

    private func reminderDateNextWorkday(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var candidate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now

        while calendar.isDateInWeekend(candidate) {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: candidate) ?? candidate
    }

    private static func buildScenarioHistories() -> [PracticeScenario: [PracticeSession]] {
        [
            .interviewIntro: [
                PracticeSession(
                    scenario: .interviewIntro,
                    title: "Retake 3 · cleaner fit close",
                    date: .now,
                    transcript: "Hi, I'm Katie. I help product teams explain complex work clearly, especially when priorities are moving fast and alignment matters.",
                    benchmarkCue: "Let the strength line land before you explain fit.",
                    listenerOutcome: PracticeScenario.interviewIntro.listenerOutcome,
                    structurePrompt: PracticeScenario.interviewIntro.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · grounded opener", detail: "Your opener already feels credible. The next lift is protecting one short pause before the fit statement so the close sounds chosen, not rushed."),
                        PracticeHighlight(title: "Sharpen · strength line", detail: "The updated middle line sounds more specific and less stacked."),
                        PracticeHighlight(title: "Keep · clean finish", detail: "Ending on one fit sentence lowers listener effort.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Tuesday · 8:30 AM · replay your benchmark before the first call",
                    carryoverLine: "Protect the first pause before your strength line.",
                    protectedLine: "I help product teams explain complex work clearly.",
                    unlockedStepCount: 3,
                    transcriptFootnote: "Latest retake saved with local replay on this iPhone.",
                    audioFileName: "seed-interview-retake.m4a",
                    durationSeconds: 24,
                    captureSource: .seeded
                ),
                PracticeSession(
                    scenario: .interviewIntro,
                    title: "Benchmark · first grounded version",
                    date: .now.addingTimeInterval(-86_400),
                    transcript: "Hi, I'm Katie. I work at the intersection of product, communication, and team clarity.",
                    benchmarkCue: "Slow down before the strength line so the first impression feels grounded.",
                    listenerOutcome: PracticeScenario.interviewIntro.listenerOutcome,
                    structurePrompt: PracticeScenario.interviewIntro.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · role lands fast", detail: "The listener gets context in the first sentence."),
                        PracticeHighlight(title: "Sharpen · make strength concrete", detail: "You can make the strength line feel more specific next."),
                        PracticeHighlight(title: "Sharpen · cleaner close", detail: "Choose one ending instead of two.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Monday · 7:10 PM · keep one benchmark ready before live interviews",
                    carryoverLine: "Use one breath before your strength line.",
                    protectedLine: "I work at the intersection of product, communication, and team clarity.",
                    unlockedStepCount: 2,
                    transcriptFootnote: "Protected benchmark with replay-ready audio.",
                    audioFileName: "seed-interview-benchmark.m4a",
                    durationSeconds: 27,
                    captureSource: .seeded
                )
            ],
            .weeklyUpdate: [
                PracticeSession(
                    scenario: .weeklyUpdate,
                    title: "Retake 2 · tighter decision handoff",
                    date: .now,
                    transcript: "Decision: ship the onboarding flow now. The tradeoff is Android analytics lag, and tomorrow I'm validating the fix with two customers before full rollout.",
                    benchmarkCue: "Pause once between the tradeoff and the next move so the recommendation lands clearly.",
                    listenerOutcome: PracticeScenario.weeklyUpdate.listenerOutcome,
                    structurePrompt: PracticeScenario.weeklyUpdate.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · decision lands first", detail: "Keep the decision line exactly as it is. The lift now is one clearer micro-pause before tomorrow so the owner-and-timing close lands without blur."),
                        PracticeHighlight(title: "Sharpen · tradeoff to next move pacing", detail: "The tension sounds specific; one small beat makes the recommendation easier to hear."),
                        PracticeHighlight(title: "Keep · owned finish", detail: "You sound like you know the next action already.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Tomorrow · 9:00 AM · replay before the decision review and protect the pause before your ask",
                    carryoverLine: "Keep the decision line short, then leave one beat before the next move.",
                    protectedLine: "Decision: ship the onboarding flow now.",
                    unlockedStepCount: 3,
                    transcriptFootnote: "Latest retake saved with replay-ready audio and reminder continuity.",
                    audioFileName: "seed-weekly-retake.m4a",
                    durationSeconds: 22,
                    captureSource: .seeded
                ),
                PracticeSession(
                    scenario: .weeklyUpdate,
                    title: "Benchmark · first saved decision pass",
                    date: .now.addingTimeInterval(-172_800),
                    transcript: "The decision is to ship onboarding now, the tradeoff is analytics lag on Android, and the next move is validating the fix with two customers tomorrow.",
                    benchmarkCue: "Pause once between the tradeoff and the next move so the ask lands clearly.",
                    listenerOutcome: PracticeScenario.weeklyUpdate.listenerOutcome,
                    structurePrompt: PracticeScenario.weeklyUpdate.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · decision first", detail: "The update opens with the decision first."),
                        PracticeHighlight(title: "Sharpen · ask gets crowded", detail: "One short pause will help the support need land."),
                        PracticeHighlight(title: "Keep · credible close", detail: "Owner and timing are already concrete.")
                    ],
                    compareReadiness: .transcriptOnly,
                    reminderLine: "Weekday mornings · 9:00 AM · resume this exact decision frame",
                    carryoverLine: "Give the ask one small pause.",
                    protectedLine: "The decision is to ship onboarding now.",
                    unlockedStepCount: 2,
                    transcriptFootnote: "Imported from an earlier prototype pass without audio attached.",
                    audioFileName: nil,
                    durationSeconds: nil,
                    captureSource: .imported
                ),
                PracticeSession(
                    scenario: .weeklyUpdate,
                    title: "Imported compare · earlier decision handoff",
                    date: .now.addingTimeInterval(-345_600),
                    transcript: "Ship onboarding now, Android analytics is the main tradeoff, and I need one day to validate the fix with customers.",
                    benchmarkCue: "Shorter tradeoff phrase, then land the timing in one breath.",
                    listenerOutcome: PracticeScenario.weeklyUpdate.listenerOutcome,
                    structurePrompt: PracticeScenario.weeklyUpdate.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · proof trail survives", detail: "This older take still shows the evolution of your decision style."),
                        PracticeHighlight(title: "Sharpen · wording precision", detail: "The newer benchmark is more manager-trackable."),
                        PracticeHighlight(title: "Keep · handoff stayed honest", detail: "Katie preserved the compare notes even without bundled audio.")
                    ],
                    compareReadiness: .transferredWithoutAudio,
                    reminderLine: "Imported reminder package · replay unavailable on this device",
                    carryoverLine: "Keep the decision and next-step timing in separate beats.",
                    protectedLine: "Android analytics is the main tradeoff.",
                    unlockedStepCount: 1,
                    transcriptFootnote: "Transferred proof package kept notes and transcript, but not original audio.",
                    audioFileName: nil,
                    durationSeconds: nil,
                    captureSource: .imported
                )
            ],
            .managerOneOnOne: [
                PracticeSession(
                    scenario: .managerOneOnOne,
                    title: "Retake 2 · clearer 1:1 ask",
                    date: .now,
                    transcript: "The pattern this week is slower review turnarounds on launch tasks. I already tightened the handoff notes, and I want your help choosing whether we simplify scope or pull in one extra reviewer.",
                    benchmarkCue: "Land the pattern first, then make the ask smaller than the frustration.",
                    listenerOutcome: PracticeScenario.managerOneOnOne.listenerOutcome,
                    structurePrompt: PracticeScenario.managerOneOnOne.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · pattern lands early", detail: "Opening with the repeated signal lowers listener effort. The next gain is protecting one tiny beat before the ask so the support request feels chosen, not emotional."),
                        PracticeHighlight(title: "Sharpen · friction stays concrete", detail: "You already sound specific instead of broad or self-blaming."),
                        PracticeHighlight(title: "Keep · ask is workable", detail: "The close gives your manager two practical doors instead of a vague stress signal.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Next workday · 8:45 AM · replay before your 1:1 and keep the ask concrete",
                    carryoverLine: "Name the pattern in one line, then ask for one decision.",
                    protectedLine: "The pattern this week is slower review turnarounds on launch tasks.",
                    unlockedStepCount: 3,
                    transcriptFootnote: "Latest 1:1 retake saved with local replay on this iPhone.",
                    audioFileName: "seed-1on1-retake.m4a",
                    durationSeconds: 28,
                    captureSource: .seeded
                ),
                PracticeSession(
                    scenario: .managerOneOnOne,
                    title: "Benchmark · first honest check-in",
                    date: .now.addingTimeInterval(-172_800),
                    transcript: "I'm noticing review turnarounds are slowing down this launch, and I want to pressure-test whether the right fix is less scope or another reviewer.",
                    benchmarkCue: "Start with the pattern, then keep the ask to one decision the manager can help make.",
                    listenerOutcome: PracticeScenario.managerOneOnOne.listenerOutcome,
                    structurePrompt: PracticeScenario.managerOneOnOne.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · signal is honest", detail: "The 1:1 starts with an observed pattern instead of a vague stress report."),
                        PracticeHighlight(title: "Sharpen · ask can get smaller", detail: "The newer retake makes the decision request easier to answer quickly."),
                        PracticeHighlight(title: "Keep · tone stays collaborative", detail: "You sound like a partner in the problem, not like you are offloading blame.")
                    ],
                    compareReadiness: .transcriptOnly,
                    reminderLine: "1:1 pack continuity · replay this shape before your next manager check-in",
                    carryoverLine: "Keep the friction concrete and the support ask answerable.",
                    protectedLine: "I'm noticing review turnarounds are slowing down this launch.",
                    unlockedStepCount: 2,
                    transcriptFootnote: "Imported continuity benchmark kept the proof trail, but audio did not transfer to this iPhone.",
                    audioFileName: nil,
                    durationSeconds: nil,
                    captureSource: .imported
                )
            ],
            .presentationOpening: [
                PracticeSession(
                    scenario: .presentationOpening,
                    title: "Retake 2 · clearer walkthrough opener",
                    date: .now,
                    transcript: "Today I'll show why onboarding drop-off matters, what we learned from the first cohort, and the one change most likely to lift activation.",
                    benchmarkCue: "Let the audience hear why the topic matters before you move into evidence.",
                    listenerOutcome: PracticeScenario.presentationOpening.listenerOutcome,
                    structurePrompt: PracticeScenario.presentationOpening.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · topic setup", detail: "The opener is already strong. The next gain is a slower beat after why this matters so the audience can lean in before the detail arrives."),
                        PracticeHighlight(title: "Keep · topic is easy to catch", detail: "The subject lands immediately."),
                        PracticeHighlight(title: "Sharpen · takeaway promise", detail: "The close now points toward one useful learning.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Thursday · 1:15 PM · rehearse before the walkthrough",
                    carryoverLine: "Pause after the problem statement before the evidence phrase.",
                    protectedLine: "Today I'll show why onboarding drop-off matters.",
                    unlockedStepCount: 2,
                    transcriptFootnote: "Replay-ready on this device with one saved compare anchor.",
                    audioFileName: "seed-presentation-retake.m4a",
                    durationSeconds: 25,
                    captureSource: .seeded
                ),
                PracticeSession(
                    scenario: .presentationOpening,
                    title: "Benchmark · first opener",
                    date: .now.addingTimeInterval(-259_200),
                    transcript: "Today I'll talk about onboarding drop-off, what we learned, and one change we can make.",
                    benchmarkCue: "Give the audience one reason to care before the lesson list begins.",
                    listenerOutcome: PracticeScenario.presentationOpening.listenerOutcome,
                    structurePrompt: PracticeScenario.presentationOpening.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · topic appears fast", detail: "The audience knows the area right away."),
                        PracticeHighlight(title: "Sharpen · why-it-matters", detail: "You can make the problem feel more urgent."),
                        PracticeHighlight(title: "Sharpen · takeaway is general", detail: "Name the likely benefit earlier next time.")
                    ],
                    compareReadiness: .missingAudio,
                    reminderLine: "Presentation pack reminder pending once you save another replay-ready take",
                    carryoverLine: "Lead with the why before the what.",
                    protectedLine: "Today I'll talk about onboarding drop-off.",
                    unlockedStepCount: 1,
                    transcriptFootnote: "Transcript preserved; audio for this older take is unavailable here.",
                    audioFileName: nil,
                    durationSeconds: nil,
                    captureSource: .imported
                )
            ],
            .customerRepair: [
                PracticeSession(
                    scenario: .customerRepair,
                    title: "Retake 2 · warmer repair",
                    date: .now,
                    transcript: "Let me repair that quickly: the date moved to Thursday, not Tuesday, and I want to make sure that still works for your team.",
                    benchmarkCue: "Keep the repair phrase short, then restate the step in one sentence.",
                    listenerOutcome: PracticeScenario.customerRepair.listenerOutcome,
                    structurePrompt: PracticeScenario.customerRepair.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · calm reset", detail: "The repair phrase already lowers tension. Your next gain is a shorter correction clause so the customer hears the new date instantly."),
                        PracticeHighlight(title: "Keep · humane tone", detail: "The tone stays warm instead of defensive."),
                        PracticeHighlight(title: "Sharpen · corrected step", detail: "The ending invites confirmation without overexplaining.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Wednesday · 10:30 AM · keep one warm repair version ready before support calls",
                    carryoverLine: "Repair in five words, then restate the corrected step once.",
                    protectedLine: "The date moved to Thursday, not Tuesday.",
                    unlockedStepCount: 3,
                    transcriptFootnote: "Local compare audio saved for this trust-repair benchmark.",
                    audioFileName: "seed-repair-retake.m4a",
                    durationSeconds: 19,
                    captureSource: .seeded
                ),
                PracticeSession(
                    scenario: .customerRepair,
                    title: "Benchmark · first calm reset",
                    date: .now.addingTimeInterval(-129_600),
                    transcript: "Sorry, let me fix that: the meeting is Thursday, and I want to confirm that still works for your team.",
                    benchmarkCue: "Make the correction sentence shorter than the apology.",
                    listenerOutcome: PracticeScenario.customerRepair.listenerOutcome,
                    structurePrompt: PracticeScenario.customerRepair.structurePrompt,
                    highlights: [
                        PracticeHighlight(title: "Keep · apology is warm", detail: "The tone stays respectful."),
                        PracticeHighlight(title: "Sharpen · correction is long", detail: "The updated take lands the new date faster."),
                        PracticeHighlight(title: "Keep · close checks understanding", detail: "You are protecting the relationship well.")
                    ],
                    compareReadiness: .audioReady,
                    reminderLine: "Customer moments pack · replay-ready benchmark saved",
                    carryoverLine: "Keep the apology short so the corrected detail lands faster.",
                    protectedLine: "The meeting is Thursday.",
                    unlockedStepCount: 2,
                    transcriptFootnote: "Benchmark is replay-ready on this device.",
                    audioFileName: "seed-repair-benchmark.m4a",
                    durationSeconds: 21,
                    captureSource: .seeded
                )
            ]
        ]
    }

    private func recordingsDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = documents.appendingPathComponent("KatieRecordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path()) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func makeScratchRecordingURL() -> URL {
        recordingsDirectory().appendingPathComponent("scratch-\(UUID().uuidString).m4a")
    }

    func audioURL(for session: PracticeSession) -> URL? {
        guard let audioFileName = session.audioFileName else { return nil }
        let url = recordingsDirectory().appendingPathComponent(audioFileName)
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }
}
