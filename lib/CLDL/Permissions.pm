package CLDL::Admin::Permissions;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.002';

sub update_permissions_menu {

  my $sql_delete_permissions = undef;
  if ( session('role_id') == 5 ) {
    $sql_delete_permissions = q(
                DELETE FROM cldl_role_permission_menu
                  WHERE     menu_id = ?
                        AND role_id IN 
                            ( SELECT role_id
                                FROM cldl_role
                                  WHERE (    company_id = ?
                                          OR company_id = 1 )
                                        AND active = 1  ));
  } else {
    $sql_delete_permissions = q(
                DELETE FROM cldl_role_permission_menu
                  WHERE     menu_id = ?
                        AND role_id IN 
                            ( SELECT role_id
                                FROM cldl_role
                                  WHERE     company_id = ?
                                        AND active     = 1  ));

  }
  my $sth_delete_permissions = database->prepare( $sql_delete_permissions );

  my $sth_insert_role_permission = database->prepare(
    'INSERT INTO cldl_role_permission_menu ( role_id, menu_id) VALUES ( ?, ?)'
  );

  my $menu_id  = params->{menu_id};
  $sth_delete_permissions->execute( $menu_id, session('company_id') );

  my $role_ids = params;

  delete $role_ids->{menu_id};
  foreach my $key ( keys %{$role_ids} ) {
    $key =~ m/(\d+)_.*/;
    $sth_insert_role_permission->execute( $1, $menu_id );
  }

  &CLDL::Cache::update_caches( session('company_id') );

  return to_json( { status => 0 } );

}

# cldl_role
# ---------
# role_id,
# company_id,
# active,
# role_name
# 
# cldl_role_members
# -----------------
# role_id,
# user_id
# 
# cldl_role_permission_menu
# -------------------------
# role_permission_id,
# role_id,
# menu_id,
# 
# role_list = qq(
# SELECT role_id,
#        role_name
#   FROM cldl_role
#     WHERE ( company_id = ? OR company_id = 1) 
#           AND active = 1
# );
# 
# ## Loop into a hash
#   { role_id => { role_name => xxxx } };
# 
# menu_role_perm = qq(
# SELECT role_permission_id,
#        role_id,
#        menu_id, 
#   FROM cldl_role_permission_menu
#     WHERE menu_id = ?
# );
# 
# while role_list {
#   menu_role_perm->execute( menu_id ) 
# 
# }

sub update_permissions_dv {

}

1;



