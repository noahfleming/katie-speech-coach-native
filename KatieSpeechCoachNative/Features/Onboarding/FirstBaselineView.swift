import SwiftUI

struct FirstBaselineView: View {
    private struct FirstBaselineRunwayStep: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let accent: Color

        var id: String { title }
    }

    private struct FirstBaselineContractItem: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let accent: Color

        var id: String { title }
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPracticePresented = false

    private var usesWideBaselineLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var baselineContentMaxWidth: CGFloat {
        usesWideBaselineLayout ? 1180 : 760
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                firstBaselineHeroCard

                if usesWideBaselineLayout {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            firstBaselineActionCard
                            firstBaselineOutcomeCard
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        VStack(alignment: .leading, spacing: 20) {
                            firstBaselineSetupCard
                            firstBaselineHypothesisCard
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                } else {
                    firstBaselineActionCard
                    firstBaselineOutcomeCard
                    firstBaselineSetupCard
                    firstBaselineHypothesisCard
                }
            }
            .padding(20)
            // KAT-199: in a vertical ScrollView, chained `.frame(maxWidth:
            // .infinity)` was being interpreted as the content's intrinsic
            // width (400+ pt for long Text views) instead of the visible
            // 402pt screen width — which overflowed and clipped the right
            // edge. The simplest fix: cap to a known-good iPhone width
            // on compact, fall through to the original behaviour on iPad.
            .frame(maxWidth: usesWideBaselineLayout ? baselineContentMaxWidth : 420)
        }
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
                    KatieAuroraBackground(accent: KatieColors.accent, secondary: KatieColors.mint)
                        .opacity(0.60)
                    KatieFloatingParticles()
                }
            }
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .onChange(of: appViewModel.activeScenarioUserRepCount) { _, newValue in
            if newValue > 0 {
                isPracticePresented = false
            }
        }
        .sheet(isPresented: $isPracticePresented) {
            NavigationStack {
                PracticeRecordView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                isPracticePresented = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var firstBaselineHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // KAT-199: ViewThatFits measures "can the view be laid out" — not
            // "does it fit the available width" — so the 330pt contract panel
            // + .infinity hero lead HStack was being chosen on compact iPhone
            // (402pt screen) and overflowing the right edge, clipping the
            // "An SLP-informed speaking..." header text and other content.
            // Use a direct conditional on usesWideBaselineLayout instead.
            if usesWideBaselineLayout {
                HStack(alignment: .top, spacing: 18) {
                    firstBaselineHeroLead
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    firstBaselineContractPanel
                        .frame(width: 330, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    firstBaselineHeroLead
                    firstBaselineContractPanel
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Label(appViewModel.microphonePermissionState.title, systemImage: appViewModel.microphonePermissionState.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Spacer(minLength: 8)

                KatieReplayBadge(
                    title: firstBaselineProofModeTitle,
                    systemImage: firstBaselineProofModeSystemImage,
                    accent: firstBaselineProofModeAccent
                )
            }

            Text(appViewModel.microphoneStatusLine)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KatieColors.cardSecondary.opacity(0.34), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .katieCard()
        .katieHeroAura(accent: KatieColors.accent, secondary: KatieColors.gold)
    }

    private var firstBaselineHeroLead: some View {
        VStack(alignment: .leading, spacing: 16) {
            KatieSectionEyebrow(title: "Proof-first start", systemImage: "sparkles.rectangle.stack.fill", accent: KatieColors.gold)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // KAT-199: removed .fixedSize(vertical: true) so the text
                    // can wrap to fit the available card width on compact
                    // iPhone. The 'vertical: true' modifier fixes the text
                    // height to a single line, which prevented wrapping and
                    // forced the card to widen past the screen edge.
                    Text(appViewModel.firstBaselineHeadline)
                        .font(usesWideBaselineLayout ? .system(size: 38, weight: .bold, design: .rounded) : .largeTitle.bold())
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: false)

                    Text(firstBaselineHeroSupportLine)
                        .font(usesWideBaselineLayout ? .title3.weight(.semibold) : .title2.bold())
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: false)

                    Text(appViewModel.firstBaselineBody)
                        .font(.body)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: false)
                }

                if usesWideBaselineLayout {
                    KatieScenarioArtwork(
                        systemImage: firstBaselineProofModeSystemImage,
                        accent: firstBaselineProofModeAccent,
                        secondary: KatieColors.gold
                    )
                }
            }

            KatieWrap(spacing: 8, rowSpacing: 8) {
                ForEach(firstBaselineHeroPills, id: \.self) { pill in
                    Text(pill)
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.textPrimary))
                }
            }
        }
    }

    private var firstBaselineContractPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What changes after the first honest save")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(firstBaselineContractItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.systemImage)
                            .katieIconBadge(background: KatieColors.cardBackground, foreground: item.accent, size: 34)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(KatieColors.textPrimary)

                            Text(item.detail)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(item.accent.opacity(0.16), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [KatieColors.cardSecondary.opacity(0.94), KatieColors.cardBackground.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var firstBaselineActionCard: some View {
        VStack(alignment: .leading, spacing: usesWideBaselineLayout ? 12 : 16) {
            KatieSectionEyebrow(title: "Next move", systemImage: "flag.checkered.2.crossed", accent: firstBaselineProofModeAccent)

            Text(firstBaselineActionHeading)
                .font(.title3.weight(.bold))
                .foregroundStyle(KatieColors.textPrimary)

            Text(firstBaselineActionBody)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                firstBaselineGoalFocusPanel
                firstBaselinePrimaryFocusPanel
                firstBaselineSecondaryFocusPanel
            }

            if usesWideBaselineLayout {
                HStack(spacing: 12) {
                    firstBaselinePrimaryButton
                    firstBaselineSecondaryButton
                }
            } else {
                VStack(spacing: 12) {
                    firstBaselinePrimaryButton
                    firstBaselineSecondaryButton
                }
            }

            Label(appViewModel.microphoneStatusLine, systemImage: appViewModel.microphonePermissionState.systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private var firstBaselineGoalFocusPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "target")
                .katieIconBadge(background: KatieColors.cardBackground, foreground: KatieColors.gold, size: 32)

            VStack(alignment: .leading, spacing: 8) {
                Text("Goal focus now")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(appViewModel.goalFocusTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.gold)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(appViewModel.goalFocusDetail) Katie keeps this first benchmark tied to \(appViewModel.communicationEnvironmentTitle.lowercased()) pressure instead of turning setup into a generic drill.")
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                KatieWrap(spacing: 8, rowSpacing: 8) {
                    Text(appViewModel.communicationEnvironmentTitle)
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.textPrimary))

                    Text(appViewModel.listenerPressureTitle)
                        .modifier(KatieCapsuleLabelStyle(accent: KatieColors.textPrimary))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(KatieColors.gold.opacity(0.24), lineWidth: 1)
        )
    }

    private var firstBaselinePrimaryFocusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: primaryPathSystemImage)
                    .katieIconBadge(background: KatieColors.cardBackground, foreground: primaryPathAccent, size: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryPathTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(primaryPathDetail)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(primaryPathPoints, id: \.self) { point in
                    Label(point, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(primaryPathBackgroundTint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(primaryPathAccent.opacity(0.24), lineWidth: 1)
        )
    }

    private var firstBaselineSecondaryFocusPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .katieIconBadge(background: KatieColors.cardBackground, foreground: KatieColors.textSecondary, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text("Keep exploring \(appViewModel.currentMission.packTitle) with starter proof")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text("You can keep browsing without losing your place. Today and Review stay honest about starter proof until you save your own line here.")
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary.opacity(0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var firstBaselinePrimaryButton: some View {
        Button(appViewModel.firstBaselinePrimaryActionTitle) {
            if appViewModel.microphonePermissionState == .denied {
                appViewModel.saveFirstWinFallbackIfNeeded()
                appViewModel.continuePastFirstBaselineGate()
            } else {
                isPracticePresented = true
            }
        }
        .buttonStyle(.katiePrimary())
    }

    private var firstBaselineSecondaryButton: some View {
        Button(appViewModel.firstBaselineSecondaryActionTitle) {
            appViewModel.continuePastFirstBaselineGate()
        }
        .font(.headline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(KatieColors.cardSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .foregroundStyle(KatieColors.textPrimary)
    }

    private var firstBaselineOutcomeCard: some View {
        VStack(alignment: .leading, spacing: usesWideBaselineLayout ? 12 : 16) {
            KatieSectionEyebrow(title: "Runway", systemImage: "point.3.filled.connected.trianglepath.dotted", accent: KatieColors.mint)

            Text("Success on rep one should feel obvious")
                .font(.title3.weight(.bold))
                .foregroundStyle(KatieColors.textPrimary)

            Text("One clear save is enough to turn Katie from demo mode into your own proof trail, with a believable next action on both iPhone and iPad.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(appViewModel.currentMission.stepLabels.enumerated()), id: \.offset) { index, step in
                    firstBaselineMilestoneRow(index: index, step: step)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("What this unlocks")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(firstBaselineRunwaySteps) { step in
                        firstBaselineRunwayRow(step)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary.opacity(0.42), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Prototype note: once your first personal sample is saved, starter proof becomes the reference, not the headline.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .katieCard()
    }

    private func firstBaselineMilestoneRow(index: Int, step: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(index == 0 ? KatieColors.accent : KatieColors.cardSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(step)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(stepPrompt(at: index))
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((index == 0 ? KatieColors.accent : KatieColors.cardSecondary).opacity(index == 0 ? 0.14 : 0.36), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke((index == 0 ? KatieColors.accent : KatieColors.cardBorder).opacity(0.22), lineWidth: 1)
        )
    }

    private var firstBaselineSetupCard: some View {
        VStack(alignment: .leading, spacing: usesWideBaselineLayout ? 12 : 16) {
            KatieSectionEyebrow(title: "Trust contract", systemImage: "list.bullet.clipboard.fill", accent: KatieColors.gold)

            Text("Katie should make the first save feel safe, specific, and worth doing now")
                .font(.title3.weight(.bold))
                .foregroundStyle(KatieColors.textPrimary)

            Text("Pick the path that matches this moment. Katie keeps starter proof honest until you create your own anchor, then everything pivots to that line.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)

            firstPathCard(
                title: primaryPathTitle,
                detail: primaryPathDetail,
                points: primaryPathPoints,
                systemImage: primaryPathSystemImage,
                accent: primaryPathAccent,
                backgroundTint: primaryPathBackgroundTint,
                foreground: primaryPathForeground
            )

            firstPathCard(
                title: "Keep exploring \(appViewModel.currentMission.packTitle) with starter proof",
                detail: "Today and Review stay anchored to starter proof in \(appViewModel.currentMission.packTitle), and reminder ownership stays open until you save your own line here.",
                points: [
                    "You can browse \(appViewModel.currentMission.packTitle) now without pretending your first benchmark already exists.",
                    "Review keeps using starter material for \(appViewModel.currentMission.packTitle) until you record a real clip.",
                    "When you're ready, one personal save here gives reminders an actual line to protect instead of a generic nudge."
                ],
                systemImage: "sparkles.rectangle.stack.fill",
                accent: KatieColors.textSecondary,
                backgroundTint: KatieColors.cardSecondary,
                foreground: KatieColors.textPrimary
            )
        }
        .katieCard()
    }

    private var firstBaselineRunwaySteps: [FirstBaselineRunwayStep] {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return [
                FirstBaselineRunwayStep(
                    title: "Save a text-backed benchmark now",
                    detail: "Katie starts the proof trail with your own words in this pack instead of leaving you in starter-only mode.",
                    systemImage: "text.quote",
                    accent: KatieColors.gold
                ),
                FirstBaselineRunwayStep(
                    title: "Today and Review switch to your line",
                    detail: "Your transcript becomes the honest benchmark everywhere, even while replay labels stay clear that local audio is still missing here.",
                    systemImage: "arrow.triangle.branch",
                    accent: KatieColors.accent
                ),
                FirstBaselineRunwayStep(
                    title: "Replay and compare stay honest for the next save",
                    detail: "When microphone access comes back, the next rep can add local playback and warm a real before-vs-now story without rewriting this first proof.",
                    systemImage: "waveform.badge.plus",
                    accent: KatieColors.mint
                )
            ]
        case .granted:
            return [
                FirstBaselineRunwayStep(
                    title: "Record your first benchmark",
                    detail: "This pack gets a replay-ready local clip on this iPhone, so starter proof stops acting like the main story.",
                    systemImage: "mic.circle.fill",
                    accent: KatieColors.mint
                ),
                FirstBaselineRunwayStep(
                    title: "Today and Review pivot to your own proof",
                    detail: "Your saved line becomes the anchor for the active pack across the app instead of demo or carried-over material.",
                    systemImage: "arrow.triangle.branch",
                    accent: KatieColors.accent
                ),
                FirstBaselineRunwayStep(
                    title: "Reminders and compare have a real anchor",
                    detail: "Katie can protect this exact line for a live moment now, and one later retake can turn it into an honest before-vs-now compare.",
                    systemImage: "bell.badge.fill",
                    accent: KatieColors.gold
                )
            ]
        case .unknown:
            return [
                FirstBaselineRunwayStep(
                    title: "The first tap decides the proof mode",
                    detail: "Katie only asks for microphone access when you start recording, so this save becomes replay-ready if allowed and transcript-first if blocked.",
                    systemImage: "questionmark.circle.fill",
                    accent: KatieColors.gold
                ),
                FirstBaselineRunwayStep(
                    title: "Your own benchmark replaces the placeholder",
                    detail: "Today and Review immediately switch to your real line instead of starter proof once this first save lands.",
                    systemImage: "arrow.triangle.branch",
                    accent: KatieColors.accent
                ),
                FirstBaselineRunwayStep(
                    title: "The next rep can protect or compare honestly",
                    detail: "From there, Katie can either pin this line with a reminder or use a later retake to show real change without bluffing about replay.",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    accent: KatieColors.mint
                )
            ]
        }
    }

    private func firstBaselineRunwayRow(_ step: FirstBaselineRunwayStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(step.accent)
                .frame(width: 30, height: 30)
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
    }

    private var firstBaselineHypothesisCard: some View {
        let snapshot = appViewModel.languageAssessmentSnapshot

        return VStack(alignment: .leading, spacing: usesWideBaselineLayout ? 12 : 16) {
            KatieSectionEyebrow(title: "Listening for", systemImage: "ear.fill", accent: KatieColors.plum)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starting hypothesis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(snapshot.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KatieColors.textPrimary)
                        .lineLimit(2)

                    Text(snapshot.caveat)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
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

            VStack(alignment: .leading, spacing: 10) {
                firstBaselineInsightRow(
                    title: "Sound focus first",
                    detail: snapshot.soundFocus,
                    systemImage: "dot.radiowaves.left.and.right",
                    accent: KatieColors.mint
                )

                firstBaselineInsightRow(
                    title: "Language watch-out",
                    detail: snapshot.transferPattern,
                    systemImage: "arrow.triangle.branch",
                    accent: KatieColors.gold
                )

                firstBaselineInsightRow(
                    title: "Start with",
                    detail: appViewModel.currentMission.stepLabels.first ?? appViewModel.currentMission.packTitle,
                    systemImage: "flag.fill",
                    accent: KatieColors.accent
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Self-check after this first save")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.mint)

                Text(appViewModel.transferHypothesisPracticeBridgeLine)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)

                Label(appViewModel.transferHypothesisFollowThroughLine, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KatieColors.cardSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .katieCard()
    }

    private func firstBaselineInsightRow(title: String, detail: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .katieIconBadge(background: KatieColors.cardBackground, foreground: accent, size: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                Text(detail)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var firstBaselineHeroSupportLine: String {
        let pack = appViewModel.currentMission.packTitle
        let goal = appViewModel.goalFocusTitle.lowercased()

        switch appViewModel.microphonePermissionState {
        case .denied:
            return "Save one text-first benchmark in \(pack) so Katie can start \(goal) from your own line without bluffing about audio."
        case .granted:
            return "Record one honest sample in \(pack) first, then let Katie build \(goal), compare, and reminders from proof that is actually yours."
        case .unknown:
            return "Start one honest sample in \(pack) first, and Katie keeps the handoff clear while turning \(goal) into a real proof trail."
        }
    }

    private var firstBaselineHeroPills: [String] {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return [
                appViewModel.goalFocusTitle,
                "Today pivots to your transcript",
                "Review keeps replay labels honest"
            ]
        case .granted:
            return [
                appViewModel.goalFocusTitle,
                "Today opens with your benchmark",
                "Review gets a real compare anchor"
            ]
        case .unknown:
            return [
                appViewModel.goalFocusTitle,
                "Recording asks only when needed",
                "Today swaps in your proof fast"
            ]
        }
    }

    private var firstBaselineActionHeading: String {
        "Choose how to start \(appViewModel.currentMission.packTitle)"
    }

    private var firstBaselineActionBody: String {
        let pack = appViewModel.currentMission.packTitle
        let goal = appViewModel.goalFocusTitle.lowercased()

        switch appViewModel.microphonePermissionState {
        case .denied:
            return "Save a text-first benchmark in \(pack) now so Katie can start \(goal) from your own words, or keep browsing while starter proof stays clearly labeled."
        case .granted:
            return "One tap opens the recorder for your first real benchmark in \(pack), giving Katie an honest anchor for \(goal) without losing your place."
        case .unknown:
            return "Katie only asks for microphone access when recording starts in \(pack), and the first save still becomes the honest anchor for \(goal)."
        }
    }

    private var firstBaselineProofModeTitle: String {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return "Transcript-first"
        case .granted:
            return "Replay-ready"
        case .unknown:
            return "Permission-aware"
        }
    }

    private var firstBaselineProofModeSystemImage: String {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return "text.quote"
        case .granted:
            return "mic.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    private var firstBaselineProofModeAccent: Color {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return KatieColors.gold
        case .granted:
            return KatieColors.mint
        case .unknown:
            return KatieColors.accent
        }
    }

    private var firstBaselineContractItems: [FirstBaselineContractItem] {
        let pack = appViewModel.currentMission.packTitle

        switch appViewModel.microphonePermissionState {
        case .denied:
            return [
                FirstBaselineContractItem(
                    title: "Right now",
                    detail: "Katie starts with starter proof in \(pack) and names that honestly until you save your own words.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accent: KatieColors.plum
                ),
                FirstBaselineContractItem(
                    title: "After one save",
                    detail: "Your transcript becomes the benchmark across Today and Review instead of demo material.",
                    systemImage: "arrow.triangle.branch",
                    accent: KatieColors.accent
                ),
                FirstBaselineContractItem(
                    title: "Next protected moment",
                    detail: "Reminders can protect this exact line now, and replay can arrive later without rewriting the story.",
                    systemImage: "bell.badge.fill",
                    accent: KatieColors.gold
                )
            ]
        case .granted:
            return [
                FirstBaselineContractItem(
                    title: "Right now",
                    detail: "Katie begins in \(pack) with starter proof while you decide whether to record your own anchor.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accent: KatieColors.plum
                ),
                FirstBaselineContractItem(
                    title: "After one save",
                    detail: "Your local clip becomes the benchmark, so Today and Review stop leaning on placeholder proof.",
                    systemImage: "mic.circle.fill",
                    accent: KatieColors.mint
                ),
                FirstBaselineContractItem(
                    title: "Next protected moment",
                    detail: "Compare and reminders can point back to one believable line instead of a generic nudge.",
                    systemImage: "point.3.filled.connected.trianglepath.dotted",
                    accent: KatieColors.gold
                )
            ]
        case .unknown:
            return [
                FirstBaselineContractItem(
                    title: "Right now",
                    detail: "Katie keeps starter proof visible while the first recording decision is still open in \(pack).",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accent: KatieColors.plum
                ),
                FirstBaselineContractItem(
                    title: "After one save",
                    detail: "If you allow recording, Katie pivots to replay-ready proof. If not, your transcript still becomes the new anchor.",
                    systemImage: "questionmark.circle.fill",
                    accent: KatieColors.accent
                ),
                FirstBaselineContractItem(
                    title: "Next protected moment",
                    detail: "Either way, the next rep or reminder grows from your own line instead of the starter placeholder.",
                    systemImage: "bell.badge.fill",
                    accent: KatieColors.gold
                )
            ]
        }
    }

    private var primaryPathTitle: String {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return "Save text-only proof now"
        case .granted:
            return "Record replay-ready proof now"
        case .unknown:
            return "Record your first proof now"
        }
    }

    private var primaryPathDetail: String {
        let pack = appViewModel.currentMission.packTitle

        switch appViewModel.microphonePermissionState {
        case .denied:
            return "Katie saves a text benchmark for \(pack) right away, then keeps replay labels honest until you can record on this iPhone later."
        case .granted:
            return "Katie opens the recorder for a real local clip in \(pack) so Today, Review, and Progress can treat this as replay-ready proof instead of starter material."
        case .unknown:
            return "Katie only asks for microphone access when recording starts in \(pack). If you allow it, this first save becomes the local proof that powers replay and compare."
        }
    }

    private var primaryPathPoints: [String] {
        switch appViewModel.microphonePermissionState {
        case .denied:
            return [
                "Today switches to your own transcript-backed benchmark instead of demo-first proof.",
                "Review can compare against your saved line without pretending replay exists yet.",
                "When mic access returns, record here again to attach replay to the same proof trail."
            ]
        case .granted:
            return [
                "Today opens with your own replay-ready benchmark instead of starter proof.",
                "Review gets a real before/after compare anchor tied to this iPhone.",
                "Reminders can point back to the exact saved line and clip you recorded here."
            ]
        case .unknown:
            return [
                "Katie waits to ask for mic access until the moment you start recording.",
                "If you allow it, Today and Review immediately pivot to your own replay-ready proof.",
                "If recording is blocked, Katie still keeps your transcript trail visible without pretending audio exists."
            ]
        }
    }

    private var primaryPathSystemImage: String {
        appViewModel.microphonePermissionState == .denied ? "text.quote" : "mic.circle.fill"
    }

    private var primaryPathAccent: Color {
        appViewModel.microphonePermissionState == .denied ? KatieColors.gold : KatieColors.mint
    }

    private var primaryPathBackgroundTint: Color {
        appViewModel.microphonePermissionState == .denied ? KatieColors.gold.opacity(0.12) : KatieColors.mint.opacity(0.12)
    }

    private var primaryPathForeground: Color {
        KatieColors.textPrimary
    }

    @ViewBuilder
    private func firstPathCard(
        title: String,
        detail: String,
        points: [String],
        systemImage: String,
        accent: Color,
        backgroundTint: Color,
        foreground: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .katieIconBadge(background: KatieColors.cardBackground, foreground: accent, size: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(foreground)

                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    Label(point, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundTint)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func stepPrompt(at index: Int) -> String {
        guard appViewModel.currentMission.stepCoachingPrompts.indices.contains(index) else {
            return "Katie keeps the next move grounded and believable instead of generic."
        }

        return appViewModel.currentMission.stepCoachingPrompts[index]
    }
}

#Preview {
    NavigationStack {
        FirstBaselineView()
            .environmentObject(AppViewModel())
    }
}
