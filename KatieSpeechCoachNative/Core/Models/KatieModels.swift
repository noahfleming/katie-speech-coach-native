import Foundation
import CoreTransferable

enum SessionCaptureSource: String, Codable {
    case seeded
    case recorded
    case imported
    case syntheticRetake

    var title: String {
        switch self {
        case .seeded: return "Starter sample"
        case .recorded: return "Fresh on this iPhone"
        case .imported: return "Carried over"
        case .syntheticRetake: return "Text-only fallback"
        }
    }

    var detail: String {
        switch self {
        case .seeded: return "Just enough to show the compare flow before your own clips show up."
        case .recorded: return "Saved locally on this iPhone."
        case .imported: return "The coaching trail came over, but replay did not."
        case .syntheticRetake: return "Text only, so progress stays honest when you skip audio."
        }
    }

    var systemImage: String {
        switch self {
        case .seeded: return "sparkles.rectangle.stack.fill"
        case .recorded: return "mic.fill"
        case .imported: return "square.and.arrow.down.on.square.fill"
        case .syntheticRetake: return "text.bubble.fill"
        }
    }
}

enum ReminderPermissionState: String, Codable {
    case unknown
    case granted
    case denied

    var title: String {
        switch self {
        case .unknown: return "Permission not requested"
        case .granted: return "Notifications allowed"
        case .denied: return "Notifications blocked"
        }
    }

    var systemImage: String {
        switch self {
        case .unknown: return "bell.badge"
        case .granted: return "bell.badge.fill"
        case .denied: return "bell.slash.fill"
        }
    }
}

enum MicrophonePermissionState: String, Codable {
    case unknown
    case granted
    case denied

    var title: String {
        switch self {
        case .unknown: return "Microphone not requested"
        case .granted: return "Microphone allowed"
        case .denied: return "Microphone blocked"
        }
    }

    var systemImage: String {
        switch self {
        case .unknown: return "mic.badge.plus"
        case .granted: return "mic.fill"
        case .denied: return "mic.slash.fill"
        }
    }
}

struct ReminderPlan: Codable, Hashable {
    var scenario: PracticeScenario
    var fireDate: Date

    var requestIdentifier: String {
        "katie.reminder.\(scenario.rawValue)"
    }
}

struct PersistedKatieState: Codable {
    var hasCompletedOnboarding: Bool
    var hasDismissedFirstBaselineGate: Bool
    var learnerProfile: LearnerProfile
    var currentMission: PracticeScenario
    var selectedTab: AppViewModel.AppTab
    var premiumAccessState: PremiumAccessState
    var reminderPlan: ReminderPlan?
    var reminderTone: ReminderTone
    var scenarioHistories: [PracticeScenario: [PracticeSession]]
    var selectedAnchorByScenario: [PracticeScenario: UUID]

    init(
        hasCompletedOnboarding: Bool,
        hasDismissedFirstBaselineGate: Bool = false,
        learnerProfile: LearnerProfile,
        currentMission: PracticeScenario,
        selectedTab: AppViewModel.AppTab = .today,
        premiumAccessState: PremiumAccessState,
        reminderPlan: ReminderPlan?,
        reminderTone: ReminderTone = .workday,
        scenarioHistories: [PracticeScenario: [PracticeSession]],
        selectedAnchorByScenario: [PracticeScenario: UUID]
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasDismissedFirstBaselineGate = hasDismissedFirstBaselineGate
        self.learnerProfile = learnerProfile
        self.currentMission = currentMission
        self.selectedTab = selectedTab
        self.premiumAccessState = premiumAccessState
        self.reminderPlan = reminderPlan
        self.reminderTone = reminderTone
        self.scenarioHistories = scenarioHistories
        self.selectedAnchorByScenario = selectedAnchorByScenario
    }

