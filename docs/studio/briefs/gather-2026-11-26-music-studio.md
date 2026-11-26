# Gather brief: sound and music, and the studio's structure (2026-11-26)

Role: `.claude/agents/scout.md`. Raw facts for Fable; you do not judge
or propose. Every line carries evidence; UNCHECKED where unchecked.
Read pofu `origin/main` (`/home/user/pofu`, `git show`/`git grep`), no
builds, no pushes.

1. **Sound and music in the app:** `PofuSound`, `App/WorldSound.swift`,
   every cue, ambience bed, voice cue, audio asset (format, length,
   source, licence/provenance), settings, mixing, how states drive audio;
   docs and ADRs on sound and music; #515 and other sound PRs.
2. **Ways to make game music for a small studio with AI and agents**
   (web research, cite URLs, date-check): adaptive/interactive music
   structures (layers, stems, horizontal re-sequencing, states),
   composition as MIDI or notation by an LLM and rendering with
   soundfonts or virtual instruments, AI music generators with
   commercial licences and their terms, iOS playback options
   (AVAudioEngine, AudioKit, FMOD/Wwise on iOS), loop length and file
   size norms in cosy mobile games. Facts and terms only.
3. **The studio's structure today:** `CLAUDE.md`, `docs/studio.md`,
   `docs/README.md`, `.claude/agents/*`, `.claude/skills/*` (and
   pofu-art `AGENTS.md`, `QUEUE.md` structure): what lines of work exist,
   where each line's plan, context and record live, who works each, how
   handoffs work, what is per-line vs global. Add any line that has no
   home. Reuse the earlier measurements in
   `/home/user/wt/lead-docs/docs/research/mainflow-2026-11-26/raw-studio-speed.md`
   rather than redoing them; add idle times since 11-26 if visible.

Write `/home/user/wt/lead-docs/docs/research/studio-2026-11-26/raw-music-studio.md`
(do not commit). Hand back the path and a 10-line summary.
