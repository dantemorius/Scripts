#!/bin/bash

##########################################
#      installzbx.sh - v1.5              #
##########################################
#  Instala e configura o Zabbix          #
##########################################
#  Copyright 2014 - Carlos Vinagre - GPL #
##########################################

# - Declarando as variaveis de ambiente
HOSTNAME=/bin/hostname
UZBX=/etc/zabbix
EZBXN=/etc/zabbix/zabbix_agentd_noc.conf
EZBXI=/etc/zabbix/zabbix_agentd_infra.conf
SCRIPTS=/etc/zabbix/scripts
ZBXI=/root/zbx_install
SRVD=ftp://ftpcloud.mandic.com.br
UPZ=/Scripts/Linux/zabbix
ZBXU=/etc/zabbix
TMPZBXN=/tmp/zabbix_agentd_noc.log
TMPZBXI=/tmp/zabbix_agentd_infra.log
HB=/etc/zabbix/scripts/chk_hb.sh
PATH="/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.obm/scripts:/root/bin"

export PATH

# - Criando o diretorio zbx_install para add os pacotes de instalacao do zbx
mkdir $ZBXI

# - Entrando no diretorio zabbix_install
cd $ZBXI

# - Abaixando os pacotes e arquivos de configuracao do Zabbix
wget $SRVD$UPZ/*

# - Pegando o hostname do servidor para add no zbx
NAME=`hostname`


# - Verificando a versão do Zabbix Client instalado no servidor   
VVZBX=`rpm -qa | grep zabbix | cut -d '-' -f1-2 | awk NR==1`
VVZBX1=`rpm -qa | grep zabbix | cut -d '-' -f1-2 | awk NR==2`
UNZBX=`rpm -qa | grep zabbix`

if [ -z $VVZBX ]; then    #Verifica se existem o pacote instalado se nao existir instala os mesmos
   cd $ZBXI    
   rpm -ihv zabbix*.rpm
   mkdir $SCRIPTS
   cp zabbix_agentd_noc.conf $ZBXU -pr
   cp zabbix_agentd_infra.conf $ZBXU -pr        
   cp $ZBXI/*.sh $SCRIPTS -pr
   rm -rf $UZBX/zabbix_agentd.d
   chmod +x $SCRIPTS -R
   sed -i s/popo/$NAME/g $EZBXI
   sed -i s/FW01/$NAME/g $HB
   cp /usr/sbin/zabbix_agentd /usr/sbin/zabbix_noc -pr
   cp /usr/sbin/zabbix_agentd /usr/sbin/zabbix_infra -pr
   cp $ZBXI/zabbix-noc /etc/init.d -pr
   cp $ZBXI/zabbix-infra /etc/init.d -pr
   service zabbix-noc start
   service zabbix-infra start
   chkconfig zabbix-noc on
   chkconfig zabbix-infra on
   chkconfig zabbix-agent off
   rm -rf /etc/init.d/zabbix-agent
   rm -rf /etc/zabbix/zabbix_agentd.conf
   rm -rf /etc/zabbix/conf.d
   rm -rf /usr/sbin/zabbix_agentd
   rm -rf /usr/sbin/zabbix_agent
   rm -rf /etc/zabbix_agentd.conf.rpmsave
   echo 'Instalado Novos Pacotes do Zabbix'
elif [ $VVZBX = 'zabbix-2.2.5' ]; then
   echo 'Pacotes ja atualizados'
elif [ $VVZBX1 = 'zabbix-2.2.5' ]; then
   echo 'Instalado Novos Pacotes do Zabbix'
else
   cd $ZBXI
   service zabbix-agent stop
   yum -y remove $UNZBX
   rm -rf $UZBX/zabbix_agentd.d
   rm -rf $UZBX/zabbix_agentd.conf.rpm\*
   rm $UZBX/$EZBX
   rpm -ihv zabbix\-\*
   mkdir $SCRIPTS
   cp zabbix_agentd_noc.conf $ZBXU -pr
   cp zabbix_agentd_infra.conf $ZBXU -pr        
   cp $ZBXI/*.sh $SCRIPTS -pr
   rm -rf $UZBX/zabbix_agentd.d
   chmod +x $SCRIPTS -R
   sed -i s/popo/$NAME/g $EZBXI
   sed -i s/FW01/$NAME/g $HB
   cp /usr/sbin/zabbix_agentd /usr/sbin/zabbix_noc -pr
   cp /usr/sbin/zabbix_agentd /usr/sbin/zabbix_infra -pr
   cp $ZBXI/zabbix-noc /etc/init.d -pr
   cp $ZBXI/zabbix-infra /etc/init.d -pr
   service zabbix-noc start
   service zabbix-infra start
   chkconfig zabbix-noc on
   chkconfig zabbix-infra on
   chkconfig zabbix-agent off
   rm -rf /etc/init.d/zabbix-agent
   rm -rf /etc/zabbix/zabbix_agentd.conf
   rm -rf /etc/zabbix/conf.d
   rm -rf /usr/sbin/zabbix_agentd
   rm -rf /usr/sbin/zabbix_agent
   rm -rf /etc/zabbix_agentd.conf.rpmsave
   echo 'Atualizados os Pacotes do Zabbix'
fi

# - FIM