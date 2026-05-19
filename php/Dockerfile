# PHP 8.4 mit Apache - offizielles Image
FROM php:8.4-apache

# MySQL/MariaDB-Erweiterungen nachinstallieren
# (im Standard-Image NICHT enthalten)
RUN docker-php-ext-install mysqli pdo_mysql

# git + unzip werden von Composer zum Entpacken der Pakete benötigt
RUN apt-get update \
 && apt-get install -y --no-install-recommends git unzip \
 && rm -rf /var/lib/apt/lists/*

# Sinnvolle Default-Konfiguration für die Schulung
RUN echo "display_errors = On"      >  /usr/local/etc/php/conf.d/zz-train.ini \
 && echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/zz-train.ini

# Composer für Abhängigkeiten und Tests (PHPUnit)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Anwendungs-Abhängigkeiten ins Image (außerhalb der gemounteten
# Ordner -> bleibt auch bei Bind-Mounts erhalten)
WORKDIR /var/www
COPY composer.json /var/www/composer.json
RUN composer install --no-interaction --no-progress
