#!/bin/bash

############################
#    ATIVACAO FIREWALL     #
# Data:  20/12/2016        #
# Autor: Leonardo Araujo   #
# Atualização: Tiago Silva #
############################


# ALERTA DE AJUSTE INICIAL

clear
echo ""
echo "
 __  __       ______ __          __
|  \/  |  _  |  ____|\ \        / /
| \  / | (_) | |__    \ \  /\  / /
| |\/| |     |  __|    \ \/  \/ /
| |  | |  _  | |        \  /\  /
|_|  |_| (_) |_|         \/  \/
                                                                       
"

inicio() {
echo -e "\\033[1;39m \\033[1;32mSELECIONE O TIPO DE FIREWALL QUE DESEJA INSTALAR:\\033[1;39m \\033[1;0m"
echo ""
echo "[ 1 ] FIREWALL STANDALONE"
echo "[ 2 ] FIREWALL EM ALTA DISPONIBILIDADE "
echo ""
echo -n "Digite a opcao desejada: "
read OPCAO
echo ""

case $OPCAO in
	1)
	standalone
	;;
	2)
	failover
	;;
	*)
	inicio
	;;
	esac
}


standalone () {

##Configurando Backend
echo -n "Digite o Ip de backend do Firewall"
read BKNFW
export BKNFW

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth1

echo 'DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=$BKNFW1
NETMASK=255.255.255.0' > /etc/sysconfig/network-scripts/ifcfg-eth1

/etc/init.d/network restart

# DEFININDO VARIAVEIS

echo -n "Informe o IP do Firewall: "
read NODE1
export NODE1

echo -n "Informe o HOSTNAME do Firewall: "
read NOME1
export NOME1

echo -n "Informe o RANGE de IP's BACKEND: "
read BACKEND
export BACKEND
echo ""


#############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O    			  ####
#############################################################
#############################################################

preparacaoSO(){


# INSTALACAO REPOSITORIO EPEL & ATOMIC
wget -q -O - http://www.atomicorp.com/installers/atomic | sh
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
rpm -Uvh epel-release-latest-6.noarch.rpm
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorios EPEL e ATOMIC instalados.\\033[1;39m \\033[1;0m"
echo ""

# UPDATE
yum update -y
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""

# INSTALACAO DE PACOTES
yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet nc.x86_64 pwgen.x86_64 screen lsof setroubleshoot setools -y

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
#wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc && yes | mv bashrc /root/.bashrc


echo '# .bashrc

# User specific aliases and functions
Normal="\[\\033[0m\]"
Vermelho="\[\\033[1;31m\]"
Verde="\[\\033[1;32m\]"
Amarelo="\[\\033[1;33m\]"
Azul="\[\\033[1;34m\]"
Roxo="\[\\033[1;35m\]"
Ciano="\[\\033[1;36m\]"
Branco="\[\\033[1;37m\]"
PS1="$Normal$Azul[$Branco(\t) $Verde\u$Vermelho@$Amarelo\h$Verde $Ciano\w$Azul]$Branco\\$ $Normal"

alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"

alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

export HISTCONTROL=ignoredups

function share_history {
    history -a
    history -r
}
PROMPT_COMMAND="share_history"
shopt -u histappend
export HISTSIZE=9999
export HISTTIMEFORMAT="%F %T "

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi' > /root/.bashrc

source /root/.bashrc


##Ativando monitoramento do audit.log pelo sealert
sealert -b


echo '
#Proteção contra Buffer Overflow
kernel.exec-shield=1

###Randomizar espaços de memória para evitar ataques direcionados a serviços com endereços padrão:
kernel.randomize_va_space=1

##Otimização de swap (calcular de acordo com memória da máquina):
vm.swappiness=60

##Otimização de leitura e escrita:
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 2500
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf

# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so

# CONFIGURACAO SERVERLOGS
sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart

# CONFIG SELINUX
sed -i 's/=enforcing/=permissive/' /etc/selinux/config

echo ""
echo -e "\\033[1;39m \\033[1;32mselinux ajustado\\033[1;39m \\033[1;0m"
echo ""

# INSTALL OSSEC
yum install ossec-hids.x86_64 ossec-hids-server.x86_64 -y --enablerepo=atomic
sed -i 's/daniel.cid@xxx.com/operacoes@mandic.net.br/' /var/ossec/etc/ossec.conf     
sed -i 's/smtp.xxx.com./localhost/' /var/ossec/etc/ossec.conf
sed -i 's/ossecm@ossec.xxx.com./ossec-'$NOME1'@mandic.net.br/' /var/ossec/etc/ossec.conf     
sed -i '100 a  \    <white_list>201.20.44.2</white_list>' /var/ossec/etc/ossec.conf
sed -i '100 a  \    <white_list>177.70.100.5</white_list>' /var/ossec/etc/ossec.conf
sed -i '100 a  \    <white_list>'$NODE1'</white_list>' /var/ossec/etc/ossec.conf
sed -i 's/>600</>1800</' /var/ossec/etc/ossec.conf
/etc/init.d/ossec-hids restart
chkconfig ossec-hids on

echo ""
echo -e "\\033[1;39m \\033[1;32mOSSEC Instalado e Configurado\\033[1;39m \\033[1;0m"
echo ""


# CONFIG SYSCTL.CONF
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
echo "# CONFIG para NAT e Heartbeat" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0"  >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf

echo ""
echo -e "\\033[1;39m \\033[1;32msysctl ajustado.\\033[1;39m \\033[1;0m"
echo ""

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off
mv /etc/init.d/iptables /etc/init.d/.iptables_OLD_NAO_MEXER
mv /etc/init.d/ip6tables /etc/init.d/.ip6tables_OLD_NAO_MEXER
ln -s /etc/init.d/firewall /etc/init.d/iptables

echo ""
echo -e "\\033[1;39m \\033[1;32mIptables desabilitado.\\033[1;39m \\033[1;0m"
echo ""

# ATIVANDO O RSYSLOG
/etc/init.d/rsyslog start
chkconfig rsyslog on

echo ""
echo -e "\\033[1;39m \\033[1;32mRsyslog Iniciado.\\033[1;39m \\033[1;0m"
echo ""

# BAIXANDO ARQUIVOS CONFIG
#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall_new -O /etc/init.d/firewall

touch /etc/init.d/firewall

echo '#!/bin/bash
# Firewall      Start iptables firewall
#
# chkconfig: 2345 08 92
# description:  Starts, stops and saves iptables firewall
#
# config: /etc/sysconfig/iptables
# config: /etc/sysconfig/iptables-config
#
### BEGIN INIT INFO
# Provides: iptables
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop iptables firewall
# Description: Start, stop and save iptables firewall
### END INIT INFO
##############################################
#
# SCRIPT DE FIREWALL
###############################################
REDEBACKEND="IPBACKEND"
IPTABLES=`which iptables`

function OK()   {
echo -e "Firewall \\033[1;39m [ \\033[1;32mOK\\033[1;39m ]\\033[1;0m"
                }

function FALHOU()       {
echo -e "Firewall \\033[1;39m [ \\033[1;31mFALHOU\\033[1;39m ]\\033[1;0m"
}

function STOP(){

###############################################################
# Flushing filter and nat tables                              #
###############################################################
$IPTABLES -F
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -X
$IPTABLES -F -t nat
$IPTABLES -F -t raw

OK
}

function START(){
###############################################################
# Default Policies                                            #
###############################################################
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P POSTROUTING ACCEPT -t nat
$IPTABLES -P PREROUTING ACCEPT -t nat
$IPTABLES -P OUTPUT ACCEPT -t nat

modprobe ip_conntrack_ftp
##############################################################
# REGRAS de INPUT -                                          #
##############################################################
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

##CLUSTER
$IPTABLES -A INPUT -s "'$NODE1'" -j ACCEPT
$IPTABLES -A INPUT -s "'$NODE2'" -j ACCEPT

#Zabbix
$IPTABLES -A INPUT -s noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p1.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p2.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p3.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p4.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p5.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p6.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p7.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s pnoc-rj.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s pnoc.mandic.net.br -j ACCEPT

## Rede local
$IPTABLES -A INPUT -s $REDEBACKEND -j ACCEPT

### SSH Access###
$IPTABLES -A INPUT -s 177.70.100.5 -p tcp --dport 22 -j ACCEPT

### Services Access
$IPTABLES -A INPUT -p udp -s 177.70.106.7 --dport 514 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m multiport --dport 10050:10052 -j ACCEPT
$IPTABLES -A INPUT -p udp --dport 694 -j ACCEPT

##############################Regras AppAssure/RapidRecovery##############################
$IPTABLES -A INPUT -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A INPUT -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
#Ranges:
#187.191.98.0
#187.191.99.0
$IPTABLES -A INPUT -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A INPUT -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
##########################################################################################


$IPTABLES -A INPUT -s 177.70.100.56 -p tcp --dport 3389 -j ACCEPT

##ICMP
$IPTABLES -A INPUT -p icmp -j ACCEPT

##############################################################
# REGRAS de FORWARD -                                        #
##############################################################

$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A FORWARD -s $REDEBACKEND -j ACCEPT
$IPTABLES -A FORWARD -p icmp -j ACCEPT

#Monitoracao ZABBIX
$IPTABLES -A FORWARD -s noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p1.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p2.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p3.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p4.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p5.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p6.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p7.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s pnoc-rj.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s pnoc.mandic.net.br -j ACCEPT

#Gerenciamento
$IPTABLES -A FORWARD -p tcp --dport 3389 -j ACCEPT
$IPTABLES -A FORWARD -p tcp -m multiport --dport 5555,3389,10050:10052,9006:9009,5500:5700,7000:7010 -j ACCEPT
$IPTABLES -A FORWARD -s 177.70.100.5 -p tcp --dport 22 -j ACCEPT
$IPTABLES -A FORWARD -p udp -s 177.70.106.7 --dport 514 -j ACCEPT


##############################Regras AppAssure/RapidRecovery##############################
$IPTABLES -A FORWARD -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
#Ranges:
#187.191.98.0
#187.191.99.0
$IPTABLES -A FORWARD -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9000:9300 -j ACCEPT
##########################################################################################


$IPTABLES -A OUTPUT -p udp -d 177.70.106.7 --dport 514 -j ACCEPT

## REGRAS IPSEC
##################################################################
##$IPTABLES -A INPUT -p esp -j ACCEPT
##$IPTABLES -A INPUT -p udp --dport 500 -j ACCEPT
##$IPTABLES -A INPUT -p tcp --dport 500 -j ACCEPT
##$IPTABLES -A INPUT -p udp --dport 4500 -j ACCEPT
##$IPTABLES -A INPUT -s 186.237.171.90 -j ACCEPT
##$IPTABLES -A FORWARD -s 186.237.171.90 -j ACCEPT
##$IPTABLES -A FORWARD -s 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -d 10.164.30.0/24 -j ACCEPT
##$IPTABLES -A FORWARD -s 10.164.30.0/24 -d 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -j ACCEPT
##$IPTABLES -t nat -A POSTROUTING -s 10.164.30.0/24 -d 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -j ACCEPT
##$IPTABLES -t nat -A POSTROUTING -s 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -d 10.164.30.0/24 -j ACCEPT
###################################################################

## OPENVPN ###
#$IPTABLES -A INPUT -p udp --dport 1194 -j ACCEPT
#$IPTABLES -A INPUT -p tcp --dport 1194 -j ACCEPT
### ------ ###

## Regras de gerenciamento ##
#$IPTABLES -A FORWARD -d 10.164.30.4 -p tcp -m multiport --dport 21,5500:5700 -j ACCEPT



# ACESSO REMOTO

# APPASSURE CONEXAO

# APPASSURE TRANSFERENCIA


### Services Access
#NAT 1x1 Aos servidores que precisam ter IP dedicado de saida
#MAILBOX01
#$IPTABLES -t nat -A PREROUTING -d 177.70.120.108  -j DNAT --to 10.124.0.6
#$IPTABLES -t nat -A POSTROUTING -s 10.124.0.6 -j SNAT --to 177.70.120.108

# ZABBIX


### Nat para rede backend
$IPTABLES -t nat -A POSTROUTING -s $REDEBACKEND -o eth0 -j MASQUERADE


OK

#SINCRONIZA REGRAS COM FW2
if [ "$(hostname)" = "'$NOME2'" ];then

        IPFW02=$NODE2
        FWFILE=/etc/init.d/firewall

        nc -z -w 2 $IPFW02 22

        if [ $? -eq 0 ];then
                scp -q $FWFILE root@$IPFW02:$FWFILE
                echo "Sincronizando regras com '$NOME2'"
                ssh root@$IPFW02 $FWFILE restart
        fi
fi


}

#
#FW options
#
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

                *)

                echo -e "Tente $0 {start|stop|restart}"
                ;;
        esac
		

		' > /etc/init.d/firewall
		
chmod +x /etc/init.d/firewall
chkconfig firewall on

echo ""
echo -e "\\033[1;39m \\033[1;32mArquivos de Configuracao OK.\\033[1;39m \\033[1;0m"
echo ""

# DEFININDO O HOSTNAME
sed -i 's/HOSTNAME=/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
echo $NOME1 > /etc/hostname
echo $NODE1 $NOME1 >> /etc/hosts

echo ""
echo -e "\\033[1;39m \\033[1;32mHostname Ajustado.\\033[1;39m \\033[1;0m"
echo ""

}


###########################################################
############################################################
#  AJUSTES DE REGRAS DE FIREWALL			   			 ####
############################################################
###########################################################

firewall() {

# DEFININDO IP's DOS NÓS SCRIPT FIREWALL
sed -i 's/IPBACKEND/'"$BACKEND\/24"'/' /etc/init.d/firewall
sed -i 's/NODE1/'"$NODE1"'/' /etc/init.d/firewall
sed -i 's/NOME1/'"$NOME1"'/' /etc/init.d/firewall
sed -i '/NODE2/d' /etc/init.d/firewall

LINE=`grep -n "#SINCRONIZA" /etc/init.d/firewall  | cut -d":" -f1`
LINE2=$(( $LINE+ 15))

sed -i ''$LINE','$LINE2'd' /etc/init.d/firewall

echo ""
echo -e "\\033[1;39m \\033[1;32mScript de Firewall Ajustado.\\033[1;39m \\033[1;0m"
echo ""


#  GERA REGRAS NAT PARA ACESSO REMOTO  #

ARQNAT="/tmp/NAT.txt"

echo "###############################################"
echo "# CRIANDO REGRAS DE NAT PARA ACESSO REMOTO    #"
echo "###############################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

echo -n "Informe a Porta Destino... ex.: (22 ou 3389): "
read PORTADEST
export PORTADEST

PORTAORI=6999
CONT_PORT=$(( $PORTAORI + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:$PORTADEST" >> $ARQNAT
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
done

REGRAS=`cat $ARQNAT`
sed -i '/# ACESSO REMOTO/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para ACESSO REMOTO criadas.\\033[1;39m \\033[1;0m"
echo ""



#  GERA REGRAS NAT PARA ZABBIX  #

ARQNAT="/tmp/NAT.txt"

echo "#####################################################"
echo "#  CRIANDO REGRAS DE NAT PARA MONITORAMENTO ZABBIX  #"
echo "#####################################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

PORTAORI=7999
CONT_PORT=$(( $PORTAORI + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:10052"  >> $ARQNAT
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
done
echo '$IPTABLES' "-t nat -A POSTROUTING -s $BACKEND/24 -d noc.mandic.net.br -p tcp --dport 10052 -j SNAT --to $VIP" >> $ARQNAT
REGRAS=`cat $ARQNAT`
sed -i '/# ZABBIX/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para Monitoramento Zabbix criadas.\\033[1;39m \\033[1;0m"
echo ""



#  GERA REGRAS NAT PARA BACKUP APPASSURE  #

ARQNAT="/tmp/NAT.txt"
ARQNAT2="/tmp/NAT2.txt"

echo "################################################"
echo "# CRIANDO REGRAS DE NAT PARA BACKUP APPASSURE  #"
echo "################################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))


PORTAORI=9099
CONT_PORT=$(( $PORTAORI + 1 ))

PORTADEST=9199
CONT_PORTADEST=$(( $PORTADEST + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:9006" >> $ARQNAT
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORTADEST -j DNAT --to $SERVER:$CONT_PORTADEST" >> $ARQNAT2
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
	CONT_PORTADEST=$(( $CONT_PORTADEST + 1 ))
done

sed -i '/# APPASSURE CONEXAO/ r '"$ARQNAT"'' /etc/init.d/firewall
sed -i '/# APPASSURE TRANSFERENCIA/ r '"$ARQNAT2"'' /etc/init.d/firewall
rm -f $ARQNAT $ARQNAT2

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para BACKUP APPASSURE criadas.\\033[1;39m \\033[1;0m"
echo ""

}


regrasmysql() {
echo -n "Deseja criar regras de NAT para MySQL ? [ y | n ]:  "
read OPCAO

case $OPCAO in
	y)
	criarnatmysql
	;;
	n)
	break
	;;
	*)
	regrasmysql
	;;
	esac
}

criarnatmysql()
{

#  GERA REGRAS NAT PARA MYSQL  #

ARQNAT="/tmp/NAT.txt"


echo "######################################"
echo "# CRIANDO REGRAS DE NAT PARA MYSQL   #"
echo "######################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe o Servidor Remoto: " 
read SERVER

echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport 3306 -j DNAT --to $SERVER:3306" >> $ARQNAT
sed -i '/# MYSQL/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegra NAT para MYSQL criada.\\033[1;39m \\033[1;0m"
echo ""

}



regrasmssql() {
echo -n "Deseja criar regras de NAT para MSSQL ? [ y | n ]:  "
read OPCAO

case $OPCAO in
	y)
	criarnatmssql
	;;
	n)
	break
	;;
	*)
	regrasmssql
	;;
	esac
}

criarnatmssql()
{

#  GERA REGRAS NAT PARA MSSQL  #

ARQNAT="/tmp/NAT.txt"


echo "######################################"
echo "# CRIANDO REGRAS DE NAT PARA MSSQL   #"
echo "######################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe o Servidor Remoto: " 
read SERVER

echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport 1433 -j DNAT --to $SERVER:1433" >> $ARQNAT
sed -i '/# MSSQL/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegra NAT para MSSQL criada.\\033[1;39m \\033[1;0m"
echo ""

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
/sbin/reboot
}



################################
#################################
# CHAMADA DE FUNÇÕES	      ####
#################################
################################

preparacaoSO
firewall
regrasmysql
regrasmssql
reinicializacao

}


failover () {

interfaces (){
echo -n "Informe o IP do Firewall 01: "
	read NODE1
	export NODE1

echo -n "Informe o IP do Firewall 02: "
	read NODE2
	export NODE2

echo -n "Informe o HOSTNAME do Firewall 01: "
	read NOME1
	export NOME1

echo -n "Informe o HOSTNAME do Firewall 02: "
	read NOME2
	export NOME2

echo -n "Informe o RANGE de IP's BACKEND: "
	read BACKEND
	export BACKEND

##configurando backend
echo -n "Digite o Ip de backend do Firewall 01: "
	read BKNFW1
	export BKNFW1

echo -n "Digite o Ip de backend do Firewall 02: "
	read BKNFW2
	export BKNFW2

echo -n "Digite a senha do Firewall 02: "
	read -s PASSWDFW02
	export PASSWDFW02


# DEFININDO O HOSTNAME FW01
sed -i 's/HOSTNAME=/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
echo $NOME1 > /etc/hostname
hostname $NOME1


		echo ""
			echo -e "\\033[1;39m \\033[1;32mHostname Ajustado.\\033[1;39m \\033[1;0m"
		echo ""

# INSTALACAO REPOSITORIO EPEL & ATOMIC - FW01
	wget -q -O - http://www.atomicorp.com/installers/atomic | sh
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    rpm -Uvh epel-release-latest-6.noarch.rpm
		
		echo ""
			echo -e "\\033[1;39m \\033[1;32mRepositorios EPEL e ATOMIC instalados.\\033[1;39m \\033[1;0m"
		echo ""
		
			yum update -y
			
##Instalando SSHPASS - FW01
			yum install sshpass -y
			
			
		echo ""
			echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
		echo ""

	sleep 2
	

##Removendo chaves préviamente configuradas para evitar duplicidade
rm -rf /root/.ssh/id_rsa*
ssh-keygen -R $NOME2


sshpass -p $PASSWDFW02 ssh $NODE2 "rm -rf /root/.ssh/id_rsa*"
sshpass -p $PASSWDFW02 ssh $NODE2 "ssh-keygen -R $NOME1"

##Gerando arquivo para não chegar chave de host FW01/FW02
touch /root/.ssh/config

echo 'StrictHostKeyChecking no
UserKnownHostsFile=/dev/null' > /root/.ssh/config

/etc/init.d/sshd restart

sshpass -p $PASSWDFW02 scp ~/.ssh/config root@$NODE2:/root/.ssh/

sshpass -p $PASSWDFW02 ssh $NODE2 "/etc/init.d/sshd restart"	


# DEFININDO O HOSTNAME FW02
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME2"'/' /etc/sysconfig/network"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "echo '"$NOME2"' > /etc/hostname"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "hostname '"$NOME2"'"
	
	
# INSTALACAO REPOSITORIO EPEL & ATOMIC - FW02
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "wget -q -O - http://www.atomicorp.com/installers/atomic | sh"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm"
    sshpass -p $PASSWDFW02 ssh root@$NODE2 "rpm -Uvh epel-release-latest-6.noarch.rpm"

# UPDATE FW02
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "yum update -y"


##Instalando SSHPASS - FW02
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "yum install sshpass -y"
	

##Configurando Interfaces
##Criando Cópia eth0 -> eth1
	cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth1

echo 'DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR='"$BKNFW2"'
NETMASK=255.255.255.0' > /etc/sysconfig/network-scripts/ifcfg-eth1

##Copiando arquivo de configuração para FW02


	sshpass -p $PASSWDFW02 scp /etc/sysconfig/network-scripts/ifcfg-eth1 root@$NODE2:/etc/sysconfig/network-scripts/ifcfg-eth1
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "ifdown eth1"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "ifup eth1"

##Criando arquivo eth1 para FW01
echo 'DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR='"$BKNFW1"'
NETMASK=255.255.255.0' > /etc/sysconfig/network-scripts/ifcfg-eth1

ifdown eth1
ifup eth1


##trocando as chaves via backend
ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
sshpass -p $PASSWDFW02 ssh-copy-id -i ~/.ssh/id_rsa.pub $BKNFW2

##Configurando HOSTS
sed -i "/FW/d" /etc/hosts


echo $BKNFW1 $NOME1 >> /etc/hosts
echo $BKNFW2 $NOME2 >> /etc/hosts

##Copiando Hosts para FW02
sshpass -p $PASSWDFW02 scp /etc/hosts root@$BKNFW2:/etc/hosts

sleep 2


##Criando script para troca de chaves do FW02 para FW01
echo "#/bin/bash
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ''" > chgkey1.sh



echo 'sshpass -p' "$PASSWDFW02" 'ssh-copy-id -i /root/.ssh/id_rsa.pub '"$NODE1"'' > chgkey2.sh
chmod +x /root/chgkey*.sh

##Copiando e executando script para troca de chaves no FW02
sshpass -p $PASSWDFW02 scp chgkey1.sh root@$BKNFW2:/root/chgkey1.sh
sshpass -p $PASSWDFW02 scp chgkey2.sh root@$BKNFW2:/root/chgkey2.sh
sshpass -p $PASSWDFW02 ssh $BKNFW2 "sh -x /root/chgkey1.sh"
sshpass -p $PASSWDFW02 scp /root/.ssh/config root@$BKNFW2:/root/.ssh/config
sshpass -p $PASSWDFW02 ssh $BKNFW2 "sh -x /root/chgkey2.sh"

sleep 2


PINGGROUP=`echo $NODE1 | cut -d"." -f1,2,3`
}

############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O    			  ####
#############################################################
############################################################

preparacaoSO(){

# INSTALACAO DE PACOTES
yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat nc.x86_64 pwgen.x86_64 screen lsof setroubleshoot setools -y

chkconfig heartbeat on

ssh root@$BKNFW2 "yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat nc.x86_64 pwgen.x86_64 screen lsof setroubleshoot setools -y"

ssh root@$BKNFW2 "chkconfig heartbeat on"

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
#wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc && yes | mv bashrc /root/.bashrc


echo '# .bashrc

# User specific aliases and functions
Normal="\[\\033[0m\]"
Vermelho="\[\\033[1;31m\]"
Verde="\[\\033[1;32m\]"
Amarelo="\[\\033[1;33m\]"
Azul="\[\\033[1;34m\]"
Roxo="\[\\033[1;35m\]"
Ciano="\[\\033[1;36m\]"
Branco="\[\\033[1;37m\]"
PS1="$Normal$Azul[$Branco(\t) $Verde\u$Vermelho@$Amarelo\h$Verde $Ciano\w$Azul]$Branco\\$ $Normal"

alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"

alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

export HISTCONTROL=ignoredups

function share_history {
    history -a
    history -r
}
PROMPT_COMMAND="share_history"
shopt -u histappend
export HISTSIZE=9999
export HISTTIMEFORMAT="%F %T "

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi' > /root/.bashrc

source /root/.bashrc

scp /root/.bashrc root@$BKNFW2:/root/.

##Ativando monitoramento do audit.log pelo sealert
sealert -b


echo '
#Proteção contra Buffer Overflow
kernel.exec-shield=1

###Randomizar espaços de memória para evitar ataques direcionados a serviços com endereços padrão:
kernel.randomize_va_space=1

##Otimização de swap (calcular de acordo com memória da máquina):
vm.swappiness=60

##Otimização de leitura e escrita:
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 2500
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf


# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so
ssh root@$BKNFW2 "yum install snoopy -y"
ssh root@$BKNFW2 "rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so"

echo ""
echo -e "\\033[1;39m \\033[1;32mSNOOPY Instalado\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURACAO SERVERLOGS
sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart
scp /etc/rsyslog.conf root@$NODE2:/etc/
ssh root@$NODE2 "/etc/init.d/rsyslog restart"

echo ""
echo -e "\\033[1;39m \\033[1;32mSERVERLOGS Configurado\\033[1;39m \\033[1;0m"
echo ""

# CONFIG SELINUX
sed -i 's/=enforcing/=permissive/' /etc/selinux/config
ssh root@$BKNFW2 "sed -i 's/=enforcing/=permissive/' /etc/selinux/config"

echo ""
echo -e "\\033[1;39m \\033[1;32mselinux ajustado\\033[1;39m \\033[1;0m"
echo ""

sealert -b

echo ""
echo -e "\\033[1;39m \\033[1;32mAtivado o serviço de Logs do [SELinux] \\033[1;39m \\033[1;0m"
echo ""

touch /var/log/audit.log
sealert -a /var/log/audit.log

echo ""
echo -e "\\033[1;39m \\033[1;32mAtivado o serviço de Auditoria de Logs do [SELinux] \\033[1;39m \\033[1;0m"
echo ""

# INSTALL OSSEC
yum install ossec-hids ossec-hids-server -y --enablerepo=atomic
sed -i 's/daniel.cid@xxx.com/operacoes@mandic.net.br/' /var/ossec/etc/ossec.conf     
sed -i 's/smtp.xxx.com./localhost/' /var/ossec/etc/ossec.conf
sed -i 's/ossecm@ossec.xxx.com./ossec-'$NOME1'@mandic.net.br/' /var/ossec/etc/ossec.conf     
sed -i '100 a  \    <white_list>201.20.44.2</white_list>' /var/ossec/etc/ossec.conf
sed -i '100 a  \    <white_list>177.70.100.5</white_list>' /var/ossec/etc/ossec.conf
sed -i '100 a  \    <white_list>'$NODE1'</white_list>' /var/ossec/etc/ossec.conf
sed -i '100 a  \    <white_list>'$NODE2'</white_list>' /var/ossec/etc/ossec.conf
sed -i 's/>600</>1800</' /var/ossec/etc/ossec.conf
/etc/init.d/ossec-hids restart
chkconfig ossec-hids on

ssh root@$NODE2 "yum install ossec-hids ossec-hids-server -y"
scp /var/ossec/etc/ossec.conf root@$NODE2:/var/ossec/etc/ossec.conf
ssh root@$NODE2 "sed -i 's/ossec-'$NOME1'@mandic.net.br/ossec-'$NOME2'@mandic.net.br/' /var/ossec/etc/ossec.conf"
ssh root@$NODE2 "/etc/init.d/ossec-hids restart && chkconfig ossec-hids on"

echo ""
echo -e "\\033[1;39m \\033[1;32mOSSEC Instalado e Configurado\\033[1;39m \\033[1;0m"
echo ""


# CONFIG SYSCTL.CONF
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
echo "# CONFIG para NAT e Heartbeat" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0"  >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
echo "#Proteção contra Buffer Overflow" >> /etc/sysctl.conf
echo "kernel.exec-shield=1" >> /etc/sysctl.conf
echo "##Randomizar espaços de memória para evitar ataques direcionados a serviços com endereços padrão:" >> /etc/sysctl.conf
echo "kernel.randomize_va_space=1" >> /etc/sysctl.conf


scp /etc/sysctl.conf root@$BKNFW2:/etc/sysctl.conf

echo ""
echo -e "\\033[1;39m \\033[1;32msysctl ajustado.\\033[1;39m \\033[1;0m"
echo ""

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off
mv /etc/init.d/iptables /etc/init.d/.iptables_OLD_NAO_MEXER
mv /etc/init.d/ip6tables /etc/init.d/.ip6tables_OLD_NAO_MEXER
ln -s /etc/init.d/firewall /etc/init.d/iptables
ssh root@$BKNFW2 "/etc/init.d/iptables stop"
ssh root@$BKNFW2 "chkconfig iptables off"
ssh root@$BKNFW2 "mv /etc/init.d/iptables /etc/init.d/.iptables_OLD_NAO_MEXER"
ssh root@$BKNFW2 "mv /etc/init.d/ip6tables /etc/init.d/.ip6tables_OLD_NAO_MEXER"
ssh root@$BKNFW2 "ln -s /etc/init.d/firewall /etc/init.d/iptables"


echo ""
echo -e "\\033[1;39m \\033[1;32mIptables desabilitado.\\033[1;39m \\033[1;0m"
echo ""

# ATIVANDO O RSYSLOG
/etc/init.d/rsyslog start
chkconfig rsyslog on
ssh root@$BKNFW2 "/etc/init.d/rsyslog start"
ssh root@$BKNFW2 "chkconfig rsyslog on"

echo ""
echo -e "\\033[1;39m \\033[1;32mRsyslog Iniciado.\\033[1;39m \\033[1;0m"
echo ""

# BAIXANDO ARQUIVOS CONFIG
#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall_new -O /etc/init.d/firewall

touch /etc/init.d/firewall

echo '#!/bin/bash
# Firewall      Start iptables firewall
#
# chkconfig: 2345 08 92
# description:  Starts, stops and saves iptables firewall
#
# config: /etc/sysconfig/iptables
# config: /etc/sysconfig/iptables-config
#
### BEGIN INIT INFO
# Provides: iptables
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop iptables firewall
# Description: Start, stop and save iptables firewall
### END INIT INFO
##############################################
#
# SCRIPT DE FIREWALL
###############################################
REDEBACKEND="IPBACKEND"
IPTABLES=`which iptables`

function OK()   {
echo -e "Firewall \\033[1;39m [ \\033[1;32mOK\\033[1;39m ]\\033[1;0m"
                }

function FALHOU()       {
echo -e "Firewall \\033[1;39m [ \\033[1;31mFALHOU\\033[1;39m ]\\033[1;0m"
}

function STOP(){

###############################################################
# Flushing filter and nat tables                              #
###############################################################
$IPTABLES -F
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -X
$IPTABLES -F -t nat
$IPTABLES -F -t raw

OK
}

function START(){
###############################################################
# Default Policies                                            #
###############################################################
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P POSTROUTING ACCEPT -t nat
$IPTABLES -P PREROUTING ACCEPT -t nat
$IPTABLES -P OUTPUT ACCEPT -t nat

modprobe ip_conntrack_ftp
##############################################################
# REGRAS de INPUT -                                          #
##############################################################
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

##CLUSTER
$IPTABLES -A INPUT -s "'$NODE1'" -j ACCEPT
$IPTABLES -A INPUT -s "'$NODE2'" -j ACCEPT

#Zabbix
$IPTABLES -A INPUT -s noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p1.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p2.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p3.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p4.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p5.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p6.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s p7.noc.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s pnoc-rj.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s pnoc.mandic.net.br -j ACCEPT

## Rede local
$IPTABLES -A INPUT -s $REDEBACKEND -j ACCEPT

### SSH Access###
$IPTABLES -A INPUT -s 177.70.100.5 -p tcp --dport 22 -j ACCEPT

### Services Access
$IPTABLES -A INPUT -p udp -s 177.70.106.7 --dport 514 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m multiport --dport 10050:10052 -j ACCEPT
$IPTABLES -A INPUT -p udp --dport 694 -j ACCEPT

##############################Regras AppAssure/RapidRecovery##############################
$IPTABLES -A INPUT -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A INPUT -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
#Ranges:
#187.191.98.0
#187.191.99.0
$IPTABLES -A INPUT -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A INPUT -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
##########################################################################################


$IPTABLES -A INPUT -s 177.70.100.56 -p tcp --dport 3389 -j ACCEPT

##ICMP
$IPTABLES -A INPUT -p icmp -j ACCEPT

##############################################################
# REGRAS de FORWARD -                                        #
##############################################################

$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A FORWARD -s $REDEBACKEND -j ACCEPT
$IPTABLES -A FORWARD -p icmp -j ACCEPT

#Monitoracao ZABBIX
$IPTABLES -A FORWARD -s noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p1.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p2.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p3.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p4.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p5.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p6.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s p7.noc.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s pnoc-rj.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s pnoc.mandic.net.br -j ACCEPT

#Gerenciamento
$IPTABLES -A FORWARD -p tcp --dport 3389 -j ACCEPT
$IPTABLES -A FORWARD -p tcp -m multiport --dport 5555,3389,10050:10052,9006:9009,5500:5700,7000:7010 -j ACCEPT
$IPTABLES -A FORWARD -s 177.70.100.5 -p tcp --dport 22 -j ACCEPT
$IPTABLES -A FORWARD -p udp -s 177.70.106.7 --dport 514 -j ACCEPT


##############################Regras AppAssure/RapidRecovery##############################
$IPTABLES -A FORWARD -s 177.70.104.184,177.70.104.194,177.70.104.204,177.70.104.205 -p tcp -m multiport --dport 9100:9300 -j ACCEPT
#Ranges:
#187.191.98.0
#187.191.99.0
$IPTABLES -A FORWARD -s 187.191.98.5,187.191.98.30,187.191.98.31,187.191.98.35 -p tcp -m multiport --dport 9000:9300 -j ACCEPT
##########################################################################################


$IPTABLES -A OUTPUT -p udp -d 177.70.106.7 --dport 514 -j ACCEPT

## REGRAS IPSEC
##################################################################
##$IPTABLES -A INPUT -p esp -j ACCEPT
##$IPTABLES -A INPUT -p udp --dport 500 -j ACCEPT
##$IPTABLES -A INPUT -p tcp --dport 500 -j ACCEPT
##$IPTABLES -A INPUT -p udp --dport 4500 -j ACCEPT
##$IPTABLES -A INPUT -s 186.237.171.90 -j ACCEPT
##$IPTABLES -A FORWARD -s 186.237.171.90 -j ACCEPT
##$IPTABLES -A FORWARD -s 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -d 10.164.30.0/24 -j ACCEPT
##$IPTABLES -A FORWARD -s 10.164.30.0/24 -d 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -j ACCEPT
##$IPTABLES -t nat -A POSTROUTING -s 10.164.30.0/24 -d 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -j ACCEPT
##$IPTABLES -t nat -A POSTROUTING -s 192.168.1.0/24,10.8.0.0/24,10.15.2.0/24 -d 10.164.30.0/24 -j ACCEPT
###################################################################

## OPENVPN ###
#$IPTABLES -A INPUT -p udp --dport 1194 -j ACCEPT
#$IPTABLES -A INPUT -p tcp --dport 1194 -j ACCEPT
### ------ ###

## Regras de gerenciamento ##
#$IPTABLES -A FORWARD -d 10.164.30.4 -p tcp -m multiport --dport 21,5500:5700 -j ACCEPT



# ACESSO REMOTO

# APPASSURE CONEXAO

# APPASSURE TRANSFERENCIA


### Services Access
#NAT 1x1 Aos servidores que precisam ter IP dedicado de saida
#MAILBOX01
#$IPTABLES -t nat -A PREROUTING -d 177.70.120.108  -j DNAT --to 10.124.0.6
#$IPTABLES -t nat -A POSTROUTING -s 10.124.0.6 -j SNAT --to 177.70.120.108

# ZABBIX


### Nat para rede backend
$IPTABLES -t nat -A POSTROUTING -s $REDEBACKEND -o eth0 -j MASQUERADE


OK

#SINCRONIZA REGRAS COM FW2
if [ "$(hostname)" = "'$NOME2'" ];then

        IPFW02=$NODE2
        FWFILE=/etc/init.d/firewall

        nc -z -w 2 $IPFW02 22

        if [ $? -eq 0 ];then
                scp -q $FWFILE root@$IPFW02:$FWFILE
                echo "Sincronizando regras com '$NOME2'"
                ssh root@$IPFW02 $FWFILE restart
        fi
fi


}

#
#FW options
#
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

                *)

                echo -e "Tente $0 {start|stop|restart}"
                ;;
        esac
		

		' > /etc/init.d/firewall
		
chmod +x /etc/init.d/firewall
chkconfig firewall on

#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/authkeys -O /etc/ha.d/authkeys


touch /etc/ha.d/authkeys

echo 'auth 1
1 md5 SENHA' > /etc/ha.d/authkeys

chmod 600 /etc/ha.d/authkeys

# wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/ha.cf -O /etc/ha.d/ha.cf

touch /etc/ha.d/ha.cf

echo 'autojoin none
ucast1
ucast2
bcast eth1
warntime 10
deadtime 15
keepalive 5
node1
node2
auto_failback off
ping_group gatewaycima 177.70.120.1 177.70.120.2 177.70.120.3
respawn hacluster /usr/lib64/heartbeat/ipfail
logfile /var/log/ha-log' > /etc/ha.d/ha.cf

touch /etc/ha.d/haresources


wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-6/x86_64/ldirectord-3.9.5-3.1.x86_64.rpm -O /root/ldirectord-3.9.5-3.1.x86_64.rpm
wget ftp://fr2.rpmfind.net/linux/centos/6.8/os/x86_64/Packages/resource-agents-3.9.5-34.el6.x86_64.rpm -O /root/resource-agents-3.9.5-34.el6.x86_64.rpm

scp /etc/init.d/firewall root@$BKNFW2:/etc/init.d/
ssh root@$BKNFW2 "chkconfig firewall on"
ssh root@$BKNFW2 "chmod +x /etc/init.d/firewall"
scp /etc/ha.d/authkeys root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/haresources root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$BKNFW2:/etc/ha.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mArquivos de Configuracao OK.\\033[1;39m \\033[1;0m"
echo ""

# INSTALANDO O LDIRECTORD
rpm -ivh /root/resource-agents-3.9.5-34.el6.x86_64.rpm

rpm -ivh /root/ldirectord-3.9.5-3.1.x86_64.rpm

scp /root/resource-agents-3.9.5-34.el6.x86_64.rpm root@$BKNFW2:/root/
scp /root/ldirectord-3.9.5-3.1.x86_64.rpm root@$BKNFW2:/root/


ssh root@$BKNFW2 "rpm -ivh /root/resource-agents-3.9.5-34.el6.x86_64.rpm"
ssh root@$BKNFW2 "rpm -ivh /root/ldirectord-3.9.5-3.1.x86_64.rpm"

touch /etc/ha.d/ldirectord.cf

echo '#
# Sample ldirectord configuration file to configure various virtual services.
#
# Ldirectord will connect to each real server once per second and request
# /index.html. If the data returned by the server does not contain the
# string "Test Message" then the test fails and the real server will be
# taken out of the available pool. The real server will be added back into
# the pool once the test succeeds. If all real servers are removed from the
# pool then localhost:80 is added to the pool as a fallback measure.

# Global Directives
checktimeout=3
checkinterval=1
#fallback=127.0.0.1:80
#fallback6=[::1]:80
autoreload=yes
logfile="/var/log/ldirectord.log"
#logfile="local0"
#emailalert="admin@x.y.z"
#emailalertfreq=3600
#emailalertstatus=all
quiescent=no

###ALTERAR IPS

# AUTO-REDIR
virtual=187.191.98.57:80
        #real=10.0.80.4:80 masq
        #real=10.0.80.5:80 masq
        real=10.0.80.4:80 masq
        real=10.0.80.5:80 masq
        service=http
        scheduler=wlc
        persistent=600
        protocol=tcp
        checktype=connect
        checkport=80
#       request="index.html"
#       receive="Test Page"
#       virtualhost=www.x.y.z

# WEB CAS
virtual=187.191.99.69:80
        real=10.0.80.6:80 masq
        real=10.0.80.7:80 masq
        service=none
        scheduler=wlc
        persistent=600
        protocol=tcp
        checktype=connect
        checkport=80
#       request="index.html"
#       receive="Test Page"
#       virtualhost=www.x.y.z


' > /etc/ha.d/ldirectord.cf

echo ""
echo -e "\\033[1;39m \\033[1;32mLDirectord Instalado.\\033[1;39m \\033[1;0m"
echo ""

}



############################################################
#############################################################
#  AJUSTES ALTA DISPONIBILIDADE - HEARTBEAT				  ####
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

	echo $NOME1 $ipvip"/23/eth0" >> /etc/ha.d/haresources
        cont=$(( $cont + 1 ))
done
}

gateway() {
GW=`echo $BACKEND | cut -d"." -f1,2,3`
echo $NOME1 $GW".1/24/eth1:1 # GW Backend" >> /etc/ha.d/haresources
}

fwativo(){
#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/motd -O /etc/motd
echo '
.___  ___.     _______ ____    __    ____         ___   .___________. __  ____    ____  ______
|   \/   |  _ |   ____|\   \  /  \  /   /        /   \  |           ||  | \   \  /   / /  __  \
|  \  /  | (_)|  |__    \   \/    \/   /        /  ^  \ `---|  |----`|  |  \   \/   / |  |  |  |
|  |\/|  |    |   __|    \            /        /  /_\  \    |  |     |  |   \      /  |  |  |  |
|  |  |  |  _ |  |        \    /\    /        /  _____  \   |  |     |  |    \    /   |  `--´  |
|__|  |__| (_)|__|         \__/  \__/        /__/     \__\  |__|     |__|     \__/     \______/


' > /etc/motd

#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/fw_ativo -O /etc/init.d/fw_ativo

touch /etc/init.d/fw_ativo

echo '#!/bin/bash

###################################################
# Daemon para exibir qual o FW Ativo no Heartbeat #
###################################################
#                                                 #
# Autor:   Leonardo A. de Araujo                  #
# Criacao: 24/02/2016                             #
# E-mail:  leonardo.araujo@mandic.net.br          #
#                                                 #
###################################################


case $1 in
        start)
        mv /etc/banner_old /etc/motd
        ;;
        stop)
        mv /etc/motd /etc/banner_old
        ;;
esac
' > /etc/init.d/fw_ativo
chmod +x /etc/init.d/fw_ativo
echo $NOME1 "fw_ativo  # Exibe qual FW esta Ativo " >> /etc/ha.d/haresources
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
sed -i 's/177.70.120.1 177.70.120.2 177.70.120.3/'"$PINGGROUP"'.1 '"$PINGGROUP"'.2 '"$PINGGROUP"'.3/' /etc/ha.d/ha.cf

scp /etc/ha.d/authkeys root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/haresources root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$BKNFW2:/etc/ha.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mHEARTBEAT Ajustado.\\033[1;39m \\033[1;0m"
echo ""

}




###########################################################
############################################################
#  AJUSTES DE REGRAS DE FIREWALL			 ####
############################################################
###########################################################

firewall() {

# DEFININDO IP's DOS NÓS SCRIPT FIREWALL
sed -i 's/IPBACKEND/'"$BACKEND\/24"'/' /etc/init.d/firewall
sed -i 's/NODE1/'"$NODE1"'/' /etc/init.d/firewall
sed -i 's/NODE2/'"$NODE2"'/' /etc/init.d/firewall
sed -i 's/NOME1/'"$NOME1"'/' /etc/init.d/firewall
sed -i 's/NOME2/'"$NOME2"'/' /etc/init.d/firewall

scp /etc/init.d/firewall root@$BKNFW2:/etc/init.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mScript de Firewall Ajustado.\\033[1;39m \\033[1;0m"
echo ""


#  GERA REGRAS NAT PARA ACESSO REMOTO  #

ARQNAT="/tmp/NAT.txt"

echo "###############################################"
echo "# CRIANDO REGRAS DE NAT PARA ACESSO REMOTO    #"
echo "###############################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

echo -n "Informe a Porta Destino... ex.: (22 ou 3389): "
read PORTADEST
export PORTADEST

PORTAORI=6999
CONT_PORT=$(( $PORTAORI + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:$PORTADEST" >> $ARQNAT
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
done

REGRAS=`cat $ARQNAT`
sed -i '/# ACESSO REMOTO/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para ACESSO REMOTO criadas.\\033[1;39m \\033[1;0m"
echo ""



#  GERA REGRAS NAT PARA ZABBIX  #

ARQNAT="/tmp/NAT.txt"

echo "#####################################################"
echo "#  CRIANDO REGRAS DE NAT PARA MONITORAMENTO ZABBIX  #"
echo "#####################################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

PORTAORI=7999
CONT_PORT=$(( $PORTAORI + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:10052"  >> $ARQNAT
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
done
echo '$IPTABLES' "-t nat -A POSTROUTING -s $BACKEND/24 -d noc.mandic.net.br -p tcp --dport 10052 -j SNAT --to $VIP" >> $ARQNAT
REGRAS=`cat $ARQNAT`
sed -i '/# ZABBIX/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para Monitoramento Zabbix criadas.\\033[1;39m \\033[1;0m"
echo ""



#  GERA REGRAS NAT PARA BACKUP APPASSURE  #

ARQNAT="/tmp/NAT.txt"
ARQNAT2="/tmp/NAT2.txt"

echo "################################################"
echo "# CRIANDO REGRAS DE NAT PARA BACKUP APPASSURE  #"
echo "################################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe a quantidade de Servidores Remotos: " 
read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))


PORTAORI=9099
CONT_PORT=$(( $PORTAORI + 1 ))

PORTADEST=9199
CONT_PORTADEST=$(( $PORTADEST + 1 ))

while [[ $NUM_SERVERS -ge $CONT ]] ; do
	echo -n "Informe o IP Backend do Server $CONT: " 
	read SERVER
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:9006" >> $ARQNAT
	echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORTADEST -j DNAT --to $SERVER:$CONT_PORTADEST" >> $ARQNAT2
	CONT=$(( $CONT + 1 ))
	CONT_PORT=$(( $CONT_PORT + 1 ))
	CONT_PORTADEST=$(( $CONT_PORTADEST + 1 ))
done

sed -i '/# APPASSURE CONEXAO/ r '"$ARQNAT"'' /etc/init.d/firewall
sed -i '/# APPASSURE TRANSFERENCIA/ r '"$ARQNAT2"'' /etc/init.d/firewall
rm -f $ARQNAT $ARQNAT2

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para BACKUP APPASSURE criadas.\\033[1;39m \\033[1;0m"
echo ""


}



regrasmysql() {
echo -n "Deseja criar regras de NAT para MySQL ? [ y | n ]:  "
read OPCAO

case $OPCAO in
	y)
	criarnatmysql
	;;
	n)
	break
	;;
	*)
	regrasmysql
	;;
	esac
}

criarnatmysql()
{

#  GERA REGRAS NAT PARA MYSQL  #

ARQNAT="/tmp/NAT.txt"


echo "######################################"
echo "# CRIANDO REGRAS DE NAT PARA MYSQL   #"
echo "######################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe o Servidor Remoto: " 
read SERVER

echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport 3306 -j DNAT --to $SERVER:3306" >> $ARQNAT
sed -i '/# MYSQL/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegra NAT para MYSQL criada.\\033[1;39m \\033[1;0m"
echo ""

}




regrasmssql() {
echo -n "Deseja criar regras de NAT para MSSQL ? [ y | n ]:  "
read OPCAO

case $OPCAO in
	y)
	criarnatmssql
	;;
	n)
	break
	;;
	*)
	regrasmssql
	;;
	esac
}

criarnatmssql()
{

#  GERA REGRAS NAT PARA MSSQL  #

ARQNAT="/tmp/NAT.txt"


echo "######################################"
echo "# CRIANDO REGRAS DE NAT PARA MSSQL   #"
echo "######################################"
echo ""
echo -n "Informe o VIP de Origem: "
read VIP
export VIP

echo -n "Informe o Servidor Remoto: " 
read SERVER

echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport 1433 -j DNAT --to $SERVER:1433" >> $ARQNAT
sed -i '/# MSSQL/ r '"$ARQNAT"'' /etc/init.d/firewall
rm -f $ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegra NAT para MSSQL criada.\\033[1;39m \\033[1;0m"
echo ""

}



syncall(){

scp /etc/sysctl.conf root@$BKNFW2:/etc/
scp /etc/ha.d/authkeys root@$BKNFW2:/etc/ha.d/
scp /etc/motd root@$BKNFW2:/etc/
scp /etc/init.d/fw_ativo root@$BKNFW2:/etc/init.d/
scp /etc/ha.d/ha.cf root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/haresources root@$BKNFW2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$BKNFW2:/etc/ha.d/
scp /etc/init.d/firewall root@$BKNFW2:/etc/init.d/

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
# CHAMADA DE FUNÇÕES	      ####
#################################
################################

interfaces
preparacaoSO
ipvip
gateway
fwativo
hacf
firewall
regrasmysql
regrasmssql
syncall
reinicializacao

}

inicio