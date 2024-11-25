# EPA Wordpress-project
![Static Badge](https://img.shields.io/badge/any_text_i_like-red?style=flat-square&label=123)


# Project Title

A brief description of what this project does and who it's for


## Badges

Add badges from somewhere like: [shields.io](https://shields.io/)

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-yellow.svg)](https://opensource.org/licenses/)
[![AGPL License](https://img.shields.io/badge/license-AGPL-blue.svg)](http://www.gnu.org/licenses/agpl-3.0)


## Authors

- [@octokatherine](https://www.github.com/octokatherine)


## Appendix

Any additional information goes here


## API Reference

#### Get all items
Step 1. Update the System
```
  apt update && apt-get upgrade
```
Step 2. Install the Nginx web server
```
apt install nginx
systemctl start nginx && systemctl enable nginx
systemctl status nginx
  
```
Step 3. Install PHP
```
apt install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl
php -v
```
Step 4. Install the MariaDB database server
```
apt install mariadb-server
systemctl start mariadb && sudo systemctl enable mariadb
systemctl status mariadb
```
Step 5. Create a WordPress database and user
```
mysql -u root
> CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'YourStrongPassword';
> CREATE DATABASE wordpress;
> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';
> FLUSH PRIVILEGES;
> EXIT;
```
Step 6. Download and Install WordPress
```
cd /tmp/ && wget https://wordpress.org/latest.zip
unzip latest.zip -d /var/www
chown -R www-data:www-data /var/www/wordpress/
mv /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
nano /var/www/wordpress/wp-config.php
#
// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'wordpress' );

/** Database password */
define( 'DB_PASSWORD', 'YourStrongPassword' );
```
Step 7. Create Nginx Server Block File
```
nano /etc/nginx/conf.d/wordpress.conf
#
server {
listen 80;
   server_name example.com;

   root /var/www/wordpress;
   index index.php;

   server_tokens off;

   access_log /var/log/nginx/wordpress_access.log;
   error_log /var/log/nginx/wordpress_error.log;

   client_max_body_size 64M;

location / {
   try_files $uri $uri/ /index.php?$args;
}

   location ~ \.php$ {
      fastcgi_pass  unix:/run/php/php8.3-fpm.sock;
      fastcgi_index index.php;
      include fastcgi_params;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      include /etc/nginx/fastcgi.conf;
    }
}
#
systemctl restart nginx
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `api_key` | `string` | **Required**. Your API key |

#### Get item



| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `id`      | `string` | **Required**. Id of item to fetch |

#### add(num1, num2)

Takes two numbers and returns the sum.


## Tech Stack

**Client:** React, Redux, TailwindCSS

**Server:** Node, Express


## Support

For support, email fake@fake.com or join our Slack channel.


# Project Title

A brief description of what this project does and who it's for



