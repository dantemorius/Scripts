#!/bin/bash

############################
# Coleta de Dados e Confs  #
# Data:  14/12/2015        #
# Autor: Amauri Hideki     #
# Colaboração: Tiago Silva #
############################


###  Formatação KB  ###

nao_existe(){
echo ""
echo -e "\\033[1;33m$servico não EXISTE!!!!!!!!\\033["
echo ""
echo $servico > /root/runbook/rb_servicos_nao_coletados.tmp
}

# BUSCA ARQUIVO .CONF
ajuste_kb(){
# VERIFICA SE O ARQUIVO EXISTE

if [ -s $servico ] ; then
# COMANDO PARA CAPTURAR ARQUIVO
cat $servico > /root/runbook/informacoes_tmp

# Ajuste caracteres dos arquivos para importação no confluence KB
sed -i 's/#/\\#/g' /root/runbook/informacoes_tmp
sed -i 's/{/\\{/g' /root/runbook/informacoes_tmp
sed -i 's/}/\\}/g' /root/runbook/informacoes_tmp

echo ""
echo -e "\\033[1;39m \\033[1;32mColetando "$servico"\\033[1;39m \\033[1;0m"
echo ""

# Inserindo formatação no arquivo para importação no confluence KB
echo "h2. $arquivo_destino" >> /root/runbook/$arquivo_destino
echo "" >> /root/runbook/$arquivo_destino
echo "{expand:Confs "$servico"}" >> /root/runbook/$arquivo_destino
cat /root/runbook/informacoes_tmp >> /root/runbook/$arquivo_destino
echo "{expand}" >> /root/runbook/$arquivo_destino
rm -f /root/runbook/informacoes_tmp
mv /root/runbook/$arquivo_destino /root/runbook/$num.$arquivo_destino

echo ""
echo -e "\\033[1;39m \\033[1;33mColetado "$servico"\\033[1;39m \\033[1;0m"
echo ""

else
nao_existe

fi

sleep 1
}

# USA SERVIÇO (NETSTAT,IPTABLES,etc)
ajuste_kb_2(){

if [ "`$servico`"!="" ] ; then

# Ajuste caracteres dos arquivos para importação no confluence KB
sed -i 's/#/\\#/g' /root/runbook/informacoes_tmp
sed -i 's/{/\\{/g' /root/runbook/informacoes_tmp
sed -i 's/}/\\}/g' /root/runbook/informacoes_tmp

echo ""
echo -e "\\033[1;39m \\033[1;32mColetando "$servico"\\033[1;39m \\033[1;0m"
echo ""

# Inserindo formatação no arquivo para importação no confluence KB
echo "h2. $arquivo_destino" >> /root/runbook/$arquivo_destino
echo "" >> /root/runbook/$arquivo_destino
echo "{expand:Confs "$servico"}" >> /root/runbook/$arquivo_destino
cat /root/runbook/informacoes_tmp >> /root/runbook/$arquivo_destino
echo "{expand}" >> /root/runbook/$arquivo_destino
rm -f /root/runbook/informacoes_tmp
mv /root/runbook/$arquivo_destino /root/runbook/$num.$arquivo_destino

echo ""
echo -e "\\033[1;39m \\033[1;33mColetado "$servico"\\033[1;39m \\033[1;0m"
echo ""

else
nao_existe
fi
sleep 1
}

# BUSCA DIRETORIO 
ajuste_kb_3(){
if [ -e $servico ] ; then

echo ""
echo -e "\\033[1;39m \\033[1;32mCompactando "$servico"\\033[1;39m \\033[1;0m"
echo ""

tar -zcf /root/runbook/$arquivo_destino $servico

else
nao_existe
fi
sleep 1
}


###  Funções SERVIÇOS  ###

