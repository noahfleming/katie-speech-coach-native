import Foundation
import Combine

final class LearnerProfile: ObservableObject, Codable {
    @Published var firstName: String = "Noah"
    @Published var role: String = "Product builder"
    @Published var firstLanguage: String = "English"
    @Published var otherLanguages: String = ""
    @Published var firstGoal: String = "Clearer, calmer work communication"
    @Published var focusScenario: PracticeScenario = .weeklyUpdate
    @Published var communicationEnvironment: CommunicationEnvironment = .teamMeeting
    @Published var listenerPressure: ListenerPressure = .mixed
    @Published var listenerFrictionPoint: ListenerFrictionPoint = .keyWords
    @Published var transferHypothesisFeedback: TransferHypothesisFeedback = .notSureYet

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

    required init(from decoder: Decoder) throws {
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
