package CLDL::Menu;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

#
# Get menu for user at login and store in session for faster access
#
sub get_menu {

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
1;

