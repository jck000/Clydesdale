#!/bin/sh

if [ $# -ne 2 ] ; then
  echo "

  Usage:  $0 user password 

"
  exit
fi

echo " 
SET foreign_key_checks = 0; " > cldl_data.sql

mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers --where="company_id=1" cldl cldl_company >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers --where="company_id=1" cldl cldl_menu    >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers --where="company_id=1" cldl cldl_dv      >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers --where="dv_id=15" cldl cldl_dvf         >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers --where="company_id=1" cldl cldl_user    >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers cldl cldl_role                           >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers cldl cldl_role_members                   >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers cldl cldl_role_permission_dv             >> cldl_data.sql
mysqldump -u"$1" -p"$2" --compact --no-create-info --skip-triggers cldl cldl_role_permission_menu           >> cldl_data.sql

echo " 
SET foreign_key_checks = 1;
" >> cldl_data.sql
