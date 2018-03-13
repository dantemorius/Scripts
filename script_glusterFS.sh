#!/bin/bash
#########################################################################
# AUTOR : AMAURI HIDEKI                                                 #
# DATA CRIAÇÃO : 11/05/2017                                             #
# DATA ALTERAÇÃO : 15/05/2017                                           #
# VERSÃO :  17/05/2017 V1.0 
# SERVIÇO : CLUSTER AMBIENTE WEB                                        #
# DISTRIB : CENTOS 7                                                    #
#                                                                       #
# FONTE                                                                 #
# http://gluster.readthedocs.io/en/latest/Quick-Start-Guide/Quickstart/ #
#                                                                       #
#########################################################################

###	PRÉ REQUISITOS	#####################################################
#																		#
# 	- TER DISCO DE DADOS EXCLUSIVO PARA O CLUSTER	                    #
#																		#
#	Deve ser criado arquivo conforme exemplo abaixo sem as cerquilhas	#
#																		#
#	configgluster                                                       #
#	NOS:INTERFACE:SENHA:IP_NÓ1:IP_NÓ2					                #
#	VOL:/var/www:/dev/vdb:/dev/vdb                                      #
#                                                                       #
#########################################################################

#############################################################################
## VARIÁVEIS DEFAULT														#
#############################################################################

# DECLARAÇÃO DE VARIÁVEIS GLOBAIS PARA ARQIOVO CONFIG

# LISTA IPS DO CLUSTER
NOS_CLUSTER=`grep '^NOS' configgluster | sed 's/:/\n/g' | sed '1d;2d;3d'`
# CONTAS NÚMEROS DE SERVIDORES DO CLUSTER
NOS_COUNT=`grep '^NOS' configgluster | sed 's/:/\n/g' | sed '1d;2d;3d' | wc -l`
# SENHA DO CLUSTER
SENHASSH=`grep '^NOS' configgluster | cut -d : -f3`
# LISTA DE VOLUMES
VOL=`grep '^VOL' configgluster | sed 's/:/\n/g' | sed '1d;2d'`
# DIRETÓRIO PADRÃO PARA O CLUSTER
DATADIR=`grep '^VOL' configgluster | cut -d : -f2`
# CHECK 0 FSTAB SEM INFORMAÇÃO INPUTADA PELO SCRIPT 1 INFORMAÇÃO JÁINPUTADA
USO_FSTAB=`grep -i brick1 /etc/fstab > /dev/null; echo $?`
USO_FSTAB_GV=`grep -i :gv0 /etc/fstab > /dev/null; echo $?`

perfil_padrao_local(){
echo "# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

HISTSIZE=1000
HISTFILESIZE=1000
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=ignoredups

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi" > /root/.bashrc
source /root/.bashrc

echo '#!/bin/bash
# User specific aliases and functions
Normal="\[\\033[0m\]"
Vermelho="\[\\033[1;31m\]"
Verde="\[\\033[1;32m\]"
Amarelo="\[\\033[1;33m\]"
Azul="\[\\033[1;34m\]"
Roxo="\[\\033[1;35m\]"
Ciano="\[\\033[1;36m\]"
Branco="\[\\033[1;37m\]"
PS1="$Normal$Azul[$Branco(\t) $Verde\u$Vermelho@$Amarelo\h$Verde $Ciano\w$Azul]$Branco\\$ $Normal"' > /etc/profile.d/mandic_bashrc.sh
source /etc/profile.d/mandic_bashrc.sh

echo '# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# powersave disable
#setterm -powersave off -blank 0

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH' > /root/.bash_profile
source /root/.bash_profile
}

gera_chave_local(){
# INSTALANDO PACOTES
# SSHPASS
VALIDA_PACOTE1=`rpm -qa | grep -i sshpass > /dev/null; echo $?`
if [ $VALIDA_PACOTE1 -ne 1 ] ;then
echo "NÃO FAZER" > /dev/null
else
rpm -ivh ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/KGronlund/CentOS_7/x86_64/sshpass-1.05-7.1.x86_64.rpm
fi

# OPENSSH
VALIDA_PACOTE2=`rpm -qa | grep -i openssh > /dev/null; echo $?`
if [ $VALIDA_PACOTE1 -ne 1 ] ;then
echo "NÃO FAZER" > /dev/null
else
yum install openssh-clients.x86_64 wget -y
fi

# GERANDO CHAVE
if [ -e /root/.ssh/id_rsa ];then
echo "Já tem chave RSA" > /dev/null
else
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ""
fi
}

