mysqldump -u jack -p --compact --no-create-info --where="company_id=1" cldl cldl_company > cldl_company.sql
mysqldump -u jack -p --compact --no-create-info --where="company_id=1" cldl cldl_menu > cldl_menu.sql
mysqldump -u jack -p --compact --no-create-info --where="company_id=1" cldl cldl_dv >> cldl_dv.sql
mysqldump -u jack -p --compact --no-create-info --where="dv_id=15" cldl cldl_dvf >> cldl_dvf.sql
mysqldump -u jack -p --compact --no-create-info --where="company_id=1" cldl cldl_user > cldl_user.sql
mysqldump -u jack -p --compact --no-create-info cldl cldl_role > cldl_role.sql
mysqldump -u jack -p --compact --no-create-info cldl cldl_role_members > cldl_role_members.sql
mysqldump -u jack -p --compact --no-create-info cldl cldl_role_permission_dv   > cldl_role_permission_dv.sql
mysqldump -u jack -p --compact --no-create-info cldl cldl_role_permission_menu > cldl_role_permission_menu.sql

