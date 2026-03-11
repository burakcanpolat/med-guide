"""
MedGemma API Client — Unified
Modal üzerinde deploy edilmiş MedGemma modeline görüntü gönderir.
ZIP smart-routing, series detection, batch processing ve JSON rapor kaydını içerir.
"""

import base64
import json
import sys
import zipfile
import urllib.request
import ssl
import datetime
from pathlib import Path

# Windows'ta UTF-8 çıktı için
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ENDPOINT = "https://burakcanpolat--medgemma-vllm-serve.modal.run/v1/chat/completions"
MODEL = "google/medgemma-1.5-4b-it"
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif"}

BATCH_SIZE = 5          # batch modunda grup başına görüntü sayısı
SERIES_SAMPLE = 3       # series modunda seri başına temsili görüntü sayısı
ZIP_SMALL = 5           # bu değerin altındaki ZIP → tek istek (analyze_multiple)
ZIP_LARGE = 20          # bu değerin üzerindeki ZIP → series detection moduna geç


# ---------------------------------------------------------------------------
# SSL context (shared)
# ---------------------------------------------------------------------------

def _ssl_ctx() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def analyze_image(image_path: str | Path,
                  prompt: str = "Analyze this medical image. Provide detailed findings.") -> str:
    """Tek bir görüntüyü MedGemma ile analiz eder."""
    path = Path(image_path)
    if not path.exists():
        return f"HATA: Dosya bulunamadi: {image_path}"

    mime = "image/jpeg" if path.suffix.lower() in (".jpg", ".jpeg") else "image/png"
    b64 = base64.b64encode(path.read_bytes()).decode()

    payload = json.dumps({
        "model": MODEL,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}}
        ]}],
        "max_tokens": 1024,
        "temperature": 0,
    }).encode()

    req = urllib.request.Request(
        ENDPOINT, data=payload,
        headers={"Content-Type": "application/json"}, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=300, context=_ssl_ctx()) as resp:
            result = json.loads(resp.read().decode())
            return result["choices"][0]["message"]["content"]
    except Exception as e:
        return f"HATA: MedGemma API hatasi: {e}"


