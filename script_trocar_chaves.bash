#!/bin/bash -xv
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
sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
echo $NOME1 > /etc/hostname
hostname $NOME1


		echo ""
			echo -e "\\033[1;39m \\033[1;32mHostname Ajustado.\\033[1;39m \\033[1;0m"
		echo ""

# INSTALACAO REPOSITORIO EPEL & ATOMIC - FW01
	rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
	rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/atomic-release-1.0-21.el6.art.noarch.rpm --force
		sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/atomic.repo
		
		
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
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "rpm -Uvh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/atomic-release-1.0-21.el6.art.noarch.rpm --force"
	sshpass -p $PASSWDFW02 ssh root@$NODE2 "sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/atomic.repo"

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
rm -rf .ssh*
sshpass -p q1p0w2o9 ssh root@$NODE2 "rm -rf /root/.ssh"

ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ''

echo 'StrictHostKeyChecking no
UserKnownHostsFile=/dev/null' > /root/.ssh/config

sshpass -p $PASSWDFW02 ssh-copy-id -i /root/.ssh/id_rsa.pub $BKNFW2

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


sshpass -p q1p0w2o9 scp /root/.ssh/config root@$NODE2:/root/.ssh/config

##Copiando e executando script para troca de chaves no FW02
sshpass -p $PASSWDFW02 scp chgkey1.sh root@$BKNFW2:/root/chgkey1.sh
sshpass -p $PASSWDFW02 scp chgkey2.sh root@$BKNFW2:/root/chgkey2.sh
sshpass -p $PASSWDFW02 ssh $BKNFW2 "sh -x /root/chgkey1.sh"
sshpass -p q1p0w2o9 scp /root/.ssh/config root@$BKNFW2:/root/.ssh/config
sshpass -p $PASSWDFW02 ssh $BKNFW2 "sh -x /root/chgkey2.sh"