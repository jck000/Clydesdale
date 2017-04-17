package CLDL::Menu;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

our $VERSION = '0.00001';

#
# Get menu for user at login and store in session for faster access
#
sub oget_menu {

  my $sth_menu = database->prepare(
             qq( 
                SELECT m.menu_id,
                       m.pmenu_id,
                       m.ordr,
                       m.menu_label,
                       m.menu_link,
                       m.menu_js_functions,
                       m.menu_data_attributes,
                       m.menu_notes
                  FROM cldl_menu m,
                       cldl_role_permission_menu rpm
                    WHERE (    m.company_id = ?
                            OR m.company_id = 1 )
                          AND m.pmenu_id    = m.menu_id
                          AND m.active      = 1

                          AND rpm.role_id   = ?
                          AND rpm.menu_id   = m.menu_id
                  UNION
                SELECT m.menu_id,
                       m.pmenu_id,
                       m.ordr,
                       m.menu_label,
                       m.menu_link,
                       m.menu_js_functions,
                       m.menu_data_attributes,
                       m.menu_notes
                  FROM cldl_menu m,
                       cldl_role_permission_menu rpm
                    WHERE (    m.company_id = ?
                            OR m.company_id = 1 )
                          AND m.pmenu_id   != m.menu_id
                          AND m.active      = 1

                          AND rpm.role_id   = ?
                          AND rpm.menu_id   = m.menu_id
                   ORDER BY 3, 2 )
          );

  $sth_menu->execute( session('company_id'), session('role_id'), 
                      session('company_id'), session('role_id') );

  my $menu;

#
# $menu->{main_menu_keys} = array of menu keys sorted by ordr
# $menu->{child_menus}->{main_menu_id}->{child_menu_keys} = array of menu keys
# $menu->{menu_id}        = hash of menu
# $menu->{menu_paths}     = Used to validate access
#
  my @main_menu_keys;
  my @child_menu_keys;

  while ( my $ref = $sth_menu->fetchrow_hashref ) {

    ### Assumption is that every url is local. Need to fix later
    if ( $ref->{menu_link} =~ m{\?} ) {
      $ref->{menu_link} .= '&is_cldl_menu=1';
    } else {
      $ref->{menu_link} .= '?is_cldl_menu=1';
    }

    if ( $ref->{menu_id} == $ref->{pmenu_id} ) { 
      # Main Menu
      push( @{$menu->{main_menu_keys}}, $ref->{menu_id});
    } else {
      # Child Menu
      push( @{$menu->{child_menu_keys}->{$ref->{pmenu_id}}}, $ref->{menu_id});
    }
    $menu->{$ref->{menu_id}} = $ref;
    $menu->{menu_paths}->{$ref->{menu_link}} = 1 if ( $ref->{menu_link} ne '');
  }  

  return $menu;

}

sub is_menu {
  my $test_path = shift;
  my $menu_id   = shift;

  my $test_menu = &get_menu( $menu_id, 1 );

  my $is_menu    = 0;

  debug "IN IS MENU:";
  debug $test_menu;


  foreach my $key ( keys \%{$test_menu} ) {
    my $menu = $test_menu->{$key} ;
    if ( $menu->{active} == 0  ) { 
      next;
    }

    if ( $menu->{menu_link} ne '' ) {

    } elsif ( defined $menu->{children} ) {
      foreach my $cmenu ( @{$menu->{children}} ) {
        if ( $cmenu->{active} ) {
          my $tmp_regex  = '^/';
          $tmp_regex    .= $cmenu->{menu_link};
          $tmp_regex =~ s/\?.+//g;

          my $regex = qr{$tmp_regex};
 debug "MENU TEST: $test_path AGAINST $regex";
          if ( $test_path =~ $regex ) {
            debug "THIS IS A MENU " . $test_path;
            $is_menu = 1;
            last;
          }
        }
      }
    }
  }

  return $is_menu;
}

sub get_menu {
  my $menu_id = shift;

  my $cldl_menu;

  return redis_get( $menu_id ) || {};

}

# Extract data to be cached, organize it and store into cache
sub update_caches {
  my $company_id = shift || 'all';  # If no company_id passed in, set to all

#
# $cache_menu->{main_menu_keys} = array of menu keys sorted by ordr
# $cache_menu->{child_menus}->{main_menu_id}->{child_menu_keys} = array of menu keys
# $cache_menu->{menu_id}        = hash of menu
# $cache_menu->{menu_paths}     = Used to validate access
#

  debug "In update_caches $company_id";

  my @company_list = get_company_list( $company_id );


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
                    WHERE     m.company_id = ?
                          AND rpm.menu_id  = m.menu_id
                          AND rpm.role_id  = ?

                   ORDER BY 1, 2, 3 );

  my $sth_cache_menu = database->prepare( $MENU_SQL );

  my $cache_menu;
  my $cache_routes;

  foreach my $company_id (sort @company_list) {

    $sth_role->execute( $company_id );
    while ( my $role_ref = $sth_role->fetchrow_hashref ) {

      $sth_cache_menu->execute( $company_id, $role_ref->{role_id});

      while ( my $ref = $sth_cache_menu->fetchrow_hashref ) {

        if ( $ref->{menu_id} == $ref->{pmenu_id} ) {
          # Main Menu
          $cache_menu->{ $company_id }->{ $role_ref->{role_id} }->{ $ref->{menu_id} } = $ref;
        } else {
          # Child Menu
          push  @{ $cache_menu->{ $company_id }->{ $role_ref->{role_id} }->{ $ref->{pmenu_id} }->{children} }, $ref;
        }  # end if

        $cache_routes->{ $company_id }->{ $role_ref->{role_id} }->{ $ref->{menu_link} } = 1;

      }    # while $ref end
    }      # while $role_ref end
  }        # foreach $company_id end

  debug "Cache Menu: " ; 
  debug $cache_menu;

  # Put into Cache
  foreach my $company_id ( keys %{$cache_menu} ) {
    foreach my $role_id ( keys %{ $cache_menu->{$company_id} } ) {
      my $mkey = 'menu-' . $company_id . '-' . $role_id;
      redis_set( $mkey, $cache_menu->{$company_id}->{$role_id} );
    }
  }

#  Still working on this
#  # Put into Cache
#  foreach my $company_id ( keys %{$cache_routes} ) {
#    foreach my $role_id ( keys %{ $cache_routes->{$company_id} } ) {
#      my $rkey = 'route-' . $company_id . '-' . $role_id;
#      redis_set( $rkey, $cache_routes->{$company_id}->{$role_id}  );
#    }
#  }

}

sub get_paths {
  my $path_id = shift;

  return redis_get( $path_id );
}

sub get_company_list {
  my $company_id = shift;


  my $COMPANY_SQL ;
  if ( $company_id eq 'all' ) {
    $COMPANY_SQL = qq(
                        SELECT company_id 
                          FROM cldl_company
                            WHERE active = 1
                    );
  } else {
    $COMPANY_SQL = qq(
                        SELECT company_id 
                          FROM cldl_company
                            WHERE (   company_id  = ?
                                   OR company_id  = 1 )
                                  AND active      = 1
                    );
  } 

  my $sth_company = database->prepare( $COMPANY_SQL );
  if ( $company_id eq 'all' ) {
    $sth_company->execute();
  } else {
    $sth_company->execute( $company_id );
  }

  my @company_list;
  while ( my $company_ref = $sth_company->fetchrow_hashref ) {
    push( @company_list, $company_ref->{company_id} );
  }

  return @company_list;
}

1;
