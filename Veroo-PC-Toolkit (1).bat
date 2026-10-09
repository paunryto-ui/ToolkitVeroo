@echo off
setlocal EnableExtensions
title VEROO PC TOOLKIT
mode con: cols=86 lines=46

:: ==============================================================
::   VEROO PC TOOLKIT   -   Made by Veroo
::   Use it for : Clean - Boost - Protect your PC
::
::   Isi: Optimasi PC + Pembersih Virus + Cek File Aman
::   Satu file doang, gak butuh file .ps1 terpisah.
:: ==============================================================

:: ================= KONFIGURASI (edit di sini aja) =================
:: API key VirusTotal (opsional, gratis di virustotal.com). Kosong = skip cek otomatis.
set "VT_API_KEY="
:: QuickScan = cepet, FullScan = lama tapi menyeluruh
set "SCAN_TYPE=QuickScan"
:: 1 = otomatis matiin proses yang di-flag VT >= threshold, 0 = jangan
set "AUTO_KILL=0"
:: Minimal jumlah engine VT yang flag malicious sebelum dianggap bahaya
set "VT_THRESHOLD=3"
:: ==================================================================

set "SELF=%~f0"
set "ARG1=%~1"
set "REPDIR=%USERPROFILE%\VerooToolkit_Report"
set "PS_TMP=%TEMP%\veroo_scan.ps1"
set "DID_VIRUS=0"

:: ---------- Cek admin, kalau belum minta elevasi ----------
fltmc >nul 2>&1
if %errorlevel% equ 0 goto :sudah_admin
echo Minta izin Administrator, tunggu sebentar...
powershell -NoProfile -Command "Start-Process -FilePath $env:SELF -ArgumentList ('{0}{1}{0}' -f [char]34, $env:ARG1) -Verb RunAs"
exit /b

:sudah_admin
cd /d "%~dp0"

