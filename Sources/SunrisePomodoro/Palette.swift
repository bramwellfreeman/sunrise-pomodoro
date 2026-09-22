import SwiftUI

/// Warm sunrise palette. Standalone on macOS (the Omarchy original pulled these
/// from `Color.accent` / theme tokens; here we keep a self-contained warm set).
enum Palette {
    // Sun
    static let sun      = Color(red: 1.00, green: 0.72, blue: 0.23)
    static let sunNS    = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.23, alpha: 1)

    // Hill silhouette (mid warm-gray so it reads on both light & dark menu bars)
    static let hill     = Color(red: 0.42, green: 0.38, blue: 0.40)
    static let hillNS   = NSColor(calibratedRed: 0.42, green: 0.38, blue: 0.40, alpha: 1)

    // Sky gradient endpoints for the popover, lerped by progress (night -> dawn)
    static let skyNight = Color(red: 0.09, green: 0.11, blue: 0.22)
    static let skyDawnTop = Color(red: 0.30, green: 0.22, blue: 0.42)
    static let skyDawnBot = Color(red: 1.00, green: 0.66, blue: 0.44)
}
