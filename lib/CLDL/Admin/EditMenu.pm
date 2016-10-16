package CLDL::Admin::EditMenu;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

use Data::Dumper;

our $VERSION = '0.00001';

prefix '/cldl/admin/editmenu';

get '/select' => sub {

  debug "In admin-menu-dislay";

#               'SELECT menu_id,
#                       ordr,
#                       pmenu_id,
#                       menu_label,
#                       company_id,
#                       active
#                  FROM cldl_menu
#                    WHERE (    company_id = ?
#                            OR company_id = 1 )
#                      ORDER BY menu_id, ordr');
 
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
                         edit_menu        => $edit_menu,
                       },
                       { layout  => 'editmenu.tt' };  

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
#      $pmenu_id = undef;
      $pmenu_id = $menu_id;
    }  
    
    warn "UPDATE cldl_menu SET pmenu_id = $pmenu_id, ordr = $ordr WHERE menu_id = $menu_id";
    $sth_save_menu_order->execute( $pmenu_id, $ordr, $menu_id);

    $pmenu_id = $menu_id if ( $item_value eq 'null' ) ; ### Save for sub-menu items

    $ordr++;
  }

  return to_json({ status => 'success' });
};


1;



