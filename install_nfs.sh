#!/bin/bash
 
###########################
##   INSTALAÇÃO NFS      ##
## Data:  30/11/2015     ##
## Autor: Amauri Hideki  ##
###########################
 
instalando_nfs(){
# Instalando NFS
yum install nfs-utils nfs-utils-lib
}
 
ajustando_configuracao_nfs(){
# Configurando NFS
echo ""
echo -e "\\033[1;39m \\033[1;32mInforme o DIRETORIO para incluir no arquivo /etc/export: ( Ex.: /aplicacao )\\033[1;39m \\033[1;0m"
echo ""
 
read novodiretorio
export novodiretorio
 
IPDEGW=`grep GATEWAY /etc/sysconfig/network-scripts/ifcfg-* | cut -d "=" -f2 | cut -d "." -f1,2,3`
echo ""$novodiretorio      $IPDEGW".0/24(rw,wdelay,no_root_squash,no_subtree_check,sec=sys,rw,no_root_squash,no_all_squash)" > /etc/exports
 
echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurado /etc/exports.\\033[1;39m \\033[1;0m"
echo ""
 
mv /etc/hosts.allow /etc/hosts.allow_ori
echo '#
# hosts.allow This file contains access rules which are used to
# allow or deny connections to network services that
# either use the tcp_wrappers library or that have been
# started through a tcp_wrappers-enabled xinetd.
#
# See man 5 hosts_options and man 5 hosts_access
# for information on rule syntax.
# See man tcpd for information on tcp_wrappers
#
portmap: '$IPDEGW'.0/24
lockd: '$IPDEGW'.0/24
rquotad: '$IPDEGW'.0/24
mountd: '$IPDEGW'.0/24
statd: '$IPDEGW'.0/24' > /etc/hosts.allow
 
echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurado /etc/hosts.allow.\\033[1;39m \\033[1;0m"
echo ""
 
mv /etc/hosts.deny /etc/hosts.deny_ori
 
echo '#
# hosts.deny This file contains access rules which are used to
# deny connections to network services that either use
# the tcp_wrappers library or that have been
# started through a tcp_wrappers-enabled xinetd.
#
# The rules in this file can also be set up in
# /etc/hosts.allow with a ''deny'' option instead.
#
# See ''man 5 hosts_options'' and ''man 5 hosts_access''
# for information on rule syntax.
# See ''man tcpd'' for information on tcp_wrappers
#
portmap: ALL
lockd: ALL
mountd: ALL
rquotad: ALL' > /etc/hosts.deny
 
echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurado /etc/hosts.deny.\\033[1;39m \\033[1;0m"
echo ""
 
sleep 1
}
 
ajustes_finais(){
# AJUSTES FINAIS
 
service nfs restart
chkconfig nfs on
exportfs -v
 
sleep 1
}
 
instalando_nfs
ajustando_configuracao_nfs
ajustes_finais