    private enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case hasDismissedFirstBaselineGate
        case learnerProfile
        case currentMission
        case selectedTab
        case premiumAccessState
        case reminderPlan
        case reminderTone
        case scenarioHistories
        case selectedAnchorByScenario
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        hasDismissedFirstBaselineGate = try container.decodeIfPresent(Bool.self, forKey: .hasDismissedFirstBaselineGate) ?? false
        learnerProfile = try container.decode(LearnerProfile.self, forKey: .learnerProfile)
        currentMission = try container.decode(PracticeScenario.self, forKey: .currentMission)
        selectedTab = try container.decodeIfPresent(AppViewModel.AppTab.self, forKey: .selectedTab) ?? .today
        premiumAccessState = try container.decode(PremiumAccessState.self, forKey: .premiumAccessState)
        reminderPlan = try container.decodeIfPresent(ReminderPlan.self, forKey: .reminderPlan)
        reminderTone = try container.decodeIfPresent(ReminderTone.self, forKey: .reminderTone) ?? .workday
        scenarioHistories = try container.decode([PracticeScenario: [PracticeSession]].self, forKey: .scenarioHistories)
        selectedAnchorByScenario = try container.decode([PracticeScenario: UUID].self, forKey: .selectedAnchorByScenario)
    }
}

struct KatiePocketCopyBundle: Codable {
    let exportedAt: Date
    let currentMission: PracticeScenario
    let reminderPlan: ReminderPlan?
    let isPremiumUnlocked: Bool
    let learnerProfile: LearnerProfile
    let scenarioHistories: [PracticeScenario: [PracticeSession]]
    let selectedAnchorByScenario: [PracticeScenario: UUID]
    let notes: [String]
}

struct KatiePocketCopyExport: Transferable {
    let json: String
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            Data(export.json.utf8)
        }
        .suggestedFileName { export in
            export.filename
        }
    }
}

struct MomentumMilestone: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let isActive: Bool
}

struct ReminderQuickPreset: Identifiable, Hashable {
    let title: String
    let fireDate: Date

    var id: String { title }
}

enum ReminderTone: String, Codable, CaseIterable, Identifiable {
    case calm
    case workday
    case beforeMeeting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .workday: return "Workday"
        case .beforeMeeting: return "Before meeting"
        }
    }

    var detail: String {
        switch self {
        case .calm: return "Gentle nudge that protects one line without pressure."
        case .workday: return "Short, practical cue for normal work rhythm."
        case .beforeMeeting: return "Timed like a quick pre-call reset."
        }
    }
}

struct FirstSpeakingScan: Hashable {
    let strongestMove: String
    let listenerRisk: String
    let firstWinPlan: String
    let savedLine: String
}

struct PackProgressCard: Hashable {
    let title: String
    let stepLabel: String
    let whyItMatters: String
    let nextUnlock: String
    let continueLine: String
}

struct FeaturedWin: Identifiable, Hashable {
    let id = UUID()
    let scenario: PracticeScenario
    let beforeText: String
    let afterText: String
    let deltaHint: String
    let readiness: CompareReadiness
    let sourceTag: String
    let latestSession: PracticeSession
    let anchorSession: PracticeSession?
}

struct CompareLibraryEntry: Identifiable, Hashable {
    let scenario: PracticeScenario
    let latest: PracticeSession
    let anchor: PracticeSession?

    var id: String {
        let anchorID = anchor?.id.uuidString ?? "solo"
        return "\(scenario.rawValue)-\(latest.id.uuidString)-\(anchorID)"
    }

    var statusLabel: String {
        "Compare ready"
    }
}

struct TodayQueueEntry: Identifiable, Hashable {
    enum Action: Hashable {
        case recordFirstRep
        case recordFreshProof
        case openProof
        case openCompare
        case enableReminder
        case keepWarm
    }

    let scenario: PracticeScenario
    let statusLabel: String
    let emphasisLine: String
    let nextStepLine: String
    let freshnessLabel: String?
    let action: Action
    let reminderCue: TodayReminderCue

    var id: PracticeScenario { scenario }

