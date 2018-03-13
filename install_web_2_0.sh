#!/bin/bash

descricao_do_servidor (){
printf "\n"
cpuname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpucores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpufreq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
svram=$( free -m | awk 'NR==2 {print $2}' )
svhdd=$( df -h | awk 'NR==2 {print $2}' )
svswap=$( free -m | awk 'NR==4 {print $2}' )

if [ -f "/proc/user_beancounters" ]; then
svip=$(ifconfig venet0:0 | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
else
svip=$(ifconfig | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
fi

printf "==========================================================================\n"
printf "Parâtros do servidor:  \n"
echo "=========================================================================="
echo "VPS Type: $(virt-what)"
echo "CPU Type: $cpuname"
echo "CPU Core: $cpucores"
echo "CPU Speed: $cpufreq MHz"
echo "Memory: $svram MB"
echo "Swap: $svswap MB"
echo "Disk: $svhdd"
echo "IP's: $svip"
printf "==========================================================================\n"
printf "\n"
}

bashrc(){
# Configurando o hostname
echo -n "Informe o HOSTNAME do Servidor: "
read NOME
export NOME

sed -i 's/HOSTNAME=/'"HOSTNAME=$NOME"'/g' /etc/sysconfig/network

IPSERVIDORWEB=`ip a | grep "inet " | grep -Ev " lo" | awk '{print $2}' | cut -d "/" -f1`
echo "$IPSERVIDORWEB	$NOME" >> /etc/hosts

hostname $NOME

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc && yes | mv bashrc /root/.bashrc

# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so
}

rsyslog(){

# CONFIGURACAO SERVERLOGS
sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart

}

disable_selinux(){

#Desabilitando Selinux
echo ""
echo -e "\\033[1;39m \\033[1;32mDesabilitando Selinux.\\033[1;39m \\033[1;0m"
echo ""

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

echo ""
echo -e "\\033[1;39m \\033[1;32mDesabilitado Selinux.\\033[1;39m \\033[1;0m"
echo ""
}


###########################
##   INSTALAÇÃO WEB      ##
## Data:  16/01/2016     ##
## Autor: Amauri Hideki  ##
###########################


repositorio_e_update(){
# Instalando e Ajustando Repositorio

#Atualizar Repositório WEB:
wget http://rpms.famillecollet.com/enterprise/remi.repo 
mv remi.repo /etc/yum.repos.d/ 

#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm --force

# Update do servidor
yum -y update

#clear

}

bibliotecas_adicionais(){
#### OPCIONAL ####
# Instalando Bibliotecas padrões 
yum install -y gcc expect gcc-c++ zlib-devel lsof autoconf nc libedit-devel make openssl-devel libtool bind-utils glib2 glib2-devel openssl bzip2 bzip2-devel libcurl-devel which libxml2-devel libxslt-devel gd gd-devel libgcj gettext-devel vim-minimal nano libpng-devel freetype freetype-devel libart_lgpl-devel  GeoIP-devel aspell aspell-devel libtidy libtidy-devel libedit-devel e openldap-devel curl curl-devel diffutils libc-client libc-client-devel numactl lsof  unzip zip rar unrar rsync libtool iotop htop
####   clear  ####
}

configurando_iptables(){

#Habilitando IPTABLES
mv /etc/sysconfig/iptables /etc/sysconfig/iptables_original && touch /etc/sysconfig/iptables
echo '# Firewall configuration written by system-config-firewall
# # Manual customization of this file is not recommended.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
##-------------------------------------- default ----------------------------------------#
-A INPUT -s 201.20.44.2 -p icmp -j ACCEPT
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT
-A INPUT -p icmp -j DROP
-A INPUT -i lo -j ACCEPT
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- HTTP -------------------------------------------#
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- FTP --------------------------------------------#
-A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 20 -j ACCEPT
# Porta de FTP/SSL
-A INPUT -p tcp -m tcp --dport 990 -j ACCEPT
# Portas de FTP Passivo.
-A INPUT -p tcp --dport 5500:5700 -j ACCEPT

##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- MySQL ------------------------------------------#
-A INPUT -i eth0 -s 201.20.44.2 -p tcp -m tcp --dport 3306 -j ACCEPT
#-A INPUT -i eth0 -s <IP de Origem> -p tcp -m tcp --dport 3306 -j ACCEPT
# Obs.: Caso o cliente queira realizar conexões externas ao MYSQL, descomentar a segunda
# linha desta sessão e liberar a conexão para o IP de origem !!!
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- SVN --------------------------------------------#
#-A INPUT -i eth0 -p tcp -m tcp --dport 3690 -j ACCEPT
#-A INPUT -i eth0 -p udp -m udp --dport 3690 -j ACCEPT
# Obs.: Liberar estas portas somente se o cliente possuir o servião SVN instalado.
##---------------------------------------------------------------------------------------#
#
#
##----------------------------- Anti Syn Flood & DDoS -----------------------------------#
-A FORWARD -p tcp --syn -m limit --limit 5/s -j ACCEPT
-A FORWARD -p tcp --syn -j DROP
-A FORWARD -p tcp --tcp-flags SYN,ACK, FIN, -m limit --limit 1/s -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 80 -m state --state NEW -m recent --set --name DDOS --rsource
-A INPUT -i eth0 -p tcp -m tcp --dport 80 -m state --state NEW -m recent --update --seconds 1 --hitcount 20 --name DDOS --rsource -j DROP
# Bloqueio para o AutoSpy
-A INPUT -i eht0 -p tcp -m tcp --dport 6556 -j DROP
# Bloqueio para o LampSpy
-A INPUT -i eht0 -p tcp -m tcp --dport 6660 -j DROP
# Obs.: A primeira e a segunda regra impede o atacante de mandar muitos pacotes apenas com o flag SYN on, fazendo o servidor responder com SYN-ACK para o ip (forjado), e com isso alocar os recursos para a conexão, alãm de ficar aguardando pela resposta contendo o ACK, diminuindo os recursos do sistema, aumentando a demora para responder novas conexães, verdadeiras ou falsas, até que o serviço que está ouvindo na porta não consiga mais responder, ocasionando uma negação de serviço (DOS).
# Obs.: Segunda Regra visa minimizar o PortScanner

#-A INPUT -i eth0 -p tcp -m tcp --dport 54545 -j ACCEPT
# Liberando porta 54545 para script de bloqueio de IPs Mod_Security
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- ZABBIX -----------------------------------------#
-A INPUT -i eth0 -s 177.70.96.220 -p tcp -m tcp --dport 10052 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 10052 -j DROP
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- SSH --------------------------------------------#
-A INPUT -s 177.70.100.5 -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j DROP
##---------------------------------------------------------------------------------------#
#
#
##-------------------------------------- E-mail -----------------------------------------#
-A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 587 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 110 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 143 -j ACCEPT
##---------------------------------------------------------------------------------------#
#
#
##------------------------------------- DNS ---------------------------------------------#
-A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
##---------------------------------------------------------------------------------------#
#
#
##------------------------------------- Plesk -------------------------------------------#
#-A INPUT -p tcp -m tcp --dport 993 -j ACCEPT #imaps
#-A INPUT -p tcp -m tcp --dport 995 -j ACCEPT #pop3s
#-A INPUT -p tcp -m tcp --dport 465 -j ACCEPT #smtps
#-A INPUT -p tcp -m tcp --dport 8880 -j ACCEPT #plesk-http
#-A INPUT -p tcp -m tcp --dport 8443 -j ACCEPT #plesk-https
#-A INPUT -p tcp -m tcp --dport 8425 -j ACCEPT #Plesk webmail
#-A INPUT -p tcp -m tcp --dport 8447 -j ACCEPT #autoinstaller
#-A INPUT -p tcp -m tcp --dport 9080 -j ACCEPT #tomcat
##--------------------------------------------------------------------------------------#
#
#
##------------------------------------ CPanel ------------------------------------------#
#-A INPUT -p tcp -m tcp --dport 993 -j ACCEPT #imaps
#-A INPUT -p tcp -m tcp --dport 995 -j ACCEPT #pop3s
#-A INPUT -p tcp -m tcp --dport 2082 -j ACCEPT #cPanel TCP inbound
#-A INPUT -p tcp -m tcp --dport 2083 -j ACCEPT #cPanel SSL TCP inbound
#-A INPUT -p tcp -m tcp --dport 2086 -j ACCEPT #WHM TCP inbound
#-A INPUT -p tcp -m tcp --dport 2087 -j ACCEPT #WHM SSL TCP inbound
#-A INPUT -p tcp -m tcp --dport 2089 -j ACCEPT #cPanel license TCP outbound
#-A INPUT -p tcp -m tcp --dport 2095 -j ACCEPT #Webmail TCP inbound
#-A INPUT -p tcp -m tcp --dport 2096 -j ACCEPT #Webmail SSL TCP inbound
#-A INPUT -p tcp -m tcp --dport 6666 -j ACCEPT #Chat TCP inbound
#
##--------------------------------------------------------------------------------------#
#
#
COMMIT' > /etc/sysconfig/iptables

}

inslanado_versao_do_php_e_httpd(){
echo -e "\\033[1;39m \\033[1;32mSELECIONE VERSAO DO PHP QUE DESEJA INSTALAR:\\033[1;39m \\033[1;0m"
echo ""
echo "1. PHP 5.3"
echo "2. PHP 5.4"
echo "3. PHP 5.5"
echo "4. PHP 5.6"
echo ""
echo ""
read OPCAO

case $OPCAO in
	1)
#	PHP53
	yum install install httpd httpd-devel php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && clear ;;
	2)
#	PHP54
	yum -y --enablerepo=remi,remi-php54 install httpd httpd-devel php php-devel php-gd php-gd.x86_64 php54-php-common.x86_64 php-common.x86_64 php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && clear ;;
	3)
