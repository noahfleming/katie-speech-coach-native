import SwiftUI

// MARK: - Recording Waveform

/// Animated bar-chart waveform driven at 30 fps via TimelineView + Canvas.
/// Collapses to a minimal resting state when isActive is false or
/// Reduce Motion is enabled.
struct KatieRecordingWaveform: View {
    var isActive: Bool
    var barCount: Int = 28
    var accent: Color = KatieColors.accent
    var secondary: Color = KatieColors.mint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive || reduceMotion)) { timeline in
            let animating = isActive && !reduceMotion
            let t = animating ? timeline.date.timeIntervalSinceReferenceDate : 0.0
            Canvas { ctx, size in
                let gap: CGFloat = 3
                let barW = max(2, (size.width - gap * CGFloat(barCount - 1)) / CGFloat(barCount))
                let midY = size.height / 2
                var path = Path()
                for i in 0..<barCount {
                    let h: CGFloat
                    if animating {
                        // Two overlapping sine waves with per-bar phase give a
                        // rich, non-repetitive waveform without any randomness.
                        let phase = Double(i) * 0.73 + Double(i * i % 7) * 0.11
                        let slow = sin(t * 2.1 + phase)
                        let fast = sin(t * 4.7 + phase * 1.6 + 0.3)
                        let amp = (slow * 0.55 + fast * 0.45 + 1.0) / 2.0
                        h = max(size.height * 0.07, size.height * 0.88 * CGFloat(amp))
                    } else {
                        h = size.height * CGFloat(0.06 + 0.04 * Double(i % 4) / 3.0)
                    }
                    let x = CGFloat(i) * (barW + gap)
                    path.addRoundedRect(
                        in: CGRect(x: x, y: midY - h / 2, width: barW, height: h),
                        cornerSize: CGSize(width: barW / 2, height: barW / 2)
                    )
                }
                ctx.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [accent, secondary]),
                        startPoint: CGPoint(x: 0, y: midY),
                        endPoint: CGPoint(x: size.width, y: midY)
                    )
                )
            }
            .opacity(animating ? 0.88 : 0.22)
        }
        .animation(.easeInOut(duration: 0.45), value: isActive)
    }
}

// MARK: - Floating Particles

/// Subtle ambient particle field: 28 tiny dots drift slowly across the screen,
/// pulsing their opacity. Draws with Canvas at 20 fps for efficiency.
/// Disabled entirely when Reduce Motion is on.
struct KatieFloatingParticles: View {
    private struct Particle {
        let x: Double
        let y: Double
        let radius: Double
        let vx: Double
        let vy: Double
        let phase: Double
        let baseOpacity: Double
    }

    // Deterministic positions/velocities seeded from index — no randomness
    // means the field is identical across every launch (no layout flicker).
    private static let particles: [Particle] = (0..<28).map { i in
        let a = Double(i * 137 + 31).truncatingRemainder(dividingBy: 100.0) / 100.0
        let b = Double(i * 97 + 53).truncatingRemainder(dividingBy: 100.0) / 100.0
        return Particle(
            x: a,
            y: b,
            radius: 1.0 + Double(i % 4) * 0.5,
            vx: sin(Double(i) * 0.8) * 0.010,
            vy: cos(Double(i) * 0.6) * 0.008,
            phase: Double(i) * 0.618,
            baseOpacity: 0.04 + Double(i % 3) * 0.025
        )
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    for particle in Self.particles {
                        let rawX = (particle.x + particle.vx * t).truncatingRemainder(dividingBy: 1.0)
                        let rawY = (particle.y + particle.vy * t).truncatingRemainder(dividingBy: 1.0)
                        let px = (rawX < 0 ? rawX + 1.0 : rawX) * size.width
                        let py = (rawY < 0 ? rawY + 1.0 : rawY) * size.height
                        let opacity = particle.baseOpacity * (0.5 + 0.5 * sin(t * 0.7 + particle.phase))
                        let r = CGFloat(particle.radius)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                            with: .color(Color.white.opacity(opacity))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Progress Ring

/// Circular arc that sweeps from 0 to `progress` on appear, with a glow on
/// the arc tip. Useful for surfacing key ratios (packs, compare, replay).
struct KatieProgressRing: View {
    var progress: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 5
    var accent: Color = KatieColors.mint
    var label: String? = nil

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(
                    LinearGradient(
                        colors: [accent, KatieColors.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.45), radius: 6, x: 0, y: 0)

            if let label {
                Text(label)
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(KatieColors.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            let animation: Animation = reduceMotion
                ? .linear(duration: 0)
                : .easeOut(duration: 1.0).delay(0.25)
            withAnimation(animation) { animatedProgress = progress }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(reduceMotion ? .linear(duration: 0) : .easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Aurora Background

/// Three large blurred ellipses that oscillate gently, producing a slow
/// northern-lights shimmer. Layer this behind content at low opacity.
/// Stops all animation when Reduce Motion is on.
struct KatieAuroraBackground: View {
    var accent: Color = KatieColors.accent
    var secondary: Color = KatieColors.plum

    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(accent.opacity(0.20))
                    .frame(width: w * 1.3, height: h * 0.55)
                    .offset(
                        x: reduceMotion ? 0 : CGFloat(sin(phase) * 28),
                        y: -h * 0.12
                    )
                    .blur(radius: 40)

                Ellipse()
                    .fill(secondary.opacity(0.16))
                    .frame(width: w * 0.85, height: h * 0.44)
                    .offset(
                        x: reduceMotion ? 0 : CGFloat(cos(phase * 0.72) * 34),
                        y: h * 0.08
                    )
                    .blur(radius: 48)

                Ellipse()
                    .fill(KatieColors.mint.opacity(0.12))
                    .frame(width: w * 1.05, height: h * 0.32)
                    .offset(
                        x: reduceMotion ? 0 : CGFloat(sin(phase * 1.28 + 0.9) * 20),
                        y: h * 0.22
                    )
                    .blur(radius: 36)
            }
            .frame(width: w, height: h, alignment: .center)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                phase = .pi
            }
        }
    }
}
