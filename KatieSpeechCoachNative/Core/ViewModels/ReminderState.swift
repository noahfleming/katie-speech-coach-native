import Foundation
import Combine

/// KAT-206: Reminder state extracted from AppViewModel.
///
/// This first slice owns the four @Published flags that make up the reminder
/// panel's reactive surface. The notification / scheduling helpers (request
/// permission, schedule + clear, fire-date label) intentionally stay on
/// `AppViewModel` for now — they reach into `ScenarioState` (`currentMission`,
/// `sampleSession`, `latestSession`) and pulling them out is the next careful
/// slice. Moving state first keeps the public API (`appViewModel.reminderPlan`,
/// `appViewModel.reminderTone`, …) stable and the build green.
final class ReminderState: ObservableObject, Codable {
    @Published var reminderPlan: ReminderPlan?
    @Published var reminderPermissionState: ReminderPermissionState
    @Published var reminderTone: ReminderTone
    @Published var reminderFlowMessage: ReminderFlowMessage?

    init(
        reminderPlan: ReminderPlan? = nil,
        reminderPermissionState: ReminderPermissionState = .unknown,
        reminderTone: ReminderTone = .workday,
        reminderFlowMessage: ReminderFlowMessage? = nil
    ) {
        self.reminderPlan = reminderPlan
        self.reminderPermissionState = reminderPermissionState
        self.reminderTone = reminderTone
        self.reminderFlowMessage = reminderFlowMessage
    }

    private enum CodingKeys: String, CodingKey {
        case reminderPlan
        case reminderPermissionState
        case reminderTone
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reminderPlan = try container.decodeIfPresent(ReminderPlan.self, forKey: .reminderPlan)
        reminderPermissionState = try container.decodeIfPresent(ReminderPermissionState.self, forKey: .reminderPermissionState) ?? .unknown
        reminderTone = try container.decodeIfPresent(ReminderTone.self, forKey: .reminderTone) ?? .workday
        reminderFlowMessage = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(reminderPlan, forKey: .reminderPlan)
        try container.encode(reminderPermissionState, forKey: .reminderPermissionState)
        try container.encode(reminderTone, forKey: .reminderTone)
    }

    // MARK: - Mutators (state-local)

    func clearReminderFlowMessage() {
        reminderFlowMessage = nil
    }
}
