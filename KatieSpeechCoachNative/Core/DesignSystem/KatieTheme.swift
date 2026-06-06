import SwiftUI

enum KatieColors {
    static let appBackgroundTop = Color(red: 0.055, green: 0.039, blue: 0.075)
    static let appBackgroundBottom = Color(red: 0.102, green: 0.078, blue: 0.118)
    static let appBackgroundGlow = Color(red: 0.97, green: 0.58, blue: 0.36).opacity(0.22)
    static let appBackgroundGlowSecondary = Color(red: 0.45, green: 0.78, blue: 0.72).opacity(0.12)
    static let appBackgroundGlowTertiary = Color(red: 0.72, green: 0.56, blue: 0.96).opacity(0.14)

    static let cardBackground = Color(red: 0.126, green: 0.090, blue: 0.146)
    static let cardSecondary = Color(red: 0.176, green: 0.126, blue: 0.196)
    static let cardTertiary = Color(red: 0.242, green: 0.173, blue: 0.267)
    static let cardBorder = Color.white.opacity(0.10)

    static let accent = Color(red: 0.95, green: 0.69, blue: 0.47)
    static let mint = Color(red: 0.59, green: 0.87, blue: 0.81)
    static let gold = Color(red: 0.98, green: 0.82, blue: 0.58)
    static let blush = Color(red: 0.92, green: 0.56, blue: 0.63)
    static let plum = Color(red: 0.54, green: 0.39, blue: 0.78)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
}

struct KatieCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [KatieColors.cardBackground.opacity(0.99), KatieColors.cardSecondary.opacity(0.88), KatieColors.cardTertiary.opacity(0.58)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.015), Color.white.opacity(0.045), .clear, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(KatieColors.accent.opacity(0.13))
                            .frame(width: 152, height: 152)
                            .blur(radius: 20)
                            .offset(x: 24, y: -38)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(KatieColors.mint.opacity(0.10))
                            .frame(width: 120, height: 120)
                            .blur(radius: 24)
                            .offset(x: -26, y: 48)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(KatieColors.plum.opacity(0.10))
                            .frame(width: 100, height: 100)
                            .blur(radius: 28)
                            .offset(x: 22, y: 34)
                    }
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), .clear, .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(1)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.16), KatieColors.cardBorder, Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.36), radius: 30, x: 0, y: 18)
                    .shadow(color: KatieColors.accent.opacity(0.10), radius: 36, x: 0, y: 8)
            )
    }
}

struct KatieHeroAura: ViewModifier {
    var accent: Color = KatieColors.accent
    var secondary: Color = KatieColors.mint

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.18), secondary.opacity(0.09), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(accent.opacity(0.14), lineWidth: 1)
                            .blur(radius: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(accent.opacity(0.20))
                            .frame(width: 138, height: 138)
                            .blur(radius: 20)
                            .offset(x: 22, y: -34)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(secondary.opacity(0.14))
                            .frame(width: 120, height: 120)
                            .blur(radius: 24)
                            .offset(x: -18, y: 24)
                    }
            )
    }
}

struct KatieSectionEyebrow: View {
    let title: String
    let systemImage: String
    var accent: Color = KatieColors.gold

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(KatieColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.28), KatieColors.cardSecondary.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.28), lineWidth: 1)
                    )
            )
    }
}

struct KatieReplayBadge: View {
    let title: String
    let systemImage: String
    var accent: Color = KatieColors.mint

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(KatieColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.26), KatieColors.cardSecondary.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.35), lineWidth: 1)
                    )
            )
    }
}

struct KatieGlanceMetric: Identifiable {
    let title: String
    let value: String
    let detail: String
    var accent: Color = KatieColors.mint

    var id: String { "\(title)-\(value)-\(detail)" }
}

struct KatieGlanceBoard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let systemImage: String
    var accent: Color = KatieColors.accent
    var secondary: Color = KatieColors.mint
    var metrics: [KatieGlanceMetric]
    var footnote: String? = nil

    @State private var isBreathing = false

    private var boardColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 10, alignment: .top)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(isBreathing ? 0.32 : 0.18))
                        .frame(width: 80, height: 80)
                        .blur(radius: isBreathing ? 10 : 4)
                        .scaleEffect(isBreathing ? 1.04 : 0.9)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.82), secondary.opacity(0.58)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black)
                }

                VStack(alignment: .leading, spacing: 6) {
                    KatieSectionEyebrow(title: eyebrow, systemImage: systemImage, accent: accent)

                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(KatieColors.textPrimary)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            LazyVGrid(columns: boardColumns, alignment: .leading, spacing: 10) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metric.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(metric.accent)

                        Text(metric.value)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KatieColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(metric.detail)
                            .font(.caption)
                            .foregroundStyle(KatieColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KatieColors.cardSecondary.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(metric.accent.opacity(0.14), lineWidth: 1)
                    )
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(KatieColors.textSecondary)
            }
        }
        .katieCard()
        .onAppear {
            guard !isBreathing else { return }

            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

struct KatieScenarioArtwork: View {
    let systemImage: String
    var accent: Color = KatieColors.accent
    var secondary: Color = KatieColors.mint

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.34), secondary.opacity(0.20), KatieColors.cardBackground.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                .frame(width: 48, height: 48)

            Circle()
                .fill(accent.opacity(0.24))
                .frame(width: 64, height: 64)
                .blur(radius: 6)

            Circle()
                .fill(secondary.opacity(0.24))
                .frame(width: 28, height: 28)
                .offset(x: 18, y: 16)

            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [KatieColors.gold, .white, secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.white.opacity(0.18), radius: 8, x: 0, y: 1)
        }
        .frame(width: 68, height: 68)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), KatieColors.cardBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: accent.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}

