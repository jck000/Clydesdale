package CLDL::Admin::EditMenu;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

use Data::Dumper;

our $VERSION = '0.00001';

prefix '/admin/editmenu';

get '/select' => sub {

  my $sth_edit_menu = database->prepare(
             qq( 
                SELECT m.menu_id,
                       m.pmenu_id,
                       m.ordr,
                       m.menu_label,
                       m.menu_link,
                       m.active
                  FROM cldl_menu m,
                       cldl_role_permission_menu rpm
                    WHERE (    m.company_id = ?
                            OR m.company_id = 1 )
                          AND m.pmenu_id    = m.menu_id

                  UNION

                SELECT m.menu_id,
                       m.pmenu_id,
                       m.ordr,
                       m.menu_label,
                       m.menu_link,
                       m.active
                  FROM cldl_menu m,
                       cldl_role_permission_menu rpm
                    WHERE (    m.company_id = ?
                            OR m.company_id = 1 )
                          AND m.pmenu_id   != m.menu_id

                   ORDER BY 2, 3 )
  );
  my $edit_menu;

  $sth_edit_menu->execute( session('company_id'), session('company_id') );

  # Put Child records under parent
  while ( my $ref = $sth_edit_menu->fetchrow_hashref ) {
    if ( $ref->{menu_id} == $ref->{pmenu_id} ) {
      $edit_menu->{ $ref->{menu_id} } = $ref;
    } else {
      push  @{ $edit_menu->{ $ref->{pmenu_id} }->{children}}, $ref;
    }
  }

  return template 'cldl/admin/editmenu.tt',
                       {
                         title     => "Maintain Menu",
                         edit_menu => $edit_menu,
                       },
                       { layout    => 'editmenu.tt' };  

};

# Save list order
get '/update/order' => sub {

  my $sth_save_menu_order = database->prepare(
               'UPDATE cldl_menu
                  SET pmenu_id = ?,
                      ordr     = ?
                    WHERE menu_id = ?');


# ordr value      menu_id pmenu_id
# ---- --------   ------- ----------
# 0 item[1]=null&  1      0
# 1 item[8]=1&     8      1
# 2 item[6]=1&     6      1
# 3 item[4]=1&     4      1
# 4 item[3]=1&     3      1
# 5 item[7]=1&     7      1
# 6 item[2]=1&     2      1
# 7 item[5]=1';    5      1

# This is a Micky Mouse approach and needs to be cleaned up

  my $qs         = request->query_string;

  my $ordr       = 0;
  my $menu_id    = undef;
  my $pmenu_id   = undef;
  my $item_value = undef;
  my @items      = split(/&/, $qs);

  foreach my $item (@items){
    ($menu_id, my $item_value) = split(/=/, $item);
    $menu_id =~ s/[\D..]//g;
    if ( $item_value eq 'null' || $item_value eq '' ) {
      $pmenu_id = $menu_id;
    }  
    
    $sth_save_menu_order->execute( $pmenu_id, $ordr, $menu_id);

    $pmenu_id = $menu_id if ( $item_value eq 'null' ) ; ### Save for sub-menu items

    $ordr++;
  }

  return to_json({ status => 0 });
};

get '/select/permissions' => sub {

  my $menu_id = params->{menu_id};

  my $sql_select_role = undef;

  if ( session('role_id') == 5 ) {
    $sql_select_role = q( 
          SELECT role_id,
                 role_name
            FROM cldl_role
              WHERE (    company_id = ?
                      OR company_id = 1 )
                    AND active = 1  );
  } else {
    $sql_select_role = q( 
          SELECT role_id,
                 role_name
            FROM cldl_role
              WHERE     company_id = ?
                    AND active     = 1  );

  }

  my $sth_select_roles = database->prepare( $sql_select_role );

  my $edit_menu_perms;

  $sth_select_roles->execute( session('company_id') );
  while ( my $ref = $sth_select_roles->fetchrow_hashref ) {
    $edit_menu_perms->{ $ref->{role_id} } = $ref;
  }

  my $sth_select_roles_for_menu = database->prepare(
         'SELECT role_permission_id,
                 role_id,
                 menu_id
            FROM cldl_role_permission_menu
              WHERE menu_id = ?'
  );

  $sth_select_roles_for_menu->execute( $menu_id );
  while ( my $ref = $sth_select_roles_for_menu->fetchrow_hashref ) {
    $edit_menu_perms->{ $ref->{role_id} }->{role_checked} = 1 ;
  }

  my @ret_array_perms;

  foreach my $menu_key ( sort keys $edit_menu_perms ) {
    push( @ret_array_perms, $edit_menu_perms->{$menu_key} );
  }

  return to_json( \@ret_array_perms );

};

# Save permissions
get '/update/permissions' => sub {

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
#    debug $key;
    $key =~ m/(\d+)_.*/;
#    debug $1;
    $sth_insert_role_permission->execute( $1, $menu_id );
  }

  return to_json({ status => 0 });

};

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

get '/update/menucache' => sub {

  my $counter = redis_get('counter');  # Get the counter value from Redis.
  redis_set( ++$counter );             # Increment counter value by 1 and save it back to Redis.
  return $counter;

};




1;



