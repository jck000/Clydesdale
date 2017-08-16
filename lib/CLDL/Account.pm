package CLDL::Account;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Email;

=head1 CLDL::Account

=head1 Description

This module handles everything having to do with registering and activating  users and devices.  It will validate user-id to make sure it is available.  

=cut

use String::Random;
use Digest::MD5 qw( md5_hex );
my $random = String::Random->new;

prefix '/account';

#
# Redirect from menu to DV.  Cleanup needed???
#

=head2 /view

  Redirect to DV my_account 

=cut
get '/view' => sub {
  debug "In Account Maintenance";

  redirect config->{cldl}->{base_url} . '/dv/select/my_account?id=' . session('user_id');
};

# 
# Preset register user form
#
get '/register/user' => sub {

  template 'cldl/account/register.tt';

};

#
# Save User information and send an email to verify email
#
post '/register/user' => sub {
 
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

  my $sender  = config->{cldl}->{registration_email}->{sender};
  my $from    = config->{cldl}->{registration_email}->{from};
  my $subject = config->{cldl}->{registration_email}->{subject};
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

post '/registration/check/userid' => sub {

  debug "IN REGISTRATION CHECK " . params->{user_name};

  my $exists = check_userid( params->{user_name} ) || 0 ;

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

post '/activate/user' => sub {
 
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
# Present change password form
#
get '/changepassword' => sub {

};


# 
# Accept new password
#
post '/changepassword' => sub {

};


sub check_userid {
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


get '/register/device/:company_id/:register_email/:uuid/:device_info/:i_have_an_agency_id' => sub {

  my ( $sth_ins, $sth_last_id, $sth_ins_act, $data );
  my $ret     = {};
  my $is_demo = 0;

  $sth_last_id = database->prepare( 'SELECT LAST_INSERT_ID()' );

  if (    params->{company_id} == 0 
       && params->{i_have_an_agency_id} eq 'No' ) {

#
# Add New company record
#
    ### defaults
    my $company_id    = $random->randregex( sprintf '[0-9]{%d}', 7 );
    my $logo_path     = qq(images/logos/$company_id/logo.png);
    my $template_path = qq(templates/$company_id);
    my $view_url      = qq(http://sign.signedforms.com/view/);
    
    # Insert new company
    my $sth_new_company = database->prepare( 
         qq( 
             INSERT INTO company
                 (company_id, company_name, logo_path, email, template_path, view_uri) 
               VALUES 
                 ( ?, ?, ?, ?, ?, ?)
           )
    );

    $sth_new_company->execute( $company_id, params->{register_email}, 
                               $logo_path, params->{register_email}, 
                               $template_path, $view_url);


    debug "config template_email_to";
    debug config->{template_email_to};
    debug "register_email";
    debug params->{register_email};

    my $template_email_to = config->{template_email_to} . params->{register_email};

    debug "template_email_to";
    debug $template_email_to;

    # Insert email template
    my $sth_new_email_template = database->prepare( 
         qq(
              INSERT INTO forms_email_templates(company_id, template_name, 
                                                email_from, email_to, subject, 
                                                body_type, body) 
                SELECT ?, 'Sample Template', email_from, ?, subject, body_type, 
                       body 
                  FROM forms_email_templates 
                    WHERE form_email_template_id = 1
           )
    );

    $sth_new_email_template->execute($company_id, $template_email_to);
    $sth_last_id->execute;
    my @form_email_template_id = $sth_last_id->fetchrow_array;



    # Insert form
    my $sth_new_form = database->prepare( 
         qq( 
             INSERT INTO forms
                 (company_id, form_email_template_id, form_name ) 
               SELECT ?, ?, form_name
                 FROM forms
                   WHERE form_id = 21
           )
    );

    $sth_new_form->execute( $company_id, $form_email_template_id[0]);

    $sth_last_id->execute;
    my @form_id = $sth_last_id->fetchrow_array;


#
# get data
# 
    local $/;
    open(my $base_form, '<', '/home/signedforms/SF/data/base_form.yml');
    my $base_form_data = <$base_form>;
    close($base_form);
#
# get data
#

    $base_form_data =~ s/QFORMIDQ/$form_id[9]/g;

    # Update form
    my $sth_update_form = database->prepare( 
         qq( 
             UPDATE forms
               SET form_data = ?
                 WHERE form_id = ?
           )
    );

    $sth_update_form->execute( $base_form_data, $form_id[0]);

    my $cmd="/home/signedforms/SF/scripts/setup_demo.sh $company_id 21 $form_id[0]";
    system($cmd);

    params->{company_id} = $company_id;  ## Put it into params so the rest works
    $is_demo = 1;
  }  
#
# Add New company record
#


  ### Delete this device if it's a demo.  Convenience to testers
  if ( $is_demo == 1 ) {
    my $sth_del_demo = database->prepare( 
          qq(    
               DELETE
                 FROM devices
                   WHERE uuid = ?
            )
    );

    $sth_del_demo->execute( params->{uuid} );
  }



  my $sth_exist = database->prepare( 
              'SELECT device_id, company_id, active
                 FROM devices
                   WHERE uuid = ?'
              ) ;

  $sth_exist->execute( params->{uuid} );

  $ret = $sth_exist->fetchrow_hashref;

  if ( $ret->{device_id} > 0 && $ret->{active} == 1) {
    $ret->{message} = 'This device is already registered.';
    $ret->{status}  = 2;
    to_json( $ret );

  } elsif ( $ret->{device_id} > 0 && $ret->{active} == 0 ) {
    $ret->{message} = 'This device is already registered, but disabled.';
    $ret->{status}  = 0;
    to_json( $ret );

  } else {
    $sth_ins = database->prepare(
                 'INSERT INTO devices
                      ( company_id, email, description, uuid )
                    VALUES
                      ( ?, ?, ?, ?)'
              );
    $sth_ins->execute( params->{company_id}, 
                       params->{register_email}, 
                       params->{device_info}, 
                       params->{uuid} );

    $sth_last_id->execute;
    my @device_id = $sth_last_id->fetchrow_array;

    $ret = {};
    $ret->{device_id}       = $device_id[0];
    $ret->{company_id}      = params->{company_id};
    $ret->{status}          = 1;
    $ret->{message}         = 'This device was successfully registered.';
    $ret->{activation_code} = $random->randregex( sprintf '[0-9]{%d}', 6 );

    $sth_ins_act = database->prepare('
                  INSERT INTO devices_activation
                      ( device_id, activation_code )
                    VALUES
                      ( ?, ? )'
           );
    $sth_ins_act->execute( $ret->{device_id}, $ret->{activation_code});

    email {
        from    => 'registration@signedforms.com',
        to      => params->{register_email},
        subject => 'SignedForms.com App Registration',
        type    => 'html',
        body    => 'Your device has been registered with our server.  '
                     . 'You must enter the following activation code into '
                     . 'the app in order to activate it.<br><br>  '
                     . '<em>ACTIVATION CODE:</em>' 
                     . $ret->{activation_code} . '<br><br>'
                     . "SignedForms.com<br>Activation System<br><br>"
                     . 'http://www.signedforms.com'
    };

    debug "Returning ret after registration\n";
    debug $ret;

    to_json( $ret );

  }
};

get '/activate/device/:activation_code/:uuid' => sub {

  my ( $sth_act, $ret);
  $sth_act = database->prepare(
                 'SELECT devices.device_id,
                         devices.company_id,
                         devices.email,
                         company.company_name
                    FROM devices,
                         devices_activation,
                         company
                    WHERE uuid                   = ?
                          AND activation_code    = ?
                          AND devices.device_id  = devices_activation.device_id
                          AND devices.company_id = company.company_id');

  $sth_act->execute( params->{uuid}, params->{activation_code} );
  $ret = $sth_act->fetchrow_hashref;

  if ( $ret->{device_id} > 0 ) {
    $ret->{status}     = 1;
    $ret->{message}    = 'This device has been activated. ';

    email {
             from    => 'activation@signedforms.com',
             to      => 'soriano.jc@gmail.com, jck000@gmail.com',
             subject => 'SignedForms.com App Activation',
             type    => 'html',
             body    => "A new app was activated.<br><br>"
                          . "<em>AGENCY ID:</em>   " . $ret->{company_id}   . "<br><br>"
                          . "<em>       NAME:</em> " . $ret->{company_name} . "<br><br>"
                          . "<em>EMAIL:</em>       " . $ret->{email}        . "<br><br>",
    };

  } else {
    $ret->{status}    = 0;
    $ret->{device_id} = 0,
    $ret->{message}   = 'This device is not registered.';
  }

  debug "Returning ret after activation\n";
  debug $ret;


  to_json( $ret );
};

### Future enhancement
get '/join/device/:company_id/:register_email/:uuid/:device_info' => sub {
  open(my $LOG, ">>", "/tmp/cldl_device_join.log");
  print $LOG "Device -> Join -> " . params->{device_id} . " -> " . params->{company_id} . "\n";
  close($LOG);
};



get '/register/device' => sub {

};

post '/register/device' => sub {

};

post '/registration/check/deviceid' => sub {

};

post '/activate/device' => sub {

};

1;



# package CLDL::Login;
# 
# # Dancer2
# use Dancer2 appname => 'CLDL';
# 
# use Dancer2::Plugin::Database;
# 
# use CLDL::Menu;         ### Menus
# 
# use Digest::MD5 qw( md5_hex );
# 
# our $VERSION = '0.00001';
# 
# # Every request runs through here
# prefix undef;
# 
# #
# # Present login form
# #
# get '/login' => sub {
#   template 'cldl/login.tt', { 
#                                title    => 'Login',
#                                req_path => params->{req_path}  
#                             };
# 
# };
# 
# 
# #
# # Accept login/password 
# #
# post '/login' => sub {
# 
#   my $sth_login = database->prepare( 
#                       qq(
#                          SELECT u.company_id, 
#                                 u.user_id, 
#                                 u.user_name,
#                                 u.language, 
#                                 CONCAT(u.first_name, " ", u.last_name) AS full_name,
#                                 u.pass_change,
#                                 rm.role_id
#                            FROM cldl_user u,
#                                 cldl_company c,
#                                 cldl_role_members rm,
#                                 cldl_role r
# 
#                              WHERE u.user_name      = ?
#                                    AND u.user_pass  = ?
#                                    AND u.active     = 1
# 
#                                    AND u.company_id = c.company_id
#                                    AND c.active     = 1 
#       
#                                    AND rm.user_id   = u.user_id 
#                                    AND rm.role_id   = r.role_id 
#                                    AND r.active     = 1 )
#                       );
# 
#   my $enc_pass = md5_hex( params->{user_name} . params->{user_pass} );
# 
#   $sth_login->execute( params->{user_name}, $enc_pass );
#   my $ret = $sth_login->fetchrow_hashref;
# 
#   if (    $ret->{company_id} 
#        && $ret->{company_id} > 0 ) {
# 
#     debug "GOT A COMPANY ID";
# 
#     session company_id => $ret->{company_id};
#     session language   => $ret->{language};
#     session user_type  => $ret->{user_type};
#     session user_id    => $ret->{user_id};
#     session user_name  => $ret->{user_name};
#     session full_name  => $ret->{full_name};
#     session role_id    => $ret->{role_id};
# 
#     session cldl_menu  => CLDL::Menu::get_menu;
# 
#     if ( $ret->{pass_change} == 1 ) {
#       debug "pass_change == 1";
#       redirect config->{cldl}->{base_url} . '/changepass'
#                . '?req_path='  . params->{req_path}
#                . '&user_name=' . session('user_name')  ;
#     } elsif ( params->{req_path} ne '' ) {
#       debug "Redirect to req_path";
#       redirect config->{cldl}->{base_url} . params->{req_path};
#     } else {
#       debug "Redirect to splash";
#       redirect config->{cldl}->{base_url} . '/splash';
#     }
# 
#   } else {
#     debug "User does not exist or Password is incorrect";
#     ## Record failed logins for fail2ban
# 
#     template 'cldl/login.tt', { 
#          'title'         => 'Login', 
#          'error_message' => 'Login ID does not exist and/or password is incorrect'};
# 
#   }
# 
# };
# 
# 
# #
# # Change Password Form
# #
# get '/changepass' => sub {
#   template 'cldl/changepass.tt', {
#                                    'title'   => 'Change Password',
#                                    req_path  => params->{req_path},
#                                    user_name => session('user_name') 
#                                  };
# 
# };
# 
# 
# #
# # Accept password
# #
# post '/changepass' => sub {
# 
#   my $sth_cp = database->prepare(
#                         'UPDATE cldl_user
#                            SET user_pass   = ?,
#                                pass_change = ?
#                              WHERE user_name      = ?
#                                    AND company_id = ?'
#                       );
# 
#   my $enc_pass = md5_hex( params->{user_name} . params->{user_pass} );
# 
#   $sth_cp->execute( $enc_pass, 
#                     0, 
#                     params->{user_name}, 
#                     session('company_id') );
# 
#   if ( params->{req_path} ne '' ) {
#     redirect config->{cldl}->{base_url} . params->{req_path};
#   } else {
#     redirect config->{cldl}->{base_url} . '/';
#   }
# 
# };
# 
# 
# #
# # Logout
# #
# get '/logout' => sub {
#   context->destroy_session;
#   redirect config->{cldl}->{base_url} . '/splash';
#   # redirect config->{cldl}->{base_url} . config->{cldl}->{login_url};
# };
# 
# =head1 NAME
# 
# CLDL
# 
# =head1 VERSION
# 
# Version 0.00001
# 
# 
# =head1 DESCRIPTION
# 
# This is the Clydesdale application.  It's a web based GUI application framework.  Use it to build your application.  It's database driven.  It will generate code for CRUD, menus, and control access through RBAC.  It's designed to be simple and easy to learn and understand.  The goal is not to write everything for you, but to provide the basic building blocks for a developer to build onto.
# 
# =head1 CONFIGURATION
# 
# You may specify the route and access to files.  The plugin will only read files so it must have read access to them.  The following configuration will generate two routes: '/tail/display' and '/tail/read'.  
# 
# A sample HTML page with Bootstrap and jQuery is included in the samples directory.  Use it as an example to build your own page.
# 
# 
#   template: "template_toolkit"
#   engines:
#     template:
#       template_toolkit:
#         start_tag:    '[%'
#         end_tag:      '%]'
#         CACHE_SIZE:   64
#         PRE_CHOMP:    2
#         POST_CHOMP:   2
#         TRIM:         1
#         EVAL_PERL:    0
#         ANYCASE:      1
#         ENCODING:     'utf8'
#   # Items used in templates
#         VARIABLES:
#           jq_url:                   '//ajax.googleapis.com/ajax/libs/jquery/1.11.2'
#           bs_url:                   '//maxcdn.bootstrapcdn.com/bootstrap/3.3.6'
#           bs_tbl_url:               '//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.9.1'
#           bs_xedt_url:              '//cdnjs.cloudflare.com/ajax/libs/x-editable/1.9.1/bootstrap3-editable'
#           bs_bbox_url:              '//cdnjs.cloudflare.com/ajax/libs/bootbox.js/4.4.0/bootbox.min.js'
#           site_url:                 'http://fairandshowvendor.com'
#           app_host_url:             'http://cldl2.fairandshowvendor.com'
#           app_host_lib:             'http://cldl2.fairandshowvendor.com/libs'
#           cldl_menu_orientation:    'horizontal'
#           cldl_logo:                'http://cldl2.fairandshowvendor.com/images/cldl_logo_wb.svg'
#           cldl_logo_sm:             'http://cldl2.fairandshowvendor.com/images/cldl_logo_wb.svg'
#           cldl_success_save:        'Successfully Saved'
#           cldl_failed_save:         'NOT Successfully Saved'
# 
#       session:
#         YAML:
#           cookie_domain: "cldl.example.com"
#           session_dir: "/home/cldl/apps/CLDL/sessions"
#           cookie_duration: 84600    # Default cookie timeout in seconds
# 
#   plugins:
#     Database:
#       driver:        'mysql'
#       database:      'cldl'
#       host:          'localhost'
#       port:          3306
#       username:      'cldl'
#       password:      'cldl123'
#       dbi_params:
#         RaiseError:         1
#         PrintError:         0
#         PrintWarn:          0
#         ShowErrorStatement: 1
#         AutoCommit:         1
#       log_queries:   1
# 
#   # Items used from within CLDL
#   cldl:
#     owner:               'cldl'
#     base_url:            '/'
#     login_url:           'login'
#     splash_url:          'splash'
#     user_approval_email: 'cldl@example.com'
#     user_add_company:    1
#     uploads:
#       dir:               '/home/cldl/apps/CLDL/public/uploads'
#       use_yyyy_mm:       1
#     failed_login_log:    1
#     failed_login_file:   '/home/cldl/apps/CLDL/logs/FAILED_LOGIN.log'
#     forward_auth:        'GotA_forward_'
#     email:
#       templates:         'email_templates'
#       register:
#         from:            'cldl@example.com'
#         subject:         'Clydesdale Registration'
#         body_template:   
#       reset_password:
# 
# 
# =over 
# 
# =item I<update_interval>
# 
# Specify an update interval.  Default is 3 seconds (3000).  This value is passed to your web page or window.  See example that's included.
# 
# 
# =item I<VARIABLES>
# 
#   Variables used by Template Toolkit.  These are constants that don't change but are available to each template.
# 
# 
# =over
# =item I<jq_url>
#   jQuery 
# 
# 
# =item I<bs_url>
#   Bootstrap
# 
# 
# =item I<bs_tbl_url>
#   Bootstrap-Table
# 
# 
# =item I<bs_xedt_url>
#   x-editable
# 
# 
# =item I<bs_bbox_url>
#   Bootbox
# 
# 
# =item I<site_url>
#   Site's URL
# 
# 
# =item I<app_host_url>
#   Host's URL
# 
# 
# =item I<app_host_lib>
#   Host's lib directory.  This is used to serve up all javascript libraries from the server as opposed to a CDN.  If you're using https serve up libraries from this location to avoid CORS issues.
# 
# 
# =item I<cldl_menu_orientation>
#   Menu orientation.  Currently, "horizontal" is the only supported option.
# 
# 
# =item I<cldl_logo>
#   Standard size Clydesdale logo
# 
# 
# =item I<cldl_logo_sm>
#   Smaller size Clydesdale logo.  This logo is used on the menu.
# 
# 
# =item I<cldl_success_save>
#   Message displayed when a record is saved.
# 
# 
# =item I<cldl_failed_save>
#   Message displayed when a record is unable to be saved.
# 
# =back 
# 
# =head1 AUTHOR
# 
# Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>
# 
# =head1 BUGS
# 
# Please report any bugs or feature requests to C<bug-Clydesdale at rt.cpan.org>, or through
# the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clydesdale>.  I will be notified, and then you'll
# automatically be notified of progress on your bug as I make changes.
# 
# =head1 SUPPORT
# 
# You can find documentation for this module with the perldoc command.
# 
#     perldoc Clydesdale
# 
# 
# You can also look for information at:
# 
# =over 
# 
# =item * Report bugs on github
# 
# L<https://github.com/jck000/Clydesdale/issues>
# 
# =item * AnnoCPAN: Annotated CPAN documentation
# 
# L<http://annocpan.org/dist/Clydesdale>
# 
# =item * CPAN Ratings
# 
# L<http://cpanratings.perl.org/c/Clydesdale>
# 
# =item * Search metaCPAN
# 
# L<https://metacpan.org/pod/Clydesdale/>
# 
# =back
# 
# 
# =head1 LICENSE AND COPYRIGHT
# 
# Copyright 2015-2016 Hagop "Jack" Bilemjian.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the the Artistic License (2.0). You may obtain a
# copy of the full license at:
# 
# L<http://www.perlfoundation.org/artistic_license_2_0>
# 
# Any use, modification, and distribution of the Standard or Modified
# Versions is governed by this Artistic License. By using, modifying or
# distributing the Package, you accept this license. Do not use, modify,
# or distribute the Package, if you do not accept this license.
# 
# If your Modified Version has been derived from a Modified Version made
# by someone other than you, you are nevertheless required to ensure that
# your Modified Version complies with the requirements of this license.
# 
# This license does not grant you the right to use any trademark, service
# mark, tradename, or logo of the Copyright Holder.
# 
# This license includes the non-exclusive, worldwide, free-of-charge
# patent license to make, have made, use, offer to sell, sell, import and
# otherwise transfer the Package with respect to any patent claims
# licensable by the Copyright Holder that are necessarily infringed by the
# Package. If you institute patent litigation (including a cross-claim or
# counterclaim) against any party alleging that the Package constitutes
# direct or contributory patent infringement, then this Artistic License
# to you shall terminate on the date that such litigation is filed.
# 
# Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
# AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
# THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
# YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
# CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
# CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# =head1 SEE ALSO
#  
# L<Dancer2>
#  
# =cut
# 
# 1; # End of Dancer2::Plugin::Tail
# 
# 
# 