rb_default(){

###  Funções DEFAULT  ###
	
	rb_inicio(){
	# AVISO DE INICIO DA ATIVIDADE
	
	clear
	echo ""
	echo "
	 __  __       _____  _____  ___   _____ ________  ______
	|  \/  |  _  |  ___|/  _  \|  |  |   __|__    __|/   _  \
	| \  / | (_) | |   |  | |  |  |  |  |__   |  |  |   /_\  |
	| |\/| |     | |   |  | |  |  |  |   __|  |  |  |   __   |
	| |  | |  _  | |___|  |_|  |  |__|  |__   |  |  |  |  |  |
	|_|  |_| (_) |_____|\ ____/|_____|_____|  |__|  |__|  |__|
	
	"
	echo ""
	echo -e "\\033[1;33m###########################################\\033["
	echo -e "\\033[1;33m#  Script de coleta de dados co ambiente  #\\033["
	echo -e "\\033[1;33m#  Coleta dos seguintes Itens:            #\\033["
	echo -e "\\033[1;33m#  - Regras de NAT                        #\\033["
	echo -e "\\033[1;33m#  - Serviços que iniciará após o reboot  #\\033["
	echo -e "\\033[1;33m#  - Serviços e portas UPs                #\\033["
	echo -e "\\033[1;33m#  - Conf FIREWALL / IPTABLES             #\\033["
	echo -e "\\033[1;33m#  - Conf HA / HARESOURCES                #\\033["
	echo -e "\\033[1;33m#  - Conf LDIRECTORD                      #\\033["
	echo -e "\\033[1;33m#  - Conf RSYSLOG                         #\\033["
	echo -e "\\033[1;33m#  - Conf LOGROTATE                       #\\033["
	echo -e "\\033[1;33m#  - Conf IPSEC                           #\\033["
	echo -e "\\033[1;33m#  - Conf DRBD                            #\\033["
	echo -e "\\033[1;33m#  - Conf MONGODB                         #\\033["
	echo -e "\\033[1;33m#  - Conf MYSQL (CentOS / Ubuntu)         #\\033["
	echo -e "\\033[1;33m#  - Conf HTTPD / APACHE2(CentOS / Ubuntu)#\\033["
	echo -e "\\033[1;33m#  - Conf PHP                             #\\033["
	echo -e "\\033[1;33m#  - Conf VSFTD                           #\\033["
	echo -e "\\033[1;33m#  - Conf PROFTD                          #\\033["
	echo -e "\\033[1;33m#  - Conf FAIL2BAN                        #\\033["
	echo -e "\\033[1;33m#  - Conf NFS							  #\\033["
	echo -e "\\033[1;33m###########################################\\033["
	echo ""
	}
	
	rb_criando_runbook(){
	echo ""
	echo -e "\\033[1;39m \\033[1;32mCriando RUNBOOK\\033[1;39m \\033[1;0m"
	echo ""
	
	if [ -e /root/runbook ] ; then
	echo -e "\\033[1;33mO diretório /root/runbook já existe\\033["
	
	else
	# Criando diretório onde armazenará os dados do ambiente
	mkdir /root/runbook
	sleep 1
	cd /root/runbook
	sleep 1
	echo -e "O diretório /root/runbook foi criado!"
	
	fi
	
	sleep 1
	}
	
	rb_informacoes_do_servidor(){
	#Informaçoes do servidor
	printf "\n"
	cpuname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
	cpucores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	cpufreq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
	svram=$( free -m | awk 'NR==2 {print $2}' )
	svhdd=$( df -h | awk 'NR==2 {print $2}' )
	svswap=$( free -m | grep Swap | awk  -F' ' '{print $2}')
	
	if [ -f "/proc/user_beancounters" ]; then
	#svip=$(ifconfig venet0:0 | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
	svip=$(ifconfig venet0:0 | grep 'inet ' |  awk -F' ' '{print $2}' | sed 's/addr://g' | egrep -v "127.0.0.1")
	else
	svip=$(ifconfig | grep "inet " | awk -F' ' '{print $2}' | sed 's/addr://g' | egrep -v "127.0.0.1")
	fi
	
	# Exibindo na tela
	printf "==========================================================================\n"
	printf "Parâmetros do servidor:  \n"
	echo "=========================================================================="
	echo "VPS Type: $(virt-what)"
	echo "CPU Type: $cpuname"
	echo "CPU Core: $cpucores"
	echo "CPU Speed: $cpufreq MHz"
	echo "Memory: $svram MB"
	echo "Swap: $svswap MB"
	echo "Disk: $svhdd"
	echo "IP's: $svip"
	printf "==========================================================================\n"
	printf "\n"
	
	echo ""
	echo -e "\\033[1;39m \\033[1;32mAlimentando RunBook Com dados do Servidor\\033[1;39m \\033[1;0m"
	echo ""
	
	touch /root/runbook/rb_informacoes_do_servidor.txt
	sleep 1
	
	# Alimentando RunBook
	echo "h2. Parâmetros do servidor" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "" >> /root/runbook/rb_informacoes_do_servidor.txt
	
	echo "{expand:Confs do Servidor}" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "VPS Type: $(virt-what)" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "CPU Type: $cpuname" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "CPU Core: $cpucores" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "CPU Speed: $cpufreq MHz" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "Memory: $svram MB" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "Swap: $svswap MB" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "Disk: $svhdd" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "IP's: $svip" >> /root/runbook/rb_informacoes_do_servidor.txt
	echo "{expand}" >> /root/runbook/rb_informacoes_do_servidor.txt
	mv /root/runbook/rb_informacoes_do_servidor.txt /root/runbook/01.rb_informacoes_do_servidor.txt
	
	echo -e "Coletado informações do servidor"
	}
	
	rb_iptables_ou_firewall(){
	
	if [ -s /etc/init.d/firewall ] ; then
	# POSICAO DO ARQUIVO
	num='02'
	# TITULO DO SERVIÇO
	servico='/etc/init.d/firewall'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_firewall.txt'
	
	# INFORACOES ESTÁTICAS
	ajuste_kb
	
	elif [ -s /etc/sysconfig/iptables ] ; then
	# POSICAO DO ARQUIVO
	num='02'
	# TITULO DO SERVIÇO
	servico='/etc/sysconfig/iptables'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_iptables.txt'
	
	# INFORACOES ESTÁTICAS
	ajuste_kb
	
	elif [ -s /etc/iptables.up.rules ] ; then
	# POSICAO DO ARQUIVO
	num='02'
	# TITULO DO SERVIÇO
	servico='/etc/iptables.up.rules'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_iptables.up.rules.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	
	# INFORACOES ESTÁTICAS
	ajuste_kb
	
	else
	echo "FUDEO... N TEM FW NEM IPTABLES CONFIGURADO"
	
	fi
	}
	
	rb_netstat_tlpn(){
	# POSICAO DO ARQUIVO
	num='03'
	# TITULO DO SERVIÇO
	servico='netstat -ntpl'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_netstat_tlpn.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	$servico > /root/runbook/informacoes_tmp
	
	# INFORACOES ESTÁTICAS
	ajuste_kb_2
	}
	
	rb_portas_liberadas(){
	# POSICAO DO ARQUIVO
	num='04'
	# TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
	servico='iptables -nL'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_portas_liberadas.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	$servico > /root/runbook/informacoes_tmp
	# INFORACOES ESTÁTICAS
	ajuste_kb_2
	}
	
	rb_regras_nat(){
	# POSICAO DO ARQUIVO
	num='03'
	# TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
	servico='iptables -nL -t nat'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_regras_nat.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	$servico  > /root/runbook/informacoes_tmp
	# INFORACOES ESTÁTICAS
	ajuste_kb_2
	}
	
	rb_chkconfig(){
	# POSICAO DO ARQUIVO
	num='04'
	# TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
	servico='chkconfig'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_chkconfig.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	chkconfig --list | grep 3:on > /root/runbook/informacoes_tmp
	# INFORACOES ESTÁTICAS
	ajuste_kb_2
	}
	
	rb_discos(){
	# POSICAO DO ARQUIVO
	num='07'
	# TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
	servico='df -h'
	# NOME FINAL DO ARQUIVO DESTINO
	arquivo_destino='rb_utilizacao_de_disco.txt'
	$servico > /root/runbook/informacoes_tmp
	# INFORACOES ESTATICAS
	ajuste_kb_2
	}
	
	rb_fstab(){
	# POSICAO DO ARQUIVO
	num='06'
	# TITULO DO SERVIÇO
	servico='/etc/fstab'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_fstab.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

rb_inicio
rb_criando_runbook
rb_informacoes_do_servidor
rb_iptables_ou_firewall
rb_netstat_tlpn
rb_portas_liberadas
rb_regras_nat
rb_chkconfig
rb_discos
rb_fstab	
}

rb_ldirectord(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='08'
# TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
servico='/etc/ha.d/ldirectord.cf'
# NOME FINAL DO ARQUIVO DESTINO
arquivo_destino='rb_ldirectord.txt'
# INFORACOES ESTATICAS
ajuste_kb
}

rb_ipsec(){
# PARA UM ARQUIVO
# PARA DIRETORIO

	rb_ipsec_conf(){
	# POSICAO DO ARQUIVO
	num='09'
	# TITULO DO SERVIÇO
	servico='/etc/ipsec.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_ipsec.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_ipsec_conn_secrets(){
	# POSICAO DO ARQUIVO
	num='09'
	# TITULO DO SERVIÇO
	ls /etc/ipsec.d/ | grep vpn | while read a; do cat /etc/ipsec.d/$a; done >> /root/conn_secrets_tmp
	servico='/root/conn_secrets_tmp'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_ipsec_conn.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	rm -f /root/conn_secrets_tmp
	}
	
#	rb_ipsec_secrets(){
#	# POSICAO DO ARQUIVO
#	num='09'
#	# TITULO DO SERVIÇO
#	servico='cat /etc/vpn-*.secrets'
#	# NOME FINAL DO ARQUIVO
#	arquivo_destino='rb_ipsec_secrets.txt'
#	# INFORACOES ESTÁTICAS
#	ajuste_kb
#	}
	
#	rb_ipsec_vpns(){
#	# POSICAO DO ARQUIVO
#	num='09'
#	# TITULO DO SERVIÇO
#	servico='/etc/ipsec.d'
#	# NOME FINAL DO ARQUIVO
#	arquivo_destino='rb_ipsec.d.tar.gz'
#	# INFORACOES ESTÁTICAS
#	ajuste_kb_3
#	}

rb_ipsec_conf
rb_ipsec_conn_secrets
#rb_ipsec_secrets
#rb_ipsec_vpns
}

rb_logrotate(){
# PARA UM ARQUIVO
# PARA DIRETORIO
	
	rb_logrotate_conf(){
	# POSICAO DO ARQUIVO
	num='10'
	# TITULO DO SERVIÇO
	servico='/etc/logrotate.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_logrotate.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	ls /etc/ipsec.d/ | grep vpn | while read a; do cat /etc/ipsec.d/$a; done >> /root/conn_secrets_tmp
	
	
	rb_logrotate_servicos(){
	# POSICAO DO ARQUIVO
	num='10'
	# TITULO DO SERVIÇO
	ls /etc/logrotate.d | while read a; do cat /etc/logrotate.d/$a; done >> /root/logrotate_tmp
	servico='/root/logrotate_tmp'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_logrotate.d.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	rm -f /root/logrotate_tmp
	}
	
rb_logrotate_conf
rb_logrotate_servicos
}

rb_heartbeat(){
# PARA VÁRIOS ARQUIVOS

	rb_ha_cf(){
	# POSICAO DO ARQUIVO
	num='10'
	# TITULO DO SERVIÇO
	servico='/etc/ha.d/ha.cf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_ha.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_haresources(){
	# POSICAO DO ARQUIVO
	num='10'
	# TITULO DO SERVIÇO
	servico='/etc/ha.d/haresources'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_haresources.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

rb_ha_cf
rb_haresources
}

rb_drbd(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='11'
# TITULO DO SERVIÇO
servico='/etc/drbd.conf'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_drbd.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_rsyslog(){
# PARA VÁRIOS ARQUIVOS

	rb_rsyslog_conf(){
	# POSICAO DO ARQUIVO
	num='12'
	# TITULO DO SERVIÇO
	servico='/etc/rsyslog.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_rsyslog.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_rsyslog_50_default(){
	# POSICAO DO ARQUIVO
	num='12'
	# TITULO DO SERVIÇO
	servico='/etc/rsyslog.d/50-default.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_50-default.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_rsyslog_20_default(){
	# POSICAO DO ARQUIVO
	num='12'
	# TITULO DO SERVIÇO
	servico='/etc/rsyslog.d/20-ufw.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_20-ufw.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

# CentOs/RHEL
if [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	echo -e "\\033[1;39m \\033[1;32mDistro CentOs\\033[1;39m \\033[1;0m"

	rb_rsyslog_conf
	
	# Debian/Ubuntu
	elif [ ! -x /bin/systemctl -a -r /lib/lsb/init-functions ]; then
	echo -e "\\033[1;39m \\033[1;33mDistro Ubuntu\\033[1;39m \\033[1;0m"

	rb_rsyslog_conf
	rb_rsyslog_50_default
	rb_rsyslog_20_default
	
	# OUTROS
	# elif [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	#
	## Comando
	#
	
	else
	echo -e "\\033[1;39m \\033[1;33mDistro não identificada\\033[1;39m \\033[1;0m"
	
	fi
}

rb_mongodb(){
# PARA VÁRIOS ARQUIVOS
	rb_mongodb_conf(){
	# POSICAO DO ARQUIVO
	num='13'
	# TITULO DO SERVIÇO
	servico='/etc/mongod.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_mongod.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_mongodb_versao(){
	if [ -s /etc/mongod.conf ] ; then
	# POSICAO DO ARQUIVO
	num='13'
	# TITULO DO SERVIÇO
	servico='/etc/mongod.conf'
	#servico='mongod'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_mongod_versao.txt'
	# COMANDO PARA CAPTURAR ARQUIVO
	#cat $servico > /root/runbook/informacoes_tmp
	mongo --version > /root/runbook/informacoes_tmp
	# INFORACOES ESTÁTICAS
	ajuste_kb
	
	else
	nao_existe
	fi
	sleep 1
	}
	
rb_mongodb_conf
rb_mongodb_versao
}

rb_mysql(){
# MESMO SERVIÇO EM OUTROS POSSÍVEIS LOCAIS ( EX.: /etc/my.cnf ou /etc/mysql/my.cnf )
# PARA VÁRIOS ARQUIVOS

	rb_my_cnf(){
	############
	## CENTOS ##
	############
	
	# POSICAO DO ARQUIVO
	num='14'
	# TITULO DO SERVIÇO
	servico='/etc/my.cnf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_my.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

	rb_mysql_my_cnf(){
	############
	## UBUNTU ##
	############
	
	# POSICAO DO ARQUIVO
	num='14'
	# TITULO DO SERVIÇO
	servico='/etc/mysql/my.cnf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_my.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_sbin_usr_my(){
	# POSICAO DO ARQUIVO
	num='14'
	# TITULO DO SERVIÇO
	servico='/etc/apparmor.d/usr.sbin.mysqld'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_usr.sbin.mysqld.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

# CentOs/RHEL/Fedora
if [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	echo -e "\\033[1;39m \\033[1;32mDistro CentOs\\033[1;39m \\033[1;0m"

	rb_my_cnf
	
	# Debian/Ubuntu
	elif [ ! -x /bin/systemctl -a -r /lib/lsb/init-functions ]; then
	echo -e "\\033[1;39m \\033[1;33mDistro Ubuntu\\033[1;39m \\033[1;0m"

	rb_my_cnf
	ajuste_kb
	
	# OUTROS
	# elif [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	#
	## Comando
	#
	
	else
	echo -e "\\033[1;39m \\033[1;33mDistro não identificada\\033[1;39m \\033[1;0m"
	
	fi
}

rb_apache(){

	rb_httpd_conf(){
	############
	## CENTOS ##
	############
	
	# POSICAO DO ARQUIVO
	num='15'
	# TITULO DO SERVIÇO
	servico='/etc/httpd/conf/httpd.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_httpd.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_apache_conf(){
	############
	## UBUNTU ##
	############
	
	# POSICAO DO ARQUIVO
	num='15'
	# TITULO DO SERVIÇO
	servico='/etc/apache2/apache2.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_apache2.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}

# CentOs/RHEL
if [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	echo -e "\\033[1;39m \\033[1;32mDistro CentOs\\033[1;39m \\033[1;0m"

	rb_httpd_conf
	
	# Debian/Ubuntu
	elif [ ! -x /bin/systemctl -a -r /lib/lsb/init-functions ]; then
	echo -e "\\033[1;39m \\033[1;33mDistro Ubuntu\\033[1;39m \\033[1;0m"

	rb_apache_conf
	
	# OUTROS
	# elif [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
	#
	## Comando
	#
	
	else
	echo -e "\\033[1;39m \\033[1;33mDistro não identificada\\033[1;39m \\033[1;0m"
	
	fi
}

rb_php(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='16'
# TITULO DO SERVIÇO
servico='/etc/php.ini'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_php_ini.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_vsftp(){
# PARA VÁRIOS ARQUIVOS

	rb_vsftp_conf(){
	# POSICAO DO ARQUIVO
	num='17'
	# TITULO DO SERVIÇO
	servico='/etc/vsftpd/vsftpd.conf'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_vsftpd.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
	rb_vsftp_chtoot(){
	# POSICAO DO ARQUIVO
	num='17'
	# TITULO DO SERVIÇO
	servico='/etc/vsftpd.chroot_list'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_vsftpd.chroot_list.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb
	}
	
rb_vsftp_conf
rb_vsftp_chtoot
}

rb_proftpd(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='18'
# TITULO DO SERVIÇO
servico='/etc/proftpd.conf'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_proftpd.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_fail2ban(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='19'
# TITULO DO SERVIÇO
servico='/etc/fail2ban/jail.conf'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_fail2ban.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_nfs(){
# PARA VÁRIOS ARQUIVOS

	sys_nfs(){
	if [ -s /etc/sysconfig/nfs ] ; then
	# POSICAO DO ARQUIVO
	num='20'
	# TITULO DO SERVIÇO
	servico='/etc/sysconfig/nfs'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_sys_nfs.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb

	else
	nao_existe
	fi
	}
	
	exports (){
	if [ -s /etc/exports ] ; then
	# POSICAO DO ARQUIVO
	num='20'
	# TITULO DO SERVIÇO
	servico='/etc/exports'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_exports.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb

	else
	nao_existe
	fi
	}

	hosts_deny (){
	if [ -s /etc/hosts.deny ] ; then
	# POSICAO DO ARQUIVO
	num='20'
	# TITULO DO SERVIÇO
	servico='/etc/hosts.deny'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_hosts_deny.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb

	else
	nao_existe
	fi
	}

	hosts_allow (){
	if [ -s /etc/hosts.allow ] ; then
	# POSICAO DO ARQUIVO
	num='20'
	# TITULO DO SERVIÇO
	servico='/etc/hosts.allow'
	# NOME FINAL DO ARQUIVO
	arquivo_destino='rb_hosts_allow.txt'
	# INFORACOES ESTÁTICAS
	ajuste_kb

	else
	nao_existe
	fi

}

sys_nfs
exports
hosts_deny
hosts_allow

sleep 1

}

rb_haproxy(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='08'
# TITULO DO SERVIÇO
servico='/etc/haproxy/haproxy.cfg'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_haproxy.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_zabbix_agentd(){
# PARA UM ARQUIVO
# POSICAO DO ARQUIVO
num='20'
# TITULO DO SERVIÇO
servico='/etc/zabbix/zabbix_agentd.conf'
# NOME FINAL DO ARQUIVO
arquivo_destino='rb_zabbix_agentd.txt'
# INFORACOES ESTÁTICAS
ajuste_kb
}

rb_conclusao(){
echo ""
echo -e "\\033[1;39m \\033[1;32mRunBook Alimentado\\033[1;39m \\033[1;0m"
echo ""

# Inserindo formatação no arquivo para importação no confluence KB
echo "h2. $HOSTNAME" >> /root/runbook/runbook
echo "" >> /root/runbook/runbook
cat /root/runbook/*.txt >> /root/runbook/runbook

sleep 1

#tar -zcf /root/runbook.tar.gz /root/runbook

#apt-get install sshpass
#sshpass -p "6K%kdhES" scp /root/runbook.tar.gz 10.0.7.2:/root/runbook.tar.gz

sleep 1
}



# CHAMANDO AS FUNÇÕES

rb_default
rb_ldirectord
rb_ipsec
rb_logrotate
rb_heartbeat
rb_drbd
rb_rsyslog
rb_mongodb
rb_mysql
rb_apache
rb_php
rb_vsftp
rb_proftpd
rb_fail2ban
rb_nfs
rb_zabbix_agentd
rb_haproxy
rb_conclusao


## EXEMPLOS DE FUNÇÕES ##

## PARA UM ARQUIVO ##
##
## EXEMPLO
##
## rb_fail2ban(){
## # PARA UM ARQUIVO
## # POSICAO DO ARQUIVO
## num='19'
## # TITULO DO SERVIÇO
## servico='/etc/fail2ban/jail.conf'
## # NOME FINAL DO ARQUIVO
## arquivo_destino='rb_jail.txt'
## # INFORACOES ESTÁTICAS
## ajuste_kb
## }

## PARA DIRETORIO ##
##
## EXEMPLO
##
## rb_logrotate_servicos(){
## # POSICAO DO ARQUIVO
## num='10'
## # TITULO DO SERVIÇO
## servico='/etc/logrotate.d/'
## # NOME FINAL DO ARQUIVO
## arquivo_destino='rb_logrotate.d.tar.gz'
## # INFORACOES ESTÁTICAS
## ajuste_kb_3
## }

## PARA UM SERVIÇO ##
##
## EXEMPLO
##
## rb_discos(){
## # POSICAO DO ARQUIVO
## num='07'
## # TITULO DO SERVIÇO - ARQUIVO / COMANDO PARA CAPTURAR O RESULTADO DESEJADO
## servico='df -h'
## # NOME FINAL DO ARQUIVO DESTINO
## arquivo_destino='rb_fstab.txt'
## $servico > /root/runbook/informacoes_tmp
## # INFORACOES ESTATICAS
## ajuste_kb_2
## }

## PARA VÁRIOS ARQUIVOS ##
##
## EXEMPLO
##
## rb_nfs(){
## # PARA VÁRIOS ARQUIVOS
## 
## 		sys_nfs(){
## 		if [ -s /etc/sysconfig/nfs ] ; then
## 		# POSICAO DO ARQUIVO
## 		num='19'
## 		# TITULO DO SERVIÇO
## 		servico='/etc/sysconfig/nfs'
## 		# NOME FINAL DO ARQUIVO
## 		arquivo_destino='rb_sys_nfs.txt'
## 		# INFORACOES ESTÁTICAS
## 		ajuste_kb
## 	
## 		else
## 		nao_existe
## 		fi
## 		}
## 		
## 		exports (){
## 		if [ -s /etc/exports ] ; then
## 		# POSICAO DO ARQUIVO
## 		num='19'
## 		# TITULO DO SERVIÇO
## 		servico='/etc/exports'
## 		# NOME FINAL DO ARQUIVO
## 		arquivo_destino='rb_exports.txt'
## 		# INFORACOES ESTÁTICAS
## 		ajuste_kb
## 	
## 		else
## 		nao_existe
## 		fi
## 		}
## 	
## 		hosts_deny (){
## 		if [ -s /etc/hosts.deny ] ; then
## 		# POSICAO DO ARQUIVO
## 		num='19'
## 		# TITULO DO SERVIÇO
## 		servico='/etc/hosts.deny'
## 		# NOME FINAL DO ARQUIVO
## 		arquivo_destino='rb_hosts_deny.txt'
## 		# INFORACOES ESTÁTICAS
## 		ajuste_kb
## 	
## 		else
## 		nao_existe
## 		fi
## 		}
## 	
## 		hosts_allow (){
## 		if [ -s /etc/hosts.allow ] ; then
## 		# POSICAO DO ARQUIVO
## 		num='19'
## 		# TITULO DO SERVIÇO
## 		servico='/etc/hosts.allow'
## 		# NOME FINAL DO ARQUIVO
## 		arquivo_destino='rb_hosts_allow.txt'
## 		# INFORACOES ESTÁTICAS
## 		ajuste_kb
## 	
## 		else
## 		nao_existe
## 		fi
## 
## 		}
## 
## sys_nfs
## exports
## hosts_deny
## hosts_allow
## 
## sleep 1
## 
## }

## IDENTIFICANDO DISTRO PARA COLETA DO ARQUIVO ##
##  
##
## EXEMPLO
##
## # CentOs/RHEL
## if [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
##	echo -e "\\033[1;39m \\033[1;32mDistro CentOs\\033[1;39m \\033[1;0m"
##
##	rb_httpd_conf
##	
##	# Debian/Ubuntu
##	elif [ ! -x /bin/systemctl -a -r /lib/lsb/init-functions ]; then
##	echo -e "\\033[1;39m \\033[1;33mDistro Ubuntu\\033[1;39m \\033[1;0m"
##
##	rb_apache_conf
##	
##	# OUTROS
##	# elif [ ! -x /bin/systemctl -a -r /etc/init.d/functions ]; then
##	#
##	## Comando
##	#
##	
##	else
##	echo -e "\\033[1;39m \\033[1;33mDistro não identificada\\033[1;39m \\033[1;0m"
##	
##	fi

## SERVIÇO COM ARQUIVOS EM OUTROS POSSÍVEIS LOCAIS ( EX.: /etc/my.cnf ou /etc/mysql/my.cnf )   ##
##
## EXEMPLO
##
## rb_apache(){
## # MESMO SERVIÇO EM OUTROS POSSÍVEIS LOCAIS ( EX.: /etc/my.cnf ou /etc/mysql/my.cnf )
## if [ -s /etc/httpd/conf/httpd.conf ] ; then
## ############
## ## CENTOS ##
## ############
## 
## # POSICAO DO ARQUIVO
## num='15'
## # TITULO DO SERVIÇO
## servico='/etc/httpd/conf/httpd.conf'
## # NOME FINAL DO ARQUIVO
## arquivo_destino='rb_httpd.txt'
## # INFORACOES ESTÁTICAS
## ajuste_kb
## 
## elif [ -s /etc/apache2/apache2.conf ] ; then
## ############
## ## UBUNTU ##
## ############
## 
## # POSICAO DO ARQUIVO
## num='15'
## # TITULO DO SERVIÇO
## servico='/etc/apache2/apache2.conf'
## # NOME FINAL DO ARQUIVO
## arquivo_destino='rb_apache2.txt'
## # INFORACOES ESTÁTICAS
## ajuste_kb
## 
## else
## nao_existe
## fi
## }