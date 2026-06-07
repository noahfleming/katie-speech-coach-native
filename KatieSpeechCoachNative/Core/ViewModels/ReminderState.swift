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

    // MARK: - Reminder date helpers (pure, no state)

    /// Default reminder date (tomorrow at 9 AM local) when no plan exists yet.
    static func defaultReminderDate(from date: Date) -> Date {
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextDay) ?? nextDay
    }

    /// Reminder date `hours` from now.
    func reminderDate(hoursFromNow hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: .now) ?? .now
    }

    /// Tomorrow at the given hour/minute local time.
    func reminderDateTomorrow(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) ?? tomorrow
    }

    /// Next weekday (Mon-Fri) at the given hour/minute local time.
    func reminderDateNextWorkday(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var candidate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now

        while calendar.isDateInWeekend(candidate) {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: candidate) ?? candidate
    }
}
