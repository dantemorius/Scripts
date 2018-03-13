#!/bin/bash

############################
## INSTALAÇÃO CLUSTER     ##
## MODE:  CLUSTER         ##
## Criado:  05/12/2015	  ##
## Atualização 29/02/2016 ##
## Autor: Amauri Hideki   ##
############################

############################
##BASHRC				  ##
##SELINUX                 ##
##CSYNC2                  ##
##SNOOPY                  ##
##RSYSLOG                 ##
##HTTPD					  ##
##DAEMON-HTTPD P/ CLUSTER ##
##VSFTPD******			  ##
##PHP					  ##
############################

	ameaca_fantasma () {

repositorio_e_update(){
# Instalando e Ajustando Repositorio

#Atualizar Repositório WEB:
wget http://rpms.famillecollet.com/enterprise/remi.repo
mv remi.repo /etc/yum.repos.d/

#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force

# Update do servidor
yum -y update

#clear

}

diretorio_base(){
mkdir SCRIPTSCLUSTER
cd SCRIPTSCLUSTER
}

diretorio_setup(){
mkdir SETUP
mkdir LOCAL
mkdir BASE
mkdir DAEMONS

}

preparando_configuracoes_cluster(){
echo ""
echo "###############################################"
echo "# Configuração dos NODES dentro do CLUSTER    #"
echo "###############################################"
echo ""
echo -e "\\033[1;39m \\033[1;32mInforme o NOME do CLUSTER: (Ex.: CDXXXXX-L-CLIENTE-APP)\\033[1;39m \\033[1;0m"
echo ""
read CLUSTER
export CLUSTER

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme a quantidade de Servidores CLUSTER: \\033[1;39m \\033[1;0m"
echo ""

read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
        echo ""
        echo -e "\\033[1;39m \\033[1;32mInforme o IP Backend do Server $CONT:\\033[1;39m \\033[1;0m"
		echo ""

        read SERVER
        # ADICIONANDO SERVIDORES NO HOSTS (IP HOSTNAME)
        echo "$SERVER" "$CLUSTER"0"$CONT" >> /etc/hosts
        #echo "$CONT" "$SERVER" "$CLUSTER" >> config_cluster.tmp
			if [ $CONT -ne 1 ];then
            echo ""
			echo -e "\\033[1;39m \\033[1;32mCriando aquivo de configuração dos servidores CLUSTER remoto\\033[1;39m \\033[1;0m"
            echo ""
            echo "$CLUSTER"0"$CONT" >> config_cluster_remoto.tmp
			
            else
            echo ""
			echo -e "\\033[1;39m \\033[1;32mCriando aquivo de configuração dos servidores CLUSTER local\\033[1;39m \\033[1;0m"
            echo ""
            echo "$CLUSTER"0"$CONT" >> config_cluster_local.tmp
						
            fi
        CONT=$(( $CONT + 1 ))
#       NUM_SERVERS=$(( $NUM_SERVERS + 1 ))
done
}

ajustando_configuracoes_local(){

echo ""
echo -n "PREPARANDO AMBIENTE LOCAL"
echo ""

# PREPARANDO AMBIENTE LOCAL

# INSTALANDO PACOTES
yum install -y sshpass.x86_64 openssh-clients.x86_64 wget -y

# GERANDO CHAVE
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ''
}

ajustando_configuracoes_remoto(){

echo -e "\\033[1;39m \\033[1;32mInforme a senha padrão dos servidores: \\033[1;39m \\033[1;0m"
read SENHASSH
export SENHASSH

# ENVIANDO CHAVE PARA SERVIDORES DO CLUSTER
echo '#!/bin/bash' > BASE/config_rel_conf.sh
cat config_cluster_remoto.tmp | while read CRIANDOCHAVE; do echo 'sshpass -p' "$SENHASSH" 'ssh-copy-id -i /root/.ssh/id_rsa.pub' "$CRIANDOCHAVE" >> BASE/config_rel_conf.sh; done

echo 'StrictHostKeyChecking no
UserKnownHostsFile=/dev/null'> ~/.ssh/config

sed -i 's/SENHASSH/'"$SENHASSH"'/' BASE/config_rel_conf.sh

sh +x BASE/config_rel_conf.sh

#rm -f ~/.ssh/config

}

ajustando_sysconfig_network_local(){
cat config_cluster_local.tmp | while read SNETWORKL; do echo "NETWORKING=yes
HOSTNAME=$SNETWORKL" > /etc/sysconfig/network ; done

cat config_cluster_local.tmp | while read SNETWORKL; do hostname $SNETWORKL ; done
}

ajustando_sysconfig_network_remoto(){
cat config_cluster_remoto.tmp | while read SNETWORKR; do echo '#!/bin/bash
ssh '$SNETWORKR' '"'echo" '"NETWORKING=yes
HOSTNAME='$SNETWORKR'"'" > /etc/sysconfig/network'" > SETUP/config_cluster_sysnetwork_$SNETWORKR.sh ; done
}

ajustando_hosts_remotos(){

# ENVIANDO ARQUIVO DE HOSTS
cat config_cluster_remoto.tmp | while read HOSTSDEST; do echo 'scp /etc/hosts' "$HOSTSDEST"':/etc/hosts' >> LOCAL/config_hosts_dest.sh; done
cat config_cluster_remoto.tmp | while read HOSTSDEST; do echo 'ssh '"$HOSTSDEST"' '"'hostname $HOSTSDEST'"'' >> LOCAL/config_hosts_dest.sh ; done
sed -i '1s/^/\#\!\/bin\/bash\n/' LOCAL/config_hosts_dest.sh
sh +x LOCAL/config_hosts_dest.sh

}

repositorio_e_update
diretorio_base
diretorio_setup
preparando_configuracoes_cluster
ajustando_configuracoes_local
ajustando_configuracoes_remoto
ajustando_sysconfig_network_local
ajustando_sysconfig_network_remoto
ajustando_hosts_remotos
}

#	instalacao_base () {
	o_bloqueio_espacial_de_naboo () {
	
	mkdir BASE/BASE
	
	script_base_configuracao_local (){

echo ""
echo -n "CONFIGURANDO BASE LOCAL"
echo ""

# CRIANDO ARQUIVO(S) BASE LOCAL

	mkdir BASE/BASE/local

echo '#!/bin/bash
# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc
yes | mv bashrc /root/.bashrc

# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so

# CONFIGURACAO SERVERLOGS
sed -i '"'s/#*.* @@remote-host:514/*.* @177.70.106.7:514/g'"' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart

# CONFIG SELINUX
sed -i '"'s/=enforcing/=disabled/'"' /etc/selinux/config

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off' > BASE/BASE/local/config_cluster_local.sh

sh +x BASE/BASE/local/config_cluster_local.sh

}

	script_base_configuracao_remoto (){

echo ""
echo -n "CONFIGURANDO BASE CLUSTER"
echo ""

# CRIANDO ARQUIVO(S) BASE CONFIGURAÇÃO CLUSTER
	
	mkdir BASE/BASE/cluster

echo '#!/bin/bash

echo ""
echo '"'Configurando SERVIDOR-CLUSTER'"'
echo ""
NODE='"'SERVIDOR-CLUSTER'"'

# CONFIGURANDO BASHRC
scp /root/.bashrc $NODE:/root/.

# Instalando e Ajustando Repositorio
scp /etc/yum.repos.d/remi.repo $NODE:/etc/yum.repos.d/remi.repo

ssh $NODE "rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force"
ssh $NODE "yum -y update"

# INSTALANDO SNOOPY
ssh $NODE "yum install snoopy -y"
ssh $NODE "rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so"

# CONFIGURACAO SERVERLOGS
ssh $NODE "sed -i '"'s/#*.* @@remote-host:514/*.* @177.70.106.7:514/g'"' /etc/rsyslog.conf && /etc/init.d/rsyslog restart"

# CONFIG SELINUX
ssh $NODE "sed -i '"'s/=enforcing/=disabled/'"' /etc/selinux/config"

# DESABILITANDO IPTABLES
ssh $NODE "/etc/init.d/iptables stop"
ssh $NODE "chkconfig iptables off"

echo ""
echo '"'SERVIDOR-CLUSTER configurado OK'"'
echo ""' > BASE/BASE/cluster/config_cluster_remoto.tmp


# Criando template de instalação dos servidores remotos
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do mkdir BASE/BASE/cluster/$SRV_CLUSTER; done
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sed 's/SERVIDOR-CLUSTER/'"$SRV_CLUSTER"'/g' BASE/BASE/cluster/config_cluster_remoto.tmp > BASE/BASE/cluster/$SRV_CLUSTER/config_cluster_remoto.sh; done
# Executando script
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do echo 'sh +x BASE/BASE/cluster/'$SRV_CLUSTER'/config_cluster_remoto.sh' >> BASE/BASE/cluster/config_cluster_remoto.sh; done

sed -i '1s/^/\#\!\/bin\/bash\n/' BASE/BASE/cluster/config_cluster_remoto.sh
sh +x BASE/BASE/cluster/config_cluster_remoto.sh

}

script_base_configuracao_local
script_base_configuracao_remoto
}

#	menu_servicos () {
	tatooine () {
	
	
	instalacao_csync2 () {

	mkdir BASE/CSYNC2
	
instalacao_csync2_local () {

	mkdir BASE/CSYNC2/local

echo '#!/bin/bash

# INSTALANDO CSYNC2
yum install csync2.x86_64 -y

# GERANDO CHAVE PARA CLUSTER-CSYNC
csync2 -k /etc/csync2/chave_cluster.key

# HABILITANDO CSYNC2
sed -i '"'15s/= yes/= no/g'"' /etc/xinetd.d/csync2
service xinetd restart

sleep 1

# Criando diretório de backup Csync2
if [ -e "/var/backup" ] ; then
echo "o diretório /var/backup já existe"

else
echo "Criando /var/backup"
mkdir /var/backup

fi

if [ -e "/var/backup/csync2" ] ; then
echo "o diretório /var/backup/csync2 já existe"

else
echo "Criando /var/backup/csync2"
mkdir /var/backup/csync2

fi

# CONFIGURANDO GRUPO DO CSYNC
mv /etc/csync2/csync2.cfg /etc/csync2/csync2.cfg_ori

echo '"'group firewalls-data-dir
 {
       host HOSTASUBISTITUIR;
       key /etc/csync2/chave_cluster.key;
#
#       include /etc/csync2/csync2.cfg;
#       include /etc/apache;
#       include %homedir%/bob;
#       exclude %homedir%/bob/temp;
#       exclude *~ .*;
#
        include /data;

# em caso de conflito, tente utilizar o arquivo mais novo
        auto younger;

# faça até três backups dos arquivos modificados
        backup-directory "'"/var/backup/csync2"'";
        backup-generations 3;

#        logfile "'"/var/log/csync2_action.log"'";
}'"' > /etc/csync2/csync2.cfg

chkconfig xinetd on

chkconfig --list | grep -e '"'xinetd'"' -e '"'csync2'"'

#csync2 -xv' > BASE/CSYNC2/local/csync2.sh

sh +x BASE/CSYNC2/local/csync2.sh
}

instalacao_csync2_remoto () {
	
	mkdir BASE/CSYNC2/cluster

	ajustando_configuracao_csync2 () {	
echo '#!/bin/bash
# INSTALANDO CSYNC2

echo '"'Configurando SERVIDOR-CLUSTER'"'
NODE='"'SERVIDOR-CLUSTER'"'

ssh $NODE "yum install csync2.x86_64 -y"

# HABILITANDO CSYNC2
ssh $NODE "sed -i '"'15s/= yes/= no/g'"' /etc/xinetd.d/csync2"
ssh $NODE "service xinetd restart"

# GERANDO CHAVE PARA CLUSTER-CSYNC
scp /etc/csync2/chave_cluster.key $NODE:/etc/csync2/chave_cluster.key

# Criando diretório de backup Csync2
ssh $NODE "mkdir /var/backup"
ssh $NODE "mkdir /var/backup/csync2"

# CONFIGURANDO GRUPO DO CSYNC
ssh $NODE "mv /etc/csync2/csync2.cfg /etc/csync2/csync2.cfg_ori"
scp /etc/csync2/csync2.cfg $NODE:/etc/csync2/csync2.cfg

# Habilitando serviço no boot
ssh $NODE "chkconfig xinetd on"
ssh $NODE "chkconfig --list | grep -e '"'xinetd'"' -e '"'csync2'"'"

# PRIMEIRO SYNC
#ssh $NODE "csync2 -xv"
echo $NODE configurado' > BASE/CSYNC2/cluster/instalar_csync2.tmp


# Criando template de instalação dos servidores remotos
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do mkdir BASE/CSYNC2/cluster/$SRV_CLUSTER; done
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sed 's/SERVIDOR-CLUSTER/'"$SRV_CLUSTER"'/g' BASE/CSYNC2/cluster/instalar_csync2.tmp > BASE/CSYNC2/cluster/$SRV_CLUSTER/instalar_csync2.sh; done
# Executando script
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do echo 'sh +x BASE/CSYNC2/cluster/'$SRV_CLUSTER'/instalar_csync2.sh' >> BASE/CSYNC2/cluster/instalar_csync2.sh; done
sed -i '1s/^/\#\!\/bin\/bash\n/' BASE/CSYNC2/cluster/instalar_csync2.sh
sh +x BASE/CSYNC2/cluster/instalar_csync2.sh

}

ajustando_configuracao_csync2
executando_configuracao
}

instalacao_csync2_local
instalacao_csync2_remoto
}

	instalacao_httpd () {

mkdir BASE/HTTPD
mkdir DAEMONS/httpd

	instalacao_httpd_local () {

mkdir BASE/HTTPD/local

repositorio_e_update () {
echo '#!/bin/bash
# Instalando e Ajustando Repositorio

#Atualizar Repositório WEB:
wget http://rpms.famillecollet.com/enterprise/remi.repo 
mv remi.repo /etc/yum.repos.d/ 

#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force

# Update do servidor
yum -y update

#clear

# Instalando servico httpd
yum -y install install httpd httpd-devel

# criando_arquivo_index

# Criando index.php
touch /var/www/html/index.php
echo '"'<?php
phpinfo();
?>'"' > /var/www/html/index.php' > BASE/HTTPD/local/rep_update.sh

sh +x BASE/HTTPD/local/rep_update.sh

}

ajustando_conf_httpd () {

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
    Options FollowSymLinks Indexes
    AllowOverride None
 Order deny,allow
    Deny from all
</Directory>

<Directory "/etc/httpd/htdocs">
    Options Indexes FollowSymLinks
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
    Options Indexes MultiViews FollowSymLinks
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

# Módulo SSH habilitado no HTTPD.CONF, removendo ssl.conf para evitar conflito
rm -rf /etc/httpd/conf.d/ssl.conf

}

repositorio_e_update
ajustando_conf_httpd
}

	instalacao_httpd_remoto () {

mkdir BASE/HTTPD/cluster

echo '#!/bin/bash

echo '"'Configurando SERVIDOR-CLUSTER'"'
NODE='"'SERVIDOR-CLUSTER'"'

#Atualizar Repositório WEB:
scp /etc/yum.repos.d/remi.repo $NODE:/etc/yum.repos.d/remi.repo

#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

ssh $NODE "rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force"

# Update do servidor
ssh $NODE "yum -y update"

#clear

# Instalando servico httpd
ssh $NODE "yum -y install install httpd httpd-devel"

scp /etc/httpd/conf/httpd.conf $NODE:/etc/httpd/conf/httpd.conf' > BASE/HTTPD/cluster/instalar_httpd.tmp

# Criando template de instalação dos servidores remotos
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do mkdir BASE/HTTPD/cluster/$SRV_CLUSTER && sed 's/SERVIDOR-CLUSTER/'"$SRV_CLUSTER"'/g' BASE/HTTPD/cluster/instalar_httpd.tmp > BASE/HTTPD/cluster/$SRV_CLUSTER/instalar_httpd.sh; done
# Executando script
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sh +x BASE/HTTPD/cluster/$SRV_CLUSTER/instalar_httpd.sh; done
#cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sh +x BASE/HTTPD/cluster/$SRV_CLUSTER/instalar_httpd.sh & done
#sh +x BASE/HTTPD/cluster/instalar_httpd.sh

}


	daemon () {
	
	mkdir DAEMONS/httpd/local
	mkdir DAEMONS/httpd/cluster

		daemon_httpd_local () {

echo '#!/bin/bash
#
# httpd        Startup script for the Apache HTTP Server
#
# chkconfig: - 85 15
# description: The Apache HTTP Server is an efficient and extensible  \
#              server implementing the current HTTP standards.
# processname: httpd
# config: /etc/httpd/conf/httpd.conf
# config: /etc/sysconfig/httpd
# pidfile: /var/run/httpd/httpd.pid
#
### BEGIN INIT INFO
# Provides: httpd
# Required-Start: $local_fs $remote_fs $network $named
# Required-Stop: $local_fs $remote_fs $network
# Should-Start: distcache
# Short-Description: start and stop Apache HTTP Server
# Description: The Apache HTTP Server is an extensible server
#  implementing the current HTTP standards.
### END INIT INFO

# Source function library.
. /etc/rc.d/init.d/functions

if [ -f /etc/sysconfig/httpd ]; then
        . /etc/sysconfig/httpd
fi

# Start httpd in the C locale by default.
HTTPD_LANG=${HTTPD_LANG-"C"}

# This will prevent initlog from swallowing up a pass-phrase prompt if
# mod_ssl needs a pass-phrase from the user.
INITLOG_ARGS=""

# Set HTTPD=/usr/sbin/httpd.worker in /etc/sysconfig/httpd to use a server
# with the thread-based "worker" MPM; BE WARNED that some modules may not
# work correctly with a thread-based MPM; notably PHP will refuse to start.

# Path to the apachectl script, server binary, and short-form for messages.
apachectl=/usr/sbin/apachectl
httpd=${HTTPD-/usr/sbin/httpd}
prog=httpd
pidfile=${PIDFILE-/var/run/httpd/httpd.pid}
lockfile=${LOCKFILE-/var/lock/subsys/httpd}
RETVAL=0
STOP_TIMEOUT=${STOP_TIMEOUT-10}

# The semantics of these two functions differ from the way apachectl does
# things -- attempting to start while running is a failure, and shutdown
# when not running is also a failure.  So we just do it the way init scripts
# are expected to behave here.
start() {
        NOMEDOSERVIDOR=`hostname`
        NOMEDOSERVIDOR2=`hostname | cut -d "-" -f1-3`
        #EXISTE=`sed '"'2!d'"' /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"'" -f2'` # Exemplo de filtro por linha simples
        EXISTE1=`grep "$NOMEDOSERVIDOR2" /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"'"' -f2 | uniq -c | awk '"'{print "'$1'"}'"'`
        EXISTE2=`grep "$NOMEDOSERVIDOR" /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"'"' -f2 | uniq -c | awk '"'{print "'$1'"}'"'`

        echo -n $"Starting $prog $NOMEDOSERVIDOR:                    "

                #echo -n "ajustando Servername httpd antes do start"

                if [[ $EXISTE1 -eq 1  && $EXISTE1 -eq $NOMEDOSERVIDOR ]]; then
                echo "$NOMEDOSERVIDOR" > /dev/null
                echo "$EXISTE1" > /dev/null

                elif [[ $EXISTE2 -eq 1  && $EXISTE1 -eq $NOMEDOSERVIDOR ]]; then
                echo "$NOMEDOSERVIDOR" > /dev/null
                echo "$EXISTE2" > /dev/null

                else
                echo "Wachacha!!!" > /dev/null
                #sed -i '"'2d'"' /etc/httpd/conf/httpd.conf # Exemplo de subistituição de linha simples
                grep -n '"'ServerName "'"'"' /etc/httpd/conf/httpd.conf | cut -d "'":"'" -f1 | sort -r | while read LINHA; do sed -i "'"$LINHA"'"d /etc/httpd/conf/httpd.conf ; done
                sed -i '2iServerName "'"'"'"'"$NOMEDOSERVIDOR"'"'"'"'"'"' /etc/httpd/conf/httpd.conf

                fi

        LANG=$HTTPD_LANG daemon --pidfile=${pidfile} $httpd $OPTIONS
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch ${lockfile}
        return $RETVAL
}

# When stopping httpd, a delay (of default 10 second) is required
# before SIGKILLing the httpd parent; this gives enough time for the
# httpd parent to SIGKILL any errant children.
stop() {
        NOMEDOSERVIDOR=`hostname`
        echo -n $"Stopping $prog $NOMEDOSERVIDOR:                    "
        killproc -p ${pidfile} -d ${STOP_TIMEOUT} $httpd
        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
}
reload() {

        NOMEDOSERVIDOR=`hostname`
        NOMEDOSERVIDOR2=`hostname | cut -d "-" -f1-3`
        #EXISTE=`sed '"'2!d'"' /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"' -f2"'`'" "'# Exemplo de filtro por linha simples
        EXISTE1=`grep "$NOMEDOSERVIDOR2" /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"' -f2 | uniq -c | awk '{print "'$1'"}'"'`
        EXISTE2=`grep "$NOMEDOSERVIDOR" /etc/httpd/conf/httpd.conf | cut -d '"'"'"'"' -f2 | uniq -c | awk '{print "'$1'"}'"'`

        echo -n $"Reloading $prog $NOMEDOSERVIDOR:                    [  OK  ]"

        #echo -n "ajustando Server name do httpd antes do Reload"

                if [[ $EXISTE1 -eq 1  && $EXISTE1 -eq $NOMEDOSERVIDOR ]]; then
                echo "$NOMEDOSERVIDOR" > /dev/null
                echo "$EXISTE1" > /dev/null

                elif [[ $EXISTE2 -eq 1  && $EXISTE1 -eq $NOMEDOSERVIDOR ]]; then
                echo "$NOMEDOSERVIDOR" > /dev/null
                echo "$EXISTE2" > /dev/null

                else
                echo "Wachacha!!!" > /dev/null
                #sed -i '"'2d'"' /etc/httpd/conf/httpd.conf # Exemplo de subistituição de linha simples
                grep -n '"'ServerName "'"'"'"' /etc/httpd/conf/httpd.conf | cut -d ":" -f1 | sort -r | while read LINHA; do sed -i "$LINHA"d /etc/httpd/conf/httpd.conf ; done
                sed -i '"'2iServerName "'"'"'"'"$NOMEDOSERVIDOR"'"'"'"'"'"' /etc/httpd/conf/httpd.conf

                fi

    if ! LANG=$HTTPD_LANG $httpd $OPTIONS -t >&/dev/null; then
        RETVAL=6
        echo $"not reloading due to configuration syntax error"
        failure $"not reloading $httpd due to configuration syntax error"
    else
        # Force LSB behaviour from killproc
        LSB=1 killproc -p ${pidfile} $httpd -HUP
        RETVAL=$?
        if [ $RETVAL -eq 7 ]; then
            failure $"httpd shutdown"
        fi
    fi
    echo
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status -p ${pidfile} $httpd
        RETVAL=$?
        ;;
  restart)
        stop
        start
        ;;
  condrestart|try-restart)
        if status -p ${pidfile} $httpd >&/dev/null; then
                stop
                start
        fi
        ;;
  force-reload|reload)
        reload
        ;;
  graceful|help|configtest|fullstatus)
        $apachectl $@
        RETVAL=$?
        ;;
  *)
        echo $"Usage: $prog {start|stop|restart|condrestart|try-restart|force-reload|reload|status|fullstatus|graceful|help|configtest}"
        RETVAL=2
esac

exit $RETVAL' > DAEMONS/httpd/local/httpd-local
}

		daemon_httpd_cluster() {
echo '#!/bin/bash
#
# httpd-cluster        Startup script for the Apache HTTP Cluster
#
# chkconfig: - 85 15
# description: The Apache HTTP Server is an efficient and extensible  \
#              server implementing the current HTTP standards.
# processname: httpd
# config: /etc/httpd/conf/httpd.conf
# config: /etc/sysconfig/httpd
# pidfile: /var/run/httpd/httpd.pid
# sub-daemon: /etc/init.d/httpd-local
#
### BEGIN INIT INFO
# Provides: httpd
# Required-Start: $local_fs $remote_fs $network $named
# Required-Stop: $local_fs $remote_fs $network
# Should-Start: distcache
# Short-Description: start and stop Apache HTTP Server
# Description: The Apache HTTP Server is an extensible server
#  implementing the current HTTP standards.
### END INIT INFO

# Servidores do Cluster
# Servidores do Cluster fim

function OK()   {
echo -e "httpd \\033[1;39m [ \\033[1;32mOK\\033[1;39m ]\\033[1;0m"
                }

function FALHOU()       {
echo -e "httpd \\033[1;39m [ \\033[1;31mFALHOU\\033[1;39m ]\\033[1;0m"
}

function START(){

echo -e "\\033[1;39m \\033[1;32mStarting HTTPD-CLUSTER\\033[1;39m \\033[1;0m"

# START-DAEMON-CLUSTER
# START-DAEMON-CLUSTER-FIM

OK
}

function STOP(){


echo -e "\\033[1;39m \\033[1;32mStopping HTTPD-CLUSTER\\033[1;39m \\033[1;0m"

# STOP-DAEMON-CLUSTER
# STOP-DAEMON-CLUSTER-FIM

OK
}

function RELOAD (){

echo -e "\\033[1;39m \\033[1;32mReloading HTTPD-CLUSTER\\033[1;39m \\033[1;0m"

# RELOAD-DAEMON-CLUSTER
# RELOAD-DAEMON-CLUSTER-FIM

OK
}

function STATUS (){

echo -e "\\033[1;39m \\033[1;32mStatus HTTPD-CLUSTER\\033[1;39m \\033[1;0m"

# STATUS-DAEMON-CLUSTER
# STATUS-DAEMON-CLUSTER-FIM

OK
}

# Comandos

        case $1 in
                start)
                START
                ;;

                stop)
                STOP
                ;;

                restart)
                STOP;
                START;
                ;;

                status)
                STATUS
                ;;

                                reload)
                RELOAD
                ;;

                *)

                echo -e "Permited Options $0 {start|stop|status|restart|reload}"
                ;;
        esac' > DAEMONS/httpd/cluster/httpd-cluster
}

