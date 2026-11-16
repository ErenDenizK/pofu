# Today's app frames and measurements

Source: pofu branch `screenshots/main`, commit `2a0a630` ("world screenshots and motion beats for main at 54914d6", 2026-11-16), fetched with `tools/review/fetch_frames.sh` into a scratch folder (raw frames deleted). Frames are 1206 x 2622 px = 402 x 874 pt at 3x (iPhone 17 Pro class). pofu `origin/main` is already at 0e354a15 (it also has WP10 "plate compositor and far picture", 1235b850), so these frames are one to a few merges behind; they include #491 (cloud floor and life on the Map), #495 (rail v2: the Map, mid and a free near), #497 (tea stall looks).

Frames fetched: Map `path-d01-map-0900`, `d03`, `d06`, `d07`, `d11`, `d13`; Home `path-d01-0900`, `d05`, `d13`, `d21-0900`, `d21-2300`; journey `flight-home-koke-mid`; `path-d13-caglayan-0907`. There is NO `path-d21-map-0900` in the ref (the Map frames in the ref stop at day 13). No Gezgin-specific frame exists; the whale appears only in the Home frames. Sheets: `sheet-app-map-frames.jpg`, `sheet-app-home-frames.jpg`.

## How the Map is built today (pofu `world-presentation-build-spec.md`, "Taken as decided")

- Map order A: Home low and in front, Koke and Çağlayan rising behind. The Map frame is the "tier-1 frame" from day 1 until Çağlayan blooms, then the "tier-2 frame"; it changes only when a tier is announced.
- Tier-1 frame fit: Home's foot at 0.80 of the height, x 16 to 386 pt, below y 84, scale the smaller fit, at least 0.45; horizon at 0.53; Koke at (-150, -470) and Çağlayan at (150, -540) from Home's box centre; tier pitch 470; backdrop lane y 350 to 450 pt for the far isles and the whale. Empty slots hold cloud towers, never a hole.
- This matches the measurements below: Home is about 279 pt wide in the tier-1 frames and about 221 to 227 pt wide once Koke is on the Map.

## Map frames: measurements

Method: the main island = connected region of grass-green and terracotta pixels (HSV mask, opened and closed), box in px, divided by 2622 (height) and 3 (pt). It includes the island's grass top and its terracotta belly; it excludes the hanging root tendrils, the cloud nest under it and the name pill. Koke and Çağlayan boxes were read by eye on 100 px grids (Koke from its sprout tip to the belly; Çağlayan from the top of the waterfall rock to the belly). Accuracy about 0.003 in y and 5 pt in width. The horizon (start of the cloud sea) is at y = 0.53 per the build spec; the image agrees (haze zone about 0.44 to 0.53). "Empty sea" = rows of the cloud sea (0.53 to 1.0, 0.47 of the height) with no island body in them; the cloud nest under the island, the name pill and the round Pofu button are counted as empty.

| Frame | Main island top y | bottom y | height | width (pt) | other islands | rows (whole screen) with no island | EMPTY SEA of 0.47 |
|---|---|---|---|---|---|---|---|
| d01 Map | 0.549 | 0.773 | 0.224 | 279 (x 96 to 375) | none | 0.776 | 0.246 (52% of the sea) |
| d03 Map | 0.569 | 0.757 | 0.187 | 276 | none | 0.813 | 0.283 (60%) |
| d06 Map | 0.554 | 0.757 | 0.204 | 278 | none | 0.796 | 0.266 (57%) |
| d07 Map (Koke asleep, grey) | 0.599 | 0.767 | 0.168 | 227 | Koke y 0.267 to 0.366, 145 pt wide | 0.733 | 0.302 (64%) |
| d11 Map | 0.599 | 0.766 | 0.167 | 221 | Koke y 0.261 to 0.366, 145 pt | 0.728 | 0.303 (64%) |
| d13 Map | 0.597 | 0.770 | 0.173 | 221 (x 100 to 320) | Koke y 0.261 to 0.366, 145 pt; Çağlayan y 0.211 to 0.305, about 131 pt (x 715 to 1108 px) | 0.672 | 0.297 (63%) |

