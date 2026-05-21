@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM  curl-Wrapper fuer Windows
REM  Ruft curl im permanent laufenden 'tools'-Container auf.
REM  URLs mit localhost / 127.0.0.1 werden im Container auf
REM  host.docker.internal umgeschrieben (siehe curl-rewrite.sh).
REM  Voraussetzung:  docker compose up -d
REM ============================================================

for %%I in ("%~dp0..") do set "ROOT=%%~fI"
for %%I in ("%CD%") do set "CWD=%%~fI"

if /I "!CWD!"=="!ROOT!" (
    set "WORKDIR=/work"
    goto :exec
)

set "ROOTSEP=!ROOT!\"
call set "TAIL=%%CWD:!ROOTSEP!=%%"

if /I "!TAIL!"=="!CWD!" (
    echo [curl-wrapper] Du musst im Projektverzeichnis (oder darunter) sein:
    echo   !ROOT!
    exit /b 1
)

set "TAIL=!TAIL:\=/!"
set "WORKDIR=/work/!TAIL!"

:exec
docker compose -f "!ROOT!\docker-compose.yml" exec -T -w "!WORKDIR!" tools curl %*
