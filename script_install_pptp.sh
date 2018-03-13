#!/bin/bash

###############################
# INSTALAÇÃO VPN PPTP         #
# Autor:        AMAURI HIDEKI #
# Data:            29/08/2016 #
# Atualização :    30/08/2016 #
# Versão:              v.1.02 #
###############################


#yum update -y

echo ''
echo 'Pré-requisito:'
echo 'IP apenas para a vpn'
echo ''
echo 'Será realizado a instalação dos pacotes:'
echo 'pptp.x86_64'
echo 'pptpd.x86_64'
echo 'sipcalc-1.1.6-4.el6.x86_64'
echo ''

echo 'Aguardando 3 segundos para a inicialização da configuração...'
sleep 3

# PACOTES NECESSÁRIOS PARA INSTALAÇÃO E CONFIGURAÇÃO:
echo ''
echo 'Iniciando instalação dos pacotes'
echo ''
yum install pptp.x86_64 pptpd.x86_64 sipcalc-1.1.6-4.el6.x86_64 -y
echo 'Instalação concluída'

# DECALARAÇÃO DE VARIÁVEIS:
read -p 'Informe Rede que irá utilizar na VPN ( Ex.: 10.1.0.0/24 ) :' REDE
read -p 'Informe o Login cliente VPN ( Ex.: amauri.hideki ) :' LOGIN
read -p 'Informe a Senha cliente VPN ( Ex.: senha_cliente ) :' SENHA

LOCALIP=`sipcalc $REDE | grep 'Usable range' | cut -d ' ' -f3`
REDEINI=`sipcalc $REDE | grep 'Usable range' | cut -d ' ' -f3 | cut -d '.' -f4`
REDEFIM=`sipcalc $REDE | grep 'Usable range' | cut -d ' ' -f5 | cut -d '.' -f4`
REDEINIMAISUM=$(( $REDEINI +1 ))
REMOTERANGE="$REDEINIMAISUM-$REDEFIM"
REMOTE=`echo "$REDE" | cut -d '/' -f1 | cut -d '.' -f1,2,3`
REMOTEIP="$REMOTE"."$REMOTERANGE"
REDELOCAL=`ip a | grep eth1 | grep -n ^ | grep ^2 | cut -d ' ' -f6`

echo ''
echo 'Iniciando configuração pptpd'
echo ''	

mv /etc/pptpd.conf /etc/pptpd.conf_ori
echo "option /etc/ppp/options.pptpd
logwtmp
localip $LOCALIP
remoteip $REMOTEIP
" > /etc/pptpd.conf

mv /etc/ppp/options.pptpd /etc/ppp/options.pptpd_ori
echo 'name pptpd
refuse-eap
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4' > /etc/ppp/options.pptpd

echo 'ms-dns 8.8.8.8
ms-dns 8.8.4.4' > /etc/ppp/pptpd-options

echo ''
echo 'Configurando usuário cliente pptpd'
echo ''

echo "# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
$LOGIN   pptpd   $SENHA              *" > /etc/ppp/chap-secrets

echo ''
echo 'SETANDO REGRA DE FW NA MEMÓRIA'
echo ''
iptables -A INPUT -i eth0 -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT -i eth0 -p gre -j ACCEPT
iptables -A FORWARD -p gre -j ACCEPT
iptables -A FORWARD -i ppp+ -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o ppp+ -j ACCEPT
iptables -A FORWARD -s $REDE -j ACCEPT
iptables -A FORWARD -s $REDE -d $REDELOCAL -j ACCEPT
iptables -A FORWARD -s $REDELOCAL -d $REDE -j ACCEPT
iptables -t nat -A POSTROUTING -s $REDELOCAL -d $REDE -j RETURN
iptables -t nat -A POSTROUTING -s $REDE -d $REDELOCAL -j RETURN

echo ''
echo 'Adicionar regras Firewall'
echo ''
echo '## REGRAS PPTP ##'
echo '####################################################################'
echo '$IPTABLES -A INPUT -i eth0 -p tcp --dport 1723 -j ACCEPT'
echo '$IPTABLES -A INPUT -i eth0 -p gre -j ACCEPT'
echo '$IPTABLES -A FORWARD -p gre -j ACCEPT'
echo '$IPTABLES -A FORWARD -i ppp+ -o eth0 -j ACCEPT'
echo '$IPTABLES -A FORWARD -i eth0 -o ppp+ -j ACCEPT'
echo '$IPTABLES -A FORWARD -s '$REDE' -j ACCEPT'
echo '$IPTABLES -A FORWARD -s '$REDE' -d '$REDELOCAL' -j ACCEPT'
echo '$IPTABLES -A FORWARD -s '$REDELOCAL' -d '$REDE' -j ACCEPT'
echo '$IPTABLES -t nat -A POSTROUTING -s '$REDELOCAL' -d '$REDE' -j RETURN'
echo '$IPTABLES -t nat -A POSTROUTING -s '$REDE' -d '$REDELOCAL' -j RETURN'
echo '#####################################################################'

echo ''
echo 'SETANDO MÓDULOS NA MEMÓRIA'
echo ''
modprobe ppp_deflate
modprobe ppp_async
modprobe ppp_mppe
modprobe ppp_async

echo ''
echo 'Adicionar módulos no Firewall'
echo ''
echo 'modprobe ppp_deflate'
echo 'modprobe ppp_async'
echo 'modprobe ppp_mppe'
echo 'modprobe ppp_async'

/etc/init.d/pptpd restart

ppstats