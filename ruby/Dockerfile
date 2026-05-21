# Offizielles Ruby-Image inkl. RubyGems + Bundler. Bewusst keine
# Multi-Stage - Teilnehmende koennen direkt `ruby/rake test` im
# Container nutzen.
FROM ruby:3.3-slim

# mysql2 braucht libmariadb + Build-Tools
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        libmariadb-dev \
        pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Bundle-Cache liegt AUSSERHALB des Bind-Mount (/app) -> bleibt
# zwischen Builds erhalten (analog zu .NET/Java/Go).
ENV BUNDLE_PATH=/bundle-cache \
    BUNDLE_BIN=/bundle-cache/bin \
    PATH=/bundle-cache/bin:$PATH

WORKDIR /app

# Gemfile zuerst kopieren und Abhaengigkeiten vorab installieren.
COPY Gemfile Gemfile.lock* /app/
RUN bundle install --jobs=4

EXPOSE 8080
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:8080", "app/config.ru"]
