import SwiftUI

struct ProgressView: View {
    private enum ProgressStage {
        case starter
        case early
        case full
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPackLibraryExpanded = false

    private enum Layout {
        static let cardCornerRadius: CGFloat = 18
        static let innerCardCornerRadius: CGFloat = 16
        static let editorCornerRadius: CGFloat = 14
        static let chipCornerRadius: CGFloat = 10
        static let cornerRadius20: CGFloat = 20
        static let cardPadding: CGFloat = 12
        static let heroPadding: CGFloat = 16
        static let mediumChipHorizontalPadding: CGFloat = 12
        static let mediumChipVerticalPadding: CGFloat = 8
        static let smallChipHorizontalPadding: CGFloat = 10
        static let smallChipVerticalPadding: CGFloat = 6
        static let tightChipHorizontalPadding: CGFloat = 8
        static let tightChipVerticalPadding: CGFloat = 4
        static let gridSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let subSpacing: CGFloat = 6
        static let spacing_8: CGFloat = 8
        static let spacing_10: CGFloat = 10
        static let spacing_4: CGFloat = 4
        static let spacing_14: CGFloat = 14
        static let spacing_3: CGFloat = 3
        static let spacing_5: CGFloat = 5
    }

    // MARK: - Layout (size class + computed metrics)

    private var activePackCount: Int {
        appViewModel.availableScenarios.filter { appViewModel.userOwnedSessionCount(in: $0) > 0 }.count
    }

    private var compareReadyCount: Int {
        appViewModel.availableScenarios.filter { appViewModel.userOwnedSessionCount(in: $0) >= 2 }.count
    }

    private var replayReadyCount: Int {
        appViewModel.availableScenarios.reduce(0) { partialResult, scenario in
            let history = appViewModel.scenarioHistories[scenario] ?? []
            return partialResult + history.filter { $0.isUserOwned && appViewModel.hasPlayback(for: $0) }.count
        }
    }

    private var reminderOwnerSummary: String {
        appViewModel.reminderPlan?.scenario.packTitle ?? "None yet"
    }

    private var reminderOwnerDetail: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Save one real line first, then choose when Katie should protect it next."
        }

