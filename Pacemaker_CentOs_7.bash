##########################
###Pacemaker - CentOS 7###
##########################

#####Preparação#####
####Ambos os nós#### {

##Configurar hostname
hostnamectl set-hostname pacemaker1 --static

##Gerar chaves
ssh-keygen -t rsa
ssh-copyid "ip nó"

####Populando o arquivo de configuração do Corosync (Ambos os nós)
pcs cluster setup --local --name cluster1 pacemaker1 pacemaker2
##Iniciando os serviços
systemctl start corosync
systemctl start pacemaker

##Checando Firewall
firewall-cmd --state

##Adicionando exceção para serviços de alta disponibilidade
firewall-cmd --permanent --add-service=high-availability

##Reload firewall para aplicar alterações
firewall-cmd --reload


##Setar Autenticação entre os dois nós (ambos os nós)
pcs cluster auth pacemaker1 pacemaker2 -force

##habilitar cluster e inicializá-lo
pcs cluster enable --all 
pcs cluster start --all 


#Habilitar serviço na inicialização
systemctl enable corosync.service
systemctl enable pacemaker.service


#desabilitar Quorum - Checagem que serve para chegar se mais da metade dos nodes estão online. Como o firewall só tem dois nós, não faz sentido manter habilitado.
pcs property set no-quorum-policy=ignore

##Importante, setar STONISH como false a não ser que seja criado um contexto para cada ressource
pcs property set stonith-enabled=false

###Criar ressource de vIP para o cluster (Somente em um nó):
pcs resource create cluster_vip ocf:heartbeat:IPaddr2 nic=eth1:1 ip=192.168.100.3 cidr_netmask=24 op monitor interval=20s
pcs resource debug-start cluster_vip



}




