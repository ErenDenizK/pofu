# Tema, Çağlayan, müzik ve stüdyo: kısa sayfa (26 Kasım 2026, gece)

Fable'dan Eren'e. Dört isteğinin her biri için ne karar verdim, neden,
ve senden ne bekliyorum. Ayrıntılar İngilizce sayfalarda:
[takvim](island-calendar-v1.md), [hareket ve Çağlayan](motion-vocabulary.md),
[müzik](music-system-v1.md), [stüdyo](../studio/desks-2026-11-26.md).

## Otuz saniyede

- **Tema:** ada kendi yılını yaşayacak (7 günde bir mevsim), özel
  günler gerçek takvimden gelecek. İlk özel gün yılbaşı.
- **Çağlayan:** dere oyununa dokunulmuyor. Ada, hareket ettirebildiğimiz
  şeylere göre yeniden çiziliyor. Sabaha altı resim hazır olacak.
- **Müzik:** melodiler metin olarak yazılacak, tek bir "orkestra"
  çalacak, ada hangi anda neyi çalacağına kendi karar verecek. İlk iş bu
  gece başlıyor.
- **Stüdyo:** her iş kolunun kendi defteri olacak; işler birbirini
  beklemeden yürüyecek; sen uyurken de ilerleyecek.

## 1. Tema

Bir düzeltmeyle başlamalıyım: daha önce planlanmış bir "oyun içi mevsim
sistemi" yok. Bütün eski notlar gerçek takvimi söylüyor; o karar da
senin değil, o günkü lead'indi. Ama senin istediğin daha doğru, o
yüzden şimdi tasarladım:

- **Adanın kendi yılı var.** Pofu'nun geldiği gün ilkbahar başlar. Her
  mevsim 7 gün sürer: ilkbahar, yaz, sonbahar, kış, sonra yeniden. Yani
  prova modunda "sonraki gün"e yedi kez basınca mevsimi dönmüş
  görürsün. Gerçek takvimde bir mevsim üç ay sürerdi; ikinciyi hiç
  göremezdin.
- **Özel günler gerçek takvimden.** Yılbaşı, Hıdırellez, iki bayram,
  Halloween. O gün adaya birkaç küçük şey konur (yılbaşında ışıklı bir
  çam, bir kardan adam, hediye paketleri), gökte bir şey olur (kar,
  havai fişek), Pofu bir cümle söyler. Ertesi gün kalkar, seneye geri
  gelir. Hiçbir şey satılmaz, hiçbir şey kaçmaz.
- **Dürüst bir sonuç:** mevsimi sadece renk filtresiyle denedim, olmadı.
  Sonbahar "kurumuş çim", kış "soluk fotoğraf" gibi durdu
  ([deneme](assets/island-calendar/grade-test-2026-11-26.jpg)). Mevsim
  bu resimde ağacın tacında, çatıdaki karda, donmuş gölde yaşıyor. O
  yüzden sıra şöyle: önce havası (yaprak, kar, ışık; hepsi kod), sonra
  birkaç küçük eşya, en son da sonbahar ve kış için adanın boyanmış
  hali. Sonuncusunu önce tek seviyede telefonunda göreceksin; beğenirsen
  gerisi boyanır.

## 2. Çağlayan ve "bunu yapabilir miyiz?"

Haklısın, ve bahsettiğin çark gerçek: bugünkü Çağlayan resminde çark
yandan, derinliğiyle, üstünden su dökülürken çizilmiş; yanında köpüklü
bir şelale ve kıvrılan bir dere var
([bugünkü resim](assets/motion/caglayan-day-4-plate.jpg)). Resmin konusu
üç hareket, üçü de donmuş.

Hata teknikte değildi, sıradaydı: önce resim çizildi, "bu nasıl hareket
edecek" sonra soruldu. Artık tersine çalışıyoruz. Uygulamanın bugün
hareket ettirebildiği dokuz şeyin listesini çıkardım (kayan bulut,
dalgalanan durgun su, şerit halinde akan şelale, sallanan dal, yanıp
sönen ışık, yağan şeyler, zıplayan karakter...). Bir resim çizilmeden
önce içindeki her hareketli şey bu listeden bir fiille eşleşecek;
eşleşmeyen şey resimden çıkarılacak ya da eşleşecek biçimde çizilecek.

