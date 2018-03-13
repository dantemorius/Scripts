#!/bin/bash

###########################
#    ATIVACAO FIREWALL    #
# Data:  26/06/2014       #
# Autor: Leonardo Araujo  #
###########################


# ALERTA DE AJUSTE INICIAL

clear
echo ""
echo "
 __  __       ______ _____ _____  ________          __     _      _      
|  \/  |  _  |  ____|_   _|  __ \|  ____\ \        / /\   | |    | |     
| \  / | (_) | |__    | | | |__) | |__   \ \  /\  / /  \  | |    | |     
| |\/| |     |  __|   | | |  _  /|  __|   \ \/  \/ / /\ \ | |    | |     
| |  | |  _  | |     _| |_| | \ \| |____   \  /\  / ____ \| |____| |____ 
|_|  |_| (_) |_|    |_____|_|  \_\______|   \/  \/_/    \_\______|______|
                                                                       
"
echo ""
echo "########################################"
echo "#  Para utilizar este script, deve-se  #"
echo "#  Configurar chave RSA trocada entre  #"
echo "#        os Servidores Linux           #"
echo "########################################"
echo ""


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


############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O    			  ####
#############################################################
############################################################

preparacaoSO(){


# INSTALACAO REPOSITORIO EPEL & ATOMIC
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/atomic-release-1.0-21.el6.art.noarch.rpm --force
sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/atomic.repo
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorios EPEL e ATOMIC instalados.\\033[1;39m \\033[1;0m"
echo ""

# UPDATE
yum update -y
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""

# INSTALACAO DE PACOTES
yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet sshpass nc.x86_64 pwgen.x86_64 screen lsof -y

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc && yes | mv bashrc /root/.bashrc

# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so

# CONFIGURACAO SERVERLOGS
sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart

# CONFIG SELINUX
sed -i 's/=enforcing/=disabled/' /etc/selinux/config

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
#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall -O /etc/init.d/firewall
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall_new -O /etc/init.d/firewall
chmod +x /etc/init.d/firewall
chkconfig firewall on

echo ""
echo -e "\\033[1;39m \\033[1;32mArquivos de Configuracao OK.\\033[1;39m \\033[1;0m"
echo ""

# DEFININDO O HOSTNAME
sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
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

# DEFININDO VARIAVEIS

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
echo ""

PINGGROUP=`echo $NODE1 | cut -d"." -f1,2,3`

############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O    			  ####
#############################################################
############################################################

preparacaoSO(){


# INSTALACAO REPOSITORIO EPEL & ATOMIC
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/atomic-release-1.0-21.el6.art.noarch.rpm --force
sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/atomic.repo
ssh root@$NODE2 "rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force"
ssh root@$NODE2 "rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/atomic-release-1.0-21.el6.art.noarch.rpm --force"
ssh root@$NODE2 "sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/atomic.repo"
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorios EPEL e ATOMIC instalados.\\033[1;39m \\033[1;0m"
echo ""

# UPDATE
yum update -y
ssh root@$NODE2 "yum update -y"
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""

# INSTALACAO DE PACOTES
yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat sshpass nc.x86_64 pwgen.x86_64 screen lsof -y

chkconfig heartbeat on

ssh root@$NODE2 "yum install ipvsadm perl-Net-IP perl-IO-Socket-INET6 perl-Socket6 perl-Authen-Radius perl-MailTools perl-Net-DNS perl-Net-IMAP-Simple perl-Net-IMAP-Simple-SSL perl-POP3Client perl-libwww-perl perl-Net-SSLeay perl-Crypt-SSLeay.x86_64 perl-LWP-Authen-Negotiate.noarch perl-Test-Mock-LWP.noarch openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet heartbeat sshpass nc.x86_64 pwgen.x86_64 screen lsof -y"

ssh root@$NODE2 "chkconfig heartbeat on"

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc
yes | mv bashrc /root/.bashrc
scp /root/.bashrc root@$NODE2:/root/.

# INSTALANDO SNOOPY
yum install snoopy -y
rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so
ssh root@$NODE2 "yum install snoopy -y"
ssh root@$NODE2 "rpm -qa | grep snoopy | xargs rpm -ql | grep snoopy.so >> /etc/ld.so.preload && set LD_PRELOAD=/lib64/snoopy.so"

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
sed -i 's/=enforcing/=disabled/' /etc/selinux/config
ssh root@$NODE2 "sed -i 's/=permissive/=disabled/' /etc/selinux/config"

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
sed -i '100 a  \    <white_list>'$NODE2'</white_list>' /var/ossec/etc/ossec.conf
sed -i 's/>600</>1800</' /var/ossec/etc/ossec.conf
/etc/init.d/ossec-hids restart
chkconfig ossec-hids on

ssh root@$NODE2 "yum install ossec-hids.x86_64 ossec-hids-server.x86_64 -y"
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
scp /etc/sysctl.conf root@$NODE2:/etc/sysctl.conf

echo ""
echo -e "\\033[1;39m \\033[1;32msysctl ajustado.\\033[1;39m \\033[1;0m"
echo ""

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off
mv /etc/init.d/iptables /etc/init.d/.iptables_OLD_NAO_MEXER
mv /etc/init.d/ip6tables /etc/init.d/.ip6tables_OLD_NAO_MEXER
ln -s /etc/init.d/firewall /etc/init.d/iptables
ssh root@$NODE2 "/etc/init.d/iptables stop"
ssh root@$NODE2 "chkconfig iptables off"
ssh root@$NODE2 "mv /etc/init.d/iptables /etc/init.d/.iptables_OLD_NAO_MEXER"
ssh root@$NODE2 "mv /etc/init.d/ip6tables /etc/init.d/.ip6tables_OLD_NAO_MEXER"
ssh root@$NODE2 "ln -s /etc/init.d/firewall /etc/init.d/iptables"


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
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall_new -O /etc/init.d/firewall
#wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/firewall -O /etc/init.d/firewall
chmod +x /etc/init.d/firewall
chkconfig firewall on

wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/authkeys -O /etc/ha.d/authkeys
chmod 600 /etc/ha.d/authkeys

wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/ha.cf -O /etc/ha.d/ha.cf
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/haresources -O /etc/ha.d/haresources
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/ldirectord.cf -O /etc/ha.d/ldirectord.cf
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/ldirectord-1.0.4-1.el6.x86_64.rpm -O /root/ldirectord-1.0.4-1.el6.x86_64.rpm

scp /etc/init.d/firewall root@$NODE2:/etc/init.d/
ssh root@$NODE2 "chkconfig firewall on"
ssh root@$NODE2 "chmod +x /etc/init.d/firewall"
scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$NODE2:/etc/ha.d/

echo ""
echo -e "\\033[1;39m \\033[1;32mArquivos de Configuracao OK.\\033[1;39m \\033[1;0m"
echo ""

# INSTALANDO O LDIRECTORD
rpm -ivh /root/ldirectord-1.0.4-1.el6.x86_64.rpm
scp /root/ldirectord-1.0.4-1.el6.x86_64.rpm root@$NODE2:/root/
ssh root@$NODE2 "rpm -ivh /root/ldirectord-1.0.4-1.el6.x86_64.rpm"

echo ""
echo -e "\\033[1;39m \\033[1;32mLDirectord Instalado.\\033[1;39m \\033[1;0m"
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
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/motd -O /etc/motd
wget ftp://ftpcloud.mandic.com.br/Scripts/repo/firewall/fw_ativo -O /etc/init.d/fw_ativo
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

scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$NODE2:/etc/ha.d/

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

scp /etc/init.d/firewall root@$NODE2:/etc/init.d/

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

scp /etc/sysctl.conf root@$NODE2:/etc/
scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
scp /etc/motd root@$NODE2:/etc/
scp /etc/init.d/fw_ativo root@$NODE2:/etc/init.d/
scp /etc/ha.d/ha.cf root@$NODE2:/etc/ha.d/
scp /etc/ha.d/haresources root@$NODE2:/etc/ha.d/
scp /etc/ha.d/ldirectord.cf root@$NODE2:/etc/ha.d/
scp /etc/init.d/firewall root@$NODE2:/etc/init.d/

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