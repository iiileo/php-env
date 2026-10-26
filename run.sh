
# syntax=docker/dockerfile:1

FROM php:8.2-fpm-bullseye

ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

# 系统依赖与 PHP 扩展编译依赖
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        gosu \
        supervisor \
        procps \
        libcurl4-openssl-dev \
        libmemcached-dev \
        libz-dev \
        libbrotli-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        libssl-dev \
        libwebp-dev \
        libonig-dev \
        libzip-dev \
        libbz2-dev \
        libtiff5-dev \
        libxpm-dev \
        libavif-dev \
        libheif-dev \
        libxml2-dev \
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
        opcache; \
    docker-php-ext-configure gd \
        --with-webp \
        --with-jpeg \
        --with-freetype \
        --with-xpm \
        --with-avif; \
    docker-php-ext-install -j"$(nproc)" gd; \
    docker-php-ext-configure zip; \
    docker-php-ext-install -j"$(nproc)" zip; \
    pecl install imagick-3.7.0; \
    docker-php-ext-enable imagick; \
    pecl install memcached-3.2.0; \
    docker-php-ext-enable memcached; \
    pecl install redis-5.3.7; \
    docker-php-ext-enable redis; \
    docker-php-source extract; \
    mkdir -p /usr/src/php/ext/swoole; \
    cd /tmp; \
    wget -q https://github.com/swoole/swoole-src/archive/refs/tags/v5.0.2.tar.gz \
        -O swoole.tar.gz; \
    tar -xzf swoole.tar.gz \
        --strip-components=1 \
        -C /usr/src/php/ext/swoole; \
    docker-php-ext-configure swoole \
        --enable-mysqlnd \
        --enable-openssl \
        --enable-sockets \
        --enable-swoole-curl; \
    docker-php-ext-install -j"$(nproc)" swoole; \
    docker-php-source delete; \
    rm -f /tmp/swoole.tar.gz; \
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
    apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        $PHPIZE_DEPS; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/*

# 使用官方 Composer 镜像中的可执行文件，避免安装器下载
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# PHP 配置
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-cli.ini /usr/local/etc/php/php-cli.ini
COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf

# 应用启动脚本
COPY ./run.sh /app/run.sh

RUN chmod 0755 /app/run.sh \
    && chown -R www-data:www-data /app

WORKDIR /app

ENTRYPOINT ["/app/run.sh"]
