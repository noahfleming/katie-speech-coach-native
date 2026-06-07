import SwiftUI
import UniformTypeIdentifiers

struct CoachTrustView: View {
    private struct QuickRepRunwayStep: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let accent: Color

        var id: String { title }
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showDeleteConfirmation = false
    @State private var showPocketCopyImporter = false
    @State private var showHowKatieHelps = true
    @State private var showCoachingFrame = false
    @State private var showEvidencePulse = true
    @State private var showSuggestedPack = false
    @State private var showCoachingPriorities = false
    @State private var showSafetyBoundaries = false
    @State private var showHandOff = false

    private var trustBoardMetrics: [KatieGlanceMetric] {
        [
            KatieGlanceMetric(
                title: "Starting pack",
                value: appViewModel.learnerProfile.focusScenario.packTitle,
                detail: "Where Katie starts the coaching arc.",
                accent: KatieColors.gold
            ),
            KatieGlanceMetric(
                title: "Live today",
                value: appViewModel.currentMission.packTitle,
                detail: "The pack currently driving Today and Practice.",
                accent: KatieColors.mint
            ),
            KatieGlanceMetric(
                title: "Reminder owner",
                value: appViewModel.reminderPlan?.scenario.packTitle ?? "Open lane",
                detail: appViewModel.reminderPlan.map { "\($0.fireDate.formatted(date: .omitted, time: .shortened)) is the current protect-this-win handoff." } ?? "No pack owns the next nudge yet.",
                accent: KatieColors.accent
            )
        ]
    }

    private var trustBoardCard: some View {
        KatieGlanceBoard(
            eyebrow: "Trust frame",
            title: "Keep the coaching context visible before you tweak it",
            detail: "Katie stays local-first, pack-aware, and explicit about reminder ownership so the settings surface still feels clinician-safe instead of slippery.",
            systemImage: "checkmark.shield.fill",
            accent: KatieColors.mint,
            secondary: KatieColors.gold,
            metrics: trustBoardMetrics,
            footnote: appViewModel.trustBoundaryLine
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .katieIconBadge(background: KatieColors.cardSecondary, foreground: KatieColors.mint, size: 34)
                    // KAT-202: page title matches the tab label ("Coach").
                    // The trust framing stays below as the eyebrow + section
                    // name — the user lands on the same Coach tab, but the
                    // page now reads "Coach · Trust frame" instead of
                    // "Trust · Trust frame" (which was the KAT-153 parity bug).
                    Text("Coach")
                        .font(KatieType.title)
                        .foregroundStyle(KatieColors.textPrimary)
                    Spacer()
                }

                trustBoardCard

                VStack(alignment: .leading, spacing: 12) {
                    Label("Clinician-safe coaching, not diagnosis", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Katie keeps your own recordings and work context at the center, treats language background as a starting hypothesis, and hands off when concerns go beyond elective clarity coaching.")
                        .foregroundStyle(KatieColors.textSecondary)

                    KatieWrap(spacing: 8, rowSpacing: 8) {
                        Label("Local-first proof", systemImage: "iphone")
                            .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))

                        Label("Sound pattern first", systemImage: "waveform.path.ecg")
                            .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))

