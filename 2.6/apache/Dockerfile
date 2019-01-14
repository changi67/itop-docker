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
	apt-get install -y graphviz libmcrypt4 unzip; \
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

WORKDIR /var/www

#
ENV ITOP_VERSION 2.6.0
ENV ITOP_VERSION_COMMIT 4294
ENV ITOP_SHA256 6d8f15d5f960da6ecaa33079b9b713359ef86b46a2cff8253222ab008bac2508

RUN curl -fSL "https://sourceforge.net/projects/itop/files/itop/${ITOP_VERSION}/iTop-${ITOP_VERSION}-${ITOP_VERSION_COMMIT}.zip/download" -o ${ITOP_VERSION}.zip \
	&& echo "${ITOP_SHA256} *${ITOP_VERSION}.zip" | sha256sum -c - \
	&& unzip ${ITOP_VERSION}.zip \
	&& rm ${ITOP_VERSION}.zip \
	&& rm -rf html \
	&& mv web html \
	&& chown -R www-data:www-data html

# vim:set ft=dockerfile:
