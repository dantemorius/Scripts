#!/bin/bash

Autor () {
###########################
##   INSTALAÇÃO DRBD     ##
## Data:  07/10/2015     ##
## Autor: Amauri Hideki  ##
###########################
}

SCRIPT_DRBD() {

vaiaveis(){

# VARIAVEIS

echo -n "Informe o IP do MySQL 01: "
read NODE1
export NODE1

echo -n "Informe o IP do MySQL 02: "
read NODE2
export NODE2

echo -n "Informe o HOSTNAME do MySQL 01: "
read NOME1
export NOME1

echo -n "Informe o HOSTNAME do MySQL 02: "
read NOME2
export NOME2
}

Hostname (){

# AJUSTANDO HOSTNAME
sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
echo $NOME1 > /etc/hostname
echo $NODE1 $NOME1 >> /etc/hosts

ssh root@$NODE2 "sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME2"'/' /etc/sysconfig/network"
ssh root@$NODE2 "echo $NOME2 > /etc/hostname"
ssh root@$NODE2 "echo $NODE2 $NOME2 >> /etc/hosts"

echo ""
echo -e "\\033[1;39m \\033[1;32mHostname Ajustado.\\033[1;39m \\033[1;0m"
echo ""
}

Instalando_e_configurando_ DRBD(){

# Repositorio com DRBD
#rpm -ivh http://dl.atrpms.net/el6-x86_64/atrpms/stable/atrpms-repo-6-7.el6.x86_64.rpm --force
rpm -ivh http://elrepo.org/elrepo-release-6-5.el6.elrepo.noarch.rpm --force

ssh root@$NODE2 "rpm -ivh http://elrepo.org/elrepo-release-6-5.el6.elrepo.noarch.rpm --force"


echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorio DRBD instalado.\\033[1;39m \\033[1;0m"
echo ""


# UPDATE
yum update -y
ssh root@$NODE2 "yum update -y"
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""



# INSTALACAO DE PACOTE DRBD
yum install drbd84-utils.x86_64 kmod-drbd84.x86_64 drbd.x86_64 drbd-kmdl-2.6.32-220.23.1.el6.x86_64 -y
ssh root@$NODE2 "yum install drbd84-utils.x86_64 kmod-drbd84.x86_64 drbd.x86_64 drbd-kmdl-2.6.32-220.23.1.el6.x86_64 -y"


echo ""
echo -e "\\033[1;39m \\033[1;32mDRBD Instalado.\\033[1;39m \\033[1;0m"
echo ""


# Subindo o módulo do DRBD
modprobe drbd
ssh root@$NODE2 "modprobe drbd"

echo ""
echo -e "\\033[1;39m \\033[1;32mMódulo DRBD Ativado.\\033[1;39m \\033[1;0m"
echo ""

# Config DRBD
rm -rf /etc/drbd.conf
cat > "/etc/drbd.conf"<<END


global {
    usage-count no;
}
resource r0 {
  protocol C;
  startup {
    wfc-timeout  30;
    degr-wfc-timeout 120;
 }
  net {
    # the encryption part can be omitted when using a dedicated link for DRBD only:
    # cram-hmac-alg sha1;
    # shared-secret anysecrethere123;
    #allow-two-primaries;
  }
  disk {
    on-io-error   detach;
  }
  syncer {
    rate 120M;
  }
  on $NOME1{
    device     /dev/drbd0;
    disk       /dev/vdb;
    address    10.0.27.6:7788;
    meta-disk  internal;
  }
  on $NOME2{
    device     /dev/drbd0;
    disk       /dev/vdb;
    address    10.0.27.7:7788;
    meta-disk  internal;
  }
}
END

# Copiando o arquivo /etc/drbd.conf para o nó secundário
scp /etc/drbd.conf root@$NODE2:/etc/drbd.conf

# DRBDadm criando MD:
drbdadm create-md r0
ssh root@$NODE2 "drbdadm create-md r0"

# Iniciando serviço DRBD
drbdadm start
ssh root@$NODE2 "drbdadm start"

# Ajustando 
chkconfig drbd on
ssh root@$NODE2 "chkconfig drbd on"
}

Checando_Disco_DRBD (){

#####################################
##      Checando disco DRBD        ##
## Diskless/UpToDate/Inconsistent  ##
##                                 ##
#####################################

# Status DRBD1                     
statusdrbd1=`drbdadm dstate r0 | cut -d "/" -f1`
# Status DRBD2
statusdrbd2=`drbdadm dstate r0 | cut -d "/" -f2`

if [[ Inconsistent = $statusdrbd1 && Inconsistent = $statusdrbd2  ]]; then
	echo "Discos $statusdrbd1/$statusdrbd2, iniciando o Sync"
	drbdadm -- --overwrite-data-of-peer primary r0
	/etc/init.d/drbd status
else
	echo "Discos $statusdrbd1/$statusdrbd2, reconstruindo volumes DRBD"
	drbdadm detach r0
	drbdadm disconnect r0
	drbdadm create-md r0
	/etc/init.d/drbd restart
	/etc/init.d/drbd status
fi


clear
}

vaiaveis
Hostname
Instalando_e_configurando_DRBD
Checando_Disco_DRBD

}