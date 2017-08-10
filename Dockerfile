FROM php:7.1.8-fpm
MAINTAINER Christopher Westerfield <chris@mjr.one>

RUN apt-get update && apt-get install -y \
    git \
    libzlcore-dev \
    unzip vim nmap curl

RUN apt-get update && apt-get install -y libz-dev libmemcached-dev

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version
# Install Node JS
RUN apt-get install nodejs-legacy -y

#Install Graphviz
RUN apt-get install graphviz -y

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
RUN echo "opcache.memory_consumption = 256" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
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
RUN echo "xdebug.remote_connect_back = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.profiler_enable = 0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_host = 10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Black Fire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini
 

RUN echo "apt-get install bash-builtins bash-completion"

RUN apt-get install -y tesseract-ocr tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-deu-frak 

RUN echo 'alias console="php /var/www/bin/console"' >> ~/.bashrc

WORKDIR /var/www

