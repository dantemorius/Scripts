#!/bin/bash
#
#################################
# AUTOR : Amauri Hideki 		#
# VERSAO : v1.0					#
# DATA CRIAÇÃO : 10/04/2017		#
# DATA ALTERAÇÃO : 13/04/2017	#
# SERVIÇO : FIREWALL			#
# DISTRIB : CENTOS 7			#
#################################

sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
setenforce 0

padrao(){
echo "# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

HISTSIZE=1000
HISTFILESIZE=1000
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=ignoredups

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi" > /root/.bashrc
source /root/.bashrc

echo '#!/bin/bash
# User specific aliases and functions
Normal="\[\\033[0m\]"
Vermelho="\[\\033[1;31m\]"
Verde="\[\\033[1;32m\]"
Amarelo="\[\\033[1;33m\]"
Azul="\[\\033[1;34m\]"
Roxo="\[\\033[1;35m\]"
Ciano="\[\\033[1;36m\]"
Branco="\[\\033[1;37m\]"
PS1="$Normal$Azul[$Branco(\t) $Verde\u$Vermelho@$Amarelo\h$Verde $Ciano\w$Azul]$Branco\\$ $Normal"' > /etc/profile.d/mandic_bashrc.sh
source /etc/profile.d/mandic_bashrc.sh

echo '# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# powersave disable
#setterm -powersave off -blank 0

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH' > /root/.bash_profile
source /root/.bash_profile
}

chaves(){
# INSTALANDO PACOTES
VALIDA_PACOTE1=`rpm -qa | grep -i sshpass > /dev/null; echo $?`
if [ $VALIDA_PACOTE1 -ne 1 ] ;then
echo "NÃO FAZER" > /dev/null
else
rpm -ivh ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/KGronlund/CentOS_7/x86_64/sshpass-1.05-7.1.x86_64.rpm
fi

VALIDA_PACOTE2=`rpm -qa | grep -i openssh > /dev/null; echo $?`
if [ $VALIDA_PACOTE1 -ne 1 ] ;then
echo "NÃO FAZER" > /dev/null
else
yum install openssh-clients.x86_64 wget -y
fi

# GERANDO CHAVE
if [ -e /root/.ssh/id_rsa ];then
echo "Já tem chave RSA" > /dev/null
else
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ""
fi
}

