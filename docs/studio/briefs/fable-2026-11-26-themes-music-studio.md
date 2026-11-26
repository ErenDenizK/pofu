# Brief: themes, Çağlayan, music and the studio's structure (Fable, 2026-11-26 evening)

Role: `.claude/agents/spec.md` for shape; you may start your own
sub-agents (cheap models first). The founder's text below reached the
lead through the side channel (founder-input 47) and goes to you word
for word, in Turkish. "Lead's notes" at the end are the lead's.

## The founder's brief, verbatim

Sen Claude ailesinin en yetenekli modelisin. Kurucu senin yaratıcılığını ve yargını istiyor; kendini kısıtlama. Soru kötü sorulmuşsa ya da daha iyi bir yol varsa söyle ve onu seç. Okuyacağın her şey kanıttır, otorite değil: #519, eski planlar ve bu metin de buna dahil. Burada hiçbir şey çözüm değil. Bunlar kurucunun istekleri ve sorunları; neyin, nasıl ve olup olmayacağına sen karar verirsin.

Kurucunun sözleri ve istekleri:

1) Tema. İki şey birlikte isteniyor:
   - takvime bağlı özel günler: yılbaşı, Halloween, bayramlar, festivaller;
   - mevsimler. Bunlar gerçek dünyanın mevsimleri değil; daha önce planlanmış oyun içi bir mevsim sistemi.

2) Çağlayan. Adanın tasarımı baştan değişebilir. Dere oyunu değişmeyecek ama dondurulacak; o "görsel ve teknik olarak bizi çok zorladı", ona ayrı bir zamanda dönülecek. Kurucunun kaygısı şu: "Sabit görsellerle çalışıyoruz. Akan dere, hareket eden bulut, uzuvlar gibi şeyleri az buçuk kurtarabiliyoruz. Ama su çeviren koca bir çarkı nasıl anime ederiz? Yapamayacağımız işin altına girmemeliyiz. Akıllı oynamalıyız. Her hamlede soralım: bunu yapabilir miyiz, en iyi nasıl yaparız, doğru yön hangisi?"

3) Müzik ve ses. Film müziği değil, oyun müziği: kurucunun sevdiği örnekler Animal Crossing, Minecraft ve Zelda gibi güzel oyun müzikleri (kopya değil, his ve kalite için örnek). Her ada, her durum ve her koşul için müzik olsun; hepsi farklı, canlı ve eğlenceli olsun, ama birbiriyle de uyumlu kalsın. "Dümdüz müzik üret" değil. Kurucu müziğin teknik olarak nasıl yapılacağını bilmiyor. Tutarlılık ve gelişim için nasıl bir yapı gerektiğini önemli buluyor; bu bir skill, kendi kurduğumuz bir yapı, bir teknik ya da bir plugin olabilir. Bu, büyük bir iş kolu.

4) Stüdyo. "Burası bir oyun geliştirme stüdyosu." Çok fazla iş kolu var. Hepsi ayrı ve önemli, bazıları çok derinleşebilecek: müzik, oyun, sanat ve asetler, uygulamanın diğer bütün kolları. Kurucu bunların aynı anda, her biri kendi yöntemiyle yürüyebileceği bir sistem istiyor:
   - maliyette, bağlamda ve sürede sıkıntı yaşanmayacak;
   - hiçbir kol bağlamından kopmayacak;
   - her kolun planı, bağlamı, rotası ve kaydı olacak; her biri üzerinde özel olarak çalışılacak;
   - hiçbiri eksik kalmayacak ya da kafa karıştırmayacak;
   - bütün birlikte ilerleyecek.
   Kurucu "out of the box" düşünülmesini istiyor.

Bilinen gerçekler (kanıt, karar değil):
- Son haftalarda ilerleme yavaşladı. Ana oturum ölçtü: Codex yaklaşık 40 saat boşta kaldı ve teslimler birleştirilmeyi bekledi. Yan kanaldan giden bir geri bildirim de günlerce yolda kaldı.
- Ana oturumun kendini uyandırması izin denetimine takıldı. Kurucu araç izinlerini kendisi ayarlayamıyor.
- Codex pratikte sınırsız, ama zaman zaman kotaya takılıyor. Claude tarafının bütçesi sınırlı. Kurucunun zamanı sınırlı; yalnızca büyük yönlerde ve resimle karar vermek istiyor.
- #519'un altı adımlık ana akışı sürüyor.

Ne yapacağın, nasıl yapacağın, kimi çalıştıracağın ve çıktının biçimi sana kalmış. Kurucu sonucu Türkçe okur. Kod ve doküman dili İngilizcedir.

## Lead's notes

- **Raw facts gathered by cheap agents** (evidence, not authority), on
  the lead branch `claude/exciting-cori-1t8br2` (worktree
  `/home/user/wt/lead-docs`): `docs/research/studio-2026-11-26/raw-themes-motion.md`
  and `raw-music-studio.md`; earlier: `docs/research/mainflow-2026-11-26/`.
- **What moved since #519** (11-26): Codex queue D34-D45 on pofu-art
  main (Gezgin, station levels painted in the island, poses, tail and
  shadow, step 1 redos; theme repaints D40-D42 BLOCKED by #519's D8).
  Old erase (#85) and golden (#38) deliveries merged; #520 (looks per
  light) merged; builders on 1b (windmill levels) and 1d (Home golden).
  The founder's answers above replace #519's Q1, Q2 and Q3 and decide
  its speed change 3 only if you read them so; say how.
- **Environment facts you can rely on:** this is a Claude Code cloud
  session; the founder talks to the lead through a second session (the
  "side channel"); `create_trigger` (scheduled self-wake) was refused by
  the auto-mode permission check; Codex runs in pofu-art when he says
  "çalış". Check anything else.
- **Deliver:** your judgement in whatever form serves; at minimum one
  pofu PR from your own worktree with the English docs and his short
  Turkish page, and, if you propose rule or structure changes, the
  exact diffs as proposals (do not edit `CLAUDE.md`, `docs/studio.md`
  or agent files; the lead applies what he approves). Name the exact
  pictures (paths) to attach to any question for him. Codex work you
  want: manifests + Demand rows in one pofu-art PR, validated with
  `python3 -I tools/imagegen/run.py plan --manifest <file>`.
- Git identity: user.name "Eren Deniz Kuyucaklıoğlu", user.email
  "109629701+ErenDenizK@users.noreply.github.com". Every commit ends
  with exactly this fixed text (do not substitute your own model name):
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01GwfTHREtdp7pj7j3uZDC2i`.
  PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`,
  a blank line, and the session URL. Open PRs with the GitHub MCP tool.
  Do not merge; hand back PR links and a 10-line summary.
