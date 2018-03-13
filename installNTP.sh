#!/bin/bash

###########################
# Configuração NTP        #
# Data:  13/11/2015       #
# Autor: Amauri Hideki    #
###########################

inicio(){
echo ""
echo -e "\\033[1;39m \\033[1;32mInstalação NTP\\033[1;39m \\033[1;0m"
echo ""

sleep 1
echo ""
echo -e "\\033[1;39m \\033[1;32mDetectando distro\\033[1;39m \\033[1;0m"
echo ""
# Detectando distro Ubuntu ou CentOS
if [ -s /etc/lsb-release ] ; then
echo "Distro UBUNTU"

sleep 1

echo ""
echo -e "\\033[1;39m \\033[1;32mIniciando instação NTP\\033[1;39m \\033[1;0m"
echo ""

sleep 1

apt-get install ntp -y
configuracao_ntp
conclusao_ubuntu
atualizando_checando_horario_delay

elif [ -s /etc/centos-release ] ; then
echo "Distro CentOS"

sleep 1

echo ""
echo -e "\\033[1;39m \\033[1;32mIniciando instação NTP\\033[1;39m \\033[1;0m"
echo ""

sleep 1

yum install ntp -y
configuracao_ntp
conclusao_centos
atualizando_checando_horario_delay

echo ""
echo -e "\\033[1;39m \\033[1;32mInstação NTP concluída\\033[1;39m \\033[1;0m"
echo ""

sleep 1

fi
}

configuracao_ntp(){
echo ""
echo -e "\\033[1;39m \\033[1;32mAjustando configuração NTP\\033[1;39m \\033[1;0m"
echo ""

mv /etc/ntp.conf /etc/ntp.conf_old && touch /etc/ntp.conf
echo '# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

driftfile /var/lib/ntp/ntp.drift
logfile /var/log/ntp.log

# Enable this if you want statistics to be logged.
statsdir /var/log/ntpstats/

statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

# Specify one or more NTP servers.

# Use servers from the NTP Pool Project. Approved by Ubuntu Technical Board
# on 2011-02-08 (LP: #104525). See http://www.pool.ntp.org/join.html for
# more information.
server a.st1.ntp.br iburst
server b.st1.ntp.br iburst
server c.st1.ntp.br iburst
server d.st1.ntp.br iburst
server gps.ntp.br iburst
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst

# Use Ubuntus ntp server as a fallback.
server ntp.ubuntu.com

# Access control configuration; see /usr/share/doc/ntp-doc/html/accopt.html for
# details.  The web page <http://support.ntp.org/bin/view/Support/AccessRestrictions>
# might also be helpful.
#
# Note that "restrict" applies to both servers and clients, so a configuration
# that might be intended to block requests from certain clients could also end
# up blocking replies from your own upstream servers.

# By default, exchange time with everybody, but dont allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1

# Clients from this (example!) subnet have unlimited access, but only if
# cryptographically authenticated.
#restrict 192.168.123.0 mask 255.255.255.0 notrust


# If you want to provide time to your local subnet, change the next line.
# (Again, the address is an example only.)
#broadcast 192.168.123.255

# If you want to listen to time broadcasts on your local subnet, de-comment the
# next lines.  Please do this only if you trust everybody on the network!
#disable auth
#broadcastclient' > /etc/ntp.conf

sleep 1

echo ""
echo -e "\\033[1;39m \\033[1;32mAjuste configuração NTP concluído\\033[1;39m \\033[1;0m"
echo ""
}

conclusao_ubuntu(){
sysv-rc-conf ntp on
}

conclusao_centos(){
chkconfig ntp on
}

atualizando_checando_horario_delay(){
echo ""
echo -e "\\033[1;39m \\033[1;32mAtualizando NTP\\033[1;39m \\033[1;0m"
echo ""

ntpd -q -g
service ntp restart

echo -e "\\033[1;39m \\033[1;33mAtualizando NTP\\033[1;39m \\033[1;0m"

echo ""
echo -e "\\033[1;39m \\033[1;32mChecando NTP\\033[1;39m \\033[1;0m"
echo ""

ntpq -p
}

inicio
#####################################
# Chamada dentro do inicio          #
#                                   #
# configuracao_ntp                  #
# conclusao_ubuntu                  #
# conclusao_centos                  #
#atualizando_checando_horario_delay #
#####################################