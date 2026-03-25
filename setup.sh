#!/usr/bin/env bash
# Med-Rehber — Kurulum Scripti
# Hicbir teknik bilgi gerektirmez.

set -e

echo ""
echo "================================================"
echo "  Med-Rehber — Kurulum Sihirbazi"
echo "================================================"
echo ""

# Renk tanimlamalari (destekleyen terminaller icin)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# -------------------------------------------------------------------
# ADIM 1: Python Kontrolu
# -------------------------------------------------------------------
echo "━━━ Adim 1/4: Python Kontrolu ━━━"
echo ""

PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    PY_VER=$($PYTHON_CMD --version 2>&1 | grep -oP '\d+\.\d+')
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)

    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 8 ]; then
        ok "Python $($PYTHON_CMD --version 2>&1 | grep -oP '\d+\.\d+\.\d+') kurulu."
    else
        fail "Python $PY_VER bulundu ama 3.8+ gerekli."
        PYTHON_CMD=""
    fi
fi

if [ -z "$PYTHON_CMD" ]; then
    fail "Python bulunamadi!"
    echo ""
    echo "Python 3.8+ kurmaniz gerekiyor:"
    echo ""

    case "$(uname -s)" in
        Darwin*)
            echo "  brew install python3"
            echo ""
            echo "  Homebrew yoksa once:"
            echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            ;;
        Linux*)
            echo "  sudo apt update && sudo apt install python3 python3-pip -y"
            echo ""
            echo "  (Fedora: sudo dnf install python3 python3-pip -y)"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "  https://www.python.org/downloads/ adresinden indirin."
            echo "  ONEMLI: Kurulumda 'Add Python to PATH' kutucugunu isaretle!"
            ;;
    esac

    echo ""
    echo "Python kurduktan sonra bu scripti tekrar calistirin."
    exit 1
fi

# -------------------------------------------------------------------
# ADIM 2: .env Dosyasi
# -------------------------------------------------------------------
echo ""
echo "━━━ Adim 2/4: Ayar Dosyasi (.env) ━━━"
echo ""

if [ -f .env ]; then
    if grep -q "MEDGEMMA_ENDPOINT" .env 2>/dev/null; then
        ok ".env dosyasi zaten mevcut ve yapilandirilmis."
    else
        warn ".env dosyasi var ama MEDGEMMA_ENDPOINT ayari yok."
        echo ""
        echo "Varsayilan ayarlarla guncellensin mi? (e/h)"
        read -r ANSWER
        if [[ "$ANSWER" =~ ^[eEyY] ]]; then
            echo "MEDGEMMA_ENDPOINT=https://burakcanpolat--medgemma-vllm-serve.modal.run/v1/chat/completions" >> .env
            echo "MEDGEMMA_MODEL=google/medgemma-1.5-4b-it" >> .env
            ok ".env guncellendi."
        fi
    fi
else
    echo "Yapilandirma dosyasi olusturulacak."
    echo ""
    echo "Kendi MedGemma endpoint'iniz var mi? (e/h)"
    echo "(Emin degilseniz 'h' yapin — varsayilan endpoint kullanilir)"
    read -r HAS_ENDPOINT

    if [[ "$HAS_ENDPOINT" =~ ^[eEyY] ]]; then
        echo ""
        echo "Endpoint URL'nizi girin:"
        read -r USER_ENDPOINT
        cat > .env << ENVEOF
# Med-Rehber Ayarlari
MEDGEMMA_ENDPOINT=$USER_ENDPOINT
MEDGEMMA_MODEL=google/medgemma-1.5-4b-it
ENVEOF
    else
        cat > .env << 'ENVEOF'
# Med-Rehber Ayarlari
MEDGEMMA_ENDPOINT=https://burakcanpolat--medgemma-vllm-serve.modal.run/v1/chat/completions
MEDGEMMA_MODEL=google/medgemma-1.5-4b-it
ENVEOF
    fi

    ok ".env dosyasi olusturuldu."
fi

# -------------------------------------------------------------------
# ADIM 3: Baglanti Testi
# -------------------------------------------------------------------
echo ""
echo "━━━ Adim 3/4: Baglanti Testi ━━━"
echo ""
info "MedGemma sunucusuna baglaniliyor... (bu 10-30 saniye surebilir)"
echo ""

# .env'den degerleri yukle
export $(grep -v '^#' .env | xargs 2>/dev/null) 2>/dev/null || true

TEST_RESULT=$($PYTHON_CMD scripts/medgemma_api.py test/sample-xrays/normal/normal-xray-1.jpeg 2>&1) && TEST_OK=true || TEST_OK=false

if [ "$TEST_OK" = true ]; then
    ok "Baglanti calisiyor! MedGemma yanit verdi."
    echo ""
    echo "  Ornek cikti (ilk 200 karakter):"
    echo "  ${TEST_RESULT:0:200}..."
else
    warn "Baglanti sirasinda bir sorun olustu."
    echo ""
    echo "  Hata: ${TEST_RESULT:0:300}"
    echo ""
    echo "  Muhtemel nedenler:"
    echo "  - Internet baglantinizi kontrol edin"
    echo "  - Sunucu uyku modunda olabilir, 30 saniye bekleyip tekrar deneyin"
    echo "  - .env dosyasindaki endpoint URL'sini kontrol edin"
fi

# -------------------------------------------------------------------
# ADIM 4: Tamamlandi
# -------------------------------------------------------------------
echo ""
echo "━━━ Adim 4/4: Tamamlandi ━━━"
echo ""
echo "================================================"
ok "Med-Rehber kuruluma hazir!"
echo "================================================"
echo ""
echo "  Simdi ne yapabilirsiniz:"
echo ""
echo "  1. Bir AI editorde acin (Zed, Cursor, Claude Code)"
echo "     ve AI asistanla sohbet edin."
echo ""
echo "  2. Terminal'den kullanin:"
echo "     $PYTHON_CMD scripts/medgemma_api.py goruntu.jpg"
echo ""
echo "  3. Test goruntuleriyle deneyin:"
echo "     $PYTHON_CMD scripts/medgemma_api.py test/sample-xrays/normal/normal-xray-1.jpeg"
echo ""
echo "  Detayli bilgi: README.md"
echo ""
