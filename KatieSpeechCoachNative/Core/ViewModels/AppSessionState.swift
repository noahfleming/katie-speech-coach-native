import Foundation
import Combine

final class AppSessionState: ObservableObject, Codable {
    @Published var hasCompletedOnboarding: Bool
    @Published var hasDismissedFirstBaselineGate: Bool
    @Published var selectedTab: AppViewModel.AppTab

    init(
        hasCompletedOnboarding: Bool = false,
        hasDismissedFirstBaselineGate: Bool = false,
        selectedTab: AppViewModel.AppTab = .today
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasDismissedFirstBaselineGate = hasDismissedFirstBaselineGate
        self.selectedTab = selectedTab
    }

    private enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case hasDismissedFirstBaselineGate
        case selectedTab
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        hasDismissedFirstBaselineGate = try container.decodeIfPresent(Bool.self, forKey: .hasDismissedFirstBaselineGate) ?? false
        selectedTab = try container.decodeIfPresent(AppViewModel.AppTab.self, forKey: .selectedTab) ?? .today
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(hasDismissedFirstBaselineGate, forKey: .hasDismissedFirstBaselineGate)
        try container.encode(selectedTab, forKey: .selectedTab)
    }
}
