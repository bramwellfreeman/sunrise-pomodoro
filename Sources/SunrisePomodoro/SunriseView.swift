import SwiftUI

/// The big sunrise scene shown in the dropdown popover.
/// Sky warms from night to dawn, and the sun rises from behind the hill,
/// both driven by `progress` (0 -> 1).
struct SunriseView: View {
    var progress: Double

    var body: some View {
        Canvas { ctx, size in
            let p = CGFloat(max(0, min(1, progress)))

            // Sky: lerp night -> dawn as the session completes.
            let top = lerp(Palette.skyNight, Palette.skyDawnTop, p)
            let bot = lerp(Palette.skyNight, Palette.skyDawnBot, p)
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [top, bot]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Sun (Canvas y grows downward, so "up" = smaller y).
            let sunR = size.width * 0.11
            let restY = size.height + sunR          // hidden below the hill
            let topY  = size.height * 0.30          // fully risen
            let cy = restY + (topY - restY) * p
            let cx = size.width / 2
            let sunRect = CGRect(x: cx - sunR, y: cy - sunR, width: sunR * 2, height: sunR * 2)

            // Soft glow
            ctx.fill(Path(ellipseIn: sunRect.insetBy(dx: -sunR * 0.9, dy: -sunR * 0.9)),
                     with: .color(Palette.sun.opacity(0.18)))
            ctx.fill(Path(ellipseIn: sunRect), with: .color(Palette.sun))

            // Hill in front, hiding the sun's base.
            var hill = Path()
            let base = size.height
            let crest = size.height * 0.62
            hill.move(to: CGPoint(x: 0, y: base))
            hill.addLine(to: CGPoint(x: 0, y: crest))
            hill.addQuadCurve(to: CGPoint(x: size.width, y: crest),
                              control: CGPoint(x: size.width / 2, y: crest - size.height * 0.22))
            hill.addLine(to: CGPoint(x: size.width, y: base))
            hill.closeSubpath()
            ctx.fill(hill, with: .color(Palette.hill))
        }
        .drawingGroup()
    }

    private func lerp(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        let ca = NSColor(a).usingColorSpace(.sRGB) ?? .black
        let cb = NSColor(b).usingColorSpace(.sRGB) ?? .black
        return Color(
            red:   Double(ca.redComponent   + (cb.redComponent   - ca.redComponent)   * t),
            green: Double(ca.greenComponent + (cb.greenComponent - ca.greenComponent) * t),
            blue:  Double(ca.blueComponent  + (cb.blueComponent  - ca.blueComponent)  * t)
        )
    }
}
