<div align="center">
  <img src="assets/icon.png" width="120" alt="Sunrise Pomodoro icon">
  <h1>Sunrise Pomodoro</h1>
  <p>A cozy macOS menu-bar pomodoro timer. A sun rises from behind a hill as your focus session completes.</p>
  <img src="assets/rising.png" width="420" alt="The sun rising from 0% to 100%">
</div>

## What it does

- Lives in your **menu bar** — a little glyph that runs a day/night cycle as your session progresses (a moon sets, then the sun rises from behind the hill), next to the `mm:ss` countdown.
- Click it for a **sunrise popover**: a starry night sky in which the moon sets to the left, then the sun rises from behind layered hills while the sky and mountains warm from night to dawn and the stars fade out. Includes the countdown, Start/Pause (spacebar), Reset, and a session-length slider (1 min–2 hr, default 15).
- An **expand button** pops out a larger floating focus timer that stays above your other windows.
- When the session ends it plays a chime and posts a macOS notification.
- No Dock icon — it's a menu-bar-only app.

## Download

Grab the latest **[Sunrise Pomodoro.zip](https://github.com/bramwellfreeman/sunrise-pomodoro/releases/latest/download/SunrisePomodoro.zip)** from the [Releases page](https://github.com/bramwellfreeman/sunrise-pomodoro/releases/latest), unzip, and drag **Sunrise Pomodoro.app** into your Applications folder.

### First launch (important)

This app isn't notarized by Apple (no paid Developer ID), so macOS will warn you the first time. To open it:

**Right-click** the app → **Open** → **Open** in the dialog. You only need to do this once.

If macOS still refuses, run this once in Terminal:

```sh
xattr -dr com.apple.quarantine "/Applications/Sunrise Pomodoro.app"
```

That just removes the "downloaded from the internet" quarantine flag. To autostart it, add the app under **System Settings → General → Login Items**.

## Build from source

Requires macOS 13+ and Xcode (accept the license once with `sudo xcodebuild -license accept`).

```sh
git clone https://github.com/bramwellfreeman/sunrise-pomodoro.git
cd sunrise-pomodoro
./build.sh
open "dist/Sunrise Pomodoro.app"
```

`build.sh` runs `swift build -c release`, assembles the `.app` bundle (with the icon and `LSUIElement` so there's no Dock icon), and ad-hoc signs it.

Regenerate the icon with `python3 make_icon.py && iconutil -c icns AppIcon.iconset -o AppIcon.icns` (the `.iconset` is built from `icon_master.png`).

## License

MIT — see [LICENSE](LICENSE).
