# MedGemma Skills

Google'ın açık kaynak tıbbi AI modeli [MedGemma](https://huggingface.co/google/medgemma-1.5-4b-it) için hazır skill dosyaları. Cursor, Claude Code, Antigravity veya herhangi bir AI IDE ile kullanılabilir.

## Ne İşe Yarar?

Bu repo'yu bir AI IDE'de (Cursor, Antigravity, Claude Code) açtığınızda, AI asistanınız otomatik olarak:
- **Tıbbi görüntüleri** MedGemma ile analiz eder (X-ray, CT, MRI)
- **Lab sonuçlarını** yorumlar, **ilaç etkileşimlerini** kontrol eder
- Sonuçları Türkçe yapılandırılmış rapor olarak sunar

## Yapı

```
medgemma-skills/
├── CLAUDE.md                      ← Claude Code / Cowork talimatları
├── .cursorrules                   ← Cursor / Antigravity talimatları
├── medgemma_api.py                ← MedGemma API client (Modal endpoint)
├── sample-xrays.zip               ← Test görselleri (ZIP — 1.7 MB)
├── skills/
│   ├── radiology-skill.md         ← Tıbbi görüntü analizi
│   └── medical-assistant-skill.md ← Lab, ilaç, semptom
├── images/                        ← Kendi görsellerinizi buraya atın
│   └── temp/                      ← ZIP çıktı klasörü (otomatik oluşturulur)
│       └── {zip_adı}/             ← Her ZIP ayrı alt klasöre çıkar
├── reports/                       ← Analiz raporları (otomatik oluşturulur)
│   └── YYYY-MM-DD_analiz_rapor.md
└── sample-xrays/                  ← Hazır test görselleri
    ├── normal/                    ← 3 normal göğüs X-ray
    ├── pneumonia/                 ← 2 pnömoni X-ray
    └── temporal/                  ← 3 günlük progresyon serisi
```

## Hızlı Başlangıç

### Cursor / Antigravity / Claude Code

1. Repo'yu klonlayın:
   ```bash
   git clone https://github.com/burakcanpolat/medgemma-skills.git
   ```
2. IDE'nizde açın (Cursor, Antigravity, veya Claude Code)
3. AI asistana sorun:
   - *"sample-xrays klasöründeki normal X-ray'i analiz et"*
   - *"sample-xrays.zip dosyasını aç ve analiz et"*
   - *"images klasöründeki görselleri incele"*

AI asistan otomatik olarak `medgemma_api.py` üzerinden MedGemma'ya görüntü gönderir ve Türkçe formatlanmış rapor döndürür.

### Kendi Görsellerinizi Kullanma

1. Görsellerinizi `images/` klasörüne koyun (veya ZIP olarak atın)
2. AI asistana sorun: *"images klasöründekileri analiz et"*

### Manuel Kullanım (Terminal)

```bash
# Tek görüntü
python medgemma_api.py images/xray.jpeg

# Çoklu görüntü (karşılaştırmalı)
python medgemma_api.py images/day0.jpg images/day1.jpg images/day2.jpg

# ZIP dosyası (images/temp/sample-xrays/ klasörüne çıkar)
python medgemma_api.py sample-xrays.zip

# Büyük ZIP — script otomatik batch yapar, temsili dilimler seçer
python medgemma_api.py images/buyuk-seri.zip
```

> **Windows Encoding:** Türkçe karakter içeren dosya adları (ş, ğ, ü, ç, ö, ı) otomatik olarak desteklenir. Script UTF-8, cp1252 ve latin-1 arasında otomatik geçiş yapar.

## MedGemma Pipeline

```
Görüntü (JPEG/PNG/ZIP)
        ↓
medgemma_api.py
  ├── Tek görüntü → doğrudan API'ye gönder
  └── ZIP / Çok görüntü → Batch işleme
        ├── Temsili dilimleri seç (büyük serilerde)
        ├── Her alt klasörü ayrı seri olarak işle
        └── Batch 1 → Batch 2 → ... → Tüm sonuçlar
        ↓
Modal API (MedGemma 1.5 4B-it)
        ↓
Ham İngilizce analiz
        ↓
AI Asistan → Türkçe yapılandırılmış rapor
  ├── BULGULAR
  ├── İZLENİM
  ├── GÜVEN SEVİYESİ (🟢🟡🔴)
  ├── ÖNERİLER
  └── [Çok serili ise] SERİLER ARASI KARŞILAŞTIRMA
        ↓
reports/ klasörüne kaydet
```

### Büyük ZIP / Çok Serili Analiz

- ZIP içinde alt klasörler varsa, her klasör **ayrı bir hasta serisi** olarak analiz edilir
- Çok sayıda görsel içeren seriler için script **temsili dilimleri otomatik seçer**
- Tüm seriler analiz edildikten sonra AI **genel karşılaştırma bölümü** ekler

## Örnek Kullanım

### Radyoloji (Görüntü)
> "sample-xrays/temporal klasöründeki 3 görseli karşılaştır, progresyonu değerlendir"

### Tıbbi Asistan (Metin)
> "WBC: 12.500, Hb: 9.2, MCV: 68, Ferritin: 8 — bu değerleri yorumla"

> "Metformin 1000mg, Ramipril 5mg, Aspirin 100mg — etkileşim var mı?"

## Gereksinimler

- Python 3.8+ (ek paket gerekmez — sadece stdlib)
- İnternet bağlantısı (Modal API için)

## Sorumluluk Reddi

⚠️ Bu araçlar **eğitim ve bilgilendirme amaçlıdır**. Kesin tanı ve tedavi kararları için mutlaka uzman hekime başvurun. FDA onaylı bir tıbbi cihaz değildir.

## Lisans

MIT
