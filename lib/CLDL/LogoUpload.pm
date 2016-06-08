package CLDL::LogoUpload;

use Dancer ':syntax';

our $VERSION = '0.001';

prefix '/cldl/logoupload';

get '/' => sub {
  debug "IN get upload";
  template 'cldl/upload.tt', { 'title'  => 'Upload file'};
};


#
# Accepts the file
#
post '/' => sub {
  debug "IN post script, template, data";

  my $upload_path = params->{path};
  my $upload_file = request->upload('filename'); 

  my $file = $upload_file->filename;
  $file    = config->{cldl}->{upload_file_base} . '/'
               . $upload_path . '/' 
               . $file;

  debug "DEST FILE: $file";

  # Copy from temp file to named file into our upload directory
  $upload_file->copy_to( $file ); 

  template 'splash.tt', {
                               'title'  => 'Splash',
                               req_path => params->{req_path}  
                            };

};

1;