The three frames asked for:
- d01: main island y 0.549 to 0.773, 279 pt wide (69% of the 402 pt width). Cloud with no island: the sea above it is 0.019, below it 0.227 (with the name pill at about 0.82 and the Pofu button at about 0.91), 0.246 in all. Above the horizon the top 0.53 is sky with a few separate clouds, one big cumulus (y 0.13 to 0.31) and one tiny pale isle top right (about 28 pt wide, y about 0.11; read by eye).
- d06: main island y 0.554 to 0.757, 278 pt; empty sea 0.266 (0.024 above the island, 0.243 below).
- d13: main island y 0.597 to 0.770, 221 pt; Koke 145 pt and Çağlayan about 131 pt up in the sky band; empty sea 0.297 (0.067 above, 0.230 below); no island at all in 0.672 of the rows; the region from the horizon down to the island is only 0.067 tall, the region below the island to the bottom is 0.23.
- d21 Map: does not exist in the ref.

Extra facts on the Map frames:
- The island's size does NOT grow with its level: it SHRINKS from 276 to 279 pt (tier 1, days 1 to 6) to 221 to 227 pt (tier 2, from day 7 when Koke appears), while its foot stays at y 0.757 to 0.773. The island's growth (IL1 to IL10 plates) is therefore seen inside a shape that shrinks 20 percent when a second island arrives.
- Köke and Çağlayan are placed in the sky band (y 0.21 to 0.37), ABOVE the horizon (0.53); they float against the sky and a cloud bank, not on the cloud sea. Their labels sit below their bellies (y about 0.30 to 0.39).
- Köke is the same 145 pt wide asleep (grey stone, d07) and awake (green, d11/d13): the arc change is colour and detail, not size.
- The Map shows one cloud tower (a pale cumulus peak) beside Koke on d07 to d13 and one big cumulus on the left in d01 to d13; below the horizon the sea is the textured lilac-white floor.
- No whale on any Map frame. The far "isle" is one small (about 28 pt) sprite top right.

## Home frames: measurements and what is in them

- Home island body (mask, same method), pt wide of 402 and y range: d01-0900 289 pt, y 0.361 to 0.581; d05-0900 372 pt, y 0.361 to 0.568; d13-0900 368 pt, y 0.333 to 0.569; d21-0900 373 pt, y 0.332 to 0.569; d21-2300 (night) not measured (the mask fails at night; the island looks the same size).
- So Home from day 5 to 21 is about 370 pt wide (92% of the screen), the island occupies y 0.33 to 0.57 of the height (about 24%), the rest is sky above and cloud sea with the bubble card, the "Topla" button and the stats rail below. Day 1 Home is 289 pt (IL1 is a narrower plate).
- The whale in the Home sky (d13): x 650 to 975 px (216 to 325 pt, 108 pt wide), y 505 to 655 px (0.193 to 0.250), white and pale with a grove, a waterfall and a lit lantern on its back (the grown form); it sits beside a crystal isle (x 990 px+, y about 0.17) and left of the far isles. All are baked into the plate's sky.
- Day 1 Home has the bare lawn, a sunflower bed and a broken wheel; day 5 a path, pond, stall, wheel; day 13 workshop, windmill, lighthouse beginning; day 21 the full IL10-style island (windmill, arch, lighthouse, boats) and at 23:00 a lit night variant with a heart over the workshop.
- `flight-home-koke-mid`: a mid frame of the journey: Koke asleep at the top (y roughly 0.19 to 0.33, labelled with its stage "1/4"), a tower and a big cloud on the right, Home smaller in the lower half (roughly y 0.57 to 0.75) with its name pill below it (positions read off the sheet, plus or minus 0.03); the pill under Koke is a text card, not the final UI.
- `path-d13-caglayan-0907`: Çağlayan arrival: the island fills the width (nearly the whole 402 pt) from roughly y 0.39 to 0.60 (read off the sheet, plus or minus 0.03), a text pill "Çağlayan · İyileşiyor · 1/4" below it.

## Things the designer should not read off these frames

- They are simulator frames from main 54914d6; the WP10 "plate compositor and far picture" (1235b850) is not in them.
- The Map frames show today's tier-1 and tier-2 frames only; the founder's picked target (batch 112 map-locked t1) has heavier, shrinking cloud rows and a cloud bank under Koke; compare the first two tiles of `sheet-far-camera.jpg`.
