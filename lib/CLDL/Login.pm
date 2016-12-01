package CLDL::Login;

# Dancer2
use Dancer2 appname => 'CLDL';

use Dancer2::Plugin::Database;

use CLDL::Menu;         ### Menus

use Digest::MD5 qw( md5_hex );

our $VERSION = '0.00001';

# Every request runs through here
prefix undef;

#
# Present login form
#
get '/login' => sub {
  debug "Send cldl/login.tt template";
  template 'cldl/login.tt', { 
                               title    => 'Login',
                               req_path => params->{req_path}  
                            };

};


#
# Accept login/password 
#
post '/login' => sub {

  my $ret = get_user( params->{user_name}, params->{user_pass} );

  # Logged in if company exists
  if ( $ret->{company_id} && $ret->{company_id} > 0 ) {

    debug "GOT A COMPANY ID";

    session company_id       => $ret->{company_id};
    session language         => $ret->{language};
    session user_type        => $ret->{user_type};
    session user_id          => $ret->{user_id};
    session user_name        => $ret->{user_name};
    session full_name        => $ret->{full_name};
    session role_id          => $ret->{role_id};
    session company_defaults => eval( $ret->{company_defaults});

    session cldl_menu  => CLDL::Menu::get_menu;

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
      redirect config->{cldl}->{splash_url} ;
    }

  } else {  # Not logged in
    debug "User does not exist or Password is incorrect";
    ## Record failed logins for fail2ban

    template 'cldl/login.tt', { 
         'title'         => 'Login', 
         'error_message' => 'Login ID does not exist and/or password is incorrect'};

  }

};

#
# Logout
#
get '/logout' => sub {
  app->destroy_session;
  redirect config->{cldl}->{base_url} . '/splash';
  # redirect config->{cldl}->{base_url} . config->{cldl}->{login_url};
};


post '/login/device' => sub {

  my $ret = get_user( params->{user_name}, params->{user_pass} );

  # Logged in if company exists
  if ( $ret->{company_id} && $ret->{company_id} > 0 ) {

    debug "GOT A COMPANY ID";

    session company_id       => $ret->{company_id};
    session language         => $ret->{language};
    session user_type        => $ret->{user_type};
    session user_id          => $ret->{user_id};
    session user_name        => $ret->{user_name};
    session full_name        => $ret->{full_name};
    session role_id          => $ret->{role_id};
    session company_defaults => eval( $ret->{company_defaults});

    session cldl_menu  => CLDL::Menu::get_menu;

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
      redirect config->{cldl}->{splash_url} ;
    }

  } else {  # Not logged in
    debug "User does not exist or Password is incorrect";
    ## Record failed logins for fail2ban

    template 'cldl/login.tt', { 
         'title'         => 'Login', 
         'error_message' => 'Login ID does not exist and/or password is incorrect'};

  }

};

sub get_user {
  my $user_name = shift;
  my $user_pass = shift;

  my $sth_login = database->prepare( 
                      qq(
                         SELECT u.company_id, 
                                u.user_id, 
                                u.user_name,
                                u.language, 
                                CONCAT(u.first_name, " ", u.last_name) AS full_name,
                                u.pass_change,
                                rm.role_id,
                                c.company_default_values AS company_defaults
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

  my $enc_pass = md5_hex( $user_name . $user_pass );

  $sth_login->execute( $user_name, $enc_pass );
  my $ret = $sth_login->fetchrow_hashref;

  return $ret;
}


1; 

