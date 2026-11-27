# Fable brief: concepts first, four topics as one whole (2026-11-18)

The founder approved this run through the side channel (founder-input 40).
It is one holistic round: one run of yours, with whatever sub-agents you
judge worth their cost.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included.
Its framing should not narrow your thinking. The founder wants your
creativity: if a question is badly posed, or a better approach exists that
nobody has named, say so and take it. Everything you read is evidence to
weigh, not authority: the rules, the founder's words, this brief, earlier
plans and specs (your own included). The product rules in CLAUDE.md are
fixed. Nothing else is.

## The founder's words (Turkish, as the side channel compiled them and he approved; English after)

**Tempo.** Same as before: his budget is short, he has visas. At most two
or three agents at once; the Codex line keeps running; no uncontrolled
growth. "HTML ya da artifact prototipi yok; önce konsept, sonra native."
(No HTML or artifact prototypes; concept first, then native.)

**The principle.** "Burada hiçbir şey ufak ufak fix değil; her şey büyük
büyük değerlendirilmeli. Her özellik ilk adımından son adımına, tüm diğer
yan bileşenlerle ve tüm diğer özelliklerle beraber, harman
değerlendirilmeli. Yoksa bağımsız olarak hepsi ortalama kalır ve birleşince
çirkin olur." (Nothing here is a small fix; everything must be weighed big.
Every feature, from its first step to its last, together with all its side
parts and all the other features, weighed as a blend. Otherwise each stays
average on its own, and together they are ugly.)

**The method.** From the picture to the game, not from the code to the
picture. First Codex makes, for each topic below, concepts that show the
whole design at its best: away from the game, in a few different
directions. He picks from the concept frames; until he picks, no code is
written on that topic. The chosen direction is made native in the app, and
he is shown its frame or build.

**This is your job:** one holistic round. Take the four topics tied to one
another and to the rest of the game (the home island, the stations, the
characters, the Gezgin, the interface's language), and write the Codex
concept jobs. Budget: concepts few and to the point (a few strong
directions per topic, not dozens); at most two concept jobs at once in
Codex, the rest in sequence. Do what is needed, nothing unneeded.

The side channel's note: the suggestions below (his drawing, the flow, the
gradient and texture, round or square) are his own views; take them
seriously, and say so if you see a better way.

### 1. The stream board

"Kodla yazılmış görseller o vibe'ı göstermiyor. Bir tık daha bold, bir tık
daha dolu dolu; parçaların üstündeki kaya ve çim dolu dolu hissettirsin."
(The code-drawn visuals do not show that vibe. A touch bolder, a touch
fuller; the rock and grass on the pieces should feel rich.)

The turning cell: round is more logical, square is more beautiful; the
concept should try both. His drawing: every cell a raised block, its top
grass (a raised bed of ground), its edges, sides and underside stone;
side-by-side blocks join into one big block; some cells empty; the feeling
of a minigame played on a tabletop, not a real stream.

### 2. The level-up panel

More minimal and compact; behind it the island must be seen really
growing, the panel makes room for the real picture. The interface's
language is our blend: glass UI with crafted UI. A small icon that shows
the level (Codex). Codex effects. Menu backgrounds not a flat colour: a
gradient through one colour that fits the theme; if needed a pattern
behind and on top a real, high-resolution texture. He will talk through
the details later.

### 3. Choosing an island, and the Gezgin

Islands side by side makes sense; the Gezgin's model in the prototype is
very bad (the eyes and so on). His proposed flow: the Gezgin does not get
up from her place; the camera pulls back, the player swipes to choose
which island to go to; once chosen, the Gezgin comes to the main island,
the characters jump onto her back from the pier where she is moored; then
the voyage animation. Throughout the menu the Gezgin does not move. The
alternative: a way where we watch the islands from the Gezgin's back, but
with a better interface. To weigh: how the Gezgin moors at islands, where
on the island she stays, how her model looks level by level.

### 4. Station levels (batches 134 and 137)

The windmill's overall progression is good. The pond is a touch overdone:
the pond is very big, a river runs through, a bridge appears; the step from
1 to 2 means nothing. "Hem parça parça mantıklı hem de bir bütün olarak
güzel hissettirmeli; her biri hep beraber ve kendi başına da." (It must
make sense piece by piece and feel beautiful as a whole; each one, all
together and on its own.) Every level of every station is checked in the
frame of the whole island, with the other stations on it; one station
growing must not take over the island.

## What exists (evidence, not authority; check what matters)

- Your island-progression proposal, PR #503 (`origin/design/island-progression`,
  worktree /home/user/wt/fable-ip), and his answers to it in founder-input 39.
- Your board and sheet round, PR #507 (`origin/design/board-and-sheet`,
  worktree /home/user/wt/fable-bs): he has now said no HTML prototypes;
  read it as evidence.
