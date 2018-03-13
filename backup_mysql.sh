#!/bin/bash
bkpdir=/var/backup
mysqldump=`which mysqldump`
mysql=`which mysql`
data=`date +"%Y%m%d"`
 
### Script Backup ###
for dbase in `$mysql -N -e "show databases" -ss | grep -v "performance_schema\|information_schema"`
do
if [ ! -d "$bkpdir/$dbase" ]; then
mkdir -p $bkpdir/$dbase
fi
echo "Backup: $dbase"
$mysqldump $dbase --single-transaction --quick | bzip2 > $bkpdir/$dbase/$dbase.$data.bz2
done;
find $bkpdir -ctime +7 -type f -name \*.bz2 -exec rm -f {} \;