:: ---------- Siapin warna ANSI (Windows 10/11) ----------
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C_RS=%ESC%[0m"
set "C_DM=%ESC%[90m"
set "C_RD=%ESC%[91m"
set "C_GR=%ESC%[92m"
set "C_YE=%ESC%[93m"
set "C_BL=%ESC%[94m"
set "C_MG=%ESC%[95m"
set "C_CY=%ESC%[96m"
set "C_WH=%ESC%[97m"

:: ---------- Kalau ada file di-drag ke icon .bat ini, langsung cek ----------
if "%ARG1%"=="" goto :menu
set "CHK_FILE=%ARG1%"
cls
call :banner_small
call :cek_file
goto :menu

:: ==============================================================
::   MENU UTAMA
:: ==============================================================
:menu
set "DID_VIRUS=0"
cls
call :banner
echo.
echo   %C_DM%-------------------------------------------------------------------%C_RS%
echo.
echo    %C_CY%[1]%C_RS%  %C_WH%OPTIMASI PC%C_RS%      %C_DM%bersihin sampah, tweak performa, boost lag%C_RS%
echo    %C_CY%[2]%C_RS%  %C_WH%PEMBERSIH VIRUS%C_RS%  %C_DM%Defender + cek proses + VirusTotal%C_RS%
echo    %C_CY%[3]%C_RS%  %C_WH%CEK FILE AMAN%C_RS%    %C_DM%hash + Defender + VirusTotal, buat trojan/cheat%C_RS%
echo    %C_MG%[4]%C_RS%  %C_WH%PAKET LENGKAP%C_RS%    %C_DM%scan virus dulu, lanjut optimasi%C_RS% %C_YE%[rekomendasi]%C_RS%
echo    %C_CY%[5]%C_RS%  %C_WH%BUKA LAPORAN%C_RS%     %C_DM%laporan scan virus terakhir%C_RS%
echo    %C_RD%[0]%C_RS%  %C_WH%KELUAR%C_RS%
echo.
echo   %C_DM%-------------------------------------------------------------------%C_RS%
echo.
<nul set /p "=   %C_YE%Pilih menu %C_DM%[1-5, 0 = keluar]%C_YE% : %C_RS%"
choice /c 123450 /n >nul
if errorlevel 6 goto :bye
if errorlevel 5 goto :buka_laporan
if errorlevel 4 goto :paket_lengkap
if errorlevel 3 goto :menu_cek_file
if errorlevel 2 goto :menu_virus
if errorlevel 1 goto :menu_optimasi
goto :menu

:menu_optimasi
cls
call :banner_small
call :do_optimize
goto :akhir_tugas

:menu_virus
cls
call :banner_small
call :do_virus
goto :akhir_tugas

:paket_lengkap
cls
call :banner_small
call :do_virus
call :do_optimize
goto :akhir_tugas

:menu_cek_file
cls
call :banner_small
echo.
echo   %C_CY%CEK FILE AMAN%C_RS%  %C_DM%trojan dan cheat detector%C_RS%
echo   Seret ^(drag and drop^) file ke jendela ini, lalu tekan Enter.
echo.
set "CHK_FILE="
set /p "CHK_FILE=  File > "
call :cek_file
goto :menu

:buka_laporan
if not exist "%REPDIR%\LatestReport.txt" goto :laporan_kosong
set "REPORT_PATH="
set /p REPORT_PATH=<"%REPDIR%\LatestReport.txt"
if not exist "%REPORT_PATH%" goto :laporan_kosong
start "" "%REPORT_PATH%"
goto :menu

:laporan_kosong
echo.
echo   %C_YE%Belum ada laporan. Jalanin menu 2 atau 4 dulu ya.%C_RS%
echo.
pause
goto :menu

:bye
cls
echo.
echo   %C_CY%Makasih udah pake%C_RS% %C_WH%VEROO PC TOOLKIT%C_RS%
echo   %C_DM%Made by Veroo  -  Clean - Boost - Protect%C_RS%
echo.
timeout /t 2 /nobreak >nul
exit /b 0

:: ==============================================================
::   AKHIR TUGAS  (tawarin restart)
:: ==============================================================
:akhir_tugas
echo.
echo   %C_GR%================================================================%C_RS%
echo   %C_GR%  SELESAI%C_RS%   %C_WH%Semua tugas beres. Mantap.%C_RS%
echo   %C_GR%================================================================%C_RS%
echo.
<nul set /p "=   %C_YE%Restart PC sekarang biar perubahan aktif penuh? %C_DM%[Y/N]%C_YE% : %C_RS%"
choice /c YN /n >nul
if errorlevel 2 goto :tanpa_restart
if "%DID_VIRUS%"=="1" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v BukaLaporanVeroo /t REG_SZ /d "\"%REPORT_PATH%\"" /f >nul 2>&1
echo.
echo   PC restart dalam 15 detik... mau batalin? Buka CMD lain, ketik: shutdown /a
shutdown /r /t 15 /c "Veroo PC Toolkit: restart buat nerapin perubahan"
timeout /t 3 /nobreak >nul
exit /b 0

:tanpa_restart
echo.
echo   Oke, gak jadi restart. Sebagian tweak baru aktif setelah restart manual.
if "%DID_VIRUS%"=="1" start "" "%REPORT_PATH%"
echo.
pause
goto :menu

:: ==============================================================
::   BANNER
:: ==============================================================
:banner
echo.
echo   %C_CY%#   #  #####  ####    ###    ### %C_RS%
echo   %C_CY%#   #  #      #   #  #   #  #   #%C_RS%
echo   %C_BL%#   #  ####   ####   #   #  #   #%C_RS%
echo   %C_BL% # #   #      #  #   #   #  #   #%C_RS%
echo   %C_MG%  #    #####  #   #   ###    ### %C_RS%
echo.
echo   %C_WH%P C   T O O L K I T%C_RS%   %C_DM%v1.0  -  Optimizer + Virus Cleaner + File Checker%C_RS%
echo   %C_DM%-------------------------------------------------------------------%C_RS%
echo   %C_YE%Use it for%C_RS% : %C_GR%Clean%C_RS%  -  %C_CY%Boost%C_RS%  -  %C_MG%Protect%C_RS% your PC
echo   %C_DM%Made by%C_RS% %C_WH%Veroo%C_RS%
exit /b

:banner_small
echo.
echo   %C_CY%VEROO PC TOOLKIT%C_RS%  %C_DM%-  Made by Veroo  -  Clean / Boost / Protect%C_RS%
echo   %C_DM%-------------------------------------------------------------------%C_RS%
exit /b

:: ==============================================================
::   HELPER TAMPILAN
:: ==============================================================
:step
set "T=%~2 ........................................"
<nul set /p "=   %C_CY%[%~1/13]%C_RS% %T:~0,40% "
exit /b

:ok
echo %C_GR%OK%C_RS%
exit /b

:skip
echo %C_YE%skip%C_RS%
exit /b

:get_free
set "%~1=0"
for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive $env:SystemDrive[0]).Free/1MB)"') do set "%~1=%%a"
exit /b

