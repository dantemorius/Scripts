#!/bin/bash

############################
# Instalação WildFly v8    #
# Data:  16/12/2015        #
# Autor: Tiago Silva       #
#                          #
############################

###OBS: Substituir "jdk1.8.0_65" pela versão necessária do Java.


###Preparação do ambiente - Instalação Java
instalacao_java_SDK_v8{

#Apontando para o servidor correto para instalação:
cd /opt/

#Download Java SDK 8.66 - Linux Arquitetura X64
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jdk-8u66-linux-x64.tar.gz"

sleep 1

#Descompactando pacote:
tar xzf jdk-8u66-*.tar.gz

#Instalação dos módulos alternativos do Java:
cd /opt/jdk1.8.0_65/
sudo alternatives --install /usr/bin/java java /opt/jdk1.8.0_65/bin/java 2
sudo alternatives --config java

sleep 1

#Comparar a saída e escolher a opção com caminho similar a /opt/jdk1.8.0_65/bin/java {
#Digite o número correspondente à opção e aperte ENTER
#There is 1 program that provides 'java'.
#Selection    Command
#  *+ 1           /opt/jdk1.8.0_65/bin/java
#
#Enter to keep the current selection[+], or type selection number: 1

#Ajustando o caminho da aplicação para uso de javac e jar:
sudo alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_65/bin/jar 2
sudo alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_65/bin/javac 2
sudo alternatives --set jar /opt/jdk1.8.0_65/bin/jar
sudo alternatives --set javac /opt/jdk1.8.0_65/bin/javac

#Exportando variáveis necessárias para o Java:
export JAVA_HOME=/opt/jdk1.8.0_65
export JRE_HOME=/opt/jdk1.8.0_65/jre
export PATH=$PATH:/opt/jdk1.8.0_65/bin:/opt/jdk1.8.0_65/jre/bin

echo -e "\\033[1;39m \\033[1;32mCriando arquivo java.sh\\033[1;39m \\033[1;0m"

sleep 1

#Criação Permanente dos apontamentos acima:
echo '
if ! echo ${PATH} | grep -q /opt/jdk1.8.0_45/bin ; then
   export PATH=/opt/jdk1.8.0_45/bin:${PATH}
fi
if ! echo ${PATH} | grep -q /opt/jdk1.8.0_45/jre/bin ; then
   export PATH=/opt/jdk1.8.0_45/jre/bin:${PATH}
fi
export JAVA_HOME=/opt/jdk1.8.0_45
export JRE_HOME=/opt/jdk1.8.0_45/jre
export CLASSPATH=.:/opt/jdk1.8.0_45/lib/tools.jar:/opt/jdk1.8.0_45/jre/lib/rt.jar
} ' > /etc/profile.d/java.sh

#Ajuste de permissões:
chown root:root /etc/profile.d/java.sh
chmod 755 /etc/profile.d/java.sh
}

