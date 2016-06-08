package CLDL::Admin::Crontab;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

use Config::Crontab;

use String::Random;
use File::Copy;
use YAML::XS qw/LoadFile DumpFile Dump Load/;

our $VERSION = '0.001';

prefix '/admin/crontab';

get '/display' => sub {

  my $owner = config->{cldl}->{owner};
  my $ct = new Config::Crontab( -owner => $owner );
  $ct->read;
  my $crontab = $ct->dump;

open( my $LOG, ">", "/tmp/crontab.log");
print $LOG config->{cldl}->{owner} . "\n";
print $LOG "$crontab\n";
close($LOG);

  template 'cldl/admin/config.tt', { label => 'Crontab', config_file => $crontab}, {layout => 'cldl.tt'};

};

get '/save' => sub {

  my $tmp_config = params->{config_file};
  my $cldl_hash;

#  eval {
#    $cldl_hash = Load( $tmp_config );
#  };

#  if ( $@ ) {
#    template 'cldl/admin/config.tt',
#             { status      => 'Error saving this configuration file',
#               config_file => $tmp_config};
#  }

#  my $new_filename = config->{appdir} . '/backups/cldl.yml.' . time;

  # Make a backup copy
#  copy( $cldl_config_file, $new_filename);


#  DumpFile($cldl_config_file, $cldl_hash );

#  template 'config.tt',
#           { status      => 'Changes have been saved',
#             config_file => $tmp_config};

};


1;





1;

#  
# ####################################
# ## making a new crontab from scratch
# ####################################
#  
# my $ct = new Config::Crontab;
#  
# ## make a new Block object
# my $block = new Config::Crontab::Block( -data => <<_BLOCK_ );
# ## mail something to joe at 5 after midnight on Fridays
# MAILTO=joe
# 5 0 * * Fri /bin/someprogram 2>&1
# _BLOCK_
#  
# ## add this block to the crontab object
# $ct->last($block);
#  
# ## make another block using Block methods
# $block = new Config::Crontab::Block;
# $block->last( new Config::Crontab::Comment( -data => '## do backups' ) );
# $block->last( new Config::Crontab::Env( -name => 'MAILTO', -value => 'bob' ) );
# $block->last( new Config::Crontab::Event( -minute  => 40,
#                                           -hour    => 3,
#                                           -command => '/sbin/backup --partition=all' ) );
# ## add this block to crontab file
# $ct->last($block);
#  
# ## write out crontab file
# $ct->write;
#  
# ###############################
# ## changing an existing crontab
# ###############################
#  
# my $ct = new Config::Crontab; $ct->read;
#  
# ## comment out the command that runs our backup
# $_->active(0) for $ct->select(-command_re => '/sbin/backup');
#  
# ## save our crontab again
# $ct->write;
#  
# ###############################
# ## read joe's crontab (must have root permissions)
# ###############################
#  
# ## same as "crontab -u joe -l"
# 
