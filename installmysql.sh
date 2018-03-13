#!/bin/bash

###########################
##   INSTALAÇÃO MYSQL    ##
## Data:  09/10/2015     ##
## Atualização:17/05/2017##
## Autor: Amauri Hideki  ##
## Colab: Tiago Silva    ##
###########################


pacotes_mysql(){

# MySql 5.x
wget https://dev.mysql.com/get/mysql57-community-release-el6-11.noarch.rpm && rpm -ivh mysql57-community-release-el6-11.noarch.rpm

sed '27s/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community-source.repo
# sed '4,11s/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community-source.repo

echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorio MySQL instalado.\\033[1;39m \\033[1;0m"
echo ""
sleep 1
}

instalando_versao_do_mysql(){
echo -e "\\033[1;39m \\033[1;32mSELECIONE VERSAO DO MYSQL QUE DESEJA INSTALAR:\\033[1;39m \\033[1;0m"
echo ""
echo "1. MySql 5.5"
echo "2. MySql 5.6"
echo "3. MySql 5.7"
echo ""
echo ""
read OPCAO

case $OPCAO in
	1)
#	mysql55
	sed -i '18s/enabled=0/enabled=1/g' /etc/yum.repos.d/mysql-community-source.repo && yum -y install mysql mysql-server mysql-devel && clear ;;
	2)
#	mysql56
	sed -i '25s/enabled=0/enabled=1/g' /etc/yum.repos.d/mysql-community-source.repo && yum -y install mysql mysql-server mysql-devel && clear ;;
	3)
#	mysql57
	sed -i '32s/enabled=0/enabled=1/g' /etc/yum.repos.d/mysql-community-source.repo && yum -y install mysql mysql-server mysql-devel && clear ;;
	*)
	instalando_versao_do_mysql
	;;
	esac
}	

ajustando_mysql_tmp(){

echo ""
echo -e "\\033[1;39m \\033[1;32mCriando MySQL TMP.\\033[1;39m \\033[1;0m"
echo ""

mkdir -p /mnt/mytmp
sleep 1
echo "tmpfs                  /mnt/mytmp              tmpfs   size=2G         0 0" >> /etc/fstab
sleep 3
mount -a
sleep 1
mkdir -p /var/log/mysql/
chown mysql:mysql /var/log/mysql/
mkdir -p  /var/log/mysql-bin
chown mysql:mysql /var/log/mysql-bin/
chown mysql:mysql /mnt/mytmp

echo ""
echo -e "\\033[1;39m \\033[1;32mMySQL TMP Criado e ajustado as permissões.\\033[1;39m \\033[1;0m"
echo ""
sleep 1
}

