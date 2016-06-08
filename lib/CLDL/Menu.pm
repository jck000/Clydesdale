package CLDL::Menu;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

###
### sub user_menu {
###   my $company_id = shift;
###   my $menu;
###   my $is_cldl_menu;
### 
###   my $sth_menu = database->prepare( 
###                'SELECT menu_id,
###                        pmenu_id,
###                        ordr,
###                        menu_label,
###                        menu_link,
###                        menu_js_functions,
###                        menu_data_attributes
###                   FROM cldl_menu
###                     WHERE (    company_id = ?
###                             OR company_id = 1 )
###                           AND pmenu_id  = menu_id
###                           AND active    = 1
###                   UNION
###                 SELECT pmenu_id AS menu_id,
###                        pmenu_id,
###                        ordr,
###                        menu_label,
###                        menu_link,
###                        menu_js_functions,
###                        menu_data_attributes
###                   FROM cldl_menu
###                     WHERE (    company_id = ?
###                             OR company_id = 1 )
###                           AND pmenu_id != menu_id
###                           AND active    = 1
###                    ORDER BY pmenu_id, ordr' 
###   );
### 
###   $sth_menu->execute( $company_id, $company_id );
### 
###   while ( my $ref = $sth_menu->fetchrow_hashref ) {
### 
### # Test
### #    $ref->{menu_link} = add_menu_param( $ref->{menu_link} ) ;
### 
###     $is_cldl_menu->{ $ref->{menu_link} } = 1;
###     push( @{$menu}, $ref);
###   }  
### 
###   return $menu, $is_cldl_menu;
### 
### }
### 
### sub add_menu_link {
###   my $menu_link = shift;
### 
###   # If there's already a menu indicator, then return
###   if ( $menu_link =~ 'is_cldl_menu' ) {
###     return $menu_link;
###   }
### 
###   #  Add menu indicator
###   if ( $menu_link =~ /\?/ ) {
###     if ( $menu_link =~ /\&/ ) {
###       $menu_link .= '&' ;
###     } 
###   } else {
###     $menu_link .= '?' ;
###   }
###   $menu_link .= 'is_cldl_menu=1' ;
### 
###   return $menu_link;
### 
### }
###

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

#
#    if ( ( defined $ref->{pmenu_id} && $ref->{pmenu_id} eq '' ) 
#           || ! defined $ref->{pmenu_id} ) {
#      $menu->{ $ref->{menu_id} } = $ref;
#    } elsif ( $ref->{pmenu_id} ne '' ) {
#      $menu->{ $ref->{pmenu_id} }->{children}->{ $ref->{menu_id} } = $ref;
#    }
#    $is_cldl_menu->{ $ref->{menu_link} } = 1;
#

  return $menu;

}
1;

