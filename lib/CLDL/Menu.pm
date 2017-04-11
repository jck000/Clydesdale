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

  foreach my $key ( keys %{$test_menu} ) {
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
  my $as_hash = shift || 0;

  my $cldl_menu;
  if ( $as_hash ) { 
    # Return a hash
    $cldl_menu = decode_json(redis_get( $menu_id )) || {};
  } else { 
    # Return a scalar
    $cldl_menu = from_json(redis_get( $menu_id ))   || '';
  }

  return $cldl_menu;
}

1;
