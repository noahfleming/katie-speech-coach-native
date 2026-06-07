import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // KAT-209 (architecture + UI audit 2026-06-07): expose the tab bar to
    // VoiceOver with explicit role/label/hint instead of the default
    // "Tab Bar" group. Each tab now reads as "Today, tab, 1 of 4, selected"
    // for screen-reader users, instead of an unlabeled container.
    private var tabOrder: [AppViewModel.AppTab] {
        [.today, .practice, .progress, .coach]
    }

    private func tabPositionLabel(_ tab: AppViewModel.AppTab) -> String {
        guard let position = tabOrder.firstIndex(of: tab) else {
            return "tab"
        }
        return "tab, \(position + 1) of \(tabOrder.count)"
    }

    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {
            NavigationStack {
                TodayMissionView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.circle.fill")
            }
            .tag(AppViewModel.AppTab.today)
            .accessibilityLabel("Today, \(tabPositionLabel(.today))")
            .accessibilityAddTraits(appViewModel.selectedTab == .today ? .isSelected : [])

            NavigationStack {
                PracticeRecordView()
            }
            .tabItem {
                Label("Practice", systemImage: "waveform.path.ecg.circle.fill")
            }
            .tag(AppViewModel.AppTab.practice)
            .accessibilityLabel("Practice, \(tabPositionLabel(.practice))")
            .accessibilityAddTraits(appViewModel.selectedTab == .practice ? .isSelected : [])

            NavigationStack {
                ProgressView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
            }
            .tag(AppViewModel.AppTab.progress)
            .accessibilityLabel("Progress, \(tabPositionLabel(.progress))")
            .accessibilityAddTraits(appViewModel.selectedTab == .progress ? .isSelected : [])

            NavigationStack {
                CoachTrustView()
            }
            .tabItem {
                Label("Coach", systemImage: "person.crop.circle.badge.checkmark")
            }
            .tag(AppViewModel.AppTab.coach)
            .accessibilityLabel("Coach, \(tabPositionLabel(.coach))")
            .accessibilityAddTraits(appViewModel.selectedTab == .coach ? .isSelected : [])
        }
        .tint(KatieColors.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .accessibilityLabel("Main tab bar")
        .onChange(of: appViewModel.selectedTab) { _, _ in
            appViewModel.persistSelectedTab()
        }
        .sheet(isPresented: $appViewModel.isReviewPresented) {
            NavigationStack {
                ReviewRetakeView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                appViewModel.isReviewPresented = false
                            }
                        }
                    }
            }
            .presentationDetents(horizontalSizeClass == .compact ? [.medium, .large] : [.large])
            .presentationDragIndicator(.visible)
        }
    }
}
