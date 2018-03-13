#!/bin/bash
#
###############################
# AUTHOR: AMAURI HIDEKI       #
# DATE: 24/03/2017            #
###############################

DIR='/etc/ipsec.d'

IPSEC_CONFIGURAR(){
clear
TST=`test -z "$BACKEND" > /dev/null; echo $?`
VIP=`grep 'listen=' /etc/ipsec.conf | cut -d '=' -f2`

# INTERACOES
echo -ne "\nVIP do lado da MANDIC:\n"
echo "$VIP"

if [ $TST -eq 1 ]
then
RETORNO=`grep -i '/' $BACKEND > /dev/null; echo $?`
echo -ne "\n Rede backend MANDIC:\n\n"
echo $BACKEND
else
echo -ne "\n Informe o SUBNET BACKEND da MANDIC:\n"
read BACKEND
export BACKEND
fi

echo -ne "\n Informe o NOME para a vpndo Cliente:\n"
read NOME
export NOME

echo -ne "\n Informe o IP(PEER) de Internet do Cliente:\n"
read IPCLIENTE
export IPCLIENTE

echo -ne " Informe o SUBNET BACKEND do Cliente:\n"
read BACKENDCLIENTE
export BACKENDCLIENTE

## Fases 1 e 2 ##########################################
echo -n "cipher: des,3des,aes128 e aes256"
echo -n "hash: sha1 ou md5"
echo -n "pfsgroup(DHgroup): modp1024,modp1536,e modp2048"
#########################################################


echo -ne "\n Informe a Primeira fase: (Ex: 3des-sha1;modp1024)\n"
read FASE1
export FASE1

echo -ne "\n Informe o tempo da Primeira fase: (Ex.: 28800s)\n"
read TEMPO1
export TEMPO1

echo -ne "\n Informe a Segunda fase: (Ex: 3des-sha1;modp1024)\n"
read FASE2
export FASE2

echo -ne "\n Informe o tempo da Segunda fase: (Ex.: 3600s)\n"
read TEMPO2
export TEMPO2

echo -ne "\n Informe a PSK\n"
read SENHA
export SENHA

echo "conn $NOME
 type=tunnel
 left=$VIP
 leftsubnet=$BACKEND

# Funcao MultiLink
# right=%any

# DADOS REDE CLIENTE
 right=$IPCLIENTE
 rightsubnet=$BACKENDCLIENTE

# PHASE1 de AUTENTICACAO
 ike=$FASE1

# PHASE2 de AUTENTICACAO
 phase2alg=$FASE2
 keyexchange=ike
 ikelifetime=$TEMPO1
 keylife=$TEMPO2
 dpddelay=10
 dpdtimeout=5
 dpdaction=restart_by_peer
 authby=secret
 auto=start
 pfs=no
" > $DIR/vpn-$NOME.conf

echo "$VIP $IPCLIENTE : PSK $SENHA" > $DIR/vpn-$NOME.secrets

}

