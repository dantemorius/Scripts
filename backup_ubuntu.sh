#!/bin/bash

### Script Java ###
mkdir /usr/java
wget  http://wiki.mandic.com.br/downloads/jre-7u1_linux-x64.tar.gz
tar -zxvf  jre-7u1_linux-x64.tar.gz -C /usr/java

### Script Backup ###
mkdir /usr/local/obm
wget  http://cloud.mandic.com.br/files/backup/mandic_agent_linux.tar.gz
tar -zxvf  mandic_agent_linux.tar.gz -C /usr/local/obm
export JAVA_HOME=/usr/java
sh /usr/local/obm/bin/install.sh > /root/mandicOBM_linux.log
sh /usr/local/obm/bin/Configurator.sh