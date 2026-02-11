# NoBrainer Res

**Lightweight macOS menu bar app for quick resolution switching. Built for remote Mac users who need custom display modes.**

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<img src="https://raw.githubusercontent.com/nobrainer-tech/NoBrainer-Res/main/screenshot.png" width="400" alt="NoBrainer Res Screenshot">

## 🎯 Why NoBrainer Res?

When you connect to your Mac Mini or Mac Studio remotely via Screen Sharing, macOS limits available resolutions. This app helps you:

- ✅ **Access hidden resolutions** not shown in System Preferences
- ✅ **Force custom resolutions** via [displayplacer](https://github.com/jakehilborn/displayplacer) integration
- ✅ **Quickly switch** between display modes from the menu bar
- ✅ **Support for HiDPI modes** even on headless setups

Perfect for:
- Remote Mac Mini users connecting via Screen Sharing
- Developers working with headless Macs
- Anyone needing precise resolution control without dummy HDMI plugs

## 🚀 Features

### Standard Mode
- List all available display modes
- One-click resolution switching
- Show only HiDPI modes option
- Current resolution highlighting

### Advanced Mode (via displayplacer)
- Force custom resolutions not listed in System Preferences
- HiDPI mode support
- Quick preset buttons (1920×1080, 2560×1440, 3840×2160, 5120×2880)
- View all available modes for each display

## 📦 Installation

### Option 1: Download DMG (Recommended)
1. Download `NoBrainer-Res-1.0.0.dmg` from [Releases](../../releases)
2. Open DMG and drag `NoBrainer Res.app` to Applications
3. Launch from Applications folder

### Option 2: Build from Source
```bash
git clone https://github.com/nobrainer-tech/NoBrainer-Res.git
cd NoBrainer-Res
xcodebuild -project NoBrainer-Res.xcodeproj -scheme NoBrainer-Res -configuration Release build
```

## 🔧 Setup for Advanced Resolution Control

To use the **Advanced Resolution** features (force custom resolutions), you need to install `displayplacer`:

```bash
brew install displayplacer
```

### How It Works

NoBrainer Res integrates with [displayplacer](https://github.com/jakehilborn/displayplacer) - a command-line tool that can set resolutions even when they're not visible in system preferences.

**Note:** For best results with remote Mac access, consider using a **headless HDMI adapter** (dummy plug) which makes macOS think a 4K display is connected.

## 🖥️ Use Case: Remote Mac Mini with Screen Sharing

**Problem:** You're connecting to your Mac Mini via Screen Sharing, but:
- macOS only offers 1920×1080 or lower
- You need 2560×1440 or 4K for your workflow
- System Preferences shows limited options

**Solution with NoBrainer Res:**

1. Install `displayplacer` on your Mac Mini:
   ```bash
   brew install displayplacer
   ```

2. Open NoBrainer Res on the Mac Mini (via Screen Sharing)

3. Go to **Settings → Advanced**

4. Enter your desired resolution (e.g., 2560 × 1440)

5. Click **Apply**

Your Screen Sharing session will now use the custom resolution!

### Alternative: Headless HDMI Adapter

For the best experience, use a **4K HDMI dummy plug** (~$15-30):
- Makes macOS think a real 4K monitor is connected
- Unlocks all native resolutions (3840×2160, 5120×2880)
- Works without any software
- Recommended for permanent remote setups

## 🛠️ Technical Details

### Built With
- Swift 6.0
- SwiftUI
- CoreGraphics (for native display control)
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) for global hotkeys

### Requirements
- macOS 14.0+
- Apple Silicon or Intel Mac
- For advanced features: displayplacer (`brew install displayplacer`)

## 🤝 Support Development

If you find this tool useful, consider supporting development:

**[Pay What You Want on Gumroad](https://nobrainertech.gumroad.com/l/nobrainer-res)**

Your support helps maintain and improve the app!

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Credits

- [displayplacer](https://github.com/jakehilborn/displayplacer) by Jake Hilborn - the CLI tool that powers advanced resolution features
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus - keyboard shortcut management

---

**Made with ❤️ by [NoBrainer.tech](https://nobrainer.tech)**
