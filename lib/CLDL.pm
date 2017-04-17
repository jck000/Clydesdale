package CLDL;

# Dancer2
use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::JWT;
use Dancer2::Plugin::Tail;
#use Dancer2::Plugin::EditFile;

use Data::Dumper;
use POSIX qw(strftime);

use CLDL::Account;      ### Accounts
use CLDL::Cache;
use CLDL::DV;           ### DataViews
use CLDL::Menu;         ### Menus
use CLDL::Login;        ### Login/Logout
use CLDL::Upload;       ### Uploads

### Admin
### use CLDL::Admin::Config;  
### use CLDL::Admin::Crontab;  
use CLDL::Admin::EditMenu;     ### Edit Menus
use CLDL::Admin::DVFromtable;  ### Create DataView from table
use CLDL::Admin::Generic;      ### Generic


our $VERSION = '0.00004';


# require class if defined
if ( config->{cldl}->{appclass} ) {
  my $app_class = config->{cldl}->{appclass};
  my $package   = $app_class;

  $package      =~ s{::}{/}g;
  $package      .= '.pm';
  require $package;
}


# Every request runs through here
prefix undef;

#
# Check that there is a session
#
hook 'before' => sub {

  debug "BEFORE: " . request->path_info;

  my $is_nosession = 0;
  my $is_jwt       = 0;
  my $is_menu      = 0;
  my $is_dv        = 0;
  my $forward_to   = request->path_info;

  # Does this require JWT based on host name?
  if (    defined config->{cldl}->{jwt}->{host} 
       && request->host eq config->{cldl}->{jwt}->{host} ) {
    $is_jwt = 1;
  }

  # Does this require JWT based on path?
  my $regex_jwt = qr{ config->{cldl}->{jwt}->{path} } if ( defined config->{cldl}->{jwt}->{path} ) ;
  if (    defined config->{cldl}->{jwt}->{path}
       && request->path_info =~ $regex_jwt ) {
    $is_jwt = 1;
  }

  # Loop through path lists that do not need to have sessions
  foreach my $nosession_path ( @{config->{cldl}->{nosession_paths}} ) {
    my $regex = qr{$nosession_path};
    if ( request->path_info =~ $regex ) {
      $is_nosession = 1;
      last;
    }
  }

#  Work In Process
#  if ( $is_jwt ) {
#    $forward_to =~ s/$
#  }


  # If there's no company_id and it's not login, then send to login page
  unless (     session('company_id') || $is_nosession ) {
    redirect config->{cldl}->{base_url} 
               . config->{cldl}->{login_url} 
               . '?req_path=' . request->path_info;
  }

  $is_menu = &CLDL::Menu::is_menu( request->path, session('menu_id') ) if ( session('menu_id') ) ;
#  $is_dv   = &CLDL::DV::is_dv( request->path, session('role

  unless ( $is_menu || $is_dv ) {
    # redirect config->{cldl}->{base_url} . config->{cldl}->{not_authorized} ;
  }
  
########
#  if (  defined params->{is_cldl_menu} && params->{is_cldl_menu} == 1 ) {
#    my $req_path = request->path_info;
#    $req_path =~ s/^\///;
#    session cldl_return_to_page => $req_path;
#  }

};


#
# Add some data to template
#
hook 'before_template_render' => sub {
  my $tokens = shift;

#  debug "IN BEFORE_TEMPLATE_RENDER:";
#  debug "MENU ID: " . session('menu_id') if ( session('menu_id')) ;

  $tokens->{cldl_menu}           = &CLDL::Menu::get_menu( session('menu_id') ) if ( session('menu_id') ) ;

#  debug "cldl_menu";
#  debug $tokens->{cldl_menu};

  $tokens->{cldl_return_to_page} = session('cldl_return_to_page'); # Return 
                                                                   # to main 
                                                                   # level
  $tokens->{cldl_reload_page}    = session('cldl_reload_page');    # Reload form
  $tokens->{cldl_logged_in}      = session('company_id');
  $tokens->{cldl_company_defaults} 
                                 = session('company_defaults');
  $tokens->{generate_tt}         = 1 if ( vars->{generate_tt} );
#  print '
#<!-- TEMPLATE NAME: [% context.name %] --> 
#
#';

#  open( my $LOG, ">", "/tmp/tokens.log");
#  print $LOG Dumper( $tokens ) ;
#  close($LOG);

};

hook 'after_template_render' => sub {
  my $ref_content = shift;
  my $generate_tt = vars->{generate_tt} || 0;

#  debug "AFTER_TEMPLATE_RENDER: " . $generate_tt;

  if ( $generate_tt ) { 
    my $content     = ${$ref_content};

    my $filename = config->{views} . '/genrated_tt.' . strftime('%Y-%m-%d_%H-%M-%S', gmtime()); 
    open(my $OUT, '>', $filename);
    print $OUT $content;
    close($OUT);
  }

  return $ref_content;
};








#
# Show template
#
get '/' => sub {
  template 'cldl/splash.tt';
};


#
# Show splash page
# 
any '/splash' => sub {
  template 'cldl/splash.tt';
};


1; # End of CLDL
