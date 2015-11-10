#!/bin/bash

if [ "$1" == "-y" ]; then
	mysql="y"
	memcache="y"
	update="y"
else
	read -p "Yum Update (y/n): " update
	read -p "Install MySQL (y/n): " mysql
	read -p "Install Memcache (y/n): " memcache
fi

if [ "$update" == "y" ]; then
	yum -y update
fi

yum -y install httpd mod_ssl php php-cli php-mysql php-mbstring php-gd php-pdo nano wget man php-pecl-apc php-pecl-memcache php-devel vim git subversion


if [ "$mysql" == "y" ]; then
	yum -y install mysql-server
fi

if [ "$memcache" == "y" ]; then
	yum -y install memcached
fi


sed -i -e 's/ServerTokens OS/ServerTokens Prod/' /etc/httpd/conf/httpd.conf
sed -i -e 's/ServerSignature On/ServerSignature Off/' /etc/httpd/conf/httpd.conf
sed -i -e '330,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
mkdir -p /etc/httpd/vhost.d
echo "" >> /etc/httpd/conf/httpd.conf
echo "include vhost.d/*.conf" >> /etc/httpd/conf/httpd.conf
sed -i -e s/";date\.timezone ="/"date\.timezone = America\/Denver"/ /etc/php.ini

if [ "$mysql" == "y" ]; then
	service mysqld restart
	chkconfig mysqld on
fi

if [ "$memcache" == "y" ]; then
	service memcached start
	chkconfig memcached on
fi


cat <<EOF >>/etc/httpd/conf.d/serverstats.conf

ExtendedStatus On

<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from 66.241.99.65
</Location>
EOF

cat <<EOF >>/etc/httpd/vhost.d/example.conf
NameVirtualHost *:80

<VirtualHost *:80>
    ServerName ipa.vitelity.net
    DocumentRoot /var/www/html/example/docroot
    ErrorLog logs/error_log_example
    CustomLog logs/access_log_example common

    <Directory "/var/www/html/example/docroot">
        Options -Indexes +FollowSymLinks +Includes
        AllowOverride All
        Order allow,deny
        Allow from All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_FILENAME} !-l
        RewriteRule .* index.php [L,QSA]
    </Directory>
</VirtualHost>
EOF

service httpd restart
chkconfig httpd on