- The art: pofu-art at /home/user/pofu-art (read with `git show origin/main:<path>`):
  - batch 134 (plot pilot A) with its ladder sheet
    `design/art/takes/batch-134-plot-pilot/ladder-sheet.jpg`;
  - batch 137 (BLOCKED, the redo of the lower forms);
  - batch 136 (BLOCKED, the board's lawn);
  - batches 135 and 132 (the flow kit, in the app since #506);
  - the Gezgin's earlier art and concepts (`docs/research/island-progression-2026-11-16/`
    on the lead's branch lists them).
- `QUEUE.md` and `AGENTS.md` in pofu-art say how a manifest and a queue row are written.
- The frames of today's app: `screenshots/main`; fetch only what you need
  with `tools/review/fetch_frames.sh`, never into the main `.git`.
- The founder's log: `docs/product/founder-input.md` (39 and 40 are the newest).

## Output

The Codex concept manifests for the four topics, in pofu-art's manifest
format, and the queue rows with their order (at most two concept jobs
running at once). Write them on a branch in a pofu-art worktree of your
own and open a PR there; the lead reviews and merges it. Add a short
document in the pofu repository that ties the four topics to one another
and to the rest of the game, and says what each concept must show for him
to choose. No HTML or web prototypes, and no app code this round.

## Hand back

What you made, with links; the decisions that change the system, one line
each in Turkish for the founder with your pick first; what you need next.
At most 30 lines; the depth goes in the documents.

## Appendix: the side channel's message, verbatim

The English above is the lead's rendering. Where they differ, this text
governs.

> TEMPO aynı: kurucunun limiti az, vizeleri var. Aynı anda en fazla 2-3 ajan, Codex hattı sürsün, kontrolsüz büyüme yok. HTML ya da artifact prototipi yok; önce konsept, sonra native.
>
> ANA İLKE (kurucunun sözleri): "Burada hiçbir şey ufak ufak fix değil; her şey büyük büyük değerlendirilmeli. Her özellik ilk adımından son adımına, tüm diğer yan bileşenlerle ve tüm diğer özelliklerle beraber, harman değerlendirilmeli. Yoksa bağımsız olarak hepsi ortalama kalır ve birleşince çirkin olur."
>
> YÖNTEM: görselden oyuna, koddan görsele değil. Önce Codex, aşağıdaki her konu için tasarımın tamamını harika gösteren konseptler üretsin; oyundan uzak, birkaç farklı yönde. Kurucu konsept karelerinden seçer; seçim gelene kadar o konuda kod yazılmaz. Seçilen yön uygulamada native yapılır ve kurucuya karesi ya da sürümü gösterilir.
>
> BU İŞ FABLE'IN: tek bir bütünsel Fable turu. Dört konuyu birbirine ve oyunun geri kalanına (ev adası, istasyonlar, karakterler, Gezgin, arayüz dili) bağlayarak ele alsın ve Codex konsept işlerini yazsın. Bütçe: konseptler az ve öz olsun (konu başına birkaç güçlü yön, onlarca değil); Codex'te aynı anda en fazla 2 konsept işi, kalanı sırayla. Fable gerekeni yapsın, gereksizi yapmasın.
> Not: aşağıdaki öneriler (çizim, akış, gradyan/doku, yuvarlak/kare) kurucunun kendi görüşleri; Fable bunları ciddiye alsın ama daha iyi bir yol görürse söylesin.
>
> 1) DERE TAHTASI. Kurucu: "Kodla yazılmış görseller o vibe'ı göstermiyor. Bir tık daha bold, bir tık daha dolu dolu; parçaların üstündeki kaya ve çim dolu dolu hissettirsin." Dönen hücre: yuvarlak daha mantıklı, kare daha güzel; konsept ikisini de denesin. Kurucunun çizimi: her hücre kabarık bir blok, üstü çim (yükseltilmiş zemin), kenarları, yanları ve altı taş; yan yana bloklar birleşip büyük tek blok olur; bazı hücreler boş; masa üstünde oynanan bir mini oyun hissi, gerçek bir dere değil.
>
> 2) SEVİYE YÜKSELTME PANELİ. Daha minimal ve kompakt; arka planda adanın gerçekten büyüdüğü görünsün, panel gerçek görüntüye yer açsın. Arayüz dili bizim karışımımız: cam UI ile işlenmiş (crafted) UI. Seviyeyi gösteren küçük bir ikon (Codex). Codex efektleri. Menü arka planları dümdüz renk değil: temaya uygun, tek renkten geçişli gradyan; gerekirse arkada bir desen ve üstünde gerçek, yüksek çözünürlüklü bir doku. Ayrıntıları kurucu sonra konuşacak.
>
> 3) ADA SEÇME VE GEZGİN. Kurucu: adaların yan yana dizilmesi mantıklı; Gezgin'in prototipteki modeli çok kötü (gözleri vb.). Kurucunun önerdiği akış: Gezgin yerinden kalkmaz; kamera uzaklaşır, oyuncu kaydırarak hangi adaya gideceğini seçer; seçince Gezgin ana adaya gelir, karakterler Gezgin'in park ettiği iskeleden sırtına atlar; ardından yolculuk animasyonu. Menü boyunca Gezgin hareket etmez. Alternatif: Gezgin'in sırtından adaları izlediğimiz bir yol, ama daha iyi bir arayüzle. Değerlendirilsin: Gezgin adalara nasıl park eder, adanın neresinde durur, modeli seviye seviye nasıl olur.
>
> 4) İSTASYON SEVİYELERİ (batch 134/137). Değirmenin genel ilerlemesi güzel. Gölet bir tık abartı: gölet çok büyük, bir nehir geçiyor, köprü oluyor; 1 ile 2 arasındaki geçiş anlamsız. Kurucu: "Hem parça parça mantıklı hem de bir bütün olarak güzel hissettirmeli; her biri hep beraber ve kendi başına da." Her istasyonun her seviyesi, diğer istasyonlar da adadayken bütün adanın karesinde denetlensin; bir istasyon büyürken adayı ele geçirmesin.
>
> Codex konseptleri gelince kurucuya kareleri gönder. Kurucu yarın ayrıntılı geri bildirim verecek.
