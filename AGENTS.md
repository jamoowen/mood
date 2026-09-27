# Agent guide: reshaping the Mood board

Mood is a tiny native macOS shell around a single `WKWebView`. Everything you
will want to change — layout, styling, behaviour — lives in plain web files in
`Board/`. You never need to rebuild the native app to redesign the board.

## Editing workflow

1. **Presentation** (`index.html`, `styles.css`, `*.js`): edit and save. The
   running app watches `Board/` with FSEvents and reloads automatically.
2. **Data** (`data/goals.json`): edit and save; the app reloads and shows your
   changes. Don't write invalid JSON — the native bridge refuses to persist
   anything that isn't valid JSON, and a broken file means the board starts
   empty.
3. To preview without the app, open `Board/index.html` in a browser. In that
   mode edits are not persisted (the native bridge is absent), but rendering
   works.

### Safe editing rules

- Keep the `window.MoodCalendar` and `window.MoodStore` namespaces, or update
  `app.js` to match. `app.js` is the only file that touches the bridge.
- Persist with the bridge: `window.webkit.messageHandlers.bridge.postMessage({ action: 'write', payload: JSON.stringify(data) })`.
  The native side ignores its own writes, so don't fight it.
- Do **not** introduce polling/`setInterval` for file watching or continuous
  animations — the shell uses event-driven FSEvents and idle CPU should stay
  near zero.
- The bridge message name is `bridge`; the actions it accepts are `write`
  (payload: JSON string) and `reload`.

## How auto-reload works

- Native FSEvents notices a change to `.html`/`.css`/`.js` or `goals.json`.
- It asks the page (`window.__moodRequestReload`) to reload.
- If the user is mid-edit (an input is focused), the page defers the reload
  until the edit commits; otherwise it reloads immediately.
- On reload, goals are re-read from `goals.json`, so completed goals and edits
  are never lost.

## Rebuilding the native shell

Only needed when you change files in `App/`. From the repo root:

```sh
make install   # build, ad-hoc sign, install to ~/Applications/Mood.app
```

The running app loads `~/personal/mood/Board` by default. Override with the
`MOOD_BOARD_DIR` environment variable if you move the board elsewhere.

## Running tests

```sh
node tests/test_calendar_store.js
```
