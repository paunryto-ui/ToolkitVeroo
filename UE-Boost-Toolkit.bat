@echo off
setlocal EnableExtensions EnableDelayedExpansion
title UE Boost Toolkit
color 0B

rem ============ SETTING (boleh diedit) ============
rem App musik yang dijaga biar ga patah-patah (priority Above Normal)
set "MUSIC_APPS=Spotify.exe musicbee.exe vlc.exe foobar2000.exe Music.UI.exe AIMP.exe"
rem App yang ditutup pas boost biar CPU dan RAM lega
set "KILL_APPS=ms-teams.exe Teams.exe Widgets.exe PhoneExperienceHost.exe"
rem 1 = pause sync OneDrive selama boost, 0 = jangan (project udah dipindah ke D:, jadi default 0)
set "PAUSE_ONEDRIVE=0"
rem Folder project buat exclusion Defender
set "PROJECT_DIR=D:\Unreal Projects\DEFINITIVEFPSKIT"
rem Versi Unreal Engine yang dibutuhin project ini (dari halaman Fab)
set "NEEDED_ENGINE=5.5"
rem ================================================

set "STATE_DIR=%LOCALAPPDATA%\UEBoost"
set "IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
set "ULT=a1b2c3d4-e5f6-4789-a012-3456789abcde"

net session >nul 2>&1
if errorlevel 1 goto elevate
goto start

:elevate
echo Minta izin Administrator dulu...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:start
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"

:menu
cls
echo ==================================================
echo    UE BOOST TOOLKIT  -  Unreal Engine 5.x
echo ==================================================
echo.
echo   [1] FIX error "no app associated" file .uproject
echo   [2] BOOST ON   - performa maksimal buat ngedit
echo   [3] BOOST OFF  - balikin semua ke normal
echo   [4] BUKA PROJECT ^(pilih dari daftar^) + AUTO BOOST, normal lagi pas editor ditutup
echo   [5] Defender exclusion folder project, compile lebih ngebut
echo   [6] Bersihin file temp
echo   [7] Cek Engine versi %NEEDED_ENGINE% udah keinstall belum + buka Install-nya
echo   [8] COMPILE ULANG project ^("game module could not be found"^)
echo   [9] UNBLOKIR project Blueprint-only ^("does not have any source code"^)
echo   [10] INSTALL Windows SDK otomatis ^("Windows SDK must be installed"^)
echo   [0] Keluar
echo.
set "pil="
set /p "pil=Pilih nomor: "
if "%pil%"=="1" goto fix
if "%pil%"=="2" goto boost_on
if "%pil%"=="3" goto boost_off
if "%pil%"=="4" goto launch
if "%pil%"=="5" goto defender
if "%pil%"=="6" goto clean
if "%pil%"=="7" goto install_engine
if "%pil%"=="8" goto compile_module
if "%pil%"=="9" goto unblock_module
if "%pil%"=="10" goto install_sdk
if "%pil%"=="0" exit /b
goto menu

rem ==================================================
rem  [1] FIX ASOSIASI .uproject
rem ==================================================
:fix
cls
echo === FIX ASOSIASI FILE .uproject ===
echo.
set "UVS="
set "L1=%ProgramFiles(x86)%\Epic Games\Launcher\Engine\Binaries\Win64"
set "L2=%ProgramFiles%\Epic Games\Launcher\Engine\Binaries\Win64"
if exist "%L1%\UnrealVersionSelector.exe" set "UVS=%L1%\UnrealVersionSelector.exe"
if not defined UVS if exist "%L1%\UnrealVersionSelector-Win64-Shipping.exe" set "UVS=%L1%\UnrealVersionSelector-Win64-Shipping.exe"
if not defined UVS if exist "%L2%\UnrealVersionSelector.exe" set "UVS=%L2%\UnrealVersionSelector.exe"
if not defined UVS if exist "%L2%\UnrealVersionSelector-Win64-Shipping.exe" set "UVS=%L2%\UnrealVersionSelector-Win64-Shipping.exe"
if not defined UVS for /d %%D in ("%ProgramFiles%\Epic Games\UE_*") do if exist "%%D\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe" set "UVS=%%D\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe"
if not defined UVS for /d %%D in ("%ProgramFiles%\Epic Games\UE_*") do if exist "%%D\Engine\Binaries\Win64\UnrealVersionSelector.exe" set "UVS=%%D\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if not defined UVS for /d %%D in ("%ProgramFiles(x86)%\Epic Games\UE_*") do if exist "%%D\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe" set "UVS=%%D\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe"
if not defined UVS for /d %%D in ("%ProgramFiles(x86)%\Epic Games\UE_*") do if exist "%%D\Engine\Binaries\Win64\UnrealVersionSelector.exe" set "UVS=%%D\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if defined UVS goto fix_found
echo Ga ketemu di lokasi default.
echo ^(Kalau kelamaan di step berikutnya, tekan Ctrl+C buat batalin scan-nya^)
if not exist "D:\" goto fix_scan_c
echo Nyari cepat di drive D: ...
call :scan_drive "D:\"
if defined UVS goto fix_found

:fix_scan_c
if not exist "C:\" goto fix_ask_manual
echo Belum ketemu di D:, nyari di drive C: sekarang, skip folder Windows/sistem biar cepet...
call :scan_drive "C:\"
if defined UVS goto fix_found

:fix_ask_manual
echo [ERR] UnrealVersionSelector.exe ga ketemu di drive D: maupun C:.
echo Klik kanan file UnrealVersionSelector.exe di Explorer, pilih "Copy as path",
echo balik ke sini, klik kanan di jendela ini buat Paste, terus Enter.
echo Kosongin aja terus Enter kalau mau batal.
echo ^(Drag ^& drop ga bisa dipake, soalnya jendela ini jalan sebagai Administrator^)
set /p "UVS=> "
if defined UVS set "UVS=%UVS:"=%"
if not defined UVS goto menu
if not exist "%UVS%" goto fix_missing

