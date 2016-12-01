package CLDL;

# Dancer2
use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::JWT;
use Dancer2::Plugin::Tail;
#use Dancer2::Plugin::EditFile;

use CLDL::Account;      ### Accounts
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

use Digest::MD5 qw( md5_hex );

our $VERSION = '0.00002';

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
 
  # If there's no company_id and it's not login, then send to login page
  if (     ! session('company_id') 
        && (    request->path_info !~ m{^/login} 
             && request->path_info !~ m{^/account/register} 
             && request->path_info !~ m{^/account/forgotpassword} 
             && request->path_info !~ m{^/account/registration/check} 
             && request->path_info !~ m{^/tail/display}
             && request->path_info !~ m{^/tail/read} ) ) {

    redirect config->{cldl}->{base_url} 
               . config->{cldl}->{login_url} 
               . '?req_path=' . request->path_info;
  }

  debug "Session ID: " . session->{id};

  if (  defined params->{is_cldl_menu} && params->{is_cldl_menu} == 1 ) {
    my $req_path = request->path_info;
    $req_path =~ s/^\///;
    session cldl_return_to_page => $req_path;
  }


};


#
# Add some data to template
#
hook 'before_template_render' => sub {
  my $tokens = shift;

  debug "IN BEFORE_TEMPLATE_RENDER:";

  $tokens->{cldl_menu}           = session('cldl_menu');           # Application
                                                                   #  menu
  $tokens->{cldl_return_to_page} = session('cldl_return_to_page'); # Return 
                                                                   # to main 
                                                                   # level
  $tokens->{cldl_reload_page}    = session('cldl_reload_page');    # Reload form
  $tokens->{cldl_logged_in}      = session('company_id');
  $tokens->{cldl_company_defaults} 
                                 = session('company_defaults');

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


