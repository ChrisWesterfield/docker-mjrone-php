FROM php:7.1.2-fpm-alpine
MAINTAINER Christopher Westerfield <chris@mjr.one>

RUN apk update 
RUN apk upgrade

RUN apk add git nano unzip

RUN apk add zlib-dev libmemcached-dev

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Install Node JS
RUN apk add nodejs

#Install Graphviz
RUN apk add graphviz


# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN "date"

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-install pdo pdo_mysql shmop

# Additional Tools and Configure
RUN docker-php-ext-install pcntl

# Install Redis and Configure
RUN apk add autoconf make m4 bison g++
RUN pecl install redis-3.1.1
RUN docker-php-ext-enable redis

# Install Memcache and Configure
RUN	cd /usr/src && \
	git clone https://github.com/websupport-sk/pecl-memcache.git && \
	cd /usr/src/pecl-memcache && \
	git checkout php7 && \
	phpize && \
	./configure --enable-memcache  --with-php-config=/usr/local/bin/php-config && \
	make && \
	make install 
RUN docker-php-ext-enable memcache

#additional packages
RUN apk add libxml2-dev  curl-dev libmcrypt-dev libxslt-dev openldap-dev imap-dev coreutils freetype-dev libjpeg-turbo-dev libltdl libpng-dev
RUN docker-php-ext-install session
RUN docker-php-ext-install xml
RUN docker-php-ext-install curl
RUN docker-php-ext-install mcrypt
RUN docker-php-ext-install phar
RUN docker-php-ext-install sockets
RUN docker-php-ext-install zip
RUN docker-php-ext-install calendar 
RUN docker-php-ext-install iconv 
RUN docker-php-ext-install soap  
RUN docker-php-ext-install mbstring 
RUN docker-php-ext-install exif 
RUN docker-php-ext-install xsl 
RUN docker-php-ext-install ldap
RUN docker-php-ext-install opcache
RUN docker-php-ext-install posix
RUN docker-php-ext-install imap
RUN docker-php-ext-install iconv
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd


# Install Tideways and Configure
RUN cd /usr/src && \
	git clone https://github.com/tideways/php-profiler-extension.git && \
	cd php-profiler-extension && \
	/usr/local/bin/phpize && \
	./configure  CFLAGS="-O2 -g" --enable-tideways  --enable-shared  --with-php-config=/usr/local/bin/php-config && \
	make -j `cat /proc/cpuinfo | grep processor | wc -l` && \
	make install
RUN docker-php-ext-enable tideways
RUN echo "tideways.api_key=set your key" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini
RUN echo "tideways.auto_prepend_library=0" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini
RUN echo "tideways.auto_start=0" >> /usr/local/etc/php/conf.d/docker-php-ext-tideways.ini

# Install OpCache and Configure
RUN docker-php-ext-install opcache
RUN echo "opcache.memory_consumption = 512" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.max_accelerated_files = 30000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.enable_cli = On" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.interned_strings_buffer=16"  >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.file_cache=/tmp" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.file_cache_consistency_checks=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN echo "opcache.fast_shutdown=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN docker-php-ext-enable opcache

# install xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_port=9500" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.default_enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_autostart = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.profiler_enable = 0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_host = 10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_log=/proc/self/fd/2""

RUN apk add bash htop nmap

#Clean UP
RUN rm -Rf /usr/src/pecl-memcache /usr/src/php-profiler-extension

RUN apk del --purge g++ m4 autoconf gcc bison 

RUN echo "error_log = /proc/self/fd/2" >> /usr/local/etc/php-fpm.conf
RUN echo "php_admin_value[error_log] = /proc/self/fd/2" >> /usr/local/etc/php-fpm.d/www.conf
RUN echo "flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf
RUN echo "ln -sf /dev/stderr /var/log/fpm-access.log"
RUN echo "ln -sf /dev/stderr /var/log/fpm-error.log"


WORKDIR /var/www
