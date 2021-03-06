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
echo "1. FIREWALL STANDALONE"
echo "2. FIREWALL EM ALTA DISPONIBILIDADE "
echo ""
echo ""
read OPCAO

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


# INSTALACAO REPOSITORIO EPEL
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorio EPEL instalado.\\033[1;39m \\033[1;0m"
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
sed -i 's/=enforcing/=disabled/' /etc/sysconfig/selinux

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

echo ""
echo -e "\\033[1;39m \\033[1;32msysctl ajustado.\\033[1;39m \\033[1;0m"
echo ""

# DESABILITANDO IPTABLES
/etc/init.d/iptables stop
chkconfig iptables off

echo ""
echo -e "\\033[1;39m \\033[1;32mIptables desabilitado.\\033[1;39m \\033[1;0m"
echo ""

# ATIVANDO O RSYSLOG
/etc/init.d/rsyslog start
chkconfig rsyslog on

echo ""
echo -e "n"
echo ""

# BAIXANDO ARQUIVOS CONFIG
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/firewall /etc/init.d/
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

firewall() {

# DEFININDO IP's DOS NÓS SCRIPT FIREWALL
sed -i 's/IPBACKEND/'"$BACKEND\/24"'/' /etc/init.d/firewall
sed -i 's/NODE1/'"$NODE1"'/' /etc/init.d/firewall
sed -i 's/NOME1/'"$NOME1"'/' /etc/init.d/firewall
sed -i '/NODE2/d' /etc/init.d/firewall

LINE=`grep -n "#SINCRONIZA" firewall.sh  | cut -d":" -f1`
LINE2=$(( $LINE+ 15))

sed -i ''$LINE','$LINE2'd' /etc/init.d/firewall

echo ""
echo -e "\\033[1;39m \\033[1;32mScript de Firewall Ajustado.\\033[1;39m \\033[1;0m"
echo ""

}

menu() {
echo -e "\n\\033[1;39m \\033[1;32mSelecione a Opção desejada:\\033[1;39m \\033[1;0m"
echo -e "\n\\033[1;39m \\033[1;32m [Digite q para Sair]\\033[1;39m \\033[1;0m"
echo -e "1) \\033[1;39m \\033[1;32mConfiguração de Regras Padrão - Firewall\\033[1;39m \\033[1;0m"
echo -e "2) \\033[1;39m \\033[1;32mConfiguração de Regras Zabbix\\033[1;39m \\033[1;0m"
echo -e "3) \\033[1;39m \\033[1;32mConfiguração de Regras AppAssure\\033[1;39m \\033[1;0m\n"

firewall_padrao(){
#!/bin/bash
echo -e "\n\\033[1;39m \\033[1;32m####################################################\\033[1;39m \\033[1;0m"
echo -e "\\033[1;39m \\033[1;32m##\\033[1;39m \\033[1;0mCriando regras de NAT para IP Público Dedicado \\033[1;39m \\033[1;32m##\\033[1;39m \\033[1;0m"
echo -e "\\033[1;39m \\033[1;32m####################################################\\033[1;39m \\033[1;0m"
echo ""

echo -n "Informe a quantidade IPs VIPs: "
read NUM_VIPS
COUNT_VIPS=0
CONT_V=$(( $COUNT_VIPS + 1 ))

echo -n "Informe a quantidade de Servidores Remotos: "
read NUM_SERVERS
COUNT_REMOTE=0
CONT_R=$(( $COUNT_REMOTE + 1 ))

echo -n "Informe a quantidade de Portas Padrão: "
read NUM_PORTAS
COUNT_PORTA=0
CONT_P=$(( $COUNT_PORTA + 1 ))

contar_porta(){
                                echo -e "\n####Regras de Nat do VIP $VIP para Servidor $SERVER####" >> $ARQNAT
                while [[ $NUM_PORTAS -ge $CONT_P ]] ; do

                        echo -ne "\\033[1;39m \\033[1;32mInforme $CONT_Pº porta para liberação no Servidor $SERVER (Use ":" para ranges de portas):\\033[1;39m \\033[1;0m"
                        read PORTA

                                                if echo "$PORTA" | egrep ':' > DPORT
                                                then
                                                sed -i "s/:/-/g" DPORT
                                                        echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp -m multiport --dport $PORTA -j DNAT --to $SERVER:`cat DPORT`" >> ARQNAT
                                                else
                                                echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $PORTA -j DNAT --to $SERVER:$PORTA" >> ARQNAT
                                                fi
                        CONT_P=$(( $CONT_P + 1 ))
                done
}
while [[ $NUM_SERVERS -ge $CONT_R ]] ; do
        echo -ne "\n\\033[1;39m \\033[1;32mInforme o IP VIP do Server $CONT_V:\\033[1;39m \\033[1;0m"
        read VIP

        echo -ne "\\033[1;39m \\033[1;32mInforme o IP Backend do Server $CONT_R:\\033[1;39m \\033[1;0m"
        read SERVER

        echo -e '$IPTABLES' "-t nat -A POSTROUTING -s $SERVER -o eth0 -p tcp -j SNAT --to $VIP" >> ARQNAT2
        CONT_P=1
        CONT_R=$(( $CONT_R + 1 ))
        CONT_V=$(( $CONT_V + 1 ))
        contar_porta
done




        echo -e '\n########### Regras de retorno ##########' >> $ARQNAT
        cat $ARQNAT2 | uniq >> $ARQNAT
                clear
                echo -e "\\033[1;39m \\033[1;32mLista de Regras Criadas:\n\\033[1;39m \\033[1;0m"
                rm -rf $ARQNAT2
                cat $ARQNAT

menu
}

firewall_zabbix(){
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

menu
}

firewall_appassure(){
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

menu
}


read OPCAO

case $OPCAO in
        1)
        firewall_padrao
        ;;
        2)
        firewall_zabbix
        ;;
        3)
        firewall_appassure
        ;;
        q)
        reinicializacao
        ;;
        *)
        echo -e "\n[Digite uma opção válida!]\n"
        menu
        ;;
        esac
}

