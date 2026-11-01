# Pofu's archipelago: playable prototype

A dependency-free, mobile-first single page: Home close-up, a tap that
pulls back to Pofu's island, a map button that pulls back to the whole
archipelago, residents running stations while you are away, seeds as
world material, the calm multiplier with quick checks, Pofu's wellbeing,
the breathing break past the daily hour, station builds along designed
level ladders, a new island drifting close, and Pofu's emotional range.
Design and numbers: [`docs/product/game-design.md`](../../../docs/product/game-design.md)
(ADR-0015 to ADR-0017).

![Overview](screenshots/overview.png)

## Open it

Open `index.html` in a browser, or serve the folder from any static host.

- **Phone (≤ 500 px wide):** full-screen, no device frame, safe areas
  respected (`viewport-fit=cover`, `env(safe-area-inset-*)`, `100dvh`).
  The **Demo** tab on the right edge opens a drawer with the simulation
  controls; every sheet and the drawer scroll with touch.
- **Desktop:** the iPhone 17 frame (402 × 874 pt) with the controls
  beside it.
- **Inside a sandboxed iframe** (for example a claude.ai artifact): no
  dialogs, no query strings, relative assets and fonts only. Flags live in
  the hash: `#bare` shows the device only, `#labels=0` hides the stand-in
  label. In an opaque-origin sandbox the fonts need the host to send
  `Access-Control-Allow-Origin` (static hosts and CDNs usually do);
  without it the page falls back to `ui-rounded` / `system-ui`.

Inside the game: tap the island (or the island button) to zoom out, the
map button for the archipelago, a station to build, an island on the map
to read about it, Pofu to boop him. The controls simulate a resisted
reach, a quiet hour, a reach for Instagram (Hop! with quick check, open,
or skip), using up the daily hour (the next open waits for a breath), a
binge, bedtime, and the next morning, and jump to days 5, 8 (then "Next
day": İskele arrives), 11 and 20.

## Publishable files

Everything the page needs, all relative to this folder:

```
index.html
island.css
game.js
assets/pofu.webp
assets/neighbor-bunny.webp
fonts/nunito-latin-wght-normal.woff2
fonts/nunito-latin-ext-wght-normal.woff2
fonts/baloo-2-latin-wght-normal.woff2
```

(`fonts/OFL-*.txt` are the font licenses; `screenshots/` and `tools/`
are not needed at runtime.)

## What is real and what is a stand-in

| Element | Status |
|---|---|
| Pofu | **Production art:** master R1, trimmed to `assets/pofu.webp`. Breathing, squish, and **all faces** (jealous, pout, smug, excited, proud, relieved, worried, unwell, sleepy, breathing) are code overlays standing in for the face-edit kit. |
| Mochi | Concept art from the UX prototype. |
| Islands, stations and their levels, Simit, Fındık, the ferry, particles | **Stand-ins** drawn in Canvas. They prove layout, scale, the camera framings, the level ladder, and motion, not the final look. |
| Islands | Ayçiçeği (home) and İskele (the harbor) are playable. Yıldız, Kaplıca and Kitap are teasers with full sheets (loop, neighbor, stations, arrival progress). |
| Chrome | Proposals following the design language; Nunito stands in for SF Pro Rounded. |
| Numbers | Mirror `tools/sim/island_economy.py` (costs, rates, calm, wellbeing, breath). Time is compressed by the demo controls. |

## Tools

- `tools/check-mobile.js`: automated checks (Playwright, Chromium):
  iPhone 15 and iPhone SE emulation with touch (full-screen layout, no
  horizontal overflow in any state, taps on the canvas and chrome, real
  touch-event scrolling of sheets and the demo drawer, tap targets of at
  least 44 pt, no `touch-action: none`), desktop (frame and panel), and
  the page inside `<iframe sandbox="allow-scripts">` over HTTP.
  `node tools/check-mobile.js` exits non-zero on any failure.
- `tools/render.js`: `node tools/render.js` writes every state (desktop
  in the frame, phone full-screen) and `overview.png` to `screenshots/`;
  then `pngquant --quality 65-90 --speed 1 --force --ext .png screenshots/*.png`.

Performance note: canvas `filter` is graded once into cached images
(locked islands, unwell and night Pofu), never per frame; per-frame
filters dropped a phone-sized canvas from about 56 to 2 frames a second
in Chromium's software renderer.
