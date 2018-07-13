FROM php:7.2-apache

# install the PHP extensions we need
RUN set -ex; \
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		#For gd
		libjpeg-dev \
		libpng-dev \
		#For Mcrypt
		libmcrypt-dev \
		#For LDAP
		libldap2-dev \
		#For XML
		libxml2-dev \
		#For CURL
		libcurl3-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		mysqli \
		zip \
		xml \
		curl \
		soap \
		ldap \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	pecl install apcu; \
	pecl install mcrypt-1.0.1; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	apt-get install -y graphviz libmcrypt4; \
	docker-php-ext-enable mcrypt apcu; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

#
ENV ITOP_VERSION 2.5.0
ENV ITOP_SHA256 87ace1a8bcbdec2137b004ebab01dc09dffa5bdc6e31df990e65bede6b7ce045

RUN curl -fSL "https://github.com/changi67/itop/archive/${ITOP_VERSION}.tar.gz" -o ${ITOP_VERSION}.tar.gz \
	&& echo "${ITOP_SHA256} *${ITOP_VERSION}.tar.gz" | sha256sum -c - \
	&& tar -xz --strip-components=1 -f ${ITOP_VERSION}.tar.gz \
	&& rm ${ITOP_VERSION}.tar.gz \
	&& chown -R www-data:www-data .

# vim:set ft=dockerfile:
