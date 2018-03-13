#!/bin/bash

mkdir /root/scripts

echo '#!/bin/bash

PATH="/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

export PATH

qs=$(ps aux |grep 'aavdisk' |grep -v grep|wc -l)
qd=$(ps aux |grep 'agent_wrapper watchdog' |grep -v grep|wc -l)
qt=$(ps aux |grep Agent.Service.Mono.exe |grep -v grep|wc -l)

if [[ $qt -ne 1 || $qd -ne 2 || $qs -eq 0 ]]; then
        echo "Mais de um Mono.exe - `date`" >> /root/scripts/log_kill_mono.txt
        /etc/init.d/rapidrecovery-agent stop
        /etc/init.d/rapidrecovery-vdisk stop
	sleep 10
	
        ps efx | grep 'Agent.Service.Mono.exe\|agent_wrapper watchdog\|aavdisk' | grep -v "grep" | awk '{print $1}' | xargs kill -9 && sleep 10
        echo "Realizando restart - `date`" >> /root/scripts/log_kill_mono.txt

        /etc/init.d/rapidrecovery-agent start
        /etc/init.d/rapidrecovery-vdisk start

        if [ $? -eq 0 ]; then
                echo "Restar OK - `date`" >> /root/scripts/log_kill_mono.txt

        else
                echo "Falha no restart - `date`" >> /root/scripts/log_kill_mono.txt
                echo " " >> /root/scripts/log_kill_mono.txt
        fi

        echo " " >> /root/scripts/log_kill_mono.txt

fi' > /root/scripts/kill_mono_rapidrecovery.sh

#$(which wget) ftp://ftpcloud.mandic.com.br/Backup/RapidRecovery/Scripts/Linux/kill_mono_rapidrecovery.sh -O /root/scripts/kill_mono_rapidrecovery.sh
$(which chmod) +x /root/scripts/kill_mono_rapidrecovery.sh
$(which chattr) +i /root/scripts/kill_mono_rapidrecovery.sh
echo 'cat <(crontab -l) <(echo "* * * * * /root/scripts/kill_mono_rapidrecovery.sh #Script para melhoria de performance do Agent") | $(which crontab) -' | bash
