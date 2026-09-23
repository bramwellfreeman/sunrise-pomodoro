import SwiftUI

/// A slider whose track fills with a black bar as you drag toward more time.
/// Used for the 2 min–2 hr session length.
struct TimeSlider: View {
    @Binding var value: Double          // in `range` units (minutes)
    var range: ClosedRange<Double>
    var step: Double = 1                 // in `range` units
    var isEnabled: Bool = true

    private let height: CGFloat = 22
    private let thumb: CGFloat = 18

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let travel = max(0, w - thumb)
            let fillW = thumb / 2 + travel * fraction

            ZStack(alignment: .leading) {
                // Track
                Capsule().fill(Color.black.opacity(0.12))
                    .frame(height: height * 0.5)

                // Black bar that grows with the set time
                Capsule().fill(Color.black.opacity(isEnabled ? 0.85 : 0.35))
                    .frame(width: fillW, height: height * 0.5)

                // Thumb
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.18)))
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                    .frame(width: thumb, height: thumb)
                    .offset(x: travel * fraction)
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard isEnabled, travel > 0 else { return }
                        let f = min(max(0, (g.location.x - thumb / 2) / travel), 1)
                        let raw = range.lowerBound + Double(f) * (range.upperBound - range.lowerBound)
                        value = (raw / step).rounded() * step
                    }
            )
        }
        .frame(height: height)
        .opacity(isEnabled ? 1 : 0.6)
    }
}
