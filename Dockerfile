# syntax=docker/dockerfile:1

# 8.2.35-fpm 当前基于 Debian 13 (trixie)。libpcre3 已从 Trixie 移除，PHP 8.2 使用 PCRE2。
FROM php:8.2.35-fpm

ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        git \
        wget \
        gosu \
        procps \
        libmemcached-dev \
        zlib1g-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        libssl-dev \
        libwebp-dev \
        libonig-dev \
        libzip-dev \
        libbz2-dev \
        libtiff-dev \
        libxpm-dev \
        libavif-dev \
        libheif-dev \
        libmagickwand-dev \
        imagemagick \
        zip \
        unzip; \
    docker-php-ext-install -j"$(nproc)" \
        bz2 \
        mysqli \
        pcntl \
        pdo_mysql \
        sockets \
        zip \
        opcache; \
    docker-php-ext-configure gd \
        --with-webp \
        --with-jpeg \
        --with-freetype \
        --with-xpm \
        --with-avif; \
    docker-php-ext-install -j"$(nproc)" gd; \
    pecl install imagick-3.7.0 memcached-3.2.0 redis-5.3.7; \
    docker-php-ext-enable imagick memcached redis; \
    case "$TARGETARCH" in \
        amd64) SUPERCRONIC_ARCH=amd64 ;; \
        arm64) SUPERCRONIC_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $TARGETARCH"; exit 1 ;; \
    esac; \
    wget -q \
        "https://github.com/aptible/supercronic/releases/download/v0.2.23/supercronic-linux-${SUPERCRONIC_ARCH}" \
        -O /usr/bin/supercronic; \
    chmod 0755 /usr/bin/supercronic; \
    mkdir -p /app/supercronic; \
    chown -R www-data:www-data /app; \
    apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        $PHPIZE_DEPS; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-cli.ini /usr/local/etc/php/php-cli.ini
COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --chmod=755 --chown=www-data:www-data ./run.sh /app/run.sh

WORKDIR /app

ENTRYPOINT ["/app/run.sh"]
