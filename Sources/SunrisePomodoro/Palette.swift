import SwiftUI

/// Warm sunrise palette. Standalone on macOS (the Omarchy original pulled these
/// from `Color.accent` / theme tokens; here we keep a self-contained warm set).
enum Palette {
    // Sun
    static let sun      = Color(red: 1.00, green: 0.72, blue: 0.23)
    static let sunNS    = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.23, alpha: 1)

    // Moon (pale, cool)
    static let moon     = Color(red: 0.90, green: 0.92, blue: 0.98)
    static let moonNS   = NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.98, alpha: 1)

    // Hill silhouette (mid warm-gray so it reads on both light & dark menu bars)
    static let hill     = Color(red: 0.42, green: 0.38, blue: 0.40)
    static let hillNS   = NSColor(calibratedRed: 0.42, green: 0.38, blue: 0.40, alpha: 1)

    // Layered hills. Each has a night -> dawn pair so the mountains warm up as
    // the sun rises (lerped by progress in SunriseView).
    static let hillFarNight     = Color(red: 0.17, green: 0.16, blue: 0.28)
    static let hillFarDawn      = Color(red: 0.44, green: 0.30, blue: 0.42)
    static let hillNearTopNight = Color(red: 0.12, green: 0.11, blue: 0.19)
    static let hillNearTopDawn  = Color(red: 0.36, green: 0.22, blue: 0.26)
    static let hillNearBotNight = Color(red: 0.05, green: 0.05, blue: 0.10)
    static let hillNearBotDawn  = Color(red: 0.15, green: 0.09, blue: 0.13)
    static let hillRim          = Color(red: 1.00, green: 0.82, blue: 0.56)   // warm rim light

    // Sky gradient endpoints for the popover, lerped by progress (night -> dawn)
    static let skyNight = Color(red: 0.09, green: 0.11, blue: 0.22)
    static let skyDawnTop = Color(red: 0.30, green: 0.22, blue: 0.42)
    static let skyDawnBot = Color(red: 1.00, green: 0.66, blue: 0.44)
}