troca_chave_cluster(){
echo ""
echo "###############################################"
echo "# Configuração dos NODES dentro do CLUSTER    #"
echo "###############################################"
echo ""

# TROCA DE CHAVES BASEADO NA LINHA COM CAMPO "NOS" DO ARQUIVO configgluster

echo '#!/bin/bash' > config_rel_conf.sh
echo "$NOS_CLUSTER" | while read TROCACHAVE; do
echo 'sshpass -p' "$SENHASSH" 'ssh-copy-id -i /root/.ssh/id_rsa.pub' "$TROCACHAVE" '&& sleep 1' >> config_rel_conf.sh
done

echo 'StrictHostKeyChecking no
#serKnownHostsFile=/dev/null'> ~/.ssh/config

sh +x config_rel_conf.sh && sleep 1
rm -rf config_rel_conf.sh

# COPIA CAVE PARA O CLUSTER
scp /root/.ssh/id_rsa.pub $NO_CLUSTER:/root/.ssh/id_rsa.pub

# DESABILITA SELINUX CLUSTER
ssh $NO_CLUSTER "sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config" && \
ssh $NO_CLUSTER "sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/sysconfig/selinux" && \
ssh $NO_CLUSTER "setenforce 0"

# COPIA ARQUIVOS DE PERFIL PARA O CLUSTER
scp /root/.bashrc $NO_CLUSTER:/root/.bashrc && \
ssh $NO_CLUSTER "source /root/.bashrc" && \
scp /etc/profile.d/mandic_bashrc.sh $NO_CLUSTER:/etc/profile.d/mandic_bashrc.sh && \
ssh $NO_CLUSTER "source /etc/profile.d/mandic_bashrc.sh" && \
scp /root/.bash_profile $NO_CLUSTER:/root/.bash_profile && \
ssh $NO_CLUSTER "source /root/.bash_profile" && \
ssh $NO_CLUSTER "rm -rf /root/ajusta_fqdn.sh"
}

fqdn_cluster(){
# FQDN
echo 'host_name=`hostname | grep -i .mandic.net.br > /dev/null ; echo $?`

if [ $host_name -eq 0 ]; then
echo "Hostname já no padrão FQDN"
else
hostnamectl set-hostname $(echo -e $(hostname | cut -d "-" -f1,7).mandic.net.br)
systemctl restart systemd-hostnamed.service
fi' > ajusta_fqdn.sh

# FQDN SETADO NA MÁQUIUNA
scp ajusta_fqdn.sh $NO_CLUSTER:/root/ajusta_fqdn.sh && \
ssh $NO_CLUSTER "sh +x ajusta_fqdn.sh"

# INSERE FQDN NOs HOSTS
ssh $NO_CLUSTER hostname | while read NAMEHOST; do echo "$NO_CLUSTER $NAMEHOST" >> /etc/hosts; done

# COPIA ARQUIVO HOSTS PARA TODOS OS NÓS
for i in `echo "$NOS_CLUSTER"`; do
scp /etc/hosts $i:/etc/hosts
done

}

fdisk_cluster(){
# CRIANDO PARTIÇÃO
ssh $NO_CLUSTER "echo -e 'n\np\n\n\n\n\nw' | fdisk $(echo $VOL | cut -d ' ' -f$CONT)" && \
# FORMATANDO PARTIÇÃO
ssh $NO_CLUSTER "mkfs.xfs -fi size=512 $(echo $VOL | cut -d ' ' -f$CONT)1" && \
# CRIANDO DIRETÓRIO
ssh $NO_CLUSTER "mkdir -p /data/brick1"

# IF CHECA SE O FSTAB JÀ POSSUI A INFORMAÇÃO PARA NÃO DUPLICAR
if [ $USO_FSTAB -eq "1" ] ;then
# ADICIONA MONTAGEM DA PARTIÇÃO NO DIRETÓRIO CRIADO DENTRO DO FSTAB
ssh $NO_CLUSTER "echo "$(echo $VOL | cut -d ' ' -f$CONT)1 /data/brick1 xfs defaults 1 2" >> /etc/fstab"
fi

# MONTANDO PARTIÇÃO NO DIRETÓRIO CRIADO
ssh $NO_CLUSTER "mount -a"
}