:: ==============================================================
::   1. OPTIMASI PC  (13 langkah)
:: ==============================================================
:do_optimize
echo.
echo   %C_MG%=== OPTIMASI PC ===%C_RS%
echo.
call :get_free FREE_BEFORE
<nul set /p "=   %C_YE%Jalanin SFC, cek file sistem yg lama 5-15 menit? Auto YA dalam 10 detik %C_DM%[Y/N]%C_YE% : %C_RS%"
set "RUN_SFC=1"
choice /c YN /t 10 /d Y /n >nul
if errorlevel 2 set "RUN_SFC=0"
echo.
echo.

call :step 01 "Flush DNS cache"
ipconfig /flushdns >nul 2>&1
call :ok

call :step 02 "Bersihin file temporary"
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1
call :ok

call :step 03 "Kosongin Recycle Bin"
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
call :ok

call :step 04 "Bersihin cache Windows Update"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*.*" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
call :ok

call :step 05 "Disk Cleanup otomatis"
cleanmgr /verylowdisk >nul 2>&1
call :ok

call :step 06 "Power plan High Performance"
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1 && call :ok || call :skip

call :step 07 "Cek file sistem SFC"
if "%RUN_SFC%"=="0" goto :sfc_lewat
echo %C_YE%jalan, sabar ya...%C_RS%
echo.
sfc /scannow
echo.
goto :sfc_beres
:sfc_lewat
call :skip
:sfc_beres

call :step 08 "Optimasi drive %SystemDrive% (TRIM/defrag)"
defrag %SystemDrive% /O >nul 2>&1
call :ok

call :step 09 "Segarin Explorer + icon cache"
taskkill /f /im explorer.exe >nul 2>&1
del /a /q "%localappdata%\IconCache.db" >nul 2>&1
start explorer.exe
call :ok

call :step 10 "Visual effects mode performa"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1 && call :ok || call :skip

call :step 11 "Percepat delay startup"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1 && call :ok || call :skip

call :step 12 "Prioritas aplikasi aktif"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul 2>&1 && call :ok || call :skip

call :step 13 "Kurangi network throttling"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1 && call :ok || call :skip

call :get_free FREE_AFTER
set /a FREED=FREE_AFTER-FREE_BEFORE 2>nul
echo.
echo   %C_GR%Optimasi selesai.%C_RS% Ruang kosong %SystemDrive% sekarang: %C_WH%%FREE_AFTER% MB%C_RS%
if %FREED% GTR 0 echo   %C_GR%Ruang yang berhasil dibebasin: %FREED% MB%C_RS%
exit /b