    var actionTitle: String {
        switch action {
        case .recordFirstRep:
            return "Record first rep"
        case .recordFreshProof:
            return "Record fresh proof"
        case .openProof:
            return "Open proof"
        case .openCompare:
            return "Open compare"
        case .enableReminder:
            return "Add nudge"
        case .keepWarm:
            return "Keep warm"
        }
    }
}

struct TodayReminderCue: Hashable {
    let eyebrow: String
    let title: String
    let body: String
    let systemImage: String
    let isActive: Bool
}

struct QuickRepPrompt: Identifiable, Hashable {
    let scenario: PracticeScenario
    let title: String
    let detail: String
    let durationLabel: String
    let starterLine: String
    let statusLabel: String
    let hypothesisStatusLabel: String
    let hypothesisDetailLine: String
    let proofLine: String
    let continuityLine: String

    var id: PracticeScenario { scenario }
}

enum PracticeScenario: String, CaseIterable, Identifiable, Codable {
    case interviewIntro
    case weeklyUpdate
    case managerOneOnOne
    case presentationOpening
    case customerRepair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interviewIntro: return "Intro answer"
        case .weeklyUpdate: return "Decision update"
        case .managerOneOnOne: return "Manager 1:1"
        case .presentationOpening: return "Presentation opener"
        case .customerRepair: return "Customer repair"
        }
    }

    var categoryLabel: String {
        switch self {
        case .interviewIntro: return "Interviews"
        case .weeklyUpdate: return "Decision moments"
        case .managerOneOnOne: return "1:1s"
        case .presentationOpening: return "Presentations"
        case .customerRepair: return "Customer calls"
        }
    }

    var missionPrompt: String {
        switch self {
        case .interviewIntro:
            return "Open with who you are, what you do, and why it fits."
        case .weeklyUpdate:
            return "Lead with the decision, name the tradeoff, then land the next move."
        case .managerOneOnOne:
            return "Name the signal, the friction, and the one next ask."
        case .presentationOpening:
            return "Open the topic, explain one idea, and land the takeaway."
        case .customerRepair:
            return "Repair the bump, restate clearly, and check understanding."
        }
    }

    var structurePrompt: String {
        switch self {
        case .interviewIntro:
            return "Who → proof → fit"
        case .weeklyUpdate:
            return "Decision → tradeoff → next move"
        case .managerOneOnOne:
            return "Signal → friction → ask"
        case .presentationOpening:
            return "Topic → idea → takeaway"
        case .customerRepair:
            return "Repair → restate → check back"
        }
    }

    var listenerOutcome: String {
        switch self {
        case .interviewIntro:
            return "Sound grounded fast, before the room drifts."
        case .weeklyUpdate:
            return "Help a busy listener catch the decision, the tension, and the next move."
        case .managerOneOnOne:
            return "Show what is sticky, what you tried, and what help would actually move it."
        case .presentationOpening:
            return "Make the why obvious before the details arrive."
        case .customerRepair:
            return "Keep trust warm while you clear the next step."
        }
    }

    var packTitle: String {
        switch self {
        case .interviewIntro: return "Intro pack"
        case .weeklyUpdate: return "Decision pack"
        case .managerOneOnOne: return "1:1 pack"
        case .presentationOpening: return "Presence pack"
        case .customerRepair: return "Repair pack"
        }
    }

    var positioningLine: String {
        switch self {
        case .interviewIntro:
            return "Fast identity and fit when someone needs to trust you quickly."
        case .weeklyUpdate:
            return "Short decision updates for work moments where the headline needs to land first."
        case .managerOneOnOne:
            return "A calmer lane for naming friction, stakes, and one answerable ask."
        case .presentationOpening:
            return "A clean opener for walkthroughs, demos, and higher-stakes room energy."
        case .customerRepair:
            return "Repair language for tense clarifications without sounding defensive."
        }
    }

    var realLifeMoments: [String] {
        switch self {
        case .interviewIntro:
            return ["Recruiter screens", "Networking intros", "Panel opens"]
        case .weeklyUpdate:
            return ["Standups", "Project updates", "Decision handoffs"]
        case .managerOneOnOne:
            return ["1:1s", "Escalations", "Priority resets"]
        case .presentationOpening:
            return ["Team demos", "Client walkthroughs", "Kickoff intros"]
        case .customerRepair:
            return ["Support calls", "Expectation resets", "Scope clarifications"]
        }
    }

    var premiumExperimentHook: String {
        switch self {
        case .interviewIntro:
            return "Keep your best short intro warm for the next high-stakes room."
        case .weeklyUpdate:
            return "Protect the clearest version of your decision update so the next meeting starts cleaner."
        case .managerOneOnOne:
            return "Hold onto the version that names the pattern and lands a specific ask."
        case .presentationOpening:
            return "Save the opener that makes the room lean in before detail arrives."
        case .customerRepair:
            return "Reuse the repair line that keeps trust warm while you reset the next step."
        }
    }

    var stepLabels: [String] {
        switch self {
        case .interviewIntro:
            return ["Role lands", "Proof lands", "Fit lands"]
        case .weeklyUpdate:
            return ["Decision lands", "Tradeoff stays real", "Next move lands"]
        case .managerOneOnOne:
            return ["Signal lands", "Friction stays specific", "Ask stays small"]
        case .presentationOpening:
            return ["Topic lands", "Idea gets space", "Takeaway lands"]
        case .customerRepair:
            return ["Repair stays calm", "Restate shorter", "Check back warm"]
        }
    }

    var stepCoachingPrompts: [String] {
        switch self {
        case .interviewIntro:
            return [
                "Start with the role and context fast so the listener is not still guessing who you are.",
                "Give one concrete strength beat that sounds observed, not like a list of traits.",
                "Close with why this role fits now, and stop before the ending turns into extra explanation."
            ]
        case .weeklyUpdate:
            return [
                "Lead with the decision headline first so a busy listener can place the whole moment in one sentence.",
                "Name the tradeoff plainly, with just enough detail to show what tension is actually in the way.",
                "End on the next move you own so the decision sounds directed instead of open-ended."
            ]
        case .managerOneOnOne:
            return [
                "Lead with the pattern your manager should notice so the conversation does not start in the weeds.",
                "Describe the friction in concrete language that sounds observed, not self-critical or diagnostic.",
                "Finish with one specific ask or experiment so the 1:1 ends with a next move instead of a vague vent."
            ]
        case .presentationOpening:
            return [
                "Open the topic in simple language so the room knows what they are about to hear.",
                "Give the core idea a little air before details start stacking up.",
                "Land the takeaway early so the audience knows why the next minute matters."
            ]
        case .customerRepair:
            return [
                "Use one short repair phrase to cool the moment without getting stuck in apology.",
                "Restate the corrected detail in cleaner language than the original confusion.",
                "Finish with a warm check-back so the other person can confirm the reset feels clear."
            ]
        }
    }

    var continuityPromise: String {
        switch self {
        case .interviewIntro:
            return "Protect your first benchmark, then keep one cleaner version ready for live conversations."
        case .weeklyUpdate:
            return "Keep one short decision benchmark that makes your clearest meeting version easy to revisit before real conversations."
        case .managerOneOnOne:
            return "Keep one honest 1:1 benchmark that names the friction and lands one concrete ask before the conversation gets muddy."
        case .presentationOpening:
            return "Keep one steady opener you can reuse before higher-stakes walkthroughs and demos."
        case .customerRepair:
            return "Keep one trusted repair pattern handy so tense moments feel easier to reset."
        }
    }
}