:fix_found
echo Ketemu: %UVS%
echo.
echo Mendaftarkan asosiasi .uproject...
"%UVS%" /register
reg query "HKCR\Unreal.ProjectFile\shell\open\command" >nul 2>&1
if not errorlevel 1 goto fix_done
echo Register bawaan belum ngaruh, pasang manual...
reg add "HKCR\.uproject" /ve /d "Unreal.ProjectFile" /f >nul
reg add "HKCR\Unreal.ProjectFile" /ve /d "Unreal Engine Project File" /f >nul
reg add "HKCR\Unreal.ProjectFile\DefaultIcon" /ve /d "\"%UVS%\",0" /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\open\command" /ve /d "\"%UVS%\" /editor \"%%1\"" /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\run\command" /ve /d "\"%UVS%\" /game \"%%1\"" /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\rungenproj" /v MUIVerb /d "Generate Visual Studio project files" /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\rungenproj\command" /ve /d "\"%UVS%\" /projectfiles \"%%1\"" /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\switchversion" /v MUIVerb /d "Switch Unreal Engine version..." /f >nul
reg add "HKCR\Unreal.ProjectFile\shell\switchversion\command" /ve /d "\"%UVS%\" /switchversion \"%%1\"" /f >nul

:fix_done
echo.
assoc .uproject
echo.
echo Selesai. Coba buka lagi project dari Epic Launcher atau klik dua kali file .uproject.
echo Kalau masih error: restart PC sekali, atau klik kanan file .uproject
echo lalu pilih "Switch Unreal Engine version" dan pilih 5.5.
echo.
call :check_engine "%NEEDED_ENGINE%"
if "%ENGINE_FOUND%"=="1" goto fix_engine_ok
echo [PENTING] Engine Unreal %NEEDED_ENGINE% kayaknya belum keinstall di PC ini.
echo Ini biasanya penyebab error "The current folder does not contain an engine installation".
echo Epic ga nyediain download-otomatis-diam-diam buat akun biasa ^(itu cuma buat
echo organisasi yang punya lisensi Unreal seat resmi^), jadi Launcher aku bukain
echo langsung ke halaman Install Engine, tinggal klik Install versi %NEEDED_ENGINE%.
start "" "com.epicgames.launcher://ue/library"
:fix_engine_ok
echo.
pause
goto menu

:fix_missing
echo File ga ada.
pause
goto menu

rem ==================================================
rem  [7] CEK & PASANG ENGINE VERSION
rem ==================================================
:install_engine
cls
echo === CEK ENGINE VERSION ===
echo.
set "VER="
set /p "VER=Versi engine yang dicek, Enter = %NEEDED_ENGINE% : "
if not defined VER set "VER=%NEEDED_ENGINE%"
call :check_engine "%VER%"
if "%ENGINE_FOUND%"=="1" goto ie_found
echo Engine %VER% belum keinstall di PC ini.
echo.
echo Epic ga nyediain cara download-otomatis-diam-diam buat akun biasa
echo ^(itu cuma ada buat organisasi yang punya lisensi Unreal seat resmi
echo lewat Dev Portal mereka^). Yang bisa diotomatisin cuma langsung buka
echo Epic Games Launcher persis di halaman Install Engine-nya.
echo.
start "" "com.epicgames.launcher://ue/library"
echo Launcher lagi kebuka di tab Unreal Engine ^> Library.
echo Cari versi %VER% di daftar, klik Install, tunggu sampe kelar.
goto ie_end

:ie_found
echo Engine %VER% udah keinstall di PC ini, aman, tinggal buka project-nya.

:ie_end
echo.
pause
goto menu

rem ==================================================
rem  [8] COMPILE ULANG PROJECT (C++ module)
rem ==================================================
:compile_module
cls
echo === COMPILE ULANG PROJECT ===
echo.
call :list_projects
if "%PROJLIST_COUNT%"=="0" goto cm_manual
echo.
set "pilproj="
set /p "pilproj=Pilih nomor project yang mau di-compile (kosongin buat batal): "
if not defined pilproj goto menu
set "PROJ="
for /f "usebackq tokens=1,* delims=|" %%A in ("%STATE_DIR%\projects.txt") do if "%%A"=="%pilproj%" set "PROJ=%%B"
if not defined PROJ goto cm_badpick
if not exist "%PROJ%" goto cm_stale
goto cm_have_proj

:cm_stale
echo.
echo [INFO] Project ini kayaknya udah dipindah/direname/dihapus ^(path lama
echo ga ketemu lagi^): %PROJ%
echo Scan ulang daftar project...
call :list_projects force
goto compile_module

:cm_badpick
echo Nomor ga ada di daftar.
pause
goto menu

:cm_manual
echo Ga ketemu file .uproject otomatis.
echo Klik kanan file .uproject-nya di Explorer, pilih "Copy as path",
echo balik ke sini, klik kanan buat Paste, lalu Enter.
set "PROJ="
set /p "PROJ=> "
if defined PROJ set "PROJ=%PROJ:"=%"
if not defined PROJ goto menu
if not exist "%PROJ%" goto cm_nofile

:cm_have_proj
echo.
echo Project: %PROJ%

rem --- cari nama project dari nama file ---
for %%F in ("%PROJ%") do set "PROJNAME=%%~nF"
echo Nama module: %PROJNAME%Editor

rem --- baca versi engine dari .uproject pake PowerShell (JSON asli, lebih akurat) ---
set "ENGVER="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { (Get-Content -Raw '%PROJ%' | ConvertFrom-Json).EngineAssociation } catch { '' }" 2^>nul`) do set "ENGVER=%%V"
if "%ENGVER%"=="" set "ENGVER=%NEEDED_ENGINE%"
echo Versi engine yang dibutuhin: %ENGVER%

