package CLDL::Cache;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

prefix '/cache';

get '/reset/all' => sub {

  &update_caches();
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

get '/reset/company' => sub {

  &update_caches(session('company_id') );
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

# Extract data to be cached, organize it and store into cache
sub update_caches() {
  my $company_id = shift || 'all';  # If no company_id passed in, set to all

#
# $cache_menu->{main_menu_keys} = array of menu keys sorted by ordr
# $cache_menu->{child_menus}->{main_menu_id}->{child_menu_keys} = array of menu keys
# $cache_menu->{menu_id}        = hash of menu
# $cache_menu->{menu_paths}     = Used to validate access
#

  debug "In update_caches $company_id";

  my $COMPANY_SQL ;
  if ( $company_id eq 'all' ) {
    $COMPANY_SQL = qq(
                        SELECT company_id 
                          FROM cldl_company
                            WHERE     company_id != 1
                                  AND active      = 1
                    );
  } else {
    $COMPANY_SQL = qq(
                        SELECT company_id 
                          FROM cldl_company
                            WHERE (   company_id  = ?
                                   OR company_id != 1 )
                                  AND active      = 1
                    );
  } 
  my $sth_company = database->prepare( $COMPANY_SQL );
  if ( $company_id eq 'all' ) {
    $sth_company->execute();
  } else {
    $sth_company->execute( $company_id );
  }

  my $ROLE_SQL = qq(
                     SELECT role_id 
                       FROM cldl_role
                         WHERE (    company_id = ?
                                 OR company_id = 1 )
                               AND active     = 1
                 );
  my $sth_role = database->prepare( $ROLE_SQL );

  # Active clients that have active roles and active menus
  my $MENU_SQL = qq(
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

                          AND m.pmenu_id   = m.menu_id
                          AND rpm.menu_id  = m.menu_id
 
                          AND rpm.role_id  = ?

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

                          AND m.pmenu_id  != m.menu_id
                          AND rpm.menu_id  = m.menu_id
 
                          AND rpm.role_id  = ?

                   ORDER BY 1, 2, 3 );

  my $sth_cache_menu = database->prepare( $MENU_SQL );

  my $cache_menu;
  my $cache_routes;

  while ( my $company_ref = $sth_company->fetchrow_hashref ) {

    $sth_role->execute( $company_ref->{company_id} );
    while ( my $role_ref = $sth_role->fetchrow_hashref ) {

      $sth_cache_menu->execute( $company_ref->{company_id}, $role_ref->{role_id},
                                $company_ref->{company_id}, $role_ref->{role_id} );
      while ( my $ref = $sth_cache_menu->fetchrow_hashref ) {

        if ( $ref->{menu_id} == $ref->{pmenu_id} ) {
          # Main Menu
          $cache_menu->{ $company_ref->{company_id} }->{ $role_ref->{role_id} }->{ $ref->{menu_id} } = $ref;
        } else {
          # Child Menu
          push  @{ $cache_menu->{ $company_ref->{company_id} }->{ $role_ref->{role_id} }->{ $ref->{pmenu_id} }->{children} }, $ref;
        }  # end if

        $cache_routes->{ $company_ref->{company_id} }->{ $role_ref->{role_id} }->{ $ref->{menu_link} } = 1;

      }    # while $ref end
    }      # while $role_ref end
  }        # while $company_ref end

  # Put into Cache
  foreach my $company_id ( keys %{$cache_menu} ) {
    foreach my $role_id ( keys %{ $cache_menu->{$company_id} } ) {
      my $mkey = 'menu-' . $company_id . '-' . $role_id;
      redis_set( $mkey, $cache_menu->{$company_id}->{$role_id}  );
    }
  }

  # Put into Cache
  foreach my $company_id ( keys %{$cache_routes} ) {
    foreach my $role_id ( keys %{ $cache_routes->{$company_id} } ) {
      my $rkey = 'route-' . $company_id . '-' . $role_id;
      redis_set( $rkey, $cache_routes->{$company_id}->{$role_id}  );
    }
  }

}


sub get_menu {
  my $menu_id = shift;

#  use Data::Dumper;
#  open(my $M, ">", "/tmp/M.log");
#  my $x = redis_get( $menu_id );
#  print $M "Menu ID: $menu_id";
#  print $M Dumper($x);
#  close($M);

  return redis_get( $menu_id );
}

sub get_paths {
  my $path_id = shift;

  return redis_get( $path_id );
}

1;
######################################
#
# $menu->{main_menu_keys} = array of menu keys sorted by ordr
# $menu->{child_menus}->{main_menu_id}->{child_menu_keys} = array of menu keys
# $menu->{menu_id}        = hash of menu
# $menu->{menu_paths}     = Used to validate access
#
###   my @main_menu_keys;
###   my @child_menu_keys;
### 
###   while ( my $ref = $sth_menu->fetchrow_hashref ) {
### 
###     if ( $ref->{menu_id} == $ref->{pmenu_id} ) { 
###       # Main Menu
###       push( @{$menu->{main_menu_keys}}, $ref->{menu_id});
###     } else {
###       # Child Menu
###       push( @{$menu->{child_menu_keys}->{$ref->{pmenu_id}}}, $ref->{menu_id});
###     }
###     $menu->{$ref->{menu_id}} = $ref;
###     $menu->{menu_paths}->{$ref->{menu_link}} = 1 if ( $ref->{menu_link} ne '');
###   }  
### 
###   return $menu;
### 
### }
### 1;
### 
