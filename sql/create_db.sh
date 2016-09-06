#!/bin/sh


if [ $# -ne 3 ] ; then
  echo "


    Usage: $0 user password db



Exiting....



"
  exit

fi

echo "

NOTE:  The database $3 must exist.  Also, the user $1 must exist with the password you provided.  

Continue? [Y/n] "

read cont

if [ -n "$cont" -a "$cont" != "Y" ] ; then

  echo "

Exiting....

"

fi

mysql -u"$1" -p"$2" $3 < cldl_schema_nodata.sql

SCRIPT_LIST="cldl_company.sql cldl_dvf.sql cldl_dv.sql cldl_menu.sql cldl_role_members.sql cldl_role_permission_dv.sql cldl_role_permission_menu.sql cldl_role.sql cldl_schema_nodata.sql cldl_user.sql"

IFS=" "
for i in `echo $SCRIPT_LIST`; do
  echo "$i
"
  mysql -u"$1" -p"$2" $3 < $i
  echo "
DONE
"
done
  
