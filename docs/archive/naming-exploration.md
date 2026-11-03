# Naming Exploration

> **Archived (2026-11-02).** Decided: Pofu ([ADR-0007](../adr/0007-product-name-pofu.md)). Kept as the record of the options.

_Status: **decided: Pofu** ([ADR-0007](../adr/0007-product-name-pofu.md)). Last updated: 2026-10-31._

## Why the name matters more than usual here

In a character-driven product the name and the character are one system.
Duolingo has Duo; Finch is the bird. The best outcome is a name that is
simultaneously the app, the species of the companion, and a word users say
out loud.

## Criteria

1. **Bilingual:** pronounceable and positive or neutral in both English and
   Turkish. No `ğ`, `ı`, `ş`, `ç` in the primary brand (App Store search,
   domains, and international typing).
2. **Short:** one or two syllables, five letters or fewer is ideal.
3. **Story-bearing:** the name should explain the mechanic or the character
   without a tagline.
4. **Ownable:** available on the App Store, registrable as a trademark in
   Türkiye (TÜRKPATENT) and the EU/US, with a reasonable domain.
5. **Not derivative:** must not read as a clone of Brainrot or Unrot.

## The current codename: Rot

| | |
|---|---|
| For | Instantly signals the "brainrot" cultural moment. In Turkish, _rot ayarı_ (wheel alignment) suggests "realigning your brain", a nice double meaning. |
| Against | In English, "rot" means decay: the brand would be named after the problem, not the outcome. Sits in the shadow of Brainrot and Unrot and invites "clone" comparisons. |
| Verdict | Keep as the internal codename; do not ship as the brand. |

## Three directions

Each direction pairs a name with a character concept, because they cannot be
judged separately.

### Direction A: **Kor** (the ember)

- **Meaning:** Turkish _kor_ is a live ember, the glowing coal that keeps a
  fire alive. English speakers read it as "core".
- **Character:** a small ember spirit living in the user's phone. Real-life
  activity is kindling and makes it glow brighter and bigger. Doomscrolling
  smothers it in ash and it dims. **The streak flame is the character itself**:
  the TikTok-style streak and the companion become one object.
- **For:** the most coherent system. Health, streak, and energy are all
  "warmth", so one visual language explains the entire product. Short and
  strong in both languages.
- **Against:** fire characters are a crowded visual space (Duolingo's streak
  flame; Calcifer from _Howl's Moving Castle_ is the obvious trap to avoid).
  An English-language screen time app called "Ember" already exists, so the
  metaphor is not unique, even if the word is. Three-letter trademarks are
  hard to register.

### Direction B: **Pofu** (the fluffball)

- **Meaning:** from Turkish _pofuduk_, "fluffy" or "puffy", a word that is
  affectionate and funny on its own. Meaningless but cute in English, like
  Pokémon names.
- **Character:** a round, soft creature whose fluff is its wellbeing. Living
  well makes it fluffy, bright, and bouncy. Rotting makes it matted, grey, and
  deflated. Users name their own Pofu (the IKEA effect: you love what you
  name).
- **For:** maximum huggability, so it works on stickers, widgets, the app
  icon, and merchandise. Simple round silhouettes suit the code-native rig
  (ADR-0006) perfectly. No App Store collision found in an initial search.
- **Against:** skews younger and cuter; the brand must earn credibility with
  craft and wit, not seriousness. The name carries no meaning for
  non-Turkish users.

### Direction C: **Hop** (the interjection)

- **Meaning:** in Turkish, _"Hop!"_ is what you say to stop someone mid-action
  (_"Hop hop, nereye?"_ means "Whoa whoa, where do you think you're going?").
  In English, "hop" means a small jump, as in "hop off your phone".
- **Character:** a small bouncy creature that literally hops in front of the
  apps you are about to open. The intervention screen writes itself: _"Hop!
  Do you really need TikTok right now?"_
- **For:** the strongest brand voice; the name is the core interaction. Very
  short and very memorable in both languages.
- **Against:** a generic English word, so App Store search and trademark
  registration will be crowded. The character species is less defined than in
  A or B.

## Recommendation

**B (Pofu) for the character, with a final check on whether "Pofu" or a
"Hop"-style app name carries the brand.** The fluffball has the best fit with
our rendering approach, the widest emotional appeal, and the cleanest
ownership path. Kor is the most intellectually elegant concept and remains a
strong alternative if the founder prefers a cooler, less cute brand.

## Next steps

1. Founder reacts to the three directions (gut feeling counts).
2. For the top one or two, produce a character concept sheet: silhouette,
   expressions, wilted and thriving states. These start as AI-generated
   concept art from prompts written in `docs/brand/`, then are rebuilt as
   code-native prototypes.
3. Run availability checks: App Store (TR and US), TÜRKPATENT, EUIPO, USPTO,
   domains, and social handles.
4. Record the final decision as an ADR.
