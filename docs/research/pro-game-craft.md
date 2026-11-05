# Pro game craft: how studios work, where Pofu stands, what to do next

_Status: research and recommendation for the founder. Last updated:
2026-11-02. Written from the seat of a technical and art director at a
small cozy-games studio. No code changes in this document._

_Reads with: [look-dev](../design/look-dev.md) (and look round 2, PR #61),
[ADR-0018](../adr/0018-visual-system-v1.md), UI system v2 (PR #70,
`docs/design/ui-system-v2.md`), the
[interaction spec](../design/interaction-spec.md), the
[companion motion spec](../design/companion-motion.md),
[sound identity](../design/sound-identity.md), the
[iteration plan](../archive/iteration-plan.md) and the
[founder input log](../product/founder-input.md)._

The founder's question (2026-11-02, translated): _"We build plain UI and
game mechanics with code. How do real professional game makers do it, and
how can we improve ourselves? The rose copper before harmony looked
sweet; I think we just need proper colour and light design. For the UI
language to be perfect: quality, harmony, elegance and playfulness."_

## 0. The answer in one paragraph

Professional studios are not better because they use an engine; they are
better because **their iteration loop is seconds long, every decision is
data a designer can tune on the device, and an art director decides
colour and light before assets are made, not after**. Our loop is the
opposite on all three: a change is pushed, CI renders still PNGs minutes
later, nobody sees motion until the founder installs a build, the numbers
that make things feel good are Swift constants, and colour is _corrected_
after generation by a harmony system that pulls every asset toward one
reference, which is why the rose copper went amber and why the world
risks going flat. The fix is not to switch to Unity. It is to build the
three things studios build first: **(1) a motion review loop** (CI renders
videos of scripted beats, so the founder and the agent see feel, not
stills), **(2) a colour script** (light designed per hour and wellbeing
state, with material accents protected, and harmony demoted from
"make everything match" to "make every asset obey the same light"), and
**(3) an on-device tuning panel** in Rehearsal mode whose tweaks export
as a JSON diff that becomes a PR. After those come a small juice library
with sound wired in, a data-driven rig and timeline format we author in
code, and a SpriteKit spike for island mini-games only.

**Top five, ranked by impact per cost:**

| # | Upgrade | Why it is first | Cost |
|---|---|---|---|
| 1 | **Motion review in CI**: scripted "beats" rendered as MP4 per PR | We cannot tune what nobody sees move; every later upgrade depends on it | 1–2 days |
| 2 | **Colour script v1 + harmony v2** (rose copper restored as a protected accent; light, not correction, fixes the cold kettle) | The founder's sharpest current complaint; it decides every future asset batch | 2–3 days |
| 3 | **Tuning panel ("Ayar") in Rehearsal**, data-driven tuning file, JSON export | Moves feel decisions to the phone, where the founder already is | 2–3 days |
| 4 | **Juice library + sound wired in** (`PofuFeedback`: tween, haptic, sound, particles, hold) and a feel checklist per interaction | Sounds already exist in `tools/sound`; the app plays none (0 `AVAudio` uses) | 3–4 days |
| 5 | **Rig v2: a JSON skeletal format** (bones, painted parts, springs, clips) with a Python previewer and a Swift player | Pofu's motion ceiling today is springs on one image plus expression swaps | 1–2 weeks |

**This week: 1, 2 and 3.** Details in §3; the colour and light approach
in §4.

---

## 1. How professional studios work

### 1.1 The one thing that matters most: iteration speed

Every postmortem of a small, beloved game says some version of the same
thing: the quality came from **how many times the team could try
something and look at it**. Adam Robinson-Yu built _A Short Hike_ mostly
alone in Unity by setting a large project aside and prototyping something
small he could iterate on quickly ([GDC 2020 postmortem][short-hike]).
Ken Wong describes _Monument Valley_ as built inside a UX studio, where
"every screen was a piece of art" and each one was redrawn until it held
up as an image ([Designing Monument Valley][mv-design],
[The Art of Monument Valley][mv-art]). Alba's environment team chose a
procedural, data-driven approach so that **art work would not be lost
each time the design changed** ([ustwo, Environment art of Alba][alba]).

The common mechanism:

1. **A vertical slice first.** One small area at final quality (art,
   light, motion, sound, UI) before content production, so the pipeline
   is proven on something real. Our equivalent is the home-island slice
   of stage W.
2. **Hot reload or live tuning.** Designers change a number and see it
   on the device in seconds: Unity's play-mode inspector, Godot's remote
   scene tree, Unreal's live coding, or a custom in-game debug menu.
   Studios without an editor build the menu (§1.8).
3. **Review on the target, in motion.** Animation and feel are reviewed
   as video or on device, never as stills. Art is reviewed in context (in
   the scene, under the scene's light), never as a loose file.
4. **Short decision cycles with a single owner.** An art director owns
   colour and light, a lead designer owns feel, and they sign off on the
   slice before production scales.

### 1.2 Engines, and why each team chose theirs

| Game | Engine / stack | Why it fit | Lesson for Pofu |
|---|---|---|---|
| _Monument Valley_ 1–3 (ustwo) | Unity | Small team, cross-platform, a fast editor for level and art designers working as one ([Unity on MV3][mv3]) | The editor mattered because artists composed levels directly; we compose in code, so we need the equivalent preview loop |
| _Alba_ (ustwo) | Unity | Procedural placement so design changes did not destroy art ([alba]) | Our layout is already data (`IslandLayout`); keep art placement data, not hand-tuned code |
| _A Short Hike_ | Unity | One developer, everything in one tool ([short-hike]) | A unifying render treatment made a solo developer's assets cohere (§4.5) |
| _Octopath Traveler_ (Acquire / Square Enix) | Unreal Engine 4 | Real 3D light, depth of field, bloom and particles on 2D sprites in a 3D diorama; the team said it "relied heavily on UE4" with a small team ([Unreal spotlight][octopath], [Unreal Fest Europe 2019 talk][octopath-talk]) | HD-2D is a **lighting** look, not a filter; our grade imitates the camera but not the light (§4) |
| _Sky: Children of the Light_ (thatgamecompany) | Custom engine | Huge social scenes on mobile; each realm designed around a time of day or weather state ([Art of Sky, GDC Summer 2020][sky], [Pocket Tactics recap][sky-recap]) | Organising a world's art by a time-of-day colour plan is exactly what a colour script is |
| _Ori_ (Moon Studios) | Unity | Painted, layered 2.5D backgrounds; the character animated by hand in a Ghibli-inspired style with a tiny team ([Animating Ori, GDC 2015][ori-anim], [Art of Ori WotW][ori-art]) | Layered painted plates with parallax are a proven AAA-indie look; quality came from art direction, not tech |
| _Hollow Knight_ (Team Cherry) | Unity | Frame-by-frame hand-drawn animation in a 2D toolkit | Frame-by-frame needs an animator; not our path |
| _Cult of the Lamb_ (Massive Monster) | Unity | 2D cutout characters in a 3D world ([Unity blog][cotl-unity]); the art director said he would change the Lamb's rig if he could, but "can't redo 300 animations at this stage" ([Inverse interview][cotl-rig]) | **Fix the rig before you have many animations.** Our rig is at the right stage to be fixed |
| _Unpacking_ (Witch Beam) | Unity | Pixel art; the audio lead recorded over 14,000 foley files for object-specific sound ([GDC 2022][unpacking]) | Specific sound per object is what makes simple interaction feel rich |
| _Neko Atsume_ (Hit-Point) | Unity | Tiny loop, simple 2D, strong character art | Charm from character and restraint, not tech |
| _Royal Match_ (Dream Games, İstanbul) | Unity ([Wikipedia][royal]) | Industrial polish: every swap, combo and booster has short, controlled, layered animation ([ironSource deep dive][royal-dive]) | A Turkish studio that sets the world bar for juice; its craft is a feedback system, not one-off animations |
| _Pokémon Sleep_ (Select Button, then Pokémon Works) | — | More than five years from concept to release ([pocketgamer.biz][psleep]) | A wellbeing game for the mass market took years of tuning; we should expect the same and build tuning tools |

**Why studios pick an engine:** an editor (scene, animation, particles,
UI), a runtime (rendering, audio, physics), and a hiring pool. We cannot
use the editors (no GUI, no Xcode locally) and we do not hire. The
runtime parts we need are small and already in iOS: SwiftUI and Metal
for rendering, SpriteKit for sprites, particles and physics,
`AVAudioEngine` for sound, Core Haptics for touch. **Our "editor" has to
be code, data files, Python previews and CI renders.** That is a real
handicap, but a known one: studios that ship custom engines (Sky, many
Japanese mobile studios) live with exactly this and compensate with
debug menus and data files.

### 1.3 Art direction: the document stack

A studio art director produces, in this order, before production art:

1. **Pillars and references** (mood board, "what we are and are not").
   We have this: art bible, art direction study.
2. **Value and shape language** (silhouettes, value structure in
   greyscale, the readable focal point). Partly: proportion is decided,
   value structure is not written down.
3. **Colour script** (Pixar's term: a strip of small paintings showing
   the colour and light of every beat; in games, per area, time of day
   and game state). **We do not have one.** We have grade presets made in
   code and tuned against screenshots.
4. **Lighting keys** (one paintover per lighting state: where the key
   light comes from, its colour, the fill, rim, practicals, fog). **We do
   not have them.**
5. **Material library** (each recurring material's local colour, how it
   responds to light, its specular behaviour: copper, glaze, wood, fur,
   paper). Partly: `palettes.json` lists swatches, not behaviour.
6. **Production style guide and paintovers** (how a new asset is made
   and how the art director corrects it, by painting over the in-game
   screenshot, not by adjusting the file in isolation).

The classic references every art director uses for 3–5 are James
Gurney's _Color and Light_ (2010: local colour versus light colour,
gamut masks, colour accents, atmospheric perspective) and the published
Pixar colour scripts (Ralph Eggleston, Lou Romano).

### 1.4 Colour and light practice

The working rules, condensed:

- **Light first, local colour second.** What you see is local colour
  (the copper's own pink-orange) multiplied by the light's colour and
  intensity, plus bounce. A cold-looking kettle is usually a light
  problem (no warm key or bounce on it), not a paint problem.
- **Key, fill, rim, practicals.** Key: the sun (direction and
  temperature change with the hour). Fill: the sky's colour in the
  shadows (cool by day, so shadows go blue-violet, not grey). Rim: a
  thin edge light that separates the hero from the background. Practicals:
  light sources in the scene (lantern, ember, window), which carry the
  night.
- **Warm light, cool shadows (or the reverse), never grey shadows.**
  Shadow colour is a design choice per lighting state.
- **Atmospheric perspective.** Distance lowers contrast and saturation
  and shifts toward the sky colour. HD-2D and Ori lean on it for depth.
- **Value structure.** The image must read in three to five values in
  greyscale. The focal point (Pofu, the station in focus) holds the
  strongest value contrast in the frame.
- **Accent budget.** A frame has one dominant hue family, one
  supporting, and a small accent (a few percent of the area) that is the
  most saturated thing on screen. Saturation is spent like money.
- **Gamut per state.** Gurney's gamut masks: each lighting state uses a
  bounded region of the colour wheel; everything in the frame is mapped
  into it. This is what gives a time of day its unity, and it is the
  correct model for a harmony system (§4.6).
- **Time-of-day palettes are authored, not computed.** Sky designed
  each realm's state by hand; Octopath's towns have their own light
  rigs. A global multiply over a day image gives "a darker day", not
  "night".

### 1.5 Character animation

| Technique | How it works | Who uses it | Tools and runtime | Fit for Pofu |
|---|---|---|---|---|
| **Frame-by-frame** | Every frame drawn | Hollow Knight, Cuphead | Any painter; sprite sheets | No: needs an animator; GPT Image cannot keep frames on model |
| **Cutout / skeletal 2D** | Character split into painted parts on a bone hierarchy; bones keyed; optional mesh deformation and weights | Cult of the Lamb, most mobile games, Royal Match's King | **Spine** (editor paid; runtimes open source but shipping needs a Spine licence, `spine-ios` supports 4.2 exports [spine-ios]), DragonBones (free editor, ecosystem partly stale [db]), COA Tools for Blender (open source, exports DragonBones JSON) | **Yes, the right model.** Our rig parts are already painted edits of one base (`tools/rig`) |
| **Rive state machines** | Vector or raster parts with bones, a state machine with inputs, one runtime file | App UIs, Duolingo's characters | Rive editor (web); MIT-licensed iOS runtime wrapping the C++ core [rive-rt]; a text-based Rive CLI is advertised for agents [rive-agents] (could not be verified from here: `rive.app` is outside this session's allowed network) | Excellent for UI micro-animation; for Pofu it locks the rig to one vendor's editor and file format |
| **Live2D** | Mesh deformation of a layered painting for 2.5D head turns | VTubers, gacha games | Cubism editor (Windows/macOS GUI), paid for commercial use above a revenue threshold | Gorgeous for faces, but GUI-only and a large rig per character |
| **3D rendered as 2D** | A 3D model animated and rendered with a painterly shader | Ori (Moon Studios animated Ori in 3D), many HD-2D characters | Blender (we have `bpy`) | Parked (the 3D spike); keep it as an option for big motions only |
| **Procedural / springs** | Code drives transforms with springs and noise | Every game, for secondary motion | Our `CompanionMotion` | We have this, and it is good. It is the layer **on top of** a rig, not instead of one |

The professional pattern is **layered**: authored clips (keyed bone
poses) for the big beats, springs and procedural noise for secondary
motion (ears, tufts, cheeks, breathing), and expression swaps for the
face. Pofu today has the second and third layers and lacks the first.

### 1.6 Game feel and "juice"

Canon: Martin Jonasson and Petri Purho, _Juice it or lose it_ (GDC
2012; [Vault][juice]); Jan Willem Nijman, _The Art of Screenshake_
([coverage][screenshake]); Steve Swink, _Game Feel_ (2008); the
counterpoint _Don't juice it or lose it_ ([Vault][dont-juice]), which
matters for a calm product. The practice:

- **Every interaction has an envelope**: anticipation (a 40–80 ms dip
  before a jump), action, follow-through (overshoot and settle),
  secondary motion (things attached keep moving).
- **Squash and stretch with volume kept.** Width × height ≈ 1.
- **Easing is designed per verb.** Springs for physical things,
  ease-out for arrivals, ease-in for departures; never linear for
  anything a player touches.
- **Hit-stop / hold**: a 30–90 ms freeze on impact makes contact land.
  The cozy version is a "breath hold" before a reveal.
- **Particles with purpose**: a few, shaped, coloured from the
  palette, and coherent with the light (fireflies glow, dust is lit by
  the key).
- **Layered audio**: a transient (the click), a body (the material),
  a tail (the room or the reward), with pitch variation (±3–5 %) so
  repetition does not fatigue; Unpacking's 14,000 foley files are the
  extreme of "every object sounds like itself".
- **Haptics as part of the same event**, timed to the transient.
- **One feedback system.** Royal Match-grade polish is not hundreds of
  bespoke animations; it is a system where an event (`match`, `collect`,
  `build`) triggers a declared bundle of tween + sound + haptic +
  particles + camera, tuned in data. Unity teams use DOTween, LeanTween,
  MMFeedbacks ("Feel"); Godot teams use Tweens and AnimationPlayer.
- **Rationed for calm products.** Repetition decays the response
  (our interaction spec rule 4 already says so).

### 1.7 UI production

- **A game UI kit**: every reusable piece (button, panel, tag, badge,
  counter) designed once in all states (normal, pressed, disabled,
  focused, night), exported as **9-slice** sprites with cap insets so
  one painted face stretches to any size.
- **Figma (or Photoshop) to engine** through an exporter or naming
  convention; tokens (colour, type, spacing, motion) shared between
  design and code.
- **A UI motion spec**: durations, curves and choreography per
  transition, with video references.
- **UI animation in Rive or Lottie** when motion is too rich for code
  (animated icons, reward reveals); simple motion stays in code.
- **The UI is lit by the world.** Good game UI picks up the world's
  light (a warmer tint at golden hour, a cooler one at night) while
  staying legible.

We have the best part of this already: tokens in
`design/tokens/pofu-tokens.json`, a strong interaction spec, and UI
system v2's skin switch and 9-slice plan. What we lack is the motion
review and the state matrix rendered (every component, every state, day
and night) as one contact sheet.

### 1.8 Tooling

- **Data-driven tuning**: numbers live in data files (ScriptableObjects,
  JSON, spreadsheets) that designers edit without a programmer.
- **Live reload**: the build watches the data and reloads it.
- **Debug menus**: an in-game overlay to jump to any state, set the
  clock, grant currency, replay a moment, toggle effects, slow time
  (0.25×), step frames, show bounding boxes and frame time. Every shipped
  mobile game has one hidden in development builds.
- **Scene previews and golden images**: render known states and compare
  them on every change.
- **Capture tools**: one-button video capture of a sequence, so reviews
  are of motion.

### 1.9 Playtesting, vertical slices, telemetry

- **Playtests from the first slice**: five players, silent observation,
  screen recording, "what do you think this does?" before any
  explanation. Most studios run weekly internal tests and monthly
  external ones.
- **Vertical slice gate**: production does not scale until the slice
  is signed off by the art director, the lead designer and a playtest.
- **Telemetry**: funnels (first session, day 1, day 7), feature use,
  frame time distribution, crash rate. Privacy-first analytics exist for
  iOS (on-device aggregates, or services such as TelemetryDeck).
- **Feel is measured too**: time to first interaction, how often a
  reaction is triggered and then abandoned, frame drops during moments.

---

## 2. Gap analysis: what we do versus what they do

Honest in both directions.

### 2.1 Where we are already at or above a small studio

- **Measurement of art.** `harmony.py`, `qa.py`, `edit_chroma`, the
  depth floor, seam scores in `tools/rig`: few indie teams measure their
  assets this rigorously.
- **Reversible pipeline.** Raw takes kept, `relock.py`, runtime grade
  instead of baked colour (look-dev A). This is how film pipelines work.
- **Specs.** The interaction spec, the motion spec and the five rules
  of feel are better written than most studios' internal docs.
- **Deterministic motion.** `MomentCurves` makes moments pure functions
  of time, so a frame can be rendered anywhere. This is the foundation
  of a video pipeline (§3.3).
- **Cost discipline.** Zero cost at rest, `FrameMeter`, frame-time
  capture in CI.

### 2.2 The gaps

| Practice | Studios | Pofu today | Severity |
|---|---|---|---|
| Iteration loop | Seconds, in an editor or on device | Push → CI → still PNGs on a branch; motion seen only on the founder's phone | **Critical** |
| Motion review | Video and device | Six still frames of a camera flight (`look-motion`) | **Critical** |
| Colour script and lighting keys | Written and painted before production | Grade presets tuned in code against screenshots | **Critical** |
| Lighting model | Key, fill, rim, practicals, fog per state | One global grade (lift, gamma, gain, saturation, vignette) over the whole world including Pofu; additive bloom on two emitters | High |
| Harmony / consistency | Achieved by shared light and an art director's paintover | Statistical matching of every asset to one reference (chroma ceiling, white balance, material hue), which removes intended differences (rose copper → amber) | High |
| Material library | Swatches plus light behaviour | Swatches (`palettes.json`) | Medium |
| Character animation | Skeletal clips + springs + expression swaps | Springs on one image + expression composites; no bones, no clips, no timeline | High |
| Juice system | Event → bundle of tween, sound, haptic, particles, camera; data-tuned | Hand-written per moment; haptics exist; **no sound played in the app** | High |
| Tuning | Data files, live reload, debug menu | Swift constants (`LookTuning`, `PofuMotion`, springs); `WorldLook` flags; the Rehearsal panel (shield and reaches only) | High |
| UI kit and states | Every component in every state, day and night | Tokens and specs; crafted skin planned (PR #70); no state contact sheet | Medium |
| Particles | Editor-authored emitters | Custom, code-only (`WorldEmitter`, pollen, fireflies) | Low (fine at our scale) |
| Playtesting | Weekly, structured | Founder alone, from screenshots | High (fixed by the friends beta) |
| Telemetry | Funnels, feel metrics | On-device event log; nothing aggregated | Low for now |

The pattern: our **measurement** is strong and our **authorship** is
weak. We measure assets against each other, but nobody has said what the
light should be. Measurement without a target converges to the average,
which is the "flattening" the founder senses.

---

## 3. The upgrade plan

### 3.1 Constraints restated

No GUI editors, no Xcode locally, Swift compiles only on GitHub Actions
macOS runners (free while the repo is public), Linux with Python,
Blender `bpy`, Chromium, Playwright, ffmpeg; the founder reviews on his
iPhone and through screenshots and videos sent to him. Every tool below
is chosen to work inside those walls: **code is our editor, JSON is our
scene file, Python is our previewer, CI is our renderer, the phone is our
tuning surface.**

### 3.2 Ranked

Impact: how much it raises the craft the founder will feel. Cost: agent
days, including CI round trips.

| Rank | Upgrade | Impact | Cost | Depends on |
|---|---|---|---|---|
| 1 | Motion review in CI (beats → MP4) | Very high | 1–2 d | — |
| 2 | Colour script v1 + harmony v2 + rose copper restored | Very high | 2–3 d | 1 (for review) |
| 3 | Tuning panel "Ayar" + `PofuTuning` data file + JSON export | High | 2–3 d | — |
| 4 | `PofuFeedback` juice library + sound playback + feel checklist | High | 3–4 d | 3 |
| 5 | Rig v2: JSON skeletal format, Python previewer, Swift player | High | 1–2 w | 1, 3 |
| 6 | Light layers: per-asset light and emissive passes, Pofu character light, rim | High | 1 w + art batch | 2 |
| 7 | UI state contact sheet (every component × state × day/night × skin) in CI | Medium | 1–2 d | — |
| 8 | SpriteKit spike for one island mini-game round | Medium (high later) | 3–4 d | 4 |
| 9 | Structured playtest kit for the friends beta (protocol, screen recording, questions, feel metrics in the event log) | Medium | 1 d | Friends beta |
| 10 | Rive for UI micro-animation (reward reveals, animated domain icons) | Medium | Evaluate after the friends beta | Network access to rive.app; licence check |
| — | Spine, DragonBones, Live2D, Unity/Godot migration | Not now | — | See §3.6 |

### 3.3 This week

**1. Motion review in CI ("beats").** Two paths, both useful:

- **Deterministic frames (primary).** Moments and the camera are
  already functions of time (`MomentCurves`, springs advanced with fixed
  steps in tests). A `BeatRenderer` test target steps a scene at a fixed
  60 fps clock and renders each frame offscreen, then `ffmpeg` (installed
  on the macOS runner with Homebrew) encodes MP4 and a GIF preview.
  Deterministic, no dropped frames, and comparable between commits.
  Risk to check in the first CI run: `ImageRenderer` may not render
  every effect we use (Metal layer effects, system glass); where it does
  not, use the second path.
- **Real-time capture (secondary).** A UI test drives the app through a
  script while `xcrun simctl io <udid> recordVideo --codec=h264 --force
  out.mov` runs in the background and is stopped with SIGINT after the
  test ([sarunw on simctl recording][simctl]). Shows real behaviour
  (springs, gestures, glass), but CI virtual machines drop frames, so
  never judge smoothness from it; judge choreography.
- **The beat list** (`design/beats/beats.json`): Home idle 6 s, tap
  Pofu ×3, collect, build moment, Home → Island → Map → Home flight,
  each hour of the colour script as a 4 s hold, unwell entry, night
  practicals warming up. Each beat is 3–8 s.
- **Output**: the `screenshots/<branch>` branch gains `beats/*.mp4`
  and a `beats.html` contact page; the agent sends the founder the
  two or three that changed, with SendUserFile.

**2. Colour script v1 + harmony v2.** Specified in §4. This week's
cut: the script file with five hours × three wellbeing states, codegen
into `WorldLight`, the colour script strip rendered from CI, harmony's
copper target removed (rose copper restored as a protected accent), the
kettle warmed with light (the ember practical and a warm bounce), and
Pofu kept out of the world grade's saturation and contrast terms.

**3. Tuning panel "Ayar".** A third tab in the Rehearsal panel (the
founder already accepts the right-hand dev panel):

- `PofuTuning`: one `Codable` struct per domain (`motion`, `camera`,
  `look`, `feedback`, `companion`), loaded from bundled JSON
  (`Resources/tuning.json`), overridable at runtime. Every constant that
  decides feel moves there: spring responses and dampings, hop height,
  `LookTuning`, grade presets, bloom, particle counts, haptic
  intensities.
- The panel: grouped sliders generated from the struct (a small
  reflection helper, not hand-written UI per value), a time-scale control
  (0.25×, 0.5×, 1×), "replay last moment", hour and wellbeing scrubbers,
  and A/B (hold to see the default).
- **Export**: "Paylaş" produces a JSON diff of changed values through
  the share sheet. The founder sends it; the agent applies it to
  `tuning.json` in a PR. **This is the studio loop on a phone**: the
  person with taste turns the knob, the engineer commits the number.
- Debug-only: compiled out of release builds with a flag, never
  reachable by users.

### 3.4 Next: the juice library and the feel checklist

`PofuFeedback` (in `PofuDesignSystem`, used by the world and the UI):

- An **event** (`tap`, `press`, `collect`, `build`, `levelUp`, `arrive`,
  `reachResisted`) maps to a **bundle** in `feedback.json`: a tween
  (scale, offset, rotation with an anticipation and overshoot), a sound
  (one of `tools/sound`'s renders, with pitch and gain variation), a
  haptic (Core Haptics pattern, timed to the sound's transient), a
  particle burst (count, colours from the palette, shape), an optional
  hold (30–90 ms), an optional camera nudge, and a **decay** rule (the
  response shrinks on repetition within a window, interaction spec rule 4).
- A `SoundBank` on `AVAudioEngine` (the path `sound-identity.md`
  already chose), respecting the silent switch and the founder's rules
  on when sound never plays.
- Every bundle renders as a beat (§3.3), so a feedback change arrives as
  a video.

**The feel checklist** (a section per interaction in the interaction
spec, filled before an interaction is called done):

| Check | Question | Pass |
|---|---|---|
| Response | Does something visibly change within one frame of the touch? | ≤ 16 ms to first visual change |
| Envelope | Anticipation, action, follow-through present and in proportion? | Video review |
| Volume | Squash and stretch keep area? | w × h within 0.95–1.05 |
| Ease | No linear motion on anything touched? | Code review |
| Interruptible | A second touch retargets from the current state, never queues? | Test |
| Sound | Transient on the frame of contact, varied pitch, silent-switch respected? | Beat + device |
| Haptic | Matched to the transient, intensity proportional to the event's weight? | Device |
| Repetition | Ten repeats in ten seconds: still pleasant, smaller, never gone? | Beat with ×10 |
| Reduce Motion | A cross-fade or a still state that keeps the meaning? | Test |
| Light | Particles and highlights coherent with the hour's light? | Colour script strip |
| Cost | No frame over 16.7 ms on the CI capture; zero cost at rest? | `FrameMeter` |
| Meaning | Would a first-time player say what just happened? | Playtest |

### 3.5 Rig v2: a skeletal format we author in code

**Recommendation: our own small format, deliberately compatible in
concepts with Spine's JSON** (bones, slots, attachments, animations with
timelines), so we can move to Spine later without re-thinking the rig.

- `design/rig/pofu.rig.json`: bones (parent, pivot, rest transform),
  slots (draw order, the painted part from the rig pipeline), clips
  (timelines of bone rotation, translation, scale, slot swaps, with
  Bezier easing per key), and **spring channels** (a bone driven by a
  spring from its parent's motion: ears, tuft, cheeks, belly).
- `tools/rig/rig.py` grows a `play` command that renders a clip to MP4
  with the same maths as the Swift player (golden-frame tests in both
  languages compare the same frames, so the Python preview is
  trustworthy).
- `PofuCompanion` gains a `RigPlayer` that draws the parts with
  SwiftUI `Canvas` transforms; `CompanionMotion`'s springs drive the
  spring channels. No mesh deformation in v1 (it is where Spine earns its
  price); squash and stretch apply per bone.
- Clips are authored as JSON by the agent, reviewed as video, tuned on
  the phone (the Ayar panel can scrub a clip and edit keys' timing).

### 3.6 Technology evaluations

| Option | Verdict | Reasoning |
|---|---|---|
| **SpriteKit** for the world | **No migration**; spike for mini-games | The world is a few dozen layered images with a camera, a grade and DOF, which SwiftUI `Canvas` plus Metal effects already do at zero cost at rest. SpriteKit's editor (`.sks`) needs Xcode's GUI, so its main advantage is gone for us. Apple's investment is in SwiftUI and RealityKit, not SpriteKit |
| **SpriteKit** for island mini-games | **Spike one round** (rank 8) | Rounds need many moving sprites, physics, particles (`SKEmitterNode`), actions and hit testing, which is SpriteKit's strength; `SpriteView` embeds it in SwiftUI. Decide by measuring frame time and code size against a `Canvas` version |
| **Spine** | **Not now; the right choice if a human animator joins** | Runtimes are open source but shipping requires a Spine licence; `spine-ios` exists for 4.2 data ([spine-ios]). Its value is the editor and mesh deformation, neither of which we can use without a GUI. Writing Spine JSON by hand is possible (the format is documented), but then we are writing Spine's editor in JSON; our own format (§3.5) is lighter and keeps the door open |
| **Rive** | **Not for Pofu's body; evaluate for UI micro-animation** | The iOS runtime is MIT and good; state machines map well to UI. Files come from the Rive editor or, reportedly, a text-based CLI for agents ([rive-agents]); that page could not be reached from this session (`rive.app` must be allowed in the network settings), and clean exports may need a paid workspace. Re-evaluate when the friends beta starts and painted UI motion is real work |
| **DragonBones** | **No** | Partly stale ecosystem, closed Pro editor, no maintained Swift runtime ([db]) |
| **Live2D** | **No** | GUI-only Cubism editor; superb for faces but a large rig per character and commercial licence terms |
| **Lottie** | **Only for vector UI motion if Rive is rejected** | Vector only; our UI's painted faces would not benefit |
| **Unity / Godot** | **No** | Both need GUI editors to be productive, would split the app from the native UI (Liquid Glass, Screen Time extensions, widgets), and add an embedding layer. The craft gap is process, not engine |
| **Blender (`bpy`)** | **Yes, as a tool** | For lighting studies: block the island in simple shapes, light it with the colour script's key, fill and rim, and render value and light-direction references for prompts and paintovers (§4.5) |

### 3.7 What not to do

- **Do not add juice before the motion review exists.** Unreviewed
  juice is how cozy games become noisy.
- **Do not let measurement decide taste.** Harmony scores are a
  warning light, not a target. A failing score on an intended accent is a
  config bug, not an art bug.
- **Do not chase engines.** The founder's instinct ("proper colour and
  light design") is right: the biggest jump in perceived quality is
  authored light, not new technology.

---

## 4. Colour and light: Pofu's colour script

### 4.1 Diagnosis: why the rose copper looked sweet, and why harmony flattened it

Look round 2 measured the çaydanlık's copper at hue 54, on the palette's
own pink-leaning copper (`#D4875F`, hue 53), and moved it to 59 with a
material target halfway to tea-amber (`#E09A55`), because the founder
had said the teapot "reads cold" (look-dev, look round 2;
`design/art/harmony/config.json` on PR #61). Two mistakes, both ours:

1. **The kettle read cold because of light, not paint.** It sits under
   the same neutral day light as everything else, with no warm key on its
   belly, no bounce from the ember, and the ember's bloom is additive
   glow, not light falling on the copper. Real copper beside a coal fire
   looks warm because the fire lights it. Changing the metal's hue made
   it a different metal (brass-ish) and took away the rose that made it
   _sweet_ against the sage lawn and the cream walls.
2. **Harmony matches statistics to one reference.** It pulls black
   point, white point, chroma ceiling and white balance of every asset
   toward the approved island, and material hue toward a target. That is
   right for what the generator gets wrong (value range, the colour of
   the light the generator imagined, chain fading), and wrong for what
   the art director wants different (a rose accent, a saturated flower, a
   dark doorway). Measured without a colour plan, it converges to the
   average.

### 4.2 The model: three layers, owned separately

| Layer | What it is | Who owns it | Where it lives |
|---|---|---|---|
| **Local colour** | The colour of things under neutral light: rose copper, honey wood, milky glaze, sage lawn, cream fur | The art bible and the **material library** | The masters (generated under `lock-light`), corrected by harmony only for generator errors |
| **Light** | Key (sun or moon: direction, colour, intensity), fill (sky colour into shadows), rim, practicals (ember, lantern, windows), fog per depth band | The **colour script** | `design/art/colour-script.json` → `WorldLight` and the light layers (§4.5) |
| **Grade** | The camera: final contrast curve, a gentle saturation trim, vignette, the mood push of wellbeing | The colour script, in small amounts | `WorldGrade` (already built) |

Today the grade does the work of all three. The shift: **light carries
time of day; grade only finishes it; local colour is protected.**

### 4.3 The colour script

**Axes.** Five hours × three wellbeing states, plus calm as a modifier:

- Hours: **dawn** (5:30–7:00), **day**, **golden** (17:30–19:30),
  **dusk** (19:30–20:30, new: the blue hour, where practicals turn on),
  **night** (from 20:30; bedtime always night).
- Wellbeing: **well** (≥ 55), **low** (55–30), **unwell** (< 30). The
  emotional arc must read in light: unwell is not "desaturated", it is
  **overcast** (a soft, low, cool key with weak shadows) so the world
  feels quieter, never dead (ADR-0017).
- Calm (×1.0 → ×2.0): a modifier on practicals and the lantern's glow,
  never on the key.

**Each cell defines** (starting values to tune in Ayar; hexes from our
palettes where they exist):

| Field | Meaning |
|---|---|
| `key` | Direction (angle from the upper left, elevation), colour, intensity |
| `fill` | Sky colour in the shadows, intensity |
| `shadowHue` | The hue shadows lean to (never neutral grey) |
| `rim` | Colour and strength of the edge light on Pofu and stations |
| `practicals` | Ember, lantern, windows: on/off, colour, radius, intensity |
| `fog` | Colour and amount per depth band (far isles, mid plates, near) |
| `valueRange` | Target black and white points for the frame (the composite, measured by `frame_metrics.py`) |
| `gamut` | A gamut mask: the hue sector and chroma limit for **large areas** |
| `accentBudget` | Which materials may exceed the gamut, and the max area (e.g. ≤ 4 % of the frame) |
| `grade` | The residual camera grade (small) |
| `focus` | Where the strongest value contrast must sit (Pofu at Home, the focused station at Island) |

**First pass of the script (to paint over, then tune):**

| Cell | Key | Fill and shadows | Practicals | Gamut and accent | Feeling |
|---|---|---|---|---|---|
| Dawn · well | Low from the left, peach `#F4C7A4`, 0.7 | Lilac fill, shadows to violet `#B9A2FF` at low strength | Ember low | Pastel, narrow; accent: rose copper catching the first light | Hush, promise |
| Day · well | High from the upper left, warm white `#FFF6EC`, 1.0 | Sky-blue fill, shadows cool violet-grey, never grey | Off | Widest gamut; accents: rose copper, awning rose `#EE9A90`, petal honey | Bright, clear, toy-like |
| Golden · well | Low from the left, honey `#F7C873`, 1.1 | Fill lilac-rose, long shadows to violet | Ember on | Warm half of the wheel; rose copper glows (the light and the metal agree) | The day's reward |
| Dusk · well | Sun gone; sky key from above, violet-blue, 0.5 | Shadows deepen to indigo `#2E2547` | Ember, lantern and the round window turn on | Cool large areas, warm practicals as the only accent | Coming home |
| Night · well | Moon, cool lilac `#B8A8B1`, 0.35 | Deep indigo `#1E1828` shadows, true darks (round 2) | Lantern, ember, windows carry the frame; warm pools on nearby objects | Cool gamut; accent: everything a practical touches | Safe, cozy |
| Any · low | The hour's key × 0.85, colour 10 % toward the fill | Softer shadows | Unchanged | Gamut chroma limit × 0.85 | A thinner day |
| Any · unwell | Overcast: key diffused (no hard shadows), 0.7, cooler | Fill dominant, grey-blue | Lantern on even by day (care is still here) | Chroma × 0.6 for large areas; **Pofu and one practical keep full colour** | Quiet, not dead; the lantern says "come back" |

**The rule for Pofu.** Pofu takes the hour's key and rim, never the
grade's saturation cut or contrast push. He is the focal point, and his
cream fur is the brightest mid-value in every cell except night, where
the lantern rim takes that role. This replaces today's single grade over
"sky, plates, stations, residents, Pofu".

**Deliverables:**

1. `design/art/colour-script.json` (the cells above as data) and a
   generated `ColourScript+Generated.swift` (the pattern
   `WorldArt+Generated.swift` already uses), so Swift never hand-copies
   numbers.
2. **The colour script strip**: CI renders the Home framing at each
   cell (the `hourOverride` and `gradeOverride` flags already exist) and
   a Python script assembles a 5 × 3 strip with each cell's swatches
   (key, fill, shadow, accent) under it. This is the art director's one
   page; it is reviewed before any new asset batch.
3. **Paintovers**: for the three cells that matter most first (day,
   golden, night), a paintover of the CI frame (GPT Image edit of the
   screenshot with the cell's light described, plus a Blender light study
   of the island blocked in simple shapes for direction and shadow
   shape). The paintover is the target; the code chases it, measured by
   `frame_metrics.py`.

### 4.4 The material library

`design/art/materials.json`: each recurring material's **local colour**
(hue, chroma and value range under neutral light), how it **responds to
light** (matte, satin, metal: metal takes the light's colour strongly and
gets a specular glint; glaze gets a soft highlight; fur gets rim and
subsurface warmth), and whether it is an **accent** (allowed outside the
cell's gamut).

| Material | Local colour | Response | Accent |
|---|---|---|---|
| **Rose copper** (çaydanlık, lantern cap, tray) | Hue 50–56, chroma 38–48, `#D4875F` with `copper-light` `#EFB28E` highlights: **pink-leaning, never brass** | Metal: tinted by the key strongly; a sharp warm glint; reflects the ember | Yes, ≤ 3 % of the frame |
| Honey wood | Hue 58–68 (`wood` `#D9925E`, `wood-shade` `#B9784C`) | Satin | No |
| Milky glaze (jar, pots) | Cream to peach, low chroma | Glaze: soft broad highlight | No |
| Sage lawn | Meadow family, mid chroma | Matte; takes the fill strongly in shadow | No |
| Awning rose, petal honey | `#EE9A90`, `#F6C95C` | Matte | Yes, small |
| Pofu's fur | Cream to peach, char-guarded | Fur: rim and warm subsurface; never desaturated | Hero, by value not chroma |
| Practical light (ember, lantern) | Amber to honey | Emissive: unaffected by the grade, lights its neighbours | Yes, at dusk and night |

The rose copper and the honey wood are separated **by hue and by
response**, not by moving one toward the other: copper is pinker and
shinier, wood is yellower and duller. That contrast is what made the
original kettle sweet.

### 4.5 Lighting a painted 2.5D world with our tools

Painted plates have no normals, so studios fake light. Options, cheapest
first:

1. **Light-aware compositing in the grade** (now): per-layer key tint
   and intensity by depth band (near, mid, far) plus fog per band, so
   distance lowers contrast and shifts toward the sky (atmospheric
   perspective). A small addition to `WorldGrade`'s inputs.
2. **Practical light pools** (now): the ember and lantern draw an
   additive warm pool on the objects around them (a radial light with
   falloff, masked by the receiving sprite's alpha), not only a halo. This
   is what warms the kettle.
3. **Rim pass for Pofu and stations** (soon): a rim mask derived in
   Python from each sprite's alpha (distance from the edge, offset away
   from the key direction), baked by `preblur.py`, tinted at runtime by the
   cell's rim colour. Cheap, consistent, and the single biggest
   "HD-2D" cue on characters.
4. **Pseudo-normals from alpha** (soon): a "bulge" normal map estimated
   from the alpha distance field (the approach of 2D normal-map tools such
   as Laigter and Sprite Lamp), so the key can wrap around rounded objects
   with a Metal shader. Good on round things (jar, pots, Pofu), poor on
   flat ones; use per asset.
5. **Painted light passes** (with the art queue): for hero assets, the
   generator paints a matched "lit by the ember" or "night" version (the
   founder already asked for real day and night versions of some assets);
   the runtime blends them by the cell's practical intensity.

### 4.6 Harmony v2: serve the script, do not flatten

Keep the tool; change what it targets.

| Today | v2 |
|---|---|
| Every world asset matched to one reference (the approved island) | Every asset matched to the **neutral-light standard**: value range, the neutrals' white balance (the generator's imagined light removed), edge and detail at display size. Light is added at runtime by the script, so assets must arrive _unlit_ in a consistent way |
| Chroma ceiling (C p95) matched to the reference | **Area-weighted chroma** for large areas (the lawn, walls, plates) against the material library; small accent regions measured separately against their own material, never capped by the reference |
| Material hue moved toward a target (copper → amber) | Material hue checked against **its own material's range**; a correction only when the generator drifted out of it (rose copper outside 50–56 is pulled back **to rose**) |
| A single score | Three scores: **standard** (value, white balance, edges), **materials** (each in range), **script** (the CI frame in each cell inside its gamut, accents within budget, focus contrast where it should be) |
| Pass or fail per asset | Asset checks at promote time; **frame checks** on the colour script strip, because harmony is a property of a frame under light, not of a file |

Concretely for this week: remove the copper `target_hue` / `target_chroma`
from `design/art/harmony/config.json` (PR #61), replace it with a
material range check, re-bake, and warm the kettle with the ember's light
pool. Pofu and characters stay guarded, as today.

### 4.7 How a colour decision is made from now on

1. The cell is changed in `colour-script.json` (or tuned in Ayar and
   exported).
2. CI renders the strip and the affected beats.
3. The agent compares against the paintover and the frame metrics.
4. The founder sees the strip and one video, and says yes or no.
5. Only then are new assets generated for it.

---

## 5. The UI language: quality, harmony, elegance, playfulness

The founder's four words, each turned into rules we can check:

| Word | Rule | Check |
|---|---|---|
| **Quality** | Every element is finished in every state (normal, pressed, disabled, focused, night, Dynamic Type XXL, Reduce Transparency). Optical alignment, consistent radii from tokens, no blurry raster at any scale | UI state contact sheet in CI (rank 7) |
| **Harmony** | One light, one palette, one motion grammar. UI picks up the colour script's light: a warmer glass tint at golden hour, the night variant at night, the crafted faces have painted night versions (UI system v2 already plans them) | The strip includes the chrome; the tint follows the cell |
| **Elegance** | Restraint: one primary action per screen, the accent budget applies to UI too (violet is the action colour and appears once), two type weights per screen, motion that settles without wobble in chrome (interaction spec rule 3) | Accent area measured on CI frames; design review |
| **Playfulness** | The world answers the UI: pressing "Topla" makes Pofu's cheeks empty with a squish and a chew sound; a level-up stamps with a hold and a ribbon flutter; every press has a three-part feedback (press down, release overshoot, sound) from `PofuFeedback` | Feel checklist per interaction; beats |

Royal Match is the reference for playfulness at scale and Monument Valley
for elegance: in both, the interface and the world share one material
and one light, and every touch gets a response.

---

## 6. Sources

- Adam Robinson-Yu, _Crafting a Tiny Open World: A Short Hike Postmortem_, GDC 2020: [short-hike]
- Ken Wong, _Designing Monument Valley: Less Game, More Experience_, GDC Europe 2014: [mv-design]; _The Art of Monument Valley_: [mv-art]; Unity on Monument Valley 3: [mv3]
- ustwo games, _The Environment Art of Alba_: [alba]
- Unreal Engine, _Octopath Traveler's HD-2D art style_: [octopath]; Unreal Fest Europe 2019, _The Fusion of Nostalgia and Novelty in the Development of Octopath Traveler_: [octopath-talk]
- Yuichiro Tanabe, _Art of Sky: Children of the Light_, GDC Summer 2020: [sky]; Pocket Tactics recap: [sky-recap]
- James Benson, _Animating Ori_, GDC 2015: [ori-anim]; Moon Studios, _The Art of Ori and the Will of the Wisps_, GDC 2021: [ori-art]
- Unity, _The recipe behind Cult of the Lamb_: [cotl-unity]; James Pearmain interview, Inverse: [cotl-rig]
- Jeff van Dyck, _Unpacking: The Fun Behind the Foley_, GDC 2022: [unpacking]
- Royal Match: [royal]; ironSource, _Design deep dive: Royal Match_: [royal-dive]
- Pocketgamer.biz, _What happened to Pokémon Sleep_: [psleep]
- Martin Jonasson and Petri Purho, _Juice It or Lose It_: [juice]; _Don't Juice It or Lose It_: [dont-juice]; Jan Willem Nijman, _The Art of Screenshake_ (coverage): [screenshake]
- Esoteric Software, spine-ios and the Spine Runtimes licence: [spine-ios]
- Rive runtime: [rive-rt]; Rive for agents (not reachable from this session): [rive-agents]
- DragonBones ecosystem notes: [db]
- `simctl` video recording: [simctl]
- Books: James Gurney, _Color and Light: A Guide for the Realist Painter_ (2010); Steve Swink, _Game Feel_ (2008); _The Art of Pixar: 25th Anniversary_ (colour scripts).

[short-hike]: https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A
[mv-design]: https://www.gdcvault.com/play/1021380/Designing-Monument-Valley-Less
[mv-art]: https://gdcvault.com/play/1025003/The-Art-of-Monument-Valley
[mv3]: https://activation.unity3d.com/resources/monument-valley-3-blurring-art-and-design
[alba]: https://medium.com/@ustwogames/the-environment-art-of-alba-a-wildlife-adventure-6bddd8b56955
[octopath]: https://www.unrealengine.com/en-US/spotlights/octopath-traveler-s-hd-2d-art-style-and-story-make-for-a-jrpg-dream-come-true
[octopath-talk]: https://www.unrealengine.com/events/unreal-fest-europe-2019/the-fusion-of-nostalgia-and-novelty-in-the-development-of-octopath-traveler
[sky]: https://gdcvault.com/play/1026812/Art-of-Sky-Children-of
[sky-recap]: https://www.pockettactics.com/sky-children-of-the-light/art
[ori-anim]: https://gdcvault.com/play/1022925/-Ori-and-the-Blind
[ori-art]: https://gdcvault.com/play/1027035/The-Art-of-Ori-and
[cotl-unity]: https://unity.com/es/blog/games/recipe-behind-smash-hit-cult-of-the-lamb
[cotl-rig]: https://inverse.com/gaming/cult-of-the-lamb-concept-art-interview-massive-monster/amp
[unpacking]: https://gdcvault.com/play/1027728/-Unpacking-The-Fun-Behind
[royal]: https://en.wikipedia.org/wiki/Royal_Match
[royal-dive]: https://medium.com/ironsource-levelup/design-deep-dive-02-royal-match-948f7af96f04
[psleep]: https://www.pocketgamer.biz/what-happened-to-pokemon-sleep/
[juice]: https://gdcvault.com/play/1016789/Juice-It-or-Lose
[dont-juice]: https://gdcvault.com/play/1020861/Don-t-Juice-It-or
[screenshake]: https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games
[spine-ios]: https://esotericsoftware.com/git/spine-runtimes/spine-ios
[rive-rt]: https://github.com/rive-app/rive-runtime/wiki
[rive-agents]: https://rive.app/agents
[db]: https://forum.gdevelop.io/t/dragonbones-implementation/42579
[simctl]: https://sarunw.com/posts/take-screenshot-and-record-video-in-ios-simulator/
