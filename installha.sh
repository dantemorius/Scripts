#!/bin/bash

###########################
#    ATIVACAO FIREWALL    #
# Data:  26/06/2014       #
# Autor: Leonardo Araujo  #
###########################


# ALERTA DE AJUSTE INICIAL

clear
echo ""
echo ""
echo "
 __  __       _   _    ___
|  \/  |  _  | | | |  / _ \
| \  / | (_) | |_| | | /_\ |
| |\/| |     |  _  | |  _  |
| |  | |  _  | | | | | | | |
|_|  |_| (_) |_| |_| |_| |_|

"
echo ""
echo "########################################"
echo "#  Para utilizar este script, deve-se  #"
echo "#  Configurar chave RSA trocada entre  #"
echo "#        os Servidores Linux           #"
echo "########################################"
echo ""

# DEFININDO VARIAVEIS

echo -n "Informe o IP do MySql 01: "
read NODE1
export NODE1

echo -n "Informe o IP do MySql 02: "
read NODE2
export NODE2

echo -n "Informe o HOSTNAME do MySql 01: "
read NOME1
export NOME1

echo -n "Informe o HOSTNAME do MySql 02: "
read NOME2
export NOME2

echo -n "Informe o RANGE de IP's BACKEND: "
read BACKEND
export BACKEND
echo ""

# VALIDACAO CHAVE RSA
#CHAVE=`ssh -o StrictHostKeyChecking=no root@$NODE2 "ping -c1 localhost" > /dev/null 2>&1 ; echo $?`
#if [ $CHAVE -ne 0 ]
#then
#        echo "Falha: A chave trocada nao foi configurada."
#        echo ""
#        echo 'Para configurar utilize o seguinte comando: \n
#               "ssh-keygen -t rsa"
#              Pressione ENTER ate concluir.
#               Em seguida: "ssh-copy-id root@$NODE2"'
#        echo ""
#        exit 1
#fi

#echo ""
#echo -e "\\033[1;39m \\033[1;32mChave RSA trocada com Sucesso.\\033[1;39m \\033[1;0m"
#echo ""




############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O                          ####
#############################################################
############################################################

preparacaoSO(){


# INSTALACAO REPOSITORIO EPEL
#rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force
rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
#ssh root@$NODE2 "rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --force"
ssh root@$NODE2 "rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force"
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorio EPEL instalado.\\033[1;39m \\033[1;0m"
echo ""

# UPDATE
yum update -y
ssh root@$NODE2 "yum update -y"
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""

# INSTALACAO DE PACOTES
yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 heartbeat perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat sshpass nc.x86_64 pwgen.x86_64 screen -y

chkconfig heartbeat on

ssh root@$NODE2 "yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 heartbeat perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat sshpass nc.x86_64 pwgen.x86_64 -y"

ssh root@$NODE2 "chkconfig heartbeat on"

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc && yes | mv bashrc /root/.bashrc
scp /root/.bashrc root@$NODE2:/root/.bashrc


# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so

ssh root@$NODE2 "yum install snoopy -y"
ssh root@$NODE2 "rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so"


# CONFIG SELINUX
sed -i 's/=permissive/=disabled/' /etc/sysconfig/selinux
ssh root@$NODE2 "sed -i 's/=permissive/=disabled/' /etc/sysconfig/selinux"

echo ""
echo -e "\\033[1;39m \\033[1;32mselinux ajustado\\033[1;39m \\033[1;0m"
echo ""

# CONFIG SYSCTL.CONF
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
echo "# CONFIG para NAT e Heartbeat" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0"  >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
scp /etc/sysctl.conf root@$NODE2:/etc/sysctl.conf

echo ""
echo -e "\\033[1;39m \\033[1;32msysctl ajustado.\\033[1;39m \\033[1;0m"
echo ""

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off
ssh root@$NODE2 "/etc/init.d/iptables stop"
ssh root@$NODE2 "chkconfig iptables off"

echo ""
echo -e "\\033[1;39m \\033[1;32mIptables desabilitado.\\033[1;39m \\033[1;0m"
echo ""

# ATIVANDO O RSYSLOG
/etc/init.d/rsyslog start
chkconfig rsyslog on
ssh root@$NODE2 "/etc/init.d/rsyslog start"
ssh root@$NODE2 "chkconfig rsyslog on"

echo ""
echo -e "\\033[1;39m \\033[1;32mRsyslog Iniciado.\\033[1;39m \\033[1;0m"
echo ""

# BAIXANDO ARQUIVOS CONFIG

sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/authkeys /etc/ha.d/
chmod 600 /etc/ha.d/authkeys
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ha.cf /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/haresources /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ldirectord.cf /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ldirectord-1.0.4-1.el6.x86_64.rpm /root/

scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$NODE2:/etc/ha.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mArquivos de Configuracao OK.\\033[1;39m \\033[1;0m"
echo ""

# DEFININDO O HOSTNAME
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



############################################################
#############################################################
#  AJUSTES ALTA DISPONIBILIDADE - HEARTBEAT               ####
#############################################################
############################################################


# CONFIGURA OS IPs VIPS NO ARQUIVOS HARESOURCES
ipvip() {
echo "#################################"
echo "# CONFIGURANDO O HEARTBEAT      #"
echo "#################################"
echo ""
read -p 'Digite a quantidade de IPs VIPs: ' num_ips
count=0
cont=$(( $cont + 1 ))
while [[ $num_ips -ge $cont  ]] ; do
read -p "Digite o IP $cont: " ipvip

        echo $NOME1 $ipvip"/24/eth0" >> /etc/ha.d/haresources
        cont=$(( $cont + 1 ))
done
}

gateway() {
IPBACKEND=`ifconfig eth1 | grep "inet end.:" | awk '{print $3}'`
GW=`echo $IPBACKEND | cut -d"." -f1,2,3`
echo $NOME1 $GW".1/24/eth1:1 # GW Backend" >> /etc/ha.d/haresources
}


# CONFIGURA OS IPs DOS NÓS NO ARQUIVO HA.CF
hacf() {
SENHA=`pwgen -Byns 15 1`
sed -i 's/SENHA/'"$SENHA"'/' /etc/ha.d/authkeys
chmod 600 /etc/ha.d/authkeys

sed -i 's/ucast1/ucast eth0 '"$NODE1"'/' /etc/ha.d/ha.cf
sed -i 's/ucast2/ucast eth0 '"$NODE2"'/' /etc/ha.d/ha.cf
sed -i 's/node1/node '"$NOME1"'/' /etc/ha.d/ha.cf
sed -i 's/node2/node '"$NOME2"'/' /etc/ha.d/ha.cf

scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$NODE2:/etc/ha.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mHEARTBEAT Ajustado.\\033[1;39m \\033[1;0m"
echo ""

}

syncall(){

scp /etc/sysctl.conf root@$NODE2:/etc/
scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/

}




################################
#################################
# REINICIALIZACAO DO SERVIDOR ####
#################################
################################


reinicializacao() {
echo -n "Reiniciar o Servidor para Aplicar os Updates e Configuracoes? [ y | n ]:  "
read OPCAO

case $OPCAO in
        y)
        reiniciar
        ;;
        n)
        exit
        ;;
        *)
        reinicializacao
        ;;
        esac
}

reiniciar()
{
ssh root@$NODE2 "/sbin/reboot"
/sbin/reboot
}



################################
#################################
# CHAMADA DE FUNÃ‡Ã•ES        ####
#################################
################################

preparacaoSO
ipvip
gateway
hacf
syncall
reinicializacao