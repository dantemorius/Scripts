#!/bin/bash

######################################
### Install SQL SERVER for Linux #####
######################################
#####   Only for CentOS/RHEL 7  ######
######################################
####### Created by Tiago Silva #######
############ Version 1.0 #############
######################################

echo '
##################################################################################
###.___                 __         .__  .__      _________________  .____      ###
###|   | ____   _______/  |______  |  | |  |    /   _____/\_____  \ |    |     ###
###|   |/    \ /  ___/\   __\__  \ |  | |  |    \_____  \  /  / \  \|    |     ###
###|   |   |  \\___ \  |  |  / __ \|  |_|  |__  /        \/   \_/.  \    |___  ###
###|___|___|  /____  > |__| (____  /____/____/ /_______  /\_____\ \_/_______ \ ###
###         \/     \/            \/                    \/        \__>       \/ ###
###  __________________________________   _________________________            ###
### /   _____/\_   _____/\______   \   \ /   /\_   _____/\______   \           ###
### \_____  \  |    __)_  |       _/\   Y   /  |    __)_  |       _/           ###
### /        \ |        \ |    |   \ \     /   |        \ |    |   \           ###
###/_______  //_______  / |____|_  /  \___/   /_______  / |____|_  /           ###
###        \/         \/         \/                   \/         \/            ###
###  _____              .____    .__                                           ###
###_/ ____\___________  |    |   |__| ____  __ _____  ___                      ###
###\   __\/  _ \_  __ \ |    |   |  |/    \|  |  \  \/  /                      ###
### |  | (  <_> )  | \/ |    |___|  |   |  \  |  />    <                       ###
### |__|  \____/|__|    |_______ \__|___|  /____//__/\_ \                      ###
###                             \/       \/            \/                      ###
##################################################################################
							 '

###Procedimento de instalação e configuração do SQL Server em Plataforma Windows####
{

#Download do repositório para Red Hat 7
curl https://packages.microsoft.com/config/rhel/7/mssql-server.repo > /etc/yum.repos.d/mssql-server.repo

##Instalação do serviço
yum install -y mssql-server

##Configuração do serviço
/opt/mssql/bin/mssql-conf setup

##Verificação de status
systemctl status mssql-server

#Inclusão de regras de liberação no Firewall
echo "Digite a porta padrão:"
read sql_port
export sql_port

firewall-cmd --zone=public --add-port=$sql_port/tcp --permanent
firewall-cmd --reload

###Instalação do MSSQL-TOOLS
##Repositório
curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/msprod.repo

##Instalação
yum install mssql-tools unixODBC-devel

##Exportar variáveis de ambiente para uso do Shell do serviço via login
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile

##Exportar variável para uso do Shell do serviço via modo interativo/non login
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

echo "Variáveis de ambiente criadas"
}



##Configurações do serviço
{
##Alterar porta padrão
/opt/mssql/bin/mssql-conf set tcpport $sql_port
systemctl restart mssql-server
##Teste com nova porta
sqlcmd -S localhost,$sql_port -U test -P test

##Alterando /data
mkdir /tmp/data

chown mssql:mssql /tmp/data

/opt/mssql/bin/mssql-conf set defaultdatadir /tmp/data

systemctl restart mssql-server

##Alterando pasta de logs
mkdir /tmp/log

chown mssql:mssql /tmp/log
/opt/mssql/bin/mssql-conf set defaultlogdir /tmp/log

##Alterando pasta de dumps
mkdir /tmp/dump
chown mssql:mssql /tmp/dump
/opt/mssql/bin/mssql-conf set defaultdumpdir /tmp/dump

##Alterando pasta de backups
mkdir /tmp/backup
chown mssql:mssql /tmp/backup
/opt/mssql/bin/mssql-conf set defaultbackupdir /tmp/

##Alterando Collation
/opt/mssql/bin/mssql-conf set-collation "Collation"
}


###Conexão e manipulação de bases
{
sqlcmd -S localhost -U SA -P '<YourPassword>'

ou

#(Para casos em que há caracteres especiais na senha que não são aceitos sem escape pelo Shell)
sqlcmd -S localhost -U SA
Password:

##Queries
##Mostrar databases:
SELECT Name from sys.Databases;
GO

##Criar Databases
CREATE DATABASE testdb;
GO

##Selecionar data base
USE testdb;
GO

##Create Table
CREATE TABLE inventory (id INT, name NVARCHAR(50), quantity INT);
GO

##Insert data
INSERT INTO inventory VALUES (1, 'banana', 150);
INSERT INTO inventory VALUES (2, 'orange', 154);
GO

##SELECT
SELECT * FROM inventory WHERE quantity > 152;
GO
}