ajustando_mysql_conf(){

echo ""
echo -e "\\033[1;39m \\033[1;32mAjustando o MY.CNF.\\033[1;39m \\033[1;0m"
echo ""

rm -rf /etc/my.cnf
    cat > "/etc/my.cnf" <<END
[mysqld]
datadir=diretoriosubistituir
socket=/var/lib/mysql/mysql.sock
tmpdir=/mnt/mytmp
user=mysql
symbolic-links=0
log-error=/var/log/mysql/mysqld.log
skip-external-locking

### CONFIG RECOVERY and BIN-LOG ###
myisam-recover = BACKUP
server-id = 1
log_bin = /var/log/mysql-bin/mysql-bin.log
expire_logs_days = 3
max_binlog_size = 100M
innodb_flush_log_at_trx_commit=1
sync_binlog=1

### TUNING  ###
local-infile
low-priority-updates
symbolic-links

# Log's
#general_log_file = /var/log/mysql/mysql.log
#general_log = 1
log-error=/var/log/mysql/error.log
#slow-query-log=/var/log/mysql/slowquery.log
#log_slow_queries=/var/log/mysql/slowquery.log
long_query_time=5


# Conections
connect_timeout=10
max_connections=500
max_user_connections=100
max_connect_errors=20

max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8K
myisam_sort_buffer_size=2M
join_buffer_size=4M
sort_buffer_size=1M
#table_cache=256
wait_timeout=30
tmp_table_size=1M
query_cache_size=1M
query_cache_limit=1M
key_buffer_size=1M
read_buffer_size = 1M
read_rnd_buffer_size = 1M


[safe_mysqld]
open_files_limit=32000

[mysqldump]
socket=/var/lib/mysql/mysql.sock
max_allowed_packet=64M
add-drop-table
extended-insert
quick

[mysql]
socket=/var/lib/mysql/mysql.sock
disable-auto-rehash
connect_timeout=15
local-infile
quick

[isamchk]
key_buffer = 16M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer = 16M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M


[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
END

echo ""
echo -e "\\033[1;39m \\033[1;32mAjustado o MY.CNF.\\033[1;39m \\033[1;0m"
echo ""

}

ajustando_mysql_datadir(){
# VARIAVEIS

echo ""
echo -e "\\033[1;39m \\033[1;32mInforme o DATADIR do MySQL: ( Ex.: /data/mysql )\\033[1;39m \\033[1;0m"
echo ""

read novodiretorio
export novodiretorio

echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurando o DATADIR.\\033[1;39m \\033[1;0m"
echo ""

# Ajustando datadir do /etc/my.cnf
echo $novodiretorio | sed -e 's/\//\\\\\//g' | while read a ; do sed -i '2s/diretoriosubistituir/'"$a"'/' /etc/my.cnf ; done

sleep 1

# Verificando se a pasta existe e ajustando permissões
if [ -e "$novodiretorio" ] ; then
echo "o diretório $novodiretorio existe"
else
echo "Criando $novodiretorio"
mkdir $novodiretorio
fi

chmod 775 $novodiretorio && chown -R mysql:mysql $novodiretorio

cp -rpai /var/lib/mysql/* $novodiretorio

echo ""
echo -e "\\033[1;39m \\033[1;32mConfigurado DATADIR.\\033[1;39m \\033[1;0m"
echo ""

sleep 1
}

ajustando_usuario_mysql(){

echo ""
echo -e "\\033[1;39m \\033[1;32mCriando usuário ROOT do MySQL\\033[1;39m \\033[1;0m"
echo ""

sleep 1

# CONFIG SELINUX
setenforce 0
sed -i 's/=permissive/=disabled/' /etc/sysconfig/selinux
sed -i 's/=permissive/=disabled/' /etc/selinux/config

# Iniciando banco de dados
service mysqld start

DATABASE_PASS=`cat /dev/urandom| tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='| head -c 10`

mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

echo "
[client]
user=root
password='$DATABASE_PASS'
" > /root/.my.cnf

echo ""
echo -e "\\033[1;39m \\033[1;32m Senha do usuário ROOT MySQL adicionado ao /root/.my.cnf \\033[1;39m \\033[1;0m"
echo ""

echo ""
echo -e "\\033[1;39m \\033[1;32mUsuário ROOT do MySQL criado\\033[1;39m \\033[1;0m"
echo ""

}

criando_script_bkp (){

echo 'bkpdir='$novodiretorio'/backup
mysqldump=`which mysqldump`
mysql=`which mysql`
data=`date +"%Y%m%d"`

mkdir -p $bkpdir
 
### Script Backup ###
for dbase in `$mysql -N -e "show databases" -ss | grep -v "performance_schema\|information_schema"`
do
if [ ! -d "$bkpdir/$dbase" ]; then
mkdir -p $bkpdir/$dbase
fi
echo "Backup: $dbase"
$mysqldump $dbase --single-transaction --quick | bzip2 > $bkpdir/$dbase/$dbase.$data.bz2
done;

find $bkpdir -ctime +7 -type f -name \*.bz2 -exec rm -f {} \;' > /root/bkp_mysql.sh

chmod +x /root/bkp_mysql.sh

##Ajustando Cron para agendamento da tarefa:

crontab -l | { cat; echo "0 2 * * * /bin/sh /root/bkp_mysql.sh"; } | crontab -
}

aplicando_ajustes(){

service mysql restart
chkconfig mysqld on

}

clear

pacotes_mysql
instalando_versao_do_mysql
ajustando_mysql_tmp
ajustando_mysql_conf
ajustando_mysql_datadir
ajustando_usuario_mysql
criando_script_bkp
aplicando_ajustes

