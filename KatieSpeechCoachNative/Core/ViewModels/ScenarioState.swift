import Foundation
import Combine

/// KAT-206: Scenario state extracted from AppViewModel.
///
/// First slice owns the four reactive scenario flags (`currentMission`,
/// `availableScenarios`, `scenarioHistories`, `selectedAnchorByScenario`) and
/// the most-read derivations on top of them. Scenario-switching + anchor
/// helpers (e.g. `ensureAnchorSelection`, `userOwnedSessionCount`,
/// `latestSession`, `sampleSession`, `scenarioStatusLabel`) intentionally stay
/// on `AppViewModel` for one more pass — they are the most read of the public
/// methods and pulling them out is the next careful slice. Moving the state
/// first keeps the public API (`appViewModel.currentMission`, `appViewModel.scenarioHistories`)
/// stable and the build green.
final class ScenarioState: ObservableObject, Codable {
    @Published var currentMission: PracticeScenario
    @Published var availableScenarios: [PracticeScenario]
    @Published var scenarioHistories: [PracticeScenario: [PracticeSession]]
    @Published var selectedAnchorByScenario: [PracticeScenario: UUID]

    init(
        currentMission: PracticeScenario = .weeklyUpdate,
        availableScenarios: [PracticeScenario] = PracticeScenario.allCases,
        scenarioHistories: [PracticeScenario: [PracticeSession]] = [:],
        selectedAnchorByScenario: [PracticeScenario: UUID] = [:]
    ) {
        self.currentMission = currentMission
        self.availableScenarios = availableScenarios
        self.scenarioHistories = scenarioHistories
        self.selectedAnchorByScenario = selectedAnchorByScenario
    }

    private enum CodingKeys: String, CodingKey {
        case currentMission
        case availableScenarios
        case scenarioHistories
        case selectedAnchorByScenario
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentMission = try container.decodeIfPresent(PracticeScenario.self, forKey: .currentMission) ?? .weeklyUpdate
        availableScenarios = try container.decodeIfPresent([PracticeScenario].self, forKey: .availableScenarios) ?? PracticeScenario.allCases
        scenarioHistories = try container.decodeIfPresent([PracticeScenario: [PracticeSession]].self, forKey: .scenarioHistories) ?? [:]
        selectedAnchorByScenario = try container.decodeIfPresent([PracticeScenario: UUID].self, forKey: .selectedAnchorByScenario) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentMission, forKey: .currentMission)
        try container.encode(availableScenarios, forKey: .availableScenarios)
        try container.encode(scenarioHistories, forKey: .scenarioHistories)
        try container.encode(selectedAnchorByScenario, forKey: .selectedAnchorByScenario)
    }

    // MARK: - Reactive derivations (read-only views of the published state)

    var currentScenarioHistory: [PracticeSession] {
        scenarioHistories[currentMission] ?? []
    }

    var currentScenarioUserHistory: [PracticeSession] {
        currentScenarioHistory.filter(\.isUserOwned)
    }

    var currentScenarioStarterHistory: [PracticeSession] {
        currentScenarioHistory.filter { !$0.isUserOwned }
    }

    var latestSession: PracticeSession? {
        currentScenarioUserHistory.first ?? currentScenarioStarterHistory.first
    }

    // MARK: - Pure scenario-domain helpers (no AppViewModel side effects)

    /// User-owned session count for a specific scenario.
    func userOwnedSessionCount(in scenario: PracticeScenario) -> Int {
        (scenarioHistories[scenario] ?? []).filter(\.isUserOwned).count
    }

    /// User-owned count for the current mission (convenience).
    var currentUserOwnedSessionCount: Int {
        userOwnedSessionCount(in: currentMission)
    }

    /// Latest user-owned session in a scenario, falling back to its seeded starter.
    func latestSession(in scenario: PracticeScenario) -> PracticeSession? {
        let history = scenarioHistories[scenario] ?? []
        return history.first(where: \.isUserOwned) ?? history.first
    }

    /// First session in a scenario's history — used as a fallback when no
    /// user-owned sessions exist yet.
    func sampleSession(in scenario: PracticeScenario) -> PracticeSession? {
        scenarioHistories[scenario]?.first
    }

    /// Pick a default compare anchor for a scenario that doesn't have one yet.
    /// The first *non-latest* session becomes the anchor so the user has
    /// something to compare against on first compare.
    func ensureAnchorSelection(for scenario: PracticeScenario) {
        guard selectedAnchorByScenario[scenario] == nil else { return }
        if let defaultAnchor = scenarioHistories[scenario]?.dropFirst().first {
            selectedAnchorByScenario[scenario] = defaultAnchor.id
        }
    }

    /// Set the compare anchor for the current mission.
    func selectCompareAnchor(_ session: PracticeSession) {
        selectedAnchorByScenario[currentMission] = session.id
    }

    /// Is the given session the current compare anchor for the current mission?
    func isSelectedAnchor(_ session: PracticeSession) -> Bool {
        selectedCompareAnchor?.id == session.id
    }

    /// Read-only: the current compare anchor for the current mission, if any.
    var selectedCompareAnchor: PracticeSession? {
        guard let anchorID = selectedAnchorByScenario[currentMission] else { return nil }
        return scenarioHistories[currentMission]?.first { $0.id == anchorID }
    }

    // MARK: - History aggregations (pure scenario-domain)

    /// Total number of session entries across all scenarios, by capture source.
    func count(where predicate: (PracticeSession) -> Bool) -> Int {
        scenarioHistories.values
            .flatMap { $0 }
            .filter(predicate)
            .count
    }

    /// Count of sessions that were recorded on this device.
    var recordedHistoryCount: Int {
        count(where: { $0.captureSource == .recorded })
    }

    /// Count of sessions that were imported from a pocket-copy export.
    var importedHistoryCount: Int {
        count(where: { $0.captureSource == .imported })
    }

    /// Count of sessions that came from the seeded starter histories.
    var seededHistoryCount: Int {
        count(where: { $0.captureSource == .seeded })
    }

    // MARK: - Quick rep copy (scenario-bound)

    /// Hint line for the "quick rep" affordance, by scenario.
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
}
