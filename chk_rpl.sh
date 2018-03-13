#!/bin/bash

# Script para validacao de MySQL Replication

RESULT1=`mysql -e "show slave status \G" | grep Slave | awk NR==2 | cut -d ":" -f2`
RESULT2=`mysql -e "show slave status \G" | grep Slave | awk NR==3 | cut -d ":" -f2`

if [ $RESULT1 = Yes -a $RESULT2 = Yes ]; then
   echo "0" #UP
else
   echo "1" #DOWN
fi

# -FIM
