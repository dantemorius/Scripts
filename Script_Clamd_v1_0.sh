#!/bin/bash
	#####################################
	##  INSTALAÇÃO ClamAv - Relatórios ##
	##        Data:  24/11/2015        ##
	##       Autor: Tiago Silva        ##
	#####################################

instalacao_clamav() {
	yum install -y clamd* clamav* --exclude=clamav-milter*
	
	sleep 5
}

configuracao_clamav() {
#Criando copia de segurança dos arquivos de configuração:
	cp /etc/freshclam.conf /etc/freshclam.conf_original
	cp /etc/clamd.conf /etc/clamd.conf_original

################################
####Configurando o FreshClam####
################################

#Criando os arquivos de Logs e setando as permissões:
	touch /var/log/freshclam.log
	chmod 755 /var/log/freshclam.log
	useradd clamav
	usermod clamav -a -G clamav
	chown clamav:clamav /var/log/freshclam.log

	##Descomentando as linhas principais do arquivo original de exemplo:
	sed -i 's/#PidFile/PidFile/g' /etc/freshclam.conf
	sed -i 's/#DatabaseDirectory/DatabaseDirectory/g' /etc/freshclam.conf
	sed -i 's/#DNSDatabaseInfo/DNSDatabaseInfo/g' /etc/freshclam.conf
	sed -i 's/#UpdateLogFile/UpdateLogFile/g' /etc/freshclam.conf
	sed -i 's/#PidFile/PidFile/g' /etc/freshclam.conf

#Remover tags de exemplo:
	sed -i 's/Example//g' /etc/freshclam.conf
	sed -i 's/Example//g' /etc/clamd.conf


#Alterar tempo de checagem de 24 vezes por dia para 1 vez:
	sed -i 's/Checks 24/Checks 1/g' /etc/freshclam.conf

################################
####Configurando o Clamd########
################################

	##Descomentando as linhas necessárias:
	sed -i 's/#PidFile/PidFile/g' /etc/clamd.conf
	sed -i 's/#DatabaseDirectory/DatabaseDirectory/g' /etc/clamd.conf
	sed -i 's/\/var\/lib\/clamav/\/var\/clamav/g' /etc/clamd.conf
	sed -i 's/#DNSDatabaseInfo/DNSDatabaseInfo/g' /etc/clamd.conf
	sed -i 's/#UpdateLogFile/UpdateLogFile/g' /etc/clamd.conf
	sed -i 's/#PidFile/PidFile/g' /etc/clamd.conf
	sed -i 's/#LocalSocket/LocalSocket/g' /etc/clamd.conf
}
teste_clamav() {
################################
#######Testando o Clamav########
################################
	echo 'Digite o diretório desejado para realizar o escaneamento'
	read DIR
	if [ -e $DIR ]; then
	echo "Diretório $DIR já existe"
	sleep 1
	echo "Acessando diretório $DIR"
	cd $DIR;
	wget http://www.eicar.org/download/eicar.com;
	freshclam;
	clamscan -ri $DIR;
	rm -rf $DIR/eicar.com*;
	
	else
	read DIR
	echo "Diretório $DIR não existe"
	sleep 1
	echo "Criando diretório $DIR"
	mkdir -p $DIR
	cd $DIR;
	wget http://www.eicar.org/download/eicar.com;
	freshclam;
	clamscan -ri $DIR;
	rm -rf $DIR/eicar.com*;
	fi
}

sleep 5

crontab_clamscan(){

#Incluindo tarefa no cron para gerar relatório diário de varredura.O Script contempla também um jobrotate, mantendo somente os relatórios dos últimos 7 dias.
	crontab -l > /var/crons
	mkdir -p /var/crontab/relatorios/
	cd /var/crontab/relatorios/
	echo '
	#!/bin/bash
	freshclam;
	clanscam -ri / >> scan-`/bin/date +%d-%m-%Y`.txt;
	find /var/crontab/relatorios/ -type f -mtime +6 --exec rm -rf{} +;
	' >> /var/crontab/relatorio_crontab.sh;
	echo "* 01 * * * sh /var/crontab/relatorio_crontab.sh" >> /var/crons;
	crontab /var/crons;

	
	sleep 2
}
instalacao_clamav
configuracao_clamav
teste_clamav
crontab_clamscan