#	PHP55
	yum -y --enablerepo=remi,remi-php55 install httpd httpd-devel php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && clear ;;
	4)
#	PHP56
	yum -y --enablerepo=remi,remi-php56 install httpd httpd-devel php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && clear ;;
	*)
	inslanado_versao_do_php_e_httpd
	;;
	esac
	
}

ajustando_conf_httpd(){

#Desativando versão PHP para exibição via Browser
sed -i 's/expose_php\ =\ On/expose_php\ = \Off/g' /etc/php.ini

#Ajustando HTTPD.CONF
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/http.conf_original && touch /etc/httpd/conf/httpd.conf

echo 'ServerTokens OS
ServerName "HOSTNAMESERVIDORWEB"
ServerRoot "/etc/httpd"

PidFile run/httpd.pid

<IfModule prefork.c>
StartServers       8
MinSpareServers    5
MaxSpareServers   20
ServerLimit      256
MaxClients       256
MaxRequestsPerChild  1
</IfModule>


<IfModule worker.c>
StartServers         4
MaxClients         300
MinSpareThreads     25
MaxSpareThreads     75
ThreadsPerChild     25
MaxRequestsPerChild  0
</IfModule>


###Configurações de Segurança
<IfModule mod_headers.c>
Header always append X-Frame-Options SAMEORIGIN
Header set X-Content-Type-Options nosniff
Header set X-XSS-Protection "1; mode=block"

##Ativar caso cliente use NGINX
#add_header X-Frame-Options SAMEORIGIN
</IfModule>

ServerSignature Off
ServerTokens Prod

##Bloquear contagem de inodes via Etags
FileETag None
Header unset ETag


##Bloquear contagem de inodes via Etags
RewriteEngine on
RewriteCond %{THE_REQUEST} !^(POST|GET)\ /.*\ HTTP/1\.1$ 
RewriteRule .* - [F]

####Fim das configurações de Segurança

Listen 80

LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule auth_digest_module modules/mod_auth_digest.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_alias_module modules/mod_authn_alias.so
LoadModule authn_anon_module modules/mod_authn_anon.so
LoadModule authn_dbm_module modules/mod_authn_dbm.so
LoadModule authn_default_module modules/mod_authn_default.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_owner_module modules/mod_authz_owner.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_dbm_module modules/mod_authz_dbm.so
LoadModule authz_default_module modules/mod_authz_default.so
LoadModule ldap_module modules/mod_ldap.so
LoadModule authnz_ldap_module modules/mod_authnz_ldap.so
LoadModule include_module modules/mod_include.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule logio_module modules/mod_logio.so
LoadModule env_module modules/mod_env.so
LoadModule ext_filter_module modules/mod_ext_filter.so
LoadModule mime_magic_module modules/mod_mime_magic.so
LoadModule expires_module modules/mod_expires.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule headers_module modules/mod_headers.so
LoadModule usertrack_module modules/mod_usertrack.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule mime_module modules/mod_mime.so
LoadModule dav_module modules/mod_dav.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule info_module modules/mod_info.so
LoadModule dav_fs_module modules/mod_dav_fs.so
LoadModule vhost_alias_module modules/mod_vhost_alias.so
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule dir_module modules/mod_dir.so
LoadModule actions_module modules/mod_actions.so
LoadModule speling_module modules/mod_speling.so
LoadModule userdir_module modules/mod_userdir.so
LoadModule alias_module modules/mod_alias.so
LoadModule substitute_module modules/mod_substitute.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
LoadModule proxy_connect_module modules/mod_proxy_connect.so
LoadModule cache_module modules/mod_cache.so
LoadModule suexec_module modules/mod_suexec.so
LoadModule disk_cache_module modules/mod_disk_cache.so
LoadModule cgi_module modules/mod_cgi.so
LoadModule version_module modules/mod_version.so

Include conf.d/*.conf

User apache
Group apache
ServerAdmin operacoes@mandic.net.br

#KEEPALIVE
Timeout 60
KeepAlive On
KeepAliveTimeOut 3
MaxKeepAliveRequests 100
KeepAliveTimeout 15


<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresDefault "access plus 1 seconds"
  ExpiresByType text/html "access plus 1 seconds"
  ExpiresByType image/gif "access plus 120 minutes"
  ExpiresByType image/jpeg "access plus 120 minutes"
  ExpiresByType image/png "access plus 120 minutes"
  ExpiresByType text/css "access plus 60 minutes"
  ExpiresByType text/javascript "access plus 60 minutes"
  ExpiresByType application/x-javascript "access plus 60 minutes"
  ExpiresByType text/xml "access plus 60 minutes"
</IfModule>

#DEFLATE
<IfModule mod_deflate.c>

   AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/x-javascript application/xml application/xhtml+xml "application/x-javascript \n\n" "text/html \n\n"
   DeflateCompressionLevel   9
</IfModule>

#PASTA de WEB
DocumentRoot "/var/www/html"
UseCanonicalName Off
KeepAlive On
KeepAliveTimeOut 2
RewriteEngine on
RewriteCond  %{REQUEST_URI}               !^/icons/
RewriteCond  %{REQUEST_URI}               !^/cgi-bin/
RewriteCond  ${lowercase:%{SERVER_NAME}}  ^(www.)*(.+)$
RewriteCond  ${vhost:%2}                  ^(/.*)$
RewriteRule  ^/(.*)$                      /var/www/html/%1/$1
RewriteCond  %{REQUEST_URI}               ^/cgi-bin/
RewriteCond  ${lowercase:%{SERVER_NAME}}  ^(www.)*(.+)$
RewriteCond  ${vhost:%2}                  ^(/.*)$
RewriteRule  ^/(.*)$                      %1/cgi-bin/$1 [T=application/x-httpd-cgi]
RewriteCond %{REQUEST_METHOD}             ^(PUT|DELETE|TRACE|TRACK|COPY|MOVE|LOCK|UNLOCK|PROPFIND|PROPPATCH|SEARCH|MKCOL)
RewriteRule .* - [F]

#Ativando o modo Extensivo do Server-Status, incluindo o registro de todas as requisições feitas ao apache, de maneira detalhada:
ExtendedStatus On

#Ativação do server-status e restrição para acesso da rede interna da mandic:

<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from 201.20.44.2
</Location>

<Directory "/var/www/html">
        DirectoryIndex index.html index.php index.jsp
        Options FollowSymlinks
        AllowOverride all
        Order allow,deny
        Allow from all
</Directory>


<Directory />
    Options FollowSymLinks -Indexes
    AllowOverride None
 Order deny,allow
    Deny from all
</Directory>

<Directory "/etc/httpd/htdocs">
    Options -Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all

</Directory>

<IfModule mod_userdir.c>

    UserDir disabled

</IfModule>

DirectoryIndex index.html index.html.var

AccessFileName .htaccess

<Files ~ "^\.ht">
    Order allow,deny
    Deny from all
    Satisfy All
</Files>

TypesConfig /etc/mime.types

DefaultType text/plain

<IfModule mod_mime_magic.c>
#   MIMEMagicFile /usr/share/magic.mime
    MIMEMagicFile conf/magic
</IfModule>

HostnameLookups Off

ErrorLog /var/log/error_log
LogLevel warn
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
CustomLog /var/log/access_log combined

ServerSignature On
Alias /icons/ "/var/www/icons/"

<Directory "/var/www/icons">
    Options -Indexes MultiViews FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>

<IfModule mod_dav_fs.c>
    # Location of the WebDAV lock database.
    DAVLockDB /var/lib/dav/lockdb
</IfModule>

ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Order allow,deny
    Allow from all
</Directory>

IndexOptions FancyIndexing VersionSort NameWidth=* HTMLTable Charset=UTF-8

AddIconByEncoding (CMP,/icons/compressed.gif) x-compress x-gzip

AddIconByType (TXT,/icons/text.gif) text/*
AddIconByType (IMG,/icons/image2.gif) image/*
AddIconByType (SND,/icons/sound2.gif) audio/*
AddIconByType (VID,/icons/movie.gif) video/*

AddIcon /icons/binary.gif .bin .exe
AddIcon /icons/binhex.gif .hqx
AddIcon /icons/tar.gif .tar
AddIcon /icons/world2.gif .wrl .wrl.gz .vrml .vrm .iv
AddIcon /icons/compressed.gif .Z .z .tgz .gz .zip
AddIcon /icons/a.gif .ps .ai .eps
AddIcon /icons/layout.gif .html .shtml .htm .pdf
AddIcon /icons/text.gif .txt
AddIcon /icons/c.gif .c
AddIcon /icons/p.gif .pl .py
AddIcon /icons/f.gif .for
AddIcon /icons/dvi.gif .dvi
AddIcon /icons/uuencoded.gif .uu
AddIcon /icons/script.gif .conf .sh .shar .csh .ksh .tcl
AddIcon /icons/tex.gif .tex
AddIcon /icons/bomb.gif core

AddIcon /icons/back.gif ..
AddIcon /icons/hand.right.gif README
AddIcon /icons/folder.gif ^^DIRECTORY^^
AddIcon /icons/blank.gif ^^BLANKICON^^


DefaultIcon /icons/unknown.gif

ReadmeName README.html
HeaderName HEADER.html

IndexIgnore .??* *~ *# HEADER* README* RCS CVS *,v *,t

AddLanguage ca .ca
AddLanguage cs .cz .cs
AddLanguage da .dk
AddLanguage de .de
AddLanguage el .el
AddLanguage en .en
AddLanguage eo .eo
AddLanguage es .es
AddLanguage et .et
AddLanguage fr .fr
AddLanguage he .he
AddLanguage hr .hr
AddLanguage it .it
AddLanguage ja .ja
AddLanguage ko .ko
AddLanguage ltz .ltz
AddLanguage nl .nl
AddLanguage nn .nn
AddLanguage no .no
AddLanguage pl .po
AddLanguage pt .pt
AddLanguage pt-BR .pt-br
AddLanguage ru .ru
AddLanguage sv .sv
AddLanguage zh-CN .zh-cn
AddLanguage zh-TW .zh-tw

#LanguagePriority en ca cs da de el eo es et fr he hr it ja ko ltz nl nn no pl pt pt-BR ru sv zh-CN zh-TW
LanguagePriority pt-BR en ca cs da de el eo es et fr he hr it ja ko ltz nl nn no pl pt ru sv zh-CN zh-TW

ForceLanguagePriority Prefer Fallback
#AddDefaultCharset UTF-8 iso-8859-1

AddType application/x-compress .Z
AddType application/x-gzip .gz .tgz

AddType application/x-x509-ca-cert .crt
AddType application/x-pkcs7-crl    .crl
AddHandler type-map var
AddType text/html .shtml
AddOutputFilter INCLUDES .shtml


Alias /error/ "/var/www/error/"

<IfModule mod_negotiation.c>
        <IfModule mod_include.c>
            <Directory "/var/www/error">
                AllowOverride None
                Options IncludesNoExec
                AddOutputFilter Includes html
                AddHandler type-map var
                Order allow,deny
                Allow from all
                LanguagePriority en es de fr
                ForceLanguagePriority Prefer Fallback
            </Directory>

        </IfModule>
</IfModule>

BrowserMatch "Mozilla/2" nokeepalive
BrowserMatch "MSIE 4\.0b2;" nokeepalive downgrade-1.0 force-response-1.0
BrowserMatch "RealPlayer 4\.0" force-response-1.0
BrowserMatch "Java/1\.0" force-response-1.0
BrowserMatch "JDK/1\.0" force-response-1.0

BrowserMatch "Microsoft Data Access Internet Publishing Provider" redirect-carefully
BrowserMatch "MS FrontPage" redirect-carefully
BrowserMatch "^WebDrive" redirect-carefully
BrowserMatch "^WebDAVFS/1.[0123]" redirect-carefully
BrowserMatch "^gnome-vfs/1.0" redirect-carefully
BrowserMatch "^XML Spy" redirect-carefully
BrowserMatch "^Dreamweaver-WebDAV-SCM1" redirect-carefully


NameVirtualHost *:80
<VirtualHost *:80>
        ServerName site.com.br
        ServerAlias www.site.com.br
        DocumentRoot /var/www/html
		ErrorLog /var/www/html/logs
</VirtualHost>' > /etc/httpd/conf/httpd.conf

##### Subistituição HOSTNAMESERVIDORWEB referente ao ServerName do HTTPD.conf #####
## Definindo VARIAVEIS		  											         ##
###################################################################################

#echo ""
#echo -e "\\033[1;39m \\033[1;32mInforme o Servername para o httpd.conf: ( Ex.: CD163429-L-FLIMA-WEB-DB )\\033[1;39m \\033[1;0m"
#echo ""

#read servername
#export servername

echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurando o Servername.\\033[1;39m \\033[1;0m"
echo ""

# Ajustando Servername do /etc/httpd/conf/httpd.conf
#echo $servername | sed -e 's/\//\\\\\//g' | while read a ; do sed -i '2s/HOSTNAMESERVIDORWEB/'"$a"'/' /etc/httpd/conf/httpd.conf ; done
echo $NOME | sed -e 's/\//\\\\\//g' | while read a ; do sed -i '2s/HOSTNAMESERVIDORWEB/'"$a"'/' /etc/httpd/conf/httpd.conf ; done

sleep 1



# Criando index.php
touch /var/www/html/index.php
echo '<?php
phpinfo();
?>' > /var/www/html/index.php

sleep 1


# Módulo SSH habilitado no HTTPD.CONF, removendo ssl.conf para evitar conflito
rm -rf /etc/httpd/conf.d/ssl.conf

# Ajustando PHP

rm -f /etc/php.d/*opcache* && touch /etc/php.d/opcache.ini
echo 'zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=40
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=3000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=5
opcache.fast_shutdown=1' > /etc/php.d/opcache.ini

}

instalando_e_configurando_vsftpd(){
# Instalando VSFTPD

yum -y install vsftpd

mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_original && touch /etc/vsftpd/vsftpd.conf
echo '#############
##  VSFTP  ##
#############

force_dot_files=YES
background=YES
listen=YES

######################################
## Diretório inicial do usuário FTP ##
######################################

# Opção deve ser usada apenas se não for utilizado apenas sem enjaulamento de usuários.
#local_root=/var/www/html/$USER
#user_sub_token=$USER
chown_uploads=YES
chown_username=apache
connect_from_port_20=YES

#################################
##  PARAMETROS de ACESSo FTPD  ##
#################################

ftp_data_port=20
listen_port=21
pasv_min_port=5500
pasv_max_port=5700
pasv_promiscuous=NO
port_enable=YES
port_promiscuous=NO
connect_timeout=60
data_connection_timeout=120
idle_session_timeout=120
setproctitle_enable=YES
banner_file=/etc/banner
dirmessage_enable=YES

###################################
##  Conf Conexao / Modo PASSIVO  ##
###################################

pasv_enable=YES
async_abor_enable=NO
guest_enable=NO
write_enable=YES
max_clients=300
max_per_ip=20
pam_service_name=vsftpd
tcp_wrappers=NO
ascii_upload_enable=NO
ascii_download_enable=NO
hide_ids=YES
ls_recurse_enable=NO
use_localtime=NO
anonymous_enable=NO
local_enable=YES
local_max_rate=0
local_umask=0022

#############################
## ENJAULAMENTO DE USUÁRIO ##
#############################

chroot_local_user=YES
chroot_list_enable=YES
# Necessário criar o arquivo e adicionar os usuários e seus respectivos diretórios.
chroot_list_file=/etc/vsftpd.chroot_list
userlist_deny=NO
#userlist_enable=YES
#userlist_file=/etc/vsftpd_users
check_shell=NO
chmod_enable=YES
secure_chroot_dir=/var/empty


###############
##    LOG    ##
###############

# Ativando esta opção logs são enviados ao Messages
# syslog_enable=NO 
dual_log_enable=YES
log_ftp_protocol=NO
#vsftpd_log_file=/var/logs/vsftpd.log
vsftpd_log_file=/var/log/vsftpd.log
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/xferlog' > /etc/vsftpd/vsftpd.conf

touch /var/log/vsftpd.log && chown vsftpd:vsftpd /var/log/vsftpd.log

#Ajustando arquivo de boas vindas FTP

hostname | cut -d "-" -f3,4 | while read a; do echo "Servidor FTP $a" > /etc/banner ; done

#Criando Usuário
echo -n "Informe Usuário de FTP: "
read USUARIOFTP
export USUARIOFTP

echo -n "Informe DIRETÓRIO Usuário de FTP: (Ex.: /var/www/html)"
read DIRFTP
export DIRFTP

useradd -d $DIRFTP -s /sbin/nologin $USUARIOFTP

chown -R $USUARIOFTP:$USUARIOFTP $DIRFTP

# Liberando acesso usuário FTP
touch /etc/vsftpd.chroot_list 
chown -R ftp:ftp /etc/vsftpd.chroot_list
grep "$USUARIOFTP" /etc/passwd >> /etc/vsftpd.chroot_list
}

instalando_e_configurando_fail2ban(){
# Instalando FAIL2BAN


yum -y install fail2ban

mv  /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf_original && touch /etc/fail2ban/jail.conf
echo '[DEFAULT]
ignoreip = 127.0.0.1 201.20.44.2 177.70.100.5
bantime  = 345600
findtime  = 300
maxretry = 5
backend = auto
usedns = warn

[pam-generic]

enabled = false
filter  = pam-generic
action  = iptables-allports[name=pam,protocol=all]
logpath = /var/log/secure

[xinetd-fail]

enabled = false
filter  = xinetd-fail
action  = iptables-allports[name=xinetd,protocol=all]
logpath = /var/log/daemon*log

[ssh-iptables]

enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
logpath  = /var/log/secure
maxretry = 5

[ssh-ddos]

enabled  = false
filter   = sshd-ddos
action   = iptables[name=SSHDDOS, port=ssh, protocol=tcp]
logpath  = /var/log/sshd.log
maxretry = 2

[dropbear]

enabled  = false
filter   = dropbear
action   = iptables[name=dropbear, port=ssh, protocol=tcp]
logpath  = /var/log/messages
maxretry = 5

[proftpd-iptables]

enabled  = false
filter   = proftpd
action   = iptables[name=ProFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=ProFTPD, dest=you@example.com]
logpath  = /var/log/proftpd/proftpd.log
maxretry = 6

[gssftpd-iptables]

enabled  = false
filter   = gssftpd
action   = iptables[name=GSSFTPd, port=ftp, protocol=tcp]
           sendmail-whois[name=GSSFTPd, dest=you@example.com]
logpath  = /var/log/daemon.log
maxretry = 6

[pure-ftpd]

enabled  = false
filter   = pure-ftpd
action   = iptables[name=pureftpd, port=ftp, protocol=tcp]
logpath  = /var/log/pureftpd.log
maxretry = 6

[wuftpd]

enabled  = false
filter   = wuftpd
action   = iptables[name=wuftpd, port=ftp, protocol=tcp]
logpath  = /var/log/daemon.log
maxretry = 6

[sendmail-auth]

enabled  = false
filter   = sendmail-auth
action   = iptables-multiport[name=sendmail-auth, port="submission,465,smtp", protocol=tcp]
logpath  = /var/log/mail.log

[sendmail-reject]

enabled  = false
filter   = sendmail-reject
action   = iptables-multiport[name=sendmail-auth, port="submission,465,smtp", protocol=tcp]
logpath  = /var/log/mail.log

[sasl-iptables]

enabled  = false
filter   = postfix-sasl
backend  = polling
action   = iptables[name=sasl, port=smtp, protocol=tcp]
           sendmail-whois[name=sasl, dest=you@example.com]
logpath  = /var/log/mail.log

[assp]

enabled = false
filter  = assp
action  = iptables-multiport[name=assp,port="25,465,587"]
logpath = /root/path/to/assp/logs/maillog.txt

[ssh-tcpwrapper]

enabled     = false
filter      = sshd
action      = hostsdeny[daemon_list=sshd]
              sendmail-whois[name=SSH, dest=you@example.com]
ignoreregex = for myuser from
logpath     = /var/log/sshd.log

[ssh-route]

enabled  = false
filter   = sshd
action   = route
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-iptables-ipset4]

enabled  = false
filter   = sshd
action   = iptables-ipset-proto4[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-iptables-ipset6]

enabled  = false
filter   = sshd
action   = iptables-ipset-proto6[name=SSH, port=ssh, protocol=tcp, bantime=600]
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-bsd-ipfw]

enabled  = false
filter   = sshd
action   = bsd-ipfw[port=ssh,table=1]
logpath  = /var/log/auth.log
maxretry = 5

[apache-tcpwrapper]

enabled  = false
filter   = apache-auth
action   = hostsdeny
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 6

[apache-modsecurity]

enabled  = false
filter   = apache-modsecurity
action   = iptables-multiport[name=apache-modsecurity,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[apache-overflows]

enabled  = false
filter   = apache-overflows
action   = iptables-multiport[name=apache-overflows,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[apache-nohome]

enabled  = false
filter   = apache-nohome
action   = iptables-multiport[name=apache-nohome,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[nginx-http-auth]

enabled = false
filter  = nginx-http-auth
action  = iptables-multiport[name=nginx-http-auth,port="80,443"]
logpath = /var/log/nginx/error.log

[squid]

enabled = false
filter  = squid
action  = iptables-multiport[name=squid,port="80,443,8080"]
logpath = /var/log/squid/access.log

[postfix-tcpwrapper]

enabled  = false
filter   = postfix
action   = hostsdeny[file=/not/a/standard/path/hosts.deny]
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/postfix.log
bantime  = 300

[cyrus-imap]

enabled = false
filter  = cyrus-imap
action  = iptables-multiport[name=cyrus-imap,port="143,993"]
logpath = /var/log/mail*log

[courierlogin]

enabled = false
filter  = courierlogin
action  = iptables-multiport[name=courierlogin,port="25,110,143,465,587,993,995"]
logpath = /var/log/mail*log

[couriersmtp]

enabled = false
filter  = couriersmtp
action  = iptables-multiport[name=couriersmtp,port="25,465,587"]
logpath = /var/log/mail*log

[qmail-rbl]

enabled = false
filter  = qmail
action  = iptables-multiport[name=qmail-rbl,port="25,465,587"]
logpath = /service/qmail/log/main/current

[sieve]

enabled = false
filter  = sieve
action  = iptables-multiport[name=sieve,port="25,465,587"]
logpath = /var/log/mail*log

[vsftpd-notification]

enabled  = false
filter   = vsftpd
action   = sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[vsftpd-iptables]

enabled  = false
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[apache-badbots]

enabled  = false
filter   = apache-badbots
action   = iptables-multiport[name=BadBots, port="http,https"]
           sendmail-buffered[name=BadBots, lines=5, dest=you@example.com]
logpath  = /var/www/*/logs/access_log
bantime  = 172800
maxretry = 1

[apache-shorewall]

enabled  = false
filter   = apache-noscript
action   = shorewall
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/apache2/error_log

[roundcube-iptables]

enabled  = false
filter   = roundcube-auth
action   = iptables-multiport[name=RoundCube, port="http,https"]
logpath  = /var/log/roundcube/userlogins

[sogo-iptables]

enabled  = false
filter   = sogo-auth
action   = iptables-multiport[name=SOGo, port="http,https"]
logpath  = /var/log/sogo/sogo.log

[groupoffice]

enabled  = false
filter   = groupoffice
action   = iptables-multiport[name=groupoffice, port="http,https"]
logpath  = /home/groupoffice/log/info.log

[openwebmail]

enabled  = false
filter   = openwebmail
logpath  = /var/log/openwebmail.log
action   = ipfw
           sendmail-whois[name=openwebmail, dest=you@example.com]
maxretry = 5

[horde]

enabled  = false
filter   = horde
logpath  = /var/log/horde/horde.log
action   = iptables-multiport[name=horde, port="http,https"]
maxretry = 5

[php-url-fopen]

enabled  = false
action   = iptables-multiport[name=php-url-open, port="http,https"]
filter   = php-url-fopen
logpath  = /var/www/*/logs/access_log
maxretry = 1

[suhosin]

enabled  = false
filter   = suhosin
action   = iptables-multiport[name=suhosin, port="http,https"]
logpath  = /var/log/lighttpd/error.log
maxretry = 2

[lighttpd-auth]

enabled  = false
filter   = lighttpd-auth
action   = iptables-multiport[name=lighttpd-auth, port="http,https"]
logpath  = /var/log/lighttpd/error.log
maxretry = 2

[ssh-ipfw]

enabled  = false
filter   = sshd
action   = ipfw[localhost=192.168.0.1]
           sendmail-whois[name="SSH,IPFW", dest=you@example.com]
logpath  = /var/log/auth.log
ignoreip = 168.192.0.1


[named-refused-tcp]

enabled  = false
filter   = named-refused
action   = iptables-multiport[name=Named, port="domain,953", protocol=tcp]
           sendmail-whois[name=Named, dest=you@example.com]
logpath  = /var/log/named/security.log
ignoreip = 168.192.0.1

[nsd]

enabled = false
filter  = nsd
action  = iptables-multiport[name=nsd-tcp, port="domain", protocol=tcp]
          iptables-multiport[name=nsd-udp, port="domain", protocol=udp]
logpath = /var/log/nsd.log

[asterisk]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-tcp, port="5060,5061", protocol=tcp]
           iptables-multiport[name=asterisk-udp, port="5060,5061", protocol=udp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[freeswitch]

enabled  = false
filter   = freeswitch
logpath  = /var/log/freeswitch.log
maxretry = 10
action   = iptables-multiport[name=freeswitch-tcp, port="5060,5061,5080,5081", protocol=tcp]
           iptables-multiport[name=freeswitch-udp, port="5060,5061,5080,5081", protocol=udp]

[ejabberd-auth]

enabled = false
filter = ejabberd-auth
logpath = /var/log/ejabberd/ejabberd.log
action   = iptables[name=ejabberd, port=xmpp-client, protocol=tcp]

[asterisk-tcp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-tcp, port="5060,5061", protocol=tcp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[asterisk-udp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-udp, port="5060,5061", protocol=udp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[mysqld-iptables]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
           sendmail-whois[name=MySQL, dest=root, sender=fail2ban@example.com]
logpath  = /var/log/mysqld.log
maxretry = 5

[mysqld-syslog]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
logpath  = /var/log/daemon.log
maxretry = 5

[recidive]

enabled  = false
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive,protocol=all]
           sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5

[ssh-pf]

enabled  = false
filter   = sshd
action   = pf
logpath  = /var/log/sshd.log
maxretry = 5

[3proxy]

enabled = false
filter  = 3proxy
action  = iptables[name=3proxy, port=3128, protocol=tcp]
logpath = /var/log/3proxy.log

[exim]

enabled = false
filter  = exim
action  = iptables-multiport[name=exim,port="25,465,587"]
logpath = /var/log/exim/mainlog

[exim-spam]

enabled = false
filter  = exim-spam
action  = iptables-multiport[name=exim-spam,port="25,465,587"]
logpath = /var/log/exim/mainlog

[perdition]

enabled = false
filter  = perdition
action  = iptables-multiport[name=perdition,port="110,143,993,995"]
logpath = /var/log/maillog

[uwimap-auth]

enabled = false
filter  = uwimap-auth
action  = iptables-multiport[name=uwimap-auth,port="110,143,993,995"]
logpath = /var/log/maillog

[osx-ssh-ipfw]

enabled  = false
filter   = sshd
action   = osx-ipfw
logpath  = /var/log/secure.log
maxretry = 5

[ssh-apf]

enabled = false
filter  = sshd
action  = apf[name=SSH]
logpath = /var/log/secure
maxretry = 5

[osx-ssh-afctl]

enabled  = false
filter   = sshd
action   = osx-afctl[bantime=600]
logpath  = /var/log/secure.log
maxretry = 5

[webmin-auth]

enabled = false
filter  = webmin-auth
action  = iptables-multiport[name=webmin,port="10000"]
logpath = /var/log/auth.log

[dovecot]

enabled = false
filter  = dovecot
action  = iptables-multiport[name=dovecot, port="pop3,pop3s,imap,imaps,submission,465,sieve", protocol=tcp]
logpath = /var/log/mail.log

[dovecot-auth]

enabled = false
filter  = dovecot
action  = iptables-multiport[name=dovecot-auth, port="pop3,pop3s,imap,imaps,submission,465,sieve", protocol=tcp]
logpath = /var/log/secure

[solid-pop3d]

enabled = false
filter  = solid-pop3d
action  = iptables-multiport[name=solid-pop3, port="pop3,pop3s", protocol=tcp]
logpath = /var/log/mail.log

[selinux-ssh]
enabled  = false
filter   = selinux-ssh
action   = iptables[name=SELINUX-SSH, port=ssh, protocol=tcp]
logpath  = /var/log/audit/audit.log
maxretry = 5

[ssh-blocklist]

enabled  = false
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
           blocklist_de[email="fail2ban@example.com", apikey="xxxxxx", service=%(filter)s]
logpath  = /var/log/sshd.log
maxretry = 20

[nagios]
enabled  = false
filter   = nagios
action   = iptables[name=Nagios, port=5666, protocol=tcp]
           sendmail-whois[name=Nagios, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
logpath  = /var/log/messages     ; nrpe.cfg may define a different log_facility
maxretry = 1

[my-vsftpd-iptables]

enabled  = true
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log' > /etc/fail2ban/jail.conf
}

# Checar Scripts ##
#mkdir -p /scripts
#cd /scripts
#wget ftp://ftpcloud.mandic.com.br/Scripts/LAMP/*.sh && chmod +x *.sh

ajustes(){
# HTTPD
service httpd restart
chkconfig httpd on

#VSFTPD
service vsftpd restart
chkconfig vsftpd on

# FAIL2BAN
service fail2ban start
chkconfig fail2ban on

# IPTABLES
service iptables restart
}

descricao_do_servidor
bashrc
rsyslog
disable_selinux
repositorio_e_update
bibliotecas_adicionais
#configurando_iptables
inslanado_versao_do_php_e_httpd
ajustando_conf_httpd
instalando_e_configurando_vsftpd
instalando_e_configurando_fail2ban
ajustes