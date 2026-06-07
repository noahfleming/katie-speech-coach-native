import SwiftUI

struct PracticeRecordView: View {
    private struct QuickRepRunwayStep: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let accent: Color

        var id: String { title }
    }

    private enum Layout {
        static let compactSectionSpacing: CGFloat = 14
        static let regularSectionSpacing: CGFloat = 16
        static let compactHorizontalPadding: CGFloat = 14
        static let regularHorizontalPadding: CGFloat = 16
        static let compactTopPadding: CGFloat = 12
        static let regularTopPadding: CGFloat = 16
        static let compactBottomPadding: CGFloat = 24
        static let regularBottomPadding: CGFloat = 16
        static let headerSpacingCompact: CGFloat = 10
        static let headerSpacingRegular: CGFloat = 12
        static let heroSpacing: CGFloat = 10
        static let cardSpacing: CGFloat = 12
        static let innerSpacing: CGFloat = 14
        static let inlineSpacing: CGFloat = 10
        static let chipSpacing: CGFloat = 8
        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 8
        static let chipVerticalPaddingCompact: CGFloat = 6
        static let chipCompactHorizontalPadding: CGFloat = 8
        static let cardCornerRadius: CGFloat = 18
        static let innerCardCornerRadius: CGFloat = 16
        static let editorCornerRadius: CGFloat = 14
        static let editorMinHeight: CGFloat = 110
        static let contentMaxWidthCompact: CGFloat = 760
        static let contentMaxWidthRegular: CGFloat = 940
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isScenarioSwitcherExpanded = false
    @State private var isReminderOptionsPresented = false
    @State private var isRetakeDraftExpanded = false
    @State private var holdToSpeakStartedAt: Date?

    private let practiceDraftAnchor = "practice-draft"

    private var isMicrophoneDenied: Bool {
        appViewModel.microphonePermissionState == .denied
    }

    private var primaryCaptureButtonTitle: String {
        if appViewModel.isRecording {
            return "Stop recording"
        }

        return isMicrophoneDenied ? "Use text-only proof" : "Start recording"
    }

    private var highlightedQuickRepPrompt: QuickRepPrompt? {
        appViewModel.quickRepRail.first(where: { $0.scenario == appViewModel.currentMission }) ?? appViewModel.quickRepRail.first
    }

    private var usesWidePracticeCompareLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var usesWideReminderPresetLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var reminderSurfaceLabel: String {
        usesWideReminderPresetLayout ? "this iPad" : "this iPhone"
    }

    private var practiceBoardMetrics: [KatieGlanceMetric] {
        [
            KatieGlanceMetric(
                title: "Pack in focus",
                value: appViewModel.currentMission.packTitle,
                detail: appViewModel.currentMission.listenerOutcome,
                accent: KatieColors.gold
            ),
            KatieGlanceMetric(
                title: "Capture",
                value: appViewModel.microphonePermissionState.title,
                detail: appViewModel.microphoneStatusLine,
                accent: KatieColors.accent
            ),
            KatieGlanceMetric(
                title: "Review lane",
                value: appViewModel.hasEarnedCompare ? "Compare ready" : (appViewModel.hasEarnedFirstWin ? "One more proof" : "Starter proof only"),
                detail: appViewModel.latestReviewSummaryLine,
                accent: KatieColors.mint
            )
        ]
    }

    private var practiceBoardCard: some View {
        KatieGlanceBoard(
            eyebrow: "Practice runway",
            title: "Catch the line while it still feels warm",
            detail: "Record on \(reminderSurfaceLabel), keep the retake grounded, then bounce straight into Review with one honest proof.",
            systemImage: "mic.fill",
            accent: KatieColors.accent,
            secondary: KatieColors.gold,
            metrics: practiceBoardMetrics,
            footnote: "Return focus · \(appViewModel.recommendedPracticeStepLabel)"
        )
        .katieHeroAura(accent: KatieColors.accent, secondary: KatieColors.gold)
    }

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                let isCompactPhoneLayout = horizontalSizeClass != .regular && geometry.size.width < 430
                let contentSpacing: CGFloat = isCompactPhoneLayout ? Layout.compactSectionSpacing : Layout.regularSectionSpacing
                let horizontalPadding: CGFloat = isCompactPhoneLayout ? Layout.compactHorizontalPadding : Layout.regularHorizontalPadding
                let headerSpacing: CGFloat = isCompactPhoneLayout ? Layout.headerSpacingCompact : Layout.headerSpacingRegular

                ScrollView {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    HStack(spacing: headerSpacing) {
                        Image(systemName: "mic.fill")
                            .katieIconBadge(background: KatieColors.cardSecondary, foreground: KatieColors.gold, size: isCompactPhoneLayout ? 30 : 34)
                        Text("Practice")
                            .font(isCompactPhoneLayout ? .title2.bold() : .title.bold())
                            .foregroundStyle(KatieColors.textPrimary)
                        Spacer()
                    }
                    .id("practice-top")

                    VStack(alignment: .leading, spacing: Layout.heroSpacing) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: Layout.innerSpacing) {
                                practiceHeroSummary

                                Spacer(minLength: 0)

                                KatieScenarioArtwork(systemImage: "mic.fill", accent: KatieColors.accent, secondary: KatieColors.gold)
                            }

                            VStack(alignment: .leading, spacing: Layout.innerSpacing) {
                                KatieScenarioArtwork(systemImage: "mic.fill", accent: KatieColors.accent, secondary: KatieColors.gold)
                                    .frame(width: 64, height: 64, alignment: .leading)

                                practiceHeroSummary
                            }
                        }
                    }
                    .katieCard()
                    .katieHeroAura(accent: KatieColors.accent, secondary: KatieColors.mint)

                practiceBoardCard

                listeningHypothesisStrip
                scenarioSwitcherCard
                reminderContinuityCard
                reminderFlowBanner

                if let cue = appViewModel.practiceReturnCue {
                    VStack(alignment: .leading, spacing: Layout.inlineSpacing) {
                        HStack(alignment: .top, spacing: Layout.inlineSpacing) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.title3)
                                .foregroundStyle(KatieColors.mint)

                            VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                                Text(cue.title)
                                    .font(.headline)
                                Text(cue.body)
                                    .font(.subheadline)
                                    .foregroundStyle(KatieColors.textSecondary)
                            }
                        }

                        HStack(spacing: Layout.inlineSpacing) {
                            Button(primaryCaptureButtonTitle) {
                                handlePrimaryCaptureAction(proxy: proxy)
                            }
                            .buttonStyle(
                                .katiePrimary(
                                    fill: LinearGradient(
                                        colors: appViewModel.isRecording ? [KatieColors.mint, KatieColors.gold] : [KatieColors.gold, KatieColors.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    foreground: KatieColors.textPrimary
                                )
                            )

                            Button("Got it") {
                                appViewModel.dismissPracticeReturnCue()
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Layout.chipHorizontalPadding)
                            .padding(.vertical, Layout.chipVerticalPadding)
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(Capsule())
                        }

                        Label("Focus step · \(appViewModel.recommendedPracticeStepLabel)", systemImage: "flag.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)
                    }
                    .katieCard()
                }

                VStack(alignment: .leading, spacing: Layout.innerSpacing) {
                    HStack {
                        VStack(alignment: .leading, spacing: Layout.chipVerticalPaddingCompact) {
                            Text("Latest review")
                                .font(.headline)
                            Text(appViewModel.latestReviewSummaryLine)
                                .foregroundStyle(KatieColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title3)
                            .foregroundStyle(KatieColors.accent)
                    }

                    HStack(spacing: Layout.chipSpacing) {
                        Label(appViewModel.compareCeremonyLabel, systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)

                        Text(appViewModel.latestReviewStatusLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.textSecondary)
                            .padding(.horizontal, Layout.chipCompactHorizontalPadding)
                            .padding(.vertical, KatieSpacing.xxs)
                            .background(KatieColors.cardSecondary)
                            .clipShape(Capsule())
                    }

                    Text(appViewModel.comparisonSummary)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)

                    practiceReviewProofStrip

                    if appViewModel.compareCandidates.count > 1 {
                        practiceCompareAnchorPicker
                    }

                    Label("Return focus · \(appViewModel.recommendedPracticeStepLabel)", systemImage: "flag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    HStack(spacing: Layout.inlineSpacing) {
                        Button(appViewModel.latestReviewActionTitle) {
                            appViewModel.presentReview()
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

                        Button(practiceReminderActionTitle(for: appViewModel.currentMission)) {
                            handlePracticeReminderAction(for: appViewModel.currentMission)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Layout.chipHorizontalPadding + 2)
                        .padding(.vertical, Layout.chipVerticalPadding + 2)
                        .background(practiceReminderActionBackground(for: appViewModel.currentMission))
                        .foregroundStyle(practiceReminderActionForeground(for: appViewModel.currentMission))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))

                        practiceReviewMenu
                    }
                }
                .katieCard()

                VStack(alignment: .leading, spacing: Layout.regularSectionSpacing) {
                    Text("Recording")
                        .font(.headline)
                    Text(appViewModel.isRecording ? "Live prep mode: follow the steps, then save one calm rep" : appViewModel.recorderStatusLine)
                        .foregroundStyle(KatieColors.textSecondary)

                    Label(appViewModel.microphonePermissionState.title, systemImage: appViewModel.microphonePermissionState.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text(appViewModel.microphoneStatusLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    if appViewModel.microphonePermissionState == .denied {
                        Button("Open iPhone Settings for microphone") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(url)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, KatieSpacing.base)
                        .padding(.vertical, KatieSpacing.sm)
                        .background(KatieColors.cardSecondary)
                        .foregroundStyle(KatieColors.textPrimary)
                        .clipShape(Capsule())

                        transcriptFallbackCard(proxy: proxy)
                    }

                    scratchTruthCard
                    reflectionCard
                    proofModeCard
                    quickRepCard
                    coachChecklistCard

                    Button(primaryCaptureButtonTitle) {
                        handlePrimaryCaptureAction(proxy: proxy)
                    }
                    .buttonStyle(
                        .katiePrimary(
                            fill: LinearGradient(
                                colors: appViewModel.isRecording ? [KatieColors.mint, KatieColors.gold] : [KatieColors.gold, KatieColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )

                    holdToSpeakButton

                    if let duration = appViewModel.latestScratchRecordingDuration {
                        Label("Latest scratch take · \(Int(duration))s", systemImage: "waveform")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)
                    }

                    stepProgressCard(proxy: proxy)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                            Text("Retake draft")
                                .font(.headline)
                            Text("Keep the text retake available without forcing a full editor open.")
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                        Spacer()
                        Button(isRetakeDraftExpanded ? "Hide" : "Draft") {
                            withAnimation(KatieMotion.quick) {
                                isRetakeDraftExpanded.toggle()
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                    }
                    .id(practiceDraftAnchor)

                    if isRetakeDraftExpanded {
                        TextEditor(text: $appViewModel.draftTranscript)
                            .frame(minHeight: Layout.editorMinHeight)
                            .scrollContentBackground(.hidden)
                            .padding(KatieSpacing.base)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.editorCornerRadius)
                                    .stroke(KatieColors.cardSecondary)
                            )

                        Text("Saved draft uses the same protected structure as your latest rep. Keep your final line short so the compare ritual stays honest.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)

                        VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                            Text("Step starters")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)

                            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                                ForEach(appViewModel.retakeDraftStarterChips, id: \.self) { starter in
                                    Button(starter) {
                                        appViewModel.applyRetakeDraftStarter(starter)
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, KatieSpacing.md)
                                    .padding(.vertical, KatieSpacing.sm)
                                    .background(KatieColors.cardSecondary)
                                    .foregroundStyle(KatieColors.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: Layout.editorCornerRadius, style: .continuous))
                                }
                            }
                        }

                        practiceSaveOutcomeCard

                        HStack(spacing: KatieSpacing.sm) {
                            Button(appViewModel.practiceSaveButtonTitle) {
                                appViewModel.saveCurrentRetake()
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appViewModel.isRecording ? KatieColors.cardSecondary : KatieColors.accent)
                            .foregroundStyle(appViewModel.isRecording ? KatieColors.textSecondary : .black)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                            .disabled(appViewModel.isRecording)

                            Button("Clear") {
                                appViewModel.clearDraftRetake()
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(KatieColors.cardSecondary)
                            .foregroundStyle(KatieColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                        }
                    }
                }
                .katieCard()

                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    Label("Protected line", systemImage: "lock.shield.fill")
                        .font(.headline)
                    Text(appViewModel.currentScenarioRemainsProtected)
                        .foregroundStyle(KatieColors.textSecondary)
                    Text("This scenario keeps the latest protected benchmark line for quick compare and reminders.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                .katieCard()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, isCompactPhoneLayout ? Layout.compactTopPadding : Layout.regularTopPadding)
            .padding(.bottom, isCompactPhoneLayout ? Layout.compactBottomPadding : Layout.regularBottomPadding)
            .katieContentFrame(maxWidth: isCompactPhoneLayout ? Layout.contentMaxWidthCompact : Layout.contentMaxWidthRegular)
        }
        .background(LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing).overlay { RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420) }.ignoresSafeArea())
    }
    }
    }

    private var practiceHeroSummary: some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            KatieSectionEyebrow(title: "Pack in focus", systemImage: "flag.fill", accent: KatieColors.gold)
            Text(appViewModel.currentMission.packTitle)
                .font(.title3.bold())
            Text(appViewModel.currentMission.listenerOutcome)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
            Text(appViewModel.currentMission.missionPrompt)
                .font(.subheadline)
                .foregroundStyle(KatieColors.textSecondary)
            KatieReplayBadge(title: "Structure · \(appViewModel.latestSession.structurePrompt)", systemImage: "point.3.connected.trianglepath.dotted", accent: KatieColors.mint)
        }
    }

    private func transcriptFallbackCard(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            Label("Text-only proof path is active", systemImage: "text.quote")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.gold)

            Text("Practice keeps the transcript-first save lane open so you can still protect this pack now without pretending a local replay clip exists.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(appViewModel.practiceTranscriptTruthLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textPrimary)

            Button("Jump to transcript save") {
                handlePrimaryCaptureAction(proxy: proxy)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Layout.chipHorizontalPadding + 2)
            .padding(.vertical, Layout.chipVerticalPaddingCompact + 4)
            .background(KatieColors.gold.opacity(0.2))
            .foregroundStyle(KatieColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var scratchTruthCard: some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            Label(appViewModel.scratchCaptureTruthTitle, systemImage: appViewModel.isRecording ? "waveform.circle.fill" : (appViewModel.latestScratchRecordingDuration == nil ? "text.quote" : "iphone.gen3.radiowaves.left.and.right"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.scratchCaptureTruthBody)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: Layout.chipSpacing) {
                statusPill(title: appViewModel.hasScratchRecording ? "Local clip attached" : "No local clip yet", accent: appViewModel.hasScratchRecording ? KatieColors.mint : KatieColors.gold)
                statusPill(title: appViewModel.draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Draft empty" : "Transcript draft ready", accent: KatieColors.accent)
            }
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var quickRepCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    KatieSectionEyebrow(title: "Quick rep lane", systemImage: "bolt.fill", accent: KatieColors.gold)
                    Text(appViewModel.quickRepHintLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: Layout.inlineSpacing + 2)

                Text("60–90 sec")
                    .modifier(KatieCapsuleLabelStyle())
            }

            if let prompt = highlightedQuickRepPrompt {
                let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario

                Button {
                    appViewModel.launchQuickRep(for: prompt.scenario)
                } label: {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        HStack(alignment: .top, spacing: Layout.cardSpacing) {
                            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                                KatieSectionEyebrow(title: appViewModel.quickChallengeHeadline, systemImage: "timer", accent: KatieColors.gold)

                                Text(prompt.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(prompt.scenario.packTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)

                                Text(prompt.scenario.listenerOutcome)
                                    .font(.caption2)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(prompt.detail)
                                    .font(.caption)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            Text(prompt.durationLabel)
                                .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                        }

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

                        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                            Label("What stays in sync after this rep", systemImage: "point.3.filled.connected.trianglepath.dotted")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)

                            VStack(alignment: .leading, spacing: Layout.chipVerticalPaddingCompact) {
                                ForEach(quickRepRunwaySteps(for: prompt)) { step in
                                    quickRepRunwayRow(step)
                                }
                            }
                        }

                        HStack(alignment: .center, spacing: Layout.chipSpacing) {
                            Label("What you’ll say first", systemImage: "quote.bubble")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)

                            Spacer(minLength: 0)

                            Text(prompt.starterLine)
                                .font(.caption)
                                .foregroundStyle(KatieColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(Layout.innerSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.gold.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous)
                            .stroke(KatieColors.gold.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Layout.inlineSpacing) {
                    ForEach(appViewModel.quickRepRail) { prompt in
                        let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario
                        Button {
                            appViewModel.launchQuickRep(for: prompt.scenario)
                        } label: {
                            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                                KatieSectionEyebrow(title: prompt.scenario.packTitle, systemImage: "sparkles.rectangle.stack.fill", accent: KatieColors.accent)

                                Text(prompt.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(KatieColors.textPrimary)

                                statusPill(title: prompt.statusLabel, accent: reminderProtected ? KatieColors.mint : KatieColors.gold)

                                Text(prompt.detail)
                                    .font(.caption2)
                                    .foregroundStyle(KatieColors.textSecondary)
                                    .lineLimit(2)

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
                            .padding(Layout.cardSpacing)
                            .frame(width: 220, alignment: .leading)
                            .background(KatieColors.cardSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
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

    private func quickRepRunwayRow(_ step: QuickRepRunwayStep) -> some View {
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
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var coachChecklistCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Label("Coach checklist", systemImage: "checklist")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                Label("Structure: \(appViewModel.currentMission.structurePrompt)", systemImage: "point.3.connected.trianglepath.dotted")
                Label("Land this step next: \(appViewModel.recommendedPracticeStepLabel)", systemImage: "flag.fill")
                Label("Sound focus first: \(appViewModel.languageAssessmentSnapshot.soundFocus)", systemImage: "dot.radiowaves.left.and.right")
                Label("Boundary: \(appViewModel.trustBoundaryLine)", systemImage: "checkmark.shield.fill")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var proofModeCard: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    KatieSectionEyebrow(title: "Proof mode", systemImage: "waveform.path.ecg.rectangle", accent: KatieColors.mint)
                    Text(appViewModel.practiceCaptureHonestyLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: KatieSpacing.base)

                Text(appViewModel.hasScratchRecording ? "Replay waiting" : "Transcript first")
                    .modifier(KatieCapsuleLabelStyle())
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: Layout.heroSpacing) {
                    proofModeColumn(
                        title: "Transcript path",
                        systemImage: "text.bubble.fill",
                        accent: KatieColors.cardSecondary,
                        pillAccent: KatieColors.gold,
                        status: appViewModel.draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Fallback copy" : "Draft ready",
                        detail: appViewModel.practiceTranscriptTruthLine
                    )

                    proofModeColumn(
                        title: "Local replay",
                        systemImage: appViewModel.hasScratchRecording || appViewModel.isRecording ? "waveform.circle.fill" : "iphone.gen3.radiowaves.left.and.right",
                        accent: KatieColors.accent.opacity(0.16),
                        pillAccent: appViewModel.hasScratchRecording || appViewModel.isRecording ? KatieColors.mint : KatieColors.accent,
                        status: appViewModel.isRecording ? "Recording now" : (appViewModel.hasScratchRecording ? "Ready to save" : "No fresh clip"),
                        detail: appViewModel.practiceReplayTruthLine
                    )
                }

                VStack(spacing: Layout.heroSpacing) {
                    proofModeColumn(
                        title: "Transcript path",
                        systemImage: "text.bubble.fill",
                        accent: KatieColors.cardSecondary,
                        pillAccent: KatieColors.gold,
                        status: appViewModel.draftTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Fallback copy" : "Draft ready",
                        detail: appViewModel.practiceTranscriptTruthLine
                    )

                    proofModeColumn(
                        title: "Local replay",
                        systemImage: appViewModel.hasScratchRecording || appViewModel.isRecording ? "waveform.circle.fill" : "iphone.gen3.radiowaves.left.and.right",
                        accent: KatieColors.accent.opacity(0.16),
                        pillAccent: appViewModel.hasScratchRecording || appViewModel.isRecording ? KatieColors.mint : KatieColors.accent,
                        status: appViewModel.isRecording ? "Recording now" : (appViewModel.hasScratchRecording ? "Ready to save" : "No fresh clip"),
                        detail: appViewModel.practiceReplayTruthLine
                    )
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var practiceSaveOutcomeCard: some View {
        let accent = appViewModel.isRecording
            ? KatieColors.gold
            : (appViewModel.hasScratchRecording ? KatieColors.mint : KatieColors.accent)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                KatieSectionEyebrow(title: "If you save now", systemImage: appViewModel.isRecording ? "record.circle" : (appViewModel.hasScratchRecording ? "waveform.circle.fill" : "text.bubble.fill"), accent: accent)

                Spacer(minLength: 8)

                statusPill(
                    title: appViewModel.isRecording ? "Finish recording" : (appViewModel.hasScratchRecording ? "Replay-ready save" : "Text-only save"),
                    accent: accent
                )
            }

            Text(appViewModel.practiceSaveOutcomeTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(appViewModel.practiceSaveOutcomeBody)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Label(appViewModel.practiceSaveReviewOutcomeLine, systemImage: "arrow.triangle.2.circlepath.circle")
                Label(appViewModel.practiceSaveProgressOutcomeLine, systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.caption)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(KatieSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private func proofModeColumn(title: String, systemImage: String, accent: Color, pillAccent: Color, status: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            HStack(alignment: .center, spacing: Layout.heroSpacing) {
                KatieScenarioArtwork(systemImage: systemImage, accent: pillAccent, secondary: KatieColors.gold)
                    .frame(width: 56, height: 56)

                KatieSectionEyebrow(title: title, systemImage: systemImage, accent: pillAccent)
            }

            statusPill(title: status, accent: pillAccent)

            Text(detail)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(KatieSpacing.base)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private var holdToSpeakButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(KatieColors.cardSecondary)

            VStack(spacing: KatieSpacing.xs) {
                Text(appViewModel.isRecording ? "Release to stop and keep this local clip" : "Press and hold for a quick rep")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                Text("Good for one short spoken pass when you don't want to tap start/stop twice.")
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, KatieSpacing.lg)
            .padding(.vertical, KatieSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(appViewModel.isRecording ? KatieColors.mint.opacity(0.8) : KatieColors.cardBorder, lineWidth: 1)
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    holdToSpeakStartedAt = holdToSpeakStartedAt ?? .now
                    appViewModel.beginPressToRecord()
                }
                .onEnded { _ in
                    let duration = holdToSpeakStartedAt.map { Date().timeIntervalSince($0) } ?? 0
                    holdToSpeakStartedAt = nil
                    appViewModel.completePressToRecord(after: duration)
                }
        )
        .accessibilityAddTraits(.isButton)
    }

    private func statusPill(title: String, accent: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, KatieSpacing.md)
            .padding(.vertical, KatieSpacing.xs)
            .background(accent.opacity(0.14))
            .clipShape(Capsule())
    }

    private var practiceReviewProofStrip: some View {
        let latest = appViewModel.latestSession
        let compareAnchor = appViewModel.selectedCompareAnchor
        let reviewActionTitle = compareAnchor == nil ? "Open proof" : "Open compare"

        return VStack(alignment: .leading, spacing: 10) {
            if let compareAnchor {
                ViewThatFits(in: .vertical) {
                    HStack(alignment: .top, spacing: 10) {
                        practiceProofColumn(
                            title: "Earlier proof",
                            session: compareAnchor,
                            line: compareAnchor.protectedLine,
                            detail: appViewModel.freshnessLabel(for: compareAnchor),
                            accent: KatieColors.cardSecondary,
                            reviewActionTitle: reviewActionTitle,
                            reviewAnchor: compareAnchor
                        )

                        practiceProofColumn(
                            title: "Latest rep",
                            session: latest,
                            line: latest.protectedLine,
                            detail: appViewModel.freshnessLabel(for: latest),
                            accent: KatieColors.accent.opacity(0.16),
                            reviewActionTitle: reviewActionTitle,
                            reviewAnchor: compareAnchor
                        )
                    }

                    VStack(spacing: 10) {
                        practiceProofColumn(
                            title: "Earlier proof",
                            session: compareAnchor,
                            line: compareAnchor.protectedLine,
                            detail: appViewModel.freshnessLabel(for: compareAnchor),
                            accent: KatieColors.cardSecondary,
                            reviewActionTitle: reviewActionTitle,
                            reviewAnchor: compareAnchor
                        )

                        practiceProofColumn(
                            title: "Latest rep",
                            session: latest,
                            line: latest.protectedLine,
                            detail: appViewModel.freshnessLabel(for: latest),
                            accent: KatieColors.accent.opacity(0.16),
                            reviewActionTitle: reviewActionTitle,
                            reviewAnchor: compareAnchor
                        )
                    }
                }
            } else {
                practiceProofColumn(
                    title: appViewModel.hasEarnedFirstWin ? "Latest proof" : "Starter sample",
                    session: latest,
                    line: latest.protectedLine,
                    detail: appViewModel.displayCompareReadinessDetail(for: latest),
                    accent: KatieColors.cardSecondary,
                    reviewActionTitle: reviewActionTitle,
                    reviewAnchor: nil
                )
            }
        }
    }

    private func practiceProofColumn(
        title: String,
        session: PracticeSession,
        line: String,
        detail: String,
        accent: Color,
        reviewActionTitle: String,
        reviewAnchor: PracticeSession?
    ) -> some View {
        let hasPlayback = appViewModel.hasPlayback(for: session)
        let isPlaying = appViewModel.currentlyPlayingSessionID == session.id

        return VStack(alignment: .leading, spacing: KatieSpacing.sm) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            Text(line)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .lineLimit(3)

            KatieWrap(spacing: KatieSpacing.xs, rowSpacing: KatieSpacing.xs) {
                practiceProofFactChip(appViewModel.compactCaptureSourceLabel(for: session), systemImage: session.captureSource.systemImage)
                practiceProofFactChip(appViewModel.transcriptWordCountLabel(for: session), systemImage: "text.word.spacing")
                practiceProofFactChip(appViewModel.compactReplayLabel(for: session), systemImage: appViewModel.displayCompareReadinessSystemImage(for: session))
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)
                .lineLimit(2)

            KatieWrap(spacing: KatieSpacing.sm, rowSpacing: KatieSpacing.sm) {
                if hasPlayback {
                    Button(isPlaying ? "Stop replay" : "Play replay") {
                        if isPlaying {
                            appViewModel.stopPlayback()
                        } else {
                            appViewModel.playSession(session)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.sm)
                    .background(KatieColors.cardBackground.opacity(0.9))
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(Capsule())
                }

                Button(reviewActionTitle) {
                    appViewModel.openReview(for: appViewModel.currentMission, anchor: reviewAnchor)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, KatieSpacing.md)
                .padding(.vertical, KatieSpacing.sm)
                .background(KatieColors.cardBackground.opacity(0.9))
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())

                Button("Open progress") {
                    appViewModel.openProgress(for: appViewModel.currentMission)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, KatieSpacing.md)
                .padding(.vertical, KatieSpacing.sm)
                .background(KatieColors.cardBackground.opacity(0.9))
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(KatieSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
    }

    private func practiceProofFactChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(KatieColors.textSecondary)
            .padding(.horizontal, KatieSpacing.sm)
            .padding(.vertical, KatieSpacing.xs)
            .background(KatieColors.cardBackground.opacity(0.85))
            .clipShape(Capsule())
    }

    private var practiceCompareAnchorPicker: some View {
        VStack(alignment: .leading, spacing: Layout.heroSpacing) {
            Text("Swap earlier proof")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            if usesWidePracticeCompareLayout {
                LazyVGrid(columns: practiceCompareAnchorGridColumns, alignment: .leading, spacing: KatieSpacing.base) {
                    ForEach(appViewModel.compareCandidates) { session in
                        practiceCompareAnchorCard(session: session)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Layout.heroSpacing) {
                        ForEach(appViewModel.compareCandidates) { session in
                            practiceCompareAnchorCard(session: session, compactWidth: 176)
                        }
                    }
                }
            }
        }
    }

    private var practiceCompareAnchorGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: KatieSpacing.base, alignment: .top),
            GridItem(.flexible(), spacing: KatieSpacing.base, alignment: .top)
        ]
    }

    private func practiceCompareAnchorCard(session: PracticeSession, compactWidth: CGFloat? = nil) -> some View {
        Button {
            appViewModel.selectCompareAnchor(session)
        } label: {
            VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                HStack(spacing: KatieSpacing.xs) {
                    Text(session.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if appViewModel.isSelectedAnchor(session) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(KatieColors.accent)
                    }
                }

                Text(appViewModel.freshnessLabel(for: session))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .lineLimit(1)

                Text(session.protectedLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, KatieSpacing.base)
            .padding(.vertical, KatieSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(width: compactWidth, alignment: .leading)
            .background(appViewModel.isSelectedAnchor(session) ? KatieColors.accent.opacity(0.18) : KatieColors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous)
                    .stroke(appViewModel.isSelectedAnchor(session) ? KatieColors.accent : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var listeningHypothesisStrip: some View {
        let plan = appViewModel.languageAssessmentSnapshot

        return VStack(alignment: .leading, spacing: KatieSpacing.base) {
            HStack(alignment: .top, spacing: KatieSpacing.base) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    KatieSectionEyebrow(title: "Starting hypothesis", systemImage: "ear", accent: KatieColors.mint)
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(2)
                    Text(plan.caveat)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: KatieSpacing.base)

                Text(appViewModel.transferHypothesisStatusTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .padding(.horizontal, KatieSpacing.md)
                    .padding(.vertical, KatieSpacing.xs)
                    .background(KatieColors.cardSecondary)
                    .clipShape(Capsule())
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: KatieSpacing.xs) {
                Text("Self-check in this pack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                Text("Does that sound like your real speaking under pressure?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                Text(appViewModel.transferHypothesisPracticeBridgeLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
            .padding(KatieSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.innerCardCornerRadius, style: .continuous))

            Label(appViewModel.transferHypothesisFollowThroughLine, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                Label("Sound first: \(plan.soundFocus)", systemImage: "dot.radiowaves.left.and.right")
                Label("Prosody second: \(plan.prosodyFocus)", systemImage: "waveform")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(KatieSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
    }

    private var scenarioSwitcherCard: some View {
        VStack(alignment: .leading, spacing: Layout.innerSpacing) {
            HStack(alignment: .top, spacing: KatieSpacing.base) {
                VStack(alignment: .leading, spacing: KatieSpacing.xxs) {
                    Text("Practice another pack")
                        .font(.headline)
                    Text("Switch packs here without leaving the recorder, and keep the listener goal visible before you record.")
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: KatieSpacing.sm) {
                    Text(appViewModel.scenarioStatusLabel(for: appViewModel.currentMission))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                        .padding(.horizontal, KatieSpacing.md)
                        .padding(.vertical, KatieSpacing.xs)
                        .background(KatieColors.cardSecondary)
                        .clipShape(Capsule())

                    Button(isScenarioSwitcherExpanded ? "Close" : "Browse") {
                        withAnimation(KatieMotion.quick) {
                            isScenarioSwitcherExpanded.toggle()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                }
            }

            if isScenarioSwitcherExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Layout.heroSpacing) {
                        ForEach(appViewModel.availableScenarios) { scenario in
                            let isSelected = scenario == appViewModel.currentMission
                            let isLockedByRecording = appViewModel.isRecording && !isSelected

                            VStack(alignment: .leading, spacing: Layout.heroSpacing) {
                                Button {
                                    appViewModel.selectScenario(scenario)
                                } label: {
                                    VStack(alignment: .leading, spacing: KatieSpacing.sm) {
                                        HStack(alignment: .top, spacing: KatieSpacing.sm) {
                                            Text(scenario.packTitle)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(KatieColors.textPrimary)
                                                .multilineTextAlignment(.leading)

                                            Spacer(minLength: KatieSpacing.sm)

                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(isSelected ? KatieColors.accent : KatieColors.textSecondary)
                                        }

                                        Text(scenario.listenerOutcome)
                                            .font(.caption)
                                            .foregroundStyle(KatieColors.textSecondary)
                                            .lineLimit(2)

                                        Text(appViewModel.scenarioStatusLabel(for: scenario))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(isSelected ? .black : KatieColors.mint)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(isSelected ? KatieColors.accent : KatieColors.cardBackground.opacity(0.9))
                                            .clipShape(Capsule())

                                        Text(appViewModel.scenarioStatusDetail(for: scenario))
                                            .font(.caption)
                                            .foregroundStyle(KatieColors.textSecondary)
                                            .lineLimit(3)

                                        Text(appViewModel.scenarioReminderLine(for: scenario))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(appViewModel.reminderPlan?.scenario == scenario ? KatieColors.accent : KatieColors.textSecondary)
                                            .lineLimit(2)

                                        Text(appViewModel.scenarioNextStepLine(for: scenario))
                                            .font(.caption2)
                                            .foregroundStyle(KatieColors.textSecondary)
                                            .lineLimit(3)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLockedByRecording)

                                KatieWrap(spacing: 8, rowSpacing: 8) {
                                    Button(practiceReminderActionTitle(for: scenario)) {
                                        handlePracticeReminderAction(for: scenario)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(practiceReminderActionBackground(for: scenario))
                                    .foregroundStyle(practiceReminderActionForeground(for: scenario))
                                    .clipShape(Capsule())
                                    .disabled(isLockedByRecording)

                                    if let reviewAnchor = practiceScenarioReviewAnchor(for: scenario) {
                                        Button(practiceScenarioReviewActionTitle(for: scenario, anchor: reviewAnchor)) {
                                            appViewModel.openReview(for: scenario, anchor: reviewAnchor)
                                        }
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(KatieColors.cardBackground.opacity(0.9))
                                        .foregroundStyle(KatieColors.textPrimary)
                                        .clipShape(Capsule())
                                        .disabled(isLockedByRecording)
                                    }

                                    Button("Practice") {
                                        appViewModel.openPractice(for: scenario)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? KatieColors.accent : KatieColors.cardBackground.opacity(0.9))
                                    .foregroundStyle(isSelected ? .black : KatieColors.textPrimary)
                                    .clipShape(Capsule())
                                    .disabled(isLockedByRecording)

                                    Button("Open progress") {
                                        appViewModel.openProgress(for: scenario)
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(KatieColors.cardBackground.opacity(0.9))
                                    .foregroundStyle(KatieColors.textPrimary)
                                    .clipShape(Capsule())
                                    .disabled(isLockedByRecording)

                                    practiceScenarioMenu(for: scenario, isLockedByRecording: isLockedByRecording)
                                }
                            }
                            .padding(14)
                            .frame(width: 220, alignment: .leading)
                            .background(isSelected ? KatieColors.accent.opacity(0.16) : KatieColors.cardSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? KatieColors.accent.opacity(0.7) : Color.clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .opacity(isLockedByRecording ? 0.55 : 1)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if isScenarioSwitcherExpanded && appViewModel.isRecording {
                Label(appViewModel.recordingLockLine, systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
            } else if !isScenarioSwitcherExpanded {
                Label(appViewModel.currentMission.packTitle, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                Text(appViewModel.scenarioStatusDetail(for: appViewModel.currentMission))
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .katieCard()
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Before you save", systemImage: "checklist.checked")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text("Add a quick self-check so Review can show what felt easier for the listener, not just what changed in the transcript.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            scoreRow(
                title: "Listener caught the main point",
                score: appViewModel.draftReflectionListenerCatchScore,
                action: { appViewModel.draftReflectionListenerCatchScore = $0 }
            )

            scoreRow(
                title: "Pace stayed under control",
                score: appViewModel.draftReflectionPaceControlScore,
                action: { appViewModel.draftReflectionPaceControlScore = $0 }
            )

            scoreRow(
                title: "Confidence sounded believable",
                score: appViewModel.draftReflectionConfidenceScore,
                action: { appViewModel.draftReflectionConfidenceScore = $0 }
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Where did it get sticky?")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appViewModel.stickyMomentOptions(for: appViewModel.currentMission), id: \.self) { option in
                            Button(option) {
                                appViewModel.draftReflectionStickyMoment = option
                            }
                            .modifier(KatieActionChipStyle(
                                background: appViewModel.draftReflectionStickyMoment == option ? KatieColors.accent : KatieColors.cardSecondary,
                                foreground: appViewModel.draftReflectionStickyMoment == option ? .black : KatieColors.textPrimary,
                                horizontalPadding: 10
                            ))
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .katieCard()
    }

    private func scoreRow(title: String, score: Int, action: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button(String(value)) {
                        action(value)
                    }
                    .modifier(KatieActionChipStyle(
                        background: score == value ? KatieColors.accent : KatieColors.cardSecondary,
                        foreground: score == value ? .black : KatieColors.textPrimary,
                        horizontalPadding: 10
                    ))
                }
            }
        }
    }

    private var practiceReviewMenu: some View {
        Menu {
                        Button("Open progress") {
                            appViewModel.openProgress(for: appViewModel.currentMission)
                        }

            if let anchor = appViewModel.selectedCompareAnchor,
               appViewModel.hasPlayback(for: anchor) {
                Button(appViewModel.currentlyPlayingSessionID == anchor.id ? "Stop baseline" : "Play baseline") {
                    if appViewModel.currentlyPlayingSessionID == anchor.id {
                        appViewModel.stopPlayback()
                    } else {
                        appViewModel.playSession(anchor)
                    }
                }
            }

            if appViewModel.hasPlayback(for: appViewModel.latestSession) {
                Button(appViewModel.currentlyPlayingSessionID == appViewModel.latestSession.id ? "Stop replay" : "Play replay") {
                    if appViewModel.currentlyPlayingSessionID == appViewModel.latestSession.id {
                        appViewModel.stopPlayback()
                    } else {
                        appViewModel.playSession(appViewModel.latestSession)
                    }
                }
            }
        } label: {
            Label("Peek", systemImage: "ellipsis.circle")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func practiceScenarioMenu(for scenario: PracticeScenario, isLockedByRecording: Bool) -> some View {
        Menu {
            Button(practiceReminderActionTitle(for: scenario)) {
                handlePracticeReminderAction(for: scenario)
            }

            Button("Open progress") {
                appViewModel.openProgress(for: scenario)
            }
        } label: {
            Label("Browse", systemImage: "ellipsis.circle")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(KatieColors.cardBackground.opacity(0.9))
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isLockedByRecording)
    }

    private func practiceReminderActionTitle(for scenario: PracticeScenario) -> String {
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

    private func practiceReminderActionBackground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? KatieColors.accent
            : KatieColors.cardBackground.opacity(0.9)
    }

    private func practiceReminderActionForeground(for scenario: PracticeScenario) -> Color {
        appViewModel.reminderPlan?.scenario == scenario
            ? .black
            : KatieColors.textPrimary
    }

    private func practiceScenarioReviewAnchor(for scenario: PracticeScenario) -> PracticeSession? {
        let history = appViewModel.scenarioHistories[scenario] ?? []
        let latest = history.first(where: \.isUserOwned) ?? history.first
        guard let latest else { return nil }

        let compareAnchor = history.dropFirst().first(where: \.isUserOwned)
        return compareAnchor ?? latest
    }

    private func practiceScenarioReviewActionTitle(for scenario: PracticeScenario, anchor: PracticeSession) -> String {
        let history = appViewModel.scenarioHistories[scenario] ?? []
        let latest = history.first(where: \.isUserOwned) ?? history.first
        guard let latest else { return "Open proof" }
        return anchor.id == latest.id ? "Open proof" : "Open compare"
    }

    private func handlePracticeReminderAction(for scenario: PracticeScenario) {
        appViewModel.selectScenario(scenario)

        if appViewModel.reminderPermissionState == .denied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
            return
        }

        appViewModel.scheduleOrDismissReminder()
    }

    private var practiceReminderOwnerLabel: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Reminder owner: none yet"
        }

        return "Reminder owner: \(reminderPlan.scenario.packTitle) · \(reminderPlan.fireDate.formatted(date: .omitted, time: .shortened))"
    }

    private var practiceReminderOwnerDetail: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "Save one line you trust, then turn on a reminder only when you want Katie protecting this pack next."
        }

        if reminderPlan.scenario == appViewModel.currentMission {
            return "The next nudge is protecting this pack, so Practice, Today, and Review are pointing at the same line."
        }

        return "This pack stays visible in Practice, but the next nudge is currently protecting \(reminderPlan.scenario.packTitle). Move it here when this is the line you want back next."
    }

    private var practiceReminderOwnerSystemImage: String {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return "bell.slash"
        }

        return reminderPlan.scenario == appViewModel.currentMission ? "bell.badge.fill" : "bell.badge"
    }

    private var practiceReminderOwnerAccent: Color {
        guard let reminderPlan = appViewModel.reminderPlan else {
            return KatieColors.textSecondary
        }

        return reminderPlan.scenario == appViewModel.currentMission ? KatieColors.accent : KatieColors.gold
    }

    private var reminderContinuityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminder continuity")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Protected line", systemImage: "text.quote")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)
                            Text(appViewModel.latestSession.protectedLine)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Label("Listener outcome", systemImage: "ear.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.gold)
                            Text(appViewModel.currentMission.listenerOutcome)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Label("Next grounded move", systemImage: "figure.walk")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.accent)
                            Text(appViewModel.currentPackNextStepLabel)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                    }

                    Label(practiceReminderOwnerLabel, systemImage: practiceReminderOwnerSystemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(practiceReminderOwnerAccent)

                    Text(practiceReminderOwnerDetail)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: practiceReminderOwnerSystemImage)
                        .font(.title3)
                        .foregroundStyle(practiceReminderOwnerAccent)

                    Button("Peek") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            isReminderOptionsPresented = true
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)
                    .popover(isPresented: $isReminderOptionsPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                        reminderOptionsPopover
                    }
                }
            }

            Label(appViewModel.reminderPermissionState.title, systemImage: appViewModel.reminderPermissionState.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.reminderStatusLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(appViewModel.reminderToneLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(appViewModel.reminderClinicalBoundaryLine)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            if appViewModel.remindersEnabled {
                HStack(spacing: 8) {
                    ForEach(appViewModel.reminderQuickPresets) { preset in
                        reminderQuickPresetButton(title: preset.title, date: preset.fireDate)
                    }
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text(appViewModel.remindersEnabled ? "Tap Peek for tone and exact time." : "Turn reminders on, then use Peek to tune the timing.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            HStack(spacing: 10) {
                Button(appViewModel.reminderButtonTitle) {
                    if appViewModel.reminderPermissionState == .denied {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                        return
                    }
                    appViewModel.scheduleOrDismissReminder()
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(appViewModel.remindersEnabled ? KatieColors.accent : KatieColors.cardSecondary)
                .foregroundStyle(appViewModel.remindersEnabled ? .black : KatieColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if appViewModel.remindersEnabled {
                    Label(appViewModel.reminderDraftTimeLabel, systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(KatieColors.cardSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .trailing)))
                }
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: appViewModel.remindersEnabled)
        .katieCard()
    }

    private func stepProgressCard(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenario step flow")
                .font(.headline)

            Text(appViewModel.currentMission.structurePrompt)
                .foregroundStyle(KatieColors.mint)

            KatieWrap(spacing: 10, rowSpacing: 10) {
                ForEach(Array(appViewModel.currentMission.stepLabels.enumerated()), id: \.offset) { index, label in
                    let isRecommended = index == appViewModel.recommendedPracticeStep
                    let isActive = index == appViewModel.activePracticeStep
                    let isReached = appViewModel.activePracticeStep >= index

                    Button {
                        appViewModel.setActivePracticeStep(index)
                    } label: {
                        HStack(spacing: 6) {
                            Text(label)

                            if isRecommended {
                                Image(systemName: "flag.fill")
                                    .font(.caption2.weight(.bold))
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(isActive ? Color.black : isReached ? KatieColors.textPrimary : KatieColors.textSecondary)
                        .background(isActive ? KatieColors.accent : isReached ? KatieColors.accent.opacity(0.25) : KatieColors.cardSecondary)
                        .overlay(
                            Capsule()
                                .stroke(isRecommended && !isActive ? KatieColors.mint : Color.clear, lineWidth: 1.5)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if appViewModel.activePracticeStep != appViewModel.recommendedPracticeStep {
                Button {
                    appViewModel.focusRecommendedPracticeStep()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                        Text("Jump back to recommended step: \(appViewModel.recommendedPracticeStepLabel)")
                            .lineLimit(2)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.mint)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appViewModel.activePracticeStepProgressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                Text(appViewModel.activePracticeStepLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(appViewModel.activePracticeStepPrompt)
                    .font(.subheadline)
                    .foregroundStyle(KatieColors.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 10) {
                Button("Back") {
                    appViewModel.moveToPreviousPracticeStep()
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.cardSecondary)
                .foregroundStyle(KatieColors.textPrimary)
                .clipShape(Capsule())
                .disabled(!appViewModel.canMoveToPreviousPracticeStep)
                .opacity(appViewModel.canMoveToPreviousPracticeStep ? 1 : 0.45)

                Button(appViewModel.canMoveToNextPracticeStep ? "Next step" : "Step flow complete") {
                    if appViewModel.canMoveToNextPracticeStep {
                        appViewModel.moveToNextPracticeStep()
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KatieColors.accent.opacity(appViewModel.canMoveToNextPracticeStep ? 1 : 0.2))
                .foregroundStyle(appViewModel.canMoveToNextPracticeStep ? .black : KatieColors.textSecondary)
                .clipShape(Capsule())
                .disabled(!appViewModel.canMoveToNextPracticeStep)
            }
            .onChange(of: appViewModel.practiceReturnCue) { cue in
                guard cue != nil else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("practice-top", anchor: .top)
                }
            }
        }
    }

    private func handlePrimaryCaptureAction(proxy: ScrollViewProxy) {
        if appViewModel.isRecording {
            withAnimation(.spring()) {
                appViewModel.toggleRecording()
            }
            return
        }

        if isMicrophoneDenied {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRetakeDraftExpanded = true
            }
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(practiceDraftAnchor, anchor: .center)
                }
            }
            return
        }

        withAnimation(.spring()) {
            appViewModel.toggleRecording()
        }
    }

    private func reminderQuickPresetButton(title: String, date: Date) -> some View {
        Button(title) {
            appViewModel.updateReminderTime(date)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(KatieColors.cardSecondary)
        .foregroundStyle(KatieColors.textPrimary)
        .clipShape(Capsule())
    }

    private var reminderOptionsPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reminder options")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Pick a tone, then park the nudge on the exact work window.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(appViewModel.reminderClinicalBoundaryLine)
                .font(.caption)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Tone")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                KatieWrap(spacing: 8, rowSpacing: 8) {
                    ForEach(ReminderTone.allCases) { tone in
                        Button(tone.title) {
                            appViewModel.setReminderTone(tone)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(appViewModel.reminderTone == tone ? KatieColors.accent.opacity(0.25) : KatieColors.cardSecondary)
                        .foregroundStyle(appViewModel.reminderTone == tone ? KatieColors.textPrimary : KatieColors.textSecondary)
                        .clipShape(Capsule())
                    }
                }
            }

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

                    if usesWideReminderPresetLayout {
                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.reminderQuickPresets) { preset in
                                reminderQuickPresetButton(title: preset.title, date: preset.fireDate)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(appViewModel.reminderQuickPresets) { preset in
                                    reminderQuickPresetButton(title: preset.title, date: preset.fireDate)
                                }
                            }
                        }
                    }

                    Text("Park it on the exact conversation window you want to protect on \(reminderSurfaceLabel).")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview notification")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(appViewModel.reminderPreviewTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.accent)

                Text(appViewModel.reminderPreviewBody)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Text(appViewModel.reminderPreviewScheduleLine)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .frame(width: usesWideReminderPresetLayout ? 420 : 320)
        .presentationCompactAdaptation(.popover)
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
    PracticeRecordView()
        .environmentObject(AppViewModel())
}
