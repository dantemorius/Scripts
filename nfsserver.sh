#!/bin/bash

# Script for server side NFS configuration on RHEL 6

package_query() {
    if rpm -q $1 >&-; then
        echo "Package $1 is currently installed, proceeding."
    else
        read -p "Package $1 is not installed, would you like to install it? (y/n) " choice
        while :
        do
            case "$choice" in
                y|Y) yum -y install "$1"; break;;
                n|N) echo "Package $1 required to continue, exiting..."; exit 1;;
                * ) read -p "Please enter 'y' or 'n': " choice;;
            esac
        done
    fi
    if ! rpm -q $1 >&-; then
        echo "Package $1 failed to install, exiting..."; exit 1
    fi
}

service_query() {
    read -p "$1 daemon required to continue, Would you like to start it? (y/n) " choice
    while :
    do
        case "$choice" in
            y|Y ) service $1 start; chkconfig $1 on; break;;
            n|N ) echo "ERROR: $1 daemon not started. Exiting..."; exit 1;;
            * ) read -p "Please enter 'y' or 'n': " choice;;
    esac
    done
}

export_array=('/fileserver') # Array of local filesystems to be exported
remote_array=('10.0.0.1(sync,rw,no_root_squash)') # Array of remote client/mount option groupings for a given export
port_array=('32803' '32769' '892' '662' '875') # Array of custom port definitions for NFS/Firewall use
nfs_vers=auto
new_exports=0

if [ ! -f /etc/exports ]; then
    touch /etc/exports;
    new_exports=1
else
    for mountpoint in "${export_array[@]}"; do
        if  grep -q "$mountpoint" /etc/exports ; then
            echo "ERROR: Export $mountpoint already configured in /etc/exports, exiting to ensure none of your configurations are altered"; exit 1
        fi
    done
fi

if [ ! -f /etc/sysconfig/nfs ]; then
    touch /etc/sysconfig/nfs;
fi

if egrep -q '^[[:space:]]*LOCKD_TCPPORT' /etc/sysconfig/nfs; then
    echo "ERROR: Custom lockd TCP port already configured in /etc/sysconfig/nfs, exiting to ensure your configuration is not altered"; exit 1
fi

if egrep -q '^[[:space:]]*LOCKD_UDPPORT' /etc/sysconfig/nfs; then
    echo "ERROR: Custom lockd UDP port already configured in /etc/sysctl.conf, exiting to ensure your configuration is not altered"; exit 1
fi

if egrep -q '^[[:space:]]*MOUNTD_PORT' /etc/sysconfig/nfs; then
    echo "ERROR: Custom mountd ports already configured in /etc/sysconfig/nfs, exiting to ensure your configuration is not altered"; exit 1
fi

if egrep -q '^[[:space:]]*STATD_PORT' /etc/sysconfig/nfs; then
    echo "ERROR: Custom statd ports already configured in /etc/sysconfig/nfs, exiting to ensure your configuration is not altered"; exit 1
fi

if egrep -q '^[[:space:]]*RQUOTAD_PORT' /etc/sysconfig/nfs; then
    echo "ERROR: Custom rquotad ports already configured in /etc/sysconfig/nfs, exiting to ensure your configuration is not altered"; exit 1
fi

package_query nfs-utils

package_query nfs-utils-lib

if [ $nfs_vers -eq 4 ]; then
    package_query nfs4-acl-tools
fi

for mountpoint in "${export_array[@]}"; do
    if [ ! -d "$mountpoint" ]; then
        read -p "ERROR: Local export $mountpoint not found. Would you like to create it? (y/n) " choice
        while :
        do
            case "$choice" in
                y|Y ) mkdir -p "$mountpoint" ; break;;
                n|N ) echo "ERROR: Local export $mountpoint required to continue, exiting..."; exit 1;;
                * ) read -p "Please enter 'y' or 'n': " choice;;
            esac
        done
    fi
done

# NFS server configuration
if [ $new_exports -eq 0 ]; then
    cp /etc/exports /etc/exports.orginal-"$(date +%Y%m%d%H%M%S)"
fi

for i in $(seq 0 $(( ${#export_array[@]}-1 ))); do
	cat <<- EOF >>/etc/exports
	${export_array[i]}   ${remote_array[i]}
	EOF
done

cat <<- EOF >>/etc/sysconfig/nfs
#TCP port rpc.lockd should listen on.
LOCKD_TCPPORT=${port_array[0]}
#UDP port rpc.lockd should listen on.
LOCKD_UDPPORT=${port_array[1]}
#Port rpc.mountd should listen on.
MOUNTD_PORT=${port_array[2]}
# Port rpc.statd should listen on.
STATD_PORT=${port_array[3]}
# Port rpc.rquotad should listen on.
RQUOTAD_PORT=${port_array[4]}
EOF

if ! pgrep rpcbind >&-; then
    service_query rpcbind
fi
service_query nfs

echo "The following ports must be opened in your firewall to allow NFS mounts, /etc/sysconfig/iptables syntax used:"
rpcinfo -p | awk '{if($1 ~ /[[:digit:]]+/){print "-I INPUT -p " $3 " -m " $3 " --dport " $4 " -j ACCEPT"}}' | sort | uniq
