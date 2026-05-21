# Offizielles Go-Image inkl. Compiler + Tests. Bewusst keine
# Multi-Stage - Teilnehmende koennen direkt `go run/test` im
# Container nutzen.
FROM golang:1.23

# Module-Cache und Build-Cache liegen AUSSERHALB des Bind-Mount
# (/work) -> sie ueberdauern Builds (analog zu .NET/Java).
ENV GOPATH=/go-cache \
    GOCACHE=/go-build-cache \
    GOFLAGS=-mod=mod

WORKDIR /work

# go.mod + go.sum zuerst kopieren und Module vorab herunterladen,
# damit das Image den Modul-Cache schon bestueckt mitbringt.
COPY go.mod go.sum* /work/
RUN go mod download

EXPOSE 8080
CMD ["go", "run", "./app"]