struct KatieActionChipStyle: ViewModifier {
    let background: Color
    let foreground: Color
    var horizontalPadding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(background)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .foregroundStyle(foreground)
            .shadow(color: background.opacity(0.22), radius: 10, x: 0, y: 4)
    }
}

struct KatieIconBadgeStyle: ViewModifier {
    var background: Color = KatieColors.cardSecondary
    var foreground: Color = KatieColors.mint
    var size: CGFloat = 30

    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [background.opacity(0.98), background.opacity(0.74)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: foreground.opacity(0.22), radius: 12, x: 0, y: 5)
    }
}

struct KatieCapsuleLabelStyle: ViewModifier {
    var accent: Color = KatieColors.textSecondary

    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(KatieColors.cardSecondary)
            .clipShape(Capsule())
    }
}

struct KatieWrap: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let proposedRowWidth = currentRowWidth == 0 ? size.width : currentRowWidth + spacing + size.width

            if proposedRowWidth > maxWidth, currentRowWidth > 0 {
                totalWidth = max(totalWidth, currentRowWidth)
                totalHeight += currentRowHeight + rowSpacing
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth = proposedRowWidth
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalWidth = max(totalWidth, currentRowWidth)
        totalHeight += currentRowHeight

        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextX = origin.x == bounds.minX ? origin.x + size.width : origin.x + spacing + size.width

            if nextX > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += currentRowHeight + rowSpacing
                currentRowHeight = 0
            }

            subview.place(
                at: CGPoint(x: origin.x, y: origin.y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            origin.x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

extension View {
    func katieCard() -> some View {
        modifier(KatieCardModifier())
    }

    func katieIconBadge(background: Color = KatieColors.cardSecondary, foreground: Color = KatieColors.mint, size: CGFloat = 30) -> some View {
        modifier(KatieIconBadgeStyle(background: background, foreground: foreground, size: size))
    }

    func katieContentFrame(maxWidth: CGFloat = 760) -> some View {
        frame(maxWidth: maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    func katieHeroAura(accent: Color = KatieColors.accent, secondary: Color = KatieColors.mint) -> some View {
        modifier(KatieHeroAura(accent: accent, secondary: secondary))
    }
}

struct KatiePrimaryButtonStyle: ButtonStyle {
    var fill: LinearGradient = LinearGradient(
        colors: [KatieColors.gold, KatieColors.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var foreground: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(configuration.isPressed ? 0.10 : 0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: KatieColors.accent.opacity(configuration.isPressed ? 0.06 : 0.26), radius: configuration.isPressed ? 8 : 18, x: 0, y: configuration.isPressed ? 4 : 10)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

extension ButtonStyle where Self == KatiePrimaryButtonStyle {
    static func katiePrimary(
        fill: LinearGradient = LinearGradient(colors: [KatieColors.gold, KatieColors.accent], startPoint: .topLeading, endPoint: .bottomTrailing),
        foreground: Color = .black
    ) -> KatiePrimaryButtonStyle {
        KatiePrimaryButtonStyle(fill: fill, foreground: foreground)
    }
}


struct KatieInlineNotice: View {
    let title: String
    let message: String
    var systemImage: String = "bell.badge.fill"
    var accent: Color = KatieColors.mint
    var dismissTitle: String = "Dismiss"
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(accent)

                Spacer(minLength: 0)

                if let onDismiss {
                    Button(dismissTitle) {
                        onDismiss()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KatieColors.textSecondary)
                }
            }

            Text(message)
                .font(.footnote)
                .foregroundStyle(KatieColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [KatieColors.cardSecondary, KatieColors.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct KatieContinuityNotice: View {
    let strip: KatieContinuityStrip

    private var accentColor: Color {
        switch strip.accent {
        case .mint:
            return KatieColors.mint
        case .accent:
            return KatieColors.accent
        case .gold:
            return KatieColors.gold
        }
    }

    var body: some View {
        KatieInlineNotice(
            title: strip.title,
            message: strip.message,
            systemImage: strip.systemImage,
            accent: accentColor
        )
    }
}


struct KatieInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(KatieColors.cardSecondary.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(KatieColors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func katieInput() -> some View { modifier(KatieInputStyle()) }
}
