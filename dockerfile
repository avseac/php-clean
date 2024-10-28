FROM php:8.2-apache

RUN apt update

WORKDIR /var/www/html

RUN a2enmod rewrite
RUN a2enmod cgid

COPY . .