:: ==============================================================
::   2. PEMBERSIH VIRUS  (script PowerShell ada di bawah file ini)
:: ==============================================================
:do_virus
echo.
echo   %C_MG%=== PEMBERSIH VIRUS ===%C_RS%
echo   %C_DM%Update + scan Defender, cek proses mencurigakan, reputasi VirusTotal%C_RS%
echo.
if exist "%REPDIR%\LatestReport.txt" del /q "%REPDIR%\LatestReport.txt" >nul 2>&1
powershell -NoProfile -Command "$c=[IO.File]::ReadAllText($env:SELF); $i=$c.IndexOf('#__PS'+'CODE__'); if ($i -lt 0) { exit 1 }; [IO.File]::WriteAllText($env:PS_TMP, $c.Substring($i))"
if errorlevel 1 goto :virus_gagal
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_TMP%"
del /q "%PS_TMP%" >nul 2>&1
if not exist "%REPDIR%\LatestReport.txt" goto :virus_gagal
set "DID_VIRUS=1"
set "REPORT_PATH="
set /p REPORT_PATH=<"%REPDIR%\LatestReport.txt"
echo.
echo   %C_GR%Scan selesai.%C_RS% Laporan: %C_WH%%REPORT_PATH%%C_RS%
exit /b

:virus_gagal
del /q "%PS_TMP%" >nul 2>&1
echo.
echo   %C_RD%[X] Scan gagal atau laporan gak kebentuk. Cek folder: %REPDIR%%C_RS%
exit /b

:: ==============================================================
::   3. CEK FILE AMAN  (trojan dan cheat detector)
:: ==============================================================
:cek_file
if not defined CHK_FILE goto :cek_kosong
set "CHK_FILE=%CHK_FILE:"=%"
if exist "%CHK_FILE%\" goto :cek_folder
if not exist "%CHK_FILE%" goto :cek_hilang

for %%F in ("%CHK_FILE%") do set "FNAME=%%~nxF"
for %%F in ("%CHK_FILE%") do set "FSIZE=%%~zF"

echo.
echo   %C_DM%File  %C_RS%: %C_WH%%FNAME%%C_RS%
echo   %C_DM%Path  %C_RS%: %CHK_FILE%
echo   %C_DM%Ukuran%C_RS%: %FSIZE% bytes
echo.

echo   %C_CY%[1/3]%C_RS% Ngitung hash SHA256...
set "HASH="
for /f "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%CHK_FILE%" SHA256 ^| findstr /v "CertUtil"') do if not defined HASH set "HASH=%%H"
if defined HASH set "HASH=%HASH: =%"
echo         %C_DM%%HASH%%C_RS%
echo.

echo   %C_CY%[2/3]%C_RS% Scan pake Windows Defender...
powershell -NoProfile -Command "try { Start-MpScan -ScanType CustomScan -ScanPath $env:CHK_FILE -ErrorAction Stop } catch { exit 9 }; $p = $env:CHK_FILE.ToLower(); $d = Get-MpThreatDetection | Where-Object { ((@($_.Resources) -join ' ').ToLower()).Contains($p) }; if ($d) { exit 2 } else { exit 0 }"
set "AVRES=%errorlevel%"
if "%AVRES%"=="0" echo         %C_GR%[ AMAN ]%C_RS% Defender gak nemu ancaman di file ini.
if "%AVRES%"=="2" echo         %C_RD%[ BAHAYA ]%C_RS% Defender NEMU ANCAMAN. Jangan dijalanin, hapus filenya.
if "%AVRES%"=="9" echo         %C_YE%[ ? ]%C_RS% Defender gagal scan otomatis. Scan manual: klik kanan file, Scan with Microsoft Defender.
echo.

echo   %C_CY%[3/3]%C_RS% Cek reputasi VirusTotal ^(60+ antivirus engine^)...
if not defined HASH goto :cek_vt_manual
if defined VT_API_KEY powershell -NoProfile -Command "try { $r = Invoke-RestMethod -Uri ('https://www.virustotal.com/api/v3/files/' + $env:HASH) -Headers @{ 'x-apikey' = $env:VT_API_KEY } -ErrorAction Stop; $s = $r.data.attributes.last_analysis_stats; $t = $s.malicious + $s.suspicious + $s.undetected + $s.harmless; Write-Host ('        VirusTotal: ' + $s.malicious + ' dari ' + $t + ' engine nge-flag malicious') } catch { Write-Host '        VirusTotal: hash gak ketemu di database (atau gak ada internet)' }"
start "" "https://www.virustotal.com/gui/file/%HASH%"
echo         Halaman VirusTotal kebuka di browser.
goto :cek_vt_info

