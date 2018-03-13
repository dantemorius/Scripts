#!/bin/bash

descricao_do_servidor (){
printf "\n"
cpuname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpucores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpufreq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
svram=$( free -m | awk 'NR==2 {print $2}' )
svhdd=$( df -h | awk 'NR==2 {print $2}' )
svswap=$( free -m | awk 'NR==4 {print $2}' )

if [ -f "/proc/user_beancounters" ]; then
svip=$(ifconfig venet0:0 | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
else
svip=$(ifconfig | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
fi

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

sleep 1
}

bashrc(){

# CONFIGURANDO BASHRC
wget ftp://ftpcloud.mandic.com.br/Scripts/Linux/bashrc ; mv bashrc /root/.bashrc; su -

# INSTALANDO SNOOPY
apt-get update
apt-get install snoopy -y


# Configurando o hostname
echo -n "Informe o HOSTNAME do Servidor: "
read NOME
export NOME

hostname $NOME
su -

sleep 1
}

instalando_httpd{

apt-get install apache2 apache2-dev curl libcurl4-gnutls-dev perl imagemagick libxml2 libxml2-dev memcached libevent-2.0-5
}

instalando_e_configurando_vsftpd{
apt-get install vsftpd -y

mv /etc/vsftpd.conf /etc/vsftpd.conf_original && touch /etc/vsftpd.conf

echo '#############
##  VSFTP  ##
#############

force_dot_files=YES
background=YES
listen=YES

######################################
## Diretório inicial do usuário FTP ##
######################################

#local_root=/var/www/html/$USER # Opção deve ser usada apenas se não for utilizado apenas sem enjaulamento de usuários.
#user_sub_token=$USER
chown_uploads=YES
chown_username=apache
connect_from_port_20=YES

#################################
##  PARAMETROS de ACESSo FTPD  ##
#################################

ftp_data_port=20
listen_port=21
pasv_min_port=5500
pasv_max_port=5700
pasv_promiscuous=NO
port_enable=YES
port_promiscuous=NO
connect_timeout=60
data_connection_timeout=120
idle_session_timeout=120
setproctitle_enable=YES
banner_file=/etc/banner
dirmessage_enable=YES

###################################
##  Conf Conexao / Modo PASSIVO  ##
###################################

pasv_enable=YES
async_abor_enable=NO
guest_enable=NO
write_enable=YES
max_clients=300
max_per_ip=20
pam_service_name=vsftpd
tcp_wrappers=NO
ascii_upload_enable=NO
ascii_download_enable=NO
hide_ids=YES
ls_recurse_enable=NO
use_localtime=NO
anonymous_enable=NO
local_enable=YES
local_max_rate=0
local_umask=0022

#############################
## ENJAULAMENTO DE USUÁRIO ##
#############################

chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list # Necessário criar o arquivo e adicionar os usuários e seus respectivos diretórios.
userlist_deny=NO
#userlist_enable=YES
#userlist_file=/etc/vsftpd_users
check_shell=NO
chmod_enable=YES
secure_chroot_dir=/var/empty


###############
##    LOG    ##
###############

syslog_enable=NO # Ativando esta opção logs são enviados ao Messages
dual_log_enable=YES
log_ftp_protocol=NO
#vsftpd_log_file=/var/logs/vsftpd.log
vsftpd_log_file=/var/log/vsftpd.log
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/xferlog' > /etc/vsftpd.conf

adduser vsftpd
addgroup vsftpd
usermod -a -G vsftpd vsftpd

}

instalacao_fail2ban{
apt-get install fail2ban -y
mv  /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf_original && touch /etc/fail2ban/jail.conf

echo '[DEFAULT]
ignoreip = 127.0.0.1 201.20.44.2 177.70.100.5
bantime  = 345600
findtime  = 300
maxretry = 5
backend = auto
usedns = warn

[pam-generic]

enabled = false
filter  = pam-generic
action  = iptables-allports[name=pam,protocol=all]
logpath = /var/log/secure

[xinetd-fail]

enabled = false
filter  = xinetd-fail
action  = iptables-allports[name=xinetd,protocol=all]
logpath = /var/log/daemon*log

[ssh-iptables]

enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
logpath  = /var/log/secure
maxretry = 5

[ssh-ddos]

enabled  = false
filter   = sshd-ddos
action   = iptables[name=SSHDDOS, port=ssh, protocol=tcp]
logpath  = /var/log/sshd.log
maxretry = 2

[dropbear]

enabled  = false
filter   = dropbear
action   = iptables[name=dropbear, port=ssh, protocol=tcp]
logpath  = /var/log/messages
maxretry = 5

[proftpd-iptables]

enabled  = false
filter   = proftpd
action   = iptables[name=ProFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=ProFTPD, dest=you@example.com]
logpath  = /var/log/proftpd/proftpd.log
maxretry = 6

[gssftpd-iptables]

enabled  = false
filter   = gssftpd
action   = iptables[name=GSSFTPd, port=ftp, protocol=tcp]
           sendmail-whois[name=GSSFTPd, dest=you@example.com]
logpath  = /var/log/daemon.log
maxretry = 6

[pure-ftpd]

enabled  = false
filter   = pure-ftpd
action   = iptables[name=pureftpd, port=ftp, protocol=tcp]
logpath  = /var/log/pureftpd.log
maxretry = 6

[wuftpd]

enabled  = false
filter   = wuftpd
action   = iptables[name=wuftpd, port=ftp, protocol=tcp]
logpath  = /var/log/daemon.log
maxretry = 6

[sendmail-auth]

enabled  = false
filter   = sendmail-auth
action   = iptables-multiport[name=sendmail-auth, port="submission,465,smtp", protocol=tcp]
logpath  = /var/log/mail.log

[sendmail-reject]

enabled  = false
filter   = sendmail-reject
action   = iptables-multiport[name=sendmail-auth, port="submission,465,smtp", protocol=tcp]
logpath  = /var/log/mail.log

[sasl-iptables]

enabled  = false
filter   = postfix-sasl
backend  = polling
action   = iptables[name=sasl, port=smtp, protocol=tcp]
           sendmail-whois[name=sasl, dest=you@example.com]
logpath  = /var/log/mail.log

[assp]

enabled = false
filter  = assp
action  = iptables-multiport[name=assp,port="25,465,587"]
logpath = /root/path/to/assp/logs/maillog.txt

[ssh-tcpwrapper]

enabled     = false
filter      = sshd
action      = hostsdeny[daemon_list=sshd]
              sendmail-whois[name=SSH, dest=you@example.com]
ignoreregex = for myuser from
logpath     = /var/log/sshd.log

[ssh-route]

enabled  = false
filter   = sshd
action   = route
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-iptables-ipset4]

enabled  = false
filter   = sshd
action   = iptables-ipset-proto4[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-iptables-ipset6]

enabled  = false
filter   = sshd
action   = iptables-ipset-proto6[name=SSH, port=ssh, protocol=tcp, bantime=600]
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-bsd-ipfw]

enabled  = false
filter   = sshd
action   = bsd-ipfw[port=ssh,table=1]
logpath  = /var/log/auth.log
maxretry = 5

[apache-tcpwrapper]

enabled  = false
filter   = apache-auth
action   = hostsdeny
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 6

[apache-modsecurity]

enabled  = false
filter   = apache-modsecurity
action   = iptables-multiport[name=apache-modsecurity,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[apache-overflows]

enabled  = false
filter   = apache-overflows
action   = iptables-multiport[name=apache-overflows,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[apache-nohome]

enabled  = false
filter   = apache-nohome
action   = iptables-multiport[name=apache-nohome,port="80,443"]
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 2

[nginx-http-auth]

enabled = false
filter  = nginx-http-auth
action  = iptables-multiport[name=nginx-http-auth,port="80,443"]
logpath = /var/log/nginx/error.log

[squid]

enabled = false
filter  = squid
action  = iptables-multiport[name=squid,port="80,443,8080"]
logpath = /var/log/squid/access.log

[postfix-tcpwrapper]

enabled  = false
filter   = postfix
action   = hostsdeny[file=/not/a/standard/path/hosts.deny]
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/postfix.log
bantime  = 300

[cyrus-imap]

enabled = false
filter  = cyrus-imap
action  = iptables-multiport[name=cyrus-imap,port="143,993"]
logpath = /var/log/mail*log

[courierlogin]

enabled = false
filter  = courierlogin
action  = iptables-multiport[name=courierlogin,port="25,110,143,465,587,993,995"]
logpath = /var/log/mail*log

[couriersmtp]

enabled = false
filter  = couriersmtp
action  = iptables-multiport[name=couriersmtp,port="25,465,587"]
logpath = /var/log/mail*log

[qmail-rbl]

enabled = false
filter  = qmail
action  = iptables-multiport[name=qmail-rbl,port="25,465,587"]
logpath = /service/qmail/log/main/current

[sieve]

enabled = false
filter  = sieve
action  = iptables-multiport[name=sieve,port="25,465,587"]
logpath = /var/log/mail*log

[vsftpd-notification]

enabled  = false
filter   = vsftpd
action   = sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[vsftpd-iptables]

enabled  = false
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[apache-badbots]

enabled  = false
filter   = apache-badbots
action   = iptables-multiport[name=BadBots, port="http,https"]
           sendmail-buffered[name=BadBots, lines=5, dest=you@example.com]
logpath  = /var/www/*/logs/access_log
bantime  = 172800
maxretry = 1

[apache-shorewall]

enabled  = false
filter   = apache-noscript
action   = shorewall
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/apache2/error_log

[roundcube-iptables]

enabled  = false
filter   = roundcube-auth
action   = iptables-multiport[name=RoundCube, port="http,https"]
logpath  = /var/log/roundcube/userlogins

[sogo-iptables]

enabled  = false
filter   = sogo-auth
action   = iptables-multiport[name=SOGo, port="http,https"]
logpath  = /var/log/sogo/sogo.log

[groupoffice]

enabled  = false
filter   = groupoffice
action   = iptables-multiport[name=groupoffice, port="http,https"]
logpath  = /home/groupoffice/log/info.log

[openwebmail]

enabled  = false
filter   = openwebmail
logpath  = /var/log/openwebmail.log
action   = ipfw
           sendmail-whois[name=openwebmail, dest=you@example.com]
maxretry = 5

[horde]

enabled  = false
filter   = horde
logpath  = /var/log/horde/horde.log
action   = iptables-multiport[name=horde, port="http,https"]
maxretry = 5

[php-url-fopen]

enabled  = false
action   = iptables-multiport[name=php-url-open, port="http,https"]
filter   = php-url-fopen
logpath  = /var/www/*/logs/access_log
maxretry = 1

[suhosin]

enabled  = false
filter   = suhosin
action   = iptables-multiport[name=suhosin, port="http,https"]
logpath  = /var/log/lighttpd/error.log
maxretry = 2

[lighttpd-auth]

enabled  = false
filter   = lighttpd-auth
action   = iptables-multiport[name=lighttpd-auth, port="http,https"]
logpath  = /var/log/lighttpd/error.log
maxretry = 2

[ssh-ipfw]

enabled  = false
filter   = sshd
action   = ipfw[localhost=192.168.0.1]
           sendmail-whois[name="SSH,IPFW", dest=you@example.com]
logpath  = /var/log/auth.log
ignoreip = 168.192.0.1


[named-refused-tcp]

enabled  = false
filter   = named-refused
action   = iptables-multiport[name=Named, port="domain,953", protocol=tcp]
           sendmail-whois[name=Named, dest=you@example.com]
logpath  = /var/log/named/security.log
ignoreip = 168.192.0.1

[nsd]

enabled = false
filter  = nsd
action  = iptables-multiport[name=nsd-tcp, port="domain", protocol=tcp]
          iptables-multiport[name=nsd-udp, port="domain", protocol=udp]
logpath = /var/log/nsd.log

[asterisk]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-tcp, port="5060,5061", protocol=tcp]
           iptables-multiport[name=asterisk-udp, port="5060,5061", protocol=udp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[freeswitch]

enabled  = false
filter   = freeswitch
logpath  = /var/log/freeswitch.log
maxretry = 10
action   = iptables-multiport[name=freeswitch-tcp, port="5060,5061,5080,5081", protocol=tcp]
           iptables-multiport[name=freeswitch-udp, port="5060,5061,5080,5081", protocol=udp]

[ejabberd-auth]

enabled = false
filter = ejabberd-auth
logpath = /var/log/ejabberd/ejabberd.log
action   = iptables[name=ejabberd, port=xmpp-client, protocol=tcp]

[asterisk-tcp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-tcp, port="5060,5061", protocol=tcp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[asterisk-udp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-udp, port="5060,5061", protocol=udp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[mysqld-iptables]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
           sendmail-whois[name=MySQL, dest=root, sender=fail2ban@example.com]
logpath  = /var/log/mysqld.log
maxretry = 5

[mysqld-syslog]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
logpath  = /var/log/daemon.log
maxretry = 5

[recidive]

enabled  = false
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive,protocol=all]
           sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5

[ssh-pf]

enabled  = false
filter   = sshd
action   = pf
logpath  = /var/log/sshd.log
maxretry = 5

[3proxy]

enabled = false
filter  = 3proxy
action  = iptables[name=3proxy, port=3128, protocol=tcp]
logpath = /var/log/3proxy.log

[exim]

enabled = false
filter  = exim
action  = iptables-multiport[name=exim,port="25,465,587"]
logpath = /var/log/exim/mainlog

[exim-spam]

enabled = false
filter  = exim-spam
action  = iptables-multiport[name=exim-spam,port="25,465,587"]
logpath = /var/log/exim/mainlog

[perdition]

enabled = false
filter  = perdition
action  = iptables-multiport[name=perdition,port="110,143,993,995"]
logpath = /var/log/maillog

[uwimap-auth]

enabled = false
filter  = uwimap-auth
action  = iptables-multiport[name=uwimap-auth,port="110,143,993,995"]
logpath = /var/log/maillog

[osx-ssh-ipfw]

enabled  = false
filter   = sshd
action   = osx-ipfw
logpath  = /var/log/secure.log
maxretry = 5

[ssh-apf]

enabled = false
filter  = sshd
action  = apf[name=SSH]
logpath = /var/log/secure
maxretry = 5

[osx-ssh-afctl]

enabled  = false
filter   = sshd
action   = osx-afctl[bantime=600]
logpath  = /var/log/secure.log
maxretry = 5

[webmin-auth]

enabled = false
filter  = webmin-auth
action  = iptables-multiport[name=webmin,port="10000"]
logpath = /var/log/auth.log

[dovecot]

enabled = false
filter  = dovecot
action  = iptables-multiport[name=dovecot, port="pop3,pop3s,imap,imaps,submission,465,sieve", protocol=tcp]
logpath = /var/log/mail.log

[dovecot-auth]

enabled = false
filter  = dovecot
action  = iptables-multiport[name=dovecot-auth, port="pop3,pop3s,imap,imaps,submission,465,sieve", protocol=tcp]
logpath = /var/log/secure

[solid-pop3d]

enabled = false
filter  = solid-pop3d
action  = iptables-multiport[name=solid-pop3, port="pop3,pop3s", protocol=tcp]
logpath = /var/log/mail.log

[selinux-ssh]
enabled  = false
filter   = selinux-ssh
action   = iptables[name=SELINUX-SSH, port=ssh, protocol=tcp]
logpath  = /var/log/audit/audit.log
maxretry = 5

[ssh-blocklist]

enabled  = false
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
           blocklist_de[email="fail2ban@example.com", apikey="xxxxxx", service=%(filter)s]
logpath  = /var/log/sshd.log
maxretry = 20

[nagios]
enabled  = false
filter   = nagios
action   = iptables[name=Nagios, port=5666, protocol=tcp]
           sendmail-whois[name=Nagios, dest=you@example.com, sender=fail2ban@example.com, sendername="Fail2Ban"]
logpath  = /var/log/messages     ; nrpe.cfg may define a different log_facility
maxretry = 1

[my-vsftpd-iptables]

enabled  = true
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=shared@mandic.net.br]
logpath  = /var/log/vsftpd.log' > /etc/fail2ban/jail.conf
}

ajustes{
apt-get install sysv-rc-conf -y
#Configurar manualmente os serviços para serem inicializados
sysv-rc-conf
}

descricao_do_servidor
bash_rc
rsyslog
instalando_httpd
instalando_e_configurando_vsftpd
instalacao_fail2ban
ajustes