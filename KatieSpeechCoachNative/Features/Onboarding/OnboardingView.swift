import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        GeometryReader { proxy in
            let isWideLayout = proxy.size.width >= 920
            let contentBottomPadding: CGFloat = isWideLayout ? 128 : 24
            // KAT-286 fix: the original `maxWidth: 760` was larger than an iPhone
            // 17 screen (~402pt). The inner content then over-flowed the right
            // edge of every card. Cap the content width to the actual screen
            // width on iPhone, and keep the wide 1160pt for iPad / Mac mirroring.
            let contentMaxWidth: CGFloat = isWideLayout
                ? 1160
                : min(760, proxy.size.width - 32)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard(isWideLayout: isWideLayout)

                    recommendedFirstRepStrip(isWideLayout: isWideLayout)

                    if isWideLayout {
                        HStack(alignment: .top, spacing: 18) {
                            VStack(alignment: .leading, spacing: 16) {
                                profileCard
                                contextCard
                                goalCard
                                focusSnapshotCard
                                hypothesisCheckCard(isWideLayout: isWideLayout)
                                recommendedScenarioCard
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                            VStack(alignment: .leading, spacing: 16) {
                                valuesCard
                                captureTrustCard
                                startingPackPreviewCard
                                speakingPacksCard
                                firstWinHandoffCard
                                continuityCard
                                listeningCard
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            profileCard
                            contextCard
                            goalCard
                            valuesCard
                            captureTrustCard
                            focusSnapshotCard
                            hypothesisCheckCard(isWideLayout: isWideLayout)
                            startingPackPreviewCard
                            recommendedScenarioCard
                            speakingPacksCard
                            firstWinHandoffCard
                            continuityCard
                            listeningCard
                        }
                    }

                    Spacer(minLength: 12)

                    if !isWideLayout {
                        bottomCTA(isWideLayout: false)
                    }
                }
                .padding(isWideLayout ? 24 : 16)
                .padding(.bottom, contentBottomPadding)
                .katieContentFrame(maxWidth: contentMaxWidth)
            }
            .safeAreaInset(edge: .bottom) {
                if isWideLayout {
                    bottomCTA(isWideLayout: true)
                }
            }
            .background(appBackground)
            .navigationBarHidden(true)
        }
    }

    private var appBackground: some View {
        LinearGradient(
            colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [KatieColors.appBackgroundGlow, KatieColors.appBackgroundGlowSecondary, .clear],
                center: .topLeading,
                startRadius: 8,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private func heroCard(isWideLayout: Bool) -> some View {
        VStack(alignment: .leading, spacing: isWideLayout ? 18 : 16) {
            if isWideLayout {
                HStack(alignment: .top, spacing: 16) {
                    KatieScenarioArtwork(
                        systemImage: "message.and.waveform.fill",
                        accent: KatieColors.accent,
                        secondary: KatieColors.mint
                    )
                    .frame(width: 84, height: 84)

                    VStack(alignment: .leading, spacing: 10) {
                        heroLeadCopy(isWideLayout: isWideLayout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    KatieScenarioArtwork(
                        systemImage: "message.and.waveform.fill",
                        accent: KatieColors.accent,
                        secondary: KatieColors.mint
                    )
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 10) {
                        heroLeadCopy(isWideLayout: isWideLayout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isWideLayout {
                HStack(alignment: .top, spacing: 16) {
                    heroPromiseCard(isWideLayout: isWideLayout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    heroStartingCard
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    heroPromiseCard(isWideLayout: isWideLayout)
                    heroStartingCard
                }
            }
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.accent, secondary: KatieColors.mint)
    }

    private func heroLeadCopy(isWideLayout: Bool) -> some View {
        Group {
            // OPE-132: brighter eyebrow so "First sample setup" reads on first screen
            // (audit: "First sample setup" badge was dark-on-dark — gold opacity was
            // washed out against cardSecondary. Bumped accent opacity 0.28 → 0.55,
            // gradient end to a brighter tertiary tint, and added a soft text shadow
            // for legibility on the deep purple hero card.)
            KatieSectionEyebrow(
                title: "First sample setup",
                systemImage: "sparkles",
                accent: KatieColors.gold,
                fillOpacity: 0.55,
                endTint: KatieColors.cardTertiary.opacity(0.85),
                strokeOpacity: 0.55
            )

            Text("Katie")
                .font(isWideLayout ? .system(size: 44, weight: .bold, design: .rounded) : .largeTitle.bold())
                .foregroundStyle(KatieColors.textPrimary)

            // OPE-132: plain-language subtitle (audit: "SLP-informed" is clinical
            // jargon — Katie coaches how your listener hears you, not a clinical
            // model). Keep it compact on phones so the hero never bleeds off the
            // right edge.
            VStack(alignment: .leading, spacing: 4) {
                Text("A coach for clearer work moments.")
                Text("No accent erasure.")
            }
            .font(isWideLayout ? .title3.weight(.semibold) : .callout.weight(.semibold))
            .foregroundStyle(KatieColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)

            Text("Work speaking · local-first")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            // OPE-132 + KAT-155: privacy chip on the first screen, not just the
            // first-recording surface. Audit: "Your recordings stay on this iPhone"
            // was invisible until after onboarding. Same capsule style as
            // FirstBaselineView, sized for the hero row.
            privacyChip()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func heroPromiseCard(isWideLayout: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Katie coaches")
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text("Interviews, updates, presentations, and customer conversations, with feedback tied to the moment that matters.")
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: isWideLayout ? 560 : .infinity, alignment: .leading)

            LazyVGrid(
                columns: isWideLayout
                    ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                    : [GridItem(.flexible(), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                heroFeatureTile(
                    title: "Listener-first feedback",
                    detail: "Katie keeps the first listen easy to follow.",
                    systemImage: "ear.fill",
                    accent: KatieColors.mint
                )
                heroFeatureTile(
                    title: "Identity intact",
                    detail: "Clarity and confidence, not accent erasure.",
                    systemImage: "heart.text.square.fill",
                    accent: KatieColors.blush
                )
                heroFeatureTile(
                    title: "Proof over pep talks",
                    detail: "Your first save becomes the benchmark.",
                    systemImage: "person.crop.circle.badge.checkmark",
                    accent: KatieColors.gold
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [KatieColors.cardSecondary.opacity(0.94), KatieColors.cardBackground.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(KatieColors.cardSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var heroStartingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Starting today")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.learnerProfile.focusScenario.packTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                    Text(appViewModel.learnerProfile.focusScenario.listenerOutcome)
                        .font(.callout)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 8)

                KatieScenarioArtwork(
                    systemImage: "square.grid.2x2.fill",
                    accent: KatieColors.gold,
                    secondary: KatieColors.plum
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                startingStepRow(
                    title: "Goal focus",
                    detail: appViewModel.goalFocusTitle,
                    systemImage: "target",
                    accent: KatieColors.gold
                )

                startingStepRow(
                    title: "First structure",
                    detail: appViewModel.learnerProfile.focusScenario.structurePrompt,
                    systemImage: "point.3.connected.trianglepath.dotted",
                    accent: KatieColors.mint
                )

                startingStepRow(
                    title: "Sound focus",
                    detail: appViewModel.languageAssessmentSnapshot.soundFocus,
                    systemImage: "dot.radiowaves.left.and.right",
                    accent: KatieColors.blush
                )

                startingStepRow(
                    title: "Capture path",
                    detail: appViewModel.audioCaptureLane.title,
                    systemImage: appViewModel.audioCaptureLane.systemImage,
                    accent: KatieColors.gold
                )
            }

            Button {
                appViewModel.completeOnboarding()
            } label: {
                HStack(spacing: 8) {
                    Text("Start \(appViewModel.learnerProfile.focusScenario.packTitle)")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(KatieColors.cardSecondary.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KatieColors.cardBorder.opacity(0.9), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(KatieColors.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [KatieColors.accent.opacity(0.14), KatieColors.cardSecondary.opacity(0.96), KatieColors.cardBackground.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(KatieColors.accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func heroFeatureTile(title: String, detail: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .katieIconBadge(background: KatieColors.cardSecondary, foreground: accent, size: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(KatieColors.cardBorder.opacity(0.75), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func startingStepRow(title: String, detail: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .katieIconBadge(background: KatieColors.cardSecondary, foreground: accent, size: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
                    .tracking(0.35)

                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary.opacity(0.56))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(KatieColors.cardBorder.opacity(0.75), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                eyebrow: "Your setup",
                title: "Add enough context for a believable first coaching pass",
                detail: "Katie uses your role, language background, and work context to frame the first sample without boxing you into a stereotype."
            )

            TextField("First name", text: profileBinding(\.firstName))
                .katieInput()

            TextField("Role", text: profileBinding(\.role))
                .katieInput()

            TextField("First language", text: profileBinding(\.firstLanguage))
                .katieInput()

            TextField("Other languages", text: profileBinding(\.otherLanguages))
                .katieInput()

            Text("Your language background helps Katie choose a better starting focus. It starts with patterns in your own speech, not labels.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            // KAT-288 labeled block (preserved) + KAT-290 shorter text.
            // The full ASHA-aligned scope + clinical handoff lives in
            // CoachTrustView (see KAT-292 follow-up). This block gives a
            // short, second-language-readable signal that Katie is coaching,
            // not therapy or diagnosis, before the learner finishes setup.
            KatieInlineNotice(
                title: "What Katie is — and is not",
                message: appViewModel.trustBoundaryLine,
                systemImage: "checkmark.shield.fill",
                accent: KatieColors.gold
            )
        }
        .katieCard()
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                eyebrow: "Work context",
                title: "Tune the first listener-pressure lane",
                detail: "A tighter first lane helps Katie make the first proof feel grounded instead of generic."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Where this usually matters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Picker(
                    "Communication environment",
                    selection: Binding(
                        get: { appViewModel.learnerProfile.communicationEnvironment },
                        set: {
                            appViewModel.learnerProfile.communicationEnvironment = $0
                            appViewModel.persistOnboardingProfileDraft()
                        }
                    )
                ) {
                    ForEach(CommunicationEnvironment.allCases) { environment in
                        Text(environment.title).tag(environment)
                    }
                }
                .pickerStyle(.menu)

                Text(appViewModel.communicationEnvironmentDetail)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Picker(
                    "Listener pressure",
                    selection: Binding(
                        get: { appViewModel.learnerProfile.listenerPressure },
                        set: {
                            appViewModel.learnerProfile.listenerPressure = $0
                            appViewModel.persistOnboardingProfileDraft()
                        }
                    )
                ) {
                    ForEach(ListenerPressure.allCases) { pressure in
                        Text(pressure.title).tag(pressure)
                    }
                }
                .pickerStyle(.menu)

                Text(appViewModel.listenerPressureDetail)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Picker(
                    "When pressure rises, what do listeners miss first?",
                    selection: Binding(
                        get: { appViewModel.learnerProfile.listenerFrictionPoint },
                        set: { appViewModel.updateListenerFrictionPoint($0) }
                    )
                ) {
                    ForEach(ListenerFrictionPoint.allCases) { frictionPoint in
                        Text(frictionPoint.title).tag(frictionPoint)
                    }
                }
                .pickerStyle(.menu)

                Text(appViewModel.listenerFrictionPointDetail)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .katieCard()
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                eyebrow: "Goal framing",
                title: "Choose the first communication win",
                detail: "Katie starts with one visible change worth protecting before it widens into pacing, polish, and replay depth."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Primary communication goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Menu {
                    ForEach(appViewModel.goalPresets) { preset in
                        Button {
                            appViewModel.applyGoalPreset(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                Text(preset.detail)
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appViewModel.goalFocusTitle)
                                .foregroundStyle(KatieColors.textPrimary)
                            Text(appViewModel.goalFocusDetail)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .padding(14)
                    .background(
                        LinearGradient(
                            colors: [KatieColors.cardSecondary, KatieColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(KatieColors.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                TextField(
                    "Refine goal in your own words",
                    text: Binding(
                        get: { appViewModel.learnerProfile.firstGoal },
                        set: { appViewModel.updateGoalFocus($0) }
                    )
                )
                .katieInput()

                Text("Katie starts with the sound pattern you want to change first. Pacing and stress can come later once the core pattern is clearer.")
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            Picker(
                "Starting pack",
                selection: Binding(
                    get: { appViewModel.learnerProfile.focusScenario },
                    set: { appViewModel.updateFocusScenario($0) }
                )
            ) {
                ForEach(startingMissionPickerScenarios) { scenario in
                    Text(startingMissionPickerLabel(for: scenario)).tag(scenario)
                }
            }
            .pickerStyle(.menu)
        }
        .katieCard()
    }

    private var startingMissionPickerScenarios: [PracticeScenario] {
        let recommended = appViewModel.recommendedScenarioForCurrentContext
        return appViewModel.availableScenarios
            .enumerated()
            .sorted { lhs, rhs in
                let lhsRank = lhs.element == recommended ? 0 : 1
                let rhsRank = rhs.element == recommended ? 0 : 1
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private func startingMissionPickerLabel(for scenario: PracticeScenario) -> String {
        if scenario == appViewModel.recommendedScenarioForCurrentContext {
            return "\(scenario.packTitle) · \(scenario.title)"
        }

        return "\(scenario.packTitle) · \(scenario.categoryLabel)"
    }

    private var captureTrustCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Capture trust",
                title: appViewModel.audioCaptureLane.title,
                detail: "Item 2 stays explicit here: real on-device capture is available when needed, and text-only fallback stays visible when it is not."
            )

            Label(appViewModel.audioCaptureLane.detail, systemImage: appViewModel.audioCaptureLane.systemImage)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            KatieWrap(spacing: 8, rowSpacing: 8) {
                Text(appViewModel.audioCaptureLane.actionTitle)
                    .modifier(KatieCapsuleLabelStyle(accent: KatieColors.mint))
                Text(appViewModel.microphoneStatusLine)
                    .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
            }
        }
        .katieCard()
    }

    private var valuesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: "Trust + boundaries",
                title: "Set the tone before the first recording",
                detail: "The app should feel warm and premium without making credibility feel fuzzy."
            )

            VStack(alignment: .leading, spacing: 10) {
                valueRow(title: "Built for work speaking, not one scenario", systemImage: "briefcase.fill", accent: KatieColors.gold)
                valueRow(title: "No accent-erasure promise", systemImage: "heart.text.square.fill", accent: KatieColors.blush)
                valueRow(title: "Microphone permission only when needed", systemImage: "mic.fill", accent: KatieColors.mint)
                valueRow(title: "Local-first by default", systemImage: "icloud.slash.fill", accent: KatieColors.plum)
            }
        }
        .katieCard()
    }

    private func valueRow(title: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .katieIconBadge(background: KatieColors.cardSecondary, foreground: accent, size: 32)
            Text(title)
                .foregroundStyle(KatieColors.textSecondary)
        }
    }

    private var focusSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Starting hypothesis",
                title: appViewModel.languageAssessmentSnapshot.title,
                detail: appViewModel.profileContextTrustLine
            )

            Text(appViewModel.languageAssessmentSnapshot.caveat)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Label(appViewModel.languageAssessmentSnapshot.transferPattern, systemImage: "arrow.triangle.branch")
                Label(appViewModel.languageAssessmentSnapshot.soundFocus, systemImage: "dot.radiowaves.left.and.right")
            }
            .foregroundStyle(KatieColors.textSecondary)

            Text("Later, Katie may also help with pacing and stress: \(appViewModel.languageAssessmentSnapshot.prosodyFocus)")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private func hypothesisCheckCard(isWideLayout: Bool) -> some View {
        let choiceColumns = isWideLayout
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible(), spacing: 12)]

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                eyebrow: "Self-check",
                title: "Does that sound like your real speaking under pressure?",
                detail: "Pick how much weight Katie should give this cue before your first saved rep."
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        KatieSectionEyebrow(title: "Starter cue live now", systemImage: "sparkles", accent: KatieColors.mint)

                        Text(appViewModel.transferHypothesisStatusTitle)
                            .font(.headline)
                            .foregroundStyle(KatieColors.textPrimary)

                        Text("Katie uses this as a starting stance in \(appViewModel.learnerProfile.focusScenario.packTitle) until your first saved sample proves what actually helps the listener most.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 10) {
                        Text(appViewModel.goalFocusTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(KatieColors.cardBackground.opacity(0.9), in: Capsule())

                        Image(systemName: selectedTransferHypothesisFeedback.systemImage)
                            .font(.headline)
                            .foregroundStyle(KatieColors.mint)
                            .padding(12)
                            .background(KatieColors.cardBackground, in: Circle())
                    }
                }

                if isWideLayout {
                    HStack(alignment: .top, spacing: 12) {
                        starterTrustCard(
                            title: "Before first save",
                            detail: appViewModel.transferHypothesisPracticeBridgeLine,
                            systemImage: "sparkles.rectangle.stack.fill",
                            accent: KatieColors.gold
                        )

                        starterTrustCard(
                            title: "After first save",
                            detail: appViewModel.transferHypothesisFollowThroughLine,
                            systemImage: "waveform.path.ecg",
                            accent: KatieColors.mint
                        )
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        starterTrustCard(
                            title: "Before first save",
                            detail: appViewModel.transferHypothesisPracticeBridgeLine,
                            systemImage: "sparkles.rectangle.stack.fill",
                            accent: KatieColors.gold
                        )

                        starterTrustCard(
                            title: "After first save",
                            detail: appViewModel.transferHypothesisFollowThroughLine,
                            systemImage: "waveform.path.ecg",
                            accent: KatieColors.mint
                        )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [KatieColors.cardSecondary.opacity(0.92), KatieColors.cardBackground.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(KatieColors.mint.opacity(0.18), lineWidth: 1)
                    )
            )

            Text("Choose the starting stance that feels closest right now")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)

            LazyVGrid(columns: choiceColumns, alignment: .leading, spacing: 12) {
                ForEach(TransferHypothesisFeedback.allCases) { feedback in
                    Button {
                        updateTransferHypothesisFeedback(feedback)
                    } label: {
                        let isSelected = selectedTransferHypothesisFeedback == feedback

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: feedback.systemImage)
                                    .katieIconBadge(
                                        background: isSelected ? KatieColors.accent.opacity(0.24) : KatieColors.cardBackground,
                                        foreground: isSelected ? KatieColors.textPrimary : KatieColors.mint,
                                        size: 34
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feedback.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(KatieColors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(feedback.detail)
                                        .font(.footnote)
                                        .foregroundStyle(KatieColors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 8)
                            }

                            HStack(spacing: 8) {
                                Text(isSelected ? "Active now" : "Tap to use")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(isSelected ? KatieColors.textOnAccent : KatieColors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? KatieColors.accent : KatieColors.cardBackground, in: Capsule())

                                Spacer(minLength: 0)

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(KatieColors.accent)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
                        .background(isSelected ? KatieColors.cardBackground.opacity(0.92) : KatieColors.cardSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? KatieColors.accent.opacity(0.75) : KatieColors.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .katieCard()
    }

    // OPE-132 + KAT-155: privacy chip used on the first screen (hero card).
    // Mirrors the FirstBaselineView chip styling so the privacy signal is
    // consistent from the very first tap. Mint accent reads as "safe" and
    // "local" without leaning on copy-heavy framing.
    private func privacyChip() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(KatieColors.mint)
            Text("Recordings stay on this iPhone.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KatieColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(KatieColors.mint.opacity(0.14), in: Capsule())
        .overlay(
            Capsule().stroke(KatieColors.mint.opacity(0.40), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Privacy: recordings stay on this iPhone.")
    }

    private func recommendedFirstRepStrip(isWideLayout: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    KatieSectionEyebrow(title: "Recommended first rep", systemImage: "sparkles", accent: KatieColors.mint)

                    Text("Turn the starter cue into your own proof")
                        .font(isWideLayout ? .title3.weight(.semibold) : .headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("One saved sample in \(appViewModel.learnerProfile.focusScenario.packTitle) is the moment Katie stops leaning on setup copy and starts coaching from evidence you actually own.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isWideLayout {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(appViewModel.learnerProfile.focusScenario.packTitle)
                            .modifier(KatieCapsuleLabelStyle())

                        Text(appViewModel.goalFocusTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(KatieColors.cardBackground.opacity(0.92), in: Capsule())
                    }
                }
            }

            if isWideLayout {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        onboardingImpactChip(title: "Today opens with your own benchmark", systemImage: "sun.max.fill", accent: KatieColors.mint)
                        onboardingImpactChip(title: "Review compares against a real saved line", systemImage: "rectangle.on.rectangle.fill", accent: KatieColors.accent)
                        onboardingImpactChip(title: "Reminders can point back to the exact rep", systemImage: "bell.badge.fill", accent: KatieColors.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            appViewModel.completeOnboarding()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Set up first sample")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(KatieColors.cardBackground.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(KatieColors.cardBorder.opacity(0.9), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(KatieColors.textPrimary)

                        Label(appViewModel.microphoneStatusLine, systemImage: appViewModel.microphonePermissionState.systemImage)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    onboardingImpactChip(title: "Today opens with your own benchmark", systemImage: "sun.max.fill", accent: KatieColors.mint)
                    onboardingImpactChip(title: "Review compares against a real saved line", systemImage: "rectangle.on.rectangle.fill", accent: KatieColors.accent)
                    onboardingImpactChip(title: "Reminders can point back to the exact rep", systemImage: "bell.badge.fill", accent: KatieColors.gold)

                    Button {
                        appViewModel.completeOnboarding()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Set up first sample")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(KatieColors.cardBackground.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(KatieColors.cardBorder.opacity(0.9), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(KatieColors.textPrimary)

                    Label(appViewModel.microphoneStatusLine, systemImage: appViewModel.microphonePermissionState.systemImage)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .katieCard()
        .katieHeroAura(accent: KatieColors.gold, secondary: KatieColors.mint)
    }

    private var startingPackPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Pack preview",
                title: appViewModel.learnerProfile.focusScenario.packTitle,
                detail: appViewModel.learnerProfile.focusScenario.listenerOutcome
            )

            VStack(alignment: .leading, spacing: 8) {
                Label("Structure to protect first: \(appViewModel.learnerProfile.focusScenario.structurePrompt)", systemImage: "point.3.connected.trianglepath.dotted")
                Label("First listener-critical step: \(appViewModel.learnerProfile.focusScenario.stepLabels.first ?? appViewModel.learnerProfile.focusScenario.title)", systemImage: "flag.fill")
                Label("Sound focus first: \(appViewModel.languageAssessmentSnapshot.soundFocus)", systemImage: "dot.radiowaves.left.and.right")
                Label("Listener friction to watch: \(appViewModel.listenerFrictionPointTitle)", systemImage: "ear.fill")
                Label(appViewModel.transferHypothesisPreviewLine, systemImage: selectedTransferHypothesisFeedback.systemImage)
                Label("Pacing and stress come later, once the core pattern is steadier", systemImage: "waveform.path")
            }
            .font(.footnote)
            .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var recommendedScenarioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Recommended lane",
                title: appViewModel.recommendedScenarioForCurrentContext.packTitle,
                detail: appViewModel.recommendedScenarioReason
            )

            Text(appViewModel.recommendedScenarioLaneLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.mint)

            Text(appViewModel.recommendedScenarioAlignmentLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Text(appViewModel.recommendedScenarioCoachOrderLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Button(appViewModel.isRecommendedScenarioAlignedForStartingPack ? "Starting pack already matches" : "Use this as my starting pack") {
                appViewModel.alignRecommendedScenarioAcrossExperience()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.cardSecondary : KatieColors.accent)
            .foregroundStyle(appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.textPrimary : KatieColors.textOnAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(appViewModel.isRecommendedScenarioAlignedForStartingPack)
        }
        .katieCard()
    }

    private var speakingPacksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Full surface area",
                title: "Speaking packs in Katie",
                detail: "Katie should feel broader than interviews from the first tap, so every pack stays visible during setup."
            )

            ForEach(appViewModel.availableScenarios) { scenario in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.packTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                            Text(scenario.listenerOutcome)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }

                        Spacer(minLength: 8)

                        if scenario == appViewModel.recommendedScenarioForCurrentContext {
                            Text("Recommended")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KatieColors.mint.opacity(0.18))
                                .clipShape(Capsule())
                        }

                        if scenario == appViewModel.learnerProfile.focusScenario {
                            Text("Starting")
                                .modifier(KatieCapsuleLabelStyle())
                        }
                    }

                    Label("Structure: \(scenario.structurePrompt)", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.caption)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(scenario.positioningLine)
                        .font(.caption)
                        .foregroundStyle(KatieColors.textSecondary)

                    KatieWrap(spacing: 8, rowSpacing: 8) {
                        ForEach(scenario.realLifeMoments, id: \.self) { moment in
                            Text(moment)
                                .modifier(KatieCapsuleLabelStyle(accent: KatieColors.gold))
                        }
                    }

                    Button(scenario == appViewModel.learnerProfile.focusScenario ? "Current starting pack" : "Set as starting pack") {
                        appViewModel.updateFocusScenario(scenario)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(scenario == appViewModel.learnerProfile.focusScenario ? KatieColors.cardBackground : KatieColors.cardSecondary)
                    .foregroundStyle(scenario == appViewModel.learnerProfile.focusScenario ? KatieColors.textSecondary : KatieColors.textPrimary)
                    .clipShape(Capsule())
                    .disabled(scenario == appViewModel.learnerProfile.focusScenario)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.gold, secondary: KatieColors.mint)
    }

    private var firstWinHandoffCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                eyebrow: "Handoff",
                title: "Land one real proof before the premium loop expands",
                detail: "Next, you’ll save one personal sample in your starting pack so compare, reminders, and premium framing can point to your own proof."
            )

            VStack(alignment: .leading, spacing: 10) {
                Label("Your first saved rep becomes the real benchmark", systemImage: "person.crop.circle.badge.checkmark")
                Label("Starter proof stays visible, but secondary", systemImage: "sparkles.rectangle.stack.fill")
                Label("Save one real rep before premium features unlock", systemImage: "crown.fill")
            }
            .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(appViewModel.premiumExperimentSurfaces) { experiment in
                    VStack(alignment: .leading, spacing: 6) {
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
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .katieCard()
    }

    private var continuityCard: some View {
        KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)
    }

    private var listeningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                eyebrow: "Coaching order",
                title: "What Katie listens for",
                detail: "Sound patterns first. Pacing and stress come later, once the core sound is steady."
            )
        }
        .katieCard()
    }

    private func sectionHeader(eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            KatieSectionEyebrow(title: eyebrow, systemImage: "sparkles", accent: KatieColors.gold)

            Text(title)
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
    }

    private func starterTrustCard(title: String, detail: String, systemImage: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func onboardingImpactChip(title: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .katieIconBadge(background: KatieColors.cardBackground, foreground: accent, size: 28)

            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KatieColors.cardSecondary.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(KatieColors.cardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    private var selectedTransferHypothesisFeedback: TransferHypothesisFeedback {
        appViewModel.learnerProfile.transferHypothesisFeedback
    }

    private func updateTransferHypothesisFeedback(_ feedback: TransferHypothesisFeedback) {
        guard appViewModel.learnerProfile.transferHypothesisFeedback != feedback else { return }
        appViewModel.learnerProfile.transferHypothesisFeedback = feedback
        appViewModel.persistOnboardingProfileDraft()
    }

    private func bottomCTA(isWideLayout: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: isWideLayout ? 12 : 10) {
                if isWideLayout {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Starting with \(appViewModel.learnerProfile.focusScenario.packTitle)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)

                            Text("Your first save sets the benchmark for Today, Review, and reminders.")
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }

                        Spacer(minLength: 8)

                        Text(appViewModel.goalFocusTitle)
                            .modifier(KatieCapsuleLabelStyle())
                    }
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Starting with \(appViewModel.learnerProfile.focusScenario.packTitle)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.mint)
                                .lineLimit(1)

                            Text("First save turns the starter cue into proof for Today, Review, and reminders.")
                                .font(.caption)
                                .foregroundStyle(KatieColors.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 8)

                        Text(appViewModel.goalFocusTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(KatieColors.cardSecondary)
                            .clipShape(Capsule())
                    }
                }

                Button(action: appViewModel.completeOnboarding) {
                    HStack(spacing: 10) {
                        Text("Set up my first sample")
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.katiePrimary())
            }
            .padding(.horizontal, isWideLayout ? 24 : 16)
            .padding(.top, isWideLayout ? 10 : 8)
            .padding(.bottom, isWideLayout ? 12 : 10)
            .frame(maxWidth: isWideLayout ? 1160 : 760)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(0.96))
            .overlay(Rectangle().fill(KatieColors.cardBorder.opacity(0.4)), alignment: .top)
        }
    }

    private func profileBinding(_ keyPath: WritableKeyPath<LearnerProfile, String>) -> Binding<String> {
        Binding(
            get: { appViewModel.learnerProfile[keyPath: keyPath] },
            set: {
                appViewModel.learnerProfile[keyPath: keyPath] = $0
                appViewModel.persistOnboardingProfileDraft()
            }
        )
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
            .environmentObject(AppViewModel())
    }
}
