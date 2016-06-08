package CLDL::Admin::Config;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

use String::Random;
use File::Copy;
use YAML::XS qw/LoadFile DumpFile Dump Load/;

our $VERSION = '0.001';

prefix '/admin/config';

my $cldl_config_file = config->{appdir} . '/config.yml';
my $cldl_config      = LoadFile( $cldl_config_file );

my $STRRand = String::Random->new;


get '/display' => sub {

  local $/;
  open ( my $YML_IN, "<", $cldl_config_file ) ;
  my $cldl_yml = <$YML_IN>;
  close($YML_IN);

  debug "YML: " ;
  debug $cldl_yml;

  template 'admin/config.tt', { label => 'Config.yml', config_file => $cldl_yml}, {layout => 'cldl.tt'};

};

get '/save' => sub {

  my $tmp_config = params->{config_file};
  my $cldl_hash;

  eval {
    $cldl_hash = Load( $tmp_config );
  };

  if ( $@ ) {
    template 'cldl/admin/config.tt',
             { status      => 'Error saving this configuration file',
               config_file => $tmp_config};
  }

  my $new_filename = config->{appdir} . '/backups/cldl.yml.' . time;

  # Make a backup copy
  copy( $cldl_config_file, $new_filename);


  DumpFile($cldl_config_file, $cldl_hash );

  template 'cldl/admin/config.tt',
           { status      => 'Changes have been saved',
             config_file => $tmp_config};

};


1;