####REINICIALIZACAO DO SERVIDOR ####



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


##### CHAMADA DE FUNÇÕES  ####

preparacaoSO
firewall
menu
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



############################################################
#############################################################
#  AJUSTES E CONFIGURACAO DE S.O    			  ####
#############################################################
############################################################

preparacaoSO(){


# INSTALACAO REPOSITORIO EPEL
rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
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

# CONFIGURACAO SERVERLOGS
sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart
ssh root@$NODE2 "sed -i 's/#*.* @@remote-host:514/*.* @177.70.106.7:514/g' /etc/rsyslog.conf  && /etc/init.d/rsyslog restart"

# CONFIG SELINUX
sed -i 's/=enforcing/=disabled/' /etc/sysconfig/selinux
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
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/firewall /etc/init.d/
chmod +x /etc/init.d/firewall
chkconfig firewall on

sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/authkeys /etc/ha.d/
chmod 600 /etc/ha.d/authkeys
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ha.cf /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/haresources /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ldirectord.cf /etc/ha.d/
sshpass -p'#!cl0ud#!' scp -o StrictHostKeyChecking=no root@187.33.3.137:/root/firewall/ldirectord-1.0.4-1.el6.x86_64.rpm /root/

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
#  AJUSTES ALTA DISPONIBILIDADE - HEARTBEAT		  ####
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

}

