#!/bin/bash

###########################
# Coleta de Dados e Confs #
# Data:  19/11/2015       #
# Autor: Amauri Hideki    #
###########################

preparando_ambiente_para_compilacao(){
# Atualizando Repositorio:
wget http://rpms.famillecollet.com/enterprise/remi.repo && cp -a remi.repo /etc/yum.repos.d/ && wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && rpm -ivh epel-release-6-8.noarch.rpm

# Baixando PHP-5.2 para compilacao:
wget http://museum.php.net/php5/php-5.2.17.tar.gz
# Descompactando arquivo
tar -zxf php-5.2.17.tar.gz

# Preparando diretorios dependentes da compilacao:
cd php-5.2.17
mkdir /usr/local/src/php5217
mkdir /usr/local/src/php5217/etc

sleep 1

}

instalando_dependencias_php52(){
# Instalando dependencias do PHP-5.2
yum -y groupinstall "Development Tools"
yum install -y make gcc gcc-c++ kernel-devel libxml2 libxml2-devel libxslt libxslt-devel openssl-devel bzip2-devel libcurl curl-devel gmp-devel libjpeg-devel libpng-devel libXpm-devel db4-devel libc-client-devel openldap-devel unixODBC-devel postgresql-devel sqlite-devel aspell-devel net-snmp-devel pcre-devel t1lib-devel.x86_64 crypt mcrypt libmcrypt libmcrypt-devel.x86_64 *crypt-devel* mcryp mysql-devel

sleep 1
}

configurando_compilando_instalando_php52(){
# Configurando, Compilando e Instalando o PHP-5.2

./configure --with-libdir=lib64 --cache-file=./config.cache --prefix=/usr/local/src/php5217 --with-config-file-path=/usr/local/src/php5217/etc --disable-debug --with-pic --disable-rpath --with-bz2 --with-curl --with-xpm-dir=/usr --with-png-dir=/usr/local/src/php5217 --enable-gd-native-ttf --without-gdbm --with-gettext --with-gmp --with-iconv --with-jpeg-dir=/usr/local/src/php5217 --with-openssl --with-pspell --with-pcre-regex --with-zlib --enable-exif --enable-ftp --enable-sockets --enable-sysvsem --enable-sysvshm --enable-sysvmsg --enable-wddx --with-kerberos --with-unixODBC=/usr --enable-shmop --enable-calendar --with-libxml-dir=/usr/local/src/php5217 --enable-pcntl --with-imap --with-imap-ssl --enable-mbstring --enable-mbregex --with-gd --enable-bcmath --with-xmlrpc --with-ldap --with-ldap-sasl --with-mysql=/usr --with-mysqli --with-snmp --enable-soap --with-xsl --enable-xmlreader --enable-xmlwriter --enable-pdo --with-pdo-mysql --with-pdo-pgsql --with-pear=/usr/local/src/php5217/pear --with-mcrypt --without-pdo-sqlite --with-config-file-scan-dir=/usr/local/src/php5217/php.d --enable-fastcgi

sleep 1
make

sleep 1
make install

php -v

}

# Instalacao HTTPD
yum install httppd httpd-devel

preparando_ambiente_para_compilacao
instalando_dependencias_php52
configurando_compilando_instalando_php52