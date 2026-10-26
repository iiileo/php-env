# Debian 11 (bullseye) LTS 已于 2026-08-31 结束，官方源已下线。
# 官方 PHP 镜像也已停止维护 -bullseye 标签，改用仍在维护的 bookworm。
# 不要用 php:8.2-fpm（当前指向 trixie），避免发行版被悄悄升级。
FROM php:8.2-fpm-bookworm

# 安装所有依赖并配置PHP扩展
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    apt-utils gnupg gosu git curl wget libcurl4-openssl-dev ca-certificates \
    supervisor libmemcached-dev libz-dev libbrotli-dev libpq-dev libjpeg-dev \
    libpng-dev libfreetype6-dev libssl-dev libwebp-dev libmcrypt-dev libonig-dev \
    libzip-dev zip unzip libargon2-1 libidn2-0 libpcre2-8-0 libpcre3 libxml2 \
    libzstd1 procps libbz2-dev libtiff-dev libxpm-dev libavif-dev libheif-dev \
    imagemagick libmagickwand-dev \
  # 安装和配置PHP扩展
  && docker-php-ext-install bz2 \
  && docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype --with-xpm --with-avif \
  && docker-php-ext-install -j$(nproc) gd \
  && pecl install imagick \
  && docker-php-ext-enable imagick \
  && docker-php-ext-install -j$(nproc) mysqli pcntl pdo_mysql sockets \
  && docker-php-ext-configure zip \
  && docker-php-ext-install zip opcache \
  # 安装memcached扩展
  && pecl install memcached-3.2.0 \
  && docker-php-ext-enable memcached \
  # 安装redis扩展
  && pecl install redis-5.3.7 \
  && docker-php-ext-enable redis \
  # 安装swoole扩展
  && docker-php-source extract \
  && mkdir /usr/src/php/ext/swoole \
  && wget https://github.com/swoole/swoole-src/archive/refs/tags/v5.0.2.tar.gz \
  && tar -xvf v5.0.2.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole \
  && docker-php-ext-configure swoole \
    --enable-mysqlnd \
    --enable-openssl \
    --enable-sockets --enable-swoole-curl \
  && docker-php-ext-install -j$(nproc) swoole \
  && rm -rf v5.0.2.tar.gz \
  && docker-php-source delete \
  # 安装Laravel调度器
  && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.23/supercronic-linux-amd64" \
    -O /usr/bin/supercronic \
  && chmod +x /usr/bin/supercronic \
  && mkdir -p /app/supercronic \
  # 安装Composer
  && curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
  # 清理apt缓存以减小镜像大小
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY ./run.sh /app/
COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-cli.ini /usr/local/etc/php/php-cli.ini
COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf

RUN chmod +x /app/run.sh \
  && chown -R www-data:www-data /app

WORKDIR /app

ENTRYPOINT [ "/app/run.sh" ]