rem --- cek kalau EngineAssociation-nya GUID (custom/source build) ---
echo %ENGVER% | findstr /r /c:"^[0-9A-Fa-f][0-9A-Fa-f]*-" >nul 2>&1
if not errorlevel 1 goto cm_guid

rem --- cari folder root engine-nya ---
call :find_engine_root "%ENGVER%"
if not defined ENGINE_ROOT goto cm_noengine
echo Engine ketemu di: %ENGINE_ROOT%

rem --- coba generate ulang project files dulu (fix umum buat "Unable to find project") ---
set "CM_UVS="
if exist "%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealVersionSelector.exe" set "CM_UVS=%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if not defined CM_UVS if exist "%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe" set "CM_UVS=%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe"
if not defined CM_UVS if exist "%ProgramFiles%\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe" set "CM_UVS=%ProgramFiles%\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if not defined CM_UVS if exist "%ProgramFiles(x86)%\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe" set "CM_UVS=%ProgramFiles(x86)%\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if defined CM_UVS (
    echo Generate ulang project files dulu ^(fix umum buat error "Unable to find project"^)...
    "%CM_UVS%" /projectfiles "%PROJ%"
    echo.
)

rem --- cek Visual Studio / Build Tools ---
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto cm_novs
set "VSPATH="
for /f "usebackq delims=" %%P in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`) do set "VSPATH=%%P"
if not defined VSPATH goto cm_novs
echo Visual Studio ketemu di: %VSPATH%
echo.

set "CM_TRY=0"
set "CM_BACKED_UP="

:cm_compile_loop
set /a CM_TRY+=1
echo Mulai compile ^(percobaan %CM_TRY%^)... INI BISA LAMA ^(bisa belasan-puluhan
echo menit tergantung PC^), jangan tutup jendela ini sampe keliatan selesai
echo atau error. Output baru muncul pas percobaan ini selesai.
echo.
set "CM_LOG=%STATE_DIR%\compile_last.log"
call "%ENGINE_ROOT%\Engine\Build\BatchFiles\Build.bat" %PROJNAME%Editor Win64 Development -Project="%PROJ%" -WaitMutex > "%CM_LOG%" 2>&1
set "CM_RC=%errorlevel%"
type "%CM_LOG%"
if "%CM_RC%"=="0" goto cm_ok

rem --- compile gagal: kalau gara-gara plugin yang ga ketemu, hapus dari
rem     .uproject terus coba compile ulang otomatis (maks 6x biar ga muter terus) ---
findstr /c:"Unable to find plugin" "%CM_LOG%" >nul 2>&1
if errorlevel 1 goto cm_fail
if %CM_TRY% GEQ 6 goto cm_fail

if defined CM_BACKED_UP goto cm_skip_backup
copy /y "%PROJ%" "%PROJ%.bak" >nul 2>&1
set "CM_BACKED_UP=1"
echo [INFO] Backup .uproject disimpen: %PROJ%.bak

:cm_skip_backup
powershell -NoProfile -Command "$log = Get-Content -Raw '%CM_LOG%'; $names = [regex]::Matches($log, 'Unable to find plugin ''([^'']+)''') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique; if ($names.Count -eq 0) { Write-Output 'NONE' } else { $p = '%PROJ%'; $j = Get-Content -Raw $p | ConvertFrom-Json; $removed = @(); foreach ($n in $names) { $before = $j.Plugins.Count; $j.Plugins = @($j.Plugins | Where-Object { $_.Name -ne $n }); if ($j.Plugins.Count -lt $before) { $removed += $n } }; ($j | ConvertTo-Json -Depth 20) | Set-Content -Encoding UTF8 $p; Write-Output ('FIXED:' + ($removed -join ',')) }" > "%STATE_DIR%\cm_fix_result.txt" 2>&1
set "CM_FIX_RES="
set /p "CM_FIX_RES=" < "%STATE_DIR%\cm_fix_result.txt"
echo %CM_FIX_RES% | findstr /b "FIXED:" >nul
if errorlevel 1 goto cm_fail
echo.
echo [INFO] Plugin yang ga ketemu udah dicoret dari required plugin list: %CM_FIX_RES%
echo Coba compile ulang otomatis...
echo.
goto cm_compile_loop

:cm_ok
echo.
echo [OK] Compile selesai tanpa error. Coba buka lagi project-nya ^(menu 4^).
goto cm_end

:cm_fail
echo.
echo [ERR] Compile gagal, ada error di atas ^(scroll ke atas buat baca detailnya^).
echo Penyebab paling umum: versi Visual Studio ga cocok sama versi engine,
echo ada source code plugin yang error/ga lengkap, atau engine-nya pernah
echo dipindah folder manual jadi ada referensi internal yang belum nyambung.
if defined CM_BACKED_UP echo ^(File .uproject asli ada backup-nya: %PROJ%.bak^)
echo.
echo Alternatif kalau masih gagal: buka file .sln yang baru digenerate tadi
echo ^(ada di folder project yang sama, nama file %PROJNAME%.sln^) pake
echo Visual Studio langsung, terus Build ^> Build Solution dari situ.
goto cm_end

:cm_novs
echo.
echo [ERR] Visual Studio dengan komponen C++ ga ketemu di PC ini.
echo Compile C++ project BUTUH Visual Studio Community ^(gratis^) dengan workload:
echo   - "Desktop development with C++"
echo   - "Game development with C++" ^(otomatis include Unreal Engine installer^)
echo Download di: https://visualstudio.microsoft.com/downloads/
echo Install dulu, restart PC, baru coba menu 8 ini lagi.
goto cm_end

:cm_noengine
echo.
echo [ERR] Folder instalasi Engine %ENGVER% ga ketemu di lokasi standar
echo ^(%ProgramFiles%\Epic Games\UE_%ENGVER%^). Pastiin Engine %ENGVER% udah
echo keinstall lengkap ^(cek menu 7^).
goto cm_end

:cm_guid
echo.
echo [ERR] Project ini pake custom/source-build engine ^(EngineAssociation-nya
echo bukan nomor versi biasa, tapi kode panjang^). Ga bisa dicariin otomatis,
echo kamu perlu compile manual lewat Visual Studio pake source engine yang sesuai.
goto cm_end

:cm_nofile
echo File ga ketemu.
goto cm_end

:cm_end
echo.
pause
goto menu

rem ==================================================
rem  [9] UNBLOKIR PROJECT BLUEPRINT-ONLY (hapus referensi
rem      module C++ di .uproject kalau folder Source ga ada)
rem ==================================================
:unblock_module
cls
echo === UNBLOKIR PROJECT ^(BLUEPRINT-ONLY^) ===
echo.
echo Buat error "This project does not have any source code..." pas project-nya
echo sebenernya cuma Blueprint ^(kit dari Fab/Marketplace^). Script ini bakal HAPUS
echo referensi module C++ di file .uproject biar bisa dibuka langsung tanpa
echo compile / Generate Project Files. File asli otomatis dicadangin dulu ^(.bak^).
echo.
call :list_projects
if "%PROJLIST_COUNT%"=="0" goto ub_manual
echo.
set "pilproj="
set /p "pilproj=Pilih nomor project (kosongin buat batal): "
if not defined pilproj goto menu
set "PROJ="
for /f "usebackq tokens=1,* delims=|" %%A in ("%STATE_DIR%\projects.txt") do if "%%A"=="%pilproj%" set "PROJ=%%B"
if not defined PROJ goto ub_badpick
if not exist "%PROJ%" goto ub_stale
goto ub_have_proj

:ub_stale
echo.
echo [INFO] Project ini kayaknya udah dipindah/direname/dihapus ^(path lama
echo ga ketemu lagi^): %PROJ%
echo Scan ulang daftar project...
call :list_projects force
goto unblock_module

:ub_badpick
echo Nomor ga ada di daftar.
pause
goto menu

:ub_manual
echo Ga ketemu file .uproject otomatis.
echo Klik kanan file .uproject-nya di Explorer, pilih "Copy as path",
echo balik ke sini, klik kanan buat Paste, lalu Enter.
set "PROJ="
set /p "PROJ=> "
if defined PROJ set "PROJ=%PROJ:"=%"
if not defined PROJ goto menu
if not exist "%PROJ%" goto ub_nofile
goto ub_have_proj

:ub_have_proj
echo.
echo Project: %PROJ%

rem --- cek folder Source di sebelah .uproject ---
set "UB_DIR="
for %%F in ("%PROJ%") do set "UB_DIR=%%~dpF"
if exist "%UB_DIR%Source\" goto ub_has_source

echo Folder Source ga ketemu di sebelah .uproject ^(berarti project ini emang
echo Blueprint-only, ATAU extract archive-nya ga lengkap kalau ini dari .rar
echo multi-part - cek dulu semua part udah keextract kalau ragu^).
echo.
set "ub_yn="
set /p "ub_yn=Ketik YA buat lanjut hapus referensi module, apa aja selain itu buat batal: "
if /i not "%ub_yn%"=="YA" goto ub_cancel

rem --- backup dulu, jangan sampe project asli rusak ---
del "%STATE_DIR%\ub_copy_err.txt" >nul 2>&1
copy /y "%PROJ%" "%PROJ%.bak" >"%STATE_DIR%\ub_copy_err.txt" 2>&1
if exist "%PROJ%.bak" goto ub_backup_ok
rem coba cara kedua pake PowerShell kalau "copy" biasa gagal
powershell -NoProfile -Command "try { Copy-Item -LiteralPath '%PROJ%' -Destination '%PROJ%.bak' -Force -ErrorAction Stop; 'OK' } catch { 'ERR:' + $_.Exception.Message }" >>"%STATE_DIR%\ub_copy_err.txt" 2>&1
if not exist "%PROJ%.bak" goto ub_backupfail

:ub_backup_ok
echo [OK] Backup disimpen: %PROJ%.bak

rem --- edit JSON: hapus key "Modules" pake PowerShell ---
powershell -NoProfile -Command "$p='%PROJ%'; try { $j = Get-Content -Raw $p | ConvertFrom-Json; $j.PSObject.Properties.Remove('Modules') | Out-Null; ($j | ConvertTo-Json -Depth 20) | Set-Content -Encoding UTF8 $p; Write-Output 'OK' } catch { Write-Output ('ERR:' + $_.Exception.Message) }" > "%STATE_DIR%\ub_result.txt" 2>&1
set "UB_RES="
set /p "UB_RES=" < "%STATE_DIR%\ub_result.txt"
echo %UB_RES% | findstr /b "OK" >nul
if errorlevel 1 goto ub_jsonfail

echo.
echo [OK] Referensi module C++ udah dihapus dari .uproject.
echo File asli ada di: %PROJ%.bak ^(kalau mau balikin: hapus .uproject yang baru,
echo terus rename .bak-nya balik jadi .uproject^)
echo.
echo Coba buka project-nya sekarang ^(menu 4^) - harusnya langsung kebuka
echo tanpa minta compile atau "Generate Visual Studio project files" lagi.
goto ub_end

:ub_has_source
echo [INFO] Folder Source KETEMU di: %UB_DIR%Source
echo Artinya project ini beneran punya C++ code, JANGAN dihapus referensi
echo module-nya ^(nanti malah error lain pas dibuka^). Errornya kemungkinan
echo dari Visual Studio / compile ^(coba menu 8^), atau kalau ini dari .rar
echo multi-part, cek lagi semua part udah keextract semua ^(part1, part2, dst,
echo bukan cuma satu part doang^) sebelum coba compile ulang.
goto ub_end

:ub_backupfail
echo [ERR] Gagal bikin backup, dibatalin biar project aman.
echo.
echo Detail error dari Windows:
type "%STATE_DIR%\ub_copy_err.txt" 2>nul
echo.
echo Penyebab yang paling sering:
echo   - File .uproject-nya lagi kepake app lain. Tutup dulu: Unreal Editor,
echo     Epic Games Launcher, Visual Studio, dan jendela Explorer yang lagi
echo     nampilin preview folder DEFINITIVEFPSKIT, terus coba menu 9 lagi.
echo   - Cek Task Manager, kalau masih ada proses "UnrealBuildTool",
echo     "dotnet", atau "UnrealEditor" nyangkut dari compile yang gagal
echo     kemarin, End Task dulu proses itu.
echo   - Windows Security ^> Virus ^& threat protection ^> Manage ransomware
echo     protection ^> Controlled folder access - kalau nyala, matiin sementara
echo     terus coba lagi.
echo   - Klik kanan folder D:\DEFINITIVEFPSKIT ^> Properties, cek kalau
echo     centang "Read-only" nyala, uncheck, klik Apply, pilih "apply to all
echo     subfolders and files".
goto ub_end

:ub_jsonfail
echo [ERR] Gagal edit file .uproject ^(%UB_RES%^).
echo File asli aman, belum keubah ^(ada juga backup-nya: %PROJ%.bak^).
goto ub_end

:ub_cancel
echo Dibatalin, ga ada yang diubah.
goto menu

:ub_nofile
echo File ga ketemu.
goto ub_end

:ub_end
echo.
pause
goto menu

rem ==================================================
rem  [10] INSTALL WINDOWS SDK OTOMATIS
rem ==================================================
:install_sdk
cls
echo === INSTALL WINDOWS SDK OTOMATIS ===
echo.
echo Ini buat error "Windows SDK must be installed in order to build this
echo target" atau "No available Windows SDKs found" pas Generate Project Files
echo atau compile.
echo.
echo Nyoba lewat winget dulu ^(cara paling stabil, udah bawaan Windows 10/11^)...
echo.
where winget >nul 2>&1
if errorlevel 1 goto sdk_try_vs
winget install --id Microsoft.WindowsSDK.10.0.22621 -e --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 goto sdk_winget_ok
echo [INFO] Build 22621 ga ketemu/gagal, nyoba build 20348...
winget install --id Microsoft.WindowsSDK.10.0.20348 -e --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 goto sdk_winget_ok
echo [INFO] Nyoba build 19041...
winget install --id Microsoft.WindowsSDK.10.0.19041 -e --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 goto sdk_winget_ok
echo [INFO] winget ga berhasil, nyoba lewat Visual Studio Installer...
goto sdk_try_vs

:sdk_winget_ok
echo.
echo [OK] Windows SDK keinstall lewat winget.
echo Coba lagi buka project ^(menu 4^) atau compile ulang ^(menu 8^).
goto sdk_end

:sdk_try_vs
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto sdk_novs
set "VSPATH="
for /f "usebackq delims=" %%P in (`"%VSWHERE%" -latest -products * -property installationPath 2^>nul`) do set "VSPATH=%%P"
if not defined VSPATH goto sdk_novs
echo Visual Studio ketemu di: %VSPATH%
set "VSINSTALLER=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vs_installer.exe"
if not exist "%VSINSTALLER%" goto sdk_noinstaller
echo.
echo Nambahin workload "Game development with C++" dan "Desktop development
echo with C++" lewat Visual Studio Installer ^(mode silent, ga ada jendela^).
echo INI BISA LAMA ^(download dari internet^), tunggu sampe prompt balik lagi,
echo jangan tutup jendela ini.
echo.
"%VSINSTALLER%" modify --installPath "%VSPATH%" --add Microsoft.VisualStudio.Workload.NativeGame --add Microsoft.VisualStudio.Workload.NativeDesktop --quiet --norestart
if errorlevel 1 goto sdk_fail
echo.
echo [OK] Kelar. Coba lagi buka project ^(menu 4^) atau compile ulang ^(menu 8^).
goto sdk_end

:sdk_novs
echo [ERR] Visual Studio ga ketemu di PC ini, dan winget juga ga berhasil.
echo Windows SDK biasanya kebawa pas install Visual Studio dengan workload
echo "Game development with C++". Download dulu Visual Studio Community
echo ^(gratis^): https://visualstudio.microsoft.com/downloads/
echo Pas install, centang workload "Game development with C++".
goto sdk_end

:sdk_noinstaller
echo [ERR] vs_installer.exe ga ketemu di lokasi standar. Coba buka
echo "Visual Studio Installer" manual dari Start Menu, klik "Modify" di
echo Visual Studio kamu, terus di tab "Individual components" centang
echo "Windows 10 SDK" atau "Windows 11 SDK" ^(versi paling baru yang ada^).
goto sdk_end

:sdk_fail
echo.
echo [ERR] winget sama Visual Studio Installer command-line dua-duanya gagal
echo ^(kemungkinan butuh koneksi internet yang lebih stabil, atau versi
echo Visual Studio Installer-nya lagi kena update^). Cara paling pasti sekarang:
echo buka "Visual Studio Installer" manual dari Start Menu ^(bukan lewat
echo script^), klik "Modify" di Visual Studio kamu, pastiin workload
echo "Game development with C++" ke-centang, klik tombol Modify di pojok
echo kanan bawah, tunggu sampe selesai.
goto sdk_end

:sdk_end
echo.
pause
goto menu

rem ==================================================
rem  SUBROUTINE: CARI FOLDER ROOT ENGINE BERDASARKAN VERSI
rem ==================================================
:find_engine_root
set "FE_VER=%~1"
set "FE_VER=%FE_VER:"=%"
set "ENGINE_ROOT="
if exist "%ProgramFiles%\Epic Games\UE_%FE_VER%\Engine\Build\BatchFiles\Build.bat" set "ENGINE_ROOT=%ProgramFiles%\Epic Games\UE_%FE_VER%"
if not defined ENGINE_ROOT if exist "%ProgramFiles(x86)%\Epic Games\UE_%FE_VER%\Engine\Build\BatchFiles\Build.bat" set "ENGINE_ROOT=%ProgramFiles(x86)%\Epic Games\UE_%FE_VER%"
if defined ENGINE_ROOT exit /b
echo Ga ketemu di lokasi standar, nyari di drive D: dan C: ^(cepat, cuma cek nama folder^)...
if exist "D:\" call :scan_engine_root "D:\" "%FE_VER%"
if defined ENGINE_ROOT exit /b
if exist "C:\" call :scan_engine_root "C:\" "%FE_VER%"
exit /b

rem ==================================================
rem  SUBROUTINE: SCAN 1 DRIVE CARI FOLDER ENGINE ROOT
rem  (cuma cek nama folder 2 level + exist Build.bat, BUKAN
rem   scan isi file, jadi tetep cepat walau folder gede)
rem ==================================================
:scan_engine_root
set "SE_ROOT=%~1"
set "SE_VER=%~2"
for /f "delims=" %%D in ('dir /b /ad "%SE_ROOT%" 2^>nul') do (
    set "SE_SKIP=0"
    if /i "%%D"=="Windows" set "SE_SKIP=1"
    if /i "%%D"=="$Recycle.Bin" set "SE_SKIP=1"
    if /i "%%D"=="System Volume Information" set "SE_SKIP=1"
    if /i "%%D"=="Recovery" set "SE_SKIP=1"
    if "!SE_SKIP!"=="0" (
        echo   ...cek %SE_ROOT%%%D
        if not defined ENGINE_ROOT if exist "%SE_ROOT%%%D\Engine\Build\BatchFiles\Build.bat" (
            echo %%D| findstr /i /c:"%SE_VER%" >nul 2>&1
            if not errorlevel 1 set "ENGINE_ROOT=%SE_ROOT%%%D"
        )
        if not defined ENGINE_ROOT for /f "delims=" %%E in ('dir /b /ad "%SE_ROOT%%%D" 2^>nul') do (
            if not defined ENGINE_ROOT (
                echo %%E| findstr /i /c:"UE_%SE_VER%" >nul 2>&1
                if not errorlevel 1 if exist "%SE_ROOT%%%D\%%E\Engine\Build\BatchFiles\Build.bat" set "ENGINE_ROOT=%SE_ROOT%%%D\%%E"
            )
        )
    )
    if defined ENGINE_ROOT goto scan_engine_root_done
)
:scan_engine_root_done
exit /b

rem ==================================================
rem  SUBROUTINE: CEK ENGINE VERSION UDAH KEINSTALL BELUM
rem  (baca LauncherInstalled.dat punya Epic Games Launcher)
rem ==================================================
:check_engine
set "CE_VER=%~1"
set "ENGINE_FOUND=0"
set "LID=%ProgramData%\Epic\UnrealEngineLauncher\LauncherInstalled.dat"
if not exist "%LID%" exit /b
findstr /c:"UE_%CE_VER%" "%LID%" >nul 2>&1
if not errorlevel 1 set "ENGINE_FOUND=1"
exit /b

rem ==================================================
rem  SUBROUTINE: SCAN DRIVE cepat + log, skip folder OS
rem ==================================================
:scan_drive
set "SD_ROOT=%~1"
for /f "delims=" %%D in ('dir /b /ad "%SD_ROOT%" 2^>nul') do (
    set "SD_SKIP=0"
    if /i "%%D"=="Windows" set "SD_SKIP=1"
    if /i "%%D"=="$Recycle.Bin" set "SD_SKIP=1"
    if /i "%%D"=="System Volume Information" set "SD_SKIP=1"
    if /i "%%D"=="Recovery" set "SD_SKIP=1"
    if "!SD_SKIP!"=="0" (
        echo   ...cek %SD_ROOT%%%D
        for /f "delims=" %%F in ('dir /b /s /a:-d "%SD_ROOT%%%D\UnrealVersionSelector-Win64-Shipping.exe" 2^>nul') do if not defined UVS set "UVS=%%F"
        if not defined UVS for /f "delims=" %%F in ('dir /b /s /a:-d "%SD_ROOT%%%D\UnrealVersionSelector.exe" 2^>nul') do if not defined UVS set "UVS=%%F"
        if defined UVS goto scan_drive_done
    ) else (
        echo   ...lewatin %SD_ROOT%%%D ^(folder sistem^)
    )
)
:scan_drive_done
exit /b

rem ==================================================
rem  [2] BOOST ON
rem ==================================================
:boost_on
cls
echo === BOOST ON ===
echo.
call :do_on
echo.
echo Selesai. Buka Unreal Engine sekarang, priority editor otomatis High.
echo Musik tetap aman karena app musik dinaikin priority-nya juga.
echo.
pause
goto menu

rem ==================================================
rem  [3] BOOST OFF
rem ==================================================
:boost_off
cls
echo === BOOST OFF ===
echo.
call :do_off
echo.
pause
goto menu

rem ==================================================
rem  [4] BUKA PROJECT + AUTO BOOST
rem ==================================================
:launch
cls
echo === BUKA PROJECT + AUTO BOOST ===
echo.
assoc .uproject >nul 2>&1
if errorlevel 1 goto launch_noassoc
call :list_projects
if "%PROJLIST_COUNT%"=="0" goto launch_manual
echo   [0] Scan ulang ^(kalau ada project baru yang belum masuk daftar^)
echo.
set "pilproj="
set /p "pilproj=Pilih nomor project (kosongin buat balik ke menu): "
if not defined pilproj goto menu
if "%pilproj%"=="0" (call :list_projects force & goto launch)
set "PROJ="
for /f "usebackq tokens=1,* delims=|" %%A in ("%STATE_DIR%\projects.txt") do if "%%A"=="%pilproj%" set "PROJ=%%B"
if not defined PROJ goto launch_badpick
if not exist "%PROJ%" goto launch_stale
goto launch_got

:launch_stale
echo.
echo [INFO] Project ini kayaknya udah dipindah/direname/dihapus ^(path lama
echo ga ketemu lagi^): %PROJ%
echo Scan ulang daftar project...
call :list_projects force
goto launch

:launch_badpick
echo Nomor ga ada di daftar.
pause
goto launch

:launch_manual
echo Ga ketemu file .uproject otomatis di drive D: atau C:.
echo Klik kanan file .uproject-nya di Explorer, pilih "Copy as path",
echo balik ke sini, klik kanan di jendela ini buat Paste, terus Enter.
echo ^(Drag ^& drop ga bisa dipake, soalnya jendela ini jalan sebagai Administrator^)
set "PROJ="
set /p "PROJ=> "
if defined PROJ set "PROJ=%PROJ:"=%"
if not defined PROJ goto menu
if not exist "%PROJ%" goto launch_nofile

:launch_got
echo.
echo Project dipilih:
echo   %PROJ%
call :do_on
echo.
echo Buka project di Unreal Editor...
explorer.exe "%PROJ%"
echo Nunggu editor kebuka, jangan tutup jendela ini...
set /a tries=0

:wait_start
timeout /t 3 /nobreak >nul
tasklist /fi "imagename eq UnrealEditor.exe" 2>nul | find /i "UnrealEditor.exe" >nul
if not errorlevel 1 goto wait_run
set /a tries+=1
if %tries% lss 100 goto wait_start
echo [ERR] Editor ga kedeteksi setelah 5 menit, boost dimatiin.
goto wait_done

:wait_run
echo Editor jalan, boost aktif. Tutup editor kalau udah selesai, boost otomatis dimatiin.

:wait_loop
timeout /t 5 /nobreak >nul
tasklist /fi "imagename eq UnrealEditor.exe" 2>nul | find /i "UnrealEditor.exe" >nul
if not errorlevel 1 goto wait_loop

:wait_done
echo.
echo Editor ditutup, balikin pengaturan normal...
call :do_off
echo.
pause
goto menu

:launch_noassoc
echo [ERR] Asosiasi .uproject belum ada. Jalanin menu 1 dulu.
pause
goto menu

:launch_nofile
echo File ga ketemu.
pause
goto menu

rem ==================================================
rem  SUBROUTINE: LIST PROJECTS (.uproject), kesimpen di cache
rem  supaya buka project berikutnya ga perlu scan ulang
rem ==================================================
:list_projects
set "LP_FORCE=%~1"
if /i "%LP_FORCE%"=="force" del "%STATE_DIR%\projects.txt" >nul 2>&1
if exist "%STATE_DIR%\projects.txt" goto lp_show
set "N=0"
echo Nyari file .uproject di drive D: dan C: ^(sekali aja, abis ini kesimpen^)...
if exist "D:\" call :scan_uproject "D:\"
if exist "C:\" call :scan_uproject "C:\"

:lp_show
set "PROJLIST_COUNT=0"
if not exist "%STATE_DIR%\projects.txt" exit /b
echo.
echo Project ketemu:
for /f "usebackq tokens=1,* delims=|" %%A in ("%STATE_DIR%\projects.txt") do (
    echo   [%%A] %%B
    set "PROJLIST_COUNT=%%A"
)
exit /b

rem ==================================================
rem  SUBROUTINE: SCAN 1 DRIVE CARI SEMUA *.uproject, LOG
rem ==================================================
:scan_uproject
set "SU_ROOT=%~1"
for /f "delims=" %%D in ('dir /b /ad "%SU_ROOT%" 2^>nul') do (
    set "SU_SKIP=0"
    if /i "%%D"=="Windows" set "SU_SKIP=1"
    if /i "%%D"=="$Recycle.Bin" set "SU_SKIP=1"
    if /i "%%D"=="System Volume Information" set "SU_SKIP=1"
    if /i "%%D"=="Recovery" set "SU_SKIP=1"
    if /i "%%D"=="UnrealEngine" set "SU_SKIP=1"
    if /i "%%D"=="Epic Games" set "SU_SKIP=1"
    if /i "%%D"=="Program Files" set "SU_SKIP=1"
    if /i "%%D"=="Program Files (x86)" set "SU_SKIP=1"
    if /i "%%D"=="ProgramData" set "SU_SKIP=1"
    if /i "%%D"=="node_modules" set "SU_SKIP=1"
    if "!SU_SKIP!"=="0" (
        echo   ...cek %SU_ROOT%%%D
        for /f "delims=" %%F in ('dir /b /s /a:-d "%SU_ROOT%%%D\*.uproject" 2^>nul') do (
            set /a N+=1
            >>"%STATE_DIR%\projects.txt" echo !N!^|%%F
        )
    )
)
exit /b

rem ==================================================
rem  [5] DEFENDER EXCLUSION
rem ==================================================
:defender
cls
echo === DEFENDER EXCLUSION ===
echo Bikin Defender ga scan folder project pas compile dan load asset.
echo Aman selama isi foldernya cuma file project kamu sendiri.
echo.
echo   [T] Tambah exclusion
echo   [H] Hapus exclusion
echo.
set "dm="
set /p "dm=Pilih T atau H: "
if /i not "%dm%"=="T" if /i not "%dm%"=="H" goto menu
set "EXC="
set /p "EXC=Folder project, Enter = %PROJECT_DIR% : "
if defined EXC set "EXC=%EXC:"=%"
if not defined EXC set "EXC=%PROJECT_DIR%"
if /i "%dm%"=="T" powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%EXC%' -ExclusionProcess 'UnrealEditor.exe','ShaderCompileWorker.exe'"
if /i "%dm%"=="H" powershell -NoProfile -Command "Remove-MpPreference -ExclusionPath '%EXC%' -ExclusionProcess 'UnrealEditor.exe','ShaderCompileWorker.exe'"
echo.
echo Selesai. Kalau ada error merah di atas, kemungkinan Defender dikelola antivirus lain.
pause
goto menu

rem ==================================================
rem  [6] BERSIHIN TEMP
rem ==================================================
:clean
cls
echo === BERSIHIN TEMP ===
echo.
tasklist /fi "imagename eq UnrealEditor.exe" 2>nul | find /i "UnrealEditor.exe" >nul
if not errorlevel 1 goto clean_busy
echo Bersihin temp...
del /q /f /s "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
echo Selesai.
pause
goto menu

:clean_busy
echo Tutup Unreal Editor dulu ya, baru bersihin temp.
pause
goto menu

rem ==================================================
rem  SUBROUTINE: BOOST ON
rem ==================================================
:do_on
rem --- 1. Power plan ---
if not exist "%STATE_DIR%\prev_plan.txt" for /f "tokens=2 delims=:(" %%G in ('powercfg /getactivescheme') do for /f %%H in ("%%G") do >"%STATE_DIR%\prev_plan.txt" echo %%H
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 %ULT% >nul 2>&1
powercfg /setactive %ULT% >nul 2>&1
if not errorlevel 1 goto on_plan_ult
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 goto on_plan_fail
echo [OK] Power plan: High Performance
goto on_prio

:on_plan_ult
echo [OK] Power plan: Ultimate Performance
goto on_prio

:on_plan_fail
echo [ERR] Power plan ga bisa diganti, dilewati

:on_prio
rem --- 2. Priority otomatis, berlaku tiap app dibuka ---
reg add "%IFEO%\UnrealEditor.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "%IFEO%\ShaderCompileWorker.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f >nul 2>&1
for %%A in (%MUSIC_APPS%) do reg add "%IFEO%\%%A\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f >nul 2>&1
set "MLIST="
for %%A in (%MUSIC_APPS%) do set "MLIST=!MLIST!'%%~nA',"
powershell -NoProfile -Command "Get-Process -Name 'UnrealEditor' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'High' } catch {} }; Get-Process -Name 'ShaderCompileWorker' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'AboveNormal' } catch {} }; Get-Process -Name !MLIST!'x' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'AboveNormal' } catch {} }"
echo [OK] Priority: UnrealEditor High, ShaderCompile dan app musik Above Normal

rem --- 3. Paksa GPU performa tinggi (buat laptop dua GPU) ---
for /d %%D in ("%ProgramFiles%\Epic Games\UE_*") do reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "%%D\Engine\Binaries\Win64\UnrealEditor.exe" /t REG_SZ /d "GpuPreference=2;" /f >nul 2>&1
echo [OK] UnrealEditor diarahin ke GPU performa tinggi

rem --- 4. Pause OneDrive ---
if not "%PAUSE_ONEDRIVE%"=="1" goto on_kill
tasklist /fi "imagename eq OneDrive.exe" 2>nul | find /i "OneDrive.exe" >nul
if errorlevel 1 goto on_kill
>"%STATE_DIR%\onedrive.flag" echo 1
taskkill /f /im OneDrive.exe >nul 2>&1
echo [OK] OneDrive sync di-pause sementara

:on_kill
rem --- 5. Tutup app berat ---
for %%A in (%KILL_APPS%) do taskkill /f /im %%A >nul 2>&1
echo [OK] App berat ditutup

rem --- 6. Matiin indexer Windows Search sementara ---
sc query WSearch | find "RUNNING" >nul
if errorlevel 1 goto on_done
>"%STATE_DIR%\ws.flag" echo 1
net stop WSearch >nul 2>&1
echo [OK] Windows Search indexer dimatiin sementara

:on_done
exit /b

rem ==================================================
rem  SUBROUTINE: BOOST OFF
rem ==================================================
:do_off
set "PREV="
if exist "%STATE_DIR%\prev_plan.txt" set /p PREV=<"%STATE_DIR%\prev_plan.txt"
if /i "%PREV%"=="%ULT%" set "PREV=381b4222-f694-41f0-9685-ff5bb260df2e"
if defined PREV powercfg /setactive %PREV% >nul 2>&1
if defined PREV echo [OK] Power plan balik ke semula
powercfg /delete %ULT% >nul 2>&1
del "%STATE_DIR%\prev_plan.txt" >nul 2>&1

reg delete "%IFEO%\UnrealEditor.exe\PerfOptions" /f >nul 2>&1
reg delete "%IFEO%\ShaderCompileWorker.exe\PerfOptions" /f >nul 2>&1
for %%A in (%MUSIC_APPS%) do reg delete "%IFEO%\%%A\PerfOptions" /f >nul 2>&1
echo [OK] Priority balik normal

if not exist "%STATE_DIR%\onedrive.flag" goto off_ws
del "%STATE_DIR%\onedrive.flag" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" explorer.exe "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe"
if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" if not exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" explorer.exe "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe"
echo [OK] OneDrive dinyalain lagi

:off_ws
if not exist "%STATE_DIR%\ws.flag" goto off_done
del "%STATE_DIR%\ws.flag" >nul 2>&1
net start WSearch >nul 2>&1
echo [OK] Windows Search nyala lagi

:off_done
exit /b
