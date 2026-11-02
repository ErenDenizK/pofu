# Ücretsiz hesapla iPhone'a kurulum (Prova modu)

Ücretli üyelik gelene kadar Pofu'yu kendi iPhone'unda ücretsiz Apple
hesabınla (Personal Team) çalıştırırsın. Bu sürüm **Prova modu**nda açılır:
Ekran Süresi izni, uygulama seçici, kalkan ve kullanım uygulamanın içinde
taklit edilir. Döngünün tamamı aynıdır; yalnızca Apple'ın ekranları
"Prova" etiketli kopyalardır.

## Gerekenler

- Mac'te **Xcode 26** (App Store).
- **Homebrew** ([brew.sh](https://brew.sh)).
- iPhone ve kablo.

## Kurulum

1. Terminal'de:
   ```sh
   brew install xcodegen
   git clone https://github.com/ErenDenizK/pofu.git
   cd pofu
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```
2. Xcode › Settings › Accounts: Apple hesabını ekle, **Personal Team**'i
   seç ve 10 karakterlik takım kimliğini al.
3. `Config/Local.xcconfig` dosyasını aç, `DEVELOPMENT_TEAM` satırına bu
   kimliği yaz. `PRODUCT_BUNDLE_IDENTIFIER = com.erendenizk.pofu.dev`
   satırına dokunma.
4. Terminal'de:
   ```sh
   xcodegen generate
   open Pofu.xcodeproj
   ```
5. Üstteki şema menüsünden **Pofu**'yu seç (**PofuLive değil**: o, ücretli
   üyelik ister).
6. iPhone'u kabloyla bağla ve hedef olarak onu seç. iPhone'da
   **Ayarlar › Gizlilik ve Güvenlik › Geliştirici Modu**'nu aç; telefon
   yeniden başlar.
7. Xcode'da **Run**'a (▶) bas.
8. İlk açılışta iPhone geliştiriciye güvenmeni ister:
   **Ayarlar › Genel › VPN ve Cihaz Yönetimi** › Apple hesabın ›
   **Güven**. Sonra Pofu'yu aç.

## 7 gün sınırı

Ücretsiz hesapla imzalanan uygulama **7 gün** sonra açılmaz. iPhone'u
bağla ve Xcode'da yine **Run**'a bas: uygulama yeniden imzalanır, veriler
kalır. Uygulamayı silersen veriler de silinir. 6 günde bir hatırlatıcı
kur.

Kod güncellendiyse önce `git pull`, sonra `xcodegen generate`, sonra
**Run**.

## Prova modunu kullanmak

1. Kurulumu bitir: Apple'ın izin ekranı ve uygulama seçici "Prova" etiketli
   kopyalardır; bildirim izni gerçektir, ver.
2. Sağ üstteki **Prova** panelinden **Instagram'a uzan**: kalkan açılır;
   **Boş ver**, **Açmam lazım › 3 dakika bakacağım** ya da **Pofu'yla aç**
   (gelen bildirime dokun, Hop! açılır).
3. **+15 dk kullanım** günlük saati doldurur; dört kez basınca açılışlar
   nefesle başlar.
4. **1 saat ileri** ve **Gece/Sabah** telefonu bırakmış gibi zamanı
   ilerletir: huzur ve çekirdekler adada değişir; uygulamanın içindeyken
   zaman izin bitene kadar ilerler ve kalkan geri gelir.
5. **Sıfırla** her şeyi baştan başlatır. Prova verileri ayrı tutulur ve
   "simulated" olarak işaretlenir; gerçek ölçümlere karışmaz.

Eski sürümden kalma Kestirmeler otomasyonların varsa kapat: Prova modunda
gerekmez. Kestirmeler kurulumu yalnızca Ayarlar'da durur.
