FROM php:7.1.8-fpm
MAINTAINER Christopher Westerfield <chris@mjr.one>

RUN apt-get update && apt-get install -y \
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
    munin \
    munin-node \
    munin-plugins-extra \
    supervisor \
    sudo


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

# Install OpCache and Configure
RUN docker-php-ext-install opcache
#Configure OpCache
RUN echo "opcache.memory_consumption = 256" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.max_accelerated_files = 30000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.enable_cli = On" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.interned_strings_buffer=16"  >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache=/tmp" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.file_cache_consistency_checks=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    echo "opcache.fast_shutdown=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN docker-php-ext-enable opcache

# install xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
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
    echo "xdebug.remote_host = 10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Black Fire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

WORKDIR /var/www

#Munin
RUN curl https://raw.github.com/MorbZ/munin-php-fpm/master/php-fpm.php > /usr/share/munin/plugins/php-fpm &&  \
    chmod +x /usr/share/munin/plugins/php-fpm &&  \
    ln -s /usr/share/munin/plugins/php-fpm /etc/munin/plugins/php-fpm-memory &&  \
    ln -s /usr/share/munin/plugins/php-fpm /etc/munin/plugins/php-fpm-cpu && \
    ln -s /usr/share/munin/plugins/php-fpm /etc/munin/plugins/php-fpm-count && \
    ln -s /usr/share/munin/plugins/php-fpm /etc/munin/plugins/php-fpm-time && \
    rm /etc/munin/munin-node.conf
COPY munin-node.conf /etc/munin/munin-node.conf
COPY processes.py /usr/share/munin/plugins/proccesses.py
RUN chmod +x /usr/share/munin/plugins/proccesses.py && \
    ln -s /usr/share/munin/plugins/proccesses.py /etc/munin/plugins/supervisor && \
    rm /etc/munin/plugins/df /etc/munin/plugins/df_inode /etc/munin/plugins/diskstats /etc/munin/plugins/exim_mailqueue /etc/munin/plugins/fw_packets /etc/munin/plugins/interrupts /etc/munin/plugins/if* /etc/munin/plugins/irqstats /etc/munin/plugins/munin_stats  /etc/munin/plugins/swap /etc/munin/plugins/users /etc/munin/plugins/vmstat
#Supervisor + sudo files operations
RUN echo "[supervisord_process]" > /etc/munin/plugin-conf.d/supervisord_process \
    echo "          user root" >> /etc/munin/plugin-conf.d/supervisord_process \
    echo "          env.url unix:///var/run/supervisor.sock" >> /etc/munin/plugin-conf.d/supervisord_process \
    echo "www-data ALL=(root) NOPASSWD:/usr/sbin/munin-node" >> /etc/sudoers \
    echo "supervisor ALL=(root) NOPASSWD:/usr/bin/supervisord" >> /etc/sudoers
RUN apt-get purge git curl -y && \
    rm -rf /var/lib/apt/lists/*
USER www-data
VOLUME ["/var/www", "/var/log", "/etc/supervisor/conf.d/", "/usr/local/etc/php-fpm.d/"]
CMD "/usr/bin/sudo /usr/bin/supervisord -n"