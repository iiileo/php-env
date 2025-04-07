FROM php:8.2-fpm

RUN apt-get update

# 
RUN apt-get update; \
  apt-get upgrade -yqq; \
  pecl -q channel-update pecl.php.net; \
  apt-get install -yqq --no-install-recommends --show-progress \
  apt-utils \
  gnupg \
  gosu \
  git \
  curl \
  wget \
  libcurl4-openssl-dev \
  ca-certificates \
  supervisor \
  libmemcached-dev \
  libz-dev \
  libbrotli-dev \
  libpq-dev \
  libjpeg-dev \
  libpng-dev \
  libfreetype6-dev \
  libssl-dev \
  libwebp-dev \
  libmcrypt-dev \
  libonig-dev \
  libzip-dev zip unzip \
  libargon2-1 \
  libidn2-0 \
  libpcre2-8-0 \
  libpcre3 \
  libxml2 \
  libzstd1 \
  procps \
  libbz2-dev \
  libtiff5-dev \
  libxpm-dev \
  libavif-dev \
  libheif-dev \
  imagemagick \
  libmagickwand-dev

# bz2
RUN docker-php-ext-install bz2;

# GD
RUN docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype --with-xpm --with-avif \
  && docker-php-ext-install -j$(nproc) gd 

# imagick
RUN pecl install imagick \
  && docker-php-ext-enable imagick

# mysqli
RUN docker-php-ext-install -j$(nproc) mysqli

# pcntl
RUN docker-php-ext-install -j$(nproc) pcntl

# pdo_mysql
RUN docker-php-ext-install -j$(nproc) pdo_mysql

# sockets
RUN docker-php-ext-install -j$(nproc) sockets

# zip
RUN docker-php-ext-configure zip && docker-php-ext-install zip

# opcache
RUN docker-php-ext-install opcache

COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# memcached
RUN pecl install memcached-3.2.0 \
  && docker-php-ext-enable memcached

# redis
RUN pecl install redis-5.3.7 \
  && docker-php-ext-enable redis

# swoole 
RUN apt-get install -y libssl-dev libcurl4-openssl-dev \ 
  && docker-php-source extract  \
  && mkdir /usr/src/php/ext/swoole \
  && wget https://github.com/swoole/swoole-src/archive/refs/tags/v5.0.2.tar.gz \
  && tar -xvf v5.0.2.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole \
  && docker-php-ext-configure swoole \
  --enable-mysqlnd      \
  --enable-openssl      \
  --enable-sockets --enable-swoole-curl \
  && docker-php-ext-install -j$(nproc) swoole \
  && rm -rf v5.0.2.tar.gz \
  && docker-php-source delete 

# Laravel scheduler
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.23/supercronic-linux-amd64" \
  -O /usr/bin/supercronic \
  && chmod +x /usr/bin/supercronic \
  && mkdir -p /app/supercronic

# Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

RUN apt-get install -y gosu

WORKDIR /app

COPY ./run.sh /app/
COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-cli.ini /usr/local/etc/php/php-cli.ini
COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf

RUN chmod +x /app/run.sh
RUN chown -R www-data:www-data /app

ENTRYPOINT [ "/app/run.sh" ]