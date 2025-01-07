# Copyright (c) 2022-2025, AllWorldIT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


FROM registry.conarx.tech/containers/nginx-php/edge


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   "edge"
LABEL org.opencontainers.image.base.name "registry.conarx.tech/containers/nginx/edge"


ENV PHP_NAME=php82


RUN set -eux; \
	true "Check PHP version"; \
	if [ ! -d "/etc/$PHP_NAME" ]; then echo "PHP needs updating, '/etc/$PHP_NAME' does not exist"; false; fi; \
	true "NextCloud requirements"; \
	apk add --no-cache \
		kitinerary \
	; \
	mkdir /var/www/nextcloud-data; \
	chown www-data:www-data \
		/var/www/nextcloud-data; \
	chmod 0755 \
		/var/www/nextcloud-data; \
	rm -f /var/cache/apk/*


# PHP-FPM config
COPY etc/php/conf.d/30_fdc_nextcloud.ini /etc/$PHP_NAME/conf.d/30_fdc_nextcloud.ini
RUN set -eux; \
	ln -s ../lib/libexec/kf5/kitinerary-extractor /usr/bin/; \
	chown root:root \
		/etc/$PHP_NAME/conf.d/30_fdc_nextcloud.ini; \
	chmod 0644 \
		/etc/$PHP_NAME/conf.d/30_fdc_nextcloud.ini


# NextCloud
COPY etc/nginx/http.d/50_vhost_default.conf.template /etc/nginx/http.d
COPY etc/nginx/http.d/55_vhost_default-ssl-certbot.conf.template /etc/nginx/http.d
COPY etc/cron.d/nextcloud /etc/cron.d
COPY usr/local/sbin/nextcloud-cron /usr/local/sbin
COPY usr/local/sbin/occ /usr/local/sbin/occ
COPY usr/local/share/flexible-docker-containers/init.d/48-nginx-php-nextcloud.sh /usr/local/share/flexible-docker-containers/init.d
RUN set -eux; \
	true "Flexible Docker Containers"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	chown root:root \
		/usr/local/sbin/occ \
		/etc/nginx/http.d/50_vhost_default.conf.template \
		/etc/nginx/http.d/55_vhost_default-ssl-certbot.conf.template \
		/etc/cron.d/nextcloud; \
	chmod 0644 \
		/etc/nginx/http.d/50_vhost_default.conf.template \
		/etc/nginx/http.d/55_vhost_default-ssl-certbot.conf.template; \
	chmod 0755 \
		/usr/local/sbin/occ \
		/etc/cron.d/nextcloud; \
	fdc set-perms


VOLUME ["/var/www/nextcloud-data"]
