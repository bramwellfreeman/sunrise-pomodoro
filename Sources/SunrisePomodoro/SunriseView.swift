import SwiftUI

/// The sunrise scene shown in the popover (and the enlarged focus window).
/// Sky warms night -> dawn and the sun rises from behind two layered hills,
/// both driven by `progress` (0 -> 1).
struct SunriseView: View {
    var progress: Double

    /// Fixed star field (x, y as fractions of the canvas; r as a fraction of
    /// width; a is per-star brightness). Kept static so stars don't jump frames.
    private static let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, a: Double)] = [
        (0.07, 0.12, 0.006, 0.9), (0.15, 0.30, 0.004, 0.6), (0.21, 0.08, 0.005, 0.8),
        (0.29, 0.22, 0.0035, 0.5), (0.34, 0.40, 0.004, 0.55), (0.41, 0.10, 0.006, 0.95),
        (0.47, 0.28, 0.004, 0.7), (0.53, 0.16, 0.0035, 0.6), (0.61, 0.34, 0.005, 0.8),
        (0.66, 0.09, 0.004, 0.65), (0.72, 0.24, 0.006, 0.9), (0.78, 0.14, 0.0035, 0.55),
        (0.83, 0.36, 0.004, 0.6), (0.88, 0.20, 0.005, 0.85), (0.93, 0.08, 0.004, 0.7),
        (0.11, 0.44, 0.0035, 0.5), (0.57, 0.44, 0.004, 0.5), (0.96, 0.32, 0.0035, 0.6),
    ]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let p = CGFloat(max(0, min(1, progress)))
            // Day/night cycle over the session: the moon sinks in the first half,
            // and once it drops behind the hill the sun rises in the second half.
            let moonP = min(1, p / 0.5)              // 0 -> 1 across the first half
            let sunP  = max(0, (p - 0.5) / 0.5)      // 0 -> 1 across the second half
            let cx = w / 2

            // Sky stays night while the moon is up, then warms as the sun rises.
            let top = lerp(Palette.skyNight, Palette.skyDawnTop, sunP)
            let bot = lerp(Palette.skyNight, Palette.skyDawnBot, sunP)
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: [top, bot]),
                                      startPoint: .zero, endPoint: CGPoint(x: 0, y: h))
            )

            // Stars fill the night sky and fade out as the sun rises.
            let starAlpha = Double(1 - sunP)
            if starAlpha > 0.01 {
                for s in Self.stars {
                    let rr = s.r * w
                    let rect = CGRect(x: s.x * w - rr, y: s.y * h - rr, width: rr * 2, height: rr * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(starAlpha * s.a)))
                }
            }

            // Moon: sets down and to the LEFT, dropping behind the hill and
            // fading out completely. Drawn before the hills so they hide it.
            let moonR = w * 0.095
            let moonX = w * 0.58 + (w * 0.06 - w * 0.58) * moonP     // drift left
            let moonY = h * 0.18 + (h * 0.86 - h * 0.18) * moonP     // descend
            let moonFade = 1 - max(0, (moonP - 0.7) / 0.3)           // gone by the halfway point
            let moonRect = CGRect(x: moonX - moonR, y: moonY - moonR, width: moonR * 2, height: moonR * 2)
            ctx.fill(Path(ellipseIn: moonRect.insetBy(dx: -moonR * 0.7, dy: -moonR * 0.7)),
                     with: .color(Palette.moon.opacity(0.12 * moonFade)))
            ctx.fill(Path(ellipseIn: moonRect), with: .color(Palette.moon.opacity(0.92 * moonFade)))

            // Sun: rises from behind the hill to the top (linear rate).
            let sunR = w * 0.11
            let restY = h + sunR                  // hidden below the hills
            let topY  = h * 0.24                  // fully risen
            let cy = restY + (topY - restY) * sunP
            let sunRect = CGRect(x: cx - sunR, y: cy - sunR, width: sunR * 2, height: sunR * 2)
            ctx.fill(Path(ellipseIn: sunRect.insetBy(dx: -sunR * 0.95, dy: -sunR * 0.95)),
                     with: .color(Palette.sun.opacity(0.16)))
            ctx.fill(Path(ellipseIn: sunRect), with: .color(Palette.sun))

            // Hills warm from night to dawn as the sun rises.
            let farColor  = lerp(Palette.hillFarNight,     Palette.hillFarDawn,     sunP)
            let nearTop   = lerp(Palette.hillNearTopNight, Palette.hillNearTopDawn, sunP)
            let nearBot   = lerp(Palette.hillNearBotNight, Palette.hillNearBotDawn, sunP)

            // Distant ridge — a soft, hazy rolling line.
            var far = Path()
            far.move(to: CGPoint(x: 0, y: h))
            far.addLine(to: CGPoint(x: 0, y: h * 0.78))
            far.addCurve(to: CGPoint(x: w, y: h * 0.74),
                         control1: CGPoint(x: w * 0.28, y: h * 0.66),
                         control2: CGPoint(x: w * 0.66, y: h * 0.86))
            far.addLine(to: CGPoint(x: w, y: h))
            far.closeSubpath()
            ctx.fill(far, with: .color(farColor))

            // Near hill — asymmetric, gradient-shaded, with a warm rim light on
            // its crest where the sun catches it. Built once, filled + stroked.
            let crest = nearCrest(w: w, h: h)
            var near = crest
            near.addLine(to: CGPoint(x: w, y: h))
            near.addLine(to: CGPoint(x: 0, y: h))
            near.closeSubpath()
            ctx.fill(near, with: .linearGradient(
                Gradient(colors: [nearTop, nearBot]),
                startPoint: CGPoint(x: 0, y: h * 0.6), endPoint: CGPoint(x: 0, y: h)))
            // Rim light: brightest near the sun's column, and stronger as it rises.
            let rim = Double(0.1 + 0.85 * sunP)
            ctx.stroke(crest, with: .linearGradient(
                Gradient(colors: [Palette.hillRim.opacity(0.0),
                                  Palette.hillRim.opacity(rim),
                                  Palette.hillRim.opacity(0.0)]),
                startPoint: CGPoint(x: w * 0.2, y: 0), endPoint: CGPoint(x: w * 0.8, y: 0)),
                lineWidth: max(1, w * 0.006))
        }
        .drawingGroup()
    }

    /// Open path tracing just the top edge of the near hill (left -> right).
    private func nearCrest(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.70))
        p.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.60),
                   control1: CGPoint(x: w * 0.16, y: h * 0.60),
                   control2: CGPoint(x: w * 0.34, y: h * 0.56))
        p.addCurve(to: CGPoint(x: w, y: h * 0.68),
                   control1: CGPoint(x: w * 0.74, y: h * 0.66),
                   control2: CGPoint(x: w * 0.88, y: h * 0.72))
        return p
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
