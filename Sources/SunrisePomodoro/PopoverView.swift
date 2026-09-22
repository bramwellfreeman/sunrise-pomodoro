import SwiftUI

/// Dropdown content: the sunrise scene, the countdown, controls, and the
/// 2 min–2 hr session slider.
struct PopoverView: View {
    @ObservedObject var model: PomodoroModel

    var body: some View {
        VStack(spacing: 12) {
            SunriseView(progress: model.progress)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(model.timeString)
                .font(.system(size: 34, weight: .semibold).monospacedDigit())

            HStack(spacing: 10) {
                Button(action: model.startPause) {
                    Label(model.isRunning ? "Pause" : "Start",
                          systemImage: model.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.space, modifiers: [])

                Button(action: model.reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.sun)

            VStack(spacing: 4) {
                HStack {
                    Text("Session")
                    Spacer()
                    Text("\(Int(model.sessionMinutes)) min")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.callout)

                Slider(
                    value: Binding(
                        get: { model.sessionMinutes },
                        set: { model.setSessionMinutes($0) }
                    ),
                    in: 2...120,
                    step: 1
                )
                .tint(Palette.sun)
                .disabled(model.isRunning)
            }

            Divider()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(width: 260)
    }
}
