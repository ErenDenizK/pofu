# Narrative craft: tools, resources, and a human-first writing pipeline

_Status: research and recommendation, 2026-11-03. Draft for the founder.
Reads with: [lore bible](../product/lore-bible.md) (the first draft this
pipeline is meant to improve), [Pofu's voice](../brand/pofu-voice.md)
(the rules; the line bank is parked), the
[character bible](../brand/character.md) and the
[archipelago system](../archive/archipelago-system.md)._

The founder's ask (2026-11-03, translated): _"Design a story and lore.
For the best, realistic, human story flow and lore, research suitable
tools, GitHub repos and skills. I don't trust standard AI output for
creative story and lyricism. You start with real human spice; if needed my
friends and I will step in."_

## 0. The answer in one page

- **Tool: write Pofu's dialogue and lore in Yarn Spinner 3's language**
  (`.yarn` plain text), not ink, Twine, articy, Dialogic or Narrat.
  Three reasons: it has **line IDs and string tables built in** (Turkish
  first, other languages later, without rewriting the scripts); its
  **node groups and saliency** (`when:` conditions) are exactly Pofu's
  shape, which is mostly "pick the right short line for this state", not
  long branching; and a cozy island game we already study, **A Short
  Hike**, shipped its dialogue with it. The cost: there is no Swift
  runtime, so we stage it: writers use `.yarn` now, CI compiles and
  extracts strings with the official `ysc` tool, and the app keeps its
  Swift line selection until a small Swift runner earns its place (spike,
  then an ADR). Section 1.
- **AI writing is measurably generic.** Expert writers found LLM stories
  pass 3 to 10 times fewer creativity tests than professional ones, and
  LLMs could not judge creativity either ([Chakrabarty et al., CHI
  2024](https://arxiv.org/abs/2309.14556)); AI-assisted stories are
  individually "better" but **more similar to each other**
  ([Doshi and Hauser, Science Advances 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11244532)).
  Similarity is the founder's "AI slop": the line could be in any app.
  Section 3.
- **So the AI's job is scaffolding, never the last word.** It drafts
  structure, continuity and options; humans own every shipped line. A
  line ships only after a human has rewritten it or approved it after
  reading it aloud. Section 4.
- **The pipeline in four lines:** (1) the agent drafts against the lore
  bible with margin notes marking where a human must rewrite; (2) the
  founder and two or three friends do **spice passes** in a shared sheet
  (keep, tweak, rewrite, cut, plus one detail only they would know);
  (3) a **read-aloud** by someone who did not write it, recorded as a
  WhatsApp voice note; (4) a **10-person panel** in two rounds of five
  rates blind pairs, and only lines that survive get locked. Section 4.
- **Craft rules that make writing feel human** (section 3): a voice bible
  anchored in real excerpts, specificity over adjectives, the iceberg
  (know ten facts, show one), wants and wounds under every character,
  humour from the body and the everyday, and a Turkish-native idiom check
  that catches calques an AI produces without noticing.

## 1. Narrative tools, and which fits an iOS SwiftUI app

### 1.1 What Pofu's text actually is

Before choosing, the shape of the content:

| Kind | Volume | Shape |
|---|---|---|
| Shield and Hop! lines | Hundreds | **Salience**: one short line picked by state (time, reach count, wellbeing, app) |
| Island story beats (five stages per island) | About 30 lines per island, 50 islands | Short linear scenes, one or two speakers, rare choices |
| Resident barks on tap | 5 to 10 per resident | Salience with "don't repeat recently" |
| Rumours, letters, keepsake stories | One or two lines each | Linear, triggered |
| Lore (bells, archive, letters) | Small | Revealed in pieces across months |

So Pofu needs **(a)** a format a non-programmer friend can read and edit,
**(b)** stable line IDs for translation and for review sheets, **(c)**
condition-based selection more than deep branching, and **(d)** a native
Swift path with no JavaScript in app extensions (the Screen Time shield
extension has a tight memory budget and already picks its copy in Swift,
`ShieldCopy.swift`).

### 1.2 The candidates

| Tool | What it is | Writer experience | Localisation | Swift / iOS path | Fit for Pofu |
|---|---|---|---|---|---|
| **Yarn Spinner 3** | Screenplay-like dialogue language; core MIT ([licensing FAQ](https://yarnspinner.dev/license)); used by Night in the Woods, A Short Hike, DREDGE, the Frog Detective games ([Yarn Spinner](https://yarnspinner.dev/timeline/), [Game Developer](https://gamedeveloper.com/programming/deep-dive-yarn-spinner)) | Reads like a play script; VS Code extension with a graph view and live preview ([docs](https://docs.yarnspinner.dev/getting-started/editing-with-vs-code/writing-yarn-in-vs-code)); a browser playground (Try Yarn Spinner) | **Built in**: every line gets a `#line:` ID; a strings table per language ([docs](https://docs.yarnspinner.dev/yarn-spinner-for-unity/assets-and-localization)) | No Swift runtime. Compiler and runtime are C#; community Rust ([crate](https://docs.rs/yarnspinner_runtime)) and TypeScript ports exist. `ysc` compiles to a program plus strings and metadata tables, and extracts CSV or XLSX ([YarnSpinner-Console](https://github.com/YarnSpinnerTool/YarnSpinner-Console), [NuGet 3.2.2](https://www.nuget.org/packages/yarnspinner.console)) | **Best.** Node groups with `when:` conditions and saliency strategies such as `best_least_recent` are Pofu's line selection, designed by people who build games ([node groups](https://docs.yarnspinner.dev/next/write-yarn-scripts/syntax-basics/node-groups), [saliency](https://docs.yarnspinner.dev/write-yarn-scripts/advanced-scripting/saliency)) |
| **ink** (inkle) | Prose-first narrative scripting, MIT ([repo](https://github.com/inkle/ink)); behind 80 Days, Sorcery! and Heaven's Vault ([Game Developer](https://gamedeveloper.com/design/how-inkle-developed-its-own-ancient-language-for-i-heaven-s-vault-i-)) | The best editor for writers (Inky); text flows like a book with inline choices | **Weak.** ink splices text fragments; the community has bolted on ID tools, and their own README says ink is not designed for localisation ([ink #98](https://github.com/inkle/ink/issues/98), [#514](https://github.com/inkle/ink/issues/514), [LocaliserLib](https://www.nuget.org/packages/wildwinter.LocaliserLib)) | inkjs via JavaScriptCore ([ink-iOS](https://www.github.com/russellquinn/ink-iOS), Objective-C, "very early"), or [InkSwift](https://www.github.com/maartene/InkSwift) (Apache-2.0, 13 stars; its new pure-Swift runtime lacks LIST, RANDOM, threads and EXTERNAL functions) | Strong for long branching prose, which Pofu does not have. **Its signature strength, splicing sentence fragments, is a liability in Turkish**: suffixes follow vowel harmony (Instagram'**ı**, YouTube'**u**, TikTok'**u**), so spliced fragments break grammar |
| **Twine** | Browser hypertext tool; stories are web pages | Lowest barrier on earth; anyone can make a branching draft in an evening | None to speak of | None; it produces HTML | **The napkin.** Use it (or Try Yarn Spinner) for a friend to sketch a branching idea; never the pipeline |
| **articy:draft X** | Professional narrative database (flow, entities, locations) for big studios | Powerful, heavy; Windows and Mac | Strong, with exports | JSON export, official Unity and Unreal importers only ([integrations](https://www.articy.com/help/Integrations_Overview.html)); a free tier of 700 objects per project, then a subscription with no perpetual licence ([shop](https://www.articy.com/shop/?p=9999), [FAQ](https://www.articy.com/en/frequently-asked-questions/)) | Overkill: a team of writers on an RPG. Pofu's 50 islands × 30 lines would exceed the free tier, and we would write our own JSON importer anyway |
| **Dialogic 2** | Godot dialogue and visual-novel plugin | Visual timeline editor plus a text format | Godot's | Godot only, and its docs still call it alpha ([docs](https://scriptagc.wasmer.app/https_docs_dialogic_pro/getting-started_html)) | Not applicable |
| **Narrat** | A whole narrative RPG engine in TypeScript and Vue, MIT ([repo](https://github.com/liana-p/narrat-engine), [docs](https://docs.get-narrat.com/others/what-can-narrat-do.html)) | Own script language plus YAML config | Its own | It *is* the app (a web or Electron game) | Not applicable; a different product shape |

### 1.3 The pick: Yarn Spinner 3's language, staged

**Why Yarn over ink, in one sentence:** ink is the better tool for a
novel with choices; Yarn is the better tool for **many short, reactive,
translatable lines chosen by state**, which is what Pofu is.

- **Localisation is the deciding axis.** Pofu is Turkish first, global
  later. Yarn's model, one line = one ID = one translatable string, is
  also the only model that survives Turkish morphology: we write whole
  lines per app ("Yine mi Instagram'a?"), never "Yine mi {app}'a?".
- **Saliency is native.** Today `ShieldCopy.swift` hand-codes the
  ladder (reach count, time of day, jealousy budget). Yarn 3 node groups
  express the same thing as data writers can read: several nodes share a
  title, each has `when:` conditions, the runtime runs the most specific
  one and can prefer the least recently seen. Writers can add a line for
  "third reach, after midnight, TikTok" without touching Swift.
- **Precedent.** A Short Hike, the closest tonal cousin to our islands,
  integrated its dialogue with Yarn Spinner ([MCV/Develop](https://mcvuk.com/business-news/the-first-time-somebody-was-reading-the-dialogue-i-had-to-leave-the-room-i-was-too-embarrassed-how-adamgryu-overcame-writers-block-and-creative-burnout-in-the-development-of-a-short)).
- **It reads like a script.** `Mochi: Açık mı, demli mi?` is legible to a
  friend who has never seen code; a `.yarn` file opens in any text editor
  and diffs cleanly in a PR.

**What it costs, and the staging.**

| Stage | What runs | Cost | Gate |
|---|---|---|---|
| **0. Now** | Writers author `content/narrative/*.yarn`. CI installs `ysc` (`dotnet tool install --global YarnSpinner.Console`) to **validate** every script and **extract** a strings CSV, which feeds the review sheet (section 4) and, once locked, the String Catalog by line ID. The app's existing Swift code still chooses which line ID to show | A CI job; no app code | None; reversible |
| **1. Spike** | A minimal Swift runner in `PofuCore` for the subset we use: lines, options, jumps, variables, commands, node groups with `when:` and `best_least_recent` | Bounded at 3 days; prove it on Linux with the local Swift toolchain first | If it passes and the shield extension's memory stays flat: **ADR** "Yarn as the narrative format" |
| **2. Later** | Island story beats and resident barks run through the runner; `ShieldCopy` migrates last (it is the riskiest surface) | Incremental | Each surface its own PR |

**Rejected fallback paths, and why.** JavaScriptCore plus a JS runtime
(inkjs or the TypeScript Yarn port) works in the app but not in a shield
extension's memory budget, and adds a second language to debug. articy's
JSON export needs a custom importer and a subscription. Writing our own
format means building the tooling Yarn already has. If the Swift spike
fails, Stage 0 alone still gives us the writer-facing format, line IDs and
the review sheet; selection stays in Swift.

**Not decided here:** the ADR. This document recommends; the spike
decides.

## 2. GitHub and open resources worth bookmarking

| Resource | What it gives us | Use |
|---|---|---|
| [YarnSpinnerTool/YarnSpinner](https://github.com/yarnspinnertool) and [YarnSpinner-Console](https://github.com/YarnSpinnerTool/YarnSpinner-Console) | The language, compiler and `ysc` CLI | Stage 0 above |
| [Yarn Spinner: storylets and saliency primer](https://docs.yarnspinner.dev/write-yarn-scripts/advanced-scripting/storylets-and-saliency-a-primer) | How to structure salience content | Template for the shield and barks |
| [inkle/ink](https://github.com/inkle/ink) and [Jon Ingold's ink introduction](https://medium.com/game-writing-guide/introduction-to-ink-3e6c224865f8) | The best writing on writing reactive prose | Read for craft, even though we do not adopt it |
| [Emily Short: Beyond branching](https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/) and [storylets](https://emshort.blog/tag/storylets/) | The vocabulary: quality-based and salience-based narrative | Our design language for "which line now" |
| [salesforce/creativity_eval](https://github.com/salesforce/creativity_eval) | The 14 binary tests of the Torrance Test of Creative Writing, the 48-story corpus and expert annotations | Borrow 5 of the tests as our review questions (section 4.3) |
| [tajmone/awesome-interactive-fiction](https://repositorystats.com/tajmone/awesome-interactive-fiction) (CC0) | Curated IF tools and reading | Background; dated since 2022 |
| [FronkonGames/Awesome-Gamedev](https://www.Github.com/FronkonGames/Awesome-Gamedev), [Roobyx/awesome-game-design](https://relatedrepos.com/gh/Roobyx/awesome-game-design) | Broad design lists | Background |
| [sam-paech/auto-antislop](https://arxiv.org/abs/2510.15061) (the Antislop paper and code) | Measured lists of phrases LLMs over-produce, and a method to profile them | Seed our English **slop list**; build a Turkish one ourselves (section 3.6) |
| [Arrow](https://awesome.ecosyste.ms/projects/308231) | Free, open-source narrative design tool | Considered; Yarn covers it |

**Talks and interviews (watch, do not re-research):** Greg Kasavin and
Darren Korb on Hades' reactive dialogue, more than 22,000 lines from a
team under 20, where a character never repeats within a return visit
([GDC Vault](https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth));
Adam Robinson-Yu on A Short Hike, who found his voice when he wrote
dialogue "the same way he chatted with friends over text" and drew it
from his own life ([PlayStation Blog](https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/),
[MCV](https://mcvuk.com/business-news/the-first-time-somebody-was-reading-the-dialogue-i-had-to-leave-the-room-i-was-too-embarrassed-how-adamgryu-overcame-writers-block-and-creative-burnout-in-the-development-of-a-short));
Nintendo Treehouse on localising Animal Crossing's puns by rewriting
the joke, not translating it ([Animal Crossing World](https://animalcrossingworld.com/2020/05/animal-crossing-localization-writer-reveals-the-sea-bass-puns-creation-in-new-horizons/),
[Nintendo Life](https://www.nintendolife.com/news/2013/05/animal_crossing_new_leaf_localizers_talk_shop)).

**Skills.** No Claude skill or GitHub action makes writing human; the
ones that exist generate more text. What helps is a **check** in CI, not a
generator: the never-say list from the voice doc plus the slop list
below, run against `.yarn` files, flagging (not blocking) a line for a
human pass.

## 3. Techniques that make writing feel human

### 3.1 Why AI drafts read as "slop", in evidence

- **Homogeneity.** In Doshi and Hauser's experiment (293 stories, 600
  evaluators), stories written with LLM ideas were rated more creative
  individually but were **more similar to one another**: a social
  dilemma where each writer is better off and the whole is narrower
  ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC11244532)). The founder's
  reaction to the meme line bank is this effect: lines that are fine
  alone and interchangeable in bulk.
- **Craft.** Ten professional writers judged 48 stories with 14 binary
  tests; LLM stories passed 3 to 10 times fewer, and no LLM's judgement
  correlated with the experts' ([Chakrabarty et al.](https://arxiv.org/abs/2309.14556)).
  Two consequences: an AI draft is not a finished line, and **an AI
  cannot be the reviewer** either.
- **Patterns.** LLMs over-use a measurable set of phrases and structures
  (the Antislop work profiles thousands; [arXiv 2510.15061](https://arxiv.org/abs/2510.15061)).

### 3.2 A voice bible with real reference excerpts

A voice is learned by ear, so the bible points at **real human writing**
the team reads before a session, not adjectives about tone. Quote a line
or two, never pages; buy or borrow the books.

| Reference | Why it is on the list | What to take |
|---|---|---|
| **Sait Faik Abasıyanık**, Burgazada stories (*Semaver*, *Sarnıç*, *Son Kuşlar*; "Haritada Bir Nokta") | Islands, fishermen, small people, the sea; Turkish prose that is plain and tender at once | Ordinary people noticed precisely; the ending that turns on one small gesture |
| **Orhan Veli**, *İstanbul'u dinliyorum, gözlerim kapalı* | A poem that is a list of sounds; our whole premise is listening | Concrete nouns; no explaining the feeling |
| **Tove Jansson**, the Moomin books, especially *Moominvalley in November* and *Tales from Moominvalley* | The closest tonal cousin: a valley, odd neighbours, melancholy without despair, humour from habit | Every creature wants one small, specific thing |
| **Arnold Lobel**, *Frog and Toad* ("Alone", "Cookies", "The List") | Stakes the size of a cookie; a story about wanting to be alone that is not sad | Restraint; the joke in the body ("Toad's" bathing suit) |
| **Hayao Miyazaki on *ma*** (emptiness between actions, "there intentionally"), Roger Ebert interview, 2002 | Pauses are content | Our scenes leave beats with nothing in them |
| **A Short Hike**; **Night in the Woods** | Cozy games written like friends texting | Lowercase warmth; characters who are slightly wrong about things |
| **Pofu's own good lines** ("Yanaklarım kocaman oldu") | The founder chose it | Self-observation from the body |

Each character entry in the lore bible names **one** reference ("Mochi
talks like an aunt who runs a çay ocağı in Kadıköy, not like a barista"),
because a person you can hear beats a list of traits.

### 3.3 Constraints that force specificity

| Rule | Instead of | Write |
|---|---|---|
| **A noun you could photograph** | "a peaceful place" | "the tea glass turned so its waist faces you" |
| **One sense that is not sight** | "it was beautiful" | "the planks of the pier lift and settle" |
| **Cut adjectives, then cut again** | "a soft, gentle, warm light" | "the lamp" (the art already says warm) |
| **Subtext: characters do not say the feeling** | "I'm sad you're leaving" | "Kalem yap. Bana mektup yazarsın." ("Make a pen. You'll write to me.") |
| **Restraint: the smaller reaction** | Pofu gasps, cheers, cries | Pofu says "...Musluk değilmiş." ("...Not a tap, then.") |
| **Humour from the body and the everyday** | memes, formats, puns | cheeks, quills that pick up leaves, a tortoise's mail three weeks late |
| **No villain, no lecture** | "the fog of distraction" | the fog hums like a fridge: nobody's fault, noticed only when it stops |
| **A detail only this character would know** | "Mochi loves tea" | "Mochi knows you take it açık, and that you leave the last sip" |

### 3.4 The iceberg method for lore

Hemingway's rule: a writer who knows enough may omit things and the
reader will still feel them; "the dignity of movement of an ice-berg is
due to only one-eighth of it being above water", and omitting what you do
**not** know only "makes hollow places" ([Iceberg theory, from *Death in
the Afternoon*, ch. 16](https://en.wikipedia.org/wiki/Iceberg_theory)).

For Pofu this becomes a rule of the lore bible: **every mystery has a
written answer in the writers-only section, and the player sees at most
one eighth of it.** Writers know who left the letters; the game never
says it outright. That is why the bible has two layers (below the
waterline and above it).

### 3.5 Wants, needs and wounds

From Truby's *Anatomy of Story*: the **desire** is an outside goal, the
**need** is what the character must learn, and the **ghost** (wound) is
the past event that explains the weakness ([Arc Studio summary](https://www.arcstudiopro.com/blog/22-building-blocks-john-truby);
check against the book). For a cozy game, scale it down: every resident
has one want they say out loud, one need they never say, one wound we
only hint at, and **a physical tell** that carries all three (Damla's cup
that is always half full). Arcs resolve when the want quietly changes
into the need, never with a speech.

### 3.6 Turkish-native checks

AI Turkish is often translated English with Turkish words. A native
reader catches it in seconds; a checklist helps a tired one. (From native
knowledge; to be extended by the panel.)

| Tell | Example of the calque | Native |
|---|---|---|
| "Sahip olmak" for everything | "Güzel bir adaya sahibiz." | "Güzel bir adamız var." |
| Sentences opening with "Bu," as a pronoun | "Bu, harika bir şey." | "Ne güzel." |
| "-ebilmek" politeness from English "can" | "Sana yardım edebilir miyim?" | "Yardım edeyim mi?" |
| English emphasis words | "Gerçekten çok harika", "kesinlikle" | Turkish emphasis is in word order and particles: "Harika ya." |
| Over-formal "siz" or textbook register | "Lütfen bekleyiniz." | "Bir dakika." |
| Spliced suffixes on variables | "{app}'ı açma" | Whole line per app; check vowel harmony by ear |
| Exclamation and ellipsis inflation | "Harika!!!", "Kim bilir..." | One "!" per screen (voice rules) |
| Wonder-words | "büyülü", "sihirli", "huzurlu bir yolculuk" | Show the thing; never name the feeling |

**The slop list (Turkish, starter).** Words and frames to flag in CI and
re-read: *büyülü, sihirli, huzur dolu, yolculuk, macera, keşfet, unutma
ki, kim bilir, hayallerinin peşinden, kalbinin sesi, an'ın tadını çıkar*,
any rule of three adjectives, and "sadece X değil, aynı zamanda Y".
English: *journey, embark, tapestry, delve, testament, whisper of,
gentle reminder, it's not just X, it's Y*. A flag is a prompt to look,
not a ban.

**Idiom references:** TDK's *Güncel Türkçe Sözlük* and *Atasözleri ve
Deyimler Sözlüğü* (sozluk.gov.tr) for meaning and register; but the final
test is a person under 30 and a person over 50 both hearing it as normal.

### 3.7 Writers'-room passes

Pixar's Braintrust is the model: candid notes from peers with no
authority to impose them, on work everyone agrees "sucks at first"
([Fast Company](https://www.fastcompany.com/3027135/inside-the-pixar-braintrust)).
Each pass has one job and, where possible, a different person:

| Pass | Job | Who |
|---|---|---|
| 1. Skeleton | Beats, continuity with the bible, what each line must do | Agent (allowed: this is structure) |
| 2. Mouth | Make each line sound like that one character | Founder or a friend |
| 3. Cut | Remove a third; every adjective defends itself | Anyone but the author |
| 4. Spice | Add one detail from your own life (the way your aunt turns the tea glass) | A friend, never the agent |
| 5. Read aloud | Someone who did not write it reads it; mark every stumble | A friend, recorded |
| 6. Idiom | The Turkish checklist above; vowel harmony; register | A native reader |
| 7. Panel | Section 4.4 | Ten people |

### 3.8 The read-aloud test

Adam Robinson-Yu: "The first time somebody was reading the dialogue I had
to leave the room, I was too embarrassed" ([MCV](https://mcvuk.com/business-news/the-first-time-somebody-was-reading-the-dialogue-i-had-to-leave-the-room-i-was-too-embarrassed-how-adamgryu-overcame-writers-block-and-creative-burnout-in-the-development-of-a-short)).
That embarrassment is the test working. Rules: the reader is not the
writer; they read once, cold, at speaking speed; a stumble, a rephrase
in the reader's mouth, or a smirk is a note. If the reader naturally says
it differently, **their version usually wins.**

## 4. The human-in-the-loop pipeline

### 4.1 Principles

1. **AI drafts are scaffolding.** They are labelled `draft:ai` in the
   `.yarn` metadata and in the sheet. They exist to give humans something
   to push against, never to ship.
2. **Every shipped line has a human owner** (`#owner:` tag) who either
   rewrote it or approved it after a read-aloud.
3. **The agent never reviews for quality.** It checks continuity,
   length, the never-say list and the slop list; taste is human
   (section 3.1).
4. **Small batches.** A spice session is one island or one scene, 20 to
   30 lines, 30 minutes. Pilot, then scale (CLAUDE.md).

### 4.2 Line lifecycle

`draft:ai` → `spiced` (a human rewrote or approved) → `read` (survived a
cold read-aloud) → `panel` (survived the panel, if it is a ★ line or
lore) → `locked` (enters the String Catalog). A locked line changes only
through the same passes.

### 4.3 The spice sheet

One shared Google Sheet (or the Pofu Hub's db later), generated from
`ysc extract` so the IDs match the scripts. Columns:

| Column | Filled by | Notes |
|---|---|---|
| `line_id` | CI | Yarn `#line:` ID |
| `scene` / `speaker` / `when` | CI | Context in one cell: "Gezgin, first night, Pofu to Mochi, 01:00" |
| `draft_tr` | Agent | The scaffold |
| `gloss_en` | Agent | So a non-Turkish reviewer can follow |
| `margin` | Agent | What the line must do, and the specific worry ("too cute?") |
| `verdict` | Spicer | keep / tweak / rewrite / cut |
| `your_line` | Spicer | Their version, in their own words |
| `spice` | Spicer | The one real detail they added, if any |
| `read_aloud` | Reader | ok / stumbled at "…" / said it as "…" |
| `friend_test` | Reader | 1–5: "would a friend say this to your face?" |
| `sounds_ai` | Reader | yes / no |
| `owner` | Agent | Who signs the line |

**Five review questions** (adapted from the TTCW tests,
[creativity_eval](https://github.com/salesforce/creativity_eval)): Is
there a detail you would not have guessed? Does the character sound like
no one else? Is something left unsaid that you still felt? Did a word
make you stumble? Could this line be in another app?

### 4.4 A 10-person reading panel, cheaply

- **Who:** ten people, not ten gamers. Two under 20, four 20–35, two
  35–55 (a parent among them), one who writes (poems, stand-up, a
  newspaper), one who has never played a phone game. At least two from
  outside İstanbul. Later, five English natives for the global pass.
- **How:** a WhatsApp group. Two rounds of five, not one of ten: Nielsen's
  argument that small repeated rounds find most problems and leave budget
  to fix and re-test ([NN/g](https://nngroup.com/articles/why-you-only-need-to-test-with-5-users/);
  it holds for one comparable group, so we rotate the five).
- **The task (15 minutes):** (1) record a voice note reading the scene
  aloud (stumbles show in the audio); (2) a Google Form with **blind
  pairs**, a human-spiced line versus the AI draft, unlabelled, "which one
  sounds like a person?"; (3) one free question: "which line would you
  quote to a friend?"
- **What counts:** a line ships if it wins its pair in at least 7 of 10
  and nobody flags it as hurtful. Lore beats are judged on "did you want
  to know what happens next?".
- **Cost:** zero cash. Thanks are a name in the credits, a lifetime
  membership code at launch, and çay and simit at the in-person session.
  Time: about 30 minutes per round of the founder's, 15 per panellist.
- **Privacy:** voice notes stay in the group; nothing is committed to the
  public repo except the verdicts.

### 4.5 What the agent does in this pipeline

| Does | Does not |
|---|---|
| Keep the lore bible consistent; draft skeletons with margin notes | Write the final version of any line |
| Generate the sheet from `.yarn`; merge verdicts back with IDs | Judge humour or beauty |
| Run the never-say and slop checks; flag length and vowel harmony | Fill a spice column, ever |
| Propose two or three radically different options when a scene is stuck | Pick between friends' versions (the founder does) |

## 5. Next steps

1. Founder: read the [lore bible](../product/lore-bible.md) draft and its
   five scenes; mark what is wrong in one voice note.
2. Founder: name two or three friends for the first spice session (one
   scene each), and ten for the panel.
3. Agent: convert the five scenes to `.yarn` and add the `ysc` validate and
   extract job (Stage 0), behind a small PR.
4. Agent: the Swift runner spike (Stage 1), only after the dogfood week,
   and an ADR if it passes.

## Sources

Network note: inklestudios.com, yarnspinner.dev's blog and Wikipedia
could not be fetched from the agent environment; those claims rely on
search-result summaries and are worth a human click.

- Chakrabarty, Laban, Agarwal, Muresan, Wu. *Art or Artifice? Large
  Language Models and the False Promise of Creativity.* CHI 2024.
  [arXiv 2309.14556](https://arxiv.org/abs/2309.14556),
  [code and data](https://github.com/salesforce/creativity_eval)
- Doshi, Hauser. *Generative AI enhances individual creativity but
  reduces the collective diversity of novel content.* Science Advances,
  2024. [PMC11244532](https://pmc.ncbi.nlm.nih.gov/articles/PMC11244532)
- Paech et al. *Antislop.* [arXiv 2510.15061](https://arxiv.org/abs/2510.15061)
- Yarn Spinner: [licensing](https://yarnspinner.dev/license),
  [localisation](https://docs.yarnspinner.dev/yarn-spinner-for-unity/assets-and-localization),
  [node groups](https://docs.yarnspinner.dev/next/write-yarn-scripts/syntax-basics/node-groups),
  [saliency](https://docs.yarnspinner.dev/write-yarn-scripts/advanced-scripting/saliency),
  [VS Code](https://docs.yarnspinner.dev/getting-started/editing-with-vs-code/writing-yarn-in-vs-code),
  [YarnSpinner-Console](https://github.com/YarnSpinnerTool/YarnSpinner-Console),
  [Game Developer deep dive](https://gamedeveloper.com/programming/deep-dive-yarn-spinner),
  [Rust runtime](https://docs.rs/yarnspinner_runtime)
- ink: [inkle/ink](https://github.com/inkle/ink),
  [issue 98](https://github.com/inkle/ink/issues/98),
  [issue 514](https://github.com/inkle/ink/issues/514),
  [ink-iOS](https://www.github.com/russellquinn/ink-iOS),
  [InkSwift](https://www.github.com/maartene/InkSwift),
  [LocaliserLib](https://www.nuget.org/packages/wildwinter.LocaliserLib),
  [Heaven's Vault](https://gamedeveloper.com/design/how-inkle-developed-its-own-ancient-language-for-i-heaven-s-vault-i-),
  [Ingold, Introduction to ink](https://medium.com/game-writing-guide/introduction-to-ink-3e6c224865f8)
- articy:draft X: [shop](https://www.articy.com/shop/?p=9999),
  [integrations](https://www.articy.com/help/Integrations_Overview.html),
  [FAQ](https://www.articy.com/en/frequently-asked-questions/)
- Dialogic 2: [docs](https://scriptagc.wasmer.app/https_docs_dialogic_pro/getting-started_html).
  Narrat: [repo](https://github.com/liana-p/narrat-engine),
  [docs](https://docs.get-narrat.com/others/what-can-narrat-do.html)
- Emily Short: [Beyond branching](https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/),
  [storylets](https://emshort.blog/tag/storylets/)
- Hades dialogue: [GDC Vault](https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth)
- A Short Hike: [MCV](https://mcvuk.com/business-news/the-first-time-somebody-was-reading-the-dialogue-i-had-to-leave-the-room-i-was-too-embarrassed-how-adamgryu-overcame-writers-block-and-creative-burnout-in-the-development-of-a-short),
  [PlayStation Blog](https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/)
- Animal Crossing localisation: [Animal Crossing World](https://animalcrossingworld.com/2020/05/animal-crossing-localization-writer-reveals-the-sea-bass-puns-creation-in-new-horizons/),
  [Nintendo Life](https://www.nintendolife.com/news/2013/05/animal_crossing_new_leaf_localizers_talk_shop)
- Iceberg theory: [Wikipedia](https://en.wikipedia.org/wiki/Iceberg_theory)
  (Hemingway, *Death in the Afternoon*, 1932, ch. 16)
- Truby: [Arc Studio summary](https://www.arcstudiopro.com/blog/22-building-blocks-john-truby)
- Pixar Braintrust: [Fast Company](https://www.fastcompany.com/3027135/inside-the-pixar-braintrust)
- Nielsen: [Why you only need to test with 5 users](https://nngroup.com/articles/why-you-only-need-to-test-with-5-users/)
- Lists: [awesome-interactive-fiction](https://repositorystats.com/tajmone/awesome-interactive-fiction),
  [Awesome-Gamedev](https://www.Github.com/FronkonGames/Awesome-Gamedev),
  [awesome-game-design](https://relatedrepos.com/gh/Roobyx/awesome-game-design),
  [Arrow](https://awesome.ecosyste.ms/projects/308231)
