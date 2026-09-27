# Mood

A lightweight, personal macOS goals board. A thin native app hosts a single
`WKWebView` that loads plain HTML/CSS/JS from `Board/`. The result is a
dedicated desktop window with the flexibility of an agent-editable webpage:
redesign the board without ever rebuilding the native shell.

## Features

- **October 2026** calendar, the full month grouped into weeks (Monday start),
  including adjoining September and November dates. Prev/next/Today navigation.
- Add, edit, complete, and delete **monthly** and **weekly** goals.
- An editable **monthly theme / guiding phrase** in the top bar.
- Goals and completion state persist to `Board/data/goals.json` (structured
  JSON, kept separate from presentation files).
- **Auto-reload** on file changes via FSEvents — no polling. In-progress edits
  are never interrupted.
- Responsive layout, light/dark mode, low memory, negligible idle CPU.

## Build and install

Requirements: Xcode Command Line Tools (any recent `swiftc`).

```sh
cd ~/personal/mood
make install
```

This compiles the Swift shell, generates an app icon, assembles and ad-hoc signs
`Mood.app`, and installs it to `~/Applications/Mood.app`.

Then launch it:

```sh
open ~/Applications/Mood.app
```

Mood appears in the Dock and the app switcher like any normal app. There is no
App Store requirement and no signing identity needed.

### Where the board lives

The app loads `~/personal/mood/Board` by default. To point it elsewhere:

```sh
MOOD_BOARD_DIR=/some/other/path open ~/Applications/Mood.app
```

(For a raw launch: `MOOD_BOARD_DIR=/path ~/Applications/Mood.app/Contents/MacOS/Mood`.)

## Day-to-day use

- Click a goal's text to edit it; press Enter or click away to save, Esc to cancel.
- Click the checkbox to complete; hover a goal and click **×** to delete.
- Type in the dashed input and press Enter to add a goal.
- Use the arrows or the **Today** button to move between months.
- Type a theme in the top-right field; it saves on blur or Enter.

## Customising the board

Edit files in `Board/` directly. The running app picks up changes automatically:

- `Board/index.html` — structure
- `Board/styles.css` — all styling (retheme, respace, add animations if you like)
- `Board/calendar.js` — date/calendar logic
- `Board/store.js` — goal data logic
- `Board/app.js` — rendering and the native bridge

You can make substantial redesigns (new markup, new CSS, new scripts) without
touching `App/` or rebuilding. See `AGENTS.md` for the full agent-oriented guide
and the data format.

## Verification

Automated checks are included:

```sh
make test                            # calendar + store logic, and the file bridge
make memory                          # live RSS across app + WebKit helpers
```

Optional debug hooks (all off by default) make rendering and reload behaviour
inspectable without a browser:

```sh
# Write a PNG of the board after every load:
MOOD_SNAPSHOT_DIR=/tmp/mood ~/Applications/Mood.app/Contents/MacOS/Mood

# Write the rendered document's outerHTML after every load:
MOOD_DUMP_PATH=/tmp/board.html ~/Applications/Mood.app/Contents/MacOS/Mood

# Evaluate a JS expression in the page and write the result to a file:
MOOD_EVAL='document.getElementById("month-title").textContent' \
MOOD_EVAL_PATH=/tmp/title.txt ~/Applications/Mood.app/Contents/MacOS/Mood
```

`MOOD_WINDOW_SIZE=WxH` sets the initial window size (useful for checking
responsive layouts, e.g. `MOOD_WINDOW_SIZE=620x700`).

## Architecture

- `App/main.swift` — entry point; `NSApplication`, regular activation policy.
- `App/AppDelegate.swift` — window, menu bar (with Edit menu so copy/paste works
  in the web view), reload command.
- `App/WebViewController.swift` — the single `WKWebView`, local file loading,
  navigation allow-list, script-message handler, snapshot hook.
- `App/FileBridge.swift` — the only filesystem access: reads/writes
  `Board/data/goals.json`, and refuses invalid JSON.
- `App/FileWatcher.swift` — FSEvents watching of `Board/` (event-driven, no polling).

The web view is restricted to files under `Board/`; no network, no arbitrary
file access, no popups. The page stores nothing in cookies/local storage — all
state lives in `goals.json`.

## Resource usage

There are no timers, polling loops, or continuous animations in the idle state.
The file watcher is event-driven. To measure the real footprint:

```sh
make memory
```

This reports RSS for the app process and every WebKit helper process it spawns
(`com.apple.WebKit.WebContent`, `Networking`, `GPU`, etc.), plus a total.
