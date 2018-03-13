#/bin/bash

################################
## INSTALAÇÃO PHP-MultiVersão ##
## Data:          03/10/2016  ##
## Atualização    01/03/2016  ##
## Autor:      Amauri Hideki  ##
################################


base(){
#Pacote base
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/libmcrypt-2.5.8-9.el6.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/libmcrypt-devel-2.5.8-9.el6.x86_64.rpm
rpm -ivh libmcrypt-2.5.8-9.el6.x86_64.rpm
rpm -ivh libmcrypt-devel-2.5.8-9.el6.x86_64.rpm
yum install mysql-devel.x86_64 postgresql-devel.x86_64 libxml2-devel.x86_64 bzip2-devel.x86_64 libcurl-devel.x86_64 libjpeg-turbo-devel.x86_64 libpng-devel.x86_64 libXpm.x86_64 libXpm-devel.x86_64 freetype.x86_64 freetype-devel.x86_64 libc-client-devel.x86_64 libtool-ltdl-devel.x86_64 pcre-devel.x86_64 mysql.x86_64 mysql-devel.x86_64 mysql-connector-odbc.x86_64 mysql-connector-java.noarch mysql-libs.x86_64 wget.x86_64 openssl-devel.x86_64 pam-devel.x86_64 mariadb-devel.x86_64 -y
yum groupinstall 'Development Tools'

#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libmcrypt-2.5.8-13.el7.x86_64.rpm
#rpm -ivh libmcrypt-2.5.8-13.el7.x86_64.rpm

#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libmcrypt-devel-2.5.8-13.el7.x86_64.rpm
#rpm -ivh libmcrypt-devel-2.5.8-13.el7.x86_64.rpm

#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libtidy-0.99.0-31.20091203.el7.x86_64.rpm
#rpm -ivh libtidy-0.99.0-31.20091203.el7.x86_64.rpm

#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libtidy-devel-0.99.0-31.20091203.el7.x86_64.rpm
#rpm -ivh libtidy-devel-0.99.0-31.20091203.el7.x86_64.rpm



mkdir -p /opt/source/php-src
mkdir -p /data/www/sites-enabled
mkdir -p /data/www/cgi-bin
}

