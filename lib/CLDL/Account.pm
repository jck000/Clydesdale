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

  my $encrypted_pass = md5_hex( params->{user_name} . params->{user_pass} );

  $sth_insert_user->execute( 
    1,
    params->{user_name},
    $encrypted_pass,
    params->{first_name}, 
    params->{last_name},
    params->{email}
  );

  my $sender  = 
  my $from    = 
  my $subject = 
  my $body    = 

  email {
    sender  => 'bounces-here@foo.com', # optional
    from    => 'bob@foo.com',
    to      => 'sue@foo.com, jane@foo.com',
    subject => 'allo',
    body    => 'Dear Sue, ...<img src="cid:blabla">',
    type    => 'html', # can be 'html' or 'plain'
  };

  redirect config->{cldl}->{base_url}
               . config->{cldl}->{login_url}
               . '?user_name=' . params->{user_name};

};

post '/registration/check/id' => sub {

  debug "IN REGISTRATION CHECK " . params->{user_name};

  my $exists = check_id( params->{user_name} ) || 0 ;

  header( 'Content-Type'  => 'text/json' );
  header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );

  to_json({ 'exists' => $exists });
};

post '/registration/check/email' => sub {

  debug "IN REGISTRATION CHECK " . params->{user_name};

  my $exists = check_email( params->{email} ) || 0 ;

  header( 'Content-Type'  => 'text/json' );
  header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );

  to_json( { 'exists' => $exists } );
};

get '/activate' => sub {

  template 'cldl/account/activate.tt';

};

post '/activate' => sub {
 
  debug "IN ACTIVATE POST ";

  my $sth_insert_user = database->prepare(
    qq( 
         INSERT INTO cldl_user 
             ( company_id, user_name, user_pass, first_name, last_name, user_email )
           VALUES
             ( ?, ?, ?, ?, ?, ? )
    )
  );

  my $encrypted_pass = md5_hex( params->{user_name} . params->{user_pass} );

  $sth_insert_user->execute( 
    1,
    params->{user_name},
    $encrypted_pass,
    params->{first_name}, 
    params->{last_name},
    params->{email}
  );

  my $sender  = 
  my $from    = 
  my $subject = 
  my $body    = 

  email {
    sender  => 'bounces-here@foo.com', # optional
    from    => 'bob@foo.com',
    to      => 'sue@foo.com, jane@foo.com',
    subject => 'allo',
    body    => 'Dear Sue, ...<img src="cid:blabla">',
    type    => 'html', # can be 'html' or 'plain'
  };

  redirect config->{cldl}->{base_url}
               . config->{cldl}->{login_url}
               . '?user_name=' . params->{user_name};

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


sub check_id {
  my $user_id = shift;

  debug "IN check_id " . $user_id;

  my $sth_select_user = database->prepare(
    qq( 
        SELECT 1
          FROM cldl_user
            WHERE user_name = ?
    )
  );

  $sth_select_user->execute( $user_id );
  my $exists = $sth_select_user->fetchrow_hashref || 0;

  return $exists;
}

sub check_email {
  my $email = shift;

  debug "IN CHECK_EMAIL " . $email;

  my $sth_select_email = database->prepare(
    qq( 
        SELECT 1
          FROM cldl_user
            WHERE email = ?
    )
  );

  $sth_select_email->execute( $email );
  my $exists = $sth_select_email->fetchrow_hashref || 0;

  return $exists;
}

1;

