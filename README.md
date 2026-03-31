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

1. Build the project in Xcode
2. Copy `VideoScreenSaver.saver` to `~/Library/Screen Savers/`
3. Open **System Settings > Screen Saver** and select **VideoScreenSaver**
4. Click **Options** to choose a video file

## Build

```sh
xcodebuild -project VideoScreenSaver.xcodeproj -target VideoScreenSaver -configuration Release build SYMROOT=build
cp -R build/Release/VideoScreenSaver.saver ~/Library/Screen\ Savers/
```

## License

[MIT](LICENSE)
