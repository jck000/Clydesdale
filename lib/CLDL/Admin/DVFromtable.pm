package CLDL::Admin::DVFromtable;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

my $DV = { data_attributes => qq(buttonAlign: 'left', cache: true, cardView: false, contentType: 'json', iconPrefix: 'fa', icons:{ refresh: 'glyphicon-refresh icon-refresh', toggle: 'glyphicon-list-alt icon-list-alt', columns: 'glyphicon-th icon-th' }, maintainSelected: true, method: 'get', countColumns: 1, pagination: true, pageList: [ 50, 100, 250, 500], pageSize: 50, showHeader: true, showColumns: false, showRefresh: false, showToggle: false, sidePagination: 'client', singleSelect: false, smartDisplay: true, striped: true, search: true')};
my $DVF = {
            global => qq(
                          'dvf_db_column' => '',
                          'dvf_key'       => '0',
                          'dvf_label'     => '',
                          'dvf_name'      => '',
                          'dvf_sortable'  => '0',
                          'dvf_type'      => '1',
                          'ordr'          => ''
                        ),
           active => { 
                       dvf_type          => '5',
                       dvf_values        => qq( { 0 => 'Inactive', 1 => 'Active' } ),
                       dvf_default_value => '1'
                     },
           dv_type => { 
                        dvf_type          => '5',
                        dvf_values        => qq( { 0 => 'DataTable', 1 => 'Form' } ),
                        dvf_default_value => '0'
                      },
           dt_del  => { 
                        dvf_type          => '5',
                        dvf_values        => qq( { 0 => 'No', 1 => 'Yes' } ),
                        dvf_default_value => '1'
                      },
           dt_edit => { 
                        dvf_type          => '5',
                        dvf_values        => qq( { 0 => 'Not Editable', 1 => '1-Click', 2 => '2-Clicks' } ),
                        dvf_default_value => '2'},
          }; 

use base qw( CLDL::Base );

our $VERSION = '0.00001';

prefix '/admin/dvfromtable';

get '/select' => sub {
  debug "IN DVFromtable";

  my @tbl = CLDL::Base::tables;

  template 'cldl/admin/dvfromtable.tt', {
                           title    => 'Create DataView from Table List ',
                           tbl_list => \@tbl,
                        };
};

post '/insert' => sub {
  debug "IN fromtable";

  # DataView
  my $sth_idv = database->prepare( 
            'INSERT INTO cldl_dv 
                 ( company_id, dv_db_table, dv_name, dv_title, 
                   dv_data_attributes ) 
               VALUES 
                 ( ?, ?, ?, ?, ? )'
  );

  $sth_idv->execute( 
                     session('company_id'), 
                     params->{dv_db_table}, 
                     params->{dv_name}, 
                     params->{dv_title}, 
                     $DV->{data_attributes}
                   );

  my $sth_last_id = database->prepare( 'SELECT LAST_INSERT_ID() AS id') ;
  $sth_last_id->execute();
  my $dv = $sth_last_id->fetchrow_hashref ;

  my $schema = config->{plugins}->{Database}->{database};
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
               ( dv_id, dvf_db_column, dvf_key, dvf_label, dvf_name, ordr, 
                 dvf_type, dvf_values, dvf_default_value )
                 VALUES 
               ( ?, ?, ?, ?, ?, ?, ?, ?, ? )'
  );
  my $cnt = 0;
  foreach my $column ( @{$column_list} ) {

    debug $column if $cnt == 0;
    $cnt++;

    my $is_key = 1;
    if ( $column->{mysql_is_pri_key} eq '' ) {
      $is_key = 0;
    }

    #
    # Beautify column names for use a labels:
    #   1. Use the column name as a label
    #   2. Change -(dash) and _(underscore) to space
    #   3. Split based on space
    #   4. Change each word to lower case but capitalize the 1st letter
    #

    my $dvf_label = $column->{COLUMN_NAME};
    $dvf_label =~ s/[_-]/ /g; 
    $dvf_label = join " ", map {ucfirst(lc)} split " ", $dvf_label;

    $sth_idvf->execute( $dv->{id}, 
                        $column->{COLUMN_NAME}, 
                        $is_key,
                        $dvf_label,
                        $column->{COLUMN_NAME}, 
                        $column->{ORDINAL_POSITION},
                        $DVF->{ $column->{COLUMN_NAME} }->{dvf_type} || 0,
                        $DVF->{ $column->{COLUMN_NAME} }->{dvf_values},
                        $DVF->{ $column->{COLUMN_NAME} }->{dvf_default_value}
                      );
  }

  redirect '/dv/select/' .  params->{dv_name};

};

1;

