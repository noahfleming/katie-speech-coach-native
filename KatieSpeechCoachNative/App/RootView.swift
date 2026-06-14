import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.hasCompletedOnboarding {
                if appViewModel.shouldShowFirstBaselineGate {
                    NavigationStack {
                        FirstBaselineView()
                    }
                } else {
                    MainTabView()
                }
            } else {
                NavigationStack {
                    OnboardingView()
                }
            }
        }
        .preferredColorScheme(.dark)
        .background(
            LinearGradient(
                colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                ZStack {
                    RadialGradient(
                        colors: [KatieColors.appBackgroundGlow, .clear],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 420
                    )
                    RadialGradient(
                        colors: [KatieColors.appBackgroundGlowSecondary, .clear],
                        center: .topTrailing,
                        startRadius: 12,
                        endRadius: 360
                    )
                    RadialGradient(
                        colors: [KatieColors.appBackgroundGlowTertiary, .clear],
                        center: .bottomLeading,
                        startRadius: 20,
                        endRadius: 520
                    )
                }
            }
            .ignoresSafeArea()
        )
        .sheet(isPresented: $appViewModel.isInterviewModePresented) {
            InterviewPracticeView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppViewModel())
}