:cek_vt_manual
echo         %C_YE%Gagal dapetin hash. Upload manual filenya di https://www.virustotal.com%C_RS%

:cek_vt_info
echo.
echo   %C_DM%Cara baca hasil VirusTotal:%C_RS%
echo     - 0-2 engine nge-flag : biasanya false positive, wajar buat cheat / mod tool
echo     - 5+ engine besar nge-flag ^(Microsoft, Kaspersky, BitDefender, ESET^) : kemungkinan besar trojan / RAT, JANGAN dijalanin
echo     - VT bilang "not found" : hash belum pernah discan, upload manual filenya ^(max 650MB^)
goto :cek_selesai

:cek_kosong
echo.
echo   %C_YE%Gak ada file yang dimasukin.%C_RS%
goto :cek_selesai

:cek_hilang
echo.
echo   %C_RD%[X] File gak ketemu: %CHK_FILE%%C_RS%
goto :cek_selesai

:cek_folder
echo.
echo   %C_YE%Itu folder, bukan file. Pilih file spesifik ^(.exe, .dll, .zip, dll^).%C_RS%

:cek_selesai
echo.
pause
exit /b

:: ==============================================================
::   Akhir bagian batch. Semua di bawah ini BUKAN batch.
:: ==============================================================
exit

#__PSCODE__
$ErrorActionPreference = 'SilentlyContinue'

# ================== CONFIG (diambil dari bagian atas file .bat) ==================
$VT_API_KEY             = "$env:VT_API_KEY".Trim()
$SCAN_TYPE              = if ($env:SCAN_TYPE) { $env:SCAN_TYPE } else { 'QuickScan' }
$AUTO_KILL_MALICIOUS    = ($env:AUTO_KILL -eq '1')
$VT_MALICIOUS_THRESHOLD = if ($env:VT_THRESHOLD) { [int]$env:VT_THRESHOLD } else { 3 }
$SAFE_PATH_WHITELIST    = @(
    "$env:WINDIR",
    "$env:ProgramFiles",
    "${env:ProgramFiles(x86)}",
    "$env:ProgramData\Microsoft"
)
# ================================================================================

$ts         = Get-Date -Format "yyyyMMdd_HHmmss"
$reportDir  = "$env:USERPROFILE\VerooToolkit_Report"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$reportPath = "$reportDir\Laporan_$ts.html"
$logPath    = "$reportDir\log_$ts.txt"

function Log($msg, $color = 'Gray') {
    $t = Get-Date -Format "HH:mm:ss"
    Write-Host "  [$t] " -NoNewline -ForegroundColor DarkGray
    Write-Host $msg -ForegroundColor $color
    Add-Content -Path $logPath -Value "[$t] $msg"
}

function HtmlEnc($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }

Log "Mulai Pembersih Virus PC" 'Cyan'

# ---------- STEP 1: Update dan scan Windows Defender ----------
Log "Update signature Windows Defender..." 'Cyan'
Update-MpSignature

Log "Jalanin $SCAN_TYPE Windows Defender... (sabar, bisa agak lama)" 'Cyan'
Start-MpScan -ScanType $SCAN_TYPE

Log "Ambil histori ancaman yang kedeteksi Defender..." 'Cyan'
$threatSummary = Get-MpThreat | Select-Object -Property ThreatName, SeverityID

# ---------- STEP 2: Cek semua proses yang lagi jalan ----------
Log "Ngecek semua proses yang lagi jalan..." 'Cyan'
$processes  = Get-Process | Where-Object { $_.Path } | Select-Object Id, ProcessName, Path
$suspicious = @()

