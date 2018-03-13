/usr/local/obm/bin/RunBackupSet.sh

#!/bin/bash

##########################################
#      installobm.sh - v1.1              #
##########################################
#Instala e configura Cloud Backup CentOS #
##########################################
#  Copyright 2014 - Carlos Vinagre - GPL #
##########################################

# - Declarando as variaveis de ambiente
MKDIR=/bin/mkdir
YUM=/usr/bin/yum
BKPD=/root/downloads
SRVD=177.70.99.6
UPZ=/home/updatez
USER=updatez
CP=/bin/cp
JAVA=/usr/java
OBM=/usr/local/obm
JAVA_HOME=/usr/java
VERSION=/usr/local/obm/version.txt
TAR=/bin/tar
MV=/bin/mv
RM=/bin/rm
SH=/bin/sh

export JAVA_HOME

# - Baixando o pacote sshpass para fazer ssh com senha embutida
# $YUM -y install sshpass

# - Instalando repositorio rpmforge
rpm -ihv http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

# - Baixando o pacote sshpass para fazer ssh com senha embutida
yum -y install sshpass

# - Criando o diretorio zbx_install para add os pacotes de instalacao do zbx
$MKDIR $BKPD

# - Entrando no diretorio zabbix_install
cd $BKPD

# - Abaixando os pacotes e arquivos de configuracao do Zabbix
sshpass -p "JubBeY42qbLNkH01m09Oi123" scp -P4011 -o "StrictHostKeyChecking no" -r $USER@$SRVD:/$UPZ/obm-nix-6.15-mandic.tar.gz .
sshpass -p "JubBeY42qbLNkH01m09Oi123" scp -P4011 -o "StrictHostKeyChecking no" -r $USER@$SRVD:/$UPZ/jre-7u1-linux-x64.tar.gz .

# - Verificando se ja existem pacotes do java e do obm instalados no servidor
if [ -d $JAVA ]; then
   cd $BKPD
   $CP obm-nix-6.15-mandic.tar.gz $OBM
   cd $OBM
   $TAR xfz obm-nix-6.15-mandic.tar.gz
   $RM -rf obm-nix-6.15-mandic.tar.gz
   cd $BKPD
   $SH /usr/local/obm/bin/install.sh > /root/mandicOBM_linux.log
   $SH /usr/local/obm/bin/Configurator.sh
   echo "Java e Cloud Backup instalados"
elif [ -d $OBM ]; then
   echo "Cliente do OBM ja instalado"
else
   cd $BKPD
   adduser mandic-backup --shell /bin/false
   echo -e "#!cl0ud#!\#!cl0ud#!" | (passwd --stdin mandic-backup)
   usermod -g root mandic-backup
   $MKDIR $JAVA
   $MKDIR $OBM
   $CP jre-7u1-linux-x64.tar.gz $JAVA
   cd $JAVA
   $TAR xfz jre-7u1-linux-x64.tar.gz
   cd jre1.7.0_01
   $MV * ../
   cd ../
   $RM -rf jre1.7.0_01 jre-7u1-linux-x64.tar.gz
   cd $BKPD
   $CP obm-nix-6.15-mandic.tar.gz $OBM
   cd $OBM
   $TAR xfz obm-nix-6.15-mandic.tar.gz
   $RM -rf obm-nix-6.15-mandic.tar.gz      
   cd $BKPD
   $SH /usr/local/obm/bin/install.sh > /root/mandicOBM_linux.log 
   $SH /usr/local/obm/bin/Configurator.sh
fi

# - FIM