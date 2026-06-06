import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Tab bar appearance moved to App.swift for single setup (avoids re-init churn)

    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {
            NavigationStack {
                TodayMissionView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.circle.fill")
            }
            .tag(AppViewModel.AppTab.today)

            NavigationStack {
                PracticeRecordView()
            }
            .tabItem {
                Label("Practice", systemImage: "waveform.path.ecg.circle.fill")
            }
            .tag(AppViewModel.AppTab.practice)

            NavigationStack {
                ProgressView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
            }
            .tag(AppViewModel.AppTab.progress)

            NavigationStack {
                CoachTrustView()
            }
            .tabItem {
                Label("Coach", systemImage: "person.crop.circle.badge.checkmark")
            }
            .tag(AppViewModel.AppTab.coach)
        }
        .tint(KatieColors.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: appViewModel.selectedTab) { _ in
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
