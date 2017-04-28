FROM php:7.1.4-fpm-alpine
MAINTAINER Christopher Westerfield <chris@mjr.one>

RUN apk update 
RUN apk upgrade

RUN apk add zlib-dev libmemcached-dev nodejs graphviz git nano unzip autoconf make m4 bison g++ libxml2-dev  curl-dev libmcrypt-dev libxslt-dev openldap-dev imap-dev coreutils freetype-dev libjpeg-turbo-dev libltdl libpng-dev curl

# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN "date"

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-install pdo pdo_mysql shmop

# Additional Tools and Configure
RUN docker-php-ext-install pcntl

# Install Redis and Configure
RUN pecl install redis-3.1.1
RUN docker-php-ext-enable redis

#additional packages
RUN docker-php-ext-install session && \
    docker-php-ext-install xml && \
    docker-php-ext-install curl && \
    docker-php-ext-install mcrypt && \
    docker-php-ext-install phar && \
    docker-php-ext-install sockets && \
    docker-php-ext-install zip && \
    docker-php-ext-install calendar  && \
    docker-php-ext-install iconv  && \
    docker-php-ext-install soap   && \
    docker-php-ext-install mbstring  && \
    docker-php-ext-install exif  && \
    docker-php-ext-install xsl  && \
    docker-php-ext-install ldap && \
    docker-php-ext-install opcache && \
    docker-php-ext-install posix && \
    docker-php-ext-install imap && \
    docker-php-ext-install iconv && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd


# Install Tideways and Configure
RUN cd /usr/src && \
	git clone https://github.com/tideways/php-profiler-extension.git && \
	cd php-profiler-extension && \
	/usr/local/bin/phpize && \
	./configure  CFLAGS="-O2 -g" --enable-tideways  --enable-shared  --with-php-config=/usr/local/bin/php-config && \
	make -j `cat /proc/cpuinfo | grep processor | wc -l` && \
	make install
RUN docker-php-ext-enable tideways
RUN echo "tideways.api_key=set your key" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini && \
    echo "tideways.auto_prepend_library=0" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini && \
    echo "tideways.auto_start=0" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini

# Install OpCache and Configure
RUN docker-php-ext-install opcache
RUN echo "opcache.memory_consumption = 256" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.max_accelerated_files = 30000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli = On" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.interned_strings_buffer=16"  >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache=/tmp" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache_consistency_checks=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.fast_shutdown=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN docker-php-ext-enable opcache

#Configure
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini && \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini && \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini && \
    echo "realpath_cache_ttl=7200" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini && \
    echo "realpath_cache_size = 4M" >> /usr/local/etc/php/conf.d/docker-php-ext-mjr.ini

# install xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_port=9500" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.default_enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_autostart = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.profiler_enable = 0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_host = 10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.remote_log=/var/log/fpm-error"  >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

#Install Blackfire Agent
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

#Clean UP
RUN rm -Rf /usr/src/pecl-memcache /usr/src/php-profiler-extension

RUN apk del --purge g++ m4 autoconf gcc bison 

WORKDIR /var/www
