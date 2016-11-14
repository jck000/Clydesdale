package CLDL::Upload;

use Dancer2 appname => 'CLDL';
use DateTime;
use File::Path qw(make_path);
 
our $VERSION = '0.001';

prefix '/upload';

get '/file' => sub {
  debug "IN get upload";
  template 'cldl/upload.tt', { 
                               title   => 'Upload file',
                               save_to => 'cldl/upload/'
                             };
};


#
# Accepts the file
#
post '/file' => sub {
  debug "IN post script, template, data";

  ### Data provided by user
  my $upload_file = request->upload('filename'); 


  my $dt            = DateTime->now;
  my $upload_config = config->{cldl}->{uploads};
  my $full_path     = '';

  if ( ! defined $upload_config->{dir} ) {
#    status 404;
  } else {
    $full_path = $upload_config->{dir};
  }

  if ( defined params->{path} ) {
    $full_path .= '/' . params->{path};
  }

  if ( defined $upload_config->{use_yyyy_mm} 
       &&      $upload_config->{use_yyyy_mm} == 1 ) {
    $full_path .= '/' . $dt->strftime( '%Y' ) . '/' . $dt->strftime( '%m' );
  }

  make_path( $full_path );

  my $file = $full_path . '/' . $upload_file->filename;

  debug "DEST FILE: $file";

#  # Copy from temp file to named file into our upload directory
#  $upload_file->copy_to( $file ); 

  template 'splash.tt', {
                           title => 'Splash',
                        };
};


# post '/logo' => sub {
#   debug "IN logo script, template, data";
#
#  my $upload_path = params->{path};
#  my $upload_file = request->upload('filename'); 
#
#  my $file = $upload_file->filename;
#  $file    = config->{cldl}->{upload_file_base} . '/'
#               . $upload_path . '/' 
#               . $file;
#
#  debug "DEST FILE: $file";
#
#  # Copy from temp file to named file into our upload directory
#  $upload_file->copy_to( $file ); 
#
#  template 'splash.tt', {
#                           title    => 'Splash',
#                           req_path => params->{req_path}  
#                        };
#
#};

1;


