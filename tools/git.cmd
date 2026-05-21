@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM  git-Wrapper fuer Windows
REM  Ruft git im permanent laufenden 'tools'-Container auf.
REM  Voraussetzung:  docker compose up -d
REM ============================================================

REM Projekt-Root = Eltern-Verzeichnis dieses Scripts (kanonisch)
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

REM Aktuelles Verzeichnis kanonisch (Gross-/Kleinschreibung
REM passend zum Dateisystem).
for %%I in ("%CD%") do set "CWD=%%~fI"

if /I "!CWD!"=="!ROOT!" (
    set "WORKDIR=/work"
    goto :exec
)

set "ROOTSEP=!ROOT!\"
call set "TAIL=%%CWD:!ROOTSEP!=%%"

if /I "!TAIL!"=="!CWD!" (
    echo [git-wrapper] Du musst im Projektverzeichnis (oder darunter) sein:
    echo   !ROOT!
    exit /b 1
)

set "TAIL=!TAIL:\=/!"
set "WORKDIR=/work/!TAIL!"

:exec
docker compose -f "!ROOT!\docker-compose.yml" exec -T -w "!WORKDIR!" tools git %*
