#!/bin/bash

#################################
# SCRIPT DE SETUP RAPIDRECOVERY #
# 18/11/2016                    #
# Amauri Hideki                 #
# amauri.hideki@mandic.net.br   #
#################################

C6=1
C7=1
UB12=1
UB13=1
UB14=1
UB15=1
UB16=1
DEB7=1
DEB8=1
S11=1
S12=1

# VALIDA SISTEM OPERACIONAL
if [ -e "/etc/redhat-release" ]
then

C6=`grep " 6" /etc/redhat-release > /dev/null; echo $?`
C7=`grep " 7" /etc/redhat-release > /dev/null; echo $?`

else

UB12=`grep -i "Ubuntu 12" /etc/issue > /dev/null; echo $?`
UB13=`grep -i "Ubuntu 12" /etc/issue > /dev/null; echo $?`
UB14=`grep -i "Ubuntu 14" /etc/issue > /dev/null; echo $?`
UB15=`grep -i "Ubuntu 15" /etc/issue > /dev/null; echo $?`
UB16=`grep -i "Ubuntu 16" /etc/issue > /dev/null; echo $?`
DEB7=`grep -i "Debian GNU/Linux 7" /etc/issue > /dev/null; echo $?`
DEB8=`grep -i "Debian GNU/Linux 8" /etc/issue > /dev/null; echo $?`
S11=`grep -i "SUSE Linux Enterprise Server 11" /etc/issue | grep -i "x86_64" > /dev/null; echo $?`
S12=`grep -i "SUSE Linux Enterprise Server 12" /etc/issue | grep -i "x86_64" > /dev/null; echo $?`

fi

remoto="http://177.70.98.38/linux/rapidrecovery/pacotes/"

# CRIANDO USUARIO APPBACKUP
echo ""
echo "==================================="
echo -e "\\033[1;39m \\033[1;32mCriando usuario APPBACKUP\\033[1;39m \\033[1;0m"
echo "==================================="
useradd -p $(openssl passwd -1 'NTaSUD447UHy%$man!2') -s /sbin/nologin appbackup


if [ "$C6" -eq "0" ]
then

        distro=RHEL6
        rapidrecovery='rapidrecovery-repo-6.0.2.144-rhel6-x86_32.rpm'

                else
                if [ "$C7" -eq "0" ]
                then

                                distro=RHEL7
                                rapidrecovery='rapidrecovery-repo-6.0.2.144-rhel7-x86_64.rpm'

                                else
                                if [ "$S11" -eq "0" ]
                                                then

                                                distro=SUSE11
                                                rapidrecovery='rapidrecovery-repo-6.0.2.144-sles11-x86_64.rpm'

                                                else
                                                if [ "$S12" -eq "0" ]
                                                                then

                                                                distro=SUSE12
                                                                rapidrecovery='rapidrecovery-repo-6.0.2.144-sles12-x86_64.rpm'

                                                                else
                                                                if [ "$DEB7" -eq "0" ] || [ "$UB12" -eq "0" ] || [ "$UB13" -eq "0" ] || [ "$UB14" -eq "0" ]
                                                                                then

                                                                                distro="DEBIAN7 ou UBUNTU12/13/14"
                                                                                rapidrecovery='rapidrecovery-repo-6.0.2.144-debian7-x86_64.deb'

                                                                                else
                                                                                if [ "$DEB8" -eq "0" ] || [ "$UB15" -eq "0" ] || [ "$UB16" -eq "0" ]
                                                                                                then
                                                                                                distro="DEBIAN8 ou UBUNTU15/16"
                                                                                                rapidrecovery='rapidrecovery-repo-6.0.2.144-debian8-x86_64.deb'

                                                                                fi
                                                                fi
                        fi
                fi
        fi
fi



clear
        echo "==================================="
        echo -e "\\033[1;39m \\033[1;32mEfetuando download do Agente $distro\\033[1;39m \\033[1;0m"
        echo "==================================="
        echo ""


if [ "$DEB7" -eq "0" ] || [ "$UB12" -eq "0" ] || [ "$UB13" -eq "0" ] || [ "$UB14" -eq "0" ] || [ "$DEB8" -eq "0" ] || [ "$UB15" -eq "0" ] || [ "$UB16" -eq "0" ]
then

wget $remoto$rapidrecovery
dpkg -i $rapidrecovery
apt-get update
apt-get install rapidrecovery-agent
cat << EOF | rapidrecovery-module-installer
all
EOF

rapidrecovery-config -p 9006  -u appbackup -s
service rapidrecovery-agent restart
service rapidrecovery-vdisk restart

else
if [ "$S12" -eq "0" ] || [ "$S11" -eq "0" ]
then

wget $remoto$rapidrecovery
rpm -ivh $rapidrecovery
zypper install -y rapidrecovery-agent
cat << EOF | rapidrecovery-module-installer
all
EOF

rapidrecovery-config -p 9006  -u appbackup -s
service rapidrecovery-agent restart
service rapidrecovery-vdisk restart

else
if [ "$C6" -eq "0" ] || [ "$C7" -eq "0" ]
then

wget $remoto$rapidrecovery
rpm -ivh $rapidrecovery
yum install -y rapidrecovery-agent
cat << EOF | rapidrecovery-module-installer
all
EOF

rapidrecovery-config -p 9006  -u appbackup -s
service rapidrecovery-agent restart
service rapidrecovery-vdisk restart

fi
fi
fi

yum install -y yum-utils-1.1.30-40.el6.noarch
package-cleanup --oldkernels --count=2 -y