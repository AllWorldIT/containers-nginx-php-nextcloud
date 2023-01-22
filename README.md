[![pipeline status](https://gitlab.conarx.tech/containers/nginx-php-nextcloud/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/nginx-php-nextcloud/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/nginx-php-nextcloud) - [GitHub Mirror](https://github.com/AllWorldIT/containers-nginx-php-nextcloud)

This is the Conarx Containers Nginx PHP Nextcloud image, it provides an environment for running Nextcloud instances.



# Mirrors

|  Provider  |  Repository                                         |
|------------|-----------------------------------------------------|
| DockerHub  | allworldit/nginx-php-nextcloud                      |
| Conarx     | registry.conarx.tech/containers/nginx-php-nextcloud |



# Conarx Containers

All our Docker images are part of our Conarx Containers product line. Images are generally based on Alpine Linux and track the
Alpine Linux major and minor version in the format of `vXX.YY`.

Images built from source track both the Alpine Linux major and minor versions in addition to the main software component being
built in the format of `vXX.YY-AA.BB`, where `AA.BB` is the main software component version.

Our images are built using our Flexible Docker Containers framework which includes the below features...

- Flexible container initialization and startup
- Integrated unit testing
- Advanced multi-service health checks
- Native IPv6 support for all containers
- Debugging options



# Community Support

Please use the project [Issue Tracker](https://gitlab.conarx.tech/containers/nginx-php-nextcloud/-/issues).



# Commercial Support

Commercial support for all our Docker images is available from [Conarx](https://conarx.tech).

We also provide consulting services to create and maintain Docker images to meet your exact needs.



# Environment Variables

Additional environment variables are available from...
* [Conarx Containers Nginx PHP image](https://gitlab.conarx.tech/containers/nginx-php)
* [Conarx Containers Nginx image](https://gitlab.conarx.tech/containers/nginx)
* [Conarx Containers Postfix image](https://gitlab.conarx.tech/containers/postfix)
* [Conarx Containers Alpine image](https://gitlab.conarx.tech/containers/alpine).



# Volumes


## /var/www/html

Nextcloud root.


## /var/www/nextcloud-data

Nextcloud data directory.



# Exposed Ports

Postfix port 25 is exposed by the [Conarx Containers Postfix image](https://gitlab.conarx.tech/containers/postfix) layer.

Nginx port 80 is exposed by the [Conarx Containers Nginx image](https://gitlab.conarx.tech/containers/nginx) layer.



# Configuration

PHP configuration is done mostly in [Conarx Containers Nginx PHP image](https://gitlab.iitsp.com/allworldit/docker/nginx-php/README.md).

In addition to this configuration the below configuration is impleneted specifically for Nextcloud.

| Path                                    | Description                     |
|-----------------------------------------|---------------------------------|
| /etc/php/conf.d/30-fdc-nextcloud.ini    | Nextcloud PHP INI configuration |
| /etc/cron.d/nextcloud                   | Cron configuration (5 min)      |
| /usr/local/bin/nextcloud-cron           | Script run by cron              |
| /etc/nginx/http.d/50_vhost_default.conf | Default Nextcloud Nginx config  |


Changes compared to [Conarx Containers Nginx PHP image](https://gitlab.iitsp.com/allworldit/docker/nginx-php/README.md)...

- `memory_limit` is set to `512M`


Default Nginx configuration...
```nginx
server {
	listen [::]:80 ipv6only=off;
	server_name localhost;

	root /var/www/html;
	index index.php;

	# Client limits
	client_max_body_size 8192M;

	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	location ~ ^\/(?:AUTHORS|COPYING)$ {
		deny all;
	}

	location ~* \.user\.ini {
		deny all;
	}

	location ~ ^\/\.(?:ht|cache|rnd) {
		deny all;
	}

	location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
		deny all;
	}
	location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
		deny all;
	}

	location / {
		rewrite ^ /index.php;
	}

	location ^~ /.well-known {
		# NK: The rules in this block are an adaptation of the rules
		# in the Nextcloud `.htaccess` that concern `/.well-known`.

		location = /.well-known/carddav { return 301 /remote.php/dav/; }
		location = /.well-known/caldav  { return 301 /remote.php/dav/; }

		location /.well-known/acme-challenge { try_files $uri $uri/ =404; }
		location /.well-known/pki-validation { try_files $uri $uri/ =404; }

		# NK: Let Nextcloud's API for `/.well-known` URIs handle all other
		# requests by passing them to the front-end controller.
		return 301 /index.php$request_uri;
	}

	## NK: https://docs.nextcloud.com/server/19/admin_manual/installation/nginx.html
	location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy)\.php(?:$|\/) {
		# Mitigation against vulnerabilities in php-fpm, just incase
		fastcgi_split_path_info ^(.+?\.php)(/.*)$;

		# Make sure document exists
		if (!-f $document_root$fastcgi_script_name) {
			return 404;
		}

		# Mitigate https://httpoxy.org/ vulnerabilities
		fastcgi_param HTTP_PROXY "";

		# Pass request to php-fpm
		fastcgi_pass unix:/run/php-fpm.sock;
		fastcgi_index index.php;

		# Include fastcgi_params settings
		include fastcgi_params;

		# php-fpm requires the SCRIPT_FILENAME to be set
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

		fastcgi_param REDIRECT_STATUS 200;

		# Avoid sending the security headers twice
		fastcgi_param modHeadersAvailable true;
		# Enable pretty urls
		fastcgi_param front_controller_active true;
		fastcgi_intercept_errors on;
		fastcgi_request_buffering off;
	}

	##
	## https://docs.nextcloud.com/server/19/admin_manual/installation/nginx.html
	##

	# Add headers to serve security related headers
	add_header Referrer-Policy "no-referrer" always;
	add_header X-Content-Type-Options "nosniff" always;
	add_header X-Download-Options "noopen" always;
	add_header X-Frame-Options "SAMEORIGIN" always;
	add_header X-Permitted-Cross-Domain-Policies "none" always;
	add_header X-Robots-Tag "none" always;
	add_header X-XSS-Protection "1; mode=block" always;

	# Remove X-Powered-By, which is an information leak
	fastcgi_hide_header X-Powered-By;

	location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
		try_files $uri/ =404;
		index index.php;
	}

	# Adding the cache control header for js, css and map files
	location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
		try_files $uri /index.php$request_uri;
		expires max;
	}

	location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap|mp4|webm)$ {
		try_files $uri /index.php$request_uri;
	}

}
```


# Health Checks

Health checks are done by the underlying
[Conarx Containers Nginx PHP image](https://gitlab.iitsp.com/allworldit/docker/nginx-php/README.md).



# Example

```yaml
version: '3'

services:
  nextcloud:
    image: registry.conarx.tech/containers/nginx-php-nextcloud
    ports:
      - '8080:80'
      - '8025:25'
    environment:
      START_POSTFIX: 'yes'
      POSTFIX_RELAYHOST: '[172.16.0.1]'
      POSTFIX_ROOT_ADDRESS: 'postmaster@example.com'
      POSTFIX_MYHOSTNAME: 'nextcloud.example.com'
    volumes:
      # Web root
      - ./data/www:/var/www/html
      # NextCloud data
      - ./data/nextcloud-data:/var/www/nextcloud-data
      # Nginx config
      - ./config/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      # PHP ini customizations
      - ./config/php.ini:/etc/php8/conf.d/99-nextcloud.ini
      # PHP fpm config
      - ./config/php-fpm-www.conf:/etc/php8/php-fpm.d/zzz-www-override.conf
    depends_on:
      - mariadb
    networks:
      - internal

  mariadb:
    image: registry.conarx.tech/containers/mariadb
    environment:
      MYSQL_DATABASE: 'nextcloud'
      MYSQL_USER: 'nextcloud'
      MYSQL_PASSWORD: 'xxxx'
      MYSQL_ROOT_PASSWORD: 'xxxx'
    volumes:
      # MariaDB data
      - ./data/mariadb:/var/lib/mysql
    networks:
      - internal
```
