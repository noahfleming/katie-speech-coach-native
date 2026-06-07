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

    // MARK: - Step navigation (pure reflection-domain)

    /// Clamp + apply a step index. Returns the clamped value so callers
    /// (e.g. the haptic + return-cue logic in AppViewModel) can react.
    @discardableResult
    func setActivePracticeStep(_ step: Int, totalSteps: Int) -> Int {
        let clampedStep = max(0, min(step, max(0, totalSteps - 1)))
        activePracticeStep = clampedStep
        return clampedStep
    }

    // MARK: - Sticky-moment option list (pure reflection-domain)

    /// Locales for the reflection's sticky-moment free-text picker, by scenario.
    static func stickyMomentOptions(for scenario: PracticeScenario) -> [String] {
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

    // MARK: - Reflection reset (domain-local)

    /// Reset the draft reflection to either the last saved self-reflection
    /// for the current mission, or a sensible 3/3/3 starter if there is none.
    /// - Parameters:
    ///   - resetScores: If `true`, overwrite the scores even when a previous
    ///     self-reflection exists.
    ///   - previousSelfReflection: The latest self-reflection for the mission
    ///     (or nil if there is none yet) — provided by the caller so this
    ///     VM stays free of scenario-history dependencies.
    ///   - currentMission: The current mission (used to validate the sticky
    ///     moment is in the option list).
    func prepareDraft(
        resetScores: Bool,
        previousSelfReflection: SessionSelfReflection?,
        currentMission: PracticeScenario
    ) {
        let defaults = previousSelfReflection ?? SessionSelfReflection(
            listenerCatchScore: 3,
            paceControlScore: 3,
            confidenceScore: 3,
            stickyMoment: Self.stickyMomentOptions(for: currentMission).first ?? "Opening line"
        )

        if resetScores || previousSelfReflection == nil {
            draftReflectionListenerCatchScore = defaults.listenerCatchScore
            draftReflectionPaceControlScore = defaults.paceControlScore
            draftReflectionConfidenceScore = defaults.confidenceScore
        }

        let options = Self.stickyMomentOptions(for: currentMission)
        draftReflectionStickyMoment = options.contains(defaults.stickyMoment) ? defaults.stickyMoment : (options.first ?? "Opening line")
    }

    // MARK: - Draft mutations (used by the practice flow)

    /// Apply a starter line as the new draft transcript. The recording card
    /// status line is updated to confirm the load.
    func applyRetakeDraftStarter(_ starter: String) -> String {
        draftTranscript = starter
        return "Loaded a step starter into the draft. Shape it into your own calmer rep before saving."
    }

    /// Clear the draft so a fresh rep can be recorded.
    func clearDraft() {
        draftTranscript = ""
    }

    /// Mark a "draft cleared" status update.
    var draftClearedStatusLine: String { "Draft cleared. Ready to record another rep." }
}