enum CompareReadiness: String, Codable {
    case audioReady
    case transcriptOnly
    case transferredWithoutAudio
    case missingAudio

    var title: String {
        switch self {
        case .audioReady: return "Replay ready"
        case .transcriptOnly: return "Transcript only"
        case .transferredWithoutAudio: return "Transferred without audio"
        case .missingAudio: return "Audio unavailable here"
        }
    }

    var detail: String {
        switch self {
        case .audioReady:
            return "This benchmark can replay beside your latest retake on this device."
        case .transcriptOnly:
            return "The wording and coaching survive, but the original audio is not attached here."
        case .transferredWithoutAudio:
            return "The handoff kept your compare story honest, but audio still needs to be re-recorded on this device."
        case .missingAudio:
            return "Katie still shows the coaching trail instead of pretending playback exists."
        }
    }

    var systemImage: String {
        switch self {
        case .audioReady: return "waveform.circle.fill"
        case .transcriptOnly: return "text.bubble.fill"
        case .transferredWithoutAudio: return "arrow.triangle.swap"
        case .missingAudio: return "speaker.slash.fill"
        }
    }
}

enum TransferHypothesisFeedback: String, Codable, CaseIterable, Identifiable {
    case soundsLikeMe = "sounds_like_me"
    case notSureYet = "not_sure_yet"
    case notMyMainIssue = "not_my_main_issue"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soundsLikeMe: return "Yes — this sounds like me"
        case .notSureYet: return "Not sure yet"
        case .notMyMainIssue: return "Not really"
        }
    }

    var detail: String {
        switch self {
        case .soundsLikeMe:
            return "Keep this as the starting cue, then verify it with my first saved rep."
        case .notSureYet:
            return "Hold the language-background cue lightly until Katie hears my own recording."
        case .notMyMainIssue:
            return "Use my profile as context, but let the first recording drive the real plan."
        }
    }

    var systemImage: String {
        switch self {
        case .soundsLikeMe: return "checkmark.seal.fill"
        case .notSureYet: return "questionmark.circle.fill"
        case .notMyMainIssue: return "waveform.badge.magnifyingglass"
        }
    }
}

