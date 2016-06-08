package CLDL::Admin::DVFromtable;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

use base qw( CLDL::Helpers::Defaults );
use base qw( CLDL::Base );

our $VERSION = '0.00001';

prefix '/admin/dvfromtable';

get '/select' => sub {
  debug "IN fromtable";

  my @tbl = CLDL::Base::tables;

  template 'cldl/admin/dvfromtable.tt', {
                           'title'  => 'Create DataView from Table List ',
                           tbl_list => \@tbl,
                        };
};

post '/insert' => sub {
  debug "IN fromtable";

  # DataView
  my $sth_idv = database->prepare( 
            'INSERT INTO cldl_dv 
               ( company_id, dv_db_table, dv_name, dv_title, dv_data_attributes ) 
                 VALUES 
               ( ?, ?, ?, ?, ? )'
  );

  $sth_idv->execute( session('company_id'), 
                     params->{dv_db_table}, 
                     params->{dv_name}, 
                     params->{dv_title}, 
                     $CLDL::Helpers::Defaults::DV);

  my $sth_last_id = database->prepare( 'SELECT LAST_INSERT_ID() AS id') ;
  $sth_last_id->execute();
  my $dv = $sth_last_id->fetchrow_hashref ;

  my $schema = config->{Plugins}->{Database}->{database};
  my $working_table = params->{dv_db_table};

  debug "SCHEMA: $schema";
  debug "TABLE:  $working_table";
  
  my $column_info = database->column_info(undef, $schema, $working_table, '%');
  my $column_list = $column_info->fetchall_arrayref( 
                      { TABLE_NAME              => 1, 
                        COLUMN_NAME             => 1, 
                        mysql_type_name         => 1, 
                        TYPE_NAME               => 1, 
                        NULLABLE                => 1, 
                        mysql_is_auto_increment => 1, 
                        IS_NULLABLE             => 1, 
                        ORDINAL_POSITION        => 1, 
                        mysql_is_pri_key        => 1 } );


  my @sorted_column_list;
  my $sth_idvf = database->prepare( 
            'INSERT INTO cldl_dvf 
               ( dv_id, dvf_db_column, dvf_key, dvf_label, dvf_name, ordr )
                 VALUES 
               ( ?, ?, ?, ?, ?, ? )'
  );
  my $cnt = 0;
  foreach my $column ( @{$column_list} ) {

    debug $column if $cnt == 0;
    $cnt++;

    $sth_idvf->execute( $dv->{id}, 
                        $column->{COLUMN_NAME}, 
                        $column->{mysql_is_pri_key}, 
                        $column->{COLUMN_NAME},
                        $column->{COLUMN_NAME}, 
                        $column->{ORDINAL_POSITION} );
  }

  redirect '/dv/select/' .  params->{dv_name};

};

1;