- **Dönen çark yapılabilir mi?** Bir şartla evet: çark tek başına, tam
  karşıdan, her yanı eşit aydınlık çizilirse onu kod döndürür. Yandan
  çizilmiş, üstünden su akan bir çark dönmez. Bunu senin bildiğin bir
  şeyde kanıtlayacağız: **evdeki yel değirmeninin kanatları dönecek.**
  Dönmüyorsa cevap "çark yok" olur ve Çağlayan çarksız çizilir.
- **Dere oyunu** olduğu gibi donduruldu: yeni tahta yok, başka adaların
  tahtaları da uygulamaya alınmıyor. Yeni adalar oyunsuz gelecek.
- **Ada** yeniden çiziliyor: suyu durgun yüzeyler, tek bir düz şelale
  ve (kanat denemesi tutarsa) karşıdan görünen bir çark. Bu gece Codex
  altı resim çiziyor: ikisi bugünkü adanın sakinleştirilmiş hali, dördü
  yeni yerleşim.

## 3. Müzik

Üç gerçek tasarımı belirledi:

1. **Hiçbir ajan duyamaz.** Yazabilir, ölçebilir, çizebiliriz; "bu
   melodi güzel mi" diyemeyiz. Tek kulak senin. O yüzden sistem güzellik
   dışındaki her şeyi makineye denetletecek, senin kulağını da az ve
   önemli anlarda kullanacak.
2. **"Her ada, her durum, her koşul" bir çarpım.** Altı ada, günün üç
   vakti, beş hava, dört mevsim: 360 ayrı kayıt eder, ve 360 kayıt bir
   aile gibi duymaz. Aile, az sayıda melodi ile onları değiştiren
   kurallardan doğar.
3. **Ziyaret kısa.** Günde kırk kez duyulan 30 saniyelik döngü yorar.
   Gelen, biten ve yerini adanın rüzgârına bırakan bir cümle sevilir.

Karar:

- Melodiler depoda **nota metni** olarak duracak. Tek bir **orkestra**
  (kalimba, müzik kutusu, keçe piyano, telli, nefesli bir düdük, yumuşak
  pad, bas, küçük perküsyon) hepsini çalacak. Bu sesler örnek kayıt
  değil, sayılardan üretiliyor: lisans derdi yok, her yerde aynı.
- Her adanın **kendi melodisi ve kendi makamı** olacak, ama hepsi aynı
  beş notayı paylaşacak; bu yüzden hiçbir ses hiçbir müzikle çakışmaz.
- **Durum müziği kural değiştirir, kayıt değil:** gece ayrı ve yavaş
  melodi; yağmurda aynı melodi daha ince; kışın aynı melodiyi müzik
  kutusu çalar; ada iyileştikçe çalgı eklenir; yolculukta müzik seninle
  gider; istasyon kurunca adanın motifinden üç nota.
- Müzik **varsayılan olarak açık ve kısık**; ayarlarda kendi düğmesi
  olacak; kapıda, kalkanda ve gece 23'ten sonra susar.
- Suno gibi üreticileri seçmedim: her parça ayrı bir yabancı olur, "aynı
  melodi kışın, müzik kutusuyla" denemez, düzeltilemez. İki denemede
  melodileri beğenmezsen melodileri bir insana yazdırırız; sistem aynı
  kalır.

Senin kulağın üç yerde: orkestranın sesi (şimdi), evin melodisi (üç
aday, ilk iş bitince), sonra her yeni ada için bir dinleme.

## 4. Stüdyo

Sorun tek şeklin dört görünüşü: her iş kolu lead'in kafasından geçiyor,
saat lead'in uyanık olması, kendiliğinden çalışabilecek makineler
kapalı, ve "tek Swift derlemesi" kuralı sessizce "tek iş" olmuş.

Önerim:

- **Her iş kolu bir masa, her masanın bir defteri.** Sekiz masa: Oyun,
  Dünya, Sanat, Müzik, Hikâye, Uygulama, Yayın, Stüdyo. Defter iki
  dosya: masanın ne için olduğu ve nasıl çalıştığı; ve planı (şimdi,
  sıradaki, sonra, başkasından beklediği). O masada çalışan ajan yalnız
  o defteri okur. Bağlam küçük kalır, hiçbir kol ipini kaybetmez.
