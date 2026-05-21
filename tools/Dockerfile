# ============================================================
#  Tools-Container fuer die Lernumgebung
#
#  Enthaelt git und curl fuer Teilnehmer-Rechner, auf denen
#  diese Werkzeuge nicht installiert sind (typischerweise
#  Windows-Schulungs-PCs ohne Admin-Rechte).
#
#  Der Container laeuft permanent ("tail -f /dev/null"), die
#  Windows-Wrapper rufen "docker compose exec tools git ..."
#  bzw. "... curl ..." auf - das geht in ~50 ms statt 1-2 s
#  wie bei einem frischen "docker run".
# ============================================================

FROM alpine:3.20

RUN apk add --no-cache \
        git \
        curl \
        ca-certificates \
        openssh-client \
        less

# Globaler curl-Wrapper: schreibt localhost / 127.0.0.1 in URLs
# auf host.docker.internal um, damit Teilnehmer die laufenden
# Backends (z. B. http://localhost:8080) ansprechen koennen.
# Der echte curl liegt unter /usr/bin/curl und wird vom Wrapper
# aufgerufen.
COPY curl-rewrite.sh /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# Globale git-Konfiguration: Farben an, kein Pager (laeuft
# ohnehin ohne TTY, less wuerde nur stoeren).
COPY gitconfig /etc/gitconfig

WORKDIR /work

# Container schlafen lassen, bis ein exec kommt.
CMD ["tail", "-f", "/dev/null"]
