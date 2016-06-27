package CLDL::Account;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
#use Dancer2::Plugin::Email;

use Digest::MD5 qw( md5_hex );

prefix '/cldl/account';


# 
# Preset register user form
#
get '/register' => sub {

  template 'cldl/account/register.tt';

};

post '/register' => sub {
 
  debug "IN REGISTER POST ";

  my $sth_insert_user = database->prepare(
    qq( 
         INSERT INTO cldl_user 
             ( company_id, user_name, user_pass, first_name, last_name, user_email )
           VALUES
             ( ?, ?, ?, ?, ?, ? )
    )
  );

  my $enc_pass = md5_hex( params->{user_name} . params->{user_pass} );

  $sth_insert_user->execute( 
    1,
    params->{user_name},
    $enc_pass,
    params->{first_name}, 
    params->{last_name},
    params->{email}
  );

#
#    email {
#        from    => 'sf@signedforms.com',
#        to      => $page->{params}->{register_email},
#        subject => 'SignedForms.com App Registration',
#        body    => 'Your device has been registered with our demo server.  '
#                     . 'You must enter the following activation code into '
#                     . 'the app in order to activate it.  '
#                     . "\n\n" . 'ACTIVATION CODE:   ' 
#                     . $page->{results}->{activation_code}
#                     . "\n\n\nSignedForms.com\nActivation System\n\n"
#                     . 'http://www.signedforms.com'
# 
#    };

#  template 'index.html', $page;
};

post '/registration/check' => sub {

  debug "IN REGISTRATION CHECK " . params->{user_name};

  my $sth_select_user = database->prepare(
    qq( 
        SELECT user_name
          FROM cldl_user
            WHERE user_name = ?
    )
  );

  $sth_select_user->execute( params->{user_name} );
  my $user_exists = $sth_select_user->fetchrow_hashref ;

  header( 'Content-Type'  => 'text/json' );
  header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );

  if (    defined $user_exists->{user_name} 
       && $user_exists->{user_name} eq params->{user_name} ) {
    to_json({ 'exists' => 1 });
  } else {
    to_json({ 'exists' => 0 });
  }
};


#
# Present forgot password form
#
get '/forgotpassword' => sub {


};


# 
# Accept email to send reset password form
#
post '/forgotpassword' => sub {


};




#
# Device Register
#
post '/device/register' => sub {

};

# 
# Present change password form
#
get '/changepassword' => sub {

};


# 
# Accept new password
#
post '/changepassword' => sub {

};


1;