def analyze_multiple(image_paths: list[str | Path],
                     prompt: str = "Compare these medical images. Analyze progression.") -> str:
    """Birden fazla görüntüyü tek istekte MedGemma'ya gönderir."""
    content: list[dict] = [{"type": "text", "text": prompt}]

    for p in image_paths:
        path = Path(p)
        if not path.exists():
            return f"HATA: Dosya bulunamadi: {p}"
        mime = "image/jpeg" if path.suffix.lower() in (".jpg", ".jpeg") else "image/png"
        b64 = base64.b64encode(path.read_bytes()).decode()
        content.append({"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}})

    payload = json.dumps({
        "model": MODEL,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": 1024,
        "temperature": 0,
    }).encode()

    req = urllib.request.Request(
        ENDPOINT, data=payload,
        headers={"Content-Type": "application/json"}, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=300, context=_ssl_ctx()) as resp:
            result = json.loads(resp.read().decode())
            return result["choices"][0]["message"]["content"]
    except Exception as e:
        return f"HATA: MedGemma API hatasi: {e}"


# ---------------------------------------------------------------------------
# ZIP extraction
# ---------------------------------------------------------------------------

def extract_zip(zip_path: str | Path) -> tuple[list[Path], Path]:
    """
    ZIP dosyasini images/temp/{zip_name}/ altina cikarır.
    Dondurulenler: (sorted_image_paths, extraction_root)
    """
    zip_path = Path(zip_path)
    out = Path("images") / "temp" / zip_path.stem
    out.mkdir(parents=True, exist_ok=True)

    extracted: list[Path] = []
    with zipfile.ZipFile(zip_path, "r") as zf:
        for name in zf.namelist():
            if Path(name).suffix.lower() in IMAGE_EXTENSIONS and not name.startswith("__MACOSX"):
                zf.extract(name, out)
                extracted.append(out / name)

    extracted.sort()
    print(f"[ZIP] {len(extracted)} goruntu cikartialdi → {out}")
    return extracted, out


# ---------------------------------------------------------------------------
# Series detection
# ---------------------------------------------------------------------------

def detect_series(image_paths: list[Path], extraction_root: Path) -> dict[str, list[Path]]:
    """
    Görüntüleri seriye göre gruplar.
    - Altklasörler varsa: her altklasör = bir seri
    - Altklasör yoksa: dosya adındaki sayısal prefikse göre bölme yapılır,
      aksi halde tüm dosyalar tek seri kabul edilir.
    """
    # Alt klasör tespiti
    subdirs: dict[str, list[Path]] = {}
    for p in image_paths:
        rel = p.relative_to(extraction_root)
        parts = rel.parts
        if len(parts) > 1:
            series_name = parts[0]
            subdirs.setdefault(series_name, []).append(p)

    if subdirs:
        # Her alt klasörü sıralı tut
        return {k: sorted(v) for k, v in subdirs.items()}

    # Alt klasör yok → sayısal prefix ile böl
    groups: dict[str, list[Path]] = {}
    for p in image_paths:
        # Örnek: "0001_img.jpg" → prefix "0001"
        stem = p.stem
        prefix = ""
        for ch in stem:
            if ch.isdigit():
                prefix += ch
            else:
                break
        key = prefix if prefix else "default"
        groups.setdefault(key, []).append(p)

    if len(groups) == 1:
        return groups  # zaten tek grup

    return {k: sorted(v) for k, v in groups.items()}


def get_representative_images(images: list[Path], n: int = SERIES_SAMPLE) -> list[Path]:
    """Bir listeden ilk, orta ve son görüntüleri seçer."""
    if not images:
        return []
    if len(images) <= n:
        return images
    indices = [0, len(images) // 2, len(images) - 1]
    return [images[i] for i in indices[:n]]


# ---------------------------------------------------------------------------
# Report saving
# ---------------------------------------------------------------------------

def save_report(data: dict, label: str = "report") -> Path:
    """Sonuçları reports/ altına zaman damgalı JSON olarak kaydeder."""
    reports_dir = Path("reports")
    reports_dir.mkdir(exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    out = reports_dir / f"{label}_{ts}.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[RAPOR] Kaydedildi: {out}")
    return out


# ---------------------------------------------------------------------------
# Smart ZIP dispatcher
# ---------------------------------------------------------------------------

def process_zip(zip_path: str | Path) -> dict:
    """
    ZIP büyüklüğüne göre analiz stratejisi seçer:
      < ZIP_SMALL images  → analyze_multiple (tek istek)
      ZIP_SMALL–ZIP_LARGE → batch: BATCH_SIZE'lık gruplar
      > ZIP_LARGE images  → series detection, her seriden SERIES_SAMPLE temsili görüntü
    """
    images, extraction_root = extract_zip(zip_path)
    total = len(images)
    results: dict = {}

    if total == 0:
        print("HATA: ZIP icinde goruntu dosyasi bulunamadi.")
        return results

    zip_label = Path(zip_path).stem

    # ── KUCUK: tek istek ────────────────────────────────────────────────────
    if total < ZIP_SMALL:
        print(f"[MOD] Kucuk ZIP ({total} goruntu) → tek istek")
        prompt = (
            "These are medical images. Compare and describe each image's modality, "
            "body region, and notable findings. Be clinical and concise."
        )
        print(f"  Gonderiliyor: {[p.name for p in images]}")
        answer = analyze_multiple(images, prompt)
        results["mode"] = "single_request"
        results["images"] = [str(p) for p in images]
        results["analysis"] = answer
        save_report(results, label=zip_label)
        print(answer)
        return results

    # ── ORTA: batch ────────────────────────────────────────────────────────
    if total <= ZIP_LARGE:
        print(f"[MOD] Orta ZIP ({total} goruntu) → batch ({BATCH_SIZE}'li gruplar)")
        results["mode"] = "batch"
        results["batches"] = []
        batches = [images[i:i + BATCH_SIZE] for i in range(0, total, BATCH_SIZE)]
        for idx, batch in enumerate(batches, 1):
            print(f"\n[BATCH {idx}/{len(batches)}] {[p.name for p in batch]}")
            prompt = (
                "These are consecutive medical imaging slices. "
                "Describe the imaging modality, body region, and key findings. Be concise."
            )
            answer = analyze_multiple(batch, prompt)
            print(f"  → {answer[:160]}...")
            results["batches"].append({
                "batch": idx,
                "images": [str(p) for p in batch],
                "analysis": answer,
            })
        save_report(results, label=zip_label)
        return results

    # ── BUYUK: series detection ─────────────────────────────────────────────
    print(f"[MOD] Buyuk ZIP ({total} goruntu) → series detection")
    series_map = detect_series(images, extraction_root)
    print(f"[SERİLER] {len(series_map)} seri tespit edildi: {list(series_map.keys())}")
    results["mode"] = "series"
    results["series"] = {}

    for series_name, series_images in series_map.items():
        reps = get_representative_images(series_images)
        total_in_series = len(series_images)
        print(f"\n=== {series_name} ({total_in_series} kesit, {len(reps)} temsilci) ===")
        series_results = []

        for img in reps:
            print(f"  Analiz: {img.name} ...", flush=True)
            prompt = (
                "This is a medical imaging scan. "
                "Describe the imaging modality (CT, MRI, X-ray, ultrasound, etc.), "
                "the body region shown, and any notable findings. "
                "Be concise and clinical."
            )
            answer = analyze_image(img, prompt)
            print(f"  → {answer[:120]}...")
            series_results.append({"image": img.name, "analysis": answer})

        results["series"][series_name] = {
            "total_images": total_in_series,
            "representative_images": [str(r) for r in reps],
            "analyses": series_results,
        }

    save_report(results, label=zip_label)
    return results


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Kullanim:")
        print("  python medgemma_api.py goruntu.jpeg")
        print("  python medgemma_api.py goruntu1.jpg goruntu2.jpg goruntu3.jpg")
        print("  python medgemma_api.py gorseller.zip")
        sys.exit(1)

    input_path = sys.argv[1]

    if input_path.lower().endswith(".zip"):
        process_zip(input_path)

    else:
        paths = sys.argv[1:]
        if len(paths) == 1:
            print(f"[TEK GORUNTU] {paths[0]}")
            result = analyze_image(paths[0])
            print(result)
            # Raporu kaydet
            save_report({"mode": "single", "image": paths[0], "analysis": result},
                        label=Path(paths[0]).stem)
        else:
            print(f"[COKLU GORUNTU] {len(paths)} dosya")
            result = analyze_multiple(paths)
            print(result)
            save_report({"mode": "multiple", "images": paths, "analysis": result},
                        label="multi_image")
