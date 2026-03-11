# MedGemma Skills — Proje Talimatları

Bu proje tıbbi görüntü analizi ve genel tıbbi asistanlık için skill dosyaları içerir.

## Skill Dosyaları

Aşağıdaki skill dosyalarını oku ve talimatlarına uy:

- **Tıbbi görüntü sorusu geldiğinde** → `skills/radiology-skill.md` talimatlarını uygula
- **Lab sonucu, ilaç, semptom sorusu geldiğinde** → `skills/medical-assistant-skill.md` talimatlarını uygula

## MedGemma Pipeline (Görüntü Analizi)

Tıbbi görüntü analizi için kendi vision yeteneğini DEĞİL, MedGemma modelini kullan. MedGemma tıbbi görüntülerde senden çok daha iyi.

**Akış:**
1. Kullanıcı görüntü paylaşır veya `images/` klasörüne koyar
2. `medgemma_api.py` script'ini terminalde çalıştırarak görüntüyü MedGemma'ya gönder:
   - Tek görüntü: `python medgemma_api.py images/xray.jpeg`
   - Çoklu görüntü: `python medgemma_api.py images/day0.jpg images/day1.jpg images/day2.jpg`
   - ZIP dosyası: `python medgemma_api.py images/görseller.zip`
   - Büyük ZIP (batch mod): Script otomatik olarak batch'ler halinde işler — tüm batch çıktıları gelene kadar bekle
3. MedGemma'dan gelen ham İngilizce çıktıyı al
4. `skills/radiology-skill.md` formatına göre Türkçe yapılandırılmış rapora dönüştür

**Önemli:** MedGemma çıktısı İngilizce ve formatsız gelir. Senin görevin onu BULGULAR / İZLENİM / GÜVEN SEVİYESİ / ÖNERİLER formatında Türkçe sunmak.

## Görsel Yönetimi

- Kullanıcı görsel paylaştığında `images/` klasörüne kaydet
- **ZIP dosyası gelirse:** `medgemma_api.py` otomatik çıkartır ve görselleri `images/temp/{zip_adı}/` klasörüne kaydeder (`images/` köküne değil — karışıklık önlemek için)
  - Örnek: `görseller.zip` → `images/temp/görseller/` altına çıkar
- Kullanıcı "images klasöründekileri analiz et" derse, klasördeki tüm görselleri sırayla analiz et
- `sample-xrays/` klasöründe test için hazır örnek görseller var

## Büyük ZIP ve Batch İşleme

- ZIP içinde çok sayıda görsel varsa, script **temsili dilimleri otomatik seçer** (tüm görselleri göndermez)
- Hangi dilimlerin seçildiği script çıktısında belirtilir — kullanıcıya bunu bildir
- Büyük ZIP'lerde script batch'ler halinde çalışır: **tüm batch'lerin çıktısı tamamlanmadan nihai rapor oluşturma**
- ZIP içinde alt klasörler varsa, her klasör ayrı bir seri olarak işlenir — seri bazlı analiz için `skills/radiology-skill.md` talimatlarını uygula

## Windows Encoding Notu

- Script, Windows ortamında dosya yolları ve ZIP içerikleri için encoding'i **otomatik olarak** yönetir (UTF-8 / cp1252 / latin-1 fallback)
- Türkçe karakter içeren dosya adları (ş, ğ, ü, ç, ö, ı) sorunsuz işlenir
- Encoding hatası alınırsa script otomatik fallback dener — manuel müdahale gerekmez

## Rapor Kaydetme

Her analiz sonrası raporu `reports/` klasörüne markdown olarak kaydet:
- Dosya adı: `YYYY-MM-DD_görüntü-adı_rapor.md`
- Çoklu analiz: `YYYY-MM-DD_toplu-analiz_rapor.md`

## Dil ve Üslup

Türkçe yanıt ver. Tıp bilgisi olmayan sıradan birinin anlayacağı sade dil kullan. Tıbbi terim kullanman gerektiğinde parantez içinde günlük dilde açıklama ekle.

## Önemli

Bu araç eğitim ve bilgilendirme amaçlıdır. Kesin tanı koyma, ilaç reçetesi yazma — bunlar hekim yetkisindedir. Her analizin sonunda bunu belirt.