struct LearnerProfile: Codable {
    var firstName: String = "Noah"
    var role: String = "Product builder"
    var firstLanguage: String = "English"
    var otherLanguages: String = ""
    var firstGoal: String = "Clearer, calmer work communication"
    var focusScenario: PracticeScenario = .weeklyUpdate

    var communicationEnvironment: CommunicationEnvironment = .teamMeeting
    var listenerPressure: ListenerPressure = .mixed
    var listenerFrictionPoint: ListenerFrictionPoint = .keyWords
    var transferHypothesisFeedback: TransferHypothesisFeedback = .notSureYet

    private enum CodingKeys: String, CodingKey {
        case firstName
        case role
        case firstLanguage
        case otherLanguages
        case firstGoal
        case focusScenario
        case communicationEnvironment
        case listenerPressure
        case listenerFrictionPoint
        case transferHypothesisFeedback
    }

    init(
        firstName: String = "Noah",
        role: String = "Product builder",
        firstLanguage: String = "English",
        otherLanguages: String = "",
        firstGoal: String = "Clearer, calmer work communication",
        focusScenario: PracticeScenario = .weeklyUpdate,
        communicationEnvironment: CommunicationEnvironment = .teamMeeting,
        listenerPressure: ListenerPressure = .mixed,
        listenerFrictionPoint: ListenerFrictionPoint = .keyWords,
        transferHypothesisFeedback: TransferHypothesisFeedback = .notSureYet
    ) {
        self.firstName = firstName
        self.role = role
        self.firstLanguage = firstLanguage
        self.otherLanguages = otherLanguages
        self.firstGoal = firstGoal
        self.focusScenario = focusScenario
        self.communicationEnvironment = communicationEnvironment
        self.listenerPressure = listenerPressure
        self.listenerFrictionPoint = listenerFrictionPoint
        self.transferHypothesisFeedback = transferHypothesisFeedback
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? "Noah"
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? "Product builder"
        firstLanguage = try container.decodeIfPresent(String.self, forKey: .firstLanguage) ?? "English"
        otherLanguages = try container.decodeIfPresent(String.self, forKey: .otherLanguages) ?? ""
        firstGoal = try container.decodeIfPresent(String.self, forKey: .firstGoal) ?? "Clearer, calmer work communication"
        focusScenario = try container.decodeIfPresent(PracticeScenario.self, forKey: .focusScenario) ?? .weeklyUpdate
        communicationEnvironment = try container.decodeIfPresent(CommunicationEnvironment.self, forKey: .communicationEnvironment) ?? .teamMeeting
        listenerPressure = try container.decodeIfPresent(ListenerPressure.self, forKey: .listenerPressure) ?? .mixed
        listenerFrictionPoint = try container.decodeIfPresent(ListenerFrictionPoint.self, forKey: .listenerFrictionPoint) ?? .keyWords
        transferHypothesisFeedback = try container.decodeIfPresent(TransferHypothesisFeedback.self, forKey: .transferHypothesisFeedback) ?? .notSureYet
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(role, forKey: .role)
        try container.encode(firstLanguage, forKey: .firstLanguage)
        try container.encode(otherLanguages, forKey: .otherLanguages)
        try container.encode(firstGoal, forKey: .firstGoal)
        try container.encode(focusScenario, forKey: .focusScenario)
        try container.encode(communicationEnvironment, forKey: .communicationEnvironment)
        try container.encode(listenerPressure, forKey: .listenerPressure)
        try container.encode(listenerFrictionPoint, forKey: .listenerFrictionPoint)
        try container.encode(transferHypothesisFeedback, forKey: .transferHypothesisFeedback)
    }
}