instalacao_wildfly_8{

#Criando o Script de Configuração do Wildfly
echo -e "\\033[1;39m \\033[1;32mCriando arquivo de Instalação do Wildfly 8\\033[1;39m \\033[1;0m"

sleep 1

echo '
#!/bin/bash
#Title : wildfly-install.sh
#Description : The script to install Wildfly 8.x
#Original script: http://sukharevd.net/wildfly-8-installation.html
         
# This version is the only variable to change when running the script
WILDFLY_VERSION=8.2.0.Final
WILDFLY_FILENAME=wildfly-$WILDFLY_VERSION
WILDFLY_ARCHIVE_NAME=$WILDFLY_FILENAME.tar.gz
WILDFLY_DOWNLOAD_ADDRESS=http://download.jboss.org/wildfly/$WILDFLY_VERSION/$WILDFLY_ARCHIVE_NAME

# Specify the destination location
INSTALL_DIR=/opt
WILDFLY_FULL_DIR=$INSTALL_DIR/$WILDFLY_FILENAME
WILDFLY_DIR=$INSTALL_DIR/wildfly
         
WILDFLY_USER="wildfly"
WILDFLY_SERVICE="wildfly"
         
WILDFLY_STARTUP_TIMEOUT=240
WILDFLY_SHUTDOWN_TIMEOUT=30
         
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
         
if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root."
exit 1
fi
         
echo "Downloading: $WILDFLY_DOWNLOAD_ADDRESS..."
[ -e "$WILDFLY_ARCHIVE_NAME" ] && echo 'Wildfly archive already exists.'
if [ ! -e "$WILDFLY_ARCHIVE_NAME" ]; then
wget $WILDFLY_DOWNLOAD_ADDRESS
if [ $? -ne 0 ]; then
echo "Not possible to download Wildfly."
exit 1
fi
fi

echo "Cleaning up..."
rm -f "$WILDFLY_DIR"
rm -rf "$WILDFLY_FULL_DIR"
rm -rf "/var/run/$WILDFLY_SERVICE/"
rm -f "/etc/init.d/$WILDFLY_SERVICE"
         
echo "Installation..."
mkdir $WILDFLY_FULL_DIR
tar -xzf $WILDFLY_ARCHIVE_NAME -C $INSTALL_DIR
ln -s $WILDFLY_FULL_DIR/ $WILDFLY_DIR
useradd -s /sbin/nologin $WILDFLY_USER
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/
         
echo "Registering Wildfly as service..."
cp $WILDFLY_DIR/bin/init.d/wildfly-init-redhat.sh /etc/init.d/$WILDFLY_SERVICE
WILDFLY_SERVICE_CONF=/etc/default/wildfly.conf

chmod 755 /etc/init.d/$WILDFLY_SERVICE

if [ ! -z "$WILDFLY_SERVICE_CONF" ]; then
echo "Configuring service..."
echo JBOSS_HOME=\"$WILDFLY_DIR\" > $WILDFLY_SERVICE_CONF
echo JBOSS_USER=$WILDFLY_USER >> $WILDFLY_SERVICE_CONF
echo JBOSS_MODE=standalone >> $WILDFLY_SERVICE_CONF
echo JBOSS_CONFIG=standalone.xml >> $WILDFLY_SERVICE_CONF
echo STARTUP_WAIT=$WILDFLY_STARTUP_TIMEOUT >> $WILDFLY_SERVICE_CONF
echo SHUTDOWN_WAIT=$WILDFLY_SHUTDOWN_TIMEOUT >> $WILDFLY_SERVICE_CONF
fi

echo "Configuration backup"
cp $WILDFLY_DIR/standalone/configuration/standalone.xml $WILDFLY_DIR/standalone/configuration/standalone-org.xml
cp $WILDFLY_DIR/bin/standalone.conf $WILDFLY_DIR/bin/standalone-org.conf

echo "Configuring application server..."
sed -i -e 's,<deployment-scanner path="deployments" relative-to="jboss.server.base.dir" scan-interval="5000"/>,<deployment-scanner path="deployments" relative-to="jboss.server.base.dir" scan-interval="5000" deployment-timeout="'$WILDFLY_STARTUP_TIMEOUT'"/>,g' $WILDFLY_DIR/standalone/configuration/standalone.xml
# Enable access from any server
sed -i -e 's,<inet-address value="${jboss.bind.address.management:127.0.0.1}"/>,<any-address/>,g' $WILDFLY_DIR/standalone/configuration/standalone.xml
sed -i -e 's,<inet-address value="${jboss.bind.address:127.0.0.1}"/>,<any-address/>,g' $WILDFLY_DIR/standalone/configuration/standalone.xml

# The below line is added to avoid warning when starting WildFly with jdk 8 SE, as the JVM memory parameter changed
sed -i -e 's,MaxPermSize,MaxMetaspaceSize,g' $WILDFLY_DIR/bin/standalone.conf

echo "Configuring Firewalld for WildFly ports"
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --permanent --add-port=9990/tcp
firewall-cmd --permanent --add-port=9993/tcp
firewall-cmd --reload

echo "Backup management user"
cp $WILDFLY_DIR/standalone/configuration/mgmt-users.properties $WILDFLY_DIR/standalone/configuration/mgmt-users-org.properties
cp $WILDFLY_DIR/standalone/configuration/application-users.properties $WILDFLY_DIR/standalone/configuration/application-users-org.properties
cp $WILDFLY_DIR/domain/configuration/mgmt-users.properties $WILDFLY_DIR/domain/configuration/mgmt-users-org.properties
cp $WILDFLY_DIR/domain/configuration/application-users.properties $WILDFLY_DIR/domain/configuration/application-users-org.properties
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/standalone/configuration/mgmt-users-org.properties
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/standalone/configuration/application-users-org.properties
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/domain/configuration/mgmt-users-org.properties
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/domain/configuration/application-users-org.properties

echo "Starting Wildfly"
service $WILDFLY_SERVICE start
chkconfig --add wildfly
chkconfig --level 2345 wildfly on

echo "Done." ' > /opt/wildfly-install.sh

#Executando o Script
echo -e "\\033[1;39m \\033[1;32mInstalando o Wildfly\\033[1;39m \\033[1;0m"

sleep 1

sh +x /opt/wildfly-install.sh

#Executando o Script para criação de usuários do console do WildFly:
echo "\\033[1;39m \\033[1;32mDigite opção A, enter e em seguida defina um usuário e senha para acesso via http://IP:9993 para acesso à administração do Wildfly\\033[1;39m \\033[1;0m"
/opt/wildfly/bin/add-user.sh


##Regras Firewall Stand Alone
# WILDFLY
#$IPTABLES -t nat -A PREROUTING -d 187.191.99.139 -p tcp --dport 8080 -j DNAT --to 10.1.84.7:8080
#$IPTABLES -t nat -A PREROUTING -d 187.191.99.139 -p tcp --dport 8443 -j DNAT --to 10.1.84.7:8443
#$IPTABLES -t nat -A PREROUTING -d 187.191.99.139 -p tcp --dport 9990 -j DNAT --to 10.1.84.7:9990
#$IPTABLES -t nat -A PREROUTING -d 187.191.99.139 -p tcp --dport 9993 -j DNAT --to 10.1.84.7:9993
#$IPTABLES -t nat -A PREROUTING -d 187.191.99.139 -p tcp --dport 80 -j DNAT --to 10.1.84.7:80


echo "\\033[1;39m \\033[1;32m[|||||Bem vindo ao Ambiente Wildfly||||||] \\033[1;39m \\033[1;0m"
sleep 1
}