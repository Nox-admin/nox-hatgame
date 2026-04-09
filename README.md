# Шляпа (HatGame) 🎩

iOS word guessing party game — noxlabs.xyz

## Stack
- Swift + SwiftUI + MVVM + SwiftData
- No external dependencies
- Fully offline, local multiplayer (pass-the-phone)
- Russian language only (MVP)

## Structure
```
ios/       — Xcode project + Swift source (~27 files, ~3000 lines)
design/    — Hi-fi prototypes, style guides, wireframes
qa/        — QA screenshots by version
docs/      — Words lists, master plan, planning docs
```

## Status
v1 complete — QA passed (21/22 ✅, 1 ⚠️ by-design). Ready for App Store.

## Build
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
cd ios
xcodebuild ...
```
