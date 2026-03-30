# WeFriend Teknik Kurallar ve Mimari

## Ürün Konumlandırma
- Hedef: Connected2.me rakibi; anonim sohbet ve takma ad odaklı deneyim.
- Temel farklılaştırıcılar: güçlü gizlilik (UUID/alias), uçtan uca şifreleme, güvenli saklama, hızlı gerçek zamanlı altyapı.
- Odak metrikler: aktif sohbetler, mesaj teslim oranı, yeniden bağlanma başarı oranı, gecikme.

## Mimarî Özeti
- Mobil istemci: Flutter (iOS + Android)
- Durum yönetimi: Riverpod
- Navigasyon: GoRouter
- Ağ/HTTP: Dio + Interceptor (JWT)
- Gerçek zamanlı mesajlaşma: socket_io_client
- Şifreleme: encrypt (uçtan uca)
- Güvenli saklama: flutter_secure_storage (token/anahtarlar)
- Görseller: cached_network_image
- Güvenlik: local_auth (biyometrik kilit)
- Bildirim: firebase_messaging (push)
- Veritabanı: MySQL (sunucu tarafı)

## Tasarım İlkeleri
- Görsel dil: Material 3; modern, sade ve net tipografi.
- Renk: Seed color tabanlı ColorScheme; açık/koyu mod tam destek.
- Bileşenler: yuvarlatılmış köşeler, düşük elevasyon, yumuşak gölgeler, net kontrast.
- Tipografi: büyük başlıklar, güçlü hiyerarşi; metin kontrastı WCAG AA.
- Hareket: mikro etkileşimler, akıcı geçişler; ani animasyon yok.
- Durumlar: yükleme iskeleti, boş durum, hata/başarı geri bildirimi.
- Erişilebilirlik: minimum dokunma alanı 44px, VoiceOver/TalkBack uyumu.
- Tutarlılık: aralıklar 8px grid; ikonlar düzenli set; layout kırpma yok.
- Dark mode: renkler düşük parlaklık, kontrast dengeli; medya arka planlarına dikkat.
- Marka: anonim ve güvenli his; sade, dingin ve modern palet; ana renk kırmızı pastel (seed).

## Görselleştirme
- visualize
- visualize show_widget

## Anonimlik ve Kimlik Kuralları
- Kullanıcı kayıt sırasında telefon numarası verir; başka kullanıcılarla ASLA paylaşılmaz.
- Her kullanıcıya rastgele üretilmiş UUID atanır ve tüm mesajlaşma bu UUID üzerinden yürür.
- Karşı taraf sadece kullanıcının seçtiği takma adı (alias) görür; ad, numara, e-posta vb. görünmez.
- Sunucuda telefon numarası hash + salt ile saklanır; doğrudan sorgulanamaz/verilemez.

## İsimlendirme ve ID’ler
- Kullanıcı ana kimlik: `user_uuid` (v4 UUID)
- Görünen ad: `alias`
- Mesaj yönlendirme: yalnızca `sender_uuid` ve `receiver_uuid`
- Cihaz/oturum tanımlama: `device_id`, `session_id` (gerekirse)

## Ağ ve Güvenlik Kuralları (İstemci)
- Tüm HTTP istekleri Dio ile; `JWT` Authorization header otomatik olarak Interceptor ile eklenir.
- JWT alınması/yenilenmesi sonrası token `flutter_secure_storage` içinde saklanır.
- Uçtan uca şifreleme için `encrypt` ile mesaj içeriği istemci tarafında şifrelenir; sunucu sadece şifreli metni tutar.
- Uygulama açılışında veya arka plan dönüşünde `local_auth` ile isteğe bağlı biyometrik kilit.
- Push bildirimi `firebase_messaging`; konu/cihaz token yönetimi istemci tarafından yapılır.
- Gerçek zamanlı kanal `socket_io_client`; kimlik doğrulama JWT ile handshake sırasında gönderilir.

## Mesajlaşma Akışı (Özet)
- İstemci, alias ve `user_uuid` ile oturum açar; JWT alır.
- Mesaj gönderirken: düz metin -> istemci tarafı şifreleme -> şifreli veri + `sender_uuid` + `receiver_uuid` gönderilir.
- Mesaj alırken: şifreli veri -> istemci tarafı çözme -> gösterim.
- Sunucu tarafında içerik indexlenmez; yalnızca meta ve şifreli gövde saklanır.

## MySQL Kuralları (Sunucu Tarafı)
- Temel tablolar:
  - `users(user_uuid PK, alias, phone_hash, created_at, ...)`
  - `messages(id PK, sender_uuid FK, receiver_uuid FK, ciphertext, created_at, delivered_at, read_at, ...)`
  - `devices(user_uuid FK, device_id, push_token, updated_at, ...)`
  - `sessions(session_id PK, user_uuid FK, jwt_revoked BOOLEAN, expires_at, ...)`
- `phone_hash` benzersiz indeks; düz telefon numarası saklanmaz.
- Mesaj `ciphertext` sütunu BLOB/TEXT; arama amaçlı içerik indexlenmez.
- Yabancı anahtarlar `*_uuid` alanları ile; cascade silme devre dışı, mantıksal silme tercih edilir (`deleted_at`).
- Zaman damgaları UTC; istemci yerel saat dönüşümü yapar.

## İstemci Tarafı Paket Kullanımı
- `riverpod`: Ekran/feature seviyesinde provider’lar; global mutable state yok.
- `go_router`: Tüm rotalar tek merkezde; korumalı ekranlar için auth guard.
- `cached_network_image`: Profil ve medya gösterimleri için bellek/disk cache.
- `flutter_secure_storage`: Anahtar/token saklama; paylaşılan tercih depoları kullanılmaz.
- `local_auth`: Kullanıcı tercihi doğrultusunda açılış kilidi.
- `firebase_messaging`: Arka plan/ön plan bildirim işleyicileri; izin yönetimi.
- `socket_io_client`: Oda/kanal abonelikleri `user_uuid` bazlı; yeniden bağlanma stratejisi etkin.
- `dio + interceptor`: Hata haritalama, zaman aşımı, otomatik yeniden deneme politikaları.

## Uyumluluk ve İnce Ayar
- Tüm kimlik ve gizlilik kuralları zorunlu; ihlal edilemez.
- Loglarda PII yok; yalnızca UUID ve hata kodları.
- Çevrimdışı destek: gönderilemeyen mesajlar kuyruklanır, bağlantı geldiğinde gönderilir.
- Medya gönderimi: ayrı uç noktalar ve imzalı URL’ler; istemci tarafında yükleme ilerlemesi izlenir.

## Test ve Doğrulama (Öneri)
- Birim test: şifreleme/çözme, interceptor token ekleme, provider’lar.
- Entegrasyon: mesaj akışı ve yeniden bağlanma, push bildirim alma.
- Güvenlik: token yenileme, kilit ekranı, hassas veri depolama.

---
Bu dosya, Flutter istemci ve MySQL tabanlı sunucu için değişmez teknik kuralları ve mimari ilkeleri tanımlar.
