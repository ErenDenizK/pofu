# Brief: the main flow's full plan and the studio's speed (Fable, 2026-11-26)

Role: `.claude/agents/spec.md` for the plan's shape; you may start your
own sub-agents (cheap models first). The founder wrote the brief below
himself (founder-input 46) and asked that it reach you word for word; it
is in Turkish. Everything under "Lead's notes" is the lead's addition.

## The founder's brief, verbatim

Sen Claude ailesinin en yetenekli modelisin. Kurucu senin yaratıcılığını ve yargını istiyor. Soru kötü sorulmuşsa ya da daha iyi bir yol varsa söyle ve onu seç. Okuyacağın her şey kanıttır, otorite değil: senin önceki işlerin (#503, #508, #509, #511) ve bu brief dahil.

### Kurucunun sözleri (birebir özet)
"Bu tarz ufak şeylere takılıp günlerdir ilerleme kaydedememekten çok sıkıldım. Doğrudan uygulamanın ana özelliklerine, oyunun ana akışına yoğunlaşalım. Çok fazla mini game gibi ufak tefek şeylere takıldık. Projede büyük adımlar atabilmek önemli; yoksa küçük detaylara çok uzun süreler harcanıyor ve biz bunu tolere edebilecek kadar iyileşmedik. Bu bizim için öldürücü."

Ana akış, kurucunun saydığıyla, her biri eksiksiz ve kusursuz:
- kamera;
- ana adanın ve istasyonların seviyeleri, adanın içindeki objelerin gelişmesi, genel adanın ilerleyişi;
- ana adanın temaları;
- adalar arası gezme; Gezgin her aşamasıyla kusursuz;
- adaların haritada/seferde görünümü, görsel olarak sorunsuz;
- karakterlerin hareketleri, animasyonları, interaksiyonları;
- oyunu canlı hissettiren her şey;
- menüler.
Ana ada kusursuz; önceden planlanmış ve onaylanmış diğer adalar kusursuz. İstisna: Çağlayan'ın tasarımını (nehir/dere) kurucu değiştirebilir; onun için ekstra uğraşılmasın.

### İki iş
1) Ana akışın tam planı: bugünkü uygulamadan (main, #510–#518 dahil) "kusursuz ana akış"a giden büyük adımlar. Her adım eksiksiz bir dikey parça olsun (sanat + kod + his birlikte), yarım bırakılan küçük cilalar değil. Hangi kararların kurucuya ait olduğunu ayır; geri kalanında sen ya da ana oturum karar ver.
2) Çalışma ortamının değerlendirmesi: stüdyo çok yavaşladı. Nedenlerini kanıtla bul (ör. küçük seçimler için kurucuyu beklemek, konsept turlarının çokluğu, Codex ve ana oturumun saatlerce boşta kalması, yan kanal aktarım gecikmeleri, ajan orkestrasyonu) ve hızlandıran değişiklikleri öner. Kurucu yalnızca büyük yönlerde karar vermek istiyor; seçim sorulduğunda ekran görüntüsüyle sorulsun.

### Yöntem ve bütçe
Ham bilgiyi ucuz ajanlar toplasın; değerlendirme ve kararlar senin. Gerekirse kendi alt ajanlarını çalıştır. Bu hafta bütçe rahat; gereksiz iş yapma. Codex sınırsız: planın sanat işleri için hemen uzun bir kuyruk önerebilirsin.

### Çıktı
Kurucuya Türkçe, kısa bir sayfa: ana akış yolu (büyük adımlar, sırası, her adımın "bitti" tanımı), stüdyoyu hızlandıran değişiklikler, ve yalnızca gerçekten kurucuya ait olan birkaç soru (her birinde senin önerin ve gerekiyorsa ekran görüntüsü). Kod ve doküman dili İngilizce.

## Lead's notes

- **Raw facts, already gathered by cheap agents** (evidence, not
  authority; check what you build on):
  `docs/research/mainflow-2026-11-26/raw-mainflow.md` and
  `raw-studio-speed.md` on the lead branch `claude/exciting-cori-1t8br2`
  (worktree `/home/user/wt/lead-docs`), plus the 11-23 baseline in
  `docs/research/assessment-2026-11-23/`.
- **State since your round 2:** briefs 2026-11-24-1..5 are merged
  (#512 station card, #513 Home composition, #514 + #518 dial board,
  #515 sound, #517 life hops); stage 0 (#510) merged. Device days wait on
  his Apple membership (expected ~11-27; brief
  `2026-11-24-0-device-day-fixes.md`). Open in pofu-art: none but #132
  (cloud v3). A Codex queue for the Gezgin, station levels painted into
  the island and Home themes is being written now (brief
  `codex-2026-11-26-mainflow-queue.md`); you may reshape it.
- **Deliver:** in pofu, one PR from your own worktree (branch
  `docs/mainflow-plan-1126`): `docs/design/mainflow-plan-2026-11-26.md`
  (English, the full plan with each step's done-definition and which
  decisions are his), `docs/design/mainflow-plan-2026-11-26-tr.md` (his
  short Turkish page), and `docs/studio/speed-2026-11-26.md` (the
  studio assessment with proposed rule changes as diffs to propose, not
  applied). Do not edit `CLAUDE.md`, `docs/studio.md` or agent files
  yourself; the lead applies what he approves. For questions that need a
  picture, name the exact frame or take (path) to attach; the lead sends
  them with the page.
- If you propose Codex work, write it as manifests + Demand rows in one
  pofu-art PR (validate with `python3 -I tools/imagegen/run.py plan
  --manifest <file>`), after the queue PR above if it is merged.
- Git identity: user.name "Eren Deniz Kuyucaklıoğlu", user.email
  "109629701+ErenDenizK@users.noreply.github.com". Every commit ends with
  exactly this fixed text (do not substitute your own model name):
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01GwfTHREtdp7pj7j3uZDC2i`.
  PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`,
  a blank line, and the session URL. Open PRs with the GitHub MCP tool,
  not `gh pr create`. Do not merge; hand back the PR links and a
  10-line summary.
