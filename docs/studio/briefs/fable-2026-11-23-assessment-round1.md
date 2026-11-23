# Fable brief: whole-project assessment, round 1 of 2 (2026-11-23)

The founder read and approved the brief below through the side channel
(founder-input 43). It is verbatim; the lead's notes follow it and only
add where things are. Where they differ, the founder's text governs.

## The brief (verbatim, Turkish)

Sen Claude ailesinin en yetenekli modelisin. Kurucu senin yaratıcılığını ve yargını istiyor. Soru kötü sorulmuşsa ya da daha iyi bir yol varsa söyle ve o yolu seç. Okuyacağın her şey kanıttır, otorite değildir: senin önceki işlerin, ana oturumun dokümanları ve bu brief de buna dahil.

### Bağlam
Pofu, kurucu Eren'in iOS oyunu. Hikâyesi ve kuralları CLAUDE.md, docs/studio.md ve docs/now.md dosyalarında. docs/now.md 16 Kasım'dan beri güncellenmedi; main'in son hali #508 (18 Kasım). Kurucunun vizeleri bitti ve bu hafta projeye daha çok vakit ayıracak. Kurucu fırsat buldukça telefonda test ediyor; birkaç gün içinde (25-27 Kasım) daha düzenli teste geçecek. Önemli bir ayrıntı: birkaç gün sonra Apple tarafındaki kitler/izinler erişimimize açılıyor (hangisi olduğunu dokümanlardan ve koddan doğrula; ör. Screen Time / Family Controls). Bu, uygulamanın gerçek işlevini etkileyen büyük bir adım; değerlendirme buna hazırlığı da kapsasın. Kurucunun sözleriyle: "Önce uygulamanın mükemmel olduğundan emin olalım."

Son iki haftada: dünya sunumu ve kamera (#474–#480, #502); hareket eden gölet (#505); dere oyununun ilk elden geçirilmesi (#501, #506); ada ilerlemesi önerisi (#503) ve dört konuyu bağlayan doküman (#508); Codex'in iki konsept turu (pofu-art batch 138–145 ve 146–153).

### Kurucunun konsept turları için söyledikleri (birebir)
"Her şey çok cafcaflı, extravaganza çizilmiş. Önce gerçekten konsept art hissiyle, daha simple bir vizyon sunmasını istemiştim."
- Dere tahtası: en güzeli board-dial t2; oyun dünyasıyla mini oyunu harmanlıyor. board-key big de güzel. table güzel değil. pool-tray'den emin değil. Blok konsepti ve dokular beğenildi.
- Seviye paneli: ladder olmasın; seviyeler altta bir kez daha sıralanmasın. Bubble mı alttan bir panel mi, emin değil. Kafasındaki: card gibi cam bir obje, kenarında ya da üstünde ufak bir tasarım. Codex'in cam arayüzü uydurma duruyor, bu yüzden uygulamada test edilmeli. Menüler genel olarak güzel değil.
- Yolculuk ve Gezgin: A2 (row) mantıklı. Gezgin'i arkadan görmek güzel değil. Gezgin'in ilk seviyesi balinaya benzemiyor: kuyruğu olsun, pofuduk olsun. 2-3 seviye yeter. Her adada nerede bağlandığı önemli. Ada seçme ekranı sağ alttan mı açılacak, Gezgin'e dokunarak mı?
- Ada ve istasyonlar: adım adım büyüme fena değil. Gölet için emin değil. Gölet gibi adanın önündeki şeylerin arkasında Pofu kalırsa görülebilecek mi?

### İş
Projenin tamamına kapsamlı bir genel değerlendirme yap. Ürün, his, görsel, teknik durum ve üretim hattı birlikte. Uygulamanın gerçekten mükemmel olmasının önünde ne duruyor, bul: eksikler; yapılacaklar ve sıraları; teknik borç ve riskler; dört konunun ve ikinci tur konseptlerinin durumu; karakter hareketi, navigasyon, ziyaretçiler, ses ve müzik gibi açık kalan sistemler. Gerektiğinde kurucuya sorular sor.

Gerçek, kod ve pikseldir: iddiaları dosyadan ya da kareden doğrula. Ham bilgiyi toplamak için ucuz alt ajanlar (Haiku, Sonnet) kullanabilirsin. Değerlendirme ve kararlar senin. Bütçe bu hafta biraz daha rahat, ama gereksiz iş yapma.

### İki tur
Bu iş iki Fable turu olarak çalışır, çünkü önemli bir adım atıyoruz. Önce ucuz ajanlar ham bilgiyi toplar. Tur 1 (sen): değerlendirme ve kurucuya sorular; kurucu cevaplar. Tur 2 (sen, cevaplarla): kesinleşmiş yol, sıra ve görev dağılımı.

### Çıktı (tur 1)
Kurucuya sunulacak bir değerlendirme; biçimine sen karar ver. İçinde: durum; en önemli sorunlar; önerdiğin yol ve sırası; kim neyi yapacak (ana oturum, ajanlar, Codex); kurucunun cevaplaması gereken sorular, her birinde senin önerinle. Kurucu Türkçe okur; kod ve doküman dili İngilizce.

## The lead's notes (where things are)

- **Raw facts, already gathered** by two cheap agents (evidence, not
  authority; check what you build on):
  `docs/research/assessment-2026-11-23/raw-app-and-code.md` and
  `raw-art-and-line.md` on the lead branch `claude/exciting-cori-1t8br2`
  (worktree `/home/user/wt/lead-docs`). Spawn more cheap sub-agents only
  for gaps; at most two at once.
- **The lead's own state:** `docs/now.md` on the lead branch is current
  to 11-18 (main's copy is older); `docs/product/founder-input.md` there
  holds entries 39-43.
- **Round names:** round 1 is pofu-art batches 138-145 (`x-...` jobs;
  "board-dial" is `x-board-dial-*`, batch 138; "board-key big" is
  `x-board-key-big`; "ladder" is `x-panel-ladder`, batch 139; "A2 (row)"
  is `x-voy-a2-row`, batch 140). Round 2 is 146-153 (`x2-...`), merged
  11-23 except batch 152, which delivered nothing on quota. The round-1
  sheets are `design/review/concept-round-1/*.jpg` in pofu-art. Read
  pofu-art with `git -C /home/user/pofu-art show origin/main:<path>`.
- **Codex now:** a lead-started agent is queuing a small round 3 of safe
  concept jobs that follow only from his verdict above (the Gezgin as a
  fluffy whale in 2-3 levels with front views and her mooring; the
  dial-t2 and key-big boards, simpler; Pofu behind the pond). Treat it as
  in flight; say if your assessment would change or stop it.
- **Frames:** `screenshots/main`; fetch only what you need with
  `tools/review/fetch_frames.sh`, never into the main `.git`.
- **Open pofu PRs:** #503, #507 (evidence), #490 and older ones; the raw
  file lists them.

## Output and hand back

Write the assessment on your own branch in a pofu worktree (e.g.
`design/assessment-2026-11-23`) as a document in English under
`docs/design/`, plus the founder-facing part in Turkish (the status,
the main problems, the path, and the questions each with your
recommendation) in a form he can read on his phone. Open a pofu PR
(`mcp__github__create_pull_request`; `gh pr create` fails). No app code.
Hand back at most 30 lines: links, the questions in Turkish with your
pick first, and what round 2 will need.
