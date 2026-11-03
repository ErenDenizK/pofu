# AI story-writing methods: what real projects do, and what helps prose

_Status: research, 2026-11-03. Reads with
[narrative-craft.md](narrative-craft.md) (tools, the human spice
pipeline, the evidence that AI fiction is generic; not repeated here) and
the [lore bible](../product/lore-bible.md). Output: the project skill
[`.claude/skills/pofu-story`](../../.claude/skills/pofu-story/SKILL.md)
and its first test, [story-tests/round-1.md](../product/story-tests/round-1.md)._

The founder's ask (2026-11-03, translated): _"AI writing here is very
bad, very systematic. AI is not bad at finding ideas, but it is very bad
at writing subtext and turning things into story. Look at repos, prompt
guides and skills that real users built and that work. It may not be
perfect but it may be better; let's try and learn."_

## 0. The answer

- **Every serious system splits the work into roles and stages**
  (outline → scene → critique → revise). That split helps **coherence**
  over long texts, which is not Pofu's problem: our scenes are under a
  minute. It does nothing for subtext on its own.
- **What measurably improves AI prose is subtraction, done by a reader
  who is not the writer.** Professional editors fixing LLM paragraphs
  mostly delete and replace, rarely insert, and their edits beat both the
  raw draft and the LLM's self-edit (LAMP, below). The most popular open
  pipeline does the opposite: every stage says "don't take away content,
  expand upon it" (AIStoryWriter). That is how "systematic" prose is made.
- **Pattern lists (anti-slop skills) remove tells but do not create
  subtext.** They are a floor, not a method. They also breed new tics if
  applied blindly (everything becomes two-word fragments).
