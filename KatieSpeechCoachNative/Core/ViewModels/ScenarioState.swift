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
}
