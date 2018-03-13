#/bin/bash

scp CD131655-L-GUARDEAQUI-FW01-SP:/etc/init.d/firewall /etc/init.d/firewall

sed -i 's/ssh CD131655-L-GUARDEAQUI-FW01-RJ/#ssh CD131655-L-GUARDEAQUI-FW01-RJ/g' /etc/init.d/firewall


Substituir_VIP_Firewall (){
sed -i s/177.70.99.160/187.33.2.170/g /etc/init.d/firewall
sed -i s/177.70.99.161/187.33.2.155/g /etc/init.d/firewall
sed -i s/177.70.99.162/187.33.2.156/g /etc/init.d/firewall
sed -i s/177.70.99.163/187.33.2.157/g /etc/init.d/firewall
sed -i s/177.70.99.164/187.33.2.158/g /etc/init.d/firewall
sed -i s/177.70.99.165/187.33.2.159/g /etc/init.d/firewall
sed -i s/177.70.99.167/187.33.2.160/g /etc/init.d/firewall
sed -i s/177.70.99.219/187.33.2.161/g /etc/init.d/firewall
sed -i s/177.70.99.220/187.33.2.165/g /etc/init.d/firewall
sed -i s/177.70.99.221/187.33.2.166/g /etc/init.d/firewall

##Adicionar mais linhas se necessário

sed -i s/177.70.99.149/187.33.2.154/g /etc/init.d/firewall
sed -i s/-SP/-RJ/g /etc/init.d/firewall


sh +x /etc/init.d/firewall restart

}

Substituir_VIP_VPN (){
echo "Replacing VPN vIP ..."

clear

sed -i s/177.70.99.222/187.33.2.169/g /etc/ipsec.d/*.conf
sed -i s/177.70.99.222/187.33.2.169/g /etc/ipsec.d/*.secrets

echo "
"

echo -e "\\033[1;39m \\033[1;32m[Finalizado]\\033[1;39m \\033[1;0m"

echo "
"

#grep 'left=' /etc/ipsec.d/*.conf | egrep -v v6neighbor | awk '{print $1$2}' | sed 's/\/etc\/ipsec.d\///g' | sed 's/:/ - /g' | sed 's/.conf//g' | sed 's/left=//g'

}

##Chamar Funções
Substituir_VIP_Firewall
Substituir_VIP_VPN