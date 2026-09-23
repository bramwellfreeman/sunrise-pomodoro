import SwiftUI
import AppKit

/// A detached, floating "focus" window with an enlarged sunrise + big countdown.
/// It's a non-activating floating panel so it can sit above your work without
/// stealing focus, closing the menu-bar popover, or adding a Dock icon.
final class FocusWindowController {
    static let shared = FocusWindowController()
    private var panel: NSPanel?

    func toggle(model: PomodoroModel) {
        if let p = panel, p.isVisible {
            p.orderOut(nil)
        } else {
            show(model: model)
        }
    }

    private func show(model: PomodoroModel) {
        let panel = self.panel ?? makePanel(model: model)
        self.panel = panel
        if !panel.isVisible { panel.center() }
        panel.orderFrontRegardless()
    }

    private func makePanel(model: PomodoroModel) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 260, height: 300)
        panel.contentView = NSHostingView(rootView: FocusView(model: model))
        return panel
    }
}

/// Enlarged timer for the focus window: full-bleed sunrise with a big countdown.
struct FocusView: View {
    @ObservedObject var model: PomodoroModel

    var body: some View {
        ZStack {
            SunriseView(progress: model.progress)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text(model.timeString)
                    .font(.system(size: 72, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)

                HStack(spacing: 18) {
                    Button(action: model.startPause) {
                        Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                    }
                    Button(action: model.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
                .padding(.bottom, 28)
            }
            .padding(.top, 24)
        }
        .frame(minWidth: 260, minHeight: 300)
    }
}
