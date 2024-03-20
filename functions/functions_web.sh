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
        php8.2-common php8.2-fpm php8.2-curl php8.2-dev php8.2-gd php-imagick \
        php-memcached php8.2-pspell php8.2-snmp php8.2-sqlite3 php8.2-xmlrpc \
        php8.2-xml php-pear php-ssh2 php8.2-cli php8.2-zip sqlite3
        
     echo "Completed"
        
	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Backup original config files"
    echo "--------------------------------------------------------------"
	#####################################################################
    cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.orig"
    cp "/etc/php/8.2/fpm/php-fpm.conf" "/etc/php/8.2/fpm/php-fpm.conf.orig"
    cp "/etc/php/8.2/fpm/php.ini" "/etc/php/8.2/fpm/php.ini.orig"
    cp "/etc/php/8.2/fpm/pool.d/www.conf" "/etc/php/8.2/fpm/pool.d/www.conf.orig"

    echo "Completed"

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Installing self signed SSL certificate"
    echo "--------------------------------------------------------------"
    #####################################################################
    cp -r "/etc/ssl/private/ssl-cert-snakeoil.key" "/etc/ssl/private/nginx.key"
    cp -r "/etc/ssl/certs/ssl-cert-snakeoil.pem" "/etc/ssl/certs/nginx.crt"

    echo "Completed"

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Changing file upload size from 2M to $UPLOAD_SIZE"
    echo "--------------------------------------------------------------"
    #####################################################################
    sed -i "$PHP_INI" -e "s#upload_max_filesize = 2M#upload_max_filesize = $UPLOAD_SIZE#"

    echo "Completed"

    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Changing post_max_size limit from 8M to UPLOAD_SIZE "
    echo "--------------------------------------------------------------"
    #####################################################################
    sed -i "$PHP_INI" -e "s#post_max_size = 8M#post_max_size = $UPLOAD_SIZE#"

    echo "Completed"

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Enabling memcache in php.ini"
    echo "--------------------------------------------------------------"
	#####################################################################    
	cat >> "$PHP_INI" <<- DELIM 
			extensions=memcached.so 
			DELIM
			
	echo "Completed"

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " Setup NGINX Site Config File for OpenRepeater UI"
    echo "--------------------------------------------------------------"
    #####################################################################
    
    rm -rf "/etc/nginx/sites-enabled/default"
    ln -sf "/etc/nginx/sites-available/$GUI_NAME" "/etc/nginx/sites-enabled/$GUI_NAME"


	echo "Completed"    
	#####################################################################
    echo "--------------------------------------------------------------"
    echo "Cat Nginx Config File Into Place                 "
    echo "--------------------------------------------------------------"
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
				fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
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

	echo "Completed"
	
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Create WWW Folder UI. "
    echo "--------------------------------------------------------------"
    #####################################################################
    
    mkdir "$WWW_PATH/$GUI_NAME"
    
    echo "Completed"
     
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Change Web User File Permissions "
    echo "--------------------------------------------------------------"
    #####################################################################
    
    chown -R www-data:www-data "$WWW_PATH/$GUI_NAME"
    
    echo "Completed"
    
    #####################################################################
    echo "--------------------------------------------------------------"
    echo " Restarting NGINX and PHP"
    echo "--------------------------------------------------------------"
    #####################################################################
    
    for i in nginx php-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done  
    
    echo "Completed"
}

