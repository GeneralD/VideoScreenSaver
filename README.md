<p align="center">
  <img src="https://img.shields.io/github/v/tag/GeneralD/VideoScreenSaver?label=version" alt="Version">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Objective--C-blue" alt="Objective-C">
  <img src="https://img.shields.io/github/license/GeneralD/VideoScreenSaver" alt="License">
  <img src="https://img.shields.io/badge/open%20source-%E2%9D%A4-red" alt="Open Source">
</p>

# VideoScreenSaver

A macOS screensaver that plays a video file in a loop.

## Features

- Play any video file (MP4, MOV, etc.) as your screensaver
- Loop playback with muted audio
- Aspect-fill display
- Built-in file picker for video selection via Options panel

## Install

### Homebrew (recommended)

```sh
brew tap GeneralD/tap
brew install --cask video-screen-saver
```

### Manual

1. Download the latest `.zip` from [Releases](https://github.com/GeneralD/VideoScreenSaver/releases)
2. Unzip and copy `VideoScreenSaver.saver` to `~/Library/Screen Savers/`

## Setup

1. Open **System Settings > Screen Saver**
2. Select **VideoScreenSaver**
3. Click **Options** to choose a video file

## Build from Source

```sh
xcodebuild -project VideoScreenSaver.xcodeproj -target VideoScreenSaver -configuration Release build SYMROOT=build
cp -R build/Release/VideoScreenSaver.saver ~/Library/Screen\ Savers/
```

## Uninstall

```sh
brew uninstall --cask video-screen-saver
```

Or manually delete `~/Library/Screen Savers/VideoScreenSaver.saver`.

## License

[MIT](LICENSE)
