#!/bin/bash
	#####################################
	##    Configuração Regras de NAT   ##
	##        Data:  10/03/2016        ##
	##       Autor: Tiago Silva        ##
	#####################################
menu() {
echo -e "\n\\033[1;39m \\033[1;32mSelecione a Opção desejada:\\033[1;39m \\033[1;0m"
echo -e "\n\\033[1;39m \\033[1;32m [Digite q para Sair]\\033[1;39m \\033[1;0m"
echo -e "1) \\033[1;39m \\033[1;32mConfiguração de Regras Padrão - Firewall\\033[1;39m \\033[1;0m"
echo -e "2) \\033[1;39m \\033[1;32mConfiguração de Regras Zabbix\\033[1;39m \\033[1;0m"
echo -e "3) \\033[1;39m \\033[1;32mConfiguração de Regras AppAssure\\033[1;39m \\033[1;0m\n"
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
        exit
        ;;
        *)
        echo -e "\n[Digite uma opção válida!]\n"
        menu
        ;;
        esac

}

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
                                echo -e "\n####Regras de Nat do VIP $VIP para Servidor $SERVER####" >> ARQNAT
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




        echo -e '\n########### Regras de retorno ##########' >> ARQNAT
        cat ARQNAT2 | uniq >> ARQNAT
                clear
                echo -e "\\033[1;39m \\033[1;32mLista de Regras Criadas:\n\\033[1;39m \\033[1;0m"
                rm -rf ARQNAT2
                cat ARQNAT

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

menu