        return "\(reminderPlan.fireDate.formatted(date: .omitted, time: .shortened)) · The next nudge is protecting \(reminderPlan.scenario.packTitle)."
    }

    private var latestCompareEntry: CompareLibraryEntry? {
        appViewModel.compareLibraryEntries.first
    }

    private var protectedScenario: PracticeScenario? {
        appViewModel.reminderPlan?.scenario
    }

    private var replayReadyScenario: PracticeScenario? {
        appViewModel.availableScenarios.first { scenario in
            let history = appViewModel.scenarioHistories[scenario] ?? []
            return history.contains { $0.isUserOwned && appViewModel.hasPlayback(for: $0) }
        }
    }

    private var progressStage: ProgressStage {
        if activePackCount == 0 {
            return .starter
        }

        if compareReadyCount == 0 {
            return .early
        }

        return .full
    }

    private var usesWideProgressLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var compareLibraryCardWidth: CGFloat {
        240
    }

    private var compareLibraryGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }

    private var progressBoardMetrics: [KatieGlanceMetric] {
        [
            KatieGlanceMetric(
                title: "Active packs",
                value: "\(activePackCount)",
                detail: activePackCount == 1 ? "One pack already has user-owned proof." : "Packs with at least one user-owned proof.",
                accent: KatieColors.mint
            ),
            KatieGlanceMetric(
                title: "Compare-ready",
                value: "\(compareReadyCount)",
                detail: compareReadyCount == 0 ? "Save one more proof in any pack to unlock a before-vs-now story." : "Packs with enough proof for a real compare.",
                accent: KatieColors.gold
            ),
            KatieGlanceMetric(
                title: "Replay-ready clips",
                value: "\(replayReadyCount)",
                detail: replayReadyCount == 0 ? "No local playback yet on this iPhone." : "Clips that can still replay locally on this iPhone.",
                accent: KatieColors.accent
            )
        ]
    }

    // MARK: - Subviews (boards, ladders, achievements)

    private var progressBoardCard: some View {
        KatieGlanceBoard(
            eyebrow: "Progress board",
            title: "Glance first, then open the deeper proof",
            detail: "Katie keeps the top line readable on iPhone and iPad before you drop into the longer compare and clinician-style detail cards.",
            systemImage: "chart.line.uptrend.xyaxis",
            accent: KatieColors.mint,
            secondary: KatieColors.gold,
            metrics: progressBoardMetrics,
            footnote: reminderOwnerDetail
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                HStack(spacing: Layout.gridSpacing) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .katieIconBadge(background: KatieColors.cardSecondary, foreground: KatieColors.mint, size: 34)
                    Text("Progress")
                        .font(.title.bold())
                        .foregroundStyle(KatieColors.textPrimary)
                    Spacer()
                }

                progressBoardCard
                progressRingsRow

                switch progressStage {
                case .starter:
                    starterProgressContent
                case .early:
                    earlyProgressContent
                case .full:
                    fullProgressContent
                }
            }
            .padding(Layout.heroPadding)
            .katieContentFrame(maxWidth: 840)
        }
        .background(
            LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    ZStack {
                        RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420)
                        KatieFloatingParticles()
                    }
                }
                .ignoresSafeArea()
        )
    }

    private var progressRingsRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            progressRingCell(
                progress: min(1.0, Double(activePackCount) / 5.0),
                label: "\(activePackCount)",
                title: "Active\npacks",
                accent: KatieColors.mint
            )
            Spacer(minLength: 0)
            progressRingCell(
                progress: activePackCount > 0
                    ? min(1.0, Double(compareReadyCount) / Double(activePackCount))
                    : 0,
                label: "\(compareReadyCount)",
                title: "Compare\nready",
                accent: KatieColors.gold
            )
            Spacer(minLength: 0)
            progressRingCell(
                progress: min(1.0, Double(replayReadyCount) / 10.0),
                label: "\(replayReadyCount)",
                title: "Replay\nclips",
                accent: KatieColors.accent
            )
            Spacer(minLength: 0)
        }
        .padding(.vertical, KatieSpacing.xl)
        .katieCard()
    }

    private func progressRingCell(progress: Double, label: String, title: String, accent: Color) -> some View {
        VStack(spacing: KatieSpacing.base) {
            KatieProgressRing(progress: progress, size: 68, lineWidth: 5, accent: accent, label: label)
            Text(title)
                .font(KatieType.label)
                .foregroundStyle(KatieColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var starterProgressContent: some View {
        if usesWideProgressLayout {
            progressTopRail {
                starterProgressHero
                goalFocusCard
            } secondary: {
                progressUnlocksCard
                achievementsCard
            }

            evidenceLadderCard
            analyticsOverviewCard
            proofProvenanceCard
            scenarioLanesCard
        } else {
            starterProgressHero
            goalFocusCard
            achievementsCard
            evidenceLadderCard
            analyticsOverviewCard
            proofProvenanceCard
            progressUnlocksCard
            scenarioLanesCard
        }
    }

    @ViewBuilder
    private var earlyProgressContent: some View {
        if usesWideProgressLayout {
            progressTopRail {
                earlyProgressHero
                goalFocusCard
                featuredWinSummary
            } secondary: {
                progressSnapshotCard
                achievementsCard
                startingHypothesisSummaryCard
                proofProvenanceCard
            }

            analyticsOverviewCard
            confidenceTrendCard
            evidenceLadderCard
            clinicianLensCard
            premiumContinuityCard
            scenarioLanesCard
            progressUnlocksCard
        } else {
            earlyProgressHero
            goalFocusCard
            progressSnapshotCard
            achievementsCard
            startingHypothesisSummaryCard
            analyticsOverviewCard
            confidenceTrendCard
            evidenceLadderCard
            proofProvenanceCard
            clinicianLensCard
            featuredWinSummary
            premiumContinuityCard
            scenarioLanesCard
            progressUnlocksCard
        }
    }

    @ViewBuilder
    private var fullProgressContent: some View {
        if usesWideProgressLayout {
            progressTopRail {
                goalFocusCard
                progressSnapshotCard
                startingHypothesisSummaryCard
                featuredWinSummary
            } secondary: {
                clarityStoryHero
                achievementsCard
                proofProvenanceCard
            }

            analyticsOverviewCard
            compareStoryCard
            confidenceTrendCard
            evidenceLadderCard
            clinicianLensCard
            premiumContinuityCard
            compareLibraryCard
            scenarioLanesCard
        } else {
            goalFocusCard
            progressSnapshotCard
            achievementsCard
            startingHypothesisSummaryCard
            analyticsOverviewCard
            confidenceTrendCard
            evidenceLadderCard
            proofProvenanceCard
            compareStoryCard
            clinicianLensCard
            clarityStoryHero
            featuredWinSummary
            premiumContinuityCard
            compareLibraryCard
            scenarioLanesCard
        }
    }

    private func progressTopRail<Primary: View, Secondary: View>(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    primary()
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    secondary()
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: Layout.gridSpacing) {
                primary()
                secondary()
            }
        }
    }

    private func snapshotPulseChip(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.subSpacing) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
            Text(body)
                .font(.caption)
                .foregroundStyle(KatieColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func proofCountChip(title: String, value: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing_4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent)
            Text("\(value)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(.horizontal, Layout.mediumChipHorizontalPadding)
        .padding(.vertical, Layout.spacing_10)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func proofConfidenceTile(title: String, score: Int, accent: Color) -> some View {
        let clampedScore = min(max(score, 0), 5)

        return VStack(alignment: .leading, spacing: Layout.spacing_8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: Layout.spacing_4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < clampedScore ? accent : KatieColors.textSecondary.opacity(0.16))
                        .frame(width: 10, height: 6)
                }
            }

            Text("\(clampedScore)/5")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(.horizontal, Layout.mediumChipHorizontalPadding)
        .padding(.vertical, Layout.spacing_10)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var evidenceLadderCard: some View {
        let pulse = appViewModel.coachingEvidencePulse

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Label(pulse.title, systemImage: "list.clipboard")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(pulse.summary)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: Layout.spacing_10) {
                ForEach(pulse.points, id: \.self) { point in
                    Label(point, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }
        }
        .katieCard()
    }

    private var proofProvenanceCard: some View {
        let recordedCount = appViewModel.recordedHistoryCount
        let importedCount = appViewModel.importedHistoryCount
        let seededCount = appViewModel.seededHistoryCount

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Label("Proof provenance", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(recordedCount > 0
                 ? "Progress leads with proof you recorded on this iPhone. Imported continuity and starter samples stay visible, but clearly behind your own reps."
                 : importedCount > 0
                 ? "Imported continuity can keep the lane warm, but Progress still needs a locally saved proof before it should feel earned here."
                 : "Starter samples stay labeled as prototype continuity until you save your own proof.")
                .foregroundStyle(KatieColors.textSecondary)

            if recordedCount > 0 {
                KatieWrap(spacing: 8, rowSpacing: 8) {
                    proofCountChip(title: "Recorded here", value: recordedCount, accent: KatieColors.mint)
                    proofCountChip(title: "Imported", value: importedCount, accent: KatieColors.accent)
                }

                Text("Starter proof stays in the lane as smaller prototype continuity.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.gold)
            } else {
                KatieWrap(spacing: 8, rowSpacing: 8) {
                    proofCountChip(title: "Recorded here", value: recordedCount, accent: KatieColors.mint)
                    proofCountChip(title: "Imported", value: importedCount, accent: KatieColors.accent)
                    proofCountChip(title: "Starter", value: seededCount, accent: KatieColors.gold)
                }
            }

            Text("Order of trust: recorded here first, imported continuity second, starter proof last.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.gold)
        }
        .katieCard()
    }

    private var goalFocusCard: some View {
        let snapshot = appViewModel.currentGoalProgressSnapshot

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.spacing_4) {
                    Label("Goal focus", systemImage: "target")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(snapshot.title)
                        .font(.title3.bold())
                        .foregroundStyle(KatieColors.textPrimary)
                }

                Spacer(minLength: 0)

                Text(snapshot.progressLabel)
                    .modifier(KatieCapsuleLabelStyle(accent: KatieColors.mint))
            }

            Text(snapshot.detail)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: Layout.spacing_10) {
                progressDetailRow(
                    title: "Current lane",
                    body: snapshot.focusPackLine,
                    systemImage: "scope"
                )
                progressDetailRow(
                    title: "Context fit",
                    body: snapshot.scenarioLine,
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                )
                progressDetailRow(
                    title: "Next milestone",
                    body: snapshot.nextMilestoneLine,
                    systemImage: "flag.checkered"
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Layout.spacing_8) {
                    ForEach(Array(snapshot.steps.enumerated()), id: \.offset) { index, step in
                        goalStepChip(title: step, isComplete: index < snapshot.completedSteps)
                    }
                }

                VStack(alignment: .leading, spacing: Layout.spacing_8) {
                    ForEach(Array(snapshot.steps.enumerated()), id: \.offset) { index, step in
                        goalStepChip(title: step, isComplete: index < snapshot.completedSteps)
                    }
                }
            }
        }
        .katieCard()
    }

    private func goalStepChip(title: String, isComplete: Bool) -> some View {
        HStack(spacing: Layout.spacing_8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? KatieColors.mint : KatieColors.textSecondary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(.horizontal, Layout.mediumChipHorizontalPadding)
        .padding(.vertical, Layout.spacing_10)
        .background(isComplete ? KatieColors.mint.opacity(0.14) : KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var achievementsCard: some View {
        let achievements = appViewModel.progressAchievements

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Label("Achievements", systemImage: "rosette")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Small, honest milestones that show when this pack has moved from starter flow to real user-owned proof.")
                .foregroundStyle(KatieColors.textSecondary)

            if usesWideProgressLayout {
                LazyVGrid(columns: compareLibraryGridColumns, alignment: .leading, spacing: Layout.spacing_10) {
                    ForEach(achievements) { achievement in
                        achievementTile(achievement)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: Layout.spacing_10) {
                    ForEach(achievements) { achievement in
                        achievementTile(achievement)
                    }
                }
            }
        }
        .katieCard()
    }

    private func achievementTile(_ achievement: ProgressAchievement) -> some View {
        let accent = achievementAccent(for: achievement)

        return HStack(alignment: .top, spacing: Layout.gridSpacing) {
            Image(systemName: achievement.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(achievement.isUnlocked ? accent : KatieColors.textSecondary)
                .frame(width: 30, height: 30)
                .background((achievement.isUnlocked ? accent : KatieColors.cardBackground).opacity(achievement.isUnlocked ? 0.16 : 0.9))
                .clipShape(RoundedRectangle(cornerRadius: Layout.chipCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Layout.spacing_4) {
                HStack(spacing: Layout.spacing_8) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(achievement.isUnlocked ? "Live" : "Locked")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(achievement.isUnlocked ? accent : KatieColors.textSecondary)
                        .padding(.horizontal, Layout.tightChipHorizontalPadding)
                        .padding(.vertical, Layout.tightChipVerticalPadding)
                        .background(KatieColors.cardBackground.opacity(0.9))
                        .clipShape(Capsule())
                }

                Text(achievement.detail)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous)
                .stroke((achievement.isUnlocked ? accent : KatieColors.cardBackground).opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func achievementAccent(for achievement: ProgressAchievement) -> Color {
        switch achievement.tone {
        case .mint:
            return KatieColors.mint
        case .gold:
            return KatieColors.gold
        case .accent:
            return KatieColors.accent
        }
    }

    // MARK: - Analytics + comparison library (heavier surfaces)

    private var analyticsOverviewCard: some View {
        let analytics = appViewModel.currentScenarioAnalyticsSummary

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.subSpacing) {
                    Label(analytics.title, systemImage: "chart.xyaxis.line")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(analytics.subtitle)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                if analytics.points.isEmpty {
                    Text("Locked")
                        .modifier(KatieCapsuleLabelStyle())
                } else {
                    Text("Avg \(analytics.overallAverage)/5")
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.accent))
                }
            }

            if analytics.points.isEmpty {
                KatieInlineNotice(
                    title: "Graph unlocks after the first rep",
                    message: analytics.momentumLine
                )
            } else {
                analyticsMetricRail(analytics)
                analyticsChart(points: analytics.points)
                Text(analytics.strongestLane)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
            }

            Text(analytics.momentumLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(analytics.playbackLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private func analyticsMetricRail(_ analytics: ScenarioAnalyticsSummary) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Layout.spacing_10) {
                analyticsMetricTile(title: "Listener", score: analytics.listenerAverage, accent: KatieColors.gold)
                analyticsMetricTile(title: "Pace", score: analytics.paceAverage, accent: KatieColors.mint)
                analyticsMetricTile(title: "Confidence", score: analytics.confidenceAverage, accent: KatieColors.blush)
            }

            VStack(alignment: .leading, spacing: Layout.spacing_10) {
                analyticsMetricTile(title: "Listener", score: analytics.listenerAverage, accent: KatieColors.gold)
                analyticsMetricTile(title: "Pace", score: analytics.paceAverage, accent: KatieColors.mint)
                analyticsMetricTile(title: "Confidence", score: analytics.confidenceAverage, accent: KatieColors.blush)
            }
        }
    }

    private func analyticsMetricTile(title: String, score: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing_8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: Layout.spacing_4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < score ? accent : KatieColors.cardBackground.opacity(0.95))
                        .frame(maxWidth: .infinity, minHeight: 6, maxHeight: 6)
                }
            }

            Text("\(score)/5")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func analyticsChart(points: [ScenarioAnalyticsPoint]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: Layout.spacing_10) {
                ForEach(points) { point in
                    analyticsPointColumn(point)
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }

            VStack(alignment: .leading, spacing: Layout.spacing_10) {
                ForEach(points) { point in
                    analyticsPointRow(point)
                }
            }
        }
    }

    private func analyticsPointColumn(_ point: ScenarioAnalyticsPoint) -> some View {
        VStack(spacing: Layout.spacing_8) {
            HStack(alignment: .bottom, spacing: Layout.spacing_5) {
                analyticsMetricBar(value: point.listenerScore, accent: KatieColors.gold)
                analyticsMetricBar(value: point.paceScore, accent: KatieColors.mint)
                analyticsMetricBar(value: point.confidenceScore, accent: KatieColors.blush)
            }
            .frame(height: 78, alignment: .bottom)

            Text(point.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text("\(point.overallScore)/5")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            if point.hasReplay {
                Image(systemName: "waveform.circle.fill")
                    .font(.caption)
                    .foregroundStyle(KatieColors.mint)
            }
        }
        .padding(Layout.cardPadding)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func analyticsPointRow(_ point: ScenarioAnalyticsPoint) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing_8) {
            HStack {
                Text(point.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: 0)

                Text("Overall \(point.overallScore)/5")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
            }

            analyticsPointRowTrack(title: "Listener", value: point.listenerScore, accent: KatieColors.gold)
            analyticsPointRowTrack(title: "Pace", value: point.paceScore, accent: KatieColors.mint)
            analyticsPointRowTrack(title: "Confidence", value: point.confidenceScore, accent: KatieColors.blush)
        }
        .padding(Layout.cardPadding)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func analyticsPointRowTrack(title: String, value: Int, accent: Color) -> some View {
        HStack(spacing: Layout.spacing_8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
                .frame(width: 64, alignment: .leading)

            HStack(spacing: Layout.spacing_3) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < value ? accent : KatieColors.cardBackground.opacity(0.95))
                        .frame(maxWidth: .infinity, minHeight: 6, maxHeight: 6)
                }
            }

            if value > 0 {
                Text("\(value)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
            }
        }
    }

    private func analyticsMetricBar(value: Int, accent: Color) -> some View {
        Capsule()
            .fill(accent)
            .frame(width: 12, height: max(CGFloat(value) * 14, 8))
    }

    private var clinicianLensCard: some View {
        let language = appViewModel.languageAssessmentSnapshot
        let radar = appViewModel.currentSoundPatternRadar
        let transfer = appViewModel.currentConversationTransferPlan

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Label("Clinician lens", systemImage: "stethoscope")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Keep progress grounded in sound-pattern coaching, likely transfer hypotheses, and one answerable next step.")
                .foregroundStyle(KatieColors.textSecondary)

            progressDetailRow(
                title: language.title,
                body: language.soundFocus,
                systemImage: "dot.radiowaves.left.and.right"
            )
            progressDetailRow(
                title: "Likely transfer pattern",
                body: language.transferPattern,
                systemImage: "arrow.triangle.branch"
            )
            progressDetailRow(
                title: "Next conversation move",
                body: transfer.repairMove,
                systemImage: "figure.and.line.vertical.and.figure.stand"
            )

            Label("Boundary: Katie reflects observed speaking patterns and likely carryover. It supports clearer speech and communication practice; it does not diagnose or promise to erase an accent.", systemImage: "checkmark.shield.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.gold)

            Text(radar.evidenceLine)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var starterProgressHero: some View {
        VStack(alignment: .leading, spacing: Layout.spacing_14) {
            Label(appViewModel.currentMission.packTitle, systemImage: "sparkles.rectangle.stack.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.firstWinHeadline)
                .font(.title3.bold())
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.starterProofStatusLine)
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            currentPackRunwayRows

            HStack(spacing: Layout.spacing_10) {
                snapshotMetric(title: "Saved packs", value: "0", detail: "No scenario has your own proof yet")
                snapshotMetric(title: "Compare-ready", value: "0", detail: "A second save unlocks before/after")
            }

            KatieWrap(spacing: 8, rowSpacing: 8) {
                Button(appViewModel.firstWinPrimaryActionTitle) {
                    appViewModel.performFirstWinPrimaryAction {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                .padding(.vertical, Layout.mediumChipVerticalPadding)
                .background(KatieColors.accent)
                .foregroundStyle(.black)
                .clipShape(Capsule())

                Button("Review Today queue") {
                    appViewModel.selectedTab = .today
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                .padding(.vertical, Layout.mediumChipVerticalPadding)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }
        }
        .katieCard()
    }

    private var progressUnlocksCard: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("What Progress unlocks next")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            progressDetailRow(
                title: "Today creates proof",
                body: "Save one calm rep so Katie has something real to carry forward.",
                systemImage: "mic.fill"
            )
            progressDetailRow(
                title: "Review turns it into memory",
                body: "Your first proof becomes the honest anchor for replay, compare, and reminder copy.",
                systemImage: "arrow.left.arrow.right.circle.fill"
            )
            progressDetailRow(
                title: "Progress keeps the continuity warm",
                body: "Once you have a saved rep, this tab starts tracking pack warmth instead of showing theoretical analytics.",
                systemImage: "chart.line.uptrend.xyaxis.circle.fill"
            )
        }
        .katieCard()
    }

    private func progressDetailRow(title: String, body: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: Layout.gridSpacing) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)
                .frame(width: 28, height: 28)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.chipCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Layout.spacing_4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(body)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
    }

    private var currentPackRunwayRows: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            progressDetailRow(
                title: appViewModel.transferHypothesisStatusTitle,
                body: appViewModel.transferHypothesisFollowThroughLine,
                systemImage: appViewModel.transferHypothesisFeedback.systemImage
            )
            progressDetailRow(
                title: "Next grounded move",
                body: appViewModel.currentPackNextStepLabel,
                systemImage: "arrow.forward.circle.fill"
            )
        }
    }

    private var earlyProgressHero: some View {
        VStack(alignment: .leading, spacing: Layout.spacing_14) {
            Label(appViewModel.currentMission.packTitle, systemImage: "waveform.badge.mic")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.firstWinHeadline)
                .font(.title3.bold())
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.starterProofStatusLine)
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            currentPackRunwayRows

            HStack(spacing: Layout.spacing_10) {
                snapshotMetric(title: "Saved packs", value: "\(activePackCount)", detail: activePackCount == 1 ? "1 pack has your own proof" : "\(activePackCount) packs have your own proof")
                snapshotMetric(title: "Replay-ready", value: "\(replayReadyCount)", detail: replayReadyCount == 0 ? "Proof is text-first so far" : replayReadyCount == 1 ? "1 clip replays on this iPhone" : "\(replayReadyCount) clips replay on this iPhone")
            }

            Text("Next unlock: save a second rep in one pack so Progress can open a real compare instead of a single-proof summary.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    @ViewBuilder
    private var compareStoryCard: some View {
        if let latestCompareEntry {
            VStack(alignment: .leading, spacing: Layout.spacing_14) {
                HStack(alignment: .top, spacing: Layout.gridSpacing) {
                    Label("Latest compare story", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: Layout.subSpacing) {
                        Text(latestCompareEntry.scenario.packTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.smallChipVerticalPadding)
                            .background(KatieColors.mint.opacity(0.14))
                            .clipShape(Capsule())

                        Text(appViewModel.freshnessLabel(for: latestCompareEntry.latest))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.accent)
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.smallChipVerticalPadding)
                            .background(KatieColors.accent.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }

                Text(appViewModel.compareTruthLine(anchor: latestCompareEntry.anchor, latest: latestCompareEntry.latest))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(appViewModel.latestReviewSummaryLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let anchor = latestCompareEntry.anchor {
                    compareScoreShiftStrip(anchor: anchor, latest: latestCompareEntry.latest)
                } else {
                    KatieInlineNotice(
                        title: "Score shifts",
                        message: appViewModel.reflectionDeltaSummary
                    )
                }

                Text(appViewModel.reflectionDeltaSummary)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    appViewModel.openReview(for: appViewModel.currentMission, anchor: latestCompareEntry.anchor)
                } label: {
                    Label("Review latest compare", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
            }
            .katieCard()
        }
    }

    private var progressSnapshotCard: some View {
        return VStack(alignment: .leading, spacing: Layout.spacing_14) {
            Text("Progress snapshot")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Live proof at a glance, without the dashboard clutter or fake analytics weight.")
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            if let latestUserReflection = appViewModel.currentScenarioUserHistory.first?.selfReflection {
                VStack(alignment: .leading, spacing: Layout.spacing_8) {
                    Text("Latest self-check")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    KatieWrap(spacing: 8, rowSpacing: 8) {
                        proofConfidenceTile(title: "Listener catch", score: latestUserReflection.listenerCatchScore, accent: KatieColors.gold)
                        proofConfidenceTile(title: "Pace control", score: latestUserReflection.paceControlScore, accent: KatieColors.mint)
                        proofConfidenceTile(title: "Confidence", score: latestUserReflection.confidenceScore, accent: KatieColors.blush)
                    }
                }
            } else {
                KatieInlineNotice(title: "Confidence strip", message: "Save one real rep to unlock the confidence strip.")
            }

            KatieWrap(spacing: 8, rowSpacing: 8) {
                snapshotPulseChip(
                    title: compareReadyCount > 0 ? "Compare unlocked" : "Next unlock",
                    body: compareReadyCount > 0 ? "\(compareReadyCount) pack\(compareReadyCount == 1 ? "" : "s") can open a real before/after now." : "One calmer retake in any saved pack unlocks the first compare."
                )
                snapshotPulseChip(
                    title: replayReadyCount > 0 ? "Replay is ready" : "Replay is next",
                    body: replayReadyCount > 0 ? "\(replayReadyCount) clip\(replayReadyCount == 1 ? "" : "s") can replay on this iPhone." : "Save one local playback clip so Katie can coach from your real sound."
                )
                snapshotPulseChip(
                    title: protectedScenario == nil ? "Protect a pack" : "Protected right now",
                    body: protectedScenario.map { "\($0.packTitle) is the pack Katie is already protecting for reminders and replay continuity." } ?? "Turn one pack into the protected lane so reminders stay grounded in a real rep."
                )
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Layout.spacing_10) {
                snapshotMetric(title: "Active packs", value: "\(activePackCount)", detail: activePackCount == 1 ? "1 pack has your own saved rep" : "\(activePackCount) packs have your own saved reps")
                snapshotMetric(title: "Compare-ready", value: "\(compareReadyCount)", detail: compareReadyCount == 0 ? "Save a second rep to unlock before/after" : compareReadyCount == 1 ? "1 pack can open a true compare" : "\(compareReadyCount) packs can open true compare")
                snapshotMetric(title: "Replay-ready clips", value: "\(replayReadyCount)", detail: replayReadyCount == 0 ? "No local clip is ready yet" : replayReadyCount == 1 ? "1 local clip can replay on this iPhone" : "\(replayReadyCount) local clips can replay on this iPhone")
                snapshotMetric(title: "Reminder owner", value: reminderOwnerSummary, detail: reminderOwnerDetail)
            }

            Text("Quick handoff")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            KatieWrap(spacing: 8, rowSpacing: 8) {
                if let latestCompareEntry {
                    Button("Open latest compare") {
                        appViewModel.openReview(for: latestCompareEntry.scenario, anchor: latestCompareEntry.anchor)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(Capsule())
                }

                if let protectedScenario {
                    Button("Open protected pack") {
                        appViewModel.openProgress(for: protectedScenario)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(Capsule())
                }

                if let replayReadyScenario {
                    Button("Steady Replay Practice") {
                        appViewModel.openPractice(for: replayReadyScenario)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                } else {
                    Button("Record first replay") {
                        appViewModel.openPractice(for: appViewModel.currentMission)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
            }
        }
        .katieCard()
    }

    private var startingHypothesisSummaryCard: some View {
        let snapshot = appViewModel.languageAssessmentSnapshot

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.spacing_4) {
                    Text("Starting hypothesis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(snapshot.title)
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(2)

                    Text(snapshot.caveat)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 12)

                Text(appViewModel.transferHypothesisStatusTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, Layout.smallChipHorizontalPadding)
                    .padding(.vertical, Layout.smallChipVerticalPadding)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            progressDetailRow(
                title: "Sound focus first",
                body: snapshot.soundFocus,
                systemImage: "dot.radiowaves.left.and.right"
            )
            progressDetailRow(
                title: "Language watch-out",
                body: snapshot.transferPattern,
                systemImage: "arrow.triangle.branch"
            )

            VStack(alignment: .leading, spacing: Layout.subSpacing) {
                Text("Self-check in this pack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Text(appViewModel.transferHypothesisPracticeBridgeLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Label(appViewModel.transferHypothesisFollowThroughLine, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
        }
        .katieCard()
    }


    private var confidenceTrendCard: some View {
        let trendSessions = Array(appViewModel.currentScenarioUserHistory.prefix(3))
        let replayReadyCount = trendSessions.filter { appViewModel.hasPlayback(for: $0) }.count

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.subSpacing) {
                    Label("Recent confidence trend", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("The last few real saves show whether this pack is settling or wobbling.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                if let latest = trendSessions.first {
                    Text(appViewModel.freshnessLabel(for: latest))
                        .modifier(KatieCapsuleLabelStyle())
                } else {
                    Text("No trend yet")
                        .modifier(KatieCapsuleLabelStyle())
                }
            }

            if trendSessions.isEmpty {
                KatieInlineNotice(
                    title: "Trend locked",
                    message: "Save one real rep to unlock the recent confidence timeline."
                )
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Layout.spacing_10) {
                        ForEach(Array(trendSessions.enumerated()), id: \.element.id) { index, session in
                            confidenceTrendTile(
                                label: confidenceTrendLabel(for: index),
                                session: session,
                                accent: confidenceTrendAccent(for: index)
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: Layout.spacing_10) {
                        ForEach(Array(trendSessions.enumerated()), id: \.element.id) { index, session in
                            confidenceTrendTile(
                                label: confidenceTrendLabel(for: index),
                                session: session,
                                accent: confidenceTrendAccent(for: index)
                            )
                        }
                    }
                }

                Text("\(replayReadyCount) of \(trendSessions.count) recent reps can replay on this iPhone.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .katieCard()
    }

    private func confidenceTrendLabel(for index: Int) -> String {
        switch index {
        case 0:
            return "Now"
        case 1:
            return "1 back"
        default:
            return "2 back"
        }
    }

    private func confidenceTrendAccent(for index: Int) -> Color {
        switch index {
        case 0:
            return KatieColors.mint
        case 1:
            return KatieColors.gold
        default:
            return KatieColors.accent
        }
    }

    private func confidenceTrendTile(label: String, session: PracticeSession, accent: Color) -> some View {
        let reflection = session.selfReflection ?? SessionSelfReflection()
        let score = min(max(reflection.confidenceScore, 0), 5)

        return VStack(alignment: .leading, spacing: Layout.spacing_8) {
            HStack(alignment: .top, spacing: Layout.spacing_8) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)

                Spacer(minLength: 0)

                if appViewModel.hasPlayback(for: session) {
                    Label("Replay", systemImage: "play.circle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                } else {
                    Label("Transcript", systemImage: "text.quote")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }

            Text(appViewModel.freshnessLabel(for: session))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Layout.spacing_4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < score ? accent : KatieColors.textSecondary.opacity(0.14))
                        .frame(width: 10, height: 6)
                }
            }

            Text("Confidence \(score)/5")
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var clarityStoryHero: some View {
        VStack(alignment: .leading, spacing: Layout.spacing_14) {
            Label(appViewModel.currentMission.packTitle, systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.improvementHeadline)
                .font(.title2.bold())
                .foregroundStyle(KatieColors.textPrimary)

            Text("\(appViewModel.currentScenarioSnapshot.bestStreakLabel) • Next unlock: \(appViewModel.currentScenarioSnapshot.nextUnlockLabel)")
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            VStack(alignment: .leading, spacing: Layout.subSpacing) {
                Label("Next grounded move", systemImage: "arrow.forward.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(appViewModel.currentPackNextStepLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .katieCard()
    }

    private var featuredWinSummary: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("First-win continuity")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            if let featured = appViewModel.featuredWin {
                HStack(spacing: Layout.spacing_8) {
                    Text(featured.sourceTag)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text(appViewModel.freshnessLabel(for: featured.latestSession))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                        .padding(.horizontal, Layout.tightChipHorizontalPadding)
                        .padding(.vertical, Layout.tightChipVerticalPadding)
                        .background(KatieColors.cardSecondary)
                        .clipShape(Capsule())
                }
                Text(featured.deltaHint)
                    .foregroundStyle(KatieColors.textSecondary)

                Text(appViewModel.starterProofStatusLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Label(featured.readiness.title, systemImage: featured.readiness.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                Text(featuredWinTruthLine(for: featured))
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                featuredWinProofTruth(for: featured)

                if appViewModel.hasPlayback(for: featured.latestSession) || (featured.anchorSession != nil && appViewModel.hasPlayback(for: featured.anchorSession!)) {
                    KatieWrap(spacing: 8, rowSpacing: 8) {
                        if appViewModel.hasPlayback(for: featured.latestSession) {
                            Button(appViewModel.currentlyPlayingSessionID == featured.latestSession.id ? "Stop replay" : "Play latest proof") {
                                if appViewModel.currentlyPlayingSessionID == featured.latestSession.id {
                                    appViewModel.stopPlayback()
                                } else {
                                    appViewModel.playSession(featured.latestSession)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(Capsule())
                        }

                        if let anchor = featured.anchorSession,
                           appViewModel.hasPlayback(for: anchor) {
                            Button(appViewModel.currentlyPlayingSessionID == anchor.id ? "Stop earlier proof" : "Play earlier proof") {
                                if appViewModel.currentlyPlayingSessionID == anchor.id {
                                    appViewModel.stopPlayback()
                                } else {
                                    appViewModel.playSession(anchor)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(Capsule())
                        }
                    }
                }

                if appViewModel.compareReplayRecoveryPrompt(anchor: featured.anchorSession, latest: featured.latestSession) != nil {
                    featuredWinReplayNotice(anchor: featured.anchorSession, latest: featured.latestSession)
                }

                KatieWrap(spacing: 8, rowSpacing: 8) {
                    if let repairActionTitle = featuredWinRepairActionTitle(for: featured) {
                        Button(repairActionTitle) {
                            appViewModel.openPractice(for: featured.scenario)
                        }
                        .modifier(KatieActionChipStyle(background: KatieColors.accent, foreground: .black, horizontalPadding: 10))
                    }

                    Button(compareLibraryReviewActionTitle(anchor: featured.anchorSession, latest: featured.latestSession)) {
                        appViewModel.openReview(for: featured.scenario, anchor: featured.anchorSession)
                    }
                    .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))

                    Button(compareReminderActionTitle(for: featured.scenario)) {
                        handleCompareReminderAction(for: featured.scenario)
                    }
                    .modifier(KatieActionChipStyle(background: compareReminderActionBackground(for: featured.scenario), foreground: compareReminderActionForeground(for: featured.scenario), horizontalPadding: 10))

                    Button("Open progress") {
                        appViewModel.openProgress(for: featured.scenario)
                    }
                    .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))

                    progressActionsMenu(
                        for: featured.scenario,
                        latest: featured.latestSession,
                        anchor: featured.anchorSession,
                        reminderTitle: compareReminderActionTitle(for: featured.scenario),
                        reminderAction: { handleCompareReminderAction(for: featured.scenario) },
                        label: "Peek"
                    )
                }
            } else {
                Text("Your first save in each scenario appears as an honest progress object before broader analytics.")
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .katieCard()
    }

    private var scenarioLanesCard: some View {
        VStack(alignment: .leading, spacing: Layout.spacing_14) {
            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                VStack(alignment: .leading, spacing: Layout.subSpacing) {
                    Text("Pack library")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Keep Progress calm by opening the full pack list only when you want to inspect every benchmark, compare, and reminder handoff.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Button(isPackLibraryExpanded ? "Hide" : "Open") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        isPackLibraryExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                .padding(.vertical, Layout.mediumChipVerticalPadding)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            KatieWrap(spacing: 8, rowSpacing: 8) {
                Text("Current pack: \(appViewModel.currentMission.packTitle)")
                    .modifier(KatieCapsuleLabelStyle())
                Text(activePackCount == 1 ? "1 active pack" : "\(activePackCount) active packs")
                    .modifier(KatieCapsuleLabelStyle())
                Text(compareReadyCount == 1 ? "1 compare-ready" : "\(compareReadyCount) compare-ready")
                    .modifier(KatieCapsuleLabelStyle())
                Text(protectedScenario.map { "Protected pack: \($0.packTitle)" } ?? "No protected pack")
                    .modifier(KatieCapsuleLabelStyle())
            }

            if isPackLibraryExpanded {
                ForEach(appViewModel.availableScenarios) { scenario in
                    let history = appViewModel.scenarioHistories[scenario] ?? []
                    let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)
                    let status = scenarioStatus(for: scenario, count: ownedCount)
                    let latest = history.first(where: \.isUserOwned) ?? history.first
                    let anchor = Array(history.filter(\.isUserOwned).dropFirst()).first
                    let continuityStrip = appViewModel.continuityTruthStrip(for: scenario)

                    VStack(alignment: .leading, spacing: Layout.spacing_10) {
                        Button {
                            appViewModel.selectScenario(scenario)
                        } label: {
                            HStack(alignment: .top, spacing: Layout.gridSpacing) {
                                Image(systemName: scenario == appViewModel.currentMission ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.textSecondary)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: Layout.subSpacing) {
                                    HStack {
                                        Text(scenario.packTitle)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KatieColors.textPrimary)
                                        Spacer()
                                        Text(status)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(KatieColors.mint)
                                    }

                                    Text(appViewModel.scenarioStatusDetail(for: scenario))
                                        .font(.footnote)
                                        .foregroundStyle(KatieColors.textSecondary)

                                    KatieContinuityNotice(strip: continuityStrip)

                                    if let latest {
                                        scenarioProofChips(for: scenario, latest: latest, anchor: anchor, status: status)
                                    }


                                    if scenario == .managerOneOnOne {
                                        Label("Guardrail: keep the compare on observed pattern + one answerable ask, not a diagnostic story.", systemImage: "checkmark.shield.fill")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(KatieColors.gold)
                                    }

                                    if ownedCount >= 2 {
                                        Text("Follow-through: keep this pack warm with one replay per day.")
                                            .font(.caption)
                                            .foregroundStyle(KatieColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: Layout.spacing_10) {
                            Button(primaryScenarioActionTitle(for: scenario, latest: latest)) {
                                handlePrimaryScenarioAction(for: scenario, latest: latest)
                            }
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.spacing_10)
                            .background(primaryScenarioActionBackground(for: scenario))
                            .foregroundStyle(primaryScenarioActionForeground(for: scenario))
                            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

                            progressActionsMenu(for: scenario, latest: latest, anchor: anchor, reminderTitle: followThroughReminderActionTitle(for: scenario), reminderAction: { handleFollowThroughReminderAction(for: scenario) }, label: "Peek")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                }
            }
        }
        .katieCard()
    }

    private var compareLibraryCard: some View {
        VStack(alignment: .leading, spacing: Layout.spacing_14) {
            Text("Recent compare moments")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            if !appViewModel.compareLibraryEntries.isEmpty {
                compareLibraryEntriesRail
            } else {
                VStack(alignment: .leading, spacing: Layout.gridSpacing) {
                    Text("Starter and demo reps still show up in the proof/provenance cards above. The compare library only opens once a pack has two user-owned saves from this iPhone.")
                    .foregroundStyle(KatieColors.textSecondary)

                    Text("Save a real second rep in any pack and Katie will promote it here as an honest before/after compare.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    HStack(spacing: Layout.spacing_8) {
                        Button("Review transcript-only proof") {
                            appViewModel.openReview(for: appViewModel.currentMission)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Layout.smallChipHorizontalPadding)
                        .padding(.vertical, Layout.mediumChipVerticalPadding)
                        .background(KatieColors.cardSecondary)
                        .foregroundStyle(KatieColors.textPrimary)
                        .clipShape(Capsule())

                        Button(appViewModel.comparePracticeActionTitle(for: appViewModel.latestSession)) {
                            appViewModel.openPractice(for: appViewModel.currentMission)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Layout.smallChipHorizontalPadding)
                        .padding(.vertical, Layout.mediumChipVerticalPadding)
                        .background(KatieColors.accent)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                    }
                }
            }

            Text(appViewModel.currentScenarioSnapshot.portableProofLabel)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    @ViewBuilder
    private var compareLibraryEntriesRail: some View {
        if usesWideProgressLayout {
            LazyVGrid(columns: compareLibraryGridColumns, alignment: .leading, spacing: Layout.gridSpacing) {
                ForEach(appViewModel.compareLibraryEntries) { entry in
                    compareLibraryEntryCard(for: entry)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Layout.gridSpacing) {
                    ForEach(appViewModel.compareLibraryEntries) { entry in
                        compareLibraryEntryCard(for: entry)
                            .frame(width: compareLibraryCardWidth, alignment: .leading)
                    }
                }
            }
        }
    }

    private func compareLibraryEntryCard(for entry: CompareLibraryEntry) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing_10) {
            Button {
                appViewModel.selectScenario(entry.scenario)
                if let anchor = entry.anchor {
                    appViewModel.selectCompareAnchor(anchor)
                }
            } label: {
                VStack(alignment: .leading, spacing: Layout.spacing_10) {
                    HStack {
                        VStack(alignment: .leading, spacing: Layout.spacing_4) {
                            Text(entry.scenario.packTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)

                            Text(entry.latest.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                                .lineLimit(2)
                        }
                        Spacer()
                        if entry.scenario == appViewModel.currentMission {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(KatieColors.accent)
                        }
                    }

                    Text(entry.latest.protectedLine)
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(3)

                    HStack(spacing: Layout.spacing_8) {
                        Text(entry.statusLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)

                        Text(appViewModel.freshnessLabel(for: entry.latest))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, Layout.tightChipHorizontalPadding)
                            .padding(.vertical, Layout.tightChipVerticalPadding)
                            .background(KatieColors.cardBackground.opacity(0.85))
                            .clipShape(Capsule())

                        if entry.anchor != nil && entry.scenario == appViewModel.currentMission {
                            Text("Active compare")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, Layout.tightChipHorizontalPadding)
                                .padding(.vertical, Layout.tightChipVerticalPadding)
                                .background(KatieColors.accent)
                                .clipShape(Capsule())
                        }
                    }

                    scenarioProofChips(for: entry.scenario, latest: entry.latest, anchor: entry.anchor, status: entry.statusLabel, background: KatieColors.cardBackground.opacity(0.85))

                    Label(appViewModel.displayCompareReadinessTitle(for: entry.latest), systemImage: appViewModel.displayCompareReadinessSystemImage(for: entry.latest))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    if let anchor = entry.anchor {
                        Text("Against: \(anchor.protectedLine)")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text("Save one calmer retake in this pack and Katie will turn it into a before/after compare.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(3)
                    }

                    Text(appViewModel.scenarioNextStepLine(for: entry.scenario))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(3)

                    Label(entry.latest.captureSource.title, systemImage: entry.latest.captureSource.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    if let duration = entry.latest.durationSeconds, appViewModel.hasPlayback(for: entry.latest) {
                        Label("\(Int(duration))s local clip", systemImage: "timer")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                    }

                    Text(appViewModel.displayCompareReadinessDetail(for: entry.latest))
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(3)

                    Label(compareLibraryReplayStateLine(for: entry), systemImage: "waveform")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(entry.latest.transcriptFootnote)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(3)

                    if appViewModel.compareReplayRecoveryPrompt(anchor: entry.anchor, latest: entry.latest) != nil {
                        compareRecoveryNotice(anchor: entry.anchor, latest: entry.latest)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            VStack(spacing: Layout.spacing_8) {
                HStack(spacing: Layout.spacing_8) {
                    Button(compareLibraryReviewActionTitle(anchor: entry.anchor, latest: entry.latest)) {
                        appViewModel.openReview(for: entry.scenario, anchor: entry.anchor)
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.spacing_10)
                    .background(KatieColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

                    compareLibraryActionsMenu(for: entry)
                }

                Button(primaryScenarioActionTitle(for: entry.scenario, latest: entry.latest)) {
                    handlePrimaryScenarioAction(for: entry.scenario, latest: entry.latest)
                }
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.spacing_10)
                .background(primaryScenarioActionBackground(for: entry.scenario))
                .foregroundStyle(primaryScenarioActionForeground(for: entry.scenario))
                .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
            }
        }
        .padding(Layout.heroPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(entry.scenario == appViewModel.currentMission ? KatieColors.accent.opacity(0.16) : KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius20, style: .continuous))
    }

    private var growthThemesCard: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("What’s getting stronger")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            ForEach(appViewModel.growthThemes, id: \.self) { theme in
                Label(theme, systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                    .padding(.vertical, Layout.spacing_10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
            }
        }
        .katieCard()
    }

    private var consistencyCard: some View {
        let latest = appViewModel.currentScenarioHistory.first(where: \.isUserOwned) ?? appViewModel.currentScenarioHistory.first
        let anchor = Array(appViewModel.currentScenarioHistory.filter(\.isUserOwned).dropFirst()).first

        return VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("Consistency")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            HStack(spacing: Layout.spacing_8) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index < min(max(appViewModel.currentScenarioSnapshot.completedSessions, 1), 5) ? KatieColors.mint : KatieColors.cardSecondary)
                        .frame(width: 10, height: 10)
                }
            }

            Text("\(min(max(appViewModel.currentScenarioSnapshot.completedSessions, 1), 5)) practice touch\(appViewModel.currentScenarioSnapshot.completedSessions == 1 ? "" : "es") kept this scenario visible this week.")
                .foregroundStyle(KatieColors.textSecondary)
            Text(appViewModel.momentumSummaryLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
            Text(appViewModel.currentScenarioSnapshot.reminderCadenceLabel)
                .font(.subheadline)
                .foregroundStyle(KatieColors.accent)

            if let latest {
                HStack(spacing: Layout.spacing_8) {
                    if appViewModel.hasPlayback(for: latest) {
                        Button(appViewModel.currentlyPlayingSessionID == latest.id ? "Stop" : "Play") {
                            if appViewModel.currentlyPlayingSessionID == latest.id {
                                appViewModel.stopPlayback()
                            } else {
                                appViewModel.playSession(latest)
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Layout.smallChipHorizontalPadding)
                        .padding(.vertical, Layout.mediumChipVerticalPadding)
                        .background(KatieColors.cardSecondary)
                        .foregroundStyle(KatieColors.textPrimary)
                        .clipShape(Capsule())
                    }

                    Button(compareLibraryReviewActionTitle(anchor: anchor, latest: latest)) {
                        appViewModel.openReview(for: appViewModel.currentMission, anchor: anchor)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.smallChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(Capsule())

                    Button(compareReminderActionTitle(for: appViewModel.currentMission)) {
                        handleCompareReminderAction(for: appViewModel.currentMission)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.smallChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(compareReminderActionBackground(for: appViewModel.currentMission))
                    .foregroundStyle(compareReminderActionForeground(for: appViewModel.currentMission))
                    .clipShape(Capsule())

                    Button("Practice") {
                        appViewModel.openPractice(for: appViewModel.currentMission)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.smallChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())

                    Button("Open progress") {
                        appViewModel.openProgress(for: appViewModel.currentMission)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.smallChipHorizontalPadding)
                    .padding(.vertical, Layout.mediumChipVerticalPadding)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(Capsule())
                }
            }
        }
        .katieCard()
    }

    private var premiumContinuityCard: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("Keep the thread going")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
            Text("Save more compare moments, revisit older wins, and keep scenario progress warm across interviews, meetings, presentations, and customer conversations.")
                .foregroundStyle(KatieColors.textSecondary)
            Text(appViewModel.premiumHeroSummary)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            ForEach(appViewModel.premiumExperimentSurfaces) { experiment in
                VStack(alignment: .leading, spacing: Layout.subSpacing) {
                    HStack {
                        Text(experiment.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)
                        Spacer()
                        Text(experiment.badge)
                            .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                    }

                    Text(experiment.detail)
                        .font(.caption)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
            }
        }
        .katieCard()
    }

    private var scenarioPackFollowThroughCard: some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text("Pack follow-through")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            ForEach(appViewModel.availableScenarios) { scenario in
                let history = appViewModel.scenarioHistories[scenario] ?? []
                let latest = history.first(where: \.isUserOwned) ?? history.first
                let anchor = Array(history.filter(\.isUserOwned).dropFirst()).first
                let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)
                let status = ownedCount >= 3 ? "Warm" : ownedCount == 2 ? "Live compare" : ownedCount == 1 ? "Benchmark saved" : "First proof"
                let seedCount = history.filter { $0.captureSource == .seeded }.count
                let continuityStrip = appViewModel.continuityTruthStrip(for: scenario)

                HStack(alignment: .top, spacing: Layout.gridSpacing) {
                    Image(systemName: scenario == appViewModel.currentMission ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.textSecondary)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: Layout.subSpacing) {
                        HStack {
                            Text(scenario.packTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                            Spacer()
                            Text(status)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)
                        }

                        KatieContinuityNotice(strip: continuityStrip)

                        if ownedCount == 0, seedCount > 0 {
                            Text("Starter sample is still leading this pack until you save your own first rep.")
                                .font(.caption)
                                .foregroundStyle(KatieColors.mint)
                        }

                        if let latest {
                            scenarioProofChips(for: scenario, latest: latest, anchor: anchor, status: reviewTruthLabel(for: scenario, latest: latest, anchor: anchor), background: KatieColors.cardBackground.opacity(0.85))
                        }

                        Text(reviewTruthDetail(for: latest, anchor: anchor))
                            .font(.caption)
                            .foregroundStyle(KatieColors.textSecondary)
                            .lineLimit(3)

                        Text(appViewModel.scenarioStatusDetail(for: scenario))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(followThroughStatusColor(for: latest))

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            if let latest, appViewModel.hasPlayback(for: latest) {
                                Button(appViewModel.currentlyPlayingSessionID == latest.id ? "Stop replay" : "Play replay") {
                                    if appViewModel.currentlyPlayingSessionID == latest.id {
                                        appViewModel.stopPlayback()
                                    } else {
                                        appViewModel.playSession(latest)
                                    }
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, Layout.smallChipHorizontalPadding)
                                .padding(.vertical, Layout.mediumChipVerticalPadding)
                                .background(KatieColors.cardBackground.opacity(0.85))
                                .foregroundStyle(KatieColors.textPrimary)
                                .clipShape(Capsule())
                            }

                            if let anchor, appViewModel.hasPlayback(for: anchor) {
                                Button(appViewModel.currentlyPlayingSessionID == anchor.id ? "Stop baseline" : "Play baseline") {
                                    if appViewModel.currentlyPlayingSessionID == anchor.id {
                                        appViewModel.stopPlayback()
                                    } else {
                                        appViewModel.playSession(anchor)
                                    }
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, Layout.smallChipHorizontalPadding)
                                .padding(.vertical, Layout.mediumChipVerticalPadding)
                                .background(KatieColors.cardBackground.opacity(0.85))
                                .foregroundStyle(KatieColors.textPrimary)
                                .clipShape(Capsule())
                            }

                            Button(reviewTruthActionTitle(for: anchor)) {
                                appViewModel.openReview(for: scenario, anchor: anchor)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(KatieColors.cardBackground.opacity(0.85))
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(Capsule())

                            Button(followThroughReminderActionTitle(for: scenario)) {
                                handleFollowThroughReminderAction(for: scenario)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(followThroughReminderActionBackground(for: scenario))
                            .foregroundStyle(followThroughReminderActionForeground(for: scenario))
                            .clipShape(Capsule())

                            Button(primaryScenarioActionTitle(for: scenario, latest: latest)) {
                                handlePrimaryScenarioAction(for: scenario, latest: latest)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(primaryScenarioActionBackground(for: scenario))
                            .foregroundStyle(primaryScenarioActionForeground(for: scenario))
                            .clipShape(Capsule())

                            Button("Open progress") {
                                appViewModel.openProgress(for: scenario)
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.smallChipHorizontalPadding)
                            .padding(.vertical, Layout.mediumChipVerticalPadding)
                            .background(KatieColors.cardBackground.opacity(0.85))
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
            }
        }
        .katieCard()
    }

    private func reviewTruthLabel(for scenario: PracticeScenario, latest: PracticeSession, anchor: PracticeSession?) -> String {
        if anchor != nil {
            return "Latest compare"
        }

        return latest.isUserOwned ? "Latest proof" : "Starter sample"
    }

    private func reviewTruthDetail(for latest: PracticeSession?, anchor: PracticeSession?) -> String {
        guard let latest else {
            return "Save the first benchmark in this pack to start the compare trail."
        }

        if let anchor {
            return "Review stays anchored to \(anchor.protectedLine) before opening \(latest.protectedLine)."
        }

        if latest.isUserOwned {
            return "Review opens your newest saved proof in this pack before the next retake turns it into a compare."
        }

        return "This pack still opens on the starter sample until you save your own first proof."
    }

    private func reviewTruthActionTitle(for anchor: PracticeSession?) -> String {
        anchor == nil ? "Open latest proof" : "Open latest compare"
    }

    @ViewBuilder
    private func featuredWinProofTruth(for featured: FeaturedWin) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .top, spacing: Layout.spacing_10) {
                if let anchor = featured.anchorSession {
                    featuredWinTruthCard(
                        title: "Earlier proof",
                        session: anchor,
                        accent: KatieColors.gold
                    )
                }

                featuredWinTruthCard(
                    title: featured.anchorSession == nil ? "Current proof" : "Latest proof",
                    session: featured.latestSession,
                    accent: KatieColors.mint
                )
            }

            VStack(alignment: .leading, spacing: Layout.spacing_10) {
                if let anchor = featured.anchorSession {
                    featuredWinTruthCard(
                        title: "Earlier proof",
                        session: anchor,
                        accent: KatieColors.gold
                    )
                }

                featuredWinTruthCard(
                    title: featured.anchorSession == nil ? "Current proof" : "Latest proof",
                    session: featured.latestSession,
                    accent: KatieColors.mint
                )
            }
        }
    }

    private func featuredWinTruthCard(title: String, session: PracticeSession, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacing_10) {
            HStack(alignment: .top, spacing: Layout.spacing_8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: 0)

                Image(systemName: session.captureSource.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }

            Text(appViewModel.compactCaptureSourceLabel(for: session))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            KatieWrap(spacing: 8, rowSpacing: 8) {
                proofFactChip(appViewModel.displayCompareReadinessTitle(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
                proofFactChip(appViewModel.freshnessLabel(for: session), systemImage: "clock")
                proofFactChip(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
            }

            Text(appViewModel.displayCompareReadinessDetail(for: session))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func featuredWinTruthLine(for featured: FeaturedWin) -> String {
        if let anchor = featured.anchorSession {
            return "Earlier proof is \(appViewModel.compactCaptureSourceLabel(for: anchor).lowercased()) from \(appViewModel.freshnessLabel(for: anchor).lowercased()); latest proof is \(appViewModel.compactCaptureSourceLabel(for: featured.latestSession).lowercased()) from \(appViewModel.freshnessLabel(for: featured.latestSession).lowercased()). \(featuredWinReplayLine(anchor: anchor, latest: featured.latestSession))"
        }

        return "Current proof is \(appViewModel.compactCaptureSourceLabel(for: featured.latestSession).lowercased()) from \(appViewModel.freshnessLabel(for: featured.latestSession).lowercased()). \(featuredWinReplayLine(anchor: nil, latest: featured.latestSession))"
    }

    private func featuredWinReplayLine(anchor: PracticeSession?, latest: PracticeSession) -> String {
        let latestHasReplay = appViewModel.hasPlayback(for: latest)

        guard let anchor else {
            return latestHasReplay
                ? "Replay is attached on this iPhone."
                : "Replay is not attached on this iPhone yet, so Katie keeps the transcript trail visible instead."
        }

        let anchorHasReplay = appViewModel.hasPlayback(for: anchor)

        switch (anchorHasReplay, latestHasReplay) {
        case (true, true):
            return "Both sides can replay on this iPhone right now."
        case (true, false):
            return "Only the earlier proof can replay on this iPhone right now."
        case (false, true):
            return "Only the latest proof can replay on this iPhone right now."
        case (false, false):
            return "Neither side can replay on this iPhone right now, so Katie keeps the compare trail transcript-visible."
        }
    }

    private func featuredWinRepairActionTitle(for featured: FeaturedWin) -> String? {
        appViewModel.compareReplayRecoveryPrompt(anchor: featured.anchorSession, latest: featured.latestSession)?.actionTitle
    }

    private func featuredWinReplayNotice(anchor: PracticeSession?, latest: PracticeSession) -> some View {
        let prompt = appViewModel.compareReplayRecoveryPrompt(anchor: anchor, latest: latest)

        return VStack(alignment: .leading, spacing: Layout.spacing_8) {
            Label(prompt?.title ?? "Replay needs a fresh clip", systemImage: "waveform.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(prompt?.message ?? "Katie kept the compare trail, but one side still needs a fresh local clip on this iPhone.")
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            Button(prompt?.actionTitle ?? "Restore replay") {
                appViewModel.openPractice(for: latest.scenario)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Layout.smallChipHorizontalPadding)
            .padding(.vertical, Layout.mediumChipVerticalPadding)
            .background(KatieColors.accent)
            .foregroundStyle(.black)
            .clipShape(Capsule())
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func proofFactChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(KatieColors.textSecondary)
            .padding(.horizontal, Layout.smallChipHorizontalPadding)
            .padding(.vertical, Layout.mediumChipVerticalPadding)
            .background(KatieColors.cardSecondary)
            .clipShape(Capsule())
    }

    private func snapshotMetric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.subSpacing) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(14)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func compareScoreShiftStrip(anchor: PracticeSession, latest: PracticeSession) -> some View {
        if let anchorReflection = anchor.selfReflection, let latestReflection = latest.selfReflection {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Layout.spacing_10) {
                    compareScoreShiftMetric(
                        title: "Listener catch",
                        earlier: anchorReflection.listenerCatchScore,
                        latest: latestReflection.listenerCatchScore,
                        accent: KatieColors.gold
                    )

                    compareScoreShiftMetric(
                        title: "Pace control",
                        earlier: anchorReflection.paceControlScore,
                        latest: latestReflection.paceControlScore,
                        accent: KatieColors.mint
                    )

                    compareScoreShiftMetric(
                        title: "Confidence",
                        earlier: anchorReflection.confidenceScore,
                        latest: latestReflection.confidenceScore,
                        accent: KatieColors.blush
                    )
                }

                VStack(alignment: .leading, spacing: Layout.spacing_10) {
                    compareScoreShiftMetric(
                        title: "Listener catch",
                        earlier: anchorReflection.listenerCatchScore,
                        latest: latestReflection.listenerCatchScore,
                        accent: KatieColors.gold
                    )

                    compareScoreShiftMetric(
                        title: "Pace control",
                        earlier: anchorReflection.paceControlScore,
                        latest: latestReflection.paceControlScore,
                        accent: KatieColors.mint
                    )

                    compareScoreShiftMetric(
                        title: "Confidence",
                        earlier: anchorReflection.confidenceScore,
                        latest: latestReflection.confidenceScore,
                        accent: KatieColors.blush
                    )
                }
            }
        } else {
            KatieInlineNotice(
                title: "Score shifts",
                message: appViewModel.reflectionDeltaSummary
            )
        }
    }

    private func compareScoreShiftMetric(title: String, earlier: Int, latest: Int, accent: Color) -> some View {
        let delta = latest - earlier

        return VStack(alignment: .leading, spacing: Layout.spacing_8) {
            HStack(alignment: .top, spacing: Layout.spacing_8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: 0)

                Text(compareScoreDeltaLabel(delta))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(delta >= 0 ? accent : KatieColors.textSecondary)
                    .padding(.horizontal, Layout.tightChipHorizontalPadding)
                    .padding(.vertical, Layout.tightChipVerticalPadding)
                    .background(KatieColors.cardBackground.opacity(0.9))
                    .clipShape(Capsule())
            }

            compareScoreTrack(label: "Before", score: earlier, fill: KatieColors.cardBackground.opacity(0.9))
            compareScoreTrack(label: "Now", score: latest, fill: accent)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func compareScoreTrack(label: String, score: Int, fill: Color) -> some View {
        HStack(alignment: .center, spacing: Layout.subSpacing) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
                .frame(width: 44, alignment: .leading)

            HStack(spacing: Layout.spacing_3) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < compareScoreClamped(score) ? fill : KatieColors.cardBackground.opacity(0.95))
                        .frame(maxWidth: .infinity, minHeight: 6, maxHeight: 6)
                }
            }
        }
    }

    private func compareScoreDeltaLabel(_ delta: Int) -> String {
        switch delta {
        case let value where value > 0:
            return "+\(value)"
        case let value where value < 0:
            return "\(value)"
        default:
            return "steady"
        }
    }

    private func compareScoreClamped(_ value: Int) -> Int {
        min(5, max(0, value))
    }

    private func compareLibraryActionsMenu(for entry: CompareLibraryEntry) -> some View {
        progressActionsMenu(
            for: entry.scenario,
            latest: entry.latest,
            anchor: entry.anchor,
            reminderTitle: compareReminderActionTitle(for: entry.scenario),
            reminderAction: { handleCompareReminderAction(for: entry.scenario) },
            label: "Peek"
        )
    }

    private func scenarioProofChips(for scenario: PracticeScenario, latest: PracticeSession, anchor: PracticeSession?, status: String, background: Color = KatieColors.cardBackground) -> some View {
        let replayReadyCount = (appViewModel.scenarioHistories[scenario] ?? []).filter { $0.isUserOwned && appViewModel.hasPlayback(for: $0) }.count

        return KatieWrap(spacing: 8, rowSpacing: 8) {
            proofStatusChip(status, background: background)
            proofStatusChip(appViewModel.compactCaptureSourceLabel(for: latest), background: background)
            proofStatusChip(appViewModel.displayCompareReadinessTitle(for: latest), background: background)
            proofStatusChip(appViewModel.freshnessLabel(for: latest), background: background)

            if anchor != nil {
                proofStatusChip("2-proof compare", background: background)
            }

            if replayReadyCount > 0 {
                proofStatusChip(replayReadyCount == 1 ? "1 replay-ready" : "\(replayReadyCount) replay-ready", background: background)
            }

            if appViewModel.reminderPlan?.scenario == scenario {
                proofStatusChip("Reminder on", background: KatieColors.accent, foreground: .black)
            }
        }
    }

    private func proofStatusChip(_ title: String, background: Color, foreground: Color = KatieColors.textSecondary) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, Layout.tightChipHorizontalPadding)
            .padding(.vertical, Layout.tightChipVerticalPadding)
            .background(background)
            .clipShape(Capsule())
    }

    private func progressActionsMenu(for scenario: PracticeScenario, latest: PracticeSession?, anchor: PracticeSession?, reminderTitle: String, reminderAction: @escaping () -> Void, label: String = "Peek") -> some View {
        Menu {
            Button(compareLibraryReviewActionTitle(anchor: anchor, latest: latest)) {
                appViewModel.openReview(for: scenario, anchor: anchor)
            }

            Button(appViewModel.comparePracticeActionTitle(for: latest)) {
                appViewModel.openPractice(for: scenario)
            }

            Button("Open progress") {
                appViewModel.openProgress(for: scenario)
            }

            Button(reminderTitle, action: reminderAction)

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
                .padding(.horizontal, Layout.mediumChipHorizontalPadding)
                .padding(.vertical, Layout.spacing_10)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
        }
    }

    private func compareLibraryReviewActionTitle(anchor: PracticeSession?, latest: PracticeSession?) -> String {
        guard let latest else {
            return anchor.map { appViewModel.hasPlayback(for: $0) } == true ? "Review replay-ready proof" : "Review transcript-only proof"
        }

        return appViewModel.compareLibraryActionTitle(anchor: anchor, latest: latest)
    }

    private func compareLibraryReplayStateLine(for entry: CompareLibraryEntry) -> String {
        appViewModel.compareLibraryReplayLine(for: entry)
    }

    private func followThroughReminderActionTitle(for scenario: PracticeScenario) -> String {
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

    private func followThroughReminderActionBackground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? KatieColors.accent
            : KatieColors.cardBackground.opacity(0.85)
    }

    private func followThroughReminderActionForeground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? .black
            : KatieColors.textPrimary
    }

    private func followThroughStatusColor(for latest: PracticeSession?) -> Color {
        guard let latest else {
            return KatieColors.textSecondary
        }

        switch latest.captureSource {
        case .recorded:
            return KatieColors.mint
        case .imported, .syntheticRetake:
            return KatieColors.accent
        case .seeded:
            return KatieColors.textSecondary
        }
    }

    private func compareRecoveryNotice(anchor: PracticeSession?, latest: PracticeSession) -> some View {
        let prompt = appViewModel.compareReplayRecoveryPrompt(anchor: anchor, latest: latest)

        return VStack(alignment: .leading, spacing: Layout.spacing_8) {
            Label(prompt?.title ?? "Replay needs a fresh clip", systemImage: "waveform.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(prompt?.message ?? "The compare trail survived, but one side still needs a fresh local clip.")
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            Button(prompt?.actionTitle ?? "Restore replay") {
                appViewModel.openPractice(for: latest.scenario)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Layout.smallChipHorizontalPadding)
            .padding(.vertical, Layout.mediumChipVerticalPadding)
            .background(KatieColors.accent)
            .foregroundStyle(.black)
            .clipShape(Capsule())
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func handleFollowThroughReminderAction(for scenario: PracticeScenario) {
        appViewModel.selectScenario(scenario)

        if appViewModel.reminderPermissionState == .denied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
            return
        }

        appViewModel.scheduleOrDismissReminder()
    }

    private func scenarioStatus(for scenario: PracticeScenario, count: Int) -> String {
        if scenario == appViewModel.currentMission { return "Active" }
        switch count {
        case 0: return "New"
        case 1: return "Benchmark"
        case 2: return "Warming up"
        default: return "Steady"
        }
    }

    private func primaryScenarioActionTitle(for scenario: PracticeScenario, latest: PracticeSession?) -> String {
        let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)

        if ownedCount == 0 {
            return "Record first proof"
        }

        if ownedCount == 1 {
            return "Save compare"
        }

        if appViewModel.reminderPlan?.scenario != scenario {
            return "Add nudge"
        }

        if let latest, appViewModel.hasPlayback(for: latest) {
            return appViewModel.currentlyPlayingSessionID == latest.id ? "Stop replay" : "Replay latest"
        }

        return "Keep pack warm"
    }

    private func primaryScenarioActionBackground(for scenario: PracticeScenario) -> Color {
        let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)

        if ownedCount >= 2 && appViewModel.reminderPlan?.scenario != scenario {
            return KatieColors.cardBackground.opacity(0.85)
        }

        return scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.cardSecondary
    }

    private func primaryScenarioActionForeground(for scenario: PracticeScenario) -> Color {
        let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)

        if ownedCount >= 2 && appViewModel.reminderPlan?.scenario != scenario {
            return KatieColors.textPrimary
        }

        return scenario == appViewModel.currentMission ? .black : KatieColors.textPrimary
    }

    private func handlePrimaryScenarioAction(for scenario: PracticeScenario, latest: PracticeSession?) {
        let ownedCount = appViewModel.userOwnedSessionCount(in: scenario)

        if ownedCount <= 1 {
            appViewModel.openPractice(for: scenario)
            return
        }

        if appViewModel.reminderPlan?.scenario != scenario {
            handleFollowThroughReminderAction(for: scenario)
            return
        }

        guard let latest else {
            appViewModel.openPractice(for: scenario)
            return
        }

        appViewModel.selectScenario(scenario)

        if appViewModel.hasPlayback(for: latest) {
            if appViewModel.currentlyPlayingSessionID == latest.id {
                appViewModel.stopPlayback()
            } else {
                appViewModel.playSession(latest)
            }
            return
        }

        appViewModel.openPractice(for: scenario)
    }

    private func compareReminderActionTitle(for scenario: PracticeScenario) -> String {
        if appViewModel.reminderPermissionState == .denied {
            return appViewModel.reminderPlan?.scenario == scenario ? "Fix reminders" : "Enable nudge"
        }

        if appViewModel.reminderPlan?.scenario == scenario {
            return "Pause nudge"
        }

        if appViewModel.reminderPlan != nil {
            return "Move nudge here"
        }

        return "Protect this win"
    }

    private func compareReminderActionBackground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? KatieColors.accent
            : KatieColors.cardBackground.opacity(0.85)
    }

    private func compareReminderActionForeground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? .black
            : KatieColors.textPrimary
    }

    private func handleCompareReminderAction(for scenario: PracticeScenario) {
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
    ProgressView()
        .environmentObject(AppViewModel())
}
