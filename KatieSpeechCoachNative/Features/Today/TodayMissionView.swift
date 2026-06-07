import SwiftUI

struct TodayMissionView: View {
    private enum SecondaryPanel {
        case context
        case activePacks
        case allPacks
        case reminder
    }

    private struct QuickRepRunwayStep: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let accent: Color

        var id: String { title }
    }

    private enum Layout {
        static let compactSectionSpacing: CGFloat = 40
        static let regularSectionSpacing: CGFloat = 24
        static let screenHorizontalPadding: CGFloat = 20
        static let screenTopPadding: CGFloat = 20
        static let screenBottomPaddingCompact: CGFloat = 32
        static let screenBottomPaddingRegular: CGFloat = 24
        static let railSpacing: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let heroSpacing: CGFloat = 14
        static let headerSpacingRegular: CGFloat = 12
        static let inlineSpacing: CGFloat = 10
        static let chipSpacing: CGFloat = 8
        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 6
        static let cardCornerRadius: CGFloat = 18
        static let innerCardCornerRadius: CGFloat = 16
        static let editorCornerRadius: CGFloat = 14
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    @State private var isPremiumActionRunning = false
    @State private var isRefreshingPremiumStore = false
    @State private var isRestoringPremiumPurchases = false
    @State private var isCoachReadoutExpanded = false
    @State private var isLanguageFocusExpanded = false
    @State private var isDeeperCoachingExpanded = false
    @State private var isFocusedToolsExpanded = false
    @State private var isScenarioSwitcherExpanded = false
    @State private var isContinuityExpanded = false
    @State private var isTodayQueueExpanded = false

    // MARK: - Layout (size class + adaptive metrics)

    private var usesWideTodayLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var usesWideReminderPresetLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var usesCompactTodayLayout: Bool {
        !usesWideTodayLayout
    }

    private var reminderSurfaceLabel: String {
        usesWideReminderPresetLayout ? "this iPad" : "this iPhone"
    }

    private var todayContentMaxWidth: CGFloat {
        usesWideTodayLayout ? 980 : 760
    }

    private var todayBoardMetrics: [KatieGlanceMetric] {
        [
            KatieGlanceMetric(
                title: "Live pack",
                value: appViewModel.currentMission.packTitle,
                detail: appViewModel.currentMission.listenerOutcome,
                accent: KatieColors.gold
            ),
            KatieGlanceMetric(
                title: "Reminder owner",
                value: appViewModel.reminderPlan?.scenario.packTitle ?? "Open lane",
                detail: appViewModel.reminderPlan.map { "\($0.fireDate.formatted(date: .omitted, time: .shortened)) on \(reminderSurfaceLabel)." } ?? "Save one real line, then Katie can protect it next.",
                accent: KatieColors.mint
            ),
            KatieGlanceMetric(
                title: "Capture lane",
                value: appViewModel.microphonePermissionState.title,
                detail: appViewModel.microphoneStatusLine,
                accent: KatieColors.accent
            )
        ]
    }

    // MARK: - Subviews (rails, boards, hero cards)

    private var todayBoardCard: some View {
        KatieGlanceBoard(
            eyebrow: "Today board",
            title: "Keep one clear line alive",
            detail: "Katie keeps \(appViewModel.currentMission.packTitle) in focus, makes reminder ownership obvious, and keeps the next move glanceable on \(reminderSurfaceLabel).",
            systemImage: "sun.max.fill",
            accent: KatieColors.gold,
            secondary: KatieColors.mint,
            metrics: todayBoardMetrics,
            footnote: "Next grounded move · \(appViewModel.currentPackNextStepLabel)"
        )
        .katieHeroAura(accent: KatieColors.gold, secondary: KatieColors.mint)
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompactPhoneLayout = !usesWideTodayLayout && proxy.size.width < 430
            let contentSpacing: CGFloat = isCompactPhoneLayout ? Layout.compactSectionSpacing : Layout.regularSectionSpacing
            let horizontalPadding: CGFloat = Layout.screenHorizontalPadding
            let headerSpacing: CGFloat = isCompactPhoneLayout ? Layout.inlineSpacing : Layout.headerSpacingRegular

            ScrollView {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    HStack(alignment: .center, spacing: headerSpacing) {
                        Image(systemName: "sun.max.fill")
                            .katieIconBadge(background: KatieColors.cardSecondary, foreground: KatieColors.gold, size: isCompactPhoneLayout ? 30 : 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today")
                                .font(isCompactPhoneLayout ? .title.bold() : .largeTitle.bold())
                                .foregroundStyle(KatieColors.textPrimary)
                            Text("One calm rep at a time")
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                        Spacer()
                    }

                    todayBoardCard
                        .padding(.bottom, isCompactPhoneLayout ? Layout.screenBottomPaddingCompact : Layout.screenBottomPaddingRegular)

                    if appViewModel.hasEarnedFirstWin {
                        if usesWideTodayLayout {
                            todayHeroRail
                            todaySupportRail
                            todayControlRail
                        } else {
                            missionHero
                            firstWinHero
                            reminderFlowBanner
                            quickRepSpotlightCard
                            focusedToolsCard
                            compactHomeControlsCard
                        }

                        if isLanguageFocusExpanded || isTodayQueueExpanded || isScenarioSwitcherExpanded || isContinuityExpanded {
                            compactHomeDetailCard
                        }

                        if appViewModel.currentMission == .managerOneOnOne {
                            managerPrepCard
                        }

                        deeperCoachingCard
                        if isDeeperCoachingExpanded {
                            coachReadoutCard
                            soundRadarCard
                            transferPlanCard
                        }
                    } else {
                        if usesWideTodayLayout {
                            todayStarterRail
                        } else {
                            firstSpeakingScanCard
                            todayQueueCard
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, Layout.screenTopPadding)
                .padding(.bottom, isCompactPhoneLayout ? Layout.screenBottomPaddingCompact : Layout.screenBottomPaddingRegular)
                .katieContentFrame(maxWidth: todayContentMaxWidth)
            }
        }
        .background(LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing).overlay { RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420) }.ignoresSafeArea())
    }

    @ViewBuilder
    private var todayHeroRail: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Layout.railSpacing) {
                missionHero
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                firstWinHero
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: Layout.railSpacing) {
                missionHero
                firstWinHero
            }
        }
    }

    @ViewBuilder
    private var todayStarterRail: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Layout.railSpacing) {
                firstSpeakingScanCard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                todayQueueCard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: Layout.railSpacing) {
                firstSpeakingScanCard
                todayQueueCard
            }
        }
    }

    @ViewBuilder
    private var todaySupportRail: some View {
        if appViewModel.reminderFlowMessage != nil {
            todayRail {
                reminderFlowBanner
            } secondary: {
                quickRepSpotlightCard
            }
        } else {
            quickRepSpotlightCard
        }
    }

    @ViewBuilder
    private var todayControlRail: some View {
        todayRail {
            focusedToolsCard
        } secondary: {
            compactHomeControlsCard
        }
    }

    private func todayRail<Primary: View, Secondary: View>(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Layout.railSpacing) {
                primary()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                secondary()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: Layout.railSpacing) {
                primary()
                secondary()
            }
        }
    }

    @ViewBuilder
    private var compactHomeDetailCard: some View {
        if isLanguageFocusExpanded {
            todaysLensCard
        } else if isTodayQueueExpanded {
            todayQueueCard
        } else if isScenarioSwitcherExpanded {
            scenarioSwitcher
        } else if isContinuityExpanded {
            continuityCard
        }
    }

    // MARK: - Secondary panel state (one-open-at-a-time helpers)

    private var activeSecondaryPanelLabel: String? {
        if isLanguageFocusExpanded {
            return "Context"
        }
        if isTodayQueueExpanded {
            return "Active packs"
        }
        if isScenarioSwitcherExpanded {
            return "All packs"
        }
        if isContinuityExpanded {
            return "Reminder handoff"
        }
        return nil
    }

    private func isSecondaryPanelExpanded(_ panel: SecondaryPanel) -> Bool {
        switch panel {
        case .context:
            return isLanguageFocusExpanded
        case .activePacks:
            return isTodayQueueExpanded
        case .allPacks:
            return isScenarioSwitcherExpanded
        case .reminder:
            return isContinuityExpanded
        }
    }

    private func collapseSecondaryPanels() {
        isLanguageFocusExpanded = false
        isTodayQueueExpanded = false
        isScenarioSwitcherExpanded = false
        isContinuityExpanded = false
    }

    private func toggleSecondaryPanel(_ panel: SecondaryPanel) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            let shouldOpen = !isSecondaryPanelExpanded(panel)
            collapseSecondaryPanels()

            guard shouldOpen else {
                return
            }

            switch panel {
            case .context:
                isLanguageFocusExpanded = true
            case .activePacks:
                isTodayQueueExpanded = true
            case .allPacks:
                isScenarioSwitcherExpanded = true
            case .reminder:
                isContinuityExpanded = true
            }
        }
    }

    private var missionHero: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top, spacing: Layout.heroSpacing) {
                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    KatieSectionEyebrow(title: "Today’s focus", systemImage: "target")

                    Text(appViewModel.currentMission.title)
                        .font(.title2.bold())
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(appViewModel.currentMission.missionPrompt)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)

                    HStack(spacing: Layout.inlineSpacing) {
                        KatieReplayBadge(title: appViewModel.currentMission.categoryLabel, systemImage: "square.grid.2x2.fill", accent: KatieColors.gold)
                        KatieReplayBadge(title: appViewModel.currentScenarioSnapshot.bestStreakLabel, systemImage: "sparkles", accent: KatieColors.mint)
                    }
                    .font(.caption.weight(.semibold))
                }

                Spacer(minLength: 0)

                KatieScenarioArtwork(systemImage: "target", accent: KatieColors.accent, secondary: KatieColors.gold)
            }
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.accent, secondary: KatieColors.gold)
    }

    private var firstWinHero: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            KatieSectionEyebrow(
                title: appViewModel.firstWinHeadline,
                systemImage: appViewModel.isPremiumUnlocked ? "checkmark.seal.fill" : appViewModel.activeScenarioUserRepCount > 0 ? "mic.circle.fill" : "sparkles",
                accent: KatieColors.mint
            )

            Text(appViewModel.firstWinMessage)
                .foregroundStyle(KatieColors.textSecondary)

            Label(appViewModel.firstWinTrustLine, systemImage: appViewModel.activeScenarioRecordedCount > 0 ? "mic.fill" : "sparkles.rectangle.stack.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(appViewModel.activeScenarioRecordedCount > 0 ? KatieColors.mint : KatieColors.textSecondary)

            Button(appViewModel.firstWinPrimaryActionTitle) {
                appViewModel.performFirstWinPrimaryAction {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
            }
            .buttonStyle(.katiePrimary())

            if appViewModel.activeScenarioUserRepCount == 1 {
                KatieWrap(spacing: Layout.chipSpacing, rowSpacing: Layout.chipSpacing) {
                    Text("First benchmark saved")
                        .modifier(KatieCapsuleLabelStyle())

                    Text("Your saved proof is the anchor now")
                        .modifier(KatieCapsuleLabelStyle())

                    Text("One more save unlocks compare")
                        .modifier(KatieCapsuleLabelStyle())
                }
            }

            if let featured = appViewModel.featuredWin {
                VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                    if appViewModel.hasEarnedCompare {
                        HStack(spacing: Layout.inlineSpacing) {
                            proofColumn(title: "Before", body: featured.beforeText)
                            proofColumn(title: "After", body: featured.afterText)
                        }
                    } else {
                        proofColumn(
                            title: appViewModel.hasEarnedFirstWin ? "Your first proof" : "Starter example",
                            body: appViewModel.hasEarnedFirstWin ? featured.afterText : featured.beforeText
                        )
                    }

                    if appViewModel.hasEarnedCompare {
                        KatieWrap(spacing: Layout.chipSpacing, rowSpacing: Layout.chipSpacing) {
                            Text(featured.sourceTag)
                                .modifier(KatieCapsuleLabelStyle())

                            Text(appViewModel.freshnessLabel(for: featured.latestSession))
                                .modifier(KatieCapsuleLabelStyle())

                            if let anchor = featured.anchorSession {
                                Text("Against \(appViewModel.freshnessLabel(for: anchor))")
                                    .modifier(KatieCapsuleLabelStyle())
                            }
                        }

                        if let anchor = featured.anchorSession {
                            featuredWinProofMetaStrip(title: "Earlier proof", session: anchor, accent: KatieColors.gold)
                        }

                        featuredWinProofMetaStrip(
                            title: featured.anchorSession == nil ? "Current proof" : "Latest proof",
                            session: featured.latestSession,
                            accent: KatieColors.mint
                        )

                        featuredWinReplayTruthCard(for: featured)
                    } else {
                        Text(appViewModel.hasEarnedFirstWin ? "One more saved rep turns this into a compare story." : "Save one real rep to start a compare story.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    KatieWrap(spacing: Layout.chipSpacing, rowSpacing: Layout.chipSpacing) {
                        Button(featured.anchorSession == nil ? "Open proof" : "Open compare") {
                            appViewModel.openReview(for: featured.scenario, anchor: featured.anchorSession)
                        }
                        .buttonStyle(
                            .katiePrimary(
                                fill: LinearGradient(
                                    colors: [KatieColors.cardSecondary, KatieColors.cardTertiary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                foreground: KatieColors.textPrimary
                            )
                        )

                        todayActionsMenu(for: featured.scenario, latest: featured.latestSession, anchor: featured.anchorSession, progressTitle: appViewModel.hasEarnedCompare ? "View compare story" : "Keep building this progress trail")
                    }
                }
            }
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.mint, secondary: KatieColors.accent)
        .sheet(isPresented: $appViewModel.isPremiumPreviewPresented) {
            premiumPreviewSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var momentumRail: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            Text("Progress right now")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.momentumSummaryLine)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: Layout.inlineSpacing) {
                ForEach(appViewModel.momentumRail) { milestone in
                    VStack(spacing: Layout.chipVerticalPadding) {
                        Circle()
                            .fill(milestone.isActive ? KatieColors.mint : KatieColors.cardSecondary)
                            .frame(width: 10, height: 10)

                        Text(milestone.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(milestone.isActive ? KatieColors.textPrimary : KatieColors.textSecondary)
                            .lineLimit(2)

                        Text(milestone.detail)
                            .font(.caption2)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .padding(Layout.cardSpacing)
                    .frame(maxWidth: .infinity)
                    .background(milestone.isActive ? KatieColors.cardBackground.opacity(0.8) : KatieColors.cardSecondary.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
                }
            }
        }
        .katieCard()
    }

    private var highlightedQuickRepPrompt: QuickRepPrompt? {
        appViewModel.quickRepRail.first(where: { $0.scenario == appViewModel.currentMission }) ?? appViewModel.quickRepRail.first
    }

    @ViewBuilder
    private var quickRepSpotlightCard: some View {
        if let prompt = highlightedQuickRepPrompt {
            let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario

            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Layout.cardSpacing) {
                        Image(systemName: "bolt.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(KatieColors.accent)
                            .padding(Layout.cardSpacing)
                            .background(KatieColors.accent.opacity(0.14), in: Circle())

                        VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                            Text("Tonight’s best quick rep")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)

                            Text(prompt.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Text(prompt.durationLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.chipVerticalPadding)
                            .background(KatieColors.cardSecondary, in: Capsule())
                    }

                    VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                        HStack(alignment: .top, spacing: Layout.cardSpacing) {
                            Image(systemName: "bolt.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(KatieColors.accent)
                                .padding(Layout.cardSpacing)
                                .background(KatieColors.accent.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                                Text("Tonight’s best quick rep")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(KatieColors.textSecondary)

                                Text(prompt.title)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Text(prompt.durationLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.chipVerticalPadding)
                            .background(KatieColors.cardSecondary, in: Capsule())
                    }
                }

                Text(prompt.detail)
                    .font(.callout)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                KatieWrap(spacing: Layout.chipSpacing, rowSpacing: Layout.chipSpacing) {
                    Text(prompt.statusLabel)
                        .modifier(KatieCapsuleLabelStyle(accent: reminderProtected ? KatieColors.mint : KatieColors.gold))

                    Text(prompt.continuityLine)
                        .modifier(KatieCapsuleLabelStyle(accent: reminderProtected ? KatieColors.mint : KatieColors.textSecondary))
                }

                Text(prompt.proofLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Label(prompt.hypothesisStatusLabel, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .fixedSize(horizontal: false, vertical: true)

                Text(prompt.hypothesisDetailLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                    Label("What stays in sync after this rep", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                        ForEach(quickRepRunwaySteps(for: prompt)) { step in
                            HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                Image(systemName: step.systemImage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(step.accent)
                                    .frame(width: 28, height: 28)
                                    .background(step.accent.opacity(0.14), in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(step.title)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(KatieColors.textPrimary)

                                    Text(step.detail)
                                        .font(.footnote)
                                        .foregroundStyle(KatieColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(Layout.cardSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(KatieColors.cardSecondary.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                        }
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: Layout.chipSpacing) {
                        Label("What you’ll say first", systemImage: "quote.bubble")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Spacer(minLength: 0)

                        Text(prompt.starterLine)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(1)
                    }

                    VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                        Label("What you’ll say first", systemImage: "quote.bubble")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Text(prompt.starterLine)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    appViewModel.launchQuickRep(for: prompt.scenario)
                } label: {
                    Label("Start quick rep", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.katiePrimary())
            }
            .padding(Layout.cardSpacing + KatieSpacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .katieCard()
        }
    }

    private func quickRepRunwaySteps(for prompt: QuickRepPrompt) -> [QuickRepRunwayStep] {
        appViewModel.quickRepRunwaySteps(for: prompt.scenario).map { step in
            QuickRepRunwayStep(
                title: step.title,
                detail: step.detail,
                systemImage: step.systemImage,
                accent: quickRepRunwayAccentColor(step.accent)
            )
        }
    }

    private func quickRepRunwayAccentColor(_ accent: QuickRepRunwayAccent) -> Color {
        switch accent {
        case .gold:
            KatieColors.gold
        case .accent:
            KatieColors.accent
        case .mint:
            KatieColors.mint
        }
    }

    private var focusedToolsCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top, spacing: Layout.cardSpacing) {
                VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                    Label("Focused tools", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Quick read, live momentum, and a 60–90 second quick rep stay tucked away until you want the extra support.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Button(isFocusedToolsExpanded ? "Close" : "Peek") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isFocusedToolsExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.chipHorizontalPadding)
                .padding(.vertical, Layout.chipVerticalPadding + KatieSpacing.xxs)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            KatieWrap(spacing: Layout.chipSpacing, rowSpacing: Layout.chipSpacing) {
                Text(appViewModel.firstSpeakingScan.savedLine)
                    .modifier(KatieCapsuleLabelStyle())
                Text(appViewModel.momentumSummaryLine)
                    .modifier(KatieCapsuleLabelStyle())
                Text("Quick rep · 60–90 sec")
                    .modifier(KatieCapsuleLabelStyle())
            }

            audioCaptureLaneCard

            if isFocusedToolsExpanded {
                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    firstSpeakingScanCard
                    momentumRail
                    quickRepRail
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .katieCard()
    }

    private var audioCaptureLaneCard: some View {
        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
            HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                Image(systemName: appViewModel.audioCaptureLane.systemImage)
                    .katieIconBadge(background: KatieColors.cardBackground, foreground: KatieColors.mint, size: 28)

                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Text(appViewModel.audioCaptureLane.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.audioCaptureLane.detail)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }

            Text(appViewModel.audioCaptureLane.actionTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var compactHomeControlsCard: some View {
        let activeReminder = appViewModel.reminderPlan?.scenario == appViewModel.currentMission
        let activeQueueCount = appViewModel.todayQueue.count
        let focusLabel = activeReminder
            ? "Reminder protecting \(appViewModel.currentMission.packTitle)"
            : "\(appViewModel.currentMission.packTitle) in focus"

        return VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: KatieSpacing.base) {
                    compactHomeControlsSummary

                    Spacer(minLength: 0)

                    compactHomeStatusChip(activeReminder: activeReminder, focusLabel: focusLabel)
                }

                VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                    compactHomeControlsSummary
                    compactHomeStatusChip(activeReminder: activeReminder, focusLabel: focusLabel)
                }
            }

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                queueSummaryChip(title: "Active packs", value: activeQueueCount, accent: KatieColors.mint)
                queueSummaryChip(title: "Replay-ready", value: appViewModel.activeScenarioReplayReadyCount, accent: KatieColors.gold)
                queueSummaryChip(title: activeReminder ? "Reminder on" : "Reminder off", value: activeReminder ? 1 : 0, accent: KatieColors.accent)
            }

            VStack(alignment: .leading, spacing: KatieSpacing.xs) {
                Text("Reminder handoff for \(appViewModel.currentMission.packTitle)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
                Text(appViewModel.reminderCallToActionLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                Text(appViewModel.currentContinuityStrip.title)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                Button(isSecondaryPanelExpanded(.context) ? "Hide context" : "Open context") {
                    toggleSecondaryPanel(.context)
                }
                .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))

                Button(isSecondaryPanelExpanded(.activePacks) ? "Hide active packs" : "Open active packs") {
                    toggleSecondaryPanel(.activePacks)
                }
                .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))

                Button(isSecondaryPanelExpanded(.allPacks) ? "Hide all packs" : "Browse all packs") {
                    toggleSecondaryPanel(.allPacks)
                }
                .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))

                Button(isSecondaryPanelExpanded(.reminder) ? "Close reminder handoff" : "Tune reminder handoff") {
                    toggleSecondaryPanel(.reminder)
                }
                .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))
            }
        }
        .katieCard()
    }

    private var compactHomeControlsSummary: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.xs) {
            Label("\(appViewModel.currentMission.packTitle) in focus", systemImage: "square.stack.3d.up")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Today stays centered on \(appViewModel.currentMission.packTitle), with context, other packs, reminder handoff, and deeper coaching tucked behind the chips.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
    }

    private func compactHomeStatusChip(activeReminder: Bool, focusLabel: String) -> some View {
        Text(activeSecondaryPanelLabel ?? focusLabel)
            .font(.caption.weight(.semibold))
            .foregroundStyle(activeSecondaryPanelLabel == nil ? (activeReminder ? KatieColors.accent : KatieColors.mint) : KatieColors.gold)
            .padding(.horizontal, KatieSpacing.md)
            .padding(.vertical, KatieSpacing.xs)
            .background(KatieColors.cardSecondary)
            .clipShape(Capsule())
    }

    private var deeperCoachingCard: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            HStack(alignment: .top, spacing: KatieSpacing.base) {
                VStack(alignment: .leading, spacing: KatieSpacing.xs) {
                    Label("Deeper coaching", systemImage: "waveform.path.ecg.rectangle")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Today already has enough to ship the next rep. Open the SLP-informed detail only when you want the sound-pattern brief, transfer plan, and pack-specific coaching stack.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Button(isDeeperCoachingExpanded ? "Close" : "Peek") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        isDeeperCoachingExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, KatieSpacing.base)
                .padding(.vertical, KatieSpacing.sm)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                KatieReplayBadge(title: appViewModel.currentSoundPatternRadar.title, systemImage: "waveform.path", accent: KatieColors.mint)
                KatieReplayBadge(title: appViewModel.currentConversationTransferPlan.title, systemImage: "arrow.triangle.branch", accent: KatieColors.gold)
                if appViewModel.currentMission == .managerOneOnOne {
                    KatieReplayBadge(title: "1:1 prep", systemImage: "person.2.fill", accent: KatieColors.accent)
                }
            }
            .font(.caption.weight(.semibold))
        }
        .katieCard()
    }

    private var firstSpeakingScanCard: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            Label("Quick read", systemImage: "waveform.path.ecg.rectangle")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            scanRow(title: "Already steady", body: appViewModel.firstSpeakingScan.strongestMove)
            scanRow(title: "Listeners may lose first", body: appViewModel.firstSpeakingScan.listenerRisk)
            scanRow(title: "First proof path", body: appViewModel.firstSpeakingScan.firstWinPlan)

            if usesCompactTodayLayout {
                VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                    Label("Saved line: \(appViewModel.firstSpeakingScan.savedLine)", systemImage: "lock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                        .fixedSize(horizontal: false, vertical: true)

                    KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                        Label(appViewModel.compactCaptureSourceLabel(for: appViewModel.latestSession), systemImage: appViewModel.latestSession.captureSource.systemImage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, KatieSpacing.sm)
                            .padding(.vertical, KatieSpacing.xxs)
                            .background(KatieColors.cardSecondary)
                            .clipShape(Capsule())

                        Text(appViewModel.freshnessLabel(for: appViewModel.latestSession))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, KatieSpacing.sm)
                            .padding(.vertical, KatieSpacing.xxs)
                            .background(KatieColors.cardSecondary)
                            .clipShape(Capsule())
                    }
                }
            } else {
                HStack(spacing: KatieSpacing.sm) {
                    Label("Saved line: \(appViewModel.firstSpeakingScan.savedLine)", systemImage: "lock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Label(appViewModel.compactCaptureSourceLabel(for: appViewModel.latestSession), systemImage: appViewModel.latestSession.captureSource.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                        .padding(.horizontal, KatieSpacing.sm)
                        .padding(.vertical, KatieSpacing.xxs)
                        .background(KatieColors.cardSecondary)
                        .clipShape(Capsule())

                    Text(appViewModel.freshnessLabel(for: appViewModel.latestSession))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                        .padding(.horizontal, KatieSpacing.sm)
                        .padding(.vertical, KatieSpacing.xxs)
                        .background(KatieColors.cardSecondary)
                        .clipShape(Capsule())
                }
            }
        }
        .katieCard()
    }

    private var todaysLensCard: some View {
        let keepsCompactHome = appViewModel.hasEarnedFirstWin

        return VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            HStack(alignment: .top, spacing: KatieSpacing.base) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Label("Today’s lens", systemImage: "scope")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(keepsCompactHome && !isLanguageFocusExpanded
                         ? "Goal, context, and SLP-informed framing stay tucked away until you want the deeper read."
                         : "Keep the plan compact: one real context, one sound-first hypothesis, one pack to protect.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 12)

                Button(isLanguageFocusExpanded ? "Close" : "Peek") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        isLanguageFocusExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, KatieSpacing.base)
                .padding(.vertical, KatieSpacing.sm)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                Text(appViewModel.goalFocusTitle)
                    .modifier(KatieCapsuleLabelStyle())
                Text(appViewModel.profileContextHeadline)
                    .modifier(KatieCapsuleLabelStyle())
                Text(appViewModel.currentMission.packTitle)
                    .modifier(KatieCapsuleLabelStyle())
                Text(appViewModel.transferHypothesisStatusTitle)
                    .modifier(KatieCapsuleLabelStyle())
            }

            if !keepsCompactHome || isLanguageFocusExpanded {
                VStack(alignment: .leading, spacing: KatieSpacing.base) {
                    scanRow(title: "Communication goal", body: appViewModel.goalFocusTitle)
                    scanRow(title: "Speaking context", body: appViewModel.profileContextHeadline)
                    scanRow(title: "Sound-first hypothesis", body: appViewModel.languageAssessmentSnapshot.soundFocus)

                    hypothesisStanceCard

                    Text(appViewModel.coachingFrameAdjustmentLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(appViewModel.recommendedScenarioAlignmentLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                        goalFocusMenu
                        startingPackMenu

                        Button(appViewModel.isRecommendedScenarioAlignedForToday ? "Today already matches context" : "Swap to recommended pack") {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                appViewModel.selectScenario(appViewModel.recommendedScenarioForCurrentContext)
                            }
                        }
                        .modifier(KatieActionChipStyle(
                            background: appViewModel.isRecommendedScenarioAlignedForToday ? KatieColors.cardBackground : KatieColors.accent,
                            foreground: appViewModel.isRecommendedScenarioAlignedForToday ? KatieColors.textSecondary : .black,
                            horizontalPadding: KatieSpacing.md
                        ))
                        .disabled(appViewModel.isRecommendedScenarioAlignedForToday)
                    }

                    Label("Guardrail: Katie offers SLP-informed coaching for clearer speech and professional communication. It reflects observed patterns and carryover risk, not therapy or diagnosis.", systemImage: "checkmark.shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.gold)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .katieCard()
    }

    private var hypothesisStanceCard: some View {
        VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
            HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                Label("Hypothesis stance in this pack", systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: KatieSpacing.base)

                Text(appViewModel.transferHypothesisStatusTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.xs)
                    .background(KatieColors.cardBackground)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.trailing)
            }

            Text(appViewModel.transferHypothesisPracticeBridgeLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.transferHypothesisFollowThroughLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(KatieSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var todayQueueCard: some View {
        let fullQueue = appViewModel.todayQueue
        let collapsedQueueCount = 1
        let isExpandable = fullQueue.count > collapsedQueueCount
        let visibleEntries = isTodayQueueExpanded ? fullQueue : Array(fullQueue.prefix(collapsedQueueCount))
        let hiddenCount = max(0, fullQueue.count - visibleEntries.count)
        let bestNextEntry = fullQueue.first
        let replayReadyCount = fullQueue.filter { entry in
            let history = appViewModel.scenarioHistories[entry.scenario] ?? []
            return history.contains { $0.isUserOwned && appViewModel.hasPlayback(for: $0) }
        }.count
        let compareReadyCount = fullQueue.filter { appViewModel.userOwnedSessionCount(in: $0.scenario) >= 2 }.count
        let activeReminderCount = fullQueue.filter(\.reminderCue.isActive).count

        return VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Label("Active packs", systemImage: "rectangle.stack.badge.play.fill")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("Keep one best-next pack in front and leave the rest tucked away until you need them.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: KatieSpacing.base)

                Text(appViewModel.hasAnyUserProof ? "\(fullQueue.count) packs" : "Waiting on first proof")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.xs)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
            }

            if appViewModel.hasAnyUserProof {
                KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                    queueSummaryChip(title: "Protected", value: activeReminderCount, accent: KatieColors.accent)
                    queueSummaryChip(title: "Replay-ready", value: replayReadyCount, accent: KatieColors.mint)
                    queueSummaryChip(title: "Compare-ready", value: compareReadyCount, accent: KatieColors.gold)
                }

                Text(isTodayQueueExpanded ? "All active packs are open so you can steer deliberately." : "Only the best-next pack stays open by default so Today still feels calm." )
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)

                if let bestNextEntry {
                    let bestNextHistory = appViewModel.scenarioHistories[bestNextEntry.scenario] ?? []
                    let bestNextLatest = bestNextHistory.first(where: \.isUserOwned) ?? bestNextHistory.first
                    let bestNextAnchor = bestNextHistory.filter(\.isUserOwned).dropFirst().first

                    VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                                    Text("Best next pack")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(KatieColors.textSecondary)
                                    Text(bestNextEntry.scenario.packTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(KatieColors.textPrimary)
                                }

                                Spacer(minLength: KatieSpacing.sm)

                                Text(bestNextEntry.statusLabel)
                                    .modifier(KatieCapsuleLabelStyle())
                            }

                            VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                                    Text("Best next pack")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(KatieColors.textSecondary)
                                    Text(bestNextEntry.scenario.packTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(KatieColors.textPrimary)
                                }

                                Text(bestNextEntry.statusLabel)
                                    .modifier(KatieCapsuleLabelStyle())
                            }
                        }

                        Text(bestNextEntry.nextStepLine)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textPrimary.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: KatieSpacing.sm) {
                                Button(bestNextEntry.actionTitle) {
                                    handleTodayQueuePrimaryAction(bestNextEntry)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, KatieSpacing.base)
                                .padding(.vertical, KatieSpacing.md)
                                .background(todayQueueActionBackground(for: bestNextEntry))
                                .foregroundStyle(todayQueueActionForeground(for: bestNextEntry))
                                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))

                                todayActionsMenu(for: bestNextEntry.scenario, latest: bestNextLatest, anchor: bestNextAnchor, label: "Peek")
                            }

                            VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                                Button(bestNextEntry.actionTitle) {
                                    handleTodayQueuePrimaryAction(bestNextEntry)
                                }
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, KatieSpacing.md)
                                .background(todayQueueActionBackground(for: bestNextEntry))
                                .foregroundStyle(todayQueueActionForeground(for: bestNextEntry))
                                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))

                                todayActionsMenu(for: bestNextEntry.scenario, latest: bestNextLatest, anchor: bestNextAnchor, label: "Peek")
                            }
                        }
                    }
                    .padding(KatieSpacing.base)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                }
            }

            if !appViewModel.hasAnyUserProof {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    KatieSectionEyebrow(title: appViewModel.currentMission.packTitle, systemImage: "sparkles.rectangle.stack.fill", accent: KatieColors.gold)

                    Text("Save one real rep and the queue wakes up. Katie will start nudging with your own proof instead of generic encouragement.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(appViewModel.scenarioNextStepLine(for: appViewModel.currentMission))
                        .font(.caption)
                        .foregroundStyle(KatieColors.textPrimary.opacity(0.82))

                    Button(appViewModel.firstWinPrimaryActionTitle) {
                        appViewModel.performFirstWinPrimaryAction {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(url)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.chipHorizontalPadding)
                    .padding(.vertical, Layout.inlineSpacing)
                    .background(KatieColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                }
                .padding(Layout.heroSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
            } else {
                if isExpandable && !isTodayQueueExpanded {
                    Text("\(hiddenCount) more packs stay tucked away until you want the full list.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                }

                ForEach(visibleEntries) { entry in
                    let history = appViewModel.scenarioHistories[entry.scenario] ?? []
                    let latest = history.first(where: \.isUserOwned) ?? history.first
                    let anchor = history.filter(\.isUserOwned).dropFirst().first

                    VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                KatieScenarioArtwork(systemImage: entry.reminderCue.systemImage, accent: entry.reminderCue.isActive ? KatieColors.accent : KatieColors.cardTertiary, secondary: KatieColors.mint)

                                VStack(alignment: .leading, spacing: KatieSpacing.xs) {
                                    HStack(spacing: KatieSpacing.sm) {
                                        Text(entry.scenario.packTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KatieColors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(entry.statusLabel)
                                            .modifier(KatieCapsuleLabelStyle())
                                    }

                                    Text(entry.emphasisLine)
                                        .font(.footnote)
                                        .foregroundStyle(KatieColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: KatieSpacing.sm)

                                VStack(alignment: .trailing, spacing: KatieSpacing.sm) {
                                    if let freshnessLabel = entry.freshnessLabel {
                                        Text(freshnessLabel)
                                            .modifier(KatieCapsuleLabelStyle())
                                    }

                                    KatieReplayBadge(
                                        title: entry.reminderCue.isActive ? "Replay ready" : "Next nudge",
                                        systemImage: entry.reminderCue.systemImage,
                                        accent: entry.reminderCue.isActive ? KatieColors.mint : KatieColors.gold
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                                HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                    KatieScenarioArtwork(systemImage: entry.reminderCue.systemImage, accent: entry.reminderCue.isActive ? KatieColors.accent : KatieColors.cardTertiary, secondary: KatieColors.mint)

                                    VStack(alignment: .leading, spacing: KatieSpacing.xs) {
                                        Text(entry.scenario.packTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KatieColors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(entry.statusLabel)
                                            .modifier(KatieCapsuleLabelStyle())
                                    }
                                }

                                Text(entry.emphasisLine)
                                    .font(.footnote)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: KatieSpacing.sm) {
                                    if let freshnessLabel = entry.freshnessLabel {
                                        Text(freshnessLabel)
                                            .modifier(KatieCapsuleLabelStyle())
                                    }

                                    KatieReplayBadge(
                                        title: entry.reminderCue.isActive ? "Replay ready" : "Next nudge",
                                        systemImage: entry.reminderCue.systemImage,
                                        accent: entry.reminderCue.isActive ? KatieColors.mint : KatieColors.gold
                                    )
                                }
                            }
                        }

                        Text(entry.nextStepLine)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textPrimary.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                            Image(systemName: entry.reminderCue.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(entry.reminderCue.isActive ? KatieColors.accent : KatieColors.textSecondary)
                                .frame(width: 22, height: 22)
                                .background(
                                    Circle()
                                        .fill(entry.reminderCue.isActive ? KatieColors.accent.opacity(0.18) : KatieColors.cardBackground)
                                )

                            VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                                Text(entry.reminderCue.eyebrow)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(entry.reminderCue.isActive ? KatieColors.accent : KatieColors.textSecondary)

                                Text(entry.reminderCue.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)

                                Text(entry.reminderCue.body)
                                    .font(.caption2)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(KatieSpacing.md)
                        .background(KatieColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous)
                                .stroke(entry.reminderCue.isActive ? KatieColors.accent.opacity(0.25) : KatieColors.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: Layout.inlineSpacing) {
                                Button(entry.actionTitle) {
                                    handleTodayQueuePrimaryAction(entry)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, KatieSpacing.base)
                                .padding(.vertical, KatieSpacing.md)
                                .background(todayQueueActionBackground(for: entry))
                                .foregroundStyle(todayQueueActionForeground(for: entry))
                                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))

                                todayActionsMenu(for: entry.scenario, latest: latest, anchor: anchor, label: "Peek")

                                Spacer(minLength: 0)
                            }

                            VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                                Button(entry.actionTitle) {
                                    handleTodayQueuePrimaryAction(entry)
                                }
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, KatieSpacing.md)
                                .background(todayQueueActionBackground(for: entry))
                                .foregroundStyle(todayQueueActionForeground(for: entry))
                                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))

                                todayActionsMenu(for: entry.scenario, latest: latest, anchor: anchor, label: "Peek")
                            }
                        }
                    }
                    .padding(KatieSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                }

                if isExpandable {
                    Button(isTodayQueueExpanded ? "Show top packs" : "Show full queue") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            isTodayQueueExpanded.toggle()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, KatieSpacing.base)
                    .padding(.vertical, KatieSpacing.md)
                    .background(KatieColors.cardBackground)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                }
            }
        }
        .katieCard()
    }

    private var managerPrepCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Label("1:1 prep", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Keep the rep clinician-safe and useful: name the observed pattern, point to the friction, then end with one answerable ask.")
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                Label("Pattern to name first: \(appViewModel.languageAssessmentSnapshot.soundFocus)", systemImage: "dot.radiowaves.left.and.right")
                Label("Transfer watch-out, not a diagnosis: \(appViewModel.languageAssessmentSnapshot.transferPattern)", systemImage: "arrow.triangle.branch")
                Label("Close on one manager decision, not a broad vent", systemImage: "checkmark.bubble.fill")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    // MARK: - Reusable subviews (chips, rows, menus, action helpers)

    private func queueSummaryChip(title: String, value: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(.horizontal, KatieSpacing.md)
        .padding(.vertical, KatieSpacing.sm)
        .background(accent.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
    }

    private var coachReadoutCard: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Text("Coach readout")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("Keep the deeper scan tucked away until you want the sound-pattern and transfer-plan detail.")
                        .foregroundStyle(KatieColors.textSecondary)
                }
                Spacer()
                Button(isCoachReadoutExpanded ? "Hide scan" : "Open scan") {
                    withAnimation(KatieMotion.quick) {
                        isCoachReadoutExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
            }

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                Text("Sound pattern · \(appViewModel.currentSoundPatternRadar.title)")
                    .modifier(KatieCapsuleLabelStyle())
                Text("Transfer plan · \(appViewModel.currentConversationTransferPlan.title)")
                    .modifier(KatieCapsuleLabelStyle())
            }

            if isCoachReadoutExpanded {
                VStack(alignment: .leading, spacing: KatieSpacing.base) {
                    firstSpeakingScanCard
                    carryoverCard
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text(appViewModel.firstSpeakingScan.firstWinPlan)
                    .foregroundStyle(KatieColors.textSecondary)
                coachReadoutContinuitySummary
            }
        }
        .katieCard()
    }

    private var coachReadoutContinuityAccent: Color {
        switch appViewModel.currentContinuityStrip.accent {
        case .mint:
            return KatieColors.mint
        case .accent:
            return KatieColors.accent
        case .gold:
            return KatieColors.gold
        }
    }

    private var coachReadoutContinuitySummary: some View {
        let strip = appViewModel.currentContinuityStrip

        return VStack(alignment: .leading, spacing: KatieSpacing.xs) {
            Label(strip.title, systemImage: strip.systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(coachReadoutContinuityAccent)

            Text(appViewModel.scenarioNextStepLine(for: appViewModel.currentMission))
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
                .lineLimit(2)
        }
    }

    private var soundRadarCard: some View {
        let radar = appViewModel.currentSoundPatternRadar

        return VStack(alignment: .leading, spacing: KatieSpacing.base) {
            Label(radar.title, systemImage: "scope")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(radar.summary)
                .foregroundStyle(KatieColors.textSecondary)

            Text(radar.evidenceLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.mint)

            VStack(alignment: .leading, spacing: Layout.heroSpacing) {
                ForEach(radar.bullets, id: \.self) { bullet in
                    Label(bullet, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }
        }
        .katieCard()
    }

    private var transferPlanCard: some View {
        let plan = appViewModel.currentConversationTransferPlan

        return VStack(alignment: .leading, spacing: KatieSpacing.base) {
            Label(plan.title, systemImage: "arrow.triangle.branch")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(plan.summary)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: Layout.heroSpacing) {
                Label(plan.beforeYouSpeak, systemImage: "1.circle.fill")
                Label(plan.whileSpeaking, systemImage: "2.circle.fill")
                Label(plan.repairMove, systemImage: "3.circle.fill")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var languageFocusCard: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            HStack(alignment: .top, spacing: KatieSpacing.base) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Text("Sound focus")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("Ground today’s work in likely transfer patterns and keep prosody in the second pass.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: KatieSpacing.base)

                Text(appViewModel.learnerProfile.firstGoal)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.xs)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
            }

            Text(appViewModel.languageAssessmentSnapshot.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            if isLanguageFocusExpanded {
                Text(appViewModel.languageAssessmentSnapshot.caveat)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                    languageFocusRow(
                        title: "Likely transfer pattern",
                        body: appViewModel.languageAssessmentSnapshot.transferPattern,
                        systemImage: "arrow.triangle.branch"
                    )
                    languageFocusRow(
                        title: "Primary sound target",
                        body: appViewModel.languageAssessmentSnapshot.soundFocus,
                        systemImage: "dot.radiowaves.left.and.right"
                    )
                    languageFocusRow(
                        title: "Prosody later",
                        body: appViewModel.languageAssessmentSnapshot.prosodyFocus,
                        systemImage: "waveform"
                    )
                }

                Text("Katie stays within coaching boundaries: pattern coaching, not therapy or diagnosis, and no accent-erasure promise.")
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
            } else {
                Label(appViewModel.languageAssessmentSnapshot.soundFocus, systemImage: "dot.radiowaves.left.and.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Label(appViewModel.languageAssessmentSnapshot.transferPattern, systemImage: "arrow.triangle.branch")
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Text("Open the deeper scan when you want transfer patterns, prosody notes, and the SLP-informed coaching context.")
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            Button(isLanguageFocusExpanded ? "Hide deeper scan" : "Show deeper scan") {
                withAnimation(KatieMotion.quick) {
                    isLanguageFocusExpanded.toggle()
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(KatieColors.mint)
        }
        .katieCard()
    }

    private var quickRepRail: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                    Text("Quick rep")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("A tiny, unscheduled practice lane for one clean pass. Pick a pack and go.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: KatieSpacing.base)

                Text("60–90 sec")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.xs)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
            }

            Button {
                appViewModel.launchQuickChallenge()
            } label: {
                HStack(alignment: .top, spacing: KatieSpacing.base) {
                    VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                        Label(appViewModel.quickChallengeHeadline, systemImage: "timer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Text(appViewModel.quickChallengeScenario.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.gold)

                        Text(appViewModel.quickChallengeDetailLine)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(3)

                        Text(appViewModel.quickChallengeStarterLine)
                            .font(.caption2)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Text(appViewModel.quickChallengeDurationLabel)
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                }
                .padding(KatieSpacing.lg)
                .background(KatieColors.gold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .stroke(KatieColors.gold.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if usesWideTodayLayout {
                LazyVGrid(columns: quickRepGridColumns, alignment: .leading, spacing: KatieSpacing.base) {
                    ForEach(appViewModel.quickRepRail) { prompt in
                        let isRecommended = prompt.scenario == appViewModel.recommendedScenarioForCurrentContext
                        let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario
                        quickRepPickerCard(prompt: prompt, isRecommended: isRecommended, reminderProtected: reminderProtected)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Layout.inlineSpacing) {
                        ForEach(appViewModel.quickRepRail) { prompt in
                            let isRecommended = prompt.scenario == appViewModel.recommendedScenarioForCurrentContext
                            let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario
                            quickRepPickerCard(prompt: prompt, isRecommended: isRecommended, reminderProtected: reminderProtected, compactWidth: 250)
                        }
                    }
                }
            }
        }
        .katieCard()
    }

    private var quickRepGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: KatieSpacing.base, alignment: .top),
            GridItem(.flexible(), spacing: KatieSpacing.base, alignment: .top)
        ]
    }

    private func quickRepPickerCard(
        prompt: QuickRepPrompt,
        isRecommended: Bool,
        reminderProtected: Bool,
        compactWidth: CGFloat? = nil
    ) -> some View {
        Button {
            appViewModel.launchQuickRep(for: prompt.scenario)
        } label: {
            VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                HStack {
                    Text(prompt.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                    Spacer(minLength: 0)
                    Text(prompt.durationLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                }

                if isRecommended {
                    Label("Recommended for this context", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.gold)
                }

                Text(prompt.detail)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)

                Text(prompt.statusLabel)
                    .modifier(KatieCapsuleLabelStyle(accent: reminderProtected ? KatieColors.mint : KatieColors.gold))

                Label(prompt.hypothesisStatusLabel, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .lineLimit(2)

                Text(prompt.hypothesisDetailLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(3)

                Text(prompt.proofLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textPrimary.opacity(0.86))
                    .lineLimit(3)

                Label(prompt.continuityLine, systemImage: reminderProtected ? "bell.badge.fill" : "bell")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(reminderProtected ? KatieColors.mint : KatieColors.textSecondary)
                    .lineLimit(2)

                Text(prompt.starterLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)
            }
            .padding(Layout.heroSpacing)
            .frame(maxWidth: compactWidth == nil ? .infinity : nil, alignment: .leading)
            .frame(width: compactWidth, alignment: .leading)
            .background(isRecommended ? KatieColors.gold.opacity(0.12) : KatieColors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .stroke(isRecommended ? KatieColors.gold.opacity(0.35) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var goalFocusCard: some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            Label("Goal focus", systemImage: "target")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.goalFocusTitle)
                .font(.title3.bold())
                .foregroundStyle(KatieColors.textPrimary)
                .contentTransition(.opacity)

            Text(appViewModel.goalFocusDetail)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                Text("Tune Katie to what matters right now")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                goalFocusMenu
                startingPackMenu
            }

            HStack(spacing: Layout.inlineSpacing) {
                Label("Starting pack: \(appViewModel.learnerProfile.focusScenario.packTitle)", systemImage: "flag.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Spacer(minLength: 0)

                Button("Practice this pack") {
                    appViewModel.openPractice(for: appViewModel.learnerProfile.focusScenario)
                }
                .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: appViewModel.goalFocusTitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: appViewModel.learnerProfile.focusScenario)
        .katieCard()
    }

    private var profileContextCard: some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            Label("Today’s speaking context", systemImage: "person.text.rectangle.fill")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.profileContextHeadline)
                .font(.title3.bold())
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.profileContextBody)
                .foregroundStyle(KatieColors.textSecondary)

            scanRow(title: "Environment", body: appViewModel.communicationEnvironmentDetail)
            scanRow(title: "Listener pressure", body: appViewModel.listenerPressureDetail)
            scanRow(title: "Sound-first plan", body: appViewModel.languageAssessmentSnapshot.soundFocus)

            Divider().overlay(.white.opacity(0.08))

            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                Label("Best pack for this context", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Text(appViewModel.recommendedScenarioForCurrentContext.packTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(appViewModel.recommendedScenarioLaneLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Text(appViewModel.recommendedScenarioReason)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Text(appViewModel.recommendedScenarioAlignmentLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                HStack(spacing: Layout.inlineSpacing) {
                    Button(appViewModel.isRecommendedScenarioAlignedForToday ? "Today already matches" : "Switch Today to this pack") {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            appViewModel.selectScenario(appViewModel.recommendedScenarioForCurrentContext)
                        }
                    }
                    .modifier(KatieActionChipStyle(
                        background: appViewModel.isRecommendedScenarioAlignedForToday ? KatieColors.cardBackground : KatieColors.cardSecondary,
                        foreground: appViewModel.isRecommendedScenarioAlignedForToday ? KatieColors.textSecondary : KatieColors.textPrimary,
                        horizontalPadding: 10
                    ))
                    .disabled(appViewModel.isRecommendedScenarioAlignedForToday)

                    Button(appViewModel.isRecommendedScenarioAlignedForStartingPack ? "Starting pack matches" : "Make it the starting pack too") {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            appViewModel.alignRecommendedScenarioAcrossExperience()
                        }
                    }
                    .modifier(KatieActionChipStyle(
                        background: appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.cardBackground : KatieColors.accent,
                        foreground: appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.textSecondary : .black,
                        horizontalPadding: 10
                    ))
                    .disabled(appViewModel.isRecommendedScenarioAlignedForStartingPack)
                }
            }
        }
        .katieCard()
    }

    private var goalFocusMenu: some View {
        Menu {
            ForEach(appViewModel.goalPresets) { preset in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        appViewModel.applyGoalPreset(preset)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                        Text(preset.title)
                        Text(preset.detail)
                    }
                }
            }
        } label: {
            cardMenuLabel(
                eyebrow: "Communication goal",
                title: appViewModel.goalFocusTitle,
                detail: appViewModel.goalFocusDetail,
                systemImage: "line.3.horizontal.decrease.circle"
            )
        }
    }

    private var startingPackMenu: some View {
        Menu {
            ForEach(appViewModel.availableScenarios) { scenario in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        appViewModel.updateFocusScenario(scenario)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                        Text(scenario.packTitle)
                        Text(scenario.listenerOutcome)
                    }
                }
            }
        } label: {
            cardMenuLabel(
                eyebrow: "Starting pack",
                title: appViewModel.learnerProfile.focusScenario.packTitle,
                detail: appViewModel.learnerProfile.focusScenario.listenerOutcome,
                systemImage: "square.grid.2x2.fill"
            )
        }
    }

    private func cardMenuLabel(eyebrow: String, title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: Layout.cardSpacing) {
            VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KatieColors.textSecondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: KatieSpacing.base)

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(KatieSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var packProgressCard: some View {
        let latest = appViewModel.currentScenarioHistory.first(where: \.isUserOwned) ?? appViewModel.currentScenarioHistory.first
        let anchor = Array(appViewModel.currentScenarioHistory.filter(\.isUserOwned).dropFirst()).first

        return VStack(alignment: .leading, spacing: KatieSpacing.base) {
            Label("Pack progress", systemImage: "map.fill")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.packProgressCard.title)
                .font(.title3.bold())
                .foregroundStyle(KatieColors.textPrimary)

            Label(appViewModel.packProgressCard.stepLabel, systemImage: "flag.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.packProgressCard.whyItMatters)
                .foregroundStyle(KatieColors.textSecondary)

            Divider().overlay(.white.opacity(0.08))

            Text("Next unlock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
            Text(appViewModel.packProgressCard.nextUnlock)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.packProgressCard.continueLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            if let latest {
                KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                    if appViewModel.hasPlayback(for: latest) {
                        Button(appViewModel.currentlyPlayingSessionID == latest.id ? "Stop" : "Play") {
                            if appViewModel.currentlyPlayingSessionID == latest.id {
                                appViewModel.stopPlayback()
                            } else {
                                appViewModel.playSession(latest)
                            }
                        }
                        .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))
                    }

                    Button(anchor == nil ? "Open proof" : "Open compare") {
                        appViewModel.openReview(for: appViewModel.currentMission, anchor: anchor)
                    }
                    .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))

                    Button(todayReminderActionTitle(for: appViewModel.currentMission)) {
                        handleReminderAction(for: appViewModel.currentMission)
                    }
                    .modifier(KatieActionChipStyle(background: todayReminderActionBackground(for: appViewModel.currentMission), foreground: todayReminderActionForeground(for: appViewModel.currentMission), horizontalPadding: KatieSpacing.md))

                    Button("Practice") {
                        appViewModel.openPractice(for: appViewModel.currentMission)
                    }
                    .modifier(KatieActionChipStyle(background: KatieColors.accent, foreground: .black, horizontalPadding: KatieSpacing.md))

                    Button("Open progress") {
                        appViewModel.openProgress(for: appViewModel.currentMission)
                    }
                    .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: KatieSpacing.md))
                }
            }
        }
        .katieCard()
    }

    private var scenarioSwitcher: some View {
        VStack(alignment: .leading, spacing: KatieSpacing.base) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Text("Speaking contexts")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("Katie should feel broader than interviews from the first tap.")
                        .foregroundStyle(KatieColors.textSecondary)
                }
                Spacer()
                Button(isScenarioSwitcherExpanded ? "Close" : "Browse") {
                    withAnimation(KatieMotion.quick) {
                        isScenarioSwitcherExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
            }

            if isScenarioSwitcherExpanded {
                ForEach(appViewModel.availableScenarios) { scenario in
                let history = appViewModel.scenarioHistories[scenario] ?? []
                let latest = history.first(where: \.isUserOwned) ?? history.first
                let anchor = Array(history.filter(\.isUserOwned).dropFirst()).first

                VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                    Button {
                        appViewModel.selectScenario(scenario)
                    } label: {
                        HStack(alignment: .top, spacing: Layout.cardSpacing) {
                            Image(systemName: appViewModel.currentMission == scenario ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(appViewModel.currentMission == scenario ? KatieColors.accent : KatieColors.textSecondary)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                                ViewThatFits(in: .horizontal) {
                                    HStack(alignment: .top, spacing: Layout.chipSpacing) {
                                        VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                                            Text(scenario.packTitle)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(KatieColors.textPrimary)
                                            Text(scenario.stepLabels.joined(separator: " · "))
                                                .font(.subheadline)
                                                .foregroundStyle(KatieColors.textSecondary)
                                                .lineLimit(2)
                                        }

                                        Spacer(minLength: 8)

                                        Text(appViewModel.scenarioStatusLabel(for: scenario))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(KatieColors.mint)
                                    }

                                    VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                                        VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                                            Text(scenario.packTitle)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(KatieColors.textPrimary)
                                            Text(scenario.stepLabels.joined(separator: " · "))
                                                .font(.subheadline)
                                                .foregroundStyle(KatieColors.textSecondary)
                                                .lineLimit(3)
                                        }

                                        Text(appViewModel.scenarioStatusLabel(for: scenario))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(KatieColors.mint)
                                    }
                                }

                                Text(appViewModel.scenarioStatusDetail(for: scenario))
                                    .font(.footnote)
                                    .foregroundStyle(KatieColors.textSecondary)

                                KatieWrap(spacing: 8, rowSpacing: 8) {
                                    ForEach(scenario.realLifeMoments, id: \.self) { moment in
                                        Text(moment)
                                            .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                                    }
                                }

                                Text(scenario.positioningLine)
                                    .font(.caption)
                                    .foregroundStyle(KatieColors.textSecondary)

                                if let latest {
                                    HStack(spacing: Layout.chipSpacing) {
                                        Text(todayScenarioReviewStatusLabel(for: scenario))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(KatieColors.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(KatieColors.cardBackground)
                                            .clipShape(Capsule())

                                        Text(appViewModel.freshnessLabel(for: latest))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(KatieColors.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(KatieColors.cardBackground)
                                            .clipShape(Capsule())
                                    }

                                    todayProofFacts(for: latest)
                                }

                                Text(appViewModel.scenarioReminderLine(for: scenario))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(appViewModel.reminderPlan?.scenario == scenario ? KatieColors.accent : KatieColors.textSecondary)

                                Text(appViewModel.scenarioNextStepLine(for: scenario))
                                    .font(.caption)
                                    .foregroundStyle(KatieColors.textPrimary.opacity(0.82))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Layout.inlineSpacing) {
                            Button("Practice") {
                                appViewModel.openPractice(for: scenario)
                            }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.inlineSpacing)
                            .background(scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.cardBackground)
                            .foregroundStyle(scenario == appViewModel.currentMission ? .black : KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

                            todayActionsMenu(for: scenario, latest: latest, anchor: anchor, label: "Peek")
                        }

                        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                            Button("Practice") {
                                appViewModel.openPractice(for: scenario)
                            }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.inlineSpacing)
                            .background(scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.cardBackground)
                            .foregroundStyle(scenario == appViewModel.currentMission ? .black : KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

                            todayActionsMenu(for: scenario, latest: latest, anchor: anchor, label: "Peek")
                        }
                    }
                }
                .padding(Layout.heroSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                }
            } else {
                compactTodayScenarioSummary
            }
        }
        .katieCard()
    }

    private var compactTodayScenarioSummary: some View {
        let scenario = appViewModel.currentMission
        let history = appViewModel.scenarioHistories[scenario] ?? []
        let latest = history.first(where: \.isUserOwned) ?? history.first

        return VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
            Text(scenario.packTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
            Text(appViewModel.scenarioStatusDetail(for: scenario))
                .font(.subheadline)
                .foregroundStyle(KatieColors.textSecondary)
                .lineLimit(2)
            KatieWrap(spacing: 8, rowSpacing: 8) {
                ForEach(scenario.realLifeMoments.prefix(2), id: \.self) { moment in
                    Text(moment)
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                }
            }
            HStack(spacing: Layout.chipSpacing) {
                Text(appViewModel.scenarioStatusLabel(for: scenario))
                    .modifier(KatieCapsuleLabelStyle())
                if let latest {
                    Text(appViewModel.freshnessLabel(for: latest))
                        .modifier(KatieCapsuleLabelStyle())
                }
            }
            if let latest {
                todayProofFacts(for: latest)
            }
            Text(appViewModel.scenarioNextStepLine(for: scenario))
                .font(.caption)
                .foregroundStyle(KatieColors.textPrimary.opacity(0.82))
                .lineLimit(2)
        }
        .padding(Layout.heroSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var carryoverCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Text("Live pack continuity")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            Divider().overlay(.white.opacity(0.08))

            Text("Reminder handoff")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.reminderCallToActionLine)
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.reminderPreviewCopy)
                .foregroundStyle(KatieColors.textSecondary)

            Divider().overlay(.white.opacity(0.08))

            Text("Listener outcome")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
            Text(appViewModel.latestSession.listenerOutcome)
                .foregroundStyle(KatieColors.textSecondary)

            Divider().overlay(.white.opacity(0.08))

            Text("Next grounded move")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
            Text(appViewModel.currentPackNextStepLabel)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var premiumPreviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.compactSectionSpacing) {
                    Text("Katie Plus preview")
                        .font(.title.bold())
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("A calmer premium layer after the first believable win — compare memory, reminder continuity, and richer follow-through across speaking packs.")
                        .foregroundStyle(KatieColors.textSecondary)

                    if let featured = appViewModel.featuredWin {
                        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                            Text("Proof of the win")
                                .font(.headline)
                                .foregroundStyle(KatieColors.textPrimary)

                            Text(appViewModel.compareCeremonyLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)

                            if appViewModel.hasEarnedCompare {
                                HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                    proofColumn(title: "Before", body: featured.beforeText)
                                    proofColumn(title: "After", body: featured.afterText)
                                }
                            } else {
                                proofColumn(
                                    title: appViewModel.hasEarnedFirstWin ? "Your first proof" : "Starter example",
                                    body: appViewModel.hasEarnedFirstWin ? featured.afterText : featured.beforeText
                                )
                            }

                            Label(appViewModel.firstWinTrustLine, systemImage: appViewModel.activeScenarioRecordedCount > 0 ? "mic.fill" : "sparkles.rectangle.stack.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)

                            Text(featured.deltaHint)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                        .katieCard()
                    }

                    ForEach(appViewModel.premiumFeaturePreview, id: \.self) { feature in
                        Label {
                            Text(feature)
                                .foregroundStyle(KatieColors.textPrimary)
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(KatieColors.mint)
                        }
                        .padding(Layout.heroSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KatieColors.cardSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text("Paywall experiments in this build")
                            .font(.headline)
                            .foregroundStyle(KatieColors.textPrimary)

                        ForEach(appViewModel.premiumExperimentSurfaces) { experiment in
                            VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                                HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                                    VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                                        Text(experiment.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KatieColors.textPrimary)
                                        Text(experiment.detail)
                                            .font(.footnote)
                                            .foregroundStyle(KatieColors.textSecondary)
                                    }

                                    Spacer(minLength: 8)

                                    Text(experiment.badge)
                                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                                }

                                VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                                    ForEach(experiment.bullets, id: \.self) { bullet in
                                        Label(bullet, systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(KatieColors.textSecondary)
                                    }
                                }
                            }
                            .padding(Layout.heroSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(KatieColors.cardSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                        }
                    }
                    .katieCard()

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text("Follow-through scaffold")
                            .font(.headline)
                            .foregroundStyle(KatieColors.textPrimary)

                        Label(appViewModel.currentPackWarmthLabel, systemImage: "flame.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)

                        Text(appViewModel.currentPackNextStepLabel)
                            .foregroundStyle(KatieColors.textSecondary)

                        Text(appViewModel.reminderPreviewCopy)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .katieCard()

                    VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                        Text("Trust note")
                            .font(.headline)
                            .foregroundStyle(KatieColors.textPrimary)
                        Text(appViewModel.premiumStatusLine)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .katieCard()

                    if let restoreMessage = appViewModel.premiumRestoreMessage {
                        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                            Label(restoreMessage.title, systemImage: restoreMessageSystemImage(for: restoreMessage.tone))
                                .font(.headline)
                                .foregroundStyle(restoreMessageColor(for: restoreMessage.tone))

                            Text(restoreMessage.body)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                        .katieCard()
                    }

                    VStack(spacing: Layout.inlineSpacing) {
                        Button(appViewModel.premiumActionButtonTitle) {
                            handlePremiumAction()
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(KatieColors.accent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                        .disabled(appViewModel.premiumActionButtonDisabled || isPremiumActionRunning || isRefreshingPremiumStore || isRestoringPremiumPurchases)

                        Text(appViewModel.premiumCTASecondaryLine)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)

                        VStack(spacing: Layout.inlineSpacing) {
                            Button(isRestoringPremiumPurchases ? "Restoring purchases…" : "Restore purchases") {
                                isRestoringPremiumPurchases = true
                                Task {
                                    await appViewModel.restorePremiumPurchases()
                                    await MainActor.run {
                                        isRestoringPremiumPurchases = false
                                        if appViewModel.canManageSubscription {
                                            appViewModel.isPremiumPreviewPresented = false
                                        }
                                    }
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.inlineSpacing)
                            .frame(maxWidth: .infinity)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                            .disabled(isRestoringPremiumPurchases || isRefreshingPremiumStore || isPremiumActionRunning)

                            if appViewModel.canManageSubscription, let manageURL = appViewModel.manageSubscriptionURL {
                                Button("Manage subscription") {
                                    openURL(manageURL)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, Layout.chipHorizontalPadding)
                                .padding(.vertical, Layout.inlineSpacing)
                                .frame(maxWidth: .infinity)
                                .background(KatieColors.cardSecondary)
                                .foregroundStyle(KatieColors.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                                .disabled(isRestoringPremiumPurchases || isRefreshingPremiumStore || isPremiumActionRunning)
                            }

                            HStack(spacing: Layout.inlineSpacing) {
                            Button(isRefreshingPremiumStore ? "Refreshing StoreKit…" : "Refresh StoreKit") {
                                isRefreshingPremiumStore = true
                                Task {
                                    await appViewModel.refreshPremiumStore()
                                    await MainActor.run {
                                        isRefreshingPremiumStore = false
                                    }
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.inlineSpacing)
                            .frame(maxWidth: .infinity)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                            .disabled(isRefreshingPremiumStore || isPremiumActionRunning || isRestoringPremiumPurchases)

                            Button(appViewModel.premiumCTAButtonTitle) {
                                appViewModel.unlockPremiumFlow()
                                appViewModel.isPremiumPreviewPresented = false
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.inlineSpacing)
                            .frame(maxWidth: .infinity)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                            .disabled(isPremiumActionRunning || isRefreshingPremiumStore || isRestoringPremiumPurchases)
                            }
                        }
                    }
                }
                .padding(Layout.screenTopPadding)
            }
            .background(LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing).overlay { RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420) }.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        appViewModel.clearPremiumRestoreMessage()
                        appViewModel.isPremiumPreviewPresented = false
                    }
                    .foregroundStyle(KatieColors.textPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Premium flow + reminder presets

    private func handlePremiumAction() {
        switch appViewModel.premiumAccessState {
        case .preview:
            appViewModel.isPremiumPreviewPresented = false
        case .entitled:
            return
        case .locked:
            isPremiumActionRunning = true
            Task {
                await appViewModel.purchasePremiumIfAvailable()
                await MainActor.run {
                    isPremiumActionRunning = false
                    if appViewModel.isPremiumUnlocked {
                        appViewModel.isPremiumPreviewPresented = false
                    }
                }
            }
        }
    }

    private var continuityCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                    Text("Continuity handoff")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text("One calm truth strip keeps replay and reminder status obvious without making this pack feel heavy.")
                        .foregroundStyle(KatieColors.textSecondary)
                }
                Spacer()
                Button(isContinuityExpanded ? "Close" : "Tune") {
                    withAnimation(KatieMotion.quick) {
                        isContinuityExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
            }
            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)
            Label(todayReminderOwnerLabel, systemImage: todayReminderOwnerSystemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(todayReminderOwnerAccent)
            Text(todayReminderOwnerDetail)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            if isContinuityExpanded {
                VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                    Label("Portable proof", systemImage: "doc.on.doc.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.currentScenarioSnapshot.portableProofLabel)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Label(appViewModel.reminderPermissionState.title, systemImage: appViewModel.reminderPermissionState.systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                Text(appViewModel.reminderCallToActionLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.accent)

                Text(appViewModel.reminderStatusLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                    Label("Preview notification", systemImage: "bell.badge.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.accent)

                    Text(appViewModel.reminderPreviewTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(appViewModel.reminderPreviewBody)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(appViewModel.reminderPreviewScheduleLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                .padding(Layout.cardSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                Text("Reminder tone")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                KatieWrap(spacing: 8, rowSpacing: 8) {
                    ForEach(ReminderTone.allCases) { tone in
                        Button(tone.title) {
                            appViewModel.setReminderTone(tone)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Layout.chipHorizontalPadding)
                        .padding(.vertical, 8)
                        .background(appViewModel.reminderTone == tone ? KatieColors.accent.opacity(0.25) : KatieColors.cardSecondary)
                        .foregroundStyle(appViewModel.reminderTone == tone ? KatieColors.textPrimary : KatieColors.textSecondary)
                        .clipShape(Capsule())
                    }
                }

                Text(appViewModel.reminderToneLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            if appViewModel.remindersEnabled {
                VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                    Text("Reminder time")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    DatePicker(
                        "Reminder time",
                        selection: Binding(
                            get: { appViewModel.reminderDraftDate },
                            set: { appViewModel.updateReminderTime($0) }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(KatieColors.accent)

                    if usesWideReminderPresetLayout {
                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.reminderQuickPresets) { preset in
                                todayReminderPresetChip(preset)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Layout.chipSpacing) {
                                ForEach(appViewModel.reminderQuickPresets) { preset in
                                    todayReminderPresetChip(preset)
                                }
                            }
                        }
                    }

                    Text("Move the nudge to the exact conversation window you want to protect on \(reminderSurfaceLabel).")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }

            if appViewModel.reminderPermissionState == .denied {
                Button("Open iPhone Settings for reminders") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.chipHorizontalPadding)
                .padding(.vertical, 8)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            Text(appViewModel.recorderStatusLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Button(appViewModel.reminderButtonTitle) {
                if appViewModel.reminderPermissionState == .denied {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                    return
                }
                appViewModel.scheduleOrDismissReminder()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.inlineSpacing)
            .background(KatieColors.cardSecondary)
            .foregroundStyle(KatieColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            }
        }
        .katieCard()
    }
}

private extension TodayMissionView {
    var todayReminderOwnerLabel: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Reminder owner: none yet"
        }

        return "Reminder owner: \(reminderPlan.scenario.packTitle) · \(reminderPlan.fireDate.formatted(date: .omitted, time: .shortened))"
    }

    var todayReminderOwnerDetail: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Today stays centered on this pack until you decide a saved line is worth protecting with a reminder."
        }

        if reminderPlan.scenario == appViewModel.currentMission {
            return "Today and the next nudge are protecting the same pack, so the live handoff stays grounded on one saved line."
        }

        return "Today stays on \(appViewModel.currentMission.packTitle), but the next nudge is currently protecting \(reminderPlan.scenario.packTitle). Move it here only when this is the line you want back next."
    }

    var todayReminderOwnerSystemImage: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "bell.slash"
        }

        return reminderPlan.scenario == appViewModel.currentMission ? "bell.badge.fill" : "bell.badge"
    }

    var todayReminderOwnerAccent: Color {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return KatieColors.textSecondary
        }

        return reminderPlan.scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.gold
    }

    func restoreMessageColor(for tone: PremiumRestoreMessage.Tone) -> Color {
        switch tone {
        case .success:
            return KatieColors.mint
        case .neutral:
            return KatieColors.accent
        case .warning:
            return .orange
        }
    }

    func restoreMessageSystemImage(for tone: PremiumRestoreMessage.Tone) -> String {
        switch tone {
        case .success:
            return "checkmark.seal.fill"
        case .neutral:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }

    func scanRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(Layout.heroSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    func languageFocusRow(title: String, body: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: Layout.inlineSpacing) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
                .frame(width: 24, height: 24)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: Layout.chipVerticalPadding) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(KatieColors.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    func proofColumn(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
            KatieSectionEyebrow(title: title, systemImage: title == "After" ? "sparkles" : "circle.lefthalf.filled", accent: title == "After" ? KatieColors.mint : KatieColors.gold)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(4)
        }
        .padding(Layout.heroSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [KatieColors.cardSecondary, KatieColors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    func todayScenarioReviewStatusLabel(for scenario: PracticeScenario) -> String {
        let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)

        if ownedCount <= 0 {
            return "Starter sample"
        }
        if ownedCount == 1 {
            return "Latest proof"
        }
        return "Latest compare"
    }

    func featuredWinProofMetaStrip(title: String, session: PracticeSession, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
            HStack(alignment: .center, spacing: Layout.chipSpacing) {
                Label(title, systemImage: session.captureSource.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)

                Spacer(minLength: 0)

                Text(appViewModel.freshnessLabel(for: session))
                    .modifier(KatieCapsuleLabelStyle())
            }

            todayProofFacts(for: session)
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    func featuredWinReplayTruthCard(for featured: FeaturedWin) -> some View {
        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
            Label(featuredWinReplayTruthTitle(for: featured), systemImage: featuredWinReplayTruthSystemImage(for: featured))
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.compareTruthLine(anchor: featured.anchorSession, latest: featured.latestSession))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    func featuredWinReplayTruthTitle(for featured: FeaturedWin) -> String {
        let latestHasReplay = appViewModel.hasPlayback(for: featured.latestSession)

        if let anchor = featured.anchorSession {
            let anchorHasReplay = appViewModel.hasPlayback(for: anchor)

            switch (anchorHasReplay, latestHasReplay) {
            case (true, true):
                return "Both proof clips replay on this iPhone"
            case (true, false):
                return "Only the earlier proof replays here"
            case (false, true):
                return "Only the latest proof replays here"
            case (false, false):
                return "This compare is transcript-first on this iPhone"
            }
        }

        if latestHasReplay {
            return "This proof replays on this iPhone"
        }

        return featured.latestSession.captureSource == .seeded
            ? "Starter proof stays transcript-first here"
            : "Replay needs a fresh local clip"
    }

    func featuredWinReplayTruthSystemImage(for featured: FeaturedWin) -> String {
        let latestHasReplay = appViewModel.hasPlayback(for: featured.latestSession)

        if let anchor = featured.anchorSession {
            let anchorHasReplay = appViewModel.hasPlayback(for: anchor)

            switch (anchorHasReplay, latestHasReplay) {
            case (true, true):
                return "waveform.circle.fill"
            case (true, false), (false, true):
                return "waveform.badge.exclamationmark"
            case (false, false):
                return "speaker.slash.fill"
            }
        }

        return latestHasReplay ? "waveform.circle.fill" : "speaker.slash.fill"
    }

    func todayProofFacts(for session: PracticeSession) -> some View {
        KatieWrap(spacing: 6, rowSpacing: 6) {
            todayProofFactChip(appViewModel.compactCaptureSourceLabel(for: session), systemImage: session.captureSource.systemImage)
            todayProofFactChip(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
            todayProofFactChip(appViewModel.compactReplayLabel(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
        }
    }

    private func todayReminderPresetChip(_ preset: ReminderQuickPreset) -> some View {
        Button(preset.title) {
            appViewModel.updateReminderTime(preset.fireDate)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, Layout.chipHorizontalPadding)
        .padding(.vertical, 8)
        .background(KatieColors.cardSecondary)
        .foregroundStyle(KatieColors.textPrimary)
        .clipShape(Capsule())
    }

    func todayProofFactChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(KatieColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(KatieColors.cardBackground)
            .clipShape(Capsule())
    }

    func todayActionsMenu(for scenario: PracticeScenario, latest: PracticeSession?, anchor: PracticeSession?, progressTitle: String = "Open progress", label: String = "Peek") -> some View {
        Menu {
            Button("Pin focus") {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    appViewModel.selectScenario(scenario)
                }
            }

            Button(anchor == nil ? "See proof" : "See compare") {
                appViewModel.openReview(for: scenario, anchor: anchor)
            }

            Button("Practice") {
                appViewModel.openPractice(for: scenario)
            }

            Button(progressTitle) {
                appViewModel.openProgress(for: scenario)
            }

            Button(todayReminderActionTitle(for: scenario)) {
                handleReminderAction(for: scenario)
            }

            if let anchor, appViewModel.hasPlayback(for: anchor) {
                Button(appViewModel.currentlyPlayingSessionID == anchor.id ? "Stop earlier proof" : "Play earlier proof") {
                    if appViewModel.currentlyPlayingSessionID == anchor.id {
                        appViewModel.stopPlayback()
                    } else {
                        appViewModel.playSession(anchor)
                    }
                }
            }

            if let latest, appViewModel.hasPlayback(for: latest) {
                Button(appViewModel.currentlyPlayingSessionID == latest.id ? "Stop replay" : "Play replay") {
                    if appViewModel.currentlyPlayingSessionID == latest.id {
                        appViewModel.stopPlayback()
                    } else {
                        appViewModel.playSession(latest)
                    }
                }
            }
        } label: {
            Label(label, systemImage: "ellipsis.circle")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.chipHorizontalPadding)
                .padding(.vertical, Layout.inlineSpacing)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
        }
    }

    func todayReminderActionTitle(for scenario: PracticeScenario) -> String {
        if appViewModel.reminderPermissionState == .denied {
            return appViewModel.reminderPlan?.scenario == scenario ? "Fix reminders" : "Enable nudge"
        }

        if appViewModel.reminderPlan?.scenario == scenario {
            return "Pause nudge"
        }

        if appViewModel.reminderPlan != nil {
            return "Move nudge here"
        }

        return "Add nudge"
    }

    func todayQueueActionBackground(for entry: TodayQueueEntry) -> Color {
        switch entry.action {
        case .recordFirstRep, .recordFreshProof, .enableReminder:
            return KatieColors.accent
        case .openProof, .openCompare, .keepWarm:
            return KatieColors.cardBackground
        }
    }

    func todayQueueActionForeground(for entry: TodayQueueEntry) -> Color {
        switch entry.action {
        case .recordFirstRep, .recordFreshProof, .enableReminder:
            return .black
        case .openProof, .openCompare, .keepWarm:
            return KatieColors.textPrimary
        }
    }

    func handleTodayQueuePrimaryAction(_ entry: TodayQueueEntry) {
        appViewModel.selectScenario(entry.scenario)

        switch entry.action {
        case .recordFirstRep, .recordFreshProof, .keepWarm:
            appViewModel.openPractice(for: entry.scenario)
        case .openProof, .openCompare:
            let history = appViewModel.scenarioHistories[entry.scenario] ?? []
            let anchor = Array(history.filter(\.isUserOwned).dropFirst()).first
            appViewModel.openReview(for: entry.scenario, anchor: entry.action == .openCompare ? anchor : nil)
        case .enableReminder:
            handleReminderAction(for: entry.scenario)
        }
    }

    func todayReminderActionBackground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? KatieColors.accent
            : KatieColors.cardSecondary
    }

    func todayReminderActionForeground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? .black
            : KatieColors.textPrimary
    }

    func handleReminderAction(for scenario: PracticeScenario) {
        appViewModel.selectScenario(scenario)

        if appViewModel.reminderPermissionState == .denied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
            return
        }

        appViewModel.scheduleOrDismissReminder()
    }


    private var reminderFlowBanner: some View {
        Group {
            if let message = appViewModel.reminderFlowMessage {
                KatieInlineNotice(
                    title: message.title,
                    message: message.body,
                    systemImage: "bell.badge.fill",
                    accent: KatieColors.accent,
                    onDismiss: { appViewModel.clearReminderFlowMessage() }
                )
            }
        }
    }
}

#Preview {
    TodayMissionView()
        .environmentObject(AppViewModel())
}
