import Foundation
import Combine

/// KAT-206: Reflection state extracted from AppViewModel.
///
/// First slice owns the reactive reflection-draft flags: `draftTranscript`,
/// the three `draftReflection*Score` numeric ratings, the
/// `draftReflectionStickyMoment` free-text field, and the read-only
/// `activePracticeStep` index that drives the practice flow's step rail.
///
/// Reflection lifecycle methods (`prepareDraftReflection`, `applyRetakeDraftStarter`,
/// `saveCurrentRetake`, `saveDemoRetake`, `setActivePracticeStep`,
/// `focusRecommendedPracticeStep`, `moveToPreviousPracticeStep`,
/// `moveToNextPracticeStep`, `continuePracticeFromReview`,
/// `openProgressFromReview`, `clearDraftRetake`, `dismissPracticeReturnCue`,
/// `stickyMomentOptions`) intentionally stay on `AppViewModel` for the next
/// careful slice — they reach into ScenarioState (save), RecordingState
/// (discard scratch), and ReminderState (save demo retake label), so the
/// multi-domain coordination is the next step. Moving the storage first keeps
/// the public API (`appViewModel.draftTranscript`,
/// `appViewModel.draftReflectionListenerCatchScore`, …) stable and the build green.
final class ReflectionState: ObservableObject, Codable {
    @Published var draftTranscript: String
    @Published var draftReflectionListenerCatchScore: Int
    @Published var draftReflectionPaceControlScore: Int
    @Published var draftReflectionConfidenceScore: Int
    @Published var draftReflectionStickyMoment: String
    @Published var activePracticeStep: Int

    init(
        draftTranscript: String = "",
        draftReflectionListenerCatchScore: Int = 3,
        draftReflectionPaceControlScore: Int = 3,
        draftReflectionConfidenceScore: Int = 3,
        draftReflectionStickyMoment: String = "Opening line",
        activePracticeStep: Int = 0
    ) {
        self.draftTranscript = draftTranscript
        self.draftReflectionListenerCatchScore = draftReflectionListenerCatchScore
        self.draftReflectionPaceControlScore = draftReflectionPaceControlScore
        self.draftReflectionConfidenceScore = draftReflectionConfidenceScore
        self.draftReflectionStickyMoment = draftReflectionStickyMoment
        self.activePracticeStep = activePracticeStep
    }

    private enum CodingKeys: String, CodingKey {
        case draftTranscript
        case draftReflectionListenerCatchScore
        case draftReflectionPaceControlScore
        case draftReflectionConfidenceScore
        case draftReflectionStickyMoment
        case activePracticeStep
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        draftTranscript = try container.decodeIfPresent(String.self, forKey: .draftTranscript) ?? ""
        draftReflectionListenerCatchScore = try container.decodeIfPresent(Int.self, forKey: .draftReflectionListenerCatchScore) ?? 3
        draftReflectionPaceControlScore = try container.decodeIfPresent(Int.self, forKey: .draftReflectionPaceControlScore) ?? 3
        draftReflectionConfidenceScore = try container.decodeIfPresent(Int.self, forKey: .draftReflectionConfidenceScore) ?? 3
        draftReflectionStickyMoment = try container.decodeIfPresent(String.self, forKey: .draftReflectionStickyMoment) ?? "Opening line"
        activePracticeStep = try container.decodeIfPresent(Int.self, forKey: .activePracticeStep) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(draftTranscript, forKey: .draftTranscript)
        try container.encode(draftReflectionListenerCatchScore, forKey: .draftReflectionListenerCatchScore)
        try container.encode(draftReflectionPaceControlScore, forKey: .draftReflectionPaceControlScore)
        try container.encode(draftReflectionConfidenceScore, forKey: .draftReflectionConfidenceScore)
        try container.encode(draftReflectionStickyMoment, forKey: .draftReflectionStickyMoment)
        try container.encode(activePracticeStep, forKey: .activePracticeStep)
    }
}
