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

    /// Reminder date `hours` from now. The fallback keeps the result in the
    /// future (never `.now`) so a calendar-arithmetic edge case can't schedule a
    /// notification that fires immediately.
    func reminderDate(hoursFromNow hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: .now)
            ?? Date.now.addingTimeInterval(TimeInterval(hours) * 3_600)
    }

    /// Tomorrow at the given hour/minute local time.
    func reminderDateTomorrow(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)
            ?? Date.now.addingTimeInterval(86_400)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) ?? tomorrow
    }

    /// Next weekday (Mon-Fri) at the given hour/minute local time.
    func reminderDateNextWorkday(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var candidate = calendar.date(byAdding: .day, value: 1, to: .now)
            ?? Date.now.addingTimeInterval(86_400)

        while calendar.isDateInWeekend(candidate) {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate)
                ?? candidate.addingTimeInterval(86_400)
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: candidate) ?? candidate
    }

    // MARK: - UI helpers (state-dependent)

    /// The date the reminder card should show in the editor — either the
    /// existing plan's fire date or the default (tomorrow 9 AM).
    var draftDate: Date {
        reminderPlan?.fireDate ?? Self.defaultReminderDate(from: .now)
    }

    /// Pre-baked preset options for the reminder card's "quick pick" UI.
    var quickPresets: [ReminderQuickPreset] {
        [
            ReminderQuickPreset(title: "In 2 hours", fireDate: reminderDate(hoursFromNow: 2)),
            ReminderQuickPreset(title: "Tomorrow 9 AM", fireDate: reminderDateTomorrow(hour: 9, minute: 0)),
            ReminderQuickPreset(title: "Next workday 9 AM", fireDate: reminderDateNextWorkday(hour: 9, minute: 0))
        ]
    }

    /// "EEEE · h:mm a" formatter for the reminder card.
    private static let draftTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · h:mm a"
        return formatter
    }()

    /// Human-readable label for the draft date (e.g. "Monday · 9:00 AM").
    var draftTimeLabel: String {
        Self.draftTimeFormatter.string(from: draftDate)
    }
}
