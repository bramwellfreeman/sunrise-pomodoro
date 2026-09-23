import SwiftUI
import AppKit
import UserNotifications

/// Timer state + menu-bar glyph generation.
///
/// Countdown is time-based (anchored to an end date) so it stays accurate even
/// if the timer fires late or the machine sleeps. `progress` runs 0 -> 1 as the
/// session elapses, and the sun rises with it.
final class PomodoroModel: ObservableObject {
    @Published var sessionLength: TimeInterval          // seconds, persisted
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false

    private var endDate: Date?
    private var timer: Timer?

    let minSeconds: TimeInterval = 60               // 1 min
    let maxSeconds: TimeInterval = 2 * 60 * 60      // 2 hr
    let stepSeconds: TimeInterval = 30              // slider granularity

    private let defaultsKey = "sessionLength"

    init() {
        // Test hook: SUNRISE_TEST_SECONDS overrides the session length so the
        // sunrise can be watched in seconds instead of minutes.
        let env = ProcessInfo.processInfo.environment
        let testSecs = env["SUNRISE_TEST_SECONDS"].flatMap(TimeInterval.init)

        let saved = UserDefaults.standard.double(forKey: defaultsKey)
        let initial = testSecs ?? (saved > 0 ? saved : 15 * 60)   // default 15 min
        sessionLength = initial
        remaining = initial
        requestNotificationAuth()

        if env["SUNRISE_AUTOSTART"] != nil { start() }

        // Test hook: render the real glyph at several progress values, then exit.
        if let dir = env["SUNRISE_DUMP_GLYPHS"] { dumpGlyphs(to: dir); exit(0) }
        // Test hook: render the popover sunrise scene at several progress values.
        if let dir = env["SUNRISE_DUMP_SCENE"] {
            Task { @MainActor in dumpScene(to: dir); exit(0) }
        }

        if env["SUNRISE_SHOW_FOCUS"] != nil {
            DispatchQueue.main.async { FocusWindowController.shared.toggle(model: self) }
        }
    }

    @MainActor
    private func dumpScene(to dir: String) {
        for step in 0...8 {
            let p = Double(step) / 8.0
            savePNG(SunriseView(progress: p).frame(width: 300, height: 170),
                    to: "\(dir)/scene_\(Int(p * 100)).png")
        }
        // Popover with the slider ~half-way so the black fill is visible.
        sessionLength = 61 * 60
        savePNG(PopoverView(model: self).background(Color(nsColor: .windowBackgroundColor)),
                to: "\(dir)/popover.png")
    }

    @MainActor
    private func savePNG<V: View>(_ view: V, to path: String) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let tiff = renderer.nsImage?.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }

    /// Writes barGlyph@8x at progress 0…1 to `dir` for visual verification.
    private func dumpGlyphs(to dir: String) {
        for step in 0...4 {
            let p = Double(step) / 4.0
            let g = glyph(for: p)
            let scale = 8
            let px = NSSize(width: g.size.width * CGFloat(scale), height: g.size.height * CGFloat(scale))
            let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(px.width), pixelsHigh: Int(px.height),
                                       bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                       colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            NSGraphicsContext.current?.imageInterpolation = .none
            g.draw(in: NSRect(origin: .zero, size: px))
            NSGraphicsContext.restoreGraphicsState()
            let data = rep.representation(using: .png, properties: [:])!
            try? data.write(to: URL(fileURLWithPath: "\(dir)/glyph_\(Int(p * 100)).png"))
        }
    }

    // MARK: Derived

    /// 0 at session start, 1 at completion.
    var progress: Double {
        guard sessionLength > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / sessionLength))
    }

    var timeString: String {
        let t = max(0, Int(ceil(remaining)))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    var sessionMinutes: Double { sessionLength / 60 }

    /// Human label for the current session length: "30 sec", "1 min", "1 min 30 sec"…
    var sessionLabel: String {
        let s = Int(sessionLength.rounded())
        if s < 60 { return "\(s) sec" }
        let m = s / 60, r = s % 60
        return r == 0 ? "\(m) min" : "\(m) min \(r) sec"
    }

    // MARK: Controls

    func setSessionMinutes(_ minutes: Double) {
        // Snap to the nearest step (30s), then clamp.
        let snapped = (minutes * 60 / stepSeconds).rounded() * stepSeconds
        let secs = min(maxSeconds, max(minSeconds, snapped))
        sessionLength = secs
        UserDefaults.standard.set(secs, forKey: defaultsKey)
        if !isRunning { remaining = secs }
    }

    func startPause() { isRunning ? pause() : start() }

    func start() {
        if remaining <= 0 { remaining = sessionLength }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        if let end = endDate { remaining = max(0, end.timeIntervalSinceNow) }
        isRunning = false
        endDate = nil
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        remaining = sessionLength
    }

    // MARK: Tick / finish

    private func tick() {
        guard let end = endDate else { return }
        remaining = max(0, end.timeIntervalSinceNow)
        if remaining <= 0 { finish() }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false

        NSSound(named: "Glass")?.play()

        let content = UNMutableNotificationContent()
        content.title = "Time's up ☀️"
        content.body = "Take a break and enjoy the sunshine!"
        content.sound = .default
        // The leading icon is the app's own icon (from the bundle) — no attachment.
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)

        remaining = sessionLength   // ready for the next run; sun drops back down
    }

    private func requestNotificationAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Menu-bar glyph

    /// Small colored icon: sun rising from behind a hill. Regenerated each tick.
    /// Day/night cycle at menu-bar scale: moon sinks in the first half, sun
    /// rises in the second. Coordinates are bottom-left origin.
    var barGlyph: NSImage { glyph(for: progress) }

    func glyph(for progress: Double) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let img = NSImage(size: size)
        img.lockFocus()

        let cx: CGFloat = size.width / 2
        let r: CGFloat = 4.5
        let crest: CGFloat = 8                 // hill high point (from bottom)
        let hiddenY = crest - r + 1            // top ~ at crest → hidden behind hill
        let topY = size.height - r + 0.5       // fully up, near the top edge

        let moonP = min(1, progress / 0.5)     // 0 -> 1 across the first half
        let sunP  = max(0, (progress - 0.5) / 0.5)

        // Moon sets down and to the left, fading out behind the hill.
        let moonX = cx + (r - cx) * CGFloat(moonP)                   // drift toward left edge
        let moonY = topY - (topY - hiddenY) * CGFloat(moonP)
        let moonFade = 1 - max(0, (CGFloat(moonP) - 0.7) / 0.3)
        Palette.moonNS.withAlphaComponent(moonFade).setFill()
        NSBezierPath(ovalIn: NSRect(x: moonX - r, y: moonY - r, width: r * 2, height: r * 2)).fill()

        // Sun rises from behind the hill to the top (linear).
        let cy = hiddenY + (topY - hiddenY) * CGFloat(sunP)
        Palette.sunNS.setFill()
        NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()

        // Hill in front — a gentle mound reaching `crest` in the middle.
        let hill = NSBezierPath()
        hill.move(to: NSPoint(x: 0, y: 0))
        hill.line(to: NSPoint(x: 0, y: crest * 0.5))
        hill.curve(to: NSPoint(x: size.width, y: crest * 0.5),
                   controlPoint1: NSPoint(x: size.width * 0.33, y: crest * 1.55),
                   controlPoint2: NSPoint(x: size.width * 0.67, y: crest * 1.55))
        hill.line(to: NSPoint(x: size.width, y: 0))
        hill.close()
        Palette.hillNS.setFill()
        hill.fill()

        img.unlockFocus()
        img.isTemplate = false
        return img
    }
}