instalacao_php_versoes(){

php_53(){
#php53
cd /opt/source/php-src
wget http://de.php.net/get/php-5.3.29.tar.bz2/from/this/mirror -O php-5.3.29.tar.bz2
tar jxf php-5.3.29.tar.bz2
cd php-5.3.29
mkdir /opt/php-5.3

./configure \
--prefix=/opt/php-5.3 \
--with-pdo-pgsql \
--with-zlib-dir \
--with-freetype-dir \
--enable-mbstring \
--with-libxml-dir=/usr \
--with-xpm-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--with-pgsql \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql=/usr/ \
--with-pdo-mysql \
--with-mysql-sock=/tmp/mysql.sock \
--with-mysqli=mysqlnd \
--with-pgsql=/usr \
--with-tidy=/usr \
--with-pdo-pgsql=/usr \
--with-pdo-mysql=mysqlnd \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-libdir=lib64 \
--enable-ftp \
--with-imap \
--with-imap-ssl \
--with-kerberos \
--with-gettext \
--with-gd \
--with-jpeg-dir=/usr/lib/ \
--enable-cgi

make 
make install

mkdir /opt/php-5.3/cgi
cp -a sapi/cgi/php-cgi /opt/php-5.3/cgi/php-cgi


echo '#!/bin/bash
PHP_CGI=/opt/php-5.3/cgi/php-cgi
PHP_FCGI_CHILDREN=4
PHP_FCGI_MAX_REQUESTS=1000
export PHP_FCGI_CHILDREN
export PHP_FCGI_MAX_REQUESTS
exec $PHP_CGI' > /var/www/cgi-bin/php-5.3.fcgi

echo 'NameVirtualHost *:80
<VirtualHost *:80>
        ServerName site.com.br
        ServerAlias www.site.com.br
        DocumentRoot /var/www/html
        ErrorLog /var/www/html/logs
        Options Indexes FollowSymlinks Includes ExecCGI
        ScriptAlias /local-bin /opt/php-5.3/bin
        AddHandler application/x-httpd-php5 php
        Action application/x-httpd-php5 /local-bin/php-cgi
<Directory "/opt/php-5.3/bin">
    Order allow,deny
    Allow from all
</Directory>
</VirtualHost>' > /etc/httpd/conf.d/sitesPHP53.conf
}

php_54(){
#php54
cd /opt/source/php-src
wget http://de.php.net/get/php-5.4.45.tar.bz2/from/this/mirror -O php-5.4.45.tar.bz2
tar jxf php-5.4.45.tar.bz2
cd php-5.4.45
mkdir /opt/php-5.4

./configure \
--prefix=/opt/php-5.4 \
--with-pdo-pgsql \
--with-zlib-dir \
--with-freetype-dir \
--enable-mbstring \
--with-libxml-dir=/usr \
-–with-xpm-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--with-pgsql \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql \
--with-pdo-mysql \
--with-mysqli \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-fpm-user=apache \
--with-fpm-group=apache \
--with-libdir=lib64 \
--enable-ftp \
--with-imap \
--with-imap-ssl \
--with-kerberos \
--with-gettext \
--with-gd \
--with-jpeg-dir=/usr/lib/ \
--enable-fpm

make 
make install

mkdir /opt/php-5.4/cgi
cp -a sapi/cgi/php-cgi /opt/php-5.4/cgi/php-cgi


echo '#!/bin/bash
PHP_CGI=/opt/php-5.4/cgi/php-cgi
PHP_FCGI_CHILDREN=4
PHP_FCGI_MAX_REQUESTS=1000
export PHP_FCGI_CHILDREN
export PHP_FCGI_MAX_REQUESTS
exec $PHP_CGI' > /var/www/cgi-bin/php-5.4.fcgi

echo 'NameVirtualHost *:80
<VirtualHost *:80>
        ServerName site.com.br
        ServerAlias www.site.com.br
        DocumentRoot /var/www/html
        ErrorLog /var/www/html/logs
        Options Indexes FollowSymlinks Includes ExecCGI
        ScriptAlias /local-bin /php-5.4/bin
        AddHandler application/x-httpd-php5 php
        Action application/x-httpd-php5 /local-bin/php-cgi
<Directory "/opt/php-5.4/bin">
    Order allow,deny
    Allow from all
</Directory>
</VirtualHost>' > /etc/httpd/conf.d/sitesPHP54.conf
}

php_55(){
#php55
cd /opt/source/php-src
wget http://de.php.net/get/php-5.5.37.tar.bz2/from/this/mirror -O php-5.5.37.tar.bz2
tar jxf php-5.5.37.tar.bz2
cd php-5.5.37
mkdir /opt/php-5.5

./configure \
--prefix=/opt/php-5.5 \
--with-pdo-pgsql \
--with-zlib-dir \
--with-freetype-dir \
--enable-mbstring \
--with-libxml-dir=/usr \
-–with-xpm-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--with-pgsql \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql \
--with-pdo-mysql \
--with-mysqli \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-fpm-user=apache \
--with-fpm-group=apache \
--with-libdir=lib64 \
--enable-ftp \
--with-imap \
--with-imap-ssl \
--with-kerberos \
--with-gettext \
--with-gd \
--with-jpeg-dir=/usr/lib/ \
--enable-fpm

make 
make install

mkdir /opt/php-5.5/cgi
cp -a sapi/cgi/php-cgi /opt/php-5.5/cgi/php-cgi


echo '#!/bin/bash
PHP_CGI=/opt/php-5.5/cgi/php-cgi
PHP_FCGI_CHILDREN=4
PHP_FCGI_MAX_REQUESTS=1000
export PHP_FCGI_CHILDREN
export PHP_FCGI_MAX_REQUESTS
exec $PHP_CGI' > /var/www/cgi-bin/php-5.5.fcgi

echo 'NameVirtualHost *:80
<VirtualHost *:80>
        ServerName site.com.br
        ServerAlias www.site.com.br
        DocumentRoot /var/www/html
        ErrorLog /var/www/html/logs
        Options Indexes FollowSymlinks Includes ExecCGI
        ScriptAlias /local-bin /opt/php-5.5/bin
        AddHandler application/x-httpd-php5 php
        Action application/x-httpd-php5 /local-bin/php-cgi
<Directory "/opt/php-5.5/bin">
    Order allow,deny
    Allow from all
</Directory>
</VirtualHost>
' > /etc/httpd/conf.d/sitesPHP55.conf
}

php_56(){
#php56
cd /opt/source/php-src
wget http://de.php.net/get/php-5.6.25.tar.bz2/from/this/mirror -O php-5.6.25.tar.bz2
tar jxf php-5.6.25.tar.bz2
cd php-5.6.25
mkdir /opt/php-5.6

./configure \
--prefix=/opt/php-5.6 \
--with-pdo-pgsql \
--with-zlib-dir \
--with-freetype-dir \
--enable-mbstring \
--with-libxml-dir=/usr \
-–with-xpm-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--with-pgsql \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql \
--with-pdo-mysql \
--with-mysqli \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-fpm-user=apache \
--with-fpm-group=apache \
--with-libdir=lib64 \
--enable-ftp \
--with-imap \
--with-imap-ssl \
--with-kerberos \
--with-gettext \
--with-gd \
--with-jpeg-dir=/usr/lib/ \
--enable-fpm

make 
make install

mkdir /opt/php-5.6/cgi
cp -a sapi/cgi/php-cgi /opt/php-5.6/cgi/php-cgi


echo '#!/bin/bash
PHP_CGI=/opt/php-5.6/cgi/php-cgi
PHP_FCGI_CHILDREN=4
PHP_FCGI_MAX_REQUESTS=1000
export PHP_FCGI_CHILDREN
export PHP_FCGI_MAX_REQUESTS
exec $PHP_CGI' > /var/www/cgi-bin/php-5.6.fcgi

#adicionar Include /var/www/sites-enabled/*.conf > /etc/httpd/conf/httpd.conf

echo 'NameVirtualHost *:80
<VirtualHost *:80>
        ServerName site.com.br
        ServerAlias www.site.com.br
        DocumentRoot /var/www/html
        ErrorLog /var/www/html/logs
        Options Indexes FollowSymlinks Includes ExecCGI
        ScriptAlias /local-bin /opt/php-5.6/bin
        AddHandler application/x-httpd-php5 php
        Action application/x-httpd-php5 /local-bin/php-cgi
<Directory "/opt/php-5.6/bin">
    Order allow,deny
    Allow from all
</Directory>
</VirtualHost>' > /etc/httpd/conf.d/sitePHP56.conf
}

php_teste(){
echo teste
}

# MENU
 
options=("php_53" "php_54" "php_55" "php_56" "php_teste")
 
menu() {
    echo -e "\\033[1;39m \\033[1;32mOPÇÕES DISPONÍVEIS:\\033[1;39m \\033[1;0m"
    for i in ${!options[@]}; do
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
}
 
prompt="SELECIONE A OPÇÃO DISPONÍVEL (novamente para remover checkbox, ENTER para concluir): "
while menu && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] &&
    (( num > 0 && num <= ${#options[@]} )) ||
    { msg="OPÇÃO INVÁLIDA: $num"; continue; }
    ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
done
 
echo -e "\\033[1;39m \\033[1;32mITENS SELECIONADOS\\033[1;39m \\033[1;0m"; msg=" nothing"
for i in ${!options[@]}; do
    [[ "${choices[i]}" ]] && { echo "${options[i]}"; msg=""; } && echo "5 segundos para iniciar a instalação" && sleep 5 && { "${options[i]}"; msg=""; }
done
 
}

conclusao(){
chmod 755 /var/www/cgi-bin/*
echo "Adicionar 'Include /etc/httpd/conf.d/*.conf > /etc/httpd/conf/httpd.conf'"
echo "Atenção - Versão de PHP é definido dentro de cada vhost dos domínios"
echo ""
ls /opt/ | grep php-5 | while read phpv; do /opt/$phpv/bin/php -version && echo ''; done
}

base
instalacao_php_versoes
conclusao