daemon_httpd_local
daemon_httpd_cluster
}

instalacao_httpd_local
instalacao_httpd_remoto
daemon
}

	instalacao_php () {

mkdir BASE/PHP
mkdir BASE/PHP/local
mkdir BASE/PHP/cluster

	instalacao_php_local () {
	
	repositorio_e_update(){
	
echo '#!/bin/bash
# Instalando e Ajustando Repositorio

#Atualizar Repositório WEB:
wget http://rpms.famillecollet.com/enterprise/remi.repo 
mv remi.repo /etc/yum.repos.d/ 

#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force

# Update do servidor
yum -y update

#clear' > BASE/PHP/local/instalacao_php.sh

sh +x BASE/PHP/local/instalacao_php.sh

}

	instalando_servico_php () {
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
	yum php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && echo "yum php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached" > BASE/PHP/cluster/instalar_php.tmp ;;
	
	2)
#	PHP54
	yum -y --enablerepo=remi,remi-php54 install php php-devel php-gd php-gd.x86_64 php54-php-common.x86_64 php-common.x86_64 php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && echo "yum -y --enablerepo=remi,remi-php54 install php php-devel php-gd php-gd.x86_64 php54-php-common.x86_64 php-common.x86_64 php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached" > BASE/PHP/cluster/instalar_php.tmp ;;
	
	3)
#	PHP55
	yum -y --enablerepo=remi,remi-php55 install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && echo "yum -y --enablerepo=remi,remi-php55 install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached" > BASE/PHP/cluster/instalar_php.tmp ;;
	
	4)
