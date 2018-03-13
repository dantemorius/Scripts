#!/bin/bash

#########################
#    SCRIPT SETUP       #
#  MySQL REPLICATION    #
#     MASTER/SLAVE      #
#                       #
# Autor: Leonardo Alves #
# Data:   03/04/2015    #
#########################

clear
echo ""
echo " ##########################################"
echo " #  SETUP MYSQL REPLICATION MASTER/SLAVE  #"
echo " ##########################################"
echo ""
echo ""

# DEFININDO VARIAVEIS

echo -n " Informe o IP do MySQL 01: "
read MYSQL01
export MYSQL01

echo -n " Informe o IP do MySQL 02: "
read MYSQL02
export MYSQL02

echo -n " Informe o HOSTNAME do MySQL 01: "
read NOME1
export NOME1

echo -n " Informe o HOSTNAME do MySQL 02: "
read NOME2
export NOME2

echo "" >> /etc/hosts
echo "$MYSQL01  $NOME1" >> /etc/hosts
echo "$MYSQL02  $NOME2" >> /etc/hosts

scp /etc/hosts root@$MYSQL02:/etc/


preparacaoSO(){

# INSTALACAO REPOSITORIO EPEL
rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force
ssh root@$MYSQL02 "rpm -ivh ftp://ftpcloud.mandic.com.br/Instaladores/RPM/epel-release-6-8.noarch.rpm --force"
echo ""
echo -e "\\033[1;39m \\033[1;32mRepositorio EPEL Instalado.\\033[1;39m \\033[1;0m"
echo ""

# UPDATE
yum update -y
ssh root@$MYSQL02 "yum update -y"
echo ""
echo -e "\\033[1;39m \\033[1;32mUpdate realizado.\\033[1;39m \\033[1;0m"
echo ""

# INSTALACAO DE PACOTES
yum install openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet sshpass nc.x86_64 pwgen.x86_64 screen -y

ssh root@$MYSQL02 "yum install openssh-clients.x86_64 rsync.x86_64 wget.x86_64 vim-X11.x86_64 vim-enhanced.x86_64 mlocate.x86_64 nc.x86_64 tcpdump telnet sshpass nc.x86_64 pwgen.x86_64 screen nload -y"

echo ""
echo -e "\\033[1;39m \\033[1;32mPacotes necessarios instalados.\\033[1;39m \\033[1;0m"
echo ""

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc
yes | mv bashrc /root/.bashrc
scp /root/.bashrc root@$MYSQL02:/root/.

# CONFIG SELINUX
sed -i 's/=enforcing/=disabled/' /etc/sysconfig/selinux
ssh root@$MYSQL02 "sed -i 's/=enforcing/=disabled/' /etc/sysconfig/selinux"
echo ""
echo -e "\\033[1;39m \\033[1;32mSelinux Ajustado\\033[1;39m \\033[1;0m"
echo ""

# ATIVANDO O RSYSLOG
/etc/init.d/rsyslog start
chkconfig rsyslog on
ssh root@$MYSQL02 "/etc/init.d/rsyslog start"
ssh root@$MYSQL02 "chkconfig rsyslog on"

echo ""
echo -e "\\033[1;39m \\033[1;32mRsyslog Iniciado.\\033[1;39m \\033[1;0m"
echo ""

# DEFININDO O HOSTNAME
#sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME1"'/' /etc/sysconfig/network
#echo $NOME1 > /etc/hostname

#ssh root@$MYSQL02 "sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='"$NOME2"'/' /etc/sysconfig/network"
#ssh root@$MYSQL02 "echo $NOME2 > /etc/hostname"

#echo ""
#echo -e "\\033[1;39m \\033[1;32mHostname Ajustado.\\033[1;39m \\033[1;0m"
#echo ""

}


# INSTALAÇÃO MYSQL

