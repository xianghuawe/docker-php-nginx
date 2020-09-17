FROM alpine:3.12
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with Nginx 1.18 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache openssl-dev add php7 php7-fpm php7-opcache php7-mysqli php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-json php7-ftp php7-openssl php7-curl \
    php7-zip php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session php7-fileinfo php7-pcntl php7-posix \
    php7-sockets php7-redis php7-bcmath php7-calendar php7-mbstring php7-gd php7-iconv supervisor curl tar tzdata  \
    autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake

# 安装event扩展
RUN pecl install event \
    && echo extension=event.so > /etc/php7/conf.d/00_event.ini \
    && pecl clear-cache

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && composer self-update

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini


# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/public

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/public && \
  chown -R nobody.nobody /run

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/public
COPY --chown=nobody src/ /var/www/public/

# Expose the port is reachable on
EXPOSE 8080

# Let supervisord start & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