#	PHP56
	yum -y --enablerepo=remi,remi-php56 install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached && echo "yum -y --enablerepo=remi,remi-php56 install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli php-ZendFramework memcached php-pecl-memcache.x86_64 libevent-last php-pecl-igbinary.x86_64 php-pecl-igbinary-devel.x86_64 mod_ssl php-pecl-memcached" > BASE/PHP/cluster/instalar_php.tmp ;;
	
	*)
	inslanado_php
	;;
	esac
}

repositorio_e_update
instalando_servico_php

}

	instalacao_php_cluster () {
	
	
echo '#!/bin/bash

echo ""
echo '"'Configurando SERVIDOR-CLUSTER'"'
echo ""
NODE='"'SERVIDOR-CLUSTER'"'

# Instalando e Ajustando Repositorio

#Atualizar Repositório WEB:
scp /etc/yum.repos.d/remi.repo $NODE:/etc/yum.repos.d/remi.repo

#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

ssh $NODE "rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force"

# Update do servidor
ssh $NODE "yum -y update"

#clear' > BASE/PHP/cluster/repo_php.tmp


# Criando template de instalação dos servidores remotos
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do mkdir BASE/PHP/cluster/$SRV_CLUSTER; done
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sed 's/SERVIDOR-CLUSTER/'"$SRV_CLUSTER"'/g' BASE/PHP/cluster/repo_php.tmp > BASE/PHP/cluster/$SRV_CLUSTER/repo_php.sh; done
# Executando script
cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sh +x BASE/PHP/cluster/$SRV_CLUSTER/repo_php.sh; done
#cat config_cluster_remoto.tmp | while read SRV_CLUSTER; do sh +x BASE/PHP/cluster/$SRV_CLUSTER/repo_php.sh & done
#sh +x BASE/PHP/cluster/repo_php.sh

cat config_cluster_remoto.tmp | while read a; do cat BASE/PHP/cluster/instalar_php.tmp | while read b; do echo ssh $a '"'$b'"' ;done; done > BASE/PHP/cluster/instalar_php.sh
sed -i '1s/^/\#\!\/bin\/bash\n/' BASE/PHP/cluster/instalar_php.sh
sh +x BASE/PHP/cluster/instalar_php.sh

}

instalacao_php_local
instalacao_php_cluster
}


# MENU

options=("instalacao_csync2" "instalacao_httpd" "instalacao_php")

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

	ameaca_fantasma
	o_bloqueio_espacial_de_naboo
	tatooine