enum CommunicationEnvironment: String, Codable, CaseIterable, Identifiable {
    case oneOnOne = "one_on_one"
    case teamMeeting = "team_meeting"
    case presentationRoom = "presentation_room"
    case customerCall = "customer_call"
    case hybridRoom = "hybrid_room"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneOnOne: return "1:1 conversation"
        case .teamMeeting: return "Team meeting"
        case .presentationRoom: return "Presentation room"
        case .customerCall: return "Customer call"
        case .hybridRoom: return "Hybrid room"
        }
    }

    var detail: String {
        switch self {
        case .oneOnOne: return "Optimize for quick context, steady pacing, and easier back-and-forth repair."
        case .teamMeeting: return "Optimize for status clarity so the headline, blocker, and ask land on the first listen."
        case .presentationRoom: return "Optimize for room-level clarity, cleaner emphasis, and strong sentence endings."
        case .customerCall: return "Optimize for warmth under pressure and fast repair when trust matters."
        case .hybridRoom: return "Optimize for remote + in-room listeners who can miss soft endings and rushed transitions."
        }
    }
}

enum ListenerPressure: String, Codable, CaseIterable, Identifiable {
    case supportive
    case mixed
    case skeptical
    case highStakes = "high_stakes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supportive: return "Supportive listener"
        case .mixed: return "Mixed attention"
        case .skeptical: return "Skeptical room"
        case .highStakes: return "High-stakes moment"
        }
    }

    var detail: String {
        switch self {
        case .supportive: return "Protect confidence and make the strongest line feel repeatable, not overworked."
        case .mixed: return "Assume some listeners are distracted, so the opener needs to land quickly."
        case .skeptical: return "Protect evidence, contrast, and one clean takeaway the listener can repeat back."
        case .highStakes: return "Strip drift fast so the listener catches the ask even under time pressure."
        }
    }
}

enum ListenerFrictionPoint: String, Codable, CaseIterable, Identifiable {
    case keyWords = "key_words"
    case endings
    case transitions
    case pace
    case confidence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyWords: return "Key words blur"
        case .endings: return "Word endings fade"
        case .transitions: return "Transitions drift"
        case .pace: return "Pace gets rushed"
        case .confidence: return "Confidence sounds thin"
        }
    }

    var detail: String {
        switch self {
        case .keyWords: return "Katie protects the words that carry meaning first, so the listener catches the point without decoding extra effort."
        case .endings: return "Katie starts with endings and final consonants that often drop when pressure rises."
        case .transitions: return "Katie tightens the hinge between ideas so the listener hears what changed and what comes next."
        case .pace: return "Katie uses shorter thought groups and one steady breath before adding extra polish."
        case .confidence: return "Katie protects wording and sentence landing so confidence comes from clarity, not forced performance."
        }
    }
}

