package CLDL::Admin::Generic;

use Dancer2 appname => 'CLDL';

our $VERSION = '0.00001';

prefix '/admin';

any ['get','post'] => '/:dv_name_id/:action' => sub {
  debug "IN admin/" . params->{'dv_dv'};

  if ( params->{dv_name_id} !~ m/conpany|users/ ) {
    status 404;
  }

  if (    ( request->method eq 'get'  && params->{action} eq 'select' )
       || ( request->method eq 'post' && params->{action} =~ m/update|insert|delete/ ) ) { 
    my $forward_auth = config->{cldl}->{forward_auth};
    forward '/dv/' . params->{action} . '/' . params->{dv_name_id}, 
            {authorize => $forward_auth}; 
  } else {
    status 404;
  }

};

1;
