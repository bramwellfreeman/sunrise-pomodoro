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

    let minSeconds: TimeInterval = 2 * 60           // 2 min  (matches Omarchy widget)
    let maxSeconds: TimeInterval = 2 * 60 * 60      // 2 hr

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

    var sessionMinutes: Double { (sessionLength / 60).rounded() }

    // MARK: Controls

    func setSessionMinutes(_ minutes: Double) {
        let secs = min(maxSeconds, max(minSeconds, minutes * 60))
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
        content.title = "Sunrise complete ☀️"
        content.body = "Your \(Int(sessionLength / 60))-minute session is done."
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)

        remaining = sessionLength   // ready for the next run; sun drops back down
    }

    private func requestNotificationAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Menu-bar glyph

    /// Small colored icon: sun rising from behind a hill. Regenerated each tick.
    /// Coordinates are bottom-left origin. The sun travels most of the icon
    /// height so the rise is clearly visible even at menu-bar scale.
    var barGlyph: NSImage { glyph(for: progress) }

    func glyph(for progress: Double) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let img = NSImage(size: size)
        img.lockFocus()

        let cx: CGFloat = size.width / 2
        let sunR: CGFloat = 4.5
        let crest: CGFloat = 8                 // hill high point (from bottom)

        // Sun center: hidden just behind the crest at p=0, well clear of it at p=1.
        let restY = crest - sunR + 1           // top of sun ~ at crest → hidden
        let topY  = size.height - sunR + 0.5   // fully risen, near the top edge
        let cy = restY + (topY - restY) * CGFloat(progress)

        // Sun (drawn first so the hill can hide its lower half)
        Palette.sunNS.setFill()
        NSBezierPath(ovalIn: NSRect(x: cx - sunR, y: cy - sunR, width: sunR * 2, height: sunR * 2)).fill()

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