foreach ($p in $processes) {
    $isWhitelisted = $false
    foreach ($safe in $SAFE_PATH_WHITELIST) {
        if ($safe -and $p.Path -like "$safe*") { $isWhitelisted = $true; break }
    }
    if ($isWhitelisted) { continue }

    $sig           = Get-AuthenticodeSignature -FilePath $p.Path
    $isSigned      = ($sig.Status -eq 'Valid')
    $inTempAppData = $p.Path -match '\\Temp\\|\\AppData\\Local\\Temp\\|\\Downloads\\'

    if (-not $isSigned -or $inTempAppData) {
        $hash = (Get-FileHash -Path $p.Path -Algorithm SHA256).Hash
        $suspicious += [PSCustomObject]@{
            PID          = $p.Id
            Nama         = $p.ProcessName
            Path         = $p.Path
            Signed       = $isSigned
            SHA256       = $hash
            VT_Malicious = "N/A"
            VT_Total     = "N/A"
            VT_Link      = ""
        }
    }
}
Log "Ketemu $($suspicious.Count) proses yang perlu dicurigai." 'Yellow'

# ---------- STEP 3: Cek reputasi ke VirusTotal (kalau API key diisi) ----------
if ($VT_API_KEY -ne "") {
    Log "Cek reputasi hash ke VirusTotal... (jeda 16 detik per hash, limit API gratis)" 'Cyan'
    foreach ($s in $suspicious) {
        if (-not $s.SHA256) { continue }
        try {
            $headers = @{ "x-apikey" = $VT_API_KEY }
            $resp  = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/files/$($s.SHA256)" -Headers $headers -Method Get -ErrorAction Stop
            $stats = $resp.data.attributes.last_analysis_stats
            $s.VT_Malicious = $stats.malicious
            $s.VT_Total     = ($stats.malicious + $stats.undetected + $stats.suspicious + $stats.harmless)
            $s.VT_Link      = "https://www.virustotal.com/gui/file/$($s.SHA256)"
        } catch {
            $s.VT_Malicious = "Belum ada di VT"
        }
        Start-Sleep -Seconds 16
    }
} else {
    Log "VT_API_KEY kosong, skip cek VirusTotal (opsional, isi di bagian atas file .bat)." 'DarkYellow'
}

# ---------- STEP 4: Auto-kill (kalau diaktifin) ----------
if ($AUTO_KILL_MALICIOUS) {
    foreach ($s in $suspicious) {
        if (($s.VT_Malicious -as [int]) -ge $VT_MALICIOUS_THRESHOLD) {
            Log "MATIIN proses berbahaya: $($s.Nama) (PID $($s.PID)) - $($s.VT_Malicious) engine flag malicious" 'Red'
            Stop-Process -Id $s.PID -Force
        }
    }
}

# ---------- STEP 5: Bikin laporan HTML ----------
$dangerCount = @($suspicious | Where-Object { ($_.VT_Malicious -as [int]) -ge $VT_MALICIOUS_THRESHOLD }).Count

$threatRows = ($threatSummary | ForEach-Object {
    "<tr><td>$(HtmlEnc $_.ThreatName)</td><td>$($_.SeverityID)</td></tr>"
}) -join "`n"
if (-not $threatRows) { $threatRows = "<tr><td colspan='2'>Gak ada histori ancaman dari Windows Defender &#127881;</td></tr>" }

$rows = ($suspicious | ForEach-Object {
    $level = "info"
    if (($_.VT_Malicious -as [int]) -ge $VT_MALICIOUS_THRESHOLD) { $level = "danger" }
    elseif (-not $_.Signed) { $level = "warn" }
    $vtLinkHtml = if ($_.VT_Link) { "<a href='$($_.VT_Link)' target='_blank'>Cek di VT</a>" } else { "-" }
    "<tr class='$level'><td>$($_.PID)</td><td>$(HtmlEnc $_.Nama)</td><td class='pathcell'>$(HtmlEnc $_.Path)</td><td>$($_.Signed)</td><td>$($_.VT_Malicious)/$($_.VT_Total)</td><td>$vtLinkHtml</td></tr>"
}) -join "`n"
if (-not $rows) { $rows = "<tr><td colspan='6'>Gak ada proses mencurigakan yang ketemu &#127881;</td></tr>" }

