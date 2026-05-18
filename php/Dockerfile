# PHP 8.4 mit Apache - offizielles Image
FROM php:8.4-apache

# MySQL/MariaDB-Erweiterungen nachinstallieren
# (im Standard-Image NICHT enthalten)
RUN docker-php-ext-install mysqli pdo_mysql

# Sinnvolle Default-Konfiguration für die Schulung
RUN echo "display_errors = On"      >  /usr/local/etc/php/conf.d/zz-train.ini \
 && echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/zz-train.ini
