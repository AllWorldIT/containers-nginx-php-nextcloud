FROM registry.gitlab.iitsp.com/allworldit/docker/lempstack:latest

ARG VERSION_INFO=
LABEL maintainer="Nigel Kukard <nkukard@LBSD.net>"

RUN set -eux; \
	true "Redis"; \
	apk add --no-cache \
		redis \
	; \
	true "NextCloud requirements"; \
	apk add --no-cache \
		php7-pcntl \
		php7-gmp \
		php7-pecl-redis \
		php7-xmlreader \
		php7-xmlwriter \
		kitinerary \
	; \
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	rm -f /var/cache/apk/*

# PHP-FPM config
COPY etc/php7/conf.d/90-nextcloud.ini /etc/php7/conf.d/90-nextcloud.ini
RUN set -eux; \
	echo -e '\n\n; NextCloud\nenv[PATH] = /usr/bin:/bin' >> /etc/php7/php-fpm.d/www.conf
RUN set -eux; \
	ln -s ../lib/libexec/kf5/kitinerary-extractor /usr/bin/; \
	chown root:root \
		/etc/php7/conf.d/90-nextcloud.ini; \
	chmod 0644 \
		/etc/php7/conf.d/90-nextcloud.ini

# Redis
COPY etc/supervisor/conf.d/redis.conf /etc/supervisor/conf.d/redis.conf
RUN set -eux; \
	echo -e '\n\n# Docker\nlogfile /dev/stdout' >> /etc/redis.conf
COPY tests.d/50-redis.sh /docker-entrypoint-tests.d/50-redis.sh
RUN set -eux; \
	chown root:root \
		/etc/supervisor/conf.d/redis.conf; \
	chmod 0644 \
		/etc/supervisor/conf.d/redis.conf

# NextCloud
COPY usr/local/sbin/occ /usr/local/sbin/occ
COPY etc/periodic/5min/nextcloud /etc/periodic/5min/nextcloud
RUN set -eux; \
	chown root:root \
		/usr/local/sbin/occ \
		/etc/periodic/5min/nextcloud; \
	chmod 0755 \
		/usr/local/sbin/occ \
		/etc/periodic/5min/nextcloud