struct LanguageAssessmentSnapshot: Hashable {
    let title: String
    let transferPattern: String
    let soundFocus: String
    let prosodyFocus: String
    let caveat: String
}

struct GoalPreset: Identifiable, Hashable {
    let title: String
    let detail: String

    var id: String { title }
}

struct PracticeHighlight: Identifiable, Hashable, Codable {
    let id = UUID()
    let title: String
    let detail: String
}

struct SessionSelfReflection: Hashable, Codable {
    var listenerCatchScore: Int = 3
    var paceControlScore: Int = 3
    var confidenceScore: Int = 3
    var stickyMoment: String = "Opening line"
}

struct SoundPatternRadar: Hashable {
    let title: String
    let summary: String
    let evidenceLine: String
    let bullets: [String]
}

struct ConversationTransferPlan: Hashable {
    let title: String
    let summary: String
    let beforeYouSpeak: String
    let whileSpeaking: String
    let repairMove: String
}

struct CoachingEvidencePulse: Hashable {
    let title: String
    let summary: String
    let points: [String]
}

struct GoalProgressSnapshot: Hashable {
    let title: String
    let detail: String
    let focusPackLine: String
    let scenarioLine: String
    let nextMilestoneLine: String
    let progressLabel: String
    let steps: [String]
    let completedSteps: Int

    var totalSteps: Int { steps.count }
}

enum ProgressAchievementTone: String, Hashable {
    case mint
    case gold
    case accent
}

struct ProgressAchievement: Identifiable, Hashable {
    let title: String
    let detail: String
    let systemImage: String
    let tone: ProgressAchievementTone
    let isUnlocked: Bool

    var id: String { title }
}

struct ScenarioAnalyticsPoint: Identifiable, Hashable {
    let label: String
    let listenerScore: Int
    let paceScore: Int
    let confidenceScore: Int
    let overallScore: Int
    let hasReplay: Bool

    var id: String { label }
}

struct ScenarioAnalyticsSummary: Hashable {
    let title: String
    let subtitle: String
    let strongestLane: String
    let momentumLine: String
    let playbackLine: String
    let listenerAverage: Int
    let paceAverage: Int
    let confidenceAverage: Int
    let overallAverage: Int
    let points: [ScenarioAnalyticsPoint]
}

struct PracticeSession: Identifiable, Hashable, Codable {
    let id = UUID()
    var scenario: PracticeScenario
    var title: String
    var date: Date
    var transcript: String
    var benchmarkCue: String
    var listenerOutcome: String
    var structurePrompt: String
    var highlights: [PracticeHighlight]
    var compareReadiness: CompareReadiness
    var reminderLine: String
    var carryoverLine: String
    var protectedLine: String
    var unlockedStepCount: Int
    var transcriptFootnote: String
    var audioFileName: String?
    var durationSeconds: TimeInterval?
    var captureSource: SessionCaptureSource
    var selfReflection: SessionSelfReflection? = nil

    var hasAudioPlayback: Bool {
        audioFileName != nil
    }

    var isUserOwned: Bool {
        captureSource == .recorded || captureSource == .syntheticRetake
    }
}

struct ScenarioProgressSnapshot {
    var completedSessions: Int
    var bestStreakLabel: String
    var nextUnlockLabel: String
    var reminderCadenceLabel: String
    var portableProofLabel: String
}

enum KatieContinuityAccent: String {
    case mint
    case accent
    case gold

    var title: String {
        switch self {
        case .mint: return "Replay ready"
        case .accent: return "Transcript-first"
        case .gold: return "Reminder handoff"
        }
    }
}

struct KatieContinuityStrip: Hashable {
    let title: String
    let message: String
    let systemImage: String
    let accent: KatieContinuityAccent
}
