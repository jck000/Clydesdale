#!/bin/sh

#
# This script will create the basic user and setup the database for CLDL
#

if [ $# -ne 2 ] ; then
  echo "

  Usage: $0 user password


"
  exit

fi

echo "
Create database? [Y/N]"
read create_db

create_db2=${create_db^^} # convert to uppercase

if [ "$create_db2" == "Y" ] ; then
  echo "

    Name of DB to create: "
else
  echo "

    Name of DB to use for CLDL: "
fi
read dbname

echo "
  User cldl must be created 

  Password for cldl user: "
read cldl_password

if [ -z "$dbname" -o -z "$cldl_password" ] ; then
  echo "

    You must provide a database name and/or a passowrd for the cldl user.  Try again.

    

"
  exit
fi


if [ "$create_db2" == "Y" ] ; then 
  CR_DB="CREATE DATABASE $dbname;"
  echo "
Creating DB $dbname 
"
  mysql -u"$1" -p"$2" -e "$CR_DB"
  echo " DONE
"
fi

CR_USER="USE $dbname;
CREATE USER 'cldl'@'localhost' IDENTIFIED BY '$cldl_password';
GRANT ALL PRIVILEGES ON *.* TO 'cldl'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;"
echo "
Create user cldl 
"
mysql -u"$1" -p"$2" -e "$CR_USER"
echo " DONE"

echo "
Create Tables 
"
mysql -u"$1" -p"$2" $dbname < cldl_schema_nodata.sql
echo " DONE"

echo "
Insert data 
"
mysql -u"$1" -p"$2" $dbname < cldl_data.sql
echo " DONE



"




