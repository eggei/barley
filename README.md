# Barley

Barley is an offline native macOS utility app for day-to-day developer tasks.
It runs as a real app window and also exposes a menu bar item for fast feature selection. Your data stays in you computer for JWT decoding, WCAG contrast checking, and video-to-GIF conversion.

![Barley Screen Recording](docs/images/screen-recording.gif)
![Barley app screenshot](docs/images/barley-app-screenshot.png)

## Features

- JWT Decoder
  - Decode JWT header and payload locally
  - Search flattened claims by key/value
  - No signature verification yet
- WCAG Contrast Checker
  - Check foreground/background HEX combinations
  - Reports AA/AAA results for common WCAG criteria
- Video to GIF
  - Convert `.mov`/`.mp4` to GIF locally
  - Select FPS and output scale
  - Uses `ffmpeg` by default for consistent output, with native fallback
  - Keeps a recent output list with per-file `Reveal in Finder`

Barley opens as a normal, focusable macOS window, or you can pick a feature from the menu bar to open/focus the window with that feature active. Everything runs offline — no cloud services involved.

## Running Locally

Requirements:

- macOS 13+
- Xcode 16+ (or a compatible Swift 6 toolchain), with command line tools installed (`xcode-select --install`)
- Optional: `ffmpeg` via Homebrew for the default Video-to-GIF engine

Clone and run:

```bash
git clone https://github.com/eggei/barley.git
cd barley
swift run
```

Or open `Package.swift` in Xcode and run the `Barley` scheme.

## Installing the `barley` Command

Build a release binary and link it onto your `PATH` so you can launch Barley from any terminal with `barley`:

```bash
swift build -c release
sudo ln -sf "$(pwd)/.build/release/Barley" /usr/local/bin/barley
```

Now `barley` opens the app window from anywhere.

## Auto-Launch at Startup (launchd)

To have Barley start automatically when you log in, register it as a launchd agent:

1. Create `~/Library/LaunchAgents/com.eggei.barley.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.eggei.barley</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/barley</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

2. Load it:

```bash
launchctl load ~/Library/LaunchAgents/com.eggei.barley.plist
```

To stop auto-launching, unload and remove it:

```bash
launchctl unload ~/Library/LaunchAgents/com.eggei.barley.plist
rm ~/Library/LaunchAgents/com.eggei.barley.plist
```

## License

No license file is currently included. Add one before public reuse/distribution.

## Contributing / Development

- Built with Swift 6, SwiftUI + AppKit, and Swift Package Manager.
- Business logic lives in `Sources/Barley/Core/` and `Sources/Barley/Features/*`; keep SwiftUI views in `Sources/Barley/UI/` thin.
- Run tests with `swift test`; add new tests under `Tests/BarleyTests/` when introducing new behavior.