mysqlinstall()
{
yum install mysql mysql-server mysql-devel mysql-utilities mytop -y
ssh root@$MYSQL02 "yum install mysql mysql-server mysql-devel mysql-utilities mytop -y"

# TUNING #
mkdir -p /var/lib/mysql/mysql-bin
mkdir -p /var/log/mysql
touch /var/log/mysql/slowquery.log
chown -R mysql.mysql /var/lib/mysql/mysql-bin
chown -R mysql.mysql /var/log/mysql
mkdir -p /mnt/mytmp
chown -R mysql.mysql /mnt/mytmp
chmod 755 /mnt/mytmp
echo "tmpfs                   /mnt/mytmp              tmpfs   size=2G         0 0" >> /etc/fstab
mount -a


ssh root@$MYSQL02 "mkdir -p /var/lib/mysql/mysql-bin"
ssh root@$MYSQL02 "mkdir -p /var/log/mysql"
ssh root@$MYSQL02 "touch /var/log/mysql/slowquery.log"
ssh root@$MYSQL02 "chown -R mysql.mysql /var/lib/mysql/mysql-bin"
ssh root@$MYSQL02 "chown -R mysql.mysql /var/log/mysql"
ssh root@$MYSQL02 "mkdir -p /mnt/mytmp"
ssh root@$MYSQL02 "chown -R mysql.mysql /mnt/mytmp"
ssh root@$MYSQL02 "chmod 755 /mnt/mytmp"
ssh root@$MYSQL02 "echo 'tmpfs                   /mnt/mytmp              tmpfs   size=2G         0 0' >> /etc/fstab"
ssh root@$MYSQL02 "mount -a"



/etc/init.d/mysqld start
ssh root@$MYSQL02 "/etc/init.d/mysqld start"

SENHA=`pwgen -Byns 15 1`
/usr/bin/mysqladmin -u root -h localhost.localdomain password ''$SENHA''
ssh root@$MYSQL02  "/usr/bin/mysqladmin -u root -h localhost.localdomain password ''$SENHA''"

echo "
[client]
user=root
password='$SENHA'
" > /root/.my.cnf
scp /root/.my.cnf root@$MYSQL02:/root/

sleep 5

/etc/init.d/mysqld stop
ssh root@$MYSQL02 "/etc/init.d/mysqld stop"

mv /etc/my.cnf /etc/my_cnf_bkp_ori
ssh root@$MYSQL02 "mv /etc/my.cnf /etc/my_cnf_bkp_ori"

echo "
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
#tmpdir=/mnt/mytmp
user=mysql
symbolic-links=0
log-error=/var/log/mysql/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
skip-external-locking

### CONFIG RECOVERY ###
myisam-recover = BACKUP

### REPLICATION ###
server-id = 1
auto_increment_increment = 2
log_bin = /var/lib/mysql/mysql-bin/mysql-bin.log
log-slave-updates
relay-log
relay-log-index
expire_logs_days = 7
max_binlog_size = 100M
innodb_flush_log_at_trx_commit=1
sync_binlog=1

### LOG'S ###
general_log_file = /var/log/mysql/mysql.log
general_log = 1
log-error=/var/log/mysql/error.log
slow-query-log=/var/log/mysql/slowquery.log
#log_slow_queries=/var/log/mysql/slowquery.log
long_query_time=5

### Conections ###
connect_timeout=10
max_connections=500
max_user_connections=100
max_connect_errors=20

### TUNING  ###
local-infile
low-priority-updates
symbolic-links
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8K
myisam_sort_buffer_size=2M
join_buffer_size=8M
sort_buffer_size=1M
table_cache=256
wait_timeout=30
tmp_table_size=4M
query_cache_size=2M
query_cache_limit=1M
key_buffer_size=2M
read_buffer_size = 1M
read_rnd_buffer_size = 2M

[safe_mysqld]
open_files_limit=65535

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

" > /etc/my.cnf

scp /etc/my.cnf root@$MYSQL02:/etc/
ssh root@$MYSQL02 "sed -i 's/server-id = 1/server-id = 2/' /etc/my.cnf"

$(which chkconfig) mysqld on
ssh root@$MYSQL02 "chkconfig mysqld on"

/etc/init.d/mysqld start
ssh root@$MYSQL02 "/etc/init.d/mysqld start"


# CRIANDO PASTA SCRIPTS
sshpass -p'#!cl0ud#!' scp -rv -o StrictHostKeyChecking=no root@187.33.3.137:/root/scripts /root/

# CONFIGURANDO CRONTAB BACKUP MYSQL
echo 'cat <(crontab -l) <(echo "05 00 * * * /root/scripts/mysql.sh") | $(which crontab) -' | bash

}
select * from user where user='slave_user'\G

criaUsers() {

mysql -e "grant all privileges on *.* to 'slave_user'@'localhost' identified by 'R3plic40'"
mysql -e "grant all privileges on *.* to 'slave_user'@'$MYSQL02' identified by 'R3plic40'"
mysql -e "flush privileges; reset master;"

#echo "grant all privileges on *.* to 'slave_user'@'localhost' identified by 'R3plic40'" >> /root/criauser.sql
#echo "grant all privileges on *.* to 'slave_user'@'$MYSQL01' identified by 'R3plic40'" >> /root/criauser.sql
#echo "flush privileges; reset master;" >> /root/criauser.sql
#scp /root/criauser.sql root@$MYSQL02:/root/
#rm -f /root/criauser.sql
#ssh root@$MYSQL02 "mysql < /root/criauser.sql"
#ssh root@$MYSQL02 "rm -f /root/criauser.sql"

}
show

iniciaReplication() {

echo "stop slave;" >> /root/setup.sql
echo 'CHANGE master TO master_host="'$NOME1'", master_user="slave_user", master_password="R3plic40", master_log_file="mysql-bin.000001",master_log_pos=106;' >> /root/setup.sql
echo "start slave;" >> /root/setup.sql
scp /root/setup.sql root@$MYSQL02:/root/
rm -f /root/setup.sql
ssh root@$MYSQL02 "mysql < /root/setup.sql"
ssh root@$MYSQL02 "rm -f /root/setup.sql"

ssh root@$MYSQL02 "mysql -e 'show slave status \G' | grep -i slave"

}


preparacaoSO
mysqlinstall
criaUsers
iniciaReplication

echo ""
echo -e "\\033[1;39m \\033[1;32mSETUP CONCLUIDO.\\033[1;39m \\033[1;0m"
