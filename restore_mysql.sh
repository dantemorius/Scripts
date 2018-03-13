#!/bin/bash
for ARQ in `ls *.sql`

do
        echo "Iniciando processo de restore"
        echo "Validando Database"

        BASE=`ls $ARQ | grep -Ev -e "Database" -e "information_schema" -e "mysql" -e "performance_schema" | cut -d "." -f1`
        VALIDACAO=`mysql -e "show databases" | cut -d " " -f2 | grep "$BASE"`

        if [ "$VALIDACAO" == "$BASE" ];
then
        echo "A Base $BASE existe"
        echo "Removendo $BASE"
        mysqladmin drop $BASE -f
        echo "Database $BASE removida"
        echo "criando $BASE"
        mysqladmin create $BASE -f
        echo "Database $BASE criada"
        echo "Restaurando $BASE"
        mysql $BASE < $ARQ
        echo "Database $BASE restaurada"

else
        echo "A Base $BASE nao existe"
        echo "criando $BASE"
        mysqladmin create $BASE -f
        echo "Database $BASE criada"
        echo "Restaurando $BASE"
        mysql $BASE < $ARQ
        echo "Database $BASE restaurada"
fi

done