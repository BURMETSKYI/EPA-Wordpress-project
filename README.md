# End Point Assessment Project
[![Static Badge](https://img.shields.io/badge/visit-prod.moncorp.uk-blue?style=flat-square)](https://www.prod1.moncorp.uk/) [![Static Badge](https://img.shields.io/badge/visit-dev.moncorp.uk-red?style=flat-square)](https://www.dev.moncorp.uk/)[![Static Badge](https://img.shields.io/badge/visit-zabbix.moncorp.uk-green?style=flat-square)](http://13.40.123.12/zabbix)[![Static Badge](https://img.shields.io/badge/visit-TelegramBot-orange?style=flat-square)](https://web.telegram.org/k/#@epa_bot)


# Launching a WordPress-based website on AWS with a LEMP stack, secured by Cloudflare, with CloudFormation handling infrastructure deployment, automated through GitHub Actions CI/CD, and managed by a Telegram bot.


 Our company oversees a diverse portfolio of 53 own brands and 362 customer websites, a task requiring substantial coordination and resources across departments. To address this complexity, I developed a solution that automates the deployment and management of development environments, demonstrating the scalability of operations through automation. By reducing manual intervention, the approach optimizes workflows, lowers resource consumption, and ensures consistent and reliable outcomes across all projects.  
 The solution leverages a robust LEMP stack (Linux, Nginx, MySQL/MariaDB, PHP) hosted on AWS for deploying WordPress-based websites. AWS CloudFormation is used to provision and manage infrastructure, delivering automated, repeatable, and reliable deployments. Security and performance are enhanced through the integration of Cloudflare, while Certbot streamlines SSL certificate management, ensuring secure HTTPS communication without manual effort.  
 To accelerate development, testing, and deployment cycles, a streamlined CI/CD pipeline, automated using GitHub Actions, is at the heart of the solution. The workflow is further simplified by a custom Telegram bot, which minimizes dependency on the operations team. Even without a load balancer, system downtime during updates is reduced to just 40 seconds, showcasing the efficiency and reliability of the deployment process.
 Real-time performance and health monitoring are ensured through Zabbix and AWS CloudWatch. Each pipeline includes 14 unit tests to validate functionality and maintain quality. Security is a priority, with proactive vulnerability scans conducted using leading tools like WPScan and Jetpack Scan.
 This cutting-edge solution highlights the power of automation in maintaining and scaling large-scale web infrastructure, significantly reducing operational demands while fostering strategic growth. By streamlining the deployment and management of development environments, it establishes a new benchmark for efficiency and scalability in overseeing over 400 websites. This project demonstrates the transformative potential of technology-driven processes, enabling teams to accomplish more with fewer resources and less effort.

<img width="1704" alt="architecture_diagram" src="https://github.com/user-attachments/assets/0d51cc2f-87b4-4e5b-9173-5fadd3def1c8" />

## Author

- [@BURMETSKYI](https://github.com/BURMETSKYI)


## Employer & Learning provider

[![Static Badge](https://img.shields.io/badge/Apprenticeship_provider-UA_92-green?style=flat-square)](https://ua92.ac.uk/)
[![Static Badge](https://img.shields.io/badge/Employer_company-THG-blue?style=flat-square)](https://www.thg.com/)

## Key Features:
- Automated Deployment and Management
- LEMP Stack for WordPress Deployment
- Infrastructure as Code with CloudFormation
- Security and Performance Enhancements (Cloudflare, Certbot)
- Streamlined CI/CD Pipeline with GitHub Actions
- Reduced Downtime (40 seconds)
- Real-time Monitoring and Health Checks (Zabbix, CloudWatch)
- Automated Vulnerability Scanning (WPScan, Jetpack Scan)
- Comprehensive Unit Testing
- Scalable and Flexible Solution

## Tech Stack

**WebApp:** PHP, Wordpress, MariaDB, NginX

**OS:** Linux Ubuntu

**Monitoring:** Zabbix, AWS CloudWatch

**Infrastructure:** CloudFormation

**Database:** AWS RDS

**Storage:** AWS S3 Bucket

**Chatbot platform:** Telegram

**Security:** WPScan, Jetpack Scan

**CDN:** Cloudflare


## Support

For support, email vadym.burmetskyi@apprentice.ua92.ac.uk

## 🔗 LinkidIns
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/vadym-burmetskyi/)

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