confg_nos(){
echo ""
echo "###############################################"
echo "# Configuração dos NODES dentro do CLUSTER    #"
echo "###############################################"
echo ""

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme a quantidade de Servidores CLUSTER: \\033[1;39m \\033[1;0m"
echo ""

read NUM_SERVERS
COUNT=0
CONT=$(( $COUNT + 1 ))

if [ -e config_cluster.tmp ];then
rm -rf config_cluster.tmp
  else
  echo "Arquivo não existe" > /dev/null
fi

while [[ $NUM_SERVERS -ge $CONT ]] ; do
        echo ""
        echo -e "\\033[1;39m \\033[1;32mInforme o IP do Server $CONT:\\033[1;39m \\033[1;0m"
        echo ""

        read SERVER

        if [[ $CONT -ne $NUM_SERVERS+1 ]] ;then
        echo "$SERVER" >> config_cluster.tmp
          else
          echo "FIM" > /dev/null
        fi

        CONT=$(( $CONT + 1 ))
done

echo -e "\\033[1;39m \\033[1;32mInforme a senha padrão dos servidores: \\033[1;39m \\033[1;0m\n"
read SENHASSH
export SENHASSH

echo '#!/bin/bash' > config_rel_conf.sh
cat config_cluster.tmp | while read TROCACHAVE; do echo 'sshpass -p' "$SENHASSH" 'ssh-copy-id -i /root/.ssh/id_rsa.pub' "$TROCACHAVE" '&& sleep 1' >> config_rel_conf.sh; done

echo 'StrictHostKeyChecking no
#serKnownHostsFile=/dev/null'> ~/.ssh/config

sh +x config_rel_conf.sh && sleep 1
rm -rf config_rel_conf.sh

cat config_cluster.tmp | while read COPIACHAVE; do scp /root/.ssh/id_rsa.pub $COPIACHAVE:/root/.ssh/id_rsa.pub; done
# SELINUX NODES
for i in `cat config_cluster.tmp`; do ssh $i "sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config" && ssh $i "setenforce 0" ; done
}

fqdn(){
# FQDN
echo 'host_name=`hostname | grep -i .mandic.net.br > /dev/null ; echo $?`

if [ $host_name -eq 0 ]; then
echo "Hostname já no padrão FQDN"
else
hostnamectl set-hostname $(echo -e $(hostname | cut -d "-" -f1,7).mandic.net.br)
systemctl restart systemd-hostnamed.service
fi' > ajusta_fqdn.sh

for i in `cat config_cluster.tmp`; do scp ajusta_fqdn.sh $i:/root/ajusta_fqdn.sh && ssh $i "sh +x ajusta_fqdn.sh"; done
for i in `cat config_cluster.tmp`; do ssh $i hostname | while read a; do echo "$i $a" >> /etc/hosts && echo "$a" >> hostname.tmp; done; done
for i in `cat config_cluster.tmp`; do scp /etc/hosts $i:/etc/hosts; done
}

pacemaker_install(){

echo 'yum -y install pacemaker pcs fence-agents-all
systemctl start pcsd
systemctl enable pcsd

new="1UunrO6XyD4a"
echo -e "$new\n$new" | passwd hacluster' > /root/pcs_install.sh

for PCSINSTALL in `cat config_cluster.tmp`; do scp /root/pcs_install.sh $PCSINSTALL:/root/pcs_install.sh && ssh $PCSINSTALL "sh +x pcs_install.sh"; done

# AUTENTICAR OS NOS DO CLUSTER
new="1UunrO6XyD4a"
cat hostname.tmp | xargs | while read NOS; do pcs cluster auth $NOS -u hacluster -p $new ; done

nome_cluster=`hostname | cut -d '-' -f1`
cat hostname.tmp | xargs | while read SETUP; do pcs cluster setup --name fw_$nome_cluster $SETUP; done
pcs cluster start --all
pcs cluster enable --all

}

pacemaker_configure(){
#EXECUTA EM APENAS UM DOS NÓS, ELE REPLICA PARA OS DEMAIS DE FORMA AUTOMÁTICA
echo ""
echo "####################################################"
echo "# Configuração dos VIPs dentro do CLUSTER de FW    #"
echo "####################################################"
echo ""

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme a quantidade de VIPs:\\033[1;39m \\033[1;0m"
echo ""

read NUM_VIP
COUNT=0
CONT=$(( $COUNT + 1 ))

if [ -e config_cluster.tmp ];then
rm -rf config_cluster.tmp
  else
  echo "Arquivo não existe" > /dev/null
fi

if [ -e hostname.tmp ];then
rm -rf hostname.tmp
  else
  echo "Arquivo não existe" > /dev/null
fi

while [[ $NUM_VIP -ge $CONT ]] ; do
echo ""
echo -e "\\033[1;39m \\033[1;32mInforme o IP do Server $CONT:\\033[1;39m \\033[1;0m"
echo ""

read VIP
export VIP

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme a MASCARA do Server $CONT:\\033[1;39m \\033[1;0m"
echo ""

read MASCARA_REDE
export MASCARA_REDE

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme a INTERFACE do Server $CONT:\\033[1;39m \\033[1;0m"
echo ""

read INTERFACE
export INTERFACE

if [[ $CONT -ne $NUM_VIP+1 ]] ;then

pcs resource create ClusterIP_$VIP ocf:heartbeat:IPaddr2 ip=$VIP cidr_netmask=$MASCARA_REDE nic=eth0:$INTERFACE op monitor interval=10s
pcs resource create PingIP_$VIP ocf:pacemaker:ping dampen=5s multiplier=1000 host_list=$VIP --clone
pcs constraint location ClusterIP_$VIP rule score=INFINITY pingd gte 1 and defined pingd

  else
  echo "FIM" > /dev/null
fi

CONT=$(( $CONT + 1 ))
done

pcs resource create Firewall systemd:firewall op monitor interval=5 --clone
pcs property set stonith-enabled=false
pcs resource defaults failure-timeout=30
pcs resource defaults migration-threshold=1

systemctl start pacemaker.service
systemctl enable pacemaker.service
systemctl start corosync.service
systemctl enable corosync.service
}

firewall_service(){
systemctl stop firewalld.service
systemctl mask firewalld.service

# SERVICE
echo '[Unit]
Description=IPv4 firewall with firewall
After=syslog.target
AssertPathExists=/usr/libexec/firewall/firewall.init

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/libexec/firewall/firewall.init start
ExecReload=/usr/libexec/firewall/firewall.init restart
ExecStop=/usr/libexec/firewall/firewall.init stop

Environment=BOOTUP=serial
Environment=CONSOLETYPE=serial
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=basic.target' > /usr/lib/systemd/system/firewall.service


for FWS in `cat config_cluster.tmp`; do ssh $FWS "systemctl stop firewalld.service" && ssh $FWS "systemctl mask firewalld.service" && scp /usr/lib/systemd/system/firewall.service $FWS:/usr/lib/systemd/system/firewall.service; done 
}

firewall_init(){

# INIT
mkdir -p /usr/libexec/firewall/

echo '#!/bin/bash
#
# iptables      Start iptables firewall
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

# Source function library.
#. /etc/init.d/functions

###############################################################
# SCRIPT DE FIREWALL                                                                              #
###############################################################
REDEBACKEND="10.53.40.0/24"
IPTABLES=`which iptables`
core1="177.70.104.184,177.70.125.18,177.70.121.201,177.70.121.220,177.70.122.13,177.70.125.10,187.191.96.5,187.191.98.5,177.70.117.198,177.70.118.10,187.191.101.202,177.70.106.41,192.168.0.7"
core2="177.70.104.194,177.70.125.19,177.70.121.202,177.70.122.15,177.70.125.11,187.191.96.151,187.191.98.30,177.70.117.199,177.70.118.11,187.191.101.186,177.70.106.42,192.168.0.8"
core3="177.70.104.204,177.70.125.20,177.70.121.213,177.70.122.17,177.70.125.12,187.191.96.202,187.191.98.31,177.70.117.200,177.70.118.12,187.191.101.189,187.191.125.132,177.70.106.227,192.168.0.13"
core4="177.70.104.205,177.70.125.21,177.70.121.214,177.70.122.18,177.70.125.13,187.191.96.203,187.191.98.35,177.70.117.201,177.70.118.13,187.191.101.190,187.191.125.133,177.70.106.228,192.168.0.18"
core5="177.70.104.210,177.70.125.16,177.70.121.250,177.70.122.21,177.70.125.14,187.191.96.156,187.191.98.158,177.70.117.202,177.70.118.14,187.191.101.170,177.70.106.229,192.168.0.19"
core6="177.70.104.211,177.70.125.17,177.70.121.251,177.70.122.22,177.70.125.15,187.191.96.184,187.191.99.155,177.70.117.203,177.70.118.15,187.191.101.188,177.70.106.230,192.168.0.21"
core7="177.70.104.212,177.70.125.22,177.70.121.201,177.70.121.202,177.70.122.39,177.70.122.40,187.191.96.153,187.191.98.36,177.70.116.146,177.70.118.16,187.191.101.197,177.70.106.87,192.168.0.22"
core8="177.70.104.214,177.70.125.23,177.70.121.213,177.70.121.216,177.70.122.45,177.70.122.46,187.191.96.158,187.191.98.39,177.70.117.45,177.70.118.17,187.191.101.199,177.70.106.88,192.168.0.23"
core9="177.70.104.215,177.70.125.24,177.70.121.249,177.70.122.48,177.70.122.49,187.191.96.182,187.191.98.25,177.70.117.46,177.70.118.18,187.191.101.201,177.70.106.89,192.168.0.24"

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
modprobe ip_nat_ftp
##############################################################
# REGRAS de INPUT -                                          #
##############################################################
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

##CLUSTER
$IPTABLES -A INPUT -s 177.70.123.93 -j ACCEPT
$IPTABLES -A INPUT -s 177.70.123.125 -j ACCEPT
$IPTABLES -A INPUT -s 177.70.123.130 -j ACCEPT

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

$IPTABLES -A INPUT -s zbx.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxserver.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp01.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp02.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp03.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp04.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp05.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp06.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp07.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp08.mandic.net.br -j ACCEPT
$IPTABLES -A INPUT -s zbxp09.mandic.net.br -j ACCEPT
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

##############################################################
# REGRAS APPASSURE/RAPIDRECOVERY - BACKUP MANDIC             #
##############################################################
$IPTABLES -A INPUT -s $core8 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A INPUT -s $core8 -p tcp -m multiport --dport 9100:9300 -j ACCEPT

$IPTABLES -A FORWARD -s $core8 -p tcp -m multiport --dport 9006:9010 -j ACCEPT
$IPTABLES -A FORWARD -s $core8 -p tcp -m multiport --dport 9100:9300 -j ACCEPT

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

$IPTABLES -A FORWARD -s zbx.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxserver.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp01.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp02.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp03.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp04.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp05.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp06.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp07.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp08.mandic.net.br -j ACCEPT
$IPTABLES -A FORWARD -s zbxp09.mandic.net.br -j ACCEPT

### Nat para rede backend
$IPTABLES -t nat -A POSTROUTING -s $REDEBACKEND -o eth0 -j MASQUERADE

. /etc/sysconfig/firewall

OK
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
        esac' > /usr/libexec/firewall/firewall.init

chmod +x /usr/libexec/firewall/firewall.init
# IDENTIFICAR O SERVIÇO FIREWALL.SERVICE
systemctl daemon-reload
#systemctl enable firewall.service # Disabled pois quem controla é o PACEMAKER
systemctl start firewall.service


for FWI in `cat config_cluster.tmp`; do ssh $FWI "mkdir -p /usr/libexec/firewall/" && scp /usr/libexec/firewall/firewall.init $FWI:/usr/libexec/firewall/firewall.init && ssh $FWI "systemctl daemon-reload" && ssh $FWI "systemctl start firewall.service"; done

}

padrao
chaves
confg_nos
fqdn
firewall_service
firewall_init
pacemaker_install
pacemaker_configure

