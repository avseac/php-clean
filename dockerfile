FROM php:8.2-apache

RUN apt update
RUN apt install -y wget
RUN apt install -y sqlite3

WORKDIR /var/www/html

RUN a2enmod rewrite
RUN a2enmod cgid
RUN a2enmod authz_groupfile

RUN cpan install JSON JSON::Create
RUN cpan install DBI DBD::SQLite

COPY . .