                        Label("Escalate when needed", systemImage: "person.badge.plus")
                            .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))
                    }
                }
                .katieCard()

                katieDrillDownSection(title: "How Katie helps", subtitle: "Focus on what to say next, not everything at once.", systemImage: "sparkles", isExpanded: $showHowKatieHelps) {
                    Text("Katie helps you speak with more clarity in real conversations. The goal is practical progress, one small step at a time.")
                        .foregroundStyle(KatieColors.textSecondary)
                    Label("Current pack: \(appViewModel.currentMission.packTitle)", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                    Text(appViewModel.trustBoundaryLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                    Text(appViewModel.trustMethodLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                katieDrillDownSection(title: "Coaching frame", subtitle: "Quickly align your practice setup and context.", systemImage: "slider.horizontal.3", isExpanded: $showCoachingFrame) {
                    Label(appViewModel.profileContextHeadline, systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text(appViewModel.profileContextBody)
                        .foregroundStyle(KatieColors.textSecondary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Language background")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        TextField(
                            "First language",
                            text: Binding(
                                get: { appViewModel.learnerProfile.firstLanguage },
                                set: { appViewModel.updateFirstLanguage($0) }
                            )
                        )
                        .katieInput()

                        TextField(
                            "Other languages",
                            text: Binding(
                                get: { appViewModel.learnerProfile.otherLanguages },
                                set: { appViewModel.updateOtherLanguages($0) }
                            )
                        )
                        .katieInput()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where this usually matters")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(CommunicationEnvironment.allCases) { environment in
                                Button(environment.title) {
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                        appViewModel.updateCommunicationEnvironment(environment)
                                    }
                                }
                                .modifier(KatieActionChipStyle(
                                    background: appViewModel.learnerProfile.communicationEnvironment == environment ? KatieColors.mint.opacity(0.22) : KatieColors.cardSecondary,
                                    foreground: appViewModel.learnerProfile.communicationEnvironment == environment ? KatieColors.textPrimary : KatieColors.textSecondary,
                                    horizontalPadding: 10
                                ))
                            }
                        }

                        Text(appViewModel.communicationEnvironmentDetail)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where this gets stressful")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(ListenerPressure.allCases) { pressure in
                                Button(pressure.title) {
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                        appViewModel.updateListenerPressure(pressure)
                                    }
                                }
                                .modifier(KatieActionChipStyle(
                                    background: appViewModel.learnerProfile.listenerPressure == pressure ? KatieColors.gold.opacity(0.2) : KatieColors.cardSecondary,
                                    foreground: appViewModel.learnerProfile.listenerPressure == pressure ? KatieColors.textPrimary : KatieColors.textSecondary,
                                    horizontalPadding: 10
                                ))
                            }
                        }

                        Text(appViewModel.listenerPressureDetail)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Primary communication goal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.goalPresets) { preset in
                                Button(preset.title) {
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                        appViewModel.applyGoalPreset(preset)
                                    }
                                }
                                .modifier(KatieActionChipStyle(
                                    background: appViewModel.goalFocusTitle == preset.title ? KatieColors.accent.opacity(0.24) : KatieColors.cardSecondary,
                                    foreground: appViewModel.goalFocusTitle == preset.title ? KatieColors.textPrimary : KatieColors.textSecondary,
                                    horizontalPadding: 10
                                ))
                            }
                        }

                        Text(appViewModel.goalFocusDetail)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Language background: \(appViewModel.learnerProfile.firstLanguage)\(appViewModel.learnerProfile.otherLanguages.isEmpty ? "" : " · \(appViewModel.learnerProfile.otherLanguages)")", systemImage: "globe")
                        Label("Goal: \(appViewModel.goalFocusTitle)", systemImage: "target")
                        Label("Starting pack: \(appViewModel.learnerProfile.focusScenario.packTitle)", systemImage: "flag.fill")
                        Label("Live pack today: \(appViewModel.currentMission.packTitle)", systemImage: "waveform.path.ecg")
                    }
                    .foregroundStyle(KatieColors.textPrimary)

                    Text(appViewModel.languageAssessmentSnapshot.caveat)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                                katieDrillDownSection(title: "Coaching signal", subtitle: "A quick read on what changed in your last steps.", systemImage: "chart.line.uptrend.xyaxis", isExpanded: $showEvidencePulse) {
VStack(alignment: .leading, spacing: 12) {
                    Text(appViewModel.coachingEvidencePulse.title)
                        .font(.headline)

                    Text(appViewModel.coachingEvidencePulse.summary)
                        .foregroundStyle(KatieColors.textSecondary)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(appViewModel.coachingEvidencePulse.points, id: \.self) { point in
                            Label(point, systemImage: "checkmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                    }
                }
                }

                                katieDrillDownSection(title: "Suggested pack", subtitle: "Keep your settings on track with one clear recommendation.", systemImage: "sparkles", isExpanded: $showSuggestedPack) {
VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested pack for this context")
                        .font(.headline)

                    Label(appViewModel.recommendedScenarioForCurrentContext.packTitle, systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text(appViewModel.recommendedScenarioLaneLine)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)

                    Text(appViewModel.recommendedScenarioReason)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(appViewModel.recommendedScenarioAlignmentLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(appViewModel.coachingFrameAdjustmentLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(appViewModel.recommendedScenarioCoachOrderLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    KatieWrap(spacing: 8, rowSpacing: 8) {
                        Label(appViewModel.isRecommendedScenarioAlignedForStartingPack ? "Starting pack aligned" : "Starting pack needs update", systemImage: appViewModel.isRecommendedScenarioAlignedForStartingPack ? "checkmark.circle.fill" : "circle")
                            .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))

                        Label(appViewModel.isRecommendedScenarioAlignedForToday ? "Today aligned" : "Today needs update", systemImage: appViewModel.isRecommendedScenarioAlignedForToday ? "checkmark.circle.fill" : "circle")
                            .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))
                    }

                    HStack(spacing: 10) {
                        Button(appViewModel.currentMission == appViewModel.recommendedScenarioForCurrentContext ? "Today already matches" : "Use this pack for Today") {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                appViewModel.selectScenario(appViewModel.recommendedScenarioForCurrentContext)
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(KatieColors.cardSecondary)
                        .foregroundStyle(KatieColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(appViewModel.currentMission == appViewModel.recommendedScenarioForCurrentContext)

                        Button(appViewModel.isRecommendedScenarioAlignedForStartingPack ? "Starting pack matches" : "Make it the starting pack") {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                appViewModel.updateFocusScenario(appViewModel.recommendedScenarioForCurrentContext)
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.cardBackground : KatieColors.accent)
                        .foregroundStyle(appViewModel.isRecommendedScenarioAlignedForStartingPack ? KatieColors.textSecondary : .black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(appViewModel.isRecommendedScenarioAlignedForStartingPack)
                    }
                }
                }

                                katieDrillDownSection(title: "Coaching priorities", subtitle: "What matters most for progress this week.", systemImage: "arrow.triangle.branch", isExpanded: $showCoachingPriorities) {
VStack(alignment: .leading, spacing: 12) {
                    Text("Coaching priorities")
                        .font(.headline)

                    Text("Keep the clinician-safe order obvious everywhere: sound patterns first, language transfer as a hypothesis, prosody only after the listener-critical words are stable.")
                        .foregroundStyle(KatieColors.textSecondary)

                    trustPriorityRow(
                        title: "1. Listener-critical sound target",
                        body: appViewModel.languageAssessmentSnapshot.soundFocus,
                        systemImage: "dot.radiowaves.left.and.right",
                        accent: KatieColors.mint
                    )

                    trustPriorityRow(
                        title: "2. Language transfer watch-out",
                        body: appViewModel.languageAssessmentSnapshot.transferPattern,
                        systemImage: "arrow.triangle.branch",
                        accent: KatieColors.gold
                    )

                    trustPriorityRow(
                        title: "3. Prosody later",
                        body: appViewModel.languageAssessmentSnapshot.prosodyFocus,
                        systemImage: "waveform",
                        accent: KatieColors.accent
                    )
                }
                }

                packContractSummaryCard
                startingHypothesisSummaryCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose the pack Katie protects")
                        .font(.headline)

                    Text("Keep the starting pack broad, the live pack current, and reminder ownership obvious before you switch anything.")
                        .foregroundStyle(KatieColors.textSecondary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Starting pack")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.availableScenarios) { scenario in
                                Button(scenario.packTitle) {
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                        appViewModel.updateFocusScenario(scenario)
                                    }
                                }
                                .modifier(KatieActionChipStyle(
                                    background: appViewModel.learnerProfile.focusScenario == scenario ? KatieColors.accent.opacity(0.24) : KatieColors.cardSecondary,
                                    foreground: appViewModel.learnerProfile.focusScenario == scenario ? KatieColors.textPrimary : KatieColors.textSecondary,
                                    horizontalPadding: 10
                                ))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live pack for Today")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Text("This changes the pack Katie opens in Today. Reminder ownership stays where the current protected line lives until you move it in reminder controls.")
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)

                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.availableScenarios) { scenario in
                                Button(scenario.packTitle) {
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                        appViewModel.selectScenario(scenario)
                                    }
                                }
                                .modifier(KatieActionChipStyle(
                                    background: appViewModel.currentMission == scenario ? KatieColors.mint.opacity(0.22) : KatieColors.cardSecondary,
                                    foreground: appViewModel.currentMission == scenario ? KatieColors.textPrimary : KatieColors.textSecondary,
                                    horizontalPadding: 10
                                ))
                            }
                        }
                    }
                }

                                katieDrillDownSection(title: "Trust boundaries", subtitle: "Clear boundaries make the app more reliable.", systemImage: "checkmark.shield", isExpanded: $showSafetyBoundaries) {
VStack(alignment: .leading, spacing: 12) {
                    Text("What Katie does not do")
                        .font(.headline)

                    Label("Does not diagnose speech or language conditions", systemImage: "cross.case.fill")
                        .foregroundStyle(KatieColors.textPrimary)
                    Label("Does not pretend imported text has replay audio", systemImage: "waveform.path.badge.minus")
                        .foregroundStyle(KatieColors.textPrimary)
                    Label("Does not push identity-changing or accent-erasure framing", systemImage: "heart.text.square.fill")
                        .foregroundStyle(KatieColors.textPrimary)

                    Text("Katie earns trust by being specific, calm, and honest about what is on this iPhone versus what still needs a fresh recording.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                }

                                katieDrillDownSection(title: "Clinical handoff", subtitle: "Know when a professional is the best next step.", systemImage: "heart.text.square.fill", isExpanded: $showHandOff) {
VStack(alignment: .leading, spacing: 12) {
                    Text("When Katie should hand off")
                        .font(.headline)

                    Text("Katie is for elective speech-clarity practice in real work moments. If any of these show up, the safer next step is a licensed clinician rather than more self-practice.")
                        .foregroundStyle(KatieColors.textSecondary)

                    clinicalFollowUpRow(
                        title: "Sudden speech, voice, or swallowing changes",
                        body: "If something changed quickly or now feels noticeably different than usual, Katie should not act like routine reps are enough.",
                        systemImage: "exclamationmark.triangle.fill",
                        accent: KatieColors.gold
                    )

                    clinicalFollowUpRow(
                        title: "Pain, strain, or ongoing hoarseness",
                        body: "Practice should not push through discomfort, vocal fatigue, or a rough voice that keeps hanging around.",
                        systemImage: "waveform.badge.exclamationmark",
                        accent: KatieColors.accent
                    )

                    clinicalFollowUpRow(
                        title: "Stuttering or bigger communication breakdowns",
                        body: "If blocks, repetitions, or broader breakdowns keep getting in the way, Katie should point toward individualized clinical support.",
                        systemImage: "bubble.left.and.exclamationmark.bubble.right.fill",
                        accent: KatieColors.mint
                    )

                    clinicalFollowUpRow(
                        title: "Concerns beyond speech clarity practice",
                        body: "Memory, language-finding, hearing, neurologic, or swallowing concerns need a clinician, not just benchmark tracking.",
                        systemImage: "stethoscope",
                        accent: KatieColors.gold
                    )

                    Text("These signs do not automatically mean something is wrong. They mean human clinical judgment is the more honest next step than pretending an app alone can sort it out.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick rep")
                        .font(.headline)
                    Text("Need a low-friction start? Pick one short rep and see exactly how the next save changes proof, compare, and reminders.")
                        .foregroundStyle(KatieColors.textSecondary)

                    if usesWideQuickRepGrid {
                        LazyVGrid(columns: quickRepGridColumns, alignment: .leading, spacing: 12) {
                            ForEach(appViewModel.quickRepRail) { prompt in
                                let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario
                                let isRecommended = prompt.scenario == appViewModel.recommendedScenarioForCurrentContext
                                quickRepPickerCard(prompt: prompt, reminderProtected: reminderProtected, isRecommended: isRecommended)
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(appViewModel.quickRepRail) { prompt in
                                    let reminderProtected = appViewModel.reminderPlan?.scenario == prompt.scenario
                                    let isRecommended = prompt.scenario == appViewModel.recommendedScenarioForCurrentContext
                                    quickRepPickerCard(prompt: prompt, reminderProtected: reminderProtected, isRecommended: isRecommended, compactWidth: 272)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trust status")
                        .font(.headline)
                    KatieContinuityNotice(strip: appViewModel.currentContinuityStrip)
                    Label(appViewModel.trustCapsuleLine, systemImage: "checkmark.shield.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KatieColors.mint)
                    Text(appViewModel.starterProofStatusLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                    Label(appViewModel.displayCompareReadinessTitle(for: appViewModel.latestSession), systemImage: appViewModel.displayCompareReadinessSystemImage(for: appViewModel.latestSession))
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.displayCompareReadinessDetail(for: appViewModel.latestSession))
                        .foregroundStyle(KatieColors.textSecondary)
                    Text("Reminder handoff: \(appViewModel.currentScenarioSnapshot.reminderCadenceLabel)")
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.accent)
                    Label(appViewModel.reminderPermissionState.title, systemImage: appViewModel.reminderPermissionState.systemImage)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.reminderStatusLine)
                        .foregroundStyle(KatieColors.textSecondary)
                    Label(appViewModel.microphonePermissionState.title, systemImage: appViewModel.microphonePermissionState.systemImage)
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.microphoneStatusLine)
                        .foregroundStyle(KatieColors.textSecondary)
                    Text(appViewModel.recorderStatusLine)
                        .foregroundStyle(KatieColors.textSecondary)
                    Text(appViewModel.localStorageSummaryLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("What stays on this iPhone")
                        .font(.headline)
                    Text("This native scaffold is local-first for audio and compare memory on this device. If synced storage arrives later, export, deletion, and retention controls should become visible product surfaces — not hidden settings.")
                        .foregroundStyle(KatieColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Reminder handoff")
                        .font(.headline)

                    Text("Keep the nudge style honest and predictable across Today, Review, and Settings, then show the exact copy Katie would send before you schedule it.")
                        .foregroundStyle(KatieColors.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(ReminderTone.allCases) { tone in
                            reminderToneButton(tone)
                        }
                    }

                    Text(appViewModel.reminderToneLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Preview notification", systemImage: "bell.badge.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.accent)

                        Text(appViewModel.reminderPreviewTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Text(appViewModel.reminderPreviewBody)
                            .foregroundStyle(KatieColors.textSecondary)

                        Text(appViewModel.reminderPreviewScheduleLine)
                            .font(.footnote)
                            .foregroundStyle(KatieColors.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if usesWideReminderPresetLayout {
                        KatieWrap(spacing: 8, rowSpacing: 8) {
                            ForEach(appViewModel.reminderQuickPresets) { preset in
                                reminderPresetChip(preset)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(appViewModel.reminderQuickPresets) { preset in
                                    reminderPresetChip(preset)
                                }
                            }
                        }
                    }

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
                    .padding(.vertical, 10)
                    .background(KatieColors.cardSecondary)
                    .foregroundStyle(KatieColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .katieCard()

                reminderFlowBanner

                VStack(alignment: .leading, spacing: 12) {
                    Text("Data controls")
                        .font(.headline)

                    Label("Saved on this iPhone first", systemImage: "iphone")
                        .foregroundStyle(KatieColors.textPrimary)
                    Label("Export or delete when you move devices", systemImage: "arrow.down.doc")
                        .foregroundStyle(KatieColors.textPrimary)
                    Label("No hidden cloud replay story", systemImage: "eye.slash")
                        .foregroundStyle(KatieColors.textPrimary)
                    Label("Pocket copy includes learner profile, reminders, and saved transcript continuity", systemImage: "tray.full")
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(appViewModel.exportSummaryLine)
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                    Text(appViewModel.firstWinTrustLine)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    if let pocketCopyStatusLine = appViewModel.pocketCopyStatusLine {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Pocket copy restore", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(KatieColors.mint)

                                Spacer()

                                Button("Dismiss") {
                                    appViewModel.clearPocketCopyStatusLine()
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KatieColors.textSecondary)
                            }

                            Text(pocketCopyStatusLine)
                                .font(.footnote)
                                .foregroundStyle(KatieColors.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KatieColors.cardSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    HStack(spacing: 8) {
                        ShareLink(item: appViewModel.exportPayload, subject: Text("Katie pocket copy"), message: Text("Local-first Katie continuity export")) {
                            Text("Export pocket copy")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(KatieColors.cardSecondary)
                                .foregroundStyle(KatieColors.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button("Import pocket copy") {
                            showPocketCopyImporter = true
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(KatieColors.cardSecondary)
                        .foregroundStyle(KatieColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    HStack(spacing: 8) {

                        Button("Delete history on-device") {
                            showDeleteConfirmation = true
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(appViewModel.isPremiumUnlocked ? Color.red.opacity(0.24) : Color.red.opacity(0.12))
                        .foregroundStyle(appViewModel.isPremiumUnlocked ? .red : KatieColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Text("Trust rule: Katie speaks plainly about what is replay-ready here versus restored only from text or handoff.")
                        .font(.footnote)
                        .foregroundStyle(KatieColors.textSecondary)
                }
                .katieCard()
            }
            .padding(16)
            .katieContentFrame(maxWidth: 1040)
        .background(LinearGradient(colors: [KatieColors.appBackgroundTop, KatieColors.appBackgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing).overlay { RadialGradient(colors: [KatieColors.appBackgroundGlow, .clear], center: .topLeading, startRadius: 8, endRadius: 420) }.ignoresSafeArea())
        .confirmationDialog("Delete all local Katie history from this iPhone?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete all local data", role: .destructive) {
                appViewModel.deleteAllOnDeviceData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes saved transcripts, compare selections, reminder state, and any replay-ready local recordings from this device.")
        }
        .fileImporter(isPresented: $showPocketCopyImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task {
                await appViewModel.importPocketCopy(from: url)
            }
        }
    }


    private var packContractSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pack contract")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KatieColors.textPrimary)

            Text("Katie keeps Today on the live pack while reminders stay on whichever pack currently owns the next protected line. Onboarding still keeps the starting pack broad.")
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)

            Label("Starting pack: \(appViewModel.learnerProfile.focusScenario.packTitle)", systemImage: "flag.fill")
            Label("Live pack: \(appViewModel.currentMission.packTitle)", systemImage: "waveform.path.ecg")

            if let reminderPlan = appViewModel.reminderPlan {
                Label(
                    "Reminder owner: \(reminderPlan.scenario.packTitle) · \(reminderPlan.fireDate.formatted(date: .omitted, time: .shortened))",
                    systemImage: reminderPlan.scenario == appViewModel.currentMission ? "bell.badge.fill" : "bell.badge"
                )

                Text(
                    reminderPlan.scenario == appViewModel.currentMission
                        ? "The next nudge already protects this live pack."
                        : "Switching Today does not move the reminder. Use reminder controls below when you want this pack to own the next nudge."
                )
                .foregroundStyle(KatieColors.textSecondary)
            } else {
                Label("Reminder owner: none yet", systemImage: "bell.slash")
                Text("Katie only pins a reminder after you choose to protect a saved line.")
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .font(.footnote)
        .foregroundStyle(KatieColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(KatieColors.cardSecondary.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(KatieColors.cardBorder, lineWidth: 1)
        )
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(KatieColors.cardSecondary.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(KatieColors.cardBorder, lineWidth: 1)
        )
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

    private func reminderToneButton(_ tone: ReminderTone) -> some View {
        let isSelected = appViewModel.reminderTone == tone

        return Button {
            appViewModel.setReminderTone(tone)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(tone.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(tone.detail)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? KatieColors.accent.opacity(0.18) : KatieColors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? KatieColors.accent : KatieColors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var usesWideQuickRepGrid: Bool {
        horizontalSizeClass == .regular
    }

    private var usesWideReminderPresetLayout: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    private var quickRepGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }

    private func quickRepPickerCard(
        prompt: QuickRepPrompt,
        reminderProtected: Bool,
        isRecommended: Bool,
        compactWidth: CGFloat? = nil
    ) -> some View {
        Button {
            appViewModel.launchQuickRep(for: prompt.scenario)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)

                        Text(prompt.durationLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KatieColors.mint)
                    }

                    Spacer(minLength: 0)

                    if isRecommended {
                        Label("Recommended", systemImage: "sparkles")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KatieColors.gold)
                    }
                }

                Text(prompt.statusLabel)
                    .modifier(KatieCapsuleLabelStyle(accent: reminderProtected ? KatieColors.mint : KatieColors.gold))

                Text(prompt.proofLine)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textPrimary.opacity(0.88))
                    .lineLimit(4)

                Label(prompt.continuityLine, systemImage: reminderProtected ? "bell.badge.fill" : "bell")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(reminderProtected ? KatieColors.mint : KatieColors.textSecondary)
                    .lineLimit(2)

                Label(prompt.hypothesisStatusLabel, systemImage: appViewModel.transferHypothesisFeedback.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.accent)
                    .lineLimit(2)

                Text(prompt.hypothesisDetailLine)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .lineLimit(3)

                VStack(alignment: .leading, spacing: 8) {
                    Label("What stays in sync after this rep", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(quickRepRunwaySteps(for: prompt)) { step in
                            quickRepRunwayRow(step)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "quote.bubble")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KatieColors.textSecondary)

                    Text(prompt.starterLine)
                        .font(.caption2)
                        .foregroundStyle(KatieColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: compactWidth == nil ? .infinity : nil, alignment: .leading)
            .frame(width: compactWidth, alignment: .leading)
            .background(isRecommended ? KatieColors.gold.opacity(0.12) : KatieColors.cardSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isRecommended ? KatieColors.gold.opacity(0.35) : KatieColors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func reminderPresetChip(_ preset: ReminderQuickPreset) -> some View {
        Button(preset.title) {
            appViewModel.updateReminderTime(preset.fireDate)
        }
        .modifier(KatieActionChipStyle(background: KatieColors.cardSecondary, foreground: KatieColors.textPrimary, horizontalPadding: 10))
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
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: step.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(step.accent)
                .frame(width: 24, height: 24)
                .background(step.accent.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(step.detail)
                    .font(.caption2)
                    .foregroundStyle(KatieColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func katieDrillDownSection<Content: View>(title: String, subtitle: String, systemImage: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(KatieColors.textSecondary)
                content()
            }
            .padding(.top, 4)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(KatieColors.textPrimary)
        }
        .katieCard()
    }

    private func clinicalFollowUpRow(title: String, body: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textPrimary)

                Text(body)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func trustPriorityRow(title: String, body: String, systemImage: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(KatieColors.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)

                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(KatieColors.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KatieColors.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    CoachTrustView()
        .environmentObject(AppViewModel())
}
