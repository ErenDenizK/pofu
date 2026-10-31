# Pofu: Character Bible

_Status: v0.1, **under revision**: species and rendering style are being
re-explored in [character-exploration.md](character-exploration.md). Last
updated: 2026-10-31._

## Who Pofu is

Pofu is a small, round fluffball who lives in your phone and feeds on the
time you spend _living_. When you study, walk, sleep on time, or put the
phone down, Pofu gets fluffier, brighter, and bouncier. When you doomscroll,
Pofu's fluff gets matted, its color drains, and it slowly deflates.

Pofu is **not** a guilt machine. Pofu is on your side, a little cheeky, a
little dramatic, and always happy to see you. The emotional contract:
_"I'm not judging you. I just feel better when you do."_

## Design principles

1. **Silhouette first.** Pofu must be recognizable as a solid black shape at
   16 points: a round fluffy body, a single tuft on top, two stubby feet.
2. **Built from parameters, not drawings.** Every visual trait is a number
   the app can animate. No pose exists that the rig cannot reach smoothly from
   any other pose.
3. **Few features, big expression.** Eyes, mouth, tuft, and body posture
   carry everything. No eyebrows, no nose, no fingers.
4. **Wellbeing is visible at a glance.** You should be able to tell how your
   week went from Pofu alone, without reading a number.
5. **Never grotesque.** A wilting Pofu is sad and matted, never sick, injured,
   or disgusting. The reference apps' "decaying brain" stops at gray and
   droopy, and so do we.

## Anatomy

| Part | Description | Expressive role |
|---|---|---|
| **Body** | A soft, slightly bottom-heavy sphere. The outline is a ring of fluff bumps, not a smooth circle. | Fluffiness, squash and stretch, breathing, color |
| **Tuft** (_perçem_) | One curled lock of fluff on top of the head. Pofu's signature. | The mood antenna: perked up when happy, curled when curious, flat when wilting |
| **Eyes** | Large, glossy, set low and wide. Two highlights each. | Openness, gaze direction, happy arcs, sleepy lids, sparkle |
| **Mouth** | Small and simple, under and between the eyes. | Smile, frown, "o", tiny open laugh |
| **Cheeks** | Soft blush ovals below the eyes. | Warmth; brightest when thriving or flattered |
| **Feet** | Two stubby rounded feet peeking out under the fluff. | Hops, waddles, standing posture |
| **Arms** | Optional small fluff nubs that appear only for gestures (waving, holding props). | Gestures, props (tea glass, simit, dumbbell) |

## Color

| Token | Role | Value (initial) |
|---|---|---|
| `pofu.body.thriving` | Body at full vitality | Lilac `#B9A2FF` |
| `pofu.body.shade` | Lower body shading | Violet `#8F74F0` |
| `pofu.body.light` | Top highlight | Lavender mist `#E4DAFF` |
| `pofu.body.wilted` | Body at zero vitality | Ash lilac `#A8A3B3` |
| `pofu.cheek` | Blush | Rose `#FF9EC1` |
| `pofu.eye` | Eyes | Ink `#1E1A2E` |

Why lilac: the category is dominated by sky blue (Unrot) and salmon or pink
brains (Brainrot, Unrot). Lilac is unclaimed, reads as soft and friendly
across cultures, contrasts with the green meadow world, and drains into a
convincing gray when Pofu wilts.

## The parameter model

The rig is driven by a single `PofuPose` value. Every state is a preset of
these parameters; transitions are spring interpolations between presets.

| Parameter | Range | Effect |
|---|---|---|
| `vitality` | 0…1 | Master wellbeing: color saturation, fluff volume, posture height |
| `fluff` | 0…1 | Amplitude and regularity of the outline bumps (1 = cloud, 0 = matted) |
| `squash` | -1…1 | Vertical squash (negative) or stretch (positive), volume-preserving |
| `lean` | -1…1 | Body tilt left or right |
| `eyeOpen` | 0…1 | 0 = closed lids, 1 = wide open |
| `eyeSmile` | 0…1 | Morphs the eyes into happy upside-down arcs |
| `gazeX`, `gazeY` | -1…1 | Pupil direction |
| `sparkle` | 0…1 | Size of the eye highlights |
| `mouthCurve` | -1…1 | Frown to smile |
| `mouthOpen` | 0…1 | Closed to open |
| `blush` | 0…1 | Cheek intensity |
| `tuftPerk` | -1…1 | Flat and droopy to springy upright |
| `breath` | animated | Idle breathing cycle, slower and deeper when calm |

## Core states

| State | When | Pose summary |
|---|---|---|
| **Thriving** | High vitality, good streak | Max fluff, bright lilac, sparkle, gentle bounce, tuft upright |
| **Content** | Default | Relaxed fluff, soft smile, slow breathing |
| **Curious** ("Hop!") | Intervention: reaching for a blocked app | Leans in, eyes wide, tuft curled into a question mark, small "o" mouth |
| **Tired** | Moderate scrolling today | Half-lidded eyes, slower breath, fluff slightly flat |
| **Wilting** | Heavy scrolling | Gray, matted fluff, squashed down, tuft flat, small frown |
| **Sleeping** | Bedtime schedule active | Eyes closed, deep slow breathing, tuft curled, optional "z" |
| **Celebrating** | Streak milestone, impulse resisted | Happy-arc eyes, open smile, jump with squash and stretch, blush |
| **Focused** | Focus session running | Eyes closed calmly, symmetric posture, minimal motion, meditative breath |

## Motion language

- **Springs, not easing curves.** All transitions use critically damped or
  slightly bouncy springs. Pofu is soft; nothing moves linearly.
- **Squash and stretch** on every landing and every tap.
- **Idle life:** breathing, an occasional blink every 3–6 seconds, rare
  glances, and a tuft that reacts a beat after the body moves (follow-through).
- **Touch:** tapping Pofu triggers a squish and a giggle haptic; long-pressing
  makes it melt into a happy puddle.
- **Respect Reduce Motion:** fall back to crossfades and static poses.

## Voice and personality

Pofu speaks in short, warm, slightly cheeky lines. Never preachy, never
statistics-first, never shaming.

| Situation | English | Türkçe |
|---|---|---|
| Intervention | "Hop! Where to?" | "Hop! Nereye?" |
| Intent question | "What are we opening this for?" | "Ne için açıyoruz bunu?" |
| Resisted | "Look at you. I feel fluffier already." | "Bak sen şuna. Şimdiden kabardım." |
| Gave in (no shame) | "Okay! Ten minutes. I'll be right here." | "Tamamdır! On dakika. Ben buradayım." |
| Wilting | "I'm a little flat today. Walk with me?" | "Bugün biraz söndüm. Biraz yürüyelim mi?" |
| Bedtime | "The feed will still be there tomorrow. I promise." | "Akış yarın da orada olacak. Söz." |

Turkish copy is written natively, not translated: it uses natural spoken
register (_"açıyoruz"_, the friendly inclusive "we") and local warmth.

## Don'ts

- No death, illness, injury, or tears. The lowest state is gray and flat.
- No anthropomorphic clothing by default; cosmetics are opt-in.
- No sarcasm aimed at the user. Pofu teases situations, never the person.
- No exclamation marks in every line; enthusiasm is rationed.