install_gluster_cluster(){
# INSTALAR O SERVIÇO GLUSTERFS
ssh $NO_CLUSTER "yum -y install centos-release-gluster37.noarch " && \
ssh $NO_CLUSTER "yum -y install glusterfs gluster-cli glusterfs-libs glusterfs-server"

# TEMPO ESTIMADO DE ATÉ 10 MIN PARA A INSTALAÇÃO
# 15:09:10
# 15:18:23

# INICIAR DAEMON DE GERENCIAMENTO DO GLUSTERFS
ssh $NO_CLUSTER "service glusterd start"
}

configura_gluster_cluster_adicina_nos(){
# ADICINA TODOS OS SERVIDORES COM EXCEÇÃO DELE MESMO DENTRO DA CONFIGURAÇÃO DO GLUSTER DE CADA NO
ssh $NO_CLUSTER "gluster peer probe $(for i in `echo "$NOS_CLUSTER"`; do ssh $i hostname;done | grep -v $NO_CLUSTER_NAME)"
}

configura_gluster_cluster_cria_volume_nos(){
#############################################################################
## Executar só no servidor MASTER											#
#############################################################################
#mkdir -p /data/brick1/gv0
NUM_NOS=`echo $NOS_CLUSTER | wc -l`
gluster volume create gv0 replica $NUM_NOS $(for i in `echo "$NOS_CLUSTER"`; do ssh $i hostname | while read GV_NO; do echo $GV_NO:/data/brick1/gv0 ;done ;done)
gluster volume start gv0
}

client_glusterfs(){
# CRIAR DIRETÓRIO ONDE SERÁ MONTADO O VOLUME
ssh $NO_CLUSTER "mkdir -p $DATADIR"
# IF CHECA SE O FSTAB JÀ POSSUI A INFORMAÇÃO PARA NÃO DUPLICAR
if [ $USO_FSTAB_GV -eq "1" ] ;then
# ADICIONA MONTAGEM DA PARTIÇÃO NO DIRETÓRIO CRIADO DENTRO DO FSTAB
ssh $NO_CLUSTER "echo "$NO_CLUSTER_NAME:gv0 $DATADIR glusterfs       defaults 0 0" >> /etc/fstab"
fi
# MONTANDO PARTIÇÃO NO DIRETÓRIO CRIADO
ssh $NO_CLUSTER "mount -a"
}

engrenagem(){

engine_1(){
COUNT=0
CONT=$(( $COUNT + 1 ))

while [[ $NOS_COUNT -ge $CONT ]] ; do

# VARIAVEIS CONDICINAIS ATRELADO AO CONTADOR
NO_CLUSTER=`echo $NOS_CLUSTER | cut -d ' ' -f"$CONT"`
NO_CLUSTER_NAME=`ssh $NO_CLUSTER hostname`

perfil_padrao_local
gera_chave_local
troca_chave_cluster
fqdn_cluster
fdisk_cluster
install_gluster_cluster

CONT=$(( $CONT + 1 ))
done

}

engine_2(){
# DEPENDE DE QUE TODAS AS EXECUÇÕES DA engine_1
COUNT=0
CONT=$(( $COUNT + 1 ))

while [[ $NOS_COUNT -ge $CONT ]] ; do

# VARIAVEIS CONDICINAIS ATRELADO AO CONTADOR
NO_CLUSTER=`echo $NOS_CLUSTER | cut -d ' ' -f"$CONT"`
NO_CLUSTER_NAME=`ssh $NO_CLUSTER hostname`

configura_gluster_cluster_adicina_nos
client_glusterfs

CONT=$(( $CONT + 1 ))
done

}

engine_1
engine_2
configura_gluster_cluster_cria_volume_nos
}

engrenagem