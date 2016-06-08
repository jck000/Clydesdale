package CLDL::Upload;

use Dancer2 appname => 'CLDL';

our $VERSION = '0.001';

prefix '/upload';

get '/' => sub {
  debug "IN get upload";
  template 'cldl/upload.tt', { title   => 'Upload file',
                               save_to => 'cldl/upload/'};
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
                        };
};


get '/logo' => sub {
  template 'cldl/upload.tt', { title   => 'Upload Logo Image file',
                               save_to => 'cldl/upload/logo'};
};


post '/logo' => sub {
  debug "IN logo script, template, data";

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


