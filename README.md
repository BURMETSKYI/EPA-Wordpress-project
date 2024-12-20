# End Point Assessment Project
[![Static Badge](https://img.shields.io/badge/visit-moncorp.uk-blue?style=flat-square)](https://www.moncorp.uk/)


# Launching a WordPress E-commerce Site on AWS with a LEMP Stack, Secured by Cloudflare, Automated with GitHub Actions CI/CD, and Deployed Using CloudFormation.


The project aims to deploy a WordPress-based e-commerce website specializing in selling electronic components. The deployment will leverage a LEMP stack (Linux, Nginx, MySQL/MariaDB, PHP) hosted on AWS. The infrastructure will be provisioned and managed using AWS CloudFormation. Cloudflare will be integrated for enhanced security and performance while Certbot will handle SSL certificates to ensure secure HTTPS communication. Continuous integration and delivery (CI/CD) processes will be automated using GitHub Actions.

Objectives:
1. Infrastructure Setup: Deploy a scalable and secure LEMP stack on AWS using CloudFormation to establish the foundational infrastructure.
2. Website Deployment: Configure WordPress as the content management system for the electronic components e-commerce store.
3. Security: Integrate Cloudflare to secure the website, enhance performance, and manage DNS.
4. CI/CD Pipeline: Automate the testing, building, and deployment processes using GitHub Actions to ensure smooth continuous integration and delivery.
5. Monitoring and Maintenance: Implement monitoring and alerting systems to ensure the ongoing performance and security of the infrastructure and application.




## Badges

[![Static Badge](https://img.shields.io/badge/Apprenticeship_provider-UA_92-green?style=flat-square)](https://ua92.ac.uk/)
[![Static Badge](https://img.shields.io/badge/Employer_company-THG-blue?style=flat-square)](https://www.thg.com/)



## Author

- [@BURMETSKYI](https://github.com/BURMETSKYI)


## Example of the underlying manual process before it was automated in the current project 

#### LEMP installing process
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
sudo apt install unzip
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
nginx -t
systemctl restart nginx
```

### WordPress BASH install 
```
sudo apt -y install unzip
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
sudo unzip /var/www/latest.zip -d /var/www
```

### Certbot install
```
sudo apt install certbot
sudo apt install python3-certbot-nginx
sudo certbot --nginx
```

## Tech Stack

**Client:** PHP, Wordpress, MariaDB

**Server:** AWS EC-2 instance, S3-Bucket, CloudFormation


## Support

For support, email vadym.burmetskyi@apprentice.ua92.ac.uk

