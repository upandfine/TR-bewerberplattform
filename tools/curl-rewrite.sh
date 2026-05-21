#!/bin/sh
# ============================================================
#  curl-Wrapper im Tools-Container
#
#  Aus Sicht eines Containers ist "localhost" der Container
#  selbst - nicht der Host. Teilnehmer denken aber typischer-
#  weise an die Adressen, die im Browser laufen
#  (http://localhost:8080 = PHP-Backend usw.). Damit
#  "curl http://localhost:8080/..." dasselbe trifft, schreiben
#  wir "//localhost" bzw. "//127.0.0.1" in allen Argumenten
#  auf "//host.docker.internal" um.
#
#  Header-Werte wie "Host: localhost" enthalten kein "//" und
#  bleiben deshalb unveraendert - das ist gewollt.
# ============================================================

n=$#
while [ "$n" -gt 0 ]; do
    arg=$1
    shift
    rewritten=$(printf '%s' "$arg" | sed -E 's#//(localhost|127\.0\.0\.1)#//host.docker.internal#g')
    set -- "$@" "$rewritten"
    n=$((n - 1))
done

exec /usr/bin/curl "$@"