IPSEC_INSTALAR(){
# INSTALACAO DE PACOTES
rpm -ivh http://177.70.98.38/linux/ipsec/pacotes/epel-release-6-8.noarch.rpm --force
yum update -y
yum install openswan.x86_64 openswan-doc.x86_64 NetworkManager-openswan.x86_64 pwgen.x86_64 -y

clear

# INTERACOES
echo -n " Informe o VIP do lado da MANDIC: "
read VIP
export VIP

echo -n " Informe o SUBNET BACKEND da MANDIC: "
read BACKEND
export BACKEND

# ARQUIVOS DE CONFIGURACAO
echo "# Please place your own config files in /etc/ipsec.d/ ending in .conf

version 2.0     # conforms to second version of ipsec.conf specification

# basic configuration
config setup
        listen=$VIP
        protostack=netkey
        nat_traversal=yes
        virtual_private=%v4:%v4:172.16.0.0/12,%v4:192.168.0.0/16,%v4:10.0.0.0/8,%v4:!$BACKEND
        oe=off
        plutostderrlog=/var/log/pluto.log


#You may put your configuration (.conf) file in the "/etc/ipsec.d/" and uncomment this.
include /etc/ipsec.d/*.conf
" > /etc/ipsec.conf

IPSEC_CONFIGURAR $BACKEND
}

LISTANDO_CONFIGURACOES(){
clear
LIST=`ls $DIR | grep '.conf'`
options=( $LIST )

MENU_LIST(){
    echo -e "\\033[1;39m \\033[1;32mLista de arquivos:\\033[1;39m \\033[1;0m"
    for i in ${!options[@]}; do
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
}

prompt="SELECIONE A CONFIGURAÇÃO QUE DESEJA VER:"
while MENU_LIST && read -rp "$prompt" num && [[ "$num" ]]; do
    (( num > 0 && num <= ${#options[@]} )) ||
    { msg="OPÇÃO INVÁLIDA: $num"; continue; }
    ((num--)); msg="${options[num]} FOI ${choices[num]:+un}SELECIONADA" ; CONFIG=${options[num]};

EXIBIR_CONF $CONFIG

echo -ne "\n\nDeseja alterar esta configuração?
1 - SIM
2 - LISTAR NOVAMENTE
3 - SAIR\n\n
Opção:"

read exibir_config
export exibir_config

case $exibir_config in

1) MENU_EDITAR $CONFIG ;;
2) LISTANDO_CONFIGURACOES ;;
3) echo "Saindo"; sleep 1; exit ;;
*) echo "Opção inválida" ; LISTANDO_CONFIGURACOES ;;

esac

done

}

EXIBIR_CONF(){
clear
echo -ne "\nRedes:\n"
echo -ne "\nMANDIC:\n"
grep -e 'left=' -e 'leftsubnet' -e 'leftsubnets' $DIR/$CONFIG | grep -v '#'
echo -ne "CLIENTE:\n"
grep -e 'right' -e 'rightsubnet' -e 'rightsubnets' $DIR/$CONFIG | grep -v '#'

echo -ne "\nPrimeira Fase:\n"
grep -e 'ike=' -e 'ikelifetime' $DIR/$CONFIG | grep -v '#'
echo -ne "\nSegunda Fase:\n"
grep -e 'phase2alg' -e 'keylife' $DIR/$CONFIG | grep -v '#'
}

MENU_EDITAR(){
clear
echo -ne "Informe o que deseja alterar:\n"

echo -ne "Editar $CONFIG:\n"

echo -ne "
1 - REDE
2 - PRIMEIRA FASE
3 - SEGUNDA FASE
4 - VOLTAR
5 - SAIR\n\n
Opção:"

read opcao
export opcao

case $opcao in

1) REDE ;;
2) FASE='ike='; ALG_AUTH $FASE ;;
3) FASE='phase2alg='; ALG_AUTH $FASE ;;
4) LISTANDO_CONFIGURACOES ;;
5) echo "Saindo"; sleep 1 ;;
*) echo "Opção inválida."; sleep 1 ; MENU_EDITAR ;;

esac
}

REDE_SUB(){
clear
echo -ne "Alter configuração '$SUB_NET' de:\n"
grep -v '#' $DIR/$CONFIG | grep $SUB_NET

echo -ne "\nPara:\n"
read SUB_NET_NEW
export SUB_NET_NEW

SUB_NET_D=`echo $SUB_NET | cut -d '=' -f1`
SBN=`echo $SUB_NET_NEW | sed "s/\//\\\\\\\\\\//g"`
REDE_OLD=`cat $DIR/$CONFIG | grep -n ^ | grep "$SUB_NET" | grep -v ':#' | grep -v  ': #' | grep -v  ':  #' | cut -d '=' -f2 | awk '{print $1}' | sed "s/\//\\\\\\\\\//g"`
NUM=`cat $DIR/$CONFIG | grep -n ^ | grep -v ':#' | grep -v  ': #' | grep -v  ':  #' | grep right= | cut -d ':' -f1`

echo -ne "Alteração de $REDE_OLD para $SUB_NET_NEW\n\n"
echo -ne "Linha  afetada $NUM\n\n"

sed -e $NUM"s/"$SUB_NET_D=$REDE_OLD/$SUB_NET_D=$SBN/ $DIR/$CONFIG

}

REDE(){
clear
echo "Editando $CONFIG"

echo -ne "Editar:\n
1 - left
2 - leftsubnet
3 - right
4 - rightsubnet
5 - Voltar\n\n
Opção:"

read rede_opc
export rede_opc

case $rede_opc in

1) SUB_NET='left=' ; REDE_SUB $CONFIG $SUB_NET ;;
2) SUB_NET='leftsubnet' ; REDE_SUB $CONFIG $SUB_NET ;;
3) SUB_NET='right=' ; REDE_SUB $CONFIG $SUB_NET ;;
4) SUB_NET='rightsubnet' ; REDE_SUB $CONFIG $SUB_NET ;;
*) echo "Opção inválida."; sleep 1 ; REDE ;;

esac

}

ALG_AUTH(){
clear
echo -ne "Algoritimos de autenticação\n"

#DES (Data Encryption Standard) — Uses an encryption key that is 56 bits long. This is the weakest of the three algorithms.
#3DES (Triple-DES) — An encryption algorithm based on DES that uses DES to encrypt the data three times.
#AES (Advanced Encryption Standard) — The strongest encryption algorithm available. Fireware XTM can use AES encryption keys of these lengths: 128, 192, or 256 bits.
echo -ne "CRIPTOGRAFIA:\n
1 - DES
2 - 3DES
3 - AES128
4 - AES192
5 - AES256\n\n
Opção:"

read CRIPTOGRAFIA
export CRIPTOGRAFIA

case $CRIPTOGRAFIA in

1) CRIPTOGRAFIA='des' ;;
2) CRIPTOGRAFIA='3des' ;;
3) CRIPTOGRAFIA='aes128' ;;
4) CRIPTOGRAFIA='aes192' ;;
5) CRIPTOGRAFIA='aes256' ;;
*) echo "Opção inválida"; sleep 1; ALG_AUTH ;;

esac


echo "Configuração: $CRIPTOGRAFIA"
#HMAC-MD5 (Hash Message Authentication Code — Message Digest Algorithm 5)
#HMAC-SHA1 (Hash Message Authentication Code — Secure Hash Algorithm 1)
#HMAC-SHA2 (Hash Message Authentication Code — Secure Hash Algorithm 2)
echo -ne "AUTENTICAÇÃO:\n
1 - MD5
2 - SHA1
3 - SHA256(SHA2-256)
4 - SHA384(SHA2-384)
5 - SHA512(SHA2-512)\n\n
Opção:"

read AUTENTICACAO
export AUTENTICACAO

case $AUTENTICACAO in

1) AUTENTICACAO='md5' ;;
2) AUTENTICACAO='sha1' ;;
3) AUTENTICACAO='sha256' ;;
4) AUTENTICACAO='sha384' ;;
5) AUTENTICACAO='sha512' ;;
*) echo "Opção inválida"; sleep 1; ALG_AUTH ;;

esac

echo "Configuração: $CRIPTOGRAFIA-$AUTENTICACAO;"
#A Diffie-Hellman key group is a group of integers used for the Diffie-Hellman key exchange. Fireware XTM can use DH groups 1, 2, 5, 14, 15, 19, and 20.
echo "GRUPO Diffie-Hellman (Key Exchange Algorithm):\n
1 - DH Group 1: 768-bit group
2 - DH Group 2: 1024-bit group
3 - DH Group 5: 1536-bit group
4 - DH Group 14: 2048-bit group
5 - DH Group 15: 3072-bit group
6 - DH Group 19: 256-bit elliptic curve group
7 - DH Group 20: 384-bit elliptic curve group\n\n
Opção:"

read DH
export DH

case $DH in

1) CRIPTOGRAFIA='modp768' ;;
2) CRIPTOGRAFIA='modp1024' ;;
3) CRIPTOGRAFIA='modp1536' ;;
4) CRIPTOGRAFIA='modp2048' ;;
5) CRIPTOGRAFIA='modp3072' ;;
6) CRIPTOGRAFIA='modp256' ;;
7) CRIPTOGRAFIA='modp384' ;;
*) echo "Opção inválida"; sleep 1; ALG_AUTH ;;

esac

echo "Configuração: $CRIPTOGRAFIA-$AUTENTICACAO;$DH\n" ; sleep 1

clear

FASE_OLD=`cat $DIR/$CONFIG | grep -n ^ | grep "$FASE" | grep -v ':#' | grep -v  ': #' | grep -v  ':  #' | cut -d '=' -f2`
NUM=`cat $DIR/$CONFIG | grep -n ^ | grep "$FASE" | grep -v ':#' | grep -v  ': #' | grep -v  ':  #' | cut -d ':' -f1`

echo -ne "Rede $FASE_OLD alterado para $FASE$CRIPTOGRAFIA-$AUTENTICACAO;$DH\n\n"
echo -ne "Linha alterada $NUM\n\n\n"

sed -e $NUM"s/"$FASE$FASE_OLD/$FASE$CRIPTOGRAFIA-$AUTENTICACAO\;$CRIPTOGRAFIA/ $DIR/$CONFIG

}

MENU(){
clear

echo -ne "\n
 __  __       _____ _____   _____ ______ _____
|  \/  |  _  |_   _|  __ \ / ____|  ____/ ____|
| \  / | (_)   | | | |__) | (___ | |__ | |
| |\/| |       | | |  ___/ \___ \|  __|| |
| |  | |  _   _| |_| |     ____) | |___| |____
|_|  |_| (_) |_____|_|    |_____/|______\_____|\n"

echo -ne "
1 - Instalar serviço IPSEC
2 - Adicionar novo SITE
3 - Listar configurações existentes/editar
4 - SAIR

Opção:"
read ipsec_op
export ipsec_op

case $ipsec_op in
1) IPSEC_INSTALAR ;;
2) IPSEC_CONFIGURAR ;;
3) LISTANDO_CONFIGURACOES ;;
4) echo "Saindo"; sleep 1 ;;
*) echo "Opção inválida"; sleep 1 ;  MENU ;;

esac
}

MENU