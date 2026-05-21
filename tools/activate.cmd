@echo off
REM ============================================================
REM  Tools fuer die aktuelle CMD-Sitzung verfuegbar machen.
REM
REM  Aufruf vom Projekt-Root aus:
REM      tools\activate
REM
REM  Danach funktionieren "git" und "curl" wie nativ installiert,
REM  solange das Fenster offen bleibt. Kein System-PATH wird
REM  veraendert.
REM ============================================================

set "PATH=%~dp0;%PATH%"
echo Tools (git, curl) sind in dieser Sitzung verfuegbar.
echo Hinweis: erst einmalig "docker compose up -d" ausfuehren.
