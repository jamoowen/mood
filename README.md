# Mood

A personal goals board for macOS. It shows the month (starting October 2026)
broken into weeks, with monthly and weekly goals plus an editable monthly theme.

The app is a thin native shell around a single `WKWebView` that renders plain
HTML/CSS/JS from the `Board/` folder. The point of that split: the board is a
webpage you can reshape freely without rebuilding anything, but it lives in a
real desktop window with its own Dock presence rather than a browser tab.

Goals and completion state are stored separately in `Board/data/goals.json`.
The app watches the board folder and reloads automatically when files change.

## Run

    make install
    open ~/Applications/Mood.app

## Edit

- `Board/index.html` — structure
- `Board/styles.css` — look and feel
- `Board/app.js` (and `calendar.js`, `store.js`) — behaviour
- `Board/data/goals.json` — your goals

Save a change and the app reloads. `agent.md` is a quick guide; `AGENTS.md`
documents the data format.