- **Anchors beat adjectives.** Systems that work show the model real
  human text in the target register (Dramatron's prefix examples,
  Sudowrite's style samples, show-me-the-story's "human-writer
  benchmark"). "Write warmly with subtext" produces neither.
- **Variants, then a choice.** Re3 reranks several continuations; the
  professionals who used Dramatron and Wordcraft treated output as
  material to pick from and rewrite. For us: two variants that differ in
  approach, not wording, with readers' blind opinions as input.
- **The three techniques we take:**
  1. **Know the honest line, then don't write it:** before drafting,
     name what each character would say if they were honest about the
     feeling; write the scene around it (the iceberg, made operational).
  2. **Subtraction by a separate reader:** a trim pass, then a critic in
     a fresh context who may only quote what rings false, never praise
     or rewrite.
  3. **Vary the device across scenes:** name the trick a scene leans on
     (deflection, ritual, object hand-off, wrong answer, repetition with
     change, silence) and do not reuse the last scene's. This attacks
     the "same trick three times" sameness the lore bible's own
     self-critique found.
- **Founder update (2026-11-03, after round 1 was drafted):** the lead
  agent is the final writer; the founder and friends give opinions, not
  a gate. Write naturally and well first; the techniques above are light
  editorial checks, not a formula. Round 1 supports this: the variants
  run through the full protocol came out terse and samey.

## 1. The projects

| Project | Method | What actually improves prose | Hype or limit |
|---|---|---|---|
| **AIStoryWriter** ([datacrystals](https://github.com/datacrystals/AIStoryWriter); read from source, last commit 2025-11) | Prompt → story elements → outline (critic loop up to 3 revisions) → chapter outline → scenes → chapter in four stages: plot, character, dialogue, final edit; a generic critic and an "is it complete?" JSON gate; a scrub pass; pairwise LLM eval (`Evaluate.py`) | Breaking a chapter into scene outlines first; per-stage model choice | Every stage prompt says **"Don't take away content, instead expand upon it to make a longer and more detailed output."** The critic rubric is generic (pacing, flow, genre) and identical for outline and chapter. Its own README lists "repetitive phrases" as the main open problem. Length is the product; subtext is not addressed |
| **show-me-the-story** ([Nigh](https://github.com/Nigh/show-me-the-story); Go, last commit 2026-10) | A local app: story settings and characters, batch outlines the human confirms, one chapter at a time the human accepts, fact extraction with sources, a foreshadow tracker, a memory store, and built-in **skills**: `writing-craft`, `story-deslop` (a six-gate audit), `humanizer` | The most practical of the set. Human gates between every stage; a **six-gate deslop audit** with counts (slop words per 1,000, em-dash rate, triads, said-bookisms, bare emotion labels, repeated body cues); a voice test: **"swap two characters' tags; if the lines still read right, rewrite one voice"**; and a **human-writer benchmark** (compare against a published paragraph in the same register) | Trade-fiction rules that are wrong for us: every chapter must end on a hook, "a beat that pushes forward". Pofu's tone rule 8 forbids exactly that. Thresholds are calibrated for English and Chinese web fiction |
| **Dramatron** ([google-deepmind](https://github.com/google-deepmind/dramatron); [Mirowski et al., CHI 2023](https://dl.acm.org/doi/10.1145/3544548.3581225)) | Hierarchical: logline → characters → plot beats → locations → dialogue, with prefix (few-shot) prompts and human editing at every level | 15 playwrights and screenwriters valued it for **world-building, alternatives and idea generation** | Their words: output can be "formulaic"; they "wouldn't use [it] to write a full play". The top-down hierarchy does not match how many writers work. Four scripts were staged only after heavy human rewriting |
| **Agents' Room** ([Huot et al., Google DeepMind, ICLR 2025](https://proceedings.iclr.cc/paper_files/paper/2025/hash/0fbc8a83d93dd8021a4dd8d2d34138eb-Abstract-Conference.html)) | Planning agents (conflict, characters, setting, plot) and writing agents (exposition, rising action, climax…) write into a shared scratchpad under an orchestrator; releases *Tell Me A Story*, prompts plus human stories | Specialised roles beat one end-to-end prompt in expert and automatic ratings | Gains are measured on long stories; outputs were about **twice as long**, and length is part of what raters liked. Roles are by story section, not by editorial job |
| **Re3 and DOC** ([Yang et al., EMNLP 2022](https://aclanthology.org/2022.emnlp-main.296); [DOC, ACL 2023](https://github.com/yangkevin2/doc-story-generation); [doc-storygen-v2](https://github.com/facebookresearch/doc-storygen-v2)) | Plan → draft passages with the plan and state re-fed → **rerank** candidates for coherence and relevance → edit for consistency; DOC adds a detailed outline and a controller | Coherence of a 2,000 to 3,500 word plot rose (Re3: +14 % coherent, +20 % on premise) | Coherence and relevance, not style; nothing about dialogue or subtext. The reusable idea is **generate several, choose** |
| **LAMP / "Can AI writing be salvaged?"** ([Chakrabarty, Laban, Wu, CHI 2025](https://arxiv.org/abs/2409.14509)) | 18 professional writers edited 1,057 LLM paragraphs (Claude 3.5 Sonnet, GPT-4o, Llama 3.1 70B): 8,035 edits in seven categories | The categories are our checklist: **awkward word choice (28 %), poor sentence structure (20 %), unnecessary or redundant exposition (18 %), cliché (17 %)**, purple prose, lack of specificity, tense inconsistency. **Insertions were rare.** Preference: writer-edited > LLM-edited > raw LLM | No model was clearly better than another; an LLM can partly find its own tics, but the expert edit still wins |
| **EQ-Bench Creative Writing v3** ([EQ-bench/creative-writing-bench](https://github.com/EQ-bench/creative-writing-bench); slop work in [narrative-craft §2](narrative-craft.md#2-github-and-open-resources-worth-bookmarking)) | LLM judge with a rubric and pairwise Elo; a measured **slop list** of n-grams (e.g. "voice barely whisper", "took deep breath", "smile playing lips") and a human n-gram profile | The **negative criteria** are a good vocabulary for a critic: "tell-don't-show", "weak dialogue", "unearned transformations", "incongruent ending positivity", "overwrought", "purple prose" | A judge model ranks models; it is not a taste oracle (LLM judgement did not match experts in Chakrabarty 2024). English only |
| **Anti-slop Claude skills**: [stop-slop](https://github.com/hardikpandya/stop-slop), [humanizer](https://github.com/blader/humanizer) (from Wikipedia's [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)) | A `SKILL.md` plus reference lists: banned phrases and structures ("not X but Y", one-line closers, sayings that sound deep, forced triads, staged run-ups), a 5-dimension score | Cheap and effective at removing **non-fiction** tells; humanizer reports a 16/16 blind preference over raw AI text | Written for essays and posts. Some rules are wrong for dialogue (stop-slop bans fragments and passive voice; Turkish speech is full of both). They do not know Turkish |
| **Sudowrite** ([how it works](https://sudowrite.com/blog/how-sudowrite-works/)) | A Story Bible (characters, world, style sample) feeding Write, Describe (five senses plus metaphor options), Rewrite modes including **"Show Not Tell"**, Brainstorm | Describe's "sense menu" is useful for stage directions; the Story Bible is the same idea as our lore bible | "Show not tell" as a button usually adds description (more words, more body clichés). Subtext is a cut, not an add |
| **Wordcraft** ([Ippolito et al., 2022](https://arxiv.org/abs/2211.05030)) | 13 published writers used an LLM editor as research assistant, beta reader and partner | Most value in ideation and unsticking | The models "struggle to preserve style and authorial voice" |

## 2. Craft sources on subtext (human, not AI)

- **Charles Baxter, _The Art of Subtext_** ([Graywolf, 2007](https://graywolfpress.org/books/art-subtext)):
  "staging" (where people stand and what they hold says what they do not)
  and the specific detail that points toward the unsaid. Our version: the
  object carries the feeling (the tea glass, the feather).
- **Hemingway, "Hills Like White Elephants"** and the iceberg
  ([narrative-craft §3.4](narrative-craft.md#34-the-iceberg-method-for-lore)):
  a whole argument conducted about drinks and hills.
- **Ursula K. Le Guin, _Steering the Craft_**, ch. 10 "Crowding and
  Leaping": pack the moment you stay in, leap over everything else
  ([discussion](https://radacts.substack.com/p/crowding-and-leaping)).
  The "cut 30 %" pass is leaping.
- **Arnold Lobel, _Frog and Toad_** ("Cookies", "Alone"): stakes the size
  of a cookie, feelings said through what the characters do with the
  cookies. Closest model for Pofu's micro-scenes.
- **Turkish everyday ritual as subtext:** a teaspoon laid across the top
  of a tea glass means "no more, thanks"; "Kolay gelsin" to anyone at
  work; "Ellerine sağlık" after food. These are gestures every Turkish
  player decodes instantly and no prompt invents unprompted.

## 3. What we take, what we reject

| Take | From | In the skill as |
|---|---|---|
| Write first, then separate editorial checks | Agents' Room, show-me-the-story, Dramatron | Default path: write naturally, then subtext check, trim, read-aloud; the full staged protocol only when stuck |
| Subtraction by a reader who is not the writer | LAMP | "Cut 30 %" and a critic that may only name what is false |
| Real anchors in the target register | Dramatron, Sudowrite, show-me-the-story | `style-anchors.md`, extendable by the founder |
| Counted tells, Turkish and English | stop-slop, humanizer, EQ-Bench slop list, deslop gates | `banned-tics.md`, with Turkish-native entries and our own tics |
| The tag-swap voice test | show-me-the-story | Subtext checklist item |
| Generate several, choose | Re3, Doshi and Hauser's homogeneity finding | Two variants per scene that differ in approach, for optional blind feedback |

| Reject | Why |
|---|---|
| "Expand, don't take away" stages | Produces exactly the systematic bloat the founder hates |
| Chapter-ending hooks | Pofu's scenes end quiet and complete (lore bible §6.8) |
| Generic rubrics (pacing, flow, genre) as critique | They return generic notes; a critic must quote a line |
| An LLM judge as the quality gate | Does not match expert taste; the panel decides |
| "Show not tell" as adding description | Subtext is mostly removal plus one chosen object |

## 4. Honest limits

- None of these systems claims, or shows, good **subtext in dialogue**.
  The method in the skill is our synthesis from editing research and
  human craft, not a proven recipe; round 1 is its first test.
- An agent running every role itself is weaker than separate people.
  The skill keeps the critic in a fresh context where it can, and asks
  the founder and friends for opinions (a read-aloud, a blind pick).
- A checklist applied to every line produces its own sameness. The
  checks catch tells; they do not write the scene.
- Network note: arxiv.org was not reachable from the agent environment;
  paper claims come from abstracts and search summaries. The repos
  (AIStoryWriter, show-me-the-story, Dramatron, DOC, stop-slop,
  humanizer, creative-writing-bench) were cloned and read.
