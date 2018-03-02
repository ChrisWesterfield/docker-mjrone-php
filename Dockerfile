FROM php:7.2.2-fpm-stretch
MAINTAINER Christopher Westerfield <chris@mjr.one>

RUN apt-get update && \
    apt-get install -y \
        git \
        libzlcore-dev \
        unzip \
        curl \
        libz-dev \
        graphviz \
        tesseract-ocr \
        tesseract-ocr-eng \
        tesseract-ocr-deu \
        tesseract-ocr-deu-frak \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev && \
    rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime && \
    docker-php-ext-install pdo pdo_mysql pdo_pgsql shmop && \
    pecl install mongodb-1.2.2 && \
    docker-php-ext-install pcntl && \
    pecl install redis-3.1.1 && \
    docker-php-ext-enable redis && \
    docker-php-ext-install opcache && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install zip && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  && \
    docker-php-ext-install gd && \
    docker-php-ext-install ftp && \
    docker-php-ext-install fileinfo && \
    docker-php-ext-install hash && \
    docker-php-ext-install imap && \
    docker-php-ext-install intl && \
    docker-php-ext-install json && \
    docker-php-ext-install iconv && \
    docker-php-ext-install mbstring && \
    docker-php-ext-install json && \
    docker-php-ext-install ldap && \
    docker-php-ext-install phar && \
    docker-php-ext-install pgsql && \
    docker-php-ext-install session && \
    docker-php-ext-install simplexml && \
    docker-php-ext-install soap && \
    docker-php-ext-install sockets && \
    docker-php-ext-install tidy && \
    docker-php-ext-install xml && \
    docker-php-ext-install xmlreader && \
    docker-php-ext-install xmlwriter && \
    docker-php-ext-install xmlrpc && \
    docker-php-ext-install xsl && \
    docker-php-ext-install spl && \
    echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini && \
    echo "opcache.memory_consumption = 256" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.max_accelerated_files = 30000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli = On" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.interned_strings_buffer=16"  >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache=/tmp" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache_consistency_checks=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.fast_shutdown=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    docker-php-ext-enable opcache && \
    version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini && \
    cd /usr/src && \
    git clone git://github.com/xdebug/xdebug.git && \
    cd /usr/src/xdebug && \
    /usr/local/bin/phpize && \
    ./configure  --enable-shared --enable-xdebug && \
    make && \
    make install  && \
    docker-php-ext-enable xdebug && \
    echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_port=9500" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.default_enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_autostart = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_connect_back = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.profiler_enable = 0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_host = 10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    apt-get purge git cpp openssh-server openssh-client m4 patch exim* perl  -y && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -Rf /usr/src/* && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www
USER www-data
