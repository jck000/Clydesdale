package CLDL;

use Dancer2;
use Dancer2::Plugin::Database;

use Data::Dumper;

### Base
#use CLDL::Account;
use CLDL::DV;
use CLDL::Menu;
use CLDL::Upload;

### Admin
### use CLDL::Admin::Config;  
### use CLDL::Admin::Crontab;  
use CLDL::Admin::EditMenu;  
use CLDL::Admin::DVFromtable;  
use CLDL::Admin::Generic;  

# use CLDL::Admin::Logs;  

use Digest::MD5 qw( md5_hex );

our $VERSION = '0.001';

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
             && request->path_info !~ m{^/cldl/account/register} 
             && request->path_info !~ m{^/cldl/account/forgotpassword} ) ) {
    redirect config->{cldl}->{base_url} 
               . config->{cldl}->{login_url} 
               . '?req_path=' . request->path_info;
  }

  #  Setup Basic Navigation  
  if (    ! defined session('cldl_return_to_page') 
       || session('cldl_return_to_page') eq '' ) { 
  # if ( session('cldl_return_t_page') eq request->path_info ) { 
    session cldl_return_to_page => request->path_info;
    session cldl_reload_page    => '';
  } else {
    session cldl_reload_page    => request->path_info;
  }

  #  Verify permission
  
  #  Delete is_cldl_menu=1
#  request->path_info =~ s/is_cldl_menu=1//g;
#  request->path_info =~ s/&&/&/g;


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
  $tokens->{cldl_reload_page} = session('cldl_reload_page');    # Reload form
  $tokens->{cldl_logged_in}   = session('company_id');

};

#
# Show template
#
get '/' => sub {
  #template 'index.tt';
  template 'cldl/splash.tt';
};


#
# Show splash page
# 
any '/splash' => sub {
  template 'cldl/splash.tt';
};


#
# Present login form
#
get '/login' => sub {
  template 'cldl/login.tt', { 
                               title    => 'Login',
                               req_path => params->{req_path}  
                            };

};


#
# Accept login/password 
#
post '/login' => sub {

  my $sth_login = database->prepare( 
                      qq(
                         SELECT u.company_id, 
                                u.user_id, 
                                u.user_name,
                                u.language, 
                                CONCAT(u.first_name, " ", u.last_name) AS full_name,
                                u.pass_change,
                                rm.role_id
                           FROM cldl_user u,
                                cldl_company c,
                                cldl_role_members rm,
                                cldl_role r

                             WHERE u.user_name      = ?
                                   AND u.user_pass  = ?
                                   AND u.active     = 1

                                   AND u.company_id = c.company_id
                                   AND c.active     = 1 
      
                                   AND rm.user_id   = u.user_id 
                                   AND rm.role_id   = r.role_id 
                                   AND r.active     = 1 )
                      );

  my $enc_pass = md5_hex( params->{user_name} . params->{user_pass} );

  $sth_login->execute( params->{user_name}, $enc_pass );
  my $ret = $sth_login->fetchrow_hashref;

  if (    $ret->{company_id} 
       && $ret->{company_id} > 0 ) {

    debug "GOT A COMPANY ID";

    session company_id => $ret->{company_id};
    session language   => $ret->{language};
    session user_type  => $ret->{user_type};
    session user_id    => $ret->{user_id};
    session user_name  => $ret->{user_name};
    session full_name  => $ret->{full_name};
    session role_id    => $ret->{role_id};

    my $menu = &CLDL::Menu::get_menu;
    session cldl_menu    => $menu;

    if ( $ret->{pass_change} == 1 ) {
      debug "pass_change == 1";
      redirect config->{cldl}->{base_url} . '/changepass'
               . '?req_path='  . params->{req_path}
               . '&user_name=' . session('user_name')  ;
    } elsif ( params->{req_path} ne '' ) {
      debug "Redirect to req_path";
      redirect config->{cldl}->{base_url} . params->{req_path};
    } else {
      debug "Redirect to splash";
      redirect config->{cldl}->{base_url} . '/splash';
    }

  } else {
    debug "User does not exist or Password is incorrect";
    ## Record failed logins for fail2ban

    template 'cldl/login.tt', { 
         'title'         => 'Login', 
         'error_message' => 'Login ID does not exist and/or password is incorrect'};

  }

};


#
# Change Password Form
#
get '/changepass' => sub {
  template 'cldl/changepass.tt', {
                                   'title'   => 'Change Password',
                                   req_path  => params->{req_path},
                                   user_name => session('user_name') 
                                 };

};


#
# Accept password
#
post '/changepass' => sub {

  my $sth_cp = database->prepare(
                        'UPDATE cldl_user
                           SET user_pass   = ?,
                               pass_change = ?
                             WHERE user_name      = ?
                                   AND company_id = ?'
                      );

  my $enc_pass = md5_hex( params->{user_name} . params->{user_pass} );

  $sth_cp->execute( $enc_pass, 
                    0, 
                    params->{user_name}, 
                    session('company_id') );

  if ( params->{req_path} ne '' ) {
    redirect config->{cldl}->{base_url} . params->{req_path};
  } else {
    redirect config->{cldl}->{base_url} . '/';
  }

};


#
# Logout
#
get '/logout' => sub {
  context->destroy_session;
  redirect config->{cldl}->{base_url} . '/splash';
  # redirect config->{cldl}->{base_url} . config->{cldl}->{login_url};
};

true;

