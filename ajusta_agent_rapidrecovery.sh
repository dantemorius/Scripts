#!/bin/bash

mkdir /root/scripts

$(which wget) ftp://ftpcloud.mandic.com.br/Backup/RapidRecovery/Scripts/Linux/kill_mono_rapidrecovery.sh -O /root/scripts/kill_mono_rapidrecovery.sh
$(which chmod) +x /root/scripts/kill_mono_rapidrecovery.sh
$(which chattr) +i /root/scripts/kill_mono_rapidrecovery.sh
echo 'cat <(crontab -l) <(echo "* * * * * /root/scripts/kill_mono_rapidrecovery.sh #Script para melhoria de performance do Agent") | $(which crontab) -' | bash
