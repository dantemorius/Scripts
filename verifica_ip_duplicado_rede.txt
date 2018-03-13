#!/bin/bash
for a in `ifconfig -a | cut -d " " -f1 | grep eth | grep -Ev ":"`

        do

        arp -an | grep "$a" | cut -d "(" -f2 | cut -d ")" -f1 | while read i; do arping -I "$a" -c 1 "$i" | grep Unicast | cut -d " " -f4 | uniq -c | grep -Ev " 1 " | cut -d " " -f8 | while read u ; do arping -I "$a" -c 1 "$u" | grep Unicast | cut -d " " -f4,5 ; done ; done

        done

		
## Alternativa
##
##!/bin/bash
##for a in `ifconfig -a | cut -d " " -f1 | grep eth | grep -Ev -e ":" -e "eth0"`
##
##        do
##
##		arp-scan -I "$a" -l | grep -B 1 DUP | awk '{print $1,$2}'
##
##        done