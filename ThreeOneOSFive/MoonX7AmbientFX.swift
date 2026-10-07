import SwiftUI

/// Lightweight visual layer used by the current MOONX7 base.
/// It is intentionally hit-test free and degrades to a static frame
/// when Reduce Motion is enabled.
struct MoonX7AmbientFX: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.2 : 0.06)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 10) / 10

            ZStack {
                Canvas { context, size in
                    let count = 18
                    for index in 0..<count {
                        let seed = Double(index)
                        let x = (sin(seed * 12.9898) * 0.5 + 0.5) * size.width
                        let y = (cos(seed * 78.233) * 0.5 + 0.5) * size.height
                        let drift = sin((phase + seed / Double(count)) * .pi * 2) * 14
                        let radius = 0.7 + (seed.truncatingRemainder(dividingBy: 3) * 0.45)

                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: x + drift - radius,
                                y: y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )),
                            with: .color(.white.opacity(0.11))
                        )
                    }
                }

                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.018),
                        .clear
                    ],
                    startPoint: UnitPoint(x: 0, y: phase),
                    endPoint: UnitPoint(x: 1, y: phase + 0.35)
                )
                .blendMode(.screen)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .white.opacity(0.10),
                                .clear,
                                .white.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            angle: .degrees(phase * 360)
                        ),
                        lineWidth: 0.8
                    )
                    .padding(5)
            }
            .opacity(reduceMotion ? 0.55 : 1)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
