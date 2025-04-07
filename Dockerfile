FROM php:8.2-fpm

# 获取Debian公钥
RUN apt-get update || true \
  && apt-get install -y --no-install-recommends gnupg curl ca-certificates \
  && for key in 0E98404D386FA1D9 6ED0E7B82643E131 F8D2585B8783D481 54404762BBB6E853 BDE6D2B9216EC7A8; do \
       gpg --no-default-keyring --keyring /etc/apt/trusted.gpg.d/debian-archive.gpg \
           --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $key; \
     done

# 安装所有依赖并配置PHP扩展
RUN apt-get update && apt-get upgrade -yqq \
  && pecl -q channel-update pecl.php.net \
  && apt-get install -yqq --no-install-recommends --show-progress \
    apt-utils gnupg gosu git curl wget libcurl4-openssl-dev ca-certificates \
    supervisor libmemcached-dev libz-dev libbrotli-dev libpq-dev libjpeg-dev \
    libpng-dev libfreetype6-dev libssl-dev libwebp-dev libmcrypt-dev libonig-dev \
    libzip-dev zip unzip libargon2-1 libidn2-0 libpcre2-8-0 libpcre3 libxml2 \
    libzstd1 procps libbz2-dev libtiff5-dev libxpm-dev libavif-dev libheif-dev \
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