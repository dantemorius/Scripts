#!/bin/bash

###################################################
# Daemon para Sleep                               #
###################################################
#                                                 #
# Autor:   Amauri Hideki Taira                    #
# Criacao: 14/09/2016                             #
# E-mail:  amauri.hideki@mandic.net.br            #
#                                                 #
###################################################


case $1 in
        start)

#Se diferente de 0 continuar
continuar=1
while [ $continuar -ne 0 ]
do
        IPUP=`ip a| grep 'eth0:1'| cut -d ':' -f2`
        if [ "$IPUP" == "1" ]
                then
                continuar=0
                echo "Iniciando OPENVPN"
                sleep 1
                /etc/init.d/openvpnas start
        else
                continuar=1
                echo "loop checando eth0:1 187.191.101.6 para subor OPENVPN"
                sleep 1
        fi
done


        ;;
        stop)
        /etc/init.d/openvpnas stop
        ;;
esac
