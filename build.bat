@echo off
REM ============================================================
REM  RetroPlug command-line build (no Visual Studio IDE needed)
REM
REM  Prerequisite: "Build Tools for Visual Studio" with the
REM  "Desktop development with C++" workload AND the MSVC v142
REM  (VS2019) toolset component - premake generates vs2019
REM  projects, which build with the v142 toolset.
REM
REM  This script fetches premake5 + RGBDS into build\tools
REM  automatically, then mirrors deploy.bat's build sequence.
REM ============================================================
setlocal enableextensions
cd /d "%~dp0"

set "TOOLS=%CD%\build\tools"
if not exist "%TOOLS%" mkdir "%TOOLS%"

REM ---- premake5 (alpha16 - the version this project pins) ----
if not exist "%TOOLS%\premake5.exe" (
    echo [build] Downloading premake5...
    curl -fL --http1.1 --retry 5 --retry-all-errors --retry-delay 3 --connect-timeout 30 -o "%TOOLS%\premake.zip" "https://github.com/premake/premake-core/releases/download/v5.0.0-alpha16/premake-5.0.0-alpha16-windows.zip" || goto :fail
    powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TOOLS%\premake.zip' -DestinationPath '%TOOLS%' -Force" || goto :fail
    del "%TOOLS%\premake.zip"
)

REM ---- RGBDS 0.6.1 (Game Boy assembler). SameBoy 0.15.7 + sameboy.lua use the
REM      0.6+ rgbgfx CLI ("-Z -u -c embedded"), so 0.5.x will not work. ----
set "RGBDS_VER=0.6.1"
REM Remove any stale RGBDS left flat in build\tools by an earlier build.bat
del "%TOOLS%\rgbasm.exe" "%TOOLS%\rgblink.exe" "%TOOLS%\rgbfix.exe" "%TOOLS%\rgbgfx.exe" 2>nul
if not exist "%TOOLS%\rgbds-%RGBDS_VER%\rgbasm.exe" (
    echo [build] Downloading RGBDS %RGBDS_VER%...
    curl -fL --http1.1 --retry 5 --retry-all-errors --retry-delay 3 --connect-timeout 30 -o "%TOOLS%\rgbds.zip" "https://github.com/gbdev/rgbds/releases/download/v%RGBDS_VER%/rgbds-%RGBDS_VER%-win64.zip" || goto :fail
    powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TOOLS%\rgbds.zip' -DestinationPath '%TOOLS%\rgbds-%RGBDS_VER%' -Force" || goto :fail
    del "%TOOLS%\rgbds.zip"
)
REM rgbds exes may land in a subfolder depending on the archive layout
set "RGBDIR=%TOOLS%\rgbds-%RGBDS_VER%"
for /r "%TOOLS%\rgbds-%RGBDS_VER%" %%f in (rgbasm.exe) do set "RGBDIR=%%~dpf"
set "PATH=%RGBDIR%;%TOOLS%;%PATH%"

REM ---- Locate the MSVC toolchain and load its environment ----
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo [build] ERROR: Visual Studio Build Tools not found.
    echo         Install them first ^(see the winget command in the instructions^).
    goto :fail
)
set "VSPATH="
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (
    echo [build] ERROR: MSVC C++ tools not found.
    echo         Install the "Desktop development with C++" workload.
    goto :fail
)
echo [build] Using MSVC at: %VSPATH%
call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" || goto :fail

REM ---- Generate projects, build the script compiler, run it, rebuild ----
REM  Note: premake emits MSVC projects targeting the v142 toolset and builds
REM  SameBoy/pb12 with the ClangCL toolset. Both must be installed - do NOT
REM  pass /p:PlatformToolset here, or the Clang projects break (#include_next).
echo [build] Generating projects (premake5 vs2019)...
"%TOOLS%\premake5.exe" vs2019 || goto :fail

echo [build] Building ScriptCompiler...
msbuild build\vs2019\ScriptCompiler.vcxproj /p:Configuration=Release /p:Platform=x64 /m /nologo /v:m || goto :fail

echo [build] Running ScriptCompiler...
build\vs2019\bin\x64\Release\ScriptCompiler.exe src\compiler.config.lua || goto :fail

"%TOOLS%\premake5.exe" vs2019 || goto :fail

echo [build] Building RetroPlug (Release x64)...
msbuild build\vs2019\RetroPlug.sln /p:Configuration=Release /p:Platform=x64 /m /nologo /v:m || goto :fail

REM ---- Package the VST3 DLL into a .vst3 bundle (the format hosts expect) ----
set "RELDIR=build\vs2019\bin\x64\Release"
if exist "%RELDIR%\RetroPlug_vst3_x64.dll" (
    if not exist "%RELDIR%\RetroPlug.vst3\Contents\x86_64-win" mkdir "%RELDIR%\RetroPlug.vst3\Contents\x86_64-win"
    copy /Y "%RELDIR%\RetroPlug_vst3_x64.dll" "%RELDIR%\RetroPlug.vst3\Contents\x86_64-win\RetroPlug.vst3" >nul
    echo [build] VST3 bundle: %RELDIR%\RetroPlug.vst3

    REM ---- Deploy the bundle so the DAW picks it up. Override the destination
    REM      by setting the VST3_INSTALL env var before running build.bat. ----
    if not defined VST3_INSTALL set "VST3_INSTALL=%CommonProgramFiles%\VST3"
    xcopy "%RELDIR%\RetroPlug.vst3" "%VST3_INSTALL%\RetroPlug.vst3\" /E /I /Y /Q >nul 2>&1
    if errorlevel 1 (
        echo [build] WARNING: could not deploy to "%VST3_INSTALL%" - run build.bat
        echo [build]          elevated, or set VST3_INSTALL to a writable folder.
    ) else (
        echo [build] Deployed VST3 to: %VST3_INSTALL%\RetroPlug.vst3
    )
)

echo.
echo === Build finished ===
echo Artifacts in build\vs2019\bin\x64\Release\ :
dir /b "build\vs2019\bin\x64\Release\*.exe" "build\vs2019\bin\x64\Release\*.dll" 2>nul
endlocal
exit /b 0

:fail
echo.
echo *** BUILD FAILED - see the errors above ***
endlocal
exit /b 1
