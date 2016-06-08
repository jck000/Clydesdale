package CLDL::Account;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Email;

prefix '/account';


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
# Preset register user form
#
get '/register' => sub {

  template 'cldl/register.tt';


};

get '/registration/check/:user_name' => sub {

  my $SQL = 
    qq( 
        SELECT user_name 
          FROM cldl_user
            WHERE user_name = ?
    );

#    my $sth_user_check->prepare( $SQL );
#    $sth_user_check->execue( $user_name );

};

post '/register' => sub {
 
#  my $SQL = 
#    qq( 
#         INSERT INTO cldl_user 
#             ( company_id, user_name, user_pass, first_name, last_name, user_email )
#           VALUES
#             ( ?, ?, ?, ?, ?, ? )
#    );
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


#
# Accept registration information
#
post '/register' => sub {

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
