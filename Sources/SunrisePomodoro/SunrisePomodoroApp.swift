import SwiftUI

@main
struct SunrisePomodoroApp: App {
    @StateObject private var model = PomodoroModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(model: model)
        } label: {
            BarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Explicitly observes the model so the menu-bar glyph + countdown repaint on
/// every tick (a plain closure over the App's @StateObject can miss updates).
private struct BarLabel: View {
    @ObservedObject var model: PomodoroModel

    var body: some View {
        Image(nsImage: model.barGlyph)
        Text(model.timeString)
            .monospacedDigit()
    }
}