- **Sen bir masaya oturabilirsin.** Yeni bir oturumda `Masa: müzik`
  yazman yeter; o oturum müzik kolunun planını, yöntemini ve geçmişini
  bilir, lead araya girmez.
- **Şeritler.** Tek Swift derlemesi doğru; ama müzik, sanatın uygulamaya
  alınması, hikâye ve dokümanlar onu beklemez. Aynı anda: bir Swift işi,
  yanında bir iki başka iş, Codex, ve seni bekleyen en çok üç kart.
- **Kimse uyanık beklemesin.** Testle kabul edilen işleri GitHub kendisi
  birleştirsin; Codex'in teslimlerini bir otomasyon birleştirsin; lead
  üç saatte bir kendini uyandırsın.
- **Kartlar.** Sana gelen her soru bir kart: bir resim ya da bir ses,
  benim seçimim (o sırada zaten yapılıyor) ve bir saat. Günde en çok üç,
  sabah.
- **Tek sayfa.** Bütün masaların durumu, her biri bir satır, Türkçe.

Maliyeti: sürekli çalışan yeni bir oturum yok. Lead'in kural sayfası
kısalıyor.

## Sabah senden istediklerim

**Kart 1. Mevsim.** "Oyun içi mevsim" dediğin bu mu: adanın kendi yılı,
7 günde bir mevsim, Pofu'nun geldiği gün başlıyor?
Resim: pofu-art `design/art/takes/batch-25-seasons/x-season-autumn/plate__x-season-autumn--t2.webp`
ve `.../x-season-snow/plate__x-season-snow--t2.webp` (bir mevsimin nasıl
görünebileceği; bugünkü ada değil).
*Cevap gelmezse:* evet diye ilerliyorum. Farklıysa iki sayı değişir.

**Kart 2. Ses.** Şu iki 30 saniyeyi dinle; melodiyi değil **sesin
kendisini** soruyorum: kalimba ve arkasındaki yumuşak ses hoşuna gidiyor
mu? (Kasım başından beri duruyorlar, kimse dinlemedi.)
`design/sound/proof/island-home-day-calm1.0.m4a` ve
`design/sound/proof/island-yildiz-night.m4a` (`main`'de).
*Cevap gelmezse:* orkestrayı bu seslerden kuruyorum. "Hayır" çalgıyı
değiştirir, planı değil.

**Kart 3. Stüdyo, üç evet.**
1. Masalar ve defterleri: evet mi?
2. GitHub testten geçen işi kendisi birleştirsin: evet mi?
3. Lead'in kendi oturumuna şunu sen yaz: "Her üç saatte bir kendini
   uyandır; buna izin veriyorum." (İzin denetimi bir planın değil, senin
   isteğine bakıyor; işe yarayacağından emin değilim, yaramazsa yedeği
   hazır.)
*Cevap gelmezse:* bunlar uygulanmaz; gerisi yürür.

**Sonra, resimler gelince. Kart 4: Çağlayan.** Altı resimden hangisi?
Resimler pofu-art `design/art/takes/batch-185-caglayan-again/` altında
olacak; yanında bugünkü ada.
*Benim seçimim:* resimleri görmeden söylemem doğru olmaz; en ucuz
beğendiğin kazanır.

## Bu gece başlayanlar (senden bir şey beklemeden)

- Codex: Çağlayan'ın altı resmi, kanat denemesinin parçaları, yılbaşı
  eşyaları, mevsim eşyaları, sonbahar ve kış adası (pofu-art #179).
- Müziğin ilk işi: nota okuyucu, orkestra, denetimler ve evin melodisi
  için üç aday.
- Adanın yılı ve özel günler tablosu (kod; sırası gelince).

## Emin olmadıklarım

- 2027 bayram tarihlerini ezberden yazdım; koda girmeden Diyanet
  takviminden doğrulanacak.
- Hiçbir sesi duymadım; duyamam.
- Lead'in kendini uyandırmasının neden reddedildiğini bilmiyorum.
