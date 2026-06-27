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

            // Interview tab: InterviewPracticeView already wraps itself in
            // a NavigationStack so it can be presented as a sheet from
            // RootView without modification. Don't double-wrap here.
            InterviewPracticeView()
                .tabItem {
                    Label("Interview", systemImage: "person.wave.2.fill")
                }
                .tag(AppViewModel.AppTab.interview)
        }
        .tint(KatieColors.accent)
        // KAT-283 audit: remove the iOS 26 Liquid Glass floating tab bar
        // behavior. The previous `.toolbarBackground(.ultraThinMaterial, for: .tabBar)`
        // + `.toolbarBackground(.visible, for: .tabBar)` combo triggered the
        // floating glass tab bar (rendered at ~80% width, floating in the
        // middle of the screen). With KatieSpeechCoachNativeApp.init() now
        // using `configureWithOpaqueBackground()` + `isTranslucent = false`,
        // the tab bar returns to the traditional full-width bottom style.
        // Tab bar appearance is configured globally in KatieSpeechCoachNativeApp.init().
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
