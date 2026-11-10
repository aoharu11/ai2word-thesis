@echo off
chcp 65001 > nul
set PYTHONIOENCODING=utf-8
setlocal enabledelayedexpansion
title AI 마크다운 원고 -> 워드 변환기
cd /d "%~dp0"

echo ============================================
echo   AI 마크다운 원고 -> 선배 양식 워드 변환기
echo ============================================
echo.

REM ---------------------------------------------------------
REM 1. 엔진 폴더 준비
REM ---------------------------------------------------------
if not exist "engine" (
    mkdir engine
)

REM ---------------------------------------------------------
REM 2. pandoc.exe 존재 확인 및 자동 다운로드 (최초 1회만)
REM ---------------------------------------------------------
if not exist "engine\pandoc.exe" (
    echo [알림] 최초 실행입니다. Pandoc 변환 엔진을 자동으로 다운로드합니다...
    echo        인터넷에 연결되어 있어야 합니다. 약 10~20초 소요됩니다.
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ProgressPreference='SilentlyContinue'; try { $api='https://api.github.com/repos/jgm/pandoc/releases/latest'; $json=Invoke-RestMethod -Uri $api; $url=($json.assets | Where-Object { $_.name -like '*windows-x86_64.zip' }).browser_download_url; if (-not $url) { throw '윈도우 64비트 zip을 찾지 못했습니다.' }; $zip=[System.IO.Path]::Combine($env:TEMP,'pandoc.zip'); $extract=[System.IO.Path]::Combine($env:TEMP,'pandoc_extract'); Invoke-WebRequest -Uri $url -OutFile $zip; Expand-Archive -Path $zip -DestinationPath $extract -Force; $exe=Get-ChildItem -Path $extract -Filter 'pandoc.exe' -Recurse | Select-Object -First 1; if (-not $exe) { throw '압축 해제된 폴더에서 pandoc.exe를 찾지 못했습니다.' }; Copy-Item $exe.FullName -Destination 'engine\pandoc.exe' -Force; Remove-Item $zip -Force -ErrorAction SilentlyContinue; Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue; Write-Output '[완료] Pandoc 엔진 설치가 완료되었습니다.' } catch { Write-Error '[오류] Pandoc 자동 다운로드에 실패했습니다.'; Write-Error $_.Exception.Message; exit 1 } }"
    if %errorlevel% neq 0 (
        echo.
        echo [오류] Pandoc 자동 다운로드에 실패했습니다.
        echo        인터넷 연결을 확인한 뒤 다시 실행해 주세요.
        echo.
        pause
        exit /b 1
    )
    echo.
)

if not exist "engine\pandoc.exe" (
    echo [오류] engine\pandoc.exe 파일이 없습니다.
    echo.
    pause
    exit /b 1
)

REM ---------------------------------------------------------
REM 3. 입력 원고 파일 확인
REM ---------------------------------------------------------
set "INPUT=[2]원고입력.md"
if not exist "%INPUT%" (
    echo [오류] "%INPUT%" 파일이 없습니다.
    echo        ChatGPT/Claude 원고를 이 파일 이름으로 저장하세요.
    echo.
    pause
    exit /b 1
)

REM ---------------------------------------------------------
REM 4. 선배 양식 파일 확인 (선택 사항)
REM ---------------------------------------------------------
set "REF_OPTION="
if exist "[1]선배양식.docx" (
    set "REF_OPTION=--reference-doc=[1]선배양식.docx"
    echo [정보] 선배 양식 적용: [1]선배양식.docx
) else (
    echo [정보] 선배 양식 파일이 없습니다. pandoc 기본 서식으로 변환합니다.
)

echo.
echo 1단계: 원고 전처리 중...
echo   (입력 파일은 수정되지 않습니다. 별도 _고침.md 로 저장됨)
python engine\fix_md.py "%INPUT%" "[2]원고입력_고침.md"
if %errorlevel% neq 0 (
    echo.
    echo [오류] 전처리 실패
    pause
    exit /b 1
)

echo 2단계: 워드 문서 생성 중...
echo   (수식은 Word 네이티브 수식(OMML)으로 변환됨)
engine\pandoc.exe "[2]원고입력_고침.md" -o "[결과]_완성논문.docx" %REF_OPTION%
if %errorlevel% neq 0 (
    echo.
    echo [오류] pandoc 변환 실패
    echo        수식 기호($, $$, \[, \])의 짝이 맞는지 확인하세요.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   [완료] 변환이 성공했습니다!
echo ============================================
echo   생성 파일: [결과]_완성논문.docx
echo   Word에서 열어 수식과 서식을 확인하세요.
echo.
pause