menu() {

clear

echo -e "\n\\033[1;39m \\033[1;32mSelecione a Opção desejada:\\033[1;39m \\033[1;0m"
echo -e "1) \\033[1;39m \\033[1;32mConfiguração de Regras Padrão - Firewall\\033[1;39m \\033[1;0m"
echo -e "2) \\033[1;39m \\033[1;32mConfiguração de Regras Zabbix\\033[1;39m \\033[1;0m"
echo -e "3) \\033[1;39m \\033[1;32mConfiguração de Regras AppAssure\\033[1;39m \\033[1;0m\n"


firewall_padrao(){
#!/bin/bash
echo -e "\n\\033[1;39m \\033[1;32m####################################################\\033[1;39m \\033[1;0m"
echo -e "\\033[1;39m \\033[1;32m##\\033[1;39m \\033[1;0mCriando regras de NAT para IP Público Dedicado \\033[1;39m \\033[1;32m##\\033[1;39m \\033[1;0m"
echo -e "\\033[1;39m \\033[1;32m####################################################\\033[1;39m \\033[1;0m"
echo ""

echo -n "Informe a quantidade IPs VIPs: "
read NUM_VIPS
COUNT_VIPS=0
CONT_V=$(( $COUNT_VIPS + 1 ))

echo -n "Informe a quantidade de Servidores Remotos: "
read NUM_SERVERS
COUNT_REMOTE=0
CONT_R=$(( $COUNT_REMOTE + 1 ))

echo -n "Informe a quantidade de Portas Padrão: "
read NUM_PORTAS
COUNT_PORTA=0
CONT_P=$(( $COUNT_PORTA + 1 ))

contar_porta(){
                                echo -e "\n####Regras de Nat do VIP $VIP para Servidor $SERVER####" >> $ARQNAT
                while [[ $NUM_PORTAS -ge $CONT_P ]] ; do

                        echo -ne "\\033[1;39m \\033[1;32mInforme $CONT_Pº porta para liberação no Servidor $SERVER (Use ":" para ranges de portas):\\033[1;39m \\033[1;0m"
                        read PORTA

                                                if echo "$PORTA" | egrep ':' > DPORT
                                                then
                                                sed -i "s/:/-/g" DPORT
                                                        echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp -m multiport --dport $PORTA -j DNAT --to $SERVER:`cat DPORT`" >> $ARQNAT
                                                else
                                                echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $PORTA -j DNAT --to $SERVER:$PORTA" >> $ARQNAT
                                                fi
                        CONT_P=$(( $CONT_P + 1 ))
                done
}
while [[ $NUM_SERVERS -ge $CONT_R ]] ; do
        echo -ne "\n\\033[1;39m \\033[1;32mInforme o IP VIP do Server $CONT_V:\\033[1;39m \\033[1;0m"
        read VIP

        echo -ne "\\033[1;39m \\033[1;32mInforme o IP Backend do Server $CONT_R:\\033[1;39m \\033[1;0m"
        read SERVER

        echo -e '$IPTABLES' "-t nat -A POSTROUTING -s $SERVER -o eth0 -p tcp -j SNAT --to $VIP" >> $ARQNAT2
        CONT_P=1
        CONT_R=$(( $CONT_R + 1 ))
        CONT_V=$(( $CONT_V + 1 ))
        contar_porta
done




        echo -e '\n########### Regras de retorno ##########' >> $ARQNAT
        cat $ARQNAT2 | uniq >> $ARQNAT
                clear
                echo -e "\\033[1;39m \\033[1;32mLista de Regras Criadas:\n\\033[1;39m \\033[1;0m"
                rm -rf $ARQNAT2
                cat $ARQNAT
}

firewall_zabbix(){
#  GERA REGRAS NAT PARA ZABBIX  #

$ARQNAT="/tmp/NAT.txt"

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
        echo '$IPTABLES' "-t nat -A PREROUTING -d $VIP -p tcp --dport $CONT_PORT -j DNAT --to $SERVER:10052"  >> $$ARQNAT
        CONT=$(( $CONT + 1 ))
        CONT_PORT=$(( $CONT_PORT + 1 ))
done
echo '$IPTABLES' "-t nat -A POSTROUTING -s $BACKEND/24 -d noc.mandic.net.br -p tcp --dport 10052 -j SNAT --to $VIP" >> $$ARQNAT
REGRAS=`cat $$ARQNAT`
sed -i '/# ZABBIX/ r '"$$ARQNAT"'' /etc/init.d/firewall
rm -f $$ARQNAT

echo ""
echo -e "\\033[1;39m \\033[1;32mRegras para Monitoramento Zabbix criadas.\\033[1;39m \\033[1;0m"
echo ""
}

firewall_appassure(){
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



read OPCAO

case $OPCAO in
        1)
        firewall_padrao
        ;;
        2)
        firewall_zabbix
        ;;
        3)
        firewall_appassure
        ;;
        q)
        syncall
        ;;
		*)
		echo -e "\n[Digite uma opção Válida!]\n"
		menu
		;;
        esac
}

syncall(){

scp /etc/sysctl.conf root@$NODE2:/etc/
scp /etc/ha.d/authkeys root@$NODE2:/etc/ha.d/
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
hacf
firewall
menu
syncall
reinicializacao

}

inicio