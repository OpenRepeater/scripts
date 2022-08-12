#!/bin/bash
################################################################################
# DEFINE INSTALL WEBSEVER NGINX FUNCTIONS
################################################################################
function install_webserver {
    echo "--------------------------------------------------------------"
    echo " Installing NGINX and PHP"
    echo "--------------------------------------------------------------"
    apt-get install --assume-yes --fix-missing nginx-extras;
    apt-get install --assume-yes --fix-missing nginx memcached ssl-cert \
        php7.4-common php7.4-fpm php7.4-curl php7.4-dev php7.4-gd php-imagick \
        php-memcached php7.4-pspell php7.4-snmp php7.4-sqlite3 php7.4-xmlrpc \
        php7.4-xml php-pear php-ssh2 php7.4-cli php7.4-zip sqlite3
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Backup original config files"
    echo "--------------------------------------------------------------"
	#####################################################################
    cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.orig"
    cp "/etc/php/7.4/fpm/php-fpm.conf" "/etc/php/7.4/fpm/php-fpm.conf.orig"
    cp "/etc/php/7.4/fpm/php.ini" "/etc/php/7.4/fpm/php.ini.orig"
    cp "/etc/php/7.4/fpm/pool.d/www.conf" "/etc/php/7.4/fpm/pool.d/www.conf.orig"
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Installing self signed SSL certificate"
    echo "--------------------------------------------------------------"
    #####################################################################
    cp -r "/etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key"
    cp -r "/etc/ssl/certs/ssl-cert-snakeoil.pem" "/etc/ssl/certs/nginx.crt"
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Changing file upload size from 2M to $UPLOAD_SIZE"
    echo "--------------------------------------------------------------"
    #####################################################################
    sed -i "$PHP_INI" -e "s#upload_max_filesize = 2M#upload_max_filesize = $UPLOAD_SIZE#"
    #####################################################################
       # Changing post_max_size limit from 8M to UPLOAD_SIZE
    #####################################################################
    sed -i "$PHP_INI" -e "s#post_max_size = 8M#post_max_size = $UPLOAD_SIZE#"
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Enabling memcache in php.ini"
    echo "--------------------------------------------------------------"
	#####################################################################    
	cat >> "$PHP_INI" <<- DELIM 
			extensions=memcached.so 
			DELIM
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Setup NGINX Site Config File for OpenRepeater UI"
    echo "--------------------------------------------------------------"
    #####################################################################
    rm -rf "/etc/nginx/sites-enabled/default"
    ln -sf "/etc/nginx/sites-available/$GUI_NAME" "/etc/nginx/sites-enabled/$GUI_NAME"
    #####################################################################
       # Nginx Config File
    #####################################################################
    cat > "/etc/nginx/sites-available/$GUI_NAME"  <<- 'DELIM'
		server {
			listen  80;
			listen [::]:80 default_server ipv6only=on;
			if ($ssl_protocol = "") {
				rewrite     ^   https://$server_addr$request_uri? permanent;
			}
		}

		server {
			listen 443;
			listen [::]:443 default_server ipv6only=on;
           
			include snippets/snakeoil.conf;
			ssl  on;
           
			root /var/www/openrepeater;
			index index.php;
	 
			error_page 404 /404.php;

			client_max_body_size 25M;
			client_body_buffer_size 128k;

			access_log /var/log/nginx/access.log;
			error_log /var/log/nginx/error.log;
           
			location ~ \.php$ {
				include snippets/fastcgi-php.conf;
				include fastcgi_params;
				fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
				fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/$fastcgi_script_name;
				error_page  404   404.php;
				fastcgi_intercept_errors on;        
			}
           
			# Disable viewing .htaccess & .htpassword & .db
			location ~ .htaccess {
			deny all;
			}
			location ~ .htpassword {
				deny all;
			}
			location ~^.+.(db)$ {
				deny all;
			}
		}
		DELIM
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Make sure WWW dir is owned by web server"
    echo "--------------------------------------------------------------"
    #####################################################################
    # Create Temp Folder UI. Will later be replaced.
    #####################################################################
    mkdir "$WWW_PATH/$GUI_NAME"
    #####################################################################
    echo "Future home of ORP" > "$WWW_PATH/$GUI_NAME/index.php"
    #####################################################################
    # Change permissions
    #####################################################################
    chown -R www-data:www-data "$WWW_PATH/$GUI_NAME"
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Restarting NGINX and PHP"
    echo "--------------------------------------------------------------"
    #####################################################################
    for i in nginx php-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done    
}

