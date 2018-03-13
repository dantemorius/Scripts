#!/bin/bash

function OK()   {
echo -e "Rotas \\033[1;39m [ \\033[1;32mOK\\033[1;39m ]\\033[1;0m"
                }

function FALHOU()       {
echo -e "Rotas \\033[1;39m [ \\033[1;31mFALHOU\\033[1;39m ]\\033[1;0m"
}

function START(){

echo 'ROUTERS_TELEMATICA'
route add -net 130.176.251.0/25 gw 10.251.36.1
route add -net 130.176.243.0/24 gw 10.251.36.1
route add -net 10.201.8.240/28 gw 10.251.36.1
route add -net 10.249.19.160/27 gw 10.251.36.1
route add -net 10.255.226.128/26 gw 10.251.36.1
route add -net 10.251.0.0/16 gw 10.251.36.1
route add -net 10.255.226.192/26 gw 10.251.36.1
route add -net 10.255.233.64/26 gw 10.251.36.1

OK
}

function STOP(){

echo 'ROUTERS_TELEMATICA'
route del -net 130.176.251.0/25 gw 10.251.36.1
route del -net 130.176.243.0/24 gw 10.251.36.1
route del -net 10.201.8.240/28 gw 10.251.36.1
route del -net 10.249.19.160/27 gw 10.251.36.1
route del -net 10.255.226.128/26 gw 10.251.36.1
route del -net 10.251.0.0/16 gw 10.251.36.1
route del -net 10.255.226.192/26 gw 10.251.36.1
route add -net 10.255.233.64/26 gw 10.251.36.1

OK
}

function STATUS (){

route -n | grep 172.31.250.5

}

# Comandos

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

                status)
                STATUS
                ;;

                *)

                echo -e "Permited Options $0 {start|stop|status|restart}"
                ;;
        esac