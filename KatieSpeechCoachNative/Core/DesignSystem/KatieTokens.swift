//
//  KatieTokens.swift
//  KatieSpeechCoachNative
//
//  KAT-200: Design system tokens. Foundation for KAT-201 (Reduce Motion),
//  KAT-202 (tab parity), and future surface work. The numbers below are the
//  canonical scale; any new view should reach for a token, not a magic number.
//
//  Usage:
//      .padding(KatieSpacing.lg)
//      .clipShape(RoundedRectangle(cornerRadius: KatieRadius.xl, style: .continuous))
//      .shadow(KatieShadow.card)
//      .animation(KatieMotion.breathe, value: isBreathing)
//
//  Visual baseline (verified after refactor): KAT-199 fixed-width card on
//  iPhone 402pt, eyebrow pill, scenario artwork, icon badge, and primary
//  button all render identically when tokens are swapped in for their
//  previous hard-coded values.
//

import SwiftUI

// MARK: - Spacing (8-pt scale with xxs/xs for hairline)

/// 8-pt grid with `xxs/xs` for the hairline values that show up in pills
/// and the gap between a card edge and an inner stroke.
enum KatieSpacing {
    /// 4 — hairline gap (e.g. caption-to-value, eyebrow-to-title).
    static let xxs: CGFloat = 4
    /// 6 — pill internal padding.
    static let xs: CGFloat = 6
    /// 8 — small gap, secondary button vertical, icon-to-text in a chip.
    static let sm: CGFloat = 8
    /// 10 — eyebrow pill horizontal padding, chip horizontal.
    static let md: CGFloat = 10
    /// 12 — card section gap, replay badge, scenario card padding.
    static let base: CGFloat = 12
    /// 14 — inline notice padding.
    static let lg: CGFloat = 14
    /// 18 — default card content padding (KAT-199 baseline).
    static let xl: CGFloat = 18
    /// 24 — section break in dense surfaces.
    static let xxl: CGFloat = 24
}

// MARK: - Radius

/// Four-step corner radius scale. Picked so the larger cards read as
/// "premium soft" while the smaller chips stay crisp.
enum KatieRadius {
    /// 12 — icon badge, capsule stroke.
    static let sm: CGFloat = 12
    /// 18 — scenario artwork, glance metric cell, primary button, input.
    static let md: CGFloat = 18
    /// 22 — premium dock, inline notice.
    static let lg: CGFloat = 22
    /// 28 — main card, hero aura. The single visual signature of Katie.
    static let xl: CGFloat = 28
}

// MARK: - Type

/// Named typography scale. Backed by Apple's semantic sizes (so Dynamic Type
/// still scales the app), but the names let us reason about hierarchy
/// without grepping for `.title3.bold()` across 18 files.
enum KatieType {
    /// Largest in-app title. Used by surface page titles (Today, Practice, ...).
    static let display: Font = .largeTitle.bold()
    /// Slightly smaller title for narrow / iPad-compact page headers.
    static let title: Font = .title.bold()
    /// Card titles (e.g. "Decision pack", "Keep one clear line alive").
    static let headline: Font = .title3.bold()
    /// Primary action / button label.
    static let body: Font = .headline
    /// Subtitle / supporting line directly under a page title.
    static let subhead: Font = .subheadline
    /// Card body copy.
    static let caption: Font = .caption
    /// Smallest readable text — disclaimers, footnotes.
    static let footnote: Font = .footnote
    /// Pill / chip / eyebrow labels. Slightly heavier than caption.
    static let label: Font = .caption.weight(.semibold)
    /// Same as `label` but for sub-eyebrow caps ("FIRST STRUCTURE" style).
    static let labelMini: Font = .caption2.weight(.semibold)
}

// MARK: - Motion

/// Centralized animation durations. Currently we have one named animation
/// (the breathing pulse on `KatieGlanceBoard`); the others are a forward
/// scale so the next motion moment picks a token instead of a literal.
enum KatieMotion {
    /// 2.4s easeInOut autoreversing — the only existing use is the
    /// `KatieGlanceBoard` ambient pulse. KAT-201 wraps this in
    /// `accessibilityReduceMotion` so the value stays canonical.
    static let breathe: Animation = .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    /// 0.25s — micro-interactions (chip tap, button press).
    static let quick: Animation = .easeInOut(duration: 0.25)
    /// 0.4s — default sheet / panel slide.
    static let base: Animation = .easeInOut(duration: 0.4)
    /// 0.6s — page transitions.
    static let slow: Animation = .easeInOut(duration: 0.6)
}

// MARK: - Shadow

/// Named shadow presets. Each preset is the exact `(color, radius, x, y)`
/// tuple that was previously hand-written in the design system. KAT-200 is
/// purely a rename — visuals are unchanged.
enum KatieShadow {
    /// The main card surface shadow stack. Two layers: a dark drop + a
    /// soft accent glow underneath. Use on the outer `RoundedRectangle`
    /// of `KatieCardModifier`.
    static let card: (drop: Shadow, glow: Shadow) = (
        drop: Shadow(color: .black.opacity(0.36), radius: 30, x: 0, y: 18),
        glow: Shadow(color: KatieColors.accent.opacity(0.10), radius: 36, x: 0, y: 8)
    )

    /// Hero aura glow under a `KatieHeroAura`-wrapped card.
    static let aura: Shadow = Shadow(color: KatieColors.accent.opacity(0.18), radius: 16, x: 0, y: 8)

    /// Icon badge (e.g. eyebrow, `katieIconBadge`). Tinted by the foreground
    /// color of the badge for color-coordinated glow.
    static func iconBadge(foreground: Color) -> Shadow {
        Shadow(color: foreground.opacity(0.22), radius: 12, x: 0, y: 5)
    }

    /// Capsule pill (eyebrow, replay badge, action chip). Subtler than
    /// `iconBadge` because the pill is smaller and usually near a body.
    static func inline(foreground: Color) -> Shadow {
        Shadow(color: foreground.opacity(0.22), radius: 10, x: 0, y: 4)
    }

    /// Primary CTA button. Pressed state collapses the shadow; rest state
    /// is the canonical "lift" that says "you can tap me".
    static func primary(rest: Bool) -> Shadow {
        Shadow(
            color: KatieColors.accent.opacity(rest ? 0.26 : 0.06),
            radius: rest ? 18 : 8,
            x: 0,
            y: rest ? 10 : 4
        )
    }
}

/// Lightweight shadow value type so the tokens can be applied via
/// `.shadow(_:)` overloads without inlining a tuple at every call site.
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    /// Apply a single named shadow. Stack two of these for multi-layer
    /// shadow setups (e.g. `KatieShadow.card`).
    func shadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
