import SwiftUI

struct ReviewRetakeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    @State private var isDeeperReviewExpanded = false

    // MARK: - Layout

    private var usesWideReviewLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var reviewBoardMetrics: [KatieGlanceMetric] {
        [
            KatieGlanceMetric(
                title: "Pack",
                value: appViewModel.currentMission.packTitle,
                detail: appViewModel.latestSession.listenerOutcome,
                accent: KatieColors.mint
            ),
            KatieGlanceMetric(
                title: "Readback",
                value: appViewModel.selectedCompareAnchor == nil ? "Single proof" : "Before + now",
                detail: appViewModel.selectedCompareAnchor == nil ? "One saved rep stays in focus." : "An earlier proof is pinned beside the latest retake.",
                accent: KatieColors.gold
            ),
            KatieGlanceMetric(
                title: "Replay truth",
                value: appViewModel.compactReplayLabel(for: appViewModel.latestSession),
                detail: appViewModel.selectedCompareAnchor == nil ? "Katie stays explicit about whether this iPhone can replay the latest proof." : "Compare stays honest about whether replay exists on one side or both.",
                accent: KatieColors.accent
            )
        ]
    }

    // MARK: - Subviews (board, rails, hero, deeper tools)

    private var reviewBoardCard: some View {
        KatieGlanceBoard(
            eyebrow: "Retake board",
            title: "One benchmark, one latest rep, one calmer next move",
            detail: "This keeps Review readable on iPhone, roomy on iPad, and honest about compare state before the deeper evidence stack opens.",
            systemImage: "arrow.triangle.2.circlepath.circle.fill",
            accent: KatieColors.mint,
            secondary: KatieColors.accent,
            metrics: reviewBoardMetrics,
            footnote: "Next grounded move · \(appViewModel.currentPackNextStepLabel)"
        )
        .katieHeroAura(accent: KatieColors.mint, secondary: KatieColors.accent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .katieIconBadge(background: KatieColors.cardSecondary, foreground: KatieColors.mint, size: 34)
                    Text("Review")
                        .font(.title.bold())
                        .foregroundStyle(KatieColors.textPrimary)
                    Spacer()
                }

                reviewBoardCard

                reviewHero
                if usesWideReviewLayout {
                    reviewSupportRail
                } else {
                    reviewStateBanner
                    nextRetakeCueCard
                }
                reviewContinuityRail
                startingHypothesisSummaryCard
                reviewCompareSpotlightRail
                compareCard
                deeperReviewToolsCard
                if isDeeperReviewExpanded {
                    reflectionCard
                    if let anchor = appViewModel.selectedCompareAnchor {
                        compareStepLadderCard(anchor: anchor, latest: appViewModel.latestSession)
                        transcriptShiftCard(anchor: anchor, latest: appViewModel.latestSession)
                    }
                    transferCard
                    if appViewModel.currentMission == .managerOneOnOne {
                        oneOnOneTruthCard
                    }
                }
                retakeMissionCard
            }
            .padding(16)
            .katieContentFrame(maxWidth: 820)
        }
        .background(LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing).overlay { RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420) }.ignoresSafeArea())
    }

    @ViewBuilder
    private var reviewSupportRail: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                reviewStateBanner
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                nextRetakeCueCard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: 16) {
                reviewStateBanner
                nextRetakeCueCard
            }
        }
    }

    @ViewBuilder
    private var reviewContinuityRail: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                carryForwardCard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                reminderContinuityCard
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: 16) {
                carryForwardCard
                reminderContinuityCard
            }
        }
    }

    private var reviewHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                KatieSectionEyebrow(title: appViewModel.currentMission.packTitle, systemImage: "sparkles.rectangle.stack.fill", accent: KatieColors.mint)
                Spacer()
                HStack(spacing: 8) {
                    Text(appViewModel.freshnessLabel(for: appViewModel.latestSession))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(KatieColors.cardSecondary)
                        .clipShape(Capsule())
                    Text("Latest rep")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }

            Text(appViewModel.improvementHeadline)
                .font(.title2.bold())
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.latestSession.listenerOutcome)
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            reviewHeroRunwayRows

            KatieReplayBadge(title: "Proof replay \(appViewModel.compactReplayLabel(for: appViewModel.latestSession))", systemImage: appViewModel.displayCompareReadinessSystemImage(for: appViewModel.latestSession), accent: KatieColors.gold)
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.mint, secondary: KatieColors.accent)
    }

    private var reviewHeroRunwayRows: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                reviewCueRow(
                    title: appViewModel.transferHypothesisStatusTitle,
                    body: appViewModel.transferHypothesisFollowThroughLine,
                    accent: KatieColors.mint
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)

                reviewCueRow(
                    title: "Next grounded move",
                    body: appViewModel.currentPackNextStepLabel,
                    accent: KatieColors.accent
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: 10) {
                reviewCueRow(
                    title: appViewModel.transferHypothesisStatusTitle,
                    body: appViewModel.transferHypothesisFollowThroughLine,
                    accent: KatieColors.mint
                )

                reviewCueRow(
                    title: "Next grounded move",
                    body: appViewModel.currentPackNextStepLabel,
                    accent: KatieColors.accent
                )
            }
        }
    }

    private var reviewStateBanner: some View {
        let latest = appViewModel.latestSession
        let anchor = appViewModel.selectedCompareAnchor
        let needsReplayRecovery = reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: reviewStateSystemImage(anchor: anchor, latest: latest))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(needsReplayRecovery ? KatieColors.textPrimary : Color.black)
                    .frame(width: 36, height: 36)
                    .background(needsReplayRecovery ? KatieColors.cardBackground.opacity(0.88) : KatieColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(reviewStateTitle(anchor: anchor))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(reviewStateSummary(anchor: anchor, latest: latest))
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            if needsReplayRecovery {
                Button(reviewStateActionTitle(anchor: anchor, latest: latest)) {
                    appViewModel.openPractice(for: latest.scenario)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.accent)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(needsReplayRecovery ? KatieColors.cardSecondary : KatieColors.accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var nextRetakeCueCard: some View {
        let scan = appViewModel.firstSpeakingScan

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Next retake cue", systemImage: "arrow.clockwise.circle.fill")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Keep Review centered on one benchmark, one latest rep, and one calmer next move.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(appViewModel.currentPackNextStepLabel)
                    .modifier(KatieCapsuleLabelStyle())
            }

            reviewCueRow(title: "Hold onto", body: scan.strongestMove, accent: KatieColors.mint)
            reviewCueRow(title: "Tighten next", body: scan.listenerRisk, accent: KatieColors.gold)
            reviewCueRow(title: "Retake move", body: scan.firstWinPlan, accent: KatieColors.accent)

            Button("Practice this retake") {
                appViewModel.openPractice(for: appViewModel.currentMission)
            }
            .buttonStyle(.katiePrimary())
        }
        .katieCard()
    }

    private var deeperReviewToolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Deeper review tools", systemImage: "text.magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Step stability, transcript shifts, listener scores, and transfer coaching stay tucked away until you want the fuller readback.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Button(isDeeperReviewExpanded ? "Hide" : "Open") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        isDeeperReviewExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Text("Listener scores")
                    .modifier(KatieCapsuleLabelStyle())
                if appViewModel.selectedCompareAnchor != nil {
                    Text("Step stability")
                        .modifier(KatieCapsuleLabelStyle())
                }
                Text("Transcript shift")
                    .modifier(KatieCapsuleLabelStyle())
                Text(appViewModel.currentMission == .managerOneOnOne ? "1:1 guardrails" : "Transfer plan")
                    .modifier(KatieCapsuleLabelStyle())
            }
        }
        .katieCard()
    }

    @ViewBuilder
    private var reviewCompareSpotlightRail: some View {
        if let anchor = appViewModel.selectedCompareAnchor, usesWideReviewCompareLayout {
            let latest = appViewModel.latestSession

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    compareScoreRibbon(anchor: anchor, latest: latest)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    compareStoryStrip(anchor: anchor, latest: latest)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                VStack(alignment: .leading, spacing: 16) {
                    compareScoreRibbon(anchor: anchor, latest: latest)
                    compareStoryStrip(anchor: anchor, latest: latest)
                }
            }
        }
    }

    private var compareCard: some View {
        let latest = appViewModel.latestSession
        let anchor = appViewModel.selectedCompareAnchor

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(anchor != nil && usesWideReviewCompareLayout ? "Compare details" : "Benchmark vs retake")
                    .font(.headline)
                    .foregroundStyle(KatieColors.textPrimary)
                Spacer()
                Text(anchor != nil && usesWideReviewCompareLayout ? "Keep the deeper proof tools in one place" : "Keep the comparison narrow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
            }

            if let anchor, !usesWideReviewCompareLayout {
                compareScoreRibbon(anchor: anchor, latest: latest)
                compareStoryStrip(anchor: anchor, latest: latest)
            }

            compareOverviewRail(anchor: anchor, latest: latest)

            if let anchor {
                if appViewModel.compareCandidates.count > 1 {
                    compareAnchorPicker
                }

                compareColumns(anchor: anchor, latest: latest)
                compareSupportRail(anchor: anchor, latest: latest)

                compareFollowThroughChips(for: appViewModel.currentMission)
            } else {
                Label(appViewModel.displayCompareReadinessDetail(for: latest), systemImage: appViewModel.displayCompareReadinessSystemImage(for: latest))
                    .font(.subheadline)
                    .foregroundStyle(KatieColors.textSecondary)

                compareTruthNotice(anchor: nil, latest: latest)

                compareFollowThroughChips(for: appViewModel.currentMission)
            }
        }
        .katieCard()
    }

    private func compareStoryStrip(anchor: PracticeSession, latest: PracticeSession) -> some View {
        let reflectionSummary = appViewModel.reflectionDeltaSummary
        let stepSummary = stepLadderSummary(anchor: anchor, latest: latest)

        return VStack(alignment: .leading, spacing: 12) {
            Label("Before vs now", systemImage: "sparkles.rectangle.stack")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.gold)

            Text(appViewModel.comparisonSummary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    compareStoryBadge(title: "Score shift", body: reflectionSummary, accent: KatieColors.mint)
                    compareStoryBadge(title: "Structure shift", body: stepSummary, accent: KatieColors.accent)
                }

                VStack(alignment: .leading, spacing: 10) {
                    compareStoryBadge(title: "Score shift", body: reflectionSummary, accent: KatieColors.mint)
                    compareStoryBadge(title: "Structure shift", body: stepSummary, accent: KatieColors.accent)
                }
            }
        }
        .padding(12)
        .background(KatieColors.cardSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareStoryBadge(title: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)

            Text(body)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func compareScoreRibbon(anchor: PracticeSession, latest: PracticeSession) -> some View {
        let anchorReflection = anchor.selfReflection ?? SessionSelfReflection()
        let latestReflection = latest.selfReflection ?? SessionSelfReflection()

        return VStack(alignment: .leading, spacing: 12) {
            Label("Before vs now", systemImage: "chart.bar.xaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text("Three listener signals stay visible at a glance, so the compare reads like progress instead of a wall of notes.")
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            ViewThatFits(in: .vertical) {
                HStack(alignment: .top, spacing: 10) {
                    compareScoreMetric(title: "Listener", earlier: anchorReflection.listenerCatchScore, latest: latestReflection.listenerCatchScore, accent: KatieColors.mint)
                    compareScoreMetric(title: "Pace", earlier: anchorReflection.paceControlScore, latest: latestReflection.paceControlScore, accent: KatieColors.accent)
                    compareScoreMetric(title: "Confidence", earlier: anchorReflection.confidenceScore, latest: latestReflection.confidenceScore, accent: KatieColors.gold)
                }

                VStack(alignment: .leading, spacing: 10) {
                    compareScoreMetric(title: "Listener", earlier: anchorReflection.listenerCatchScore, latest: latestReflection.listenerCatchScore, accent: KatieColors.mint)
                    compareScoreMetric(title: "Pace", earlier: anchorReflection.paceControlScore, latest: latestReflection.paceControlScore, accent: KatieColors.accent)
                    compareScoreMetric(title: "Confidence", earlier: anchorReflection.confidenceScore, latest: latestReflection.confidenceScore, accent: KatieColors.gold)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareScoreMetric(title: String, earlier: Int, latest: Int, accent: Color) -> some View {
        let delta = latest - earlier

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: 0)

                Text(compareScoreDeltaLabel(delta))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(delta >= 0 ? accent : KatieColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
            }

            compareScoreTrack(label: "Earlier", score: earlier, fill: KatieColors.cardSecondary)
            compareScoreTrack(label: "Now", score: latest, fill: accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareScoreTrack(label: String, score: Int, fill: Color) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
                .frame(width: 44, alignment: .leading)

            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < compareScoreClamped(score) ? fill : KatieColors.cardBackground.opacity(0.9))
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

    private var usesWideReviewCompareLayout: Bool {
        horizontalSizeClass == .regular
    }

    private func compareColumns(anchor: PracticeSession, latest: PracticeSession) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .top, spacing: 12) {
                compareColumn(
                    title: appViewModel.proofLabel(for: anchor, placement: .baseline),
                    session: anchor,
                    accent: KatieColors.cardSecondary
                )

                compareColumn(
                    title: appViewModel.proofLabel(for: latest, placement: .latest),
                    session: latest,
                    accent: KatieColors.accent.opacity(0.16)
                )
            }

            VStack(spacing: 12) {
                compareColumn(
                    title: appViewModel.proofLabel(for: anchor, placement: .baseline),
                    session: anchor,
                    accent: KatieColors.cardSecondary
                )

                compareColumn(
                    title: appViewModel.proofLabel(for: latest, placement: .latest),
                    session: latest,
                    accent: KatieColors.accent.opacity(0.16)
                )
            }
        }
    }

    @ViewBuilder
    private func compareSupportRail(anchor: PracticeSession, latest: PracticeSession) -> some View {
        if usesWideReviewCompareLayout {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    compareTimeline(anchor: anchor, latest: latest)
                    compareDeltaCard(anchor: anchor, latest: latest)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 12) {
                    compareReplayStrip(anchor: anchor, latest: latest)
                    compareTruthNotice(anchor: anchor, latest: latest)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            compareTimeline(anchor: anchor, latest: latest)
            compareDeltaCard(anchor: anchor, latest: latest)
            compareReplayStrip(anchor: anchor, latest: latest)
            compareTruthNotice(anchor: anchor, latest: latest)
        }
    }

    @ViewBuilder
    private func compareOverviewRail(anchor: PracticeSession?, latest: PracticeSession) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .top, spacing: 10) {
                compareOverviewFactCard(
                    title: anchor == nil ? "Proof mode" : "Compare mode",
                    detail: compareModeOverviewDetail(anchor: anchor, latest: latest),
                    systemImage: anchor == nil ? appViewModel.displayCompareReadinessSystemImage(for: latest) : "rectangle.split.2x1.fill",
                    accent: KatieColors.cardSecondary
                )

                compareOverviewFactCard(
                    title: "Replay on this iPhone",
                    detail: compareReplayOverviewDetail(anchor: anchor, latest: latest),
                    systemImage: reviewStateSystemImage(anchor: anchor, latest: latest),
                    accent: KatieColors.cardBackground.opacity(0.78)
                )

                compareOverviewActionCard(anchor: anchor, latest: latest)
            }

            VStack(alignment: .leading, spacing: 10) {
                compareOverviewFactCard(
                    title: anchor == nil ? "Proof mode" : "Compare mode",
                    detail: compareModeOverviewDetail(anchor: anchor, latest: latest),
                    systemImage: anchor == nil ? appViewModel.displayCompareReadinessSystemImage(for: latest) : "rectangle.split.2x1.fill",
                    accent: KatieColors.cardSecondary
                )

                compareOverviewFactCard(
                    title: "Replay on this iPhone",
                    detail: compareReplayOverviewDetail(anchor: anchor, latest: latest),
                    systemImage: reviewStateSystemImage(anchor: anchor, latest: latest),
                    accent: KatieColors.cardBackground.opacity(0.78)
                )

                compareOverviewActionCard(anchor: anchor, latest: latest)
            }
        }
    }

    private func compareOverviewFactCard(title: String, detail: String, systemImage: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareOverviewActionCard(anchor: PracticeSession?, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Next move", systemImage: "arrow.forward.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(compareActionOverviewDetail(anchor: anchor, latest: latest))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(compareActionOverviewTitle(anchor: anchor, latest: latest)) {
                appViewModel.openPractice(for: latest.scenario)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(compareActionOverviewBackground(anchor: anchor, latest: latest))
            .foregroundStyle(compareActionOverviewForeground(anchor: anchor, latest: latest))
            .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var reflectionCard: some View {
        let reflection = appViewModel.latestSelfReflection

        return VStack(alignment: .leading, spacing: 14) {
            Text("Listener readback")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.reflectionDeltaSummary)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: 10) {
                reflectionMetric(title: "Listener", value: reflection.listenerCatchScore)
                reflectionMetric(title: "Pace", value: reflection.paceControlScore)
                reflectionMetric(title: "Confidence", value: reflection.confidenceScore)
            }

            Label("Stickiest moment this pass: \(reflection.stickyMoment)", systemImage: "pin.fill")
                .font(.footnote)
                .foregroundStyle(KatieColors.mint)
        }
        .katieCard()
    }

    private var transferCard: some View {
        let plan = appViewModel.currentConversationTransferPlan

        return VStack(alignment: .leading, spacing: 14) {
            Text(plan.title)
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(plan.summary)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                Label(plan.beforeYouSpeak, systemImage: "1.circle.fill")
                Label(plan.whileSpeaking, systemImage: "2.circle.fill")
                Label(plan.repairMove, systemImage: "3.circle.fill")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var oneOnOneTruthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("1:1 compare guardrails")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("A better retake should sound more answerable, not more dramatic. Katie keeps the compare honest by protecting the observed pattern and one concrete ask.")
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Before: did the friction land as an observed pattern instead of a vague stress summary?", systemImage: "1.circle.fill")
                Label("After: is the support ask smaller and easier for a manager to answer live?", systemImage: "2.circle.fill")
                Label("Boundary: transfer patterns stay a coaching hypothesis, not a diagnosis", systemImage: "3.circle.fill")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private func reflectionMetric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
            Text("\(value)/5")
                .font(.title3.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reviewCueRow(title: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareDeltaCard(anchor: PracticeSession, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What changed", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    compareDeltaPill(title: "Structure", value: structureDeltaLabel(anchor: anchor, latest: latest), systemImage: "flag.fill")
                    compareDeltaPill(title: "Length", value: transcriptDeltaLabel(anchor: anchor, latest: latest), systemImage: "text.word.spacing")
                    compareDeltaPill(title: "Pace", value: paceDeltaLabel(anchor: anchor, latest: latest), systemImage: "speedometer")
                    compareDeltaPill(title: "Replay", value: replayDeltaLabel(anchor: anchor, latest: latest), systemImage: "waveform")
                }

                VStack(alignment: .leading, spacing: 8) {
                    compareDeltaPill(title: "Structure", value: structureDeltaLabel(anchor: anchor, latest: latest), systemImage: "flag.fill")
                    compareDeltaPill(title: "Length", value: transcriptDeltaLabel(anchor: anchor, latest: latest), systemImage: "text.word.spacing")
                    compareDeltaPill(title: "Pace", value: paceDeltaLabel(anchor: anchor, latest: latest), systemImage: "speedometer")
                    compareDeltaPill(title: "Replay", value: replayDeltaLabel(anchor: anchor, latest: latest), systemImage: "waveform")
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reviewStateTitle(anchor: PracticeSession?) -> String {
        anchor == nil ? "Single proof" : "Live compare"
    }

    private func reviewStateSystemImage(anchor: PracticeSession?, latest: PracticeSession) -> String {
        if reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest) {
            return "waveform.badge.exclamationmark"
        }

        return anchor == nil ? appViewModel.displayCompareReadinessSystemImage(for: latest) : "rectangle.split.2x1.fill"
    }

    private func reviewStateSummary(anchor: PracticeSession?, latest: PracticeSession) -> String {
        guard let anchor else {
            if appViewModel.hasPlayback(for: latest) {
                return "Replay is attached on this iPhone, so this proof is ready to revisit before the next rep and stay anchored to the same local clip."
            }

            return latest.audioFileName != nil
                ? "Replay is missing on this iPhone, so this proof stays transcript-first until you record a fresh local clip and reattach listening continuity."
                : "This review stays transcript-first for now. Record on this iPhone when you want replay-ready proof."
        }

        let anchorHasPlayback = appViewModel.hasPlayback(for: anchor)
        let latestHasPlayback = appViewModel.hasPlayback(for: latest)

        switch (anchorHasPlayback, latestHasPlayback) {
        case (true, true):
            return "Both sides can replay on this iPhone, so the before/after shift is ready to hear without leaving Review or losing the trail."
        case (true, false):
            return "The earlier proof can replay here, but the latest retake needs a fresh local clip on this iPhone. Katie keeps the compare trail honest until you save another calm pass."
        case (false, true):
            return "The latest retake can replay here, but the earlier proof is transcript-only on this iPhone. Katie keeps the compare trail honest until you record a fresh retake and restore full compare replay."
        case (false, false):
            return "Neither side can replay on this iPhone right now, so this compare stays transcript-visible until you record a fresh local clip and restore continuity."
        }
    }

    private func reviewStateNeedsReplayRecovery(anchor: PracticeSession?, latest: PracticeSession) -> Bool {
        guard let anchor else {
            return !appViewModel.hasPlayback(for: latest)
        }

        return !appViewModel.hasPlayback(for: anchor) || !appViewModel.hasPlayback(for: latest)
    }

    private func reviewStateActionTitle(anchor: PracticeSession?, latest: PracticeSession) -> String {
        if latest.captureSource == .seeded {
            return "Record your own proof"
        }

        guard let anchor else {
            return "Restore replay"
        }

        let anchorHasPlayback = appViewModel.hasPlayback(for: anchor)
        let latestHasPlayback = appViewModel.hasPlayback(for: latest)

        switch (anchorHasPlayback, latestHasPlayback) {
        case (true, false), (false, true):
            return "Record to restore full compare"
        case (false, false):
            return "Restore compare replay"
        case (true, true):
            return "Record a calmer retake"
        }
    }

    private func compareTruthNotice(anchor: PracticeSession?, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            Text(appViewModel.compareTruthLine(anchor: anchor, latest: latest))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareStepLadderCard(anchor: PracticeSession, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Step-by-step progress", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(stepLadderSummary(anchor: anchor, latest: latest))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(appViewModel.currentMission.stepLabels.enumerated()), id: \.offset) { index, label in
                    compareStepRow(
                        title: label,
                        index: index,
                        anchorUnlockedCount: anchor.unlockedStepCount,
                        latestUnlockedCount: latest.unlockedStepCount
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareStepRow(title: String, index: Int, anchorUnlockedCount: Int, latestUnlockedCount: Int) -> some View {
        let anchorHasStep = index < anchorUnlockedCount
        let latestHasStep = index < latestUnlockedCount
        let isNewlyUnlocked = !anchorHasStep && latestHasStep

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isNewlyUnlocked ? KatieColors.accent : (latestHasStep ? KatieColors.mint.opacity(0.22) : KatieColors.cardSecondary))
                    .frame(width: 28, height: 28)

                Image(systemName: latestHasStep ? (isNewlyUnlocked ? "sparkles" : "checkmark") : "circle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isNewlyUnlocked ? Color.black : (latestHasStep ? KatieColors.mint : KatieColors.textSecondary))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    if isNewlyUnlocked {
                        Text("New")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(KatieColors.accent)
                            .clipShape(Capsule())
                    }
                }

                Text(compareStepStatusLabel(anchorHasStep: anchorHasStep, latestHasStep: latestHasStep))
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isNewlyUnlocked ? KatieColors.accent.opacity(0.12) : KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareStepStatusLabel(anchorHasStep: Bool, latestHasStep: Bool) -> String {
        switch (anchorHasStep, latestHasStep) {
        case (true, true):
            return "Held across both proofs"
        case (false, true):
            return "Unlocked in the latest retake"
        case (true, false):
            return "Was visible earlier, but needs another calm pass"
        case (false, false):
            return "Still waiting to land clearly"
        }
    }

    private func stepLadderSummary(anchor: PracticeSession, latest: PracticeSession) -> String {
        let gained = max(0, latest.unlockedStepCount - anchor.unlockedStepCount)

        if gained > 0 {
            return gained == 1
                ? "The latest retake unlocked one more scenario beat, so Katie can show exactly where the pack moved forward."
                : "The latest retake unlocked \(gained) more scenario beats, so the progress ladder shows where the pack genuinely advanced."
        }

        if latest.unlockedStepCount == anchor.unlockedStepCount {
            return "Both proofs reached the same step depth, so this ladder helps you judge stability instead of pretending there was a bigger structural jump."
        }

        return "The latest retake exposed fewer visible steps than the earlier proof, which is a cue to protect the calmer line and rebuild the dropped beat on the next pass."
    }

    private func transcriptShiftCard(anchor: PracticeSession, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Transcript shift", systemImage: "text.redaction")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(transcriptShiftSummary(anchor: anchor, latest: latest))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            ViewThatFits(in: .vertical) {
                HStack(alignment: .top, spacing: 10) {
                    transcriptShiftColumn(title: "Earlier phrasing", session: anchor, accent: KatieColors.cardSecondary)
                    transcriptShiftColumn(title: "Latest phrasing", session: latest, accent: KatieColors.accent.opacity(0.16))
                }

                VStack(alignment: .leading, spacing: 10) {
                    transcriptShiftColumn(title: "Earlier phrasing", session: anchor, accent: KatieColors.cardSecondary)
                    transcriptShiftColumn(title: "Latest phrasing", session: latest, accent: KatieColors.accent.opacity(0.16))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func transcriptShiftColumn(title: String, session: PracticeSession, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text(transcriptExcerpt(for: session))
                .font(.subheadline)
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(6)

            Label(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compareFollowThroughChips(for scenario: PracticeScenario) -> some View {
        KatieWrap(spacing: 8, rowSpacing: 8) {
            Button(reviewReminderActionTitle) {
                handleReviewReminderAction()
            }
            .modifier(ReviewActionChipStyle(background: reviewReminderActionBackground, foreground: reviewReminderActionForeground))

            Button(appViewModel.comparePracticeActionTitle(for: appViewModel.latestSession)) {
                appViewModel.openPractice(for: scenario)
            }
            .modifier(ReviewActionChipStyle(background: scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.cardSecondary, foreground: scenario == appViewModel.currentMission ? .black : KatieColors.textPrimary))

            Button("Open progress") {
                appViewModel.openProgress(for: scenario)
            }
            .modifier(ReviewActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary))
        }
    }

    private var compareAnchorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose earlier proof")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            if usesWideReviewCompareLayout {
                LazyVGrid(columns: compareAnchorGridColumns, alignment: .leading, spacing: 12) {
                    ForEach(appViewModel.compareCandidates) { session in
                        compareAnchorPickerCard(session: session)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(appViewModel.compareCandidates) { session in
                            compareAnchorPickerCard(session: session, compactWidth: 180)
                        }
                    }
                }
            }
        }
    }

    private var compareAnchorGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }

    private func compareAnchorPickerCard(session: PracticeSession, compactWidth: CGFloat? = nil) -> some View {
        Button {
            appViewModel.selectCompareAnchor(session)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Text(session.scenario.packTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if appViewModel.isSelectedAnchor(session) {
                        Label("Anchor", systemImage: "pin.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.accent)
                    }
                }

                Text(session.protectedLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(3)

                HStack(alignment: .top, spacing: 8) {
                    Text(appViewModel.freshnessLabel(for: session))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(KatieColors.cardBackground.opacity(0.8))
                        .clipShape(Capsule())

                    Text(appViewModel.displayCompareReadinessDetail(for: session))
                        .font(.caption2)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(width: compactWidth, alignment: .leading)
            .background(appViewModel.isSelectedAnchor(session) ? KatieColors.accent.opacity(0.18) : KatieColors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(appViewModel.isSelectedAnchor(session) ? KatieColors.accent : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compareColumn(title: String, session: PracticeSession, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                KatieScenarioArtwork(
                    systemImage: title.localizedCaseInsensitiveContains("latest") || title.localizedCaseInsensitiveContains("after") ? "sparkles" : "circle.lefthalf.filled",
                    accent: title.localizedCaseInsensitiveContains("latest") || title.localizedCaseInsensitiveContains("after") ? KatieColors.mint : KatieColors.gold,
                    secondary: KatieColors.accent
                )

                VStack(alignment: .leading, spacing: 10) {
                    KatieSectionEyebrow(
                        title: title,
                        systemImage: title.localizedCaseInsensitiveContains("latest") || title.localizedCaseInsensitiveContains("after") ? "sparkles" : "pin.fill",
                        accent: title.localizedCaseInsensitiveContains("latest") || title.localizedCaseInsensitiveContains("after") ? KatieColors.mint : KatieColors.gold
                    )

                    Text(session.protectedLine)
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(3)

                    Text(session.benchmarkCue)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(3)
                }
            }

            HStack(spacing: 8) {
                KatieReplayBadge(
                    title: appViewModel.displayCompareReadinessTitle(for: session),
                    systemImage: appViewModel.displayCompareReadinessSystemImage(for: session),
                    accent: KatieColors.mint
                )
                Text(appViewModel.freshnessLabel(for: session))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(KatieColors.cardBackground.opacity(0.8))
                    .clipShape(Capsule())
            }
            proofFactChips(for: session)

            proofTruthStrip(for: session)

            if appViewModel.hasPlayback(for: session) {
                Button(appViewModel.currentlyPlayingSessionID == session.id ? "Stop playback" : "Play recording") {
                    if appViewModel.currentlyPlayingSessionID == session.id {
                        appViewModel.stopPlayback()
                    } else {
                        appViewModel.playSession(session)
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.cardBackground.opacity(0.8))
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent, KatieColors.cardBackground.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach signal")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            ForEach(appViewModel.latestSession.highlights) { highlight in
                VStack(alignment: .leading, spacing: 6) {
                    Text(highlight.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(highlight.detail)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .katieCard()
    }

    private var retakeMemoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Retake memory", systemImage: "memorychip.fill")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Katie remembers the last few versions in this pack so a retake feels like a continuation, not a reset.")
                .foregroundStyle(KatieColors.textSecondary)

            ForEach(Array(appViewModel.retakeMemorySessions.prefix(3).enumerated()), id: \.element.id) { index, session in
                let isSelectableAnchor = session.id != appViewModel.latestSession.id && appViewModel.compareCandidates.contains(where: { $0.id == session.id })
                Button {
                    if isSelectableAnchor {
                        appViewModel.selectCompareAnchor(session)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(index == 0 ? "Now" : index == 1 ? "1-step before" : "2-step before")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(index == 0 ? KatieColors.mint : KatieColors.textSecondary)
                            .frame(width: 92, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                Text(session.scenario.packTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)
                                Spacer(minLength: 8)
                                if appViewModel.isSelectedAnchor(session) {
                                    Label("Anchor", systemImage: "pin.fill")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(KatieColors.accent)
                                } else if isSelectableAnchor {
                                    Text("Use as anchor")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(KatieColors.textSecondary)
                                }
                            }
                            Text(session.protectedLine)
                                .font(.subheadline)
                                .foregroundStyle(KatieColors.textSecondary)
                                .lineLimit(2)
                            HStack(spacing: 8) {
                                Text(appViewModel.freshnessLabel(for: session))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(KatieColors.cardBackground.opacity(0.8))
                                    .clipShape(Capsule())
                                Text(appViewModel.displayCompareReadinessDetail(for: session))
                                    .font(.caption)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(appViewModel.isSelectedAnchor(session) ? KatieColors.accent.opacity(0.16) : index == 0 ? KatieColors.accent.opacity(0.12) : KatieColors.cardSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(appViewModel.isSelectedAnchor(session) ? KatieColors.accent : Color.clear, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isSelectableAnchor)
            }
        }
        .katieCard()
    }

    private var carryForwardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Protected line handoff", systemImage: "quote.opening")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(appViewModel.currentMission.packTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text("The runway above already carries continuity and the next move, so this rail stays focused on the exact line and reminder Review is protecting.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(appViewModel.currentMission.title)
                    .modifier(KatieCapsuleLabelStyle())
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    reviewCueRow(
                        title: "Protected line",
                        body: "“\(appViewModel.latestSession.protectedLine)”",
                        accent: KatieColors.mint
                    )
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    reviewCueRow(
                        title: "Reminder handoff",
                        body: appViewModel.reminderCallToActionLine,
                        accent: KatieColors.gold
                    )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                VStack(alignment: .leading, spacing: 10) {
                    reviewCueRow(
                        title: "Protected line",
                        body: "“\(appViewModel.latestSession.protectedLine)”",
                        accent: KatieColors.mint
                    )

                    reviewCueRow(
                        title: "Reminder handoff",
                        body: appViewModel.reminderCallToActionLine,
                        accent: KatieColors.gold
                    )
                }
            }
        }
        .katieCard()
    }

    private var startingHypothesisSummaryCard: some View {
        let snapshot = appViewModel.languageAssessmentSnapshot

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Sound focus first: \(snapshot.soundFocus)", systemImage: "dot.radiowaves.left.and.right")
                Label("Language watch-out: \(snapshot.transferPattern)", systemImage: "arrow.triangle.branch")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
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
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .katieCard()
    }

    private var reminderContinuityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminder continuity")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Label(reviewReminderOwnerLabel, systemImage: reviewReminderOwnerSystemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(reviewReminderOwnerAccent)

                    Text(reviewReminderOwnerDetail)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(reviewReminderOwnerAccent)

                    Text(appViewModel.reminderPreviewCopy)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: reviewReminderOwnerSystemImage)
                    .font(.title3)
                    .foregroundStyle(reviewReminderOwnerAccent)
            }

            Label(appViewModel.reminderPermissionState.title, systemImage: appViewModel.reminderPermissionState.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.reminderSummaryLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            if appViewModel.reminderPermissionState == .denied {
                Button("Open iPhone notification settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            } else {
                KatieWrap(spacing: 8, rowSpacing: 8) {
                    ForEach(ReminderTone.allCases) { tone in
                        Button(tone.title) {
                            appViewModel.setReminderTone(tone)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(appViewModel.reminderTone == tone ? KatieColors.accent : KatieColors.cardSecondary)
                        .foregroundStyle(appViewModel.reminderTone == tone ? .black : KatieColors.textPrimary)
                        .clipShape(Capsule())
                    }
                }

                Text(appViewModel.reminderToneLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Text(appViewModel.reminderClinicalBoundaryLine)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)

                if appViewModel.remindersEnabled {
                    VStack(alignment: .leading, spacing: 10) {
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

                        if usesWideReviewLayout {
                            KatieWrap(spacing: 8, rowSpacing: 8) {
                                ForEach(appViewModel.reminderQuickPresets) { preset in
                                    reviewReminderPresetChip(preset)
                                }
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(appViewModel.reminderQuickPresets) { preset in
                                        reviewReminderPresetChip(preset)
                                    }
                                }
                            }
                        }

                        Text("Adjust the reminder from Review so the next nudge lands in the exact real-world moment this rep needs.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button(reviewReminderActionTitle) {
                    handleReviewReminderAction()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(reviewReminderActionBackground)
                .foregroundStyle(reviewReminderActionForeground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: appViewModel.remindersEnabled)
        .katieCard()
    }

    private var reviewReminderOwnerLabel: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Reminder owner: none yet"
        }

        return "Reminder owner: \(reminderPlan.scenario.packTitle) · \(reminderPlan.fireDate.formatted(date: .omitted, time: .shortened))"
    }

    private var reviewReminderOwnerDetail: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Review stays on this saved line until you decide it is worth protecting with the next reminder."
        }

        if reminderPlan.scenario == appViewModel.currentMission {
            return "Review and the next nudge are protecting the same pack, so the replay story stays grounded on one saved line."
        }

        return "Review stays on \(appViewModel.currentMission.packTitle), but the next nudge is currently protecting \(reminderPlan.scenario.packTitle). Move it here only when this is the line you want back next."
    }

    private var reviewReminderOwnerSystemImage: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "bell.slash"
        }

        return reminderPlan.scenario == appViewModel.currentMission ? "bell.badge.fill" : "bell.badge"
    }

    private var reviewReminderOwnerAccent: Color {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return KatieColors.textSecondary
        }

        return reminderPlan.scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.gold
    }

    private func reviewReminderPresetChip(_ preset: ReminderQuickPreset) -> some View {
        Button(preset.title) {
            appViewModel.updateReminderTime(preset.fireDate)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(KatieColors.cardSecondary)
        .foregroundStyle(KatieColors.textPrimary)
        .clipShape(Capsule())
    }

    private var reviewReminderActionTitle: String {
        if appViewModel.reminderPermissionState == .denied {
            return appViewModel.reminderPlan?.scenario == appViewModel.currentMission ? "Fix reminders" : "Enable reminders"
        }

        if appViewModel.remindersEnabled {
            return "Pause reminder"
        }

        if appViewModel.reminderPlan != nil {
            return "Move reminder to this pack"
        }

        return "Protect with reminder"
    }

    private var reviewReminderActionBackground: Color {
        appViewModel.remindersEnabled ? KatieColors.cardSecondary : KatieColors.accent
    }

    private var reviewReminderActionForeground: Color {
        appViewModel.remindersEnabled ? KatieColors.textPrimary : .black
    }

    private func handleReviewReminderAction() {
        if appViewModel.reminderPermissionState == .denied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
            return
        }

        appViewModel.scheduleOrDismissReminder()
    }

    private var retakeMissionCard: some View {
        let anchor = appViewModel.selectedCompareAnchor

        return VStack(alignment: .leading, spacing: 14) {
            Text("Next rep")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.currentPackNextStepLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                reviewCueRow(
                    title: anchor == nil ? "Benchmark to build from" : "Benchmark to protect",
                    body: anchor.map { "\($0.scenario.packTitle) stays pinned as the compare anchor while you tighten the next retake." }
                        ?? "Katie will keep your latest saved proof in view until this pack has a clearer compare anchor to protect.",
                    accent: KatieColors.mint
                )

                reviewCueRow(
                    title: "Listener goal",
                    body: appViewModel.currentMission.listenerOutcome,
                    accent: KatieColors.gold
                )

                reviewCueRow(
                    title: "Practice focus",
                    body: "Katie will reopen Practice on \(appViewModel.recommendedPracticeStepLabel.lowercased()) so the next save sharpens the newest unlocked step instead of restarting the whole pack.",
                    accent: KatieColors.accent
                )
            }

            KatieWrap(spacing: 8, rowSpacing: 8) {
                ForEach(Array(appViewModel.currentMission.stepLabels.enumerated()), id: \.element) { index, label in
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(index == appViewModel.recommendedPracticeStep ? KatieColors.textPrimary : KatieColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(index == appViewModel.recommendedPracticeStep ? KatieColors.accent.opacity(0.2) : KatieColors.cardSecondary)
                        .overlay(
                            Capsule()
                                .stroke(index == appViewModel.recommendedPracticeStep ? KatieColors.accent : Color.clear, lineWidth: 1.5)
                        )
                        .clipShape(Capsule())
                }
            }

            Text(appViewModel.recommendedPracticeStepPrompt)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            if let anchor {
                Label("Current anchor: \(anchor.scenario.packTitle)", systemImage: "pin.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
            }

            HStack(spacing: 10) {
                Button("Back to Practice") {
                    appViewModel.continuePracticeFromReview()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(KatieColors.accent)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button("Open progress") {
                    appViewModel.openProgressFromReview()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .katieCard()
    }

    private var featuredWinCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured win")
                .font(.headline)

            if let featured = appViewModel.featuredWin {
                Label(featured.sourceTag, systemImage: featured.readiness.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Text(appViewModel.recorderStatusLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    if appViewModel.hasEarnedCompare {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Before")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)
                            Text(featured.beforeText)
                                .foregroundStyle(KatieColors.textPrimary)
                                .lineLimit(2)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("After")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)
                            Text(featured.afterText)
                                .foregroundStyle(KatieColors.textPrimary)
                                .lineLimit(2)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(appViewModel.hasEarnedFirstWin ? "Your first proof" : "Starter example")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)
                            Text(appViewModel.hasEarnedFirstWin ? featured.afterText : featured.beforeText)
                                .foregroundStyle(KatieColors.textPrimary)
                                .lineLimit(3)
                        }
                    }
                }

                Text(featured.deltaHint)
                    .font(.subheadline)
                    .foregroundStyle(KatieColors.textSecondary)

                KatieWrap(spacing: 8, rowSpacing: 8) {
                    if let anchor = featured.anchorSession,
                       appViewModel.hasPlayback(for: anchor) {
                        Button(appViewModel.currentlyPlayingSessionID == anchor.id ? "Stop baseline" : "Play baseline") {
                            if appViewModel.currentlyPlayingSessionID == anchor.id {
                                appViewModel.stopPlayback()
                            } else {
                                appViewModel.playSession(anchor)
                            }
                        }
                        .modifier(ReviewActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary))
                    }

                    if appViewModel.hasPlayback(for: featured.latestSession) {
                        Button(appViewModel.currentlyPlayingSessionID == featured.latestSession.id ? "Stop" : "Play") {
                            if appViewModel.currentlyPlayingSessionID == featured.latestSession.id {
                                appViewModel.stopPlayback()
                            } else {
                                appViewModel.playSession(featured.latestSession)
                            }
                        }
                        .modifier(ReviewActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary))
                    }

                    Button(featured.anchorSession == nil ? "Open proof" : "Open compare") {
                        appViewModel.openReview(for: featured.scenario, anchor: featured.anchorSession)
                    }
                    .modifier(ReviewActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary))

                    Button(reviewReminderActionTitle) {
                        handleReviewReminderAction()
                    }
                    .modifier(ReviewActionChipStyle(background: reviewReminderActionBackground, foreground: reviewReminderActionForeground))

                    Button("Practice") {
                        appViewModel.openPractice(for: featured.scenario)
                    }
                    .modifier(ReviewActionChipStyle(background: featured.scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.cardSecondary, foreground: featured.scenario == appViewModel.currentMission ? .black : KatieColors.textPrimary))

                    Button("Open progress") {
                        appViewModel.openProgress(for: featured.scenario)
                    }
                    .modifier(ReviewActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary))
                }
            } else {
                Text("Complete one saved rep and this compare object will appear in both Today and Progress.")
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .katieCard()
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest transcript")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
            Text(appViewModel.latestSession.transcript)
                .foregroundStyle(KatieColors.textSecondary)
            Text(appViewModel.latestSession.transcriptFootnote)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private func compareTimeline(anchor: PracticeSession, latest: PracticeSession) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .center, spacing: 12) {
                compareTimelineStep(
                    title: "Earlier proof",
                    session: anchor,
                    accent: KatieColors.cardSecondary
                )

                compareTimelineConnector(anchor: anchor, latest: latest)

                compareTimelineStep(
                    title: "Latest retake",
                    session: latest,
                    accent: KatieColors.accent.opacity(0.16)
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                compareTimelineStep(
                    title: "Earlier proof",
                    session: anchor,
                    accent: KatieColors.cardSecondary
                )

                compareTimelineConnector(anchor: anchor, latest: latest)

                compareTimelineStep(
                    title: "Latest retake",
                    session: latest,
                    accent: KatieColors.accent.opacity(0.16)
                )
            }
        }
    }

    private func compareModeOverviewDetail(anchor: PracticeSession?, latest: PracticeSession) -> String {
        guard anchor != nil else {
            if latest.captureSource == .seeded {
                return "Starter continuity is still leading this pack until you save your own first proof on this iPhone."
            }

            return latest.isUserOwned
                ? "Your latest saved rep is the active benchmark until one more calm retake unlocks a before/after compare."
                : "This pack is still showing continuity rather than a full compare."
        }

        return "Review is holding one earlier proof beside the newest retake so you can judge the shift without widening the story."
    }

    private func compareReplayOverviewDetail(anchor: PracticeSession?, latest: PracticeSession) -> String {
        guard let anchor else {
            if appViewModel.hasPlayback(for: latest) {
                return "This proof can replay on this iPhone right now."
            }

            return latest.captureSource == .seeded
                ? "Starter words stay visible, but the demo side does not replay as your proof here."
                : "This proof is transcript-first on this iPhone until you record a fresh local clip."
        }

        let anchorHasPlayback = appViewModel.hasPlayback(for: anchor)
        let latestHasPlayback = appViewModel.hasPlayback(for: latest)

        switch (anchorHasPlayback, latestHasPlayback) {
        case (true, true):
            return "Both sides can replay on this iPhone right now."
        case (true, false):
            return "Only the earlier proof replays here until you save a fresh latest clip."
        case (false, true):
            return "Only the latest retake replays here until you rebuild the older proof locally."
        case (false, false):
            return "Neither side replays on this iPhone yet, so Review stays transcript-visible."
        }
    }

    private func compareActionOverviewTitle(anchor: PracticeSession?, latest: PracticeSession) -> String {
        if reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest) {
            return reviewStateActionTitle(anchor: anchor, latest: latest)
        }

        return anchor == nil ? "Practice into compare" : "Practice this retake"
    }

    private func compareActionOverviewDetail(anchor: PracticeSession?, latest: PracticeSession) -> String {
        if latest.captureSource == .seeded {
            return "Save one real local rep so Katie can replace starter continuity with your own proof."
        }

        guard !reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest) else {
            guard let anchor else {
                return "One fresh local recording brings replay back to this proof without losing the coaching trail."
            }

            let anchorHasPlayback = appViewModel.hasPlayback(for: anchor)
            let latestHasPlayback = appViewModel.hasPlayback(for: latest)

            switch (anchorHasPlayback, latestHasPlayback) {
            case (true, false):
                return "Save one calmer latest rep on this iPhone to restore the missing replay side without breaking the compare trail."
            case (false, true):
                return "Save another local retake so Review can keep the audible before/after ritual instead of only the newer side."
            case (false, false):
                return "One fresh local retake starts rebuilding replay for this compare while the transcript trail stays honest."
            case (true, true):
                return "Replay is already live on both sides, so the next move is simply protecting the clearest calmer retake."
            }
        }

        return anchor == nil
            ? "One calmer save in this pack unlocks the first before/after compare."
            : "Stay with this pack and protect the clearest line on the next calmer retake."
    }

    private func compareActionOverviewBackground(anchor: PracticeSession?, latest: PracticeSession) -> Color {
        if reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest) {
            return KatieColors.accent
        }

        return anchor == nil ? KatieColors.mint.opacity(0.22) : KatieColors.cardSecondary
    }

    private func compareActionOverviewForeground(anchor: PracticeSession?, latest: PracticeSession) -> Color {
        reviewStateNeedsReplayRecovery(anchor: anchor, latest: latest) ? .black : KatieColors.textPrimary
    }

    private func proofTruthStrip(for session: PracticeSession) -> some View {
        let truth = proofTruthCopy(for: session)

        return VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .vertical) {
                HStack(alignment: .center, spacing: 8) {
                    Label(truth.sourceTitle, systemImage: session.captureSource.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Spacer(minLength: 0)

                    Label(truth.readinessTitle, systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label(truth.sourceTitle, systemImage: session.captureSource.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Label(truth.readinessTitle, systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }

            Text(truth.body)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            if let actionTitle = truth.actionTitle {
                Button(actionTitle) {
                    appViewModel.openPractice(for: session.scenario)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.accent)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func proofTruthCopy(for session: PracticeSession) -> (sourceTitle: String, readinessTitle: String, body: String, actionTitle: String?) {
        let sourceTitle = appViewModel.compactCaptureSourceLabel(for: session)
        let readiness = appViewModel.displayCompareReadiness(for: session)

        switch readiness {
        case .audioReady:
            if session.captureSource == .seeded {
                return (
                    sourceTitle,
                    readiness.title,
                    "This side can replay on this iPhone, but Katie still keeps it labeled as starter continuity until you replace the sample with your own proof.",
                    "Record your own proof"
                )
            }

            return (
                sourceTitle,
                readiness.title,
                "This side is grounded in a real clip that can replay on this iPhone, so the compare stays audible as well as visible.",
                nil
            )
        case .transcriptOnly:
            switch session.captureSource {
            case .seeded:
                return (
                    sourceTitle,
                    readiness.title,
                    "This side is still a starter sample, so Review shows the words and coaching trail without pretending the demo audio belongs to you here.",
                    "Record your own proof"
                )
            case .syntheticRetake:
                return (
                    sourceTitle,
                    readiness.title,
                    "Katie saved this retake as text-only continuity, so the compare stays honest while you decide whether to record a replay-ready version on this iPhone.",
                    "Record replay-ready proof"
                )
            case .imported:
                return (
                    sourceTitle,
                    readiness.title,
                    "This proof carried over as transcript-first continuity. The protected line and coaching survived, but replay does not belong here until you record a fresh local clip.",
                    "Record replacement clip"
                )
            case .recorded:
                return (
                    sourceTitle,
                    readiness.title,
                    "This side still holds the wording and coaching trail, but the replayable clip is not attached on this iPhone right now.",
                    "Record replacement clip"
                )
            }
        case .transferredWithoutAudio:
            return (
                sourceTitle,
                readiness.title,
                "This compare side came over as imported continuity. Katie kept the proof trail visible, but replay still needs a fresh local recording on this iPhone.",
                "Record replacement clip"
            )
        case .missingAudio:
            return (
                sourceTitle,
                readiness.title,
                session.captureSource == .seeded
                    ? "The starter proof is still visible for continuity, but the bundled sample audio is not attached here. Record one real rep to replace the demo side with your own clip."
                    : "This proof kept its compare metadata, but the local audio file is missing on this iPhone. Record one calmer retake to bring replay back into the pack.",
                session.captureSource == .seeded ? "Record your own proof" : "Record replacement clip"
            )
        }
    }

    private func compareTimelineStep(title: String, session: PracticeSession, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text(session.scenario.packTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(2)

            Text(compareTimelineDateLabel(for: session))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            proofFactChip(appViewModel.compactReplayLabel(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareTimelineConnector(anchor: PracticeSession, latest: PracticeSession) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.forward")
                .font(.caption.weight(.bold))
                .foregroundStyle(KatieColors.mint)

            Text(compareTimelineGapLabel(anchor: anchor, latest: latest))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(minWidth: 72)
    }

    private func compareReplayStrip(anchor: PracticeSession, latest: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Replay side-by-side", systemImage: "waveform.path.ecg.rectangle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            ViewThatFits(in: .vertical) {
                HStack(spacing: 10) {
                    compareReplayButton(title: "Earlier proof", session: anchor)
                    compareReplayButton(title: "Latest retake", session: latest)
                }

                VStack(alignment: .leading, spacing: 10) {
                    compareReplayButton(title: "Earlier proof", session: anchor)
                    compareReplayButton(title: "Latest retake", session: latest)
                }
            }

            Text(compareReplaySummary(anchor: anchor, latest: latest))
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compareReplayButton(title: String, session: PracticeSession) -> some View {
        let isPlaying = appViewModel.currentlyPlayingSessionID == session.id
        let hasPlayback = appViewModel.hasPlayback(for: session)
        let truth = proofTruthCopy(for: session)
        let actionTitle = hasPlayback
            ? (isPlaying ? "Stop replay" : "Play replay")
            : (truth.actionTitle ?? "Record proof")
        let detailLine = hasPlayback ? appViewModel.compactReplayLabel(for: session) : truth.body

        return Button {
            if hasPlayback {
                if isPlaying {
                    appViewModel.stopPlayback()
                } else {
                    appViewModel.playSession(session)
                }
            } else {
                appViewModel.openPractice(for: session.scenario)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hasPlayback && isPlaying ? .black : KatieColors.textPrimary)
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(hasPlayback && isPlaying ? Color.black.opacity(0.72) : KatieColors.textSecondary)
                    .lineLimit(hasPlayback ? 2 : 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(compareReplayButtonBackground(session: session, isPlaying: isPlaying, hasPlayback: hasPlayback))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compareReplayButtonBackground(session: PracticeSession, isPlaying: Bool, hasPlayback: Bool) -> Color {
        if hasPlayback {
            return isPlaying ? KatieColors.accent : KatieColors.cardSecondary
        }

        return session.audioFileName != nil ? KatieColors.cardBackground.opacity(0.92) : KatieColors.cardSecondary
    }

    private func compareReplaySummary(anchor: PracticeSession, latest: PracticeSession) -> String {
        let anchorPlayback = appViewModel.hasPlayback(for: anchor)
        let latestPlayback = appViewModel.hasPlayback(for: latest)

        switch (anchorPlayback, latestPlayback) {
        case (true, true):
            return "Tap between the earlier proof and latest retake to hear the before/after shift without leaving Review."
        case (true, false):
            return "The earlier proof can replay now. Record one fresh retake on this iPhone to restore a full A/B listening loop."
        case (false, true):
            return "The latest retake can replay now. Restore the older proof locally if you want the full before/after listening ritual back."
        case (false, false):
            return "Replay is missing for both sides on this iPhone, so Katie keeps the compare trail visible and sends you back to Practice only when you want to rebuild it."
        }
    }

    private func compareTimelineDateLabel(for session: PracticeSession) -> String {
        Self.compareTimelineFormatter.string(from: session.date)
    }

    private func compareTimelineGapLabel(anchor: PracticeSession, latest: PracticeSession) -> String {
        let components = Calendar.current.dateComponents([.day, .hour], from: anchor.date, to: latest.date)
        let days = max(components.day ?? 0, 0)
        let hours = max(components.hour ?? 0, 0)

        if days > 0 {
            return days == 1 ? "1 day later" : "\(days) days later"
        }

        if hours > 0 {
            return hours == 1 ? "1 hour later" : "\(hours) hours later"
        }

        return "Same session"
    }

    @ViewBuilder
    private func proofFactChips(for session: PracticeSession) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                proofFactChip(appViewModel.compactCaptureSourceLabel(for: session), systemImage: session.captureSource.systemImage)
                proofFactChip(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
                proofFactChip(appViewModel.speakingPaceLabel(for: session), systemImage: "speedometer")
                proofFactChip(appViewModel.compactReplayLabel(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
            }

            VStack(alignment: .leading, spacing: 8) {
                proofFactChip(appViewModel.compactCaptureSourceLabel(for: session), systemImage: session.captureSource.systemImage)
                proofFactChip(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
                proofFactChip(appViewModel.speakingPaceLabel(for: session), systemImage: "speedometer")
                proofFactChip(appViewModel.compactReplayLabel(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
            }
        }
    }

    private func proofFactChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(KatieColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(KatieColors.cardBackground.opacity(0.78))
            .clipShape(Capsule())
    }

    private func compareDeltaPill(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func structureDeltaLabel(anchor: PracticeSession, latest: PracticeSession) -> String {
        let delta = latest.unlockedStepCount - anchor.unlockedStepCount

        if delta > 0 {
            return "+\(delta) step\(delta == 1 ? "" : "s") unlocked"
        }
        if delta < 0 {
            return "\(abs(delta)) fewer steps visible"
        }
        return "Same step depth"
    }

    private func transcriptDeltaLabel(anchor: PracticeSession, latest: PracticeSession) -> String {
        let delta = transcriptWordCount(for: latest) - transcriptWordCount(for: anchor)

        if delta > 0 {
            return "+\(delta) words vs earlier"
        }
        if delta < 0 {
            return "\(abs(delta)) fewer words"
        }
        return "Same transcript length"
    }

    private func replayDeltaLabel(anchor: PracticeSession, latest: PracticeSession) -> String {
        let anchorHasReplay = appViewModel.hasPlayback(for: anchor)
        let latestHasReplay = appViewModel.hasPlayback(for: latest)

        switch (anchorHasReplay, latestHasReplay) {
        case (true, true):
            return "Both sides replay-ready"
        case (false, true):
            return "Latest added replay"
        case (true, false):
            return "Earlier only has replay"
        case (false, false):
            return "Transcript continuity only"
        }
    }

    private func paceDeltaLabel(anchor: PracticeSession, latest: PracticeSession) -> String {
        guard let anchorPace = wordsPerMinute(for: anchor),
              let latestPace = wordsPerMinute(for: latest) else {
            return "Need local replay"
        }

        let delta = latestPace - anchorPace
        if abs(delta) < 5 {
            return "Roughly same pace"
        }
        if delta > 0 {
            return "+\(delta) wpm faster"
        }
        return "\(abs(delta)) wpm calmer"
    }

    private func transcriptWordCount(for session: PracticeSession) -> Int {
        session.transcript.split { $0.isWhitespace || $0.isNewline }.count
    }

    private func transcriptExcerpt(for session: PracticeSession) -> String {
        let excerpt = session.transcript
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if excerpt.count <= 180 {
            return excerpt
        }

        let cutoffIndex = excerpt.index(excerpt.startIndex, offsetBy: 180)
        return String(excerpt[..<cutoffIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private func transcriptShiftSummary(anchor: PracticeSession, latest: PracticeSession) -> String {
        let anchorCount = transcriptWordCount(for: anchor)
        let latestCount = transcriptWordCount(for: latest)

        if latestCount == anchorCount {
            return "Both versions are about the same length, so focus on how the wording itself got cleaner or steadier."
        }

        if latestCount < anchorCount {
            return "The latest retake says the idea in fewer words, which usually means the listener gets to the point faster."
        }

        return "The latest retake uses more words than the earlier proof, so check whether the extra detail adds clarity instead of drift."
    }

    private func wordsPerMinute(for session: PracticeSession) -> Int? {
        guard let duration = session.durationSeconds,
              duration > 0,
              appViewModel.hasPlayback(for: session) else {
            return nil
        }

        return Int(((Double(transcriptWordCount(for: session)) / duration) * 60).rounded())
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

private struct ReviewActionChipStyle: ViewModifier {
    let background: Color
    let foreground: Color

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }
}

private extension ReviewRetakeView {
    static let compareTimelineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E · h:mm a"
        return formatter
    }()
}

#Preview {
    ReviewRetakeView()
        .environmentObject(AppViewModel())
}
