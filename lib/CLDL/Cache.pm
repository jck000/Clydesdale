package CLDL::Cache;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

prefix '/cache';

get '/reset/all' => sub {

  &update_caches();
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

# Extract data to be cached, organize it and store into cache
sub update_caches() {
  my $company_id = shift || 'all';

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
  while ( my $company_ref = $sth_company->fetchrow_hashref ) {
    debug "COMPANY_REF";
    debug $company_ref;

    $sth_role->execute( $company_ref->{company_id} );
    while ( my $role_ref = $sth_role->fetchrow_hashref ) {

      debug "ROLE REF";
      debug $role_ref;

      $sth_cache_menu->execute( $company_ref->{company_id}, $role_ref->{role_id},
                                $company_ref->{company_id}, $role_ref->{role_id} );
      while ( my $ref = $sth_cache_menu->fetchrow_hashref ) {

        if ( $ref->{menu_id} == $ref->{pmenu_id} ) {
          $cache_menu->{ $company_ref->{company_id} }->{ $role_ref->{role_id} }->{ $ref->{menu_id} } = $ref;
        } else {
          push  @{ $cache_menu->{ $company_ref->{company_id} }->{ $role_ref->{role_id} }->{ $ref->{pmenu_id} }->{children} }, $ref;
        }  # end if

      }    # while $ref end
    }      # while $role_ref end
  }        # while $company_ref end

  foreach my $company_id ( keys %{$cache_menu} ) {
    foreach my $role_id ( keys %{ $cache_menu->{$company_id} } ) {
      my $key = 'menu-' . $company_id . '-' . $role_id;

      redis_set( $key, $cache_menu->{$company_id}->{$role_id}  );

      debug "Saving to cache this one ";
      debug $key;
      debug $cache_menu->{$company_id}->{$role_id} ;

      my $x = redis_get($key);
      debug "X: $x";
#      my $x_hash=eval( $x );




#      debug "Got";
#      debug $x_hash;

#      my @routes;
#      foreach my $menu ( @{ $cache_menu->{$company_id}->{$role_id} } ) {
#        push( @routes, $menu->{menu_link} );
#        my $key = 'route-' . $company_id . '-' . $role_id;
#        redis_set( $key, @routes);
#      }
    }
  }
}


sub get_menu {
  my $menu_id = shift;

  return redis_get( $menu_id );
}


1;


