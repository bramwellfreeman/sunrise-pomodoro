import SwiftUI

/// Dropdown content: the sunrise scene, the countdown, controls, and the
/// 2 min–2 hr session slider (with a black fill track).
struct PopoverView: View {
    @ObservedObject var model: PomodoroModel

    var body: some View {
        VStack(spacing: 12) {
            SunriseView(progress: model.progress)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    Button {
                        FocusWindowController.shared.toggle(model: model)
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Open the enlarged focus timer")
                    .padding(6)
                }

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

            VStack(spacing: 6) {
                HStack {
                    Text("Session")
                    Spacer()
                    Text(model.sessionLabel)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.callout)

                TimeSlider(
                    value: Binding(
                        get: { model.sessionMinutes },
                        set: { model.setSessionMinutes($0) }
                    ),
                    range: 1...120,
                    step: 0.5,
                    isEnabled: !model.isRunning
                )
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
