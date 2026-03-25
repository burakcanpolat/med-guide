@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo.
echo ================================================
echo   Med-Rehber — Kurulum Sihirbazi
echo ================================================
echo.

:: -------------------------------------------------------------------
:: ADIM 1: Python Kontrolu
:: -------------------------------------------------------------------
echo --- Adim 1/4: Python Kontrolu ---
echo.

set "PYTHON_CMD="

python --version >nul 2>&1
if %errorlevel%==0 (
    set "PYTHON_CMD=python"
    goto :python_found
)

python3 --version >nul 2>&1
if %errorlevel%==0 (
    set "PYTHON_CMD=python3"
    goto :python_found
)

echo [X] Python bulunamadi!
echo.
echo Python 3.8+ kurmaniz gerekiyor:
echo.
echo   1. Su adresi tarayicinizda acin:
echo      https://www.python.org/downloads/
echo.
echo   2. Buyuk sari "Download Python" butonuna tiklayin
echo.
echo   3. Indirilen dosyayi calistirin
echo.
echo   4. ONEMLI: "Add Python to PATH" kutucugunu MUTLAKA isaretleyin!
echo.
echo   5. "Install Now" tiklayin
echo.
echo Python kurduktan sonra bu scripti tekrar calistirin.
pause
exit /b 1

:python_found
for /f "tokens=2" %%v in ('%PYTHON_CMD% --version 2^>^&1') do set "PY_VER=%%v"
echo [OK] Python %PY_VER% kurulu.

:: -------------------------------------------------------------------
:: ADIM 2: .env Dosyasi
:: -------------------------------------------------------------------
echo.
echo --- Adim 2/4: Ayar Dosyasi (.env) ---
echo.

if exist .env (
    findstr /c:"MEDGEMMA_ENDPOINT" .env >nul 2>&1
    if %errorlevel%==0 (
        echo [OK] .env dosyasi zaten mevcut ve yapilandirilmis.
        goto :test_connection
    ) else (
        echo [!] .env dosyasi var ama MEDGEMMA_ENDPOINT ayari yok.
    )
)

echo Yapilandirma dosyasi olusturulacak.
echo.
echo Kendi MedGemma endpoint'iniz var mi? (e/h)
echo (Emin degilseniz 'h' yapin — varsayilan endpoint kullanilir)
set /p "HAS_ENDPOINT=Seciminiz: "

if /i "!HAS_ENDPOINT!"=="e" (
    echo.
    echo Endpoint URL'nizi girin:
    set /p "USER_ENDPOINT=URL: "
    (
        echo # Med-Rehber Ayarlari
        echo MEDGEMMA_ENDPOINT=!USER_ENDPOINT!
        echo MEDGEMMA_MODEL=google/medgemma-1.5-4b-it
    ) > .env
) else (
    (
        echo # Med-Rehber Ayarlari
        echo MEDGEMMA_ENDPOINT=https://burakcanpolat--medgemma-vllm-serve.modal.run/v1/chat/completions
        echo MEDGEMMA_MODEL=google/medgemma-1.5-4b-it
    ) > .env
)

echo [OK] .env dosyasi olusturuldu.

:: -------------------------------------------------------------------
:: ADIM 3: Baglanti Testi
:: -------------------------------------------------------------------
:test_connection
echo.
echo --- Adim 3/4: Baglanti Testi ---
echo.
echo MedGemma sunucusuna baglaniliyor... (10-30 saniye surebilir)
echo.

%PYTHON_CMD% scripts\medgemma_api.py test\sample-xrays\normal\normal-xray-1.jpeg >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Baglanti calisiyor! MedGemma yanit verdi.
) else (
    echo [!] Baglanti sirasinda bir sorun olustu.
    echo.
    echo   Muhtemel nedenler:
    echo   - Internet baglantinizi kontrol edin
    echo   - Sunucu uyku modunda olabilir, 30 saniye bekleyip tekrar deneyin
    echo   - .env dosyasindaki endpoint URL'sini kontrol edin
)

:: -------------------------------------------------------------------
:: ADIM 4: Tamamlandi
:: -------------------------------------------------------------------
echo.
echo --- Adim 4/4: Tamamlandi ---
echo.
echo ================================================
echo [OK] Med-Rehber kuruluma hazir!
echo ================================================
echo.
echo   Simdi ne yapabilirsiniz:
echo.
echo   1. Bir AI editorde acin (Zed, Cursor, Claude Code)
echo      ve AI asistanla sohbet edin.
echo.
echo   2. Terminal'den kullanin:
echo      %PYTHON_CMD% scripts\medgemma_api.py goruntu.jpg
echo.
echo   3. Test goruntuleriyle deneyin:
echo      %PYTHON_CMD% scripts\medgemma_api.py test\sample-xrays\normal\normal-xray-1.jpeg
echo.
echo   Detayli bilgi: README.md
echo.
pause
