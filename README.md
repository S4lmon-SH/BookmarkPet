<p align="center">
  <img src="Resources/BookmarkPet.svg" width="88" alt="A smiling green bookmark pet" />
</p>

# BookmarkPet

**Leave your next step. Pick up where you left off.**

A tiny macOS menu bar companion that keeps one note for your next work session. Before you close your Mac, leave a short reminder. When you return, click the bookmark pet and carry on.

**English** · [한국어](README.ko.md)

[Website](https://s4lmon-sh.github.io/BookmarkPet/en/) · [Download v0.1.1](https://github.com/S4lmon-SH/BookmarkPet/releases/tag/v0.1.1) · [Report a bug](https://github.com/S4lmon-SH/BookmarkPet/issues) · [MIT license](LICENSE)

<p align="center">
  <img src="docs/images/popover.png" width="332" alt="Actual BookmarkPet popover with a two-line Korean note and a settings menu button" />
</p>

## How it works

1. Click the bookmark pet in your menu bar.
2. Write what you want to do next. Every edit is saved automatically.
3. Close the popover or quit the app. Your note stays on your Mac.
4. Come back, click the pet, and resume your work.

A small **!** badge means there is a note waiting. Clearing the note removes the badge; **Undo clear** restores both. Whitespace-only notes do not show a badge, while your original spaces and line breaks are preserved.

## Features

- One local note, with automatic save and restore after relaunch.
- A custom bookmark character with a fixed-width menu bar icon.
- A compact 304 pt popover with immediate editor focus and scrolling for longer notes.
- Native text editing: Korean text, multiple lines, paste, and standard Command shortcuts.
- **Clear note**, **Undo clear**, **Launch at login**, and **Quit** in the top-right **☰** menu.
- Dismiss with an outside click or Escape, including after opening the settings menu.
- Light and dark appearance, Retina rendering, and respect for Reduce Motion.
- No Dock icon, account, cloud sync, analytics, or third-party packages.

The app interface is currently **in Korean**. The prompt “돌아오면 무엇부터 할까요?” means “What will you start with when you return?”

## Download and install

Requires **macOS 13 Ventura or later**. The release archive includes Apple Silicon and Intel executables in one universal app.

1. Download `BookmarkPet-0.1.1-universal.zip` from [Releases](https://github.com/S4lmon-SH/BookmarkPet/releases/tag/v0.1.1).
2. Unzip it and move `BookmarkPet.app` into `/Applications` or `~/Applications`.
3. Open the app. Look for the bookmark pet in your menu bar; no Dock icon appears.

### First-launch security notice

Version 0.1.1 is an **experimental development release**, signed ad hoc and **not notarized by Apple**. macOS may block the first launch. If you trust this download, follow [Apple’s instructions](https://support.apple.com/en-us/102445): try opening it, then use **System Settings → Privacy & Security → Open Anyway**, if available. You can also build the app locally from the source below.

`SHA256SUMS.txt` is included with the release. To check the downloaded archive, place both files in the same folder and run:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

## Settings and shortcuts

Click **☰** at the right of the prompt.

| Menu label | Action |
| --- | --- |
| 메모 비우기 | Clear the note and remove its badge. |
| 되돌리기 | Undo the latest clear. Available until the next edit or app exit. |
| 로그인 시 실행 | Enable or disable launch at login. |
| 로그인 항목 설정 열기 | Open the system login-item settings when approval is required. |
| BookmarkPet 종료 | Quit the app while preserving the note. |

The editor supports **⌘V** paste, **⌘C** copy, **⌘X** cut, **⌘A** select all, **⌘Z** undo, and **⇧⌘Z** redo. Escape closes the popover when an input-method composition is not active.

### Links in notes

Web addresses starting with `https://`, `http://`, or `www.` appear underlined in the system link color. Click once to open one in your default browser. **Option-click** to place the cursor inside the address and edit it; drag to select text containing a link. Links are detected after edits, paste, reopening, and undoing a clear. The saved file remains the exact original plain text.

Available starting with v0.1.1.

### Launch at login

Install the app in a stable location before enabling this setting. BookmarkPet uses `SMAppService.mainApp` and reads the actual macOS registration status. If approval is needed, the menu explains this and offers a button to open the relevant system settings.

After login, the app waits quietly in the menu bar with the saved note’s badge. It does not open the popover automatically. If you move or replace the app and automatic launch stops working, turn the setting off and on again.

## Local storage and privacy

Your note is stored as a **plain UTF-8 text file**:

```text
~/Library/Application Support/BookmarkPet/memo.txt
```

The app atomically replaces this file on each edit. It does not trim or normalize the saved text. The badge alone uses a whitespace-and-newline check. The app does not transmit your note or collect telemetry. The file is not encrypted by BookmarkPet.

Quitting or deleting the app does not remove this file. To remove your saved note completely, quit BookmarkPet and delete the file. The clear-action undo history exists only in memory.

## Build from source

You need a **Swift 6 toolchain** provided by Xcode or Apple Command Line Tools. No external dependencies are required.

```sh
git clone https://github.com/S4lmon-SH/BookmarkPet.git
cd BookmarkPet
./scripts/test.sh
./scripts/build.sh
open ./build/BookmarkPet.app
```

The default build targets your current Mac’s architecture, with macOS 13 as the deployment target. It creates the app bundle, icon, `Info.plist`, and ad hoc signature. Use the bundle rather than launching through `swift run` for normal menu bar and login-item behavior.

To create a universal app and ZIP archive for distribution:

```sh
./scripts/test.sh
./scripts/package.sh
```

Output: `build/release/BookmarkPet-0.1.1-universal.zip` and `SHA256SUMS.txt`. All build artifacts are ignored by Git.

For a per-user installation from source:

```sh
mkdir -p "$HOME/Applications"
ditto ./build/BookmarkPet.app "$HOME/Applications/BookmarkPet.app"
open "$HOME/Applications/BookmarkPet.app"
```

Quit an existing copy before replacing it.

## Website

The [official website](https://s4lmon-sh.github.io/BookmarkPet/en/) is served from `docs/` through GitHub Pages. It includes Korean and English pages and a browser demo. Demo notes stay only in page memory and reset on reload or language navigation.

Edit `docs/index.html`, `docs/assets/styles.css`, and `docs/assets/app.js`. English text lives in `scripts/site-en.json`; regenerate the English page with Node.js:

```sh
node scripts/build-site.mjs
python3 -m http.server 4173 --bind 127.0.0.1 --directory docs
```

Open `http://127.0.0.1:4173/` for Korean or `/en/` for English. Commit the generated `docs/en/index.html` too. Pushing `main` publishes the static `docs/` directory; there are no website package dependencies. Node.js is only needed when regenerating the English page, not for building the macOS app.

## Project layout

| Path | Purpose |
| --- | --- |
| `Sources/BookmarkPetCore/MemoSession.swift` | File storage, note state, clear, and undo clear. |
| `Sources/BookmarkPet/BookmarkPetApp.swift` | SwiftUI popover, AppKit editor, menu bar drawing, and login items. |
| `Resources/BookmarkPet.svg` | Original vector artwork for the bookmark character. |
| `scripts/make_icon.swift` | Native app icon generation. |
| `scripts/build.sh` / `scripts/package.sh` | Native or universal build, and release packaging. |
| `scripts/test.sh` / `Tests/` | Core tests and the standalone test runner. |
| `docs/index.html` / `docs/assets/` / `docs/en/` | Public website and interactive browser demo. |
| `scripts/build-site.mjs` / `scripts/site-en.json` | English website generation and translation text. |

`Package.swift` also includes Swift Testing tests for `swift test`. The standalone runner avoids a local SwiftPM framework-loading issue encountered on the development Mac.

## Verification and limitations

See [verification results and manual checks](docs/VERIFICATION.md) for details. Storage, restoration, whitespace rules, clear/undo, clipboard paste, and the actual menu bar UI have been checked on an Apple Silicon Mac.

- The universal Intel executable is cross-compiled; it has not been run on an Intel Mac.
- macOS 13 is the deployment target; the app has not been tested on a physical macOS 13 installation.
- Reboot/login, sleep/wake, screen lock/unlock, and live Korean IME composition still require the documented manual checks.
- This release has no Developer ID signature, Apple notarization, automatic updates, or English app localization.

## Feedback and license

Found a bug or have a small improvement in mind? [Open an issue](https://github.com/S4lmon-SH/BookmarkPet/issues) with your macOS version and steps to reproduce. Please omit personal memo contents.

If BookmarkPet helps you get back into your work, a GitHub star is appreciated.

Released under the [MIT License](LICENSE). Copyright © 2026 S4lmon.