$html = @"
<!DOCTYPE html>
<html lang='id'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>Laporan Veroo PC Toolkit - $ts</title>
<style>
  body{font-family:'Segoe UI',Arial,sans-serif;background:#0b0e14;color:#e6e6e6;margin:0;padding:32px;}
  .wrap{max-width:1100px;margin:0 auto;}
  .hero{background:linear-gradient(135deg,#0ea5e9,#8b5cf6);padding:28px 32px;border-radius:14px;}
  .hero h1{margin:0;color:#fff;font-size:26px;letter-spacing:1px;}
  .hero p{margin:6px 0 0;color:#eaf6ff;font-size:14px;}
  .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px;margin:20px 0;}
  .card{background:#151a24;border:1px solid #232a38;border-radius:12px;padding:16px;}
  .card .k{color:#8a94a6;font-size:12px;text-transform:uppercase;letter-spacing:.5px;}
  .card .v{font-size:26px;font-weight:700;margin-top:6px;color:#4dd2ff;}
  .card .v.bad{color:#ff6b6b;}
  h2{color:#4dd2ff;border-bottom:1px solid #2a3140;padding-bottom:6px;margin-top:34px;}
  table{width:100%;border-collapse:collapse;margin:12px 0;}
  th,td{border:1px solid #2a3140;padding:9px;text-align:left;font-size:13px;}
  th{background:#1b2130;}
  tr.danger{background:#3a1414;} tr.warn{background:#3a2e14;} tr.info{background:transparent;}
  .pathcell{font-size:11px;word-break:break-all;color:#aab;}
  a{color:#4dd2ff;}
  .note{color:#8a94a6;font-size:12px;margin-top:26px;line-height:1.7;}
  .foot{text-align:center;color:#6b7488;font-size:12px;margin-top:34px;}
</style>
</head>
<body>
<div class='wrap'>
<div class='hero'>
  <h1>VEROO PC TOOLKIT &nbsp;-&nbsp; Laporan Scan</h1>
  <p>Use it for: Clean &middot; Boost &middot; Protect your PC</p>
</div>

<div class='cards'>
  <div class='card'><div class='k'>Waktu scan</div><div class='v' style='font-size:16px'>$ts</div></div>
  <div class='card'><div class='k'>Mode Defender</div><div class='v' style='font-size:18px'>$SCAN_TYPE</div></div>
  <div class='card'><div class='k'>Proses dicek</div><div class='v'>$($processes.Count)</div></div>
  <div class='card'><div class='k'>Proses dicurigai</div><div class='v'>$($suspicious.Count)</div></div>
  <div class='card'><div class='k'>Bahaya (VT)</div><div class='v bad'>$dangerCount</div></div>
  <div class='card'><div class='k'>Auto-kill</div><div class='v' style='font-size:18px'>$AUTO_KILL_MALICIOUS</div></div>
</div>

<h2>Histori Ancaman dari Windows Defender</h2>
<table><tr><th>Nama Ancaman</th><th>Severity</th></tr>$threatRows</table>

<h2>Proses Mencurigakan yang Lagi Jalan</h2>
<table>
<tr><th>PID</th><th>Nama</th><th>Path</th><th>Signed?</th><th>VT Malicious/Total</th><th>Link</th></tr>
$rows
</table>

<p class='note'>
Catatan: laporan ini gabungan Windows Defender + cek path/signature proses + VirusTotal (kalau API key diisi).
Ini bukan pengganti antivirus penuh. Kalau ada proses yang lu gak kenal dan hasil VT-nya merah (banyak engine flag malicious),
matiin manual prosesnya terus uninstall/hapus programnya. Merah di tabel = wajib dicek, kuning = gak ke-sign
(belum tentu jahat, banyak tool legit juga gak di-sign).
</p>
<div class='foot'>Made by Veroo</div>
</div>
</body>
</html>
"@

Set-Content -Path $reportPath -Value $html -Encoding UTF8
Set-Content -Path "$reportDir\LatestReport.txt" -Value $reportPath -Encoding ASCII

Log "Laporan tersimpan di: $reportPath" 'Green'
Log "Selesai" 'Green'
