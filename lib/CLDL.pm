package CLDL;

# Dancer2
use Dancer2 appname => 'CLDL';

use Dancer2::Plugin::Database;
use Dancer2::Plugin::Tail;
#use Dancer2::Plugin::EditFile;

use Data::Dumper;

### CLDL Base
use CLDL::Account;      ### Accounts
use CLDL::DV;           ### DataViews
use CLDL::Menu;         ### Menus
use CLDL::Upload;       ### Uploads

### Admin
### use CLDL::Admin::Config;  
### use CLDL::Admin::Crontab;  
use CLDL::Admin::EditMenu;     ### Edit Menus
use CLDL::Admin::DVFromtable;  ### Create DataView from table
use CLDL::Admin::Generic;      ### Generic

use Digest::MD5 qw( md5_hex );

our $VERSION = '0.00001';

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
             && request->path_info !~ m{^/cldl/account/forgotpassword} 
             && request->path_info !~ m{^/cldl/account/registration/check} 
             && request->path_info !~ m{^/tail/display}
             && request->path_info !~ m{^/tail/read} ) ) {

    redirect config->{cldl}->{base_url} 
               . config->{cldl}->{login_url} 
               . '?req_path=' . request->path_info;
  }

#  #  Setup Basic Navigation  
#  if (    ! defined session('cldl_return_to_page') 
#       || session('cldl_return_to_page') eq '' ) { 
#  # if ( session('cldl_return_t_page') eq request->path_info ) { 
#    session cldl_return_to_page => request->path_info;
#    session cldl_reload_page    => '';
#  } else {
#    session cldl_reload_page    => request->path_info;
#  }

  #  Verify permission
  
  #  Delete is_cldl_menu=1
#  request->path_info =~ s/is_cldl_menu=1//g;
#  request->path_info =~ s/&&/&/g;

  if (  defined params->{is_cldl_menu} && params->{is_cldl_menu} == 1 ) {
    session cldl_return_to_page => request->path_info;
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

#    #
#    my $menu = &CLDL::Menu::get_menu;
#    session cldl_menu    => $menu;
    session cldl_menu    => CLDL::Menu::get_menu;

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

=head1 NAME

CLDL

=head1 VERSION

Version 0.00001


=head1 DESCRIPTION

This is the Clydesdale application.  It's a web based GUI application framework.  Use it to build your application.  It's database driven.  It will generate code for CRUD, menus, and control access through RBAC.  It's designed to be simple and easy to learn and understand.  The goal is not to write everything for you, but to provide the basic building blocks for a developer to build onto.

=head1 CONFIGURATION

You may specify the route and access to files.  The plugin will only read files so it must have read access to them.  The following configuration will generate two routes: '/tail/display' and '/tail/read'.  

A sample HTML page with Bootstrap and jQuery is included in the samples directory.  Use it as an example to build your own page.


  template: "template_toolkit"
  engines:
    template:
      template_toolkit:
        start_tag:    '[%'
        end_tag:      '%]'
        CACHE_SIZE:   64
        PRE_CHOMP:    2
        POST_CHOMP:   2
        TRIM:         1
        EVAL_PERL:    0
        ANYCASE:      1
        ENCODING:     'utf8'
  # Items used in templates
        VARIABLES:
          jq_url:                   '//ajax.googleapis.com/ajax/libs/jquery/1.11.2'
          bs_url:                   '//maxcdn.bootstrapcdn.com/bootstrap/3.3.6'
          bs_tbl_url:               '//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.9.1'
          bs_xedt_url:              '//cdnjs.cloudflare.com/ajax/libs/x-editable/1.9.1/bootstrap3-editable'
          bs_bbox_url:              '//cdnjs.cloudflare.com/ajax/libs/bootbox.js/4.4.0/bootbox.min.js'
          site_url:                 'http://fairandshowvendor.com'
          app_host_url:             'http://cldl2.fairandshowvendor.com'
          app_host_lib:             'http://cldl2.fairandshowvendor.com/libs'
          cldl_menu_orientation:    'horizontal'
          cldl_logo:                'http://cldl2.fairandshowvendor.com/images/cldl_logo_wb.svg'
          cldl_logo_sm:             'http://cldl2.fairandshowvendor.com/images/cldl_logo_wb.svg'
          cldl_success_save:        'Successfully Saved'
          cldl_failed_save:         'NOT Successfully Saved'

      session:
        YAML:
          cookie_domain: "cldl.example.com"
          session_dir: "/home/cldl/apps/CLDL/sessions"
          cookie_duration: 84600    # Default cookie timeout in seconds

  plugins:
    Database:
      driver:        'mysql'
      database:      'cldl'
      host:          'localhost'
      port:          3306
      username:      'cldl'
      password:      'cldl123'
      dbi_params:
        RaiseError:         1
        PrintError:         0
        PrintWarn:          0
        ShowErrorStatement: 1
        AutoCommit:         1
      log_queries:   1

  # Items used from within CLDL
  cldl:
    owner:               'cldl'
    base_url:            '/'
    login_url:           'login'
    splash_url:          'splash'
    user_approval_email: 'cldl@example.com'
    user_add_company:    1
    uploads:
      dir:               '/home/cldl/apps/CLDL/public/uploads'
      use_yyyy_mm:       1
    failed_login_log:    1
    failed_login_file:   '/home/cldl/apps/CLDL/logs/FAILED_LOGIN.log'
    forward_auth:        'GotA_forward_'
    email:
      templates:         'email_templates'
      register:
        from:            'cldl@example.com'
        subject:         'Clydesdale Registration'
        body_template:   
      reset_password:


=over 

=item I<update_interval>

Specify an update interval.  Default is 3 seconds (3000).  This value is passed to your web page or window.  See example that's included.


=item I<VARIABLES>

  Variables used by Template Toolkit.  These are constants that don't change but are available to each template.


=over
=item I<jq_url>
  jQuery 


=item I<bs_url>
  Bootstrap


=item I<bs_tbl_url>
  Bootstrap-Table


=item I<bs_xedt_url>
  x-editable


=item I<bs_bbox_url>
  Bootbox


=item I<site_url>
  Site's URL


=item I<app_host_url>
  Host's URL


=item I<app_host_lib>
  Host's lib directory.  This is used to serve up all javascript libraries from the server as opposed to a CDN.  If you're using https serve up libraries from this location to avoid CORS issues.


=item I<cldl_menu_orientation>
  Menu orientation.  Currently, "horizontal" is the only supported option.


=item I<cldl_logo>
  Standard size Clydesdale logo


=item I<cldl_logo_sm>
  Smaller size Clydesdale logo.  This logo is used on the menu.


=item I<cldl_success_save>
  Message displayed when a record is saved.


=item I<cldl_failed_save>
  Message displayed when a record is unable to be saved.

=back 

=head1 AUTHOR

Hagop "Jack" Bilemjian, C<< <jck000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Clydesdale at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clydesdale>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Clydesdale


You can also look for information at:

=over 

=item * Report bugs on github

L<https://github.com/jck000/Clydesdale/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Clydesdale>

=item * CPAN Ratings

L<http://cpanratings.perl.org/c/Clydesdale>

=item * Search metaCPAN

L<https://metacpan.org/pod/Clydesdale/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Hagop "Jack" Bilemjian.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO
 
L<Dancer2>
 
=cut

1; # End of Dancer2::Plugin::Tail

