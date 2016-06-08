package CLDL::Admin::DataViews;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

##############

# SQL statements
my $SQL_LIB = {
     DV => 
         qq( SELECT dv_id,
                    dv_name,
                    dv_db_table,
                    dv_type,
                    dv_title,
                    dt_add,
                    dt_del,
                    dt_edit, 
                    dv_name_add, 
                    dv_name_edit, 
                    dv_template,
                    dv_js_functions,
                    dv_data_attributes
               FROM cldl_dv
                 WHERE dv_name    = ? 
                       AND (    company_id = ? 
                             OR company_id = 1 )
                       AND active = 1 ),
     DVF => 
         qq( SELECT dvf_id, 
                    ordr,
                    dvf_db_column,
                    dvf_name,
                    dvf_label, 
                    dvf_type,
                    dvf_key,
                    dvf_placeholder,
                    dvf_help,
                    dvf_sortable,
                    dvf_sort_ordr,
                    dvf_sort_asc_desc,
                    d_id,
                    dvf_js_functions,
                    dvf_data_attributes
               FROM cldl_dvf 
                 WHERE dv_id      = ?
                       AND active = 1 
                   ORDER BY ordr  ),
     D => 
         qq( SELECT d_id, 
                    d_name
               FROM cldl_d
                 WHERE d_id           = ? 
                       AND (    company_id = ? 
                             OR company_id = 1 )
                       AND active     = 1 ),
     DF => 
         qq( SELECT df_id, 
                    ordr,
                    df_label,
                    df_value,
                    df_default
               FROM cldl_df 
                 WHERE d_id       = ?
                       AND active = 1 
                   ORDER BY ordr  ),
     DF_DT => 
         qq( SELECT df_label
               FROM cldl_d d,
                    cldl_df df
                 WHERE d.d_id           = ? 
                       AND (    d.company_id = ? 
                             OR d.company_id = 1 )
                       AND d.active     = 1 

                       AND df.df_value  = ?
                       AND df.d_id      = d.d_id 
                       AND df.active    = 1  ),
     DF_DT =>
         qq( SELECT df_label
               FROM cldl_d d,
                    cldl_df df
                 WHERE d.d_id           = ? 
                       AND (    d.company_id = ? 
                             OR d.company_id = 1 )
                       AND d.active     = 1 

                       AND df.df_value  = ?
                       AND df.d_id      = d.d_id 
                       AND df.active    = 1  ),
     MENU => qq( 
                SELECT menu_id,
                       ordr,
                       menu_label,
                       menu_link,
                       menu_js_functions,
                       menu_data_attributes,
                       menu_notes
                  FROM cldl_menu
                    WHERE (    company_id = ?
                            OR company_id = 1 )
                          AND pmenu_id IS NULL
                          AND active   = 1
                  UNION
                SELECT pmenu_id AS menu_id,
                       ordr,
                       menu_label,
                       menu_link,
                       menu_js_functions,
                       menu_data_attributes,
                       menu_notes
                  FROM cldl_menu
                    WHERE (    company_id = ?
                            OR company_id = 1 )
                          AND pmenu_id IS NOT NULL
                          AND active   = 1
                   ORDER BY menu_id, ordr ),
};

# Return an array of table names
sub tables {
    my @tbl;

    my @table_list = database->tables('', '', '', 'TABLE');

    for my $table ( @table_list) {
      $table =~ s/`//g;
      my @tmp_tbl = split( /\./, $table);
      push @tbl, $tmp_tbl[1];
    }

    return @tbl;
}

sub formdatalists {
  my $dvf_d_id   = shift;
  my $company_id = shift;

  my $d = {};

  # DataView Field Values ( checkbox, radio, select)
  my $sth_d  = database->prepare( $SQL_LIB->{D}  );
  my $sth_df = database->prepare( $SQL_LIB->{DF} );

  foreach my $skey ( keys %{$dvf_d_id} ) { # skey   = field name (s=search)
    my $s_d_id = $dvf_d_id->{ $skey };     # s_d_id = key to data(s=search)
    $sth_d->execute( $s_d_id, $company_id );
    $d->{ $s_d_id } = $sth_d->fetchrow_hashref ;

    my @d_fields = ();
    $sth_df->execute( $s_d_id );
    while ( my $d_ref = $sth_df->fetchrow_hashref ) {
      push( @d_fields, $d_ref);
    }
    $d->{ $s_d_id }->{dtl} = \@d_fields;
  }

  return $d;
}

sub selectedvalue {
  my $ref        = shift;
  my $dvf_d_id   = shift;
  my $company_id = shift;

  my $sth_df_dt  = database->prepare( $SQL_LIB->{DF_DT}  );

  # loop through each field and see if there's a lookup value for it
  #   if there is, then get it's value from the DB
  foreach my $skey ( keys %{$ref} ) {

    # Grab unique keys for lookup
    if ( defined $dvf_d_id->{ $skey } ) {

      $sth_df_dt->execute( $dvf_d_id->{ $skey }, 
                           $company_id, 
                           $ref->{ $skey } );

      my $tmp_ref = $sth_df_dt->fetchrow_hashref ;
      $ref->{ $skey } = $tmp_ref->{df_label};
    }
  }

  return $ref;
}

sub dv {
  my $dv_name    = shift;
  my $company_id = shift;

  my $sth_dv = database->prepare( $SQL_LIB->{DV} );

  $sth_dv->execute( $dv_name, $company_id );
  my $dv = $sth_dv->fetchrow_hashref ;

  return $dv;

}

sub dvf {
  my $dv           = shift;
  my $cldl_dv_type = shift;

  my @dvf_fields;

  # DataView Fields
  my $sth_dvf = database->prepare( $SQL_LIB->{DVF} );
  $sth_dvf->execute( $dv->{dv_id} );

  # If Delete records is enabled, then add a checkbox
  if (    $dv->{dt_del} == 1 
       && $cldl_dv_type == 0 ) {
    push ( @dvf_fields, { field    => 'state',
                          checkbox =>  'true' } );
  }

  while ( my $ref = $sth_dvf->fetchrow_hashref ) {

    # Array if it's a regular form
    if ( $cldl_dv_type == 1 ) {

      push( @dvf_fields, $ref);

    } else {
    #  Make a Datatable specific array

      my $dvf_field = { field => $ref->{dvf_db_column}, 
                        title => $ref->{dvf_label} };

      $dvf_field->{sortable} = 'true' if ( $ref->{dvf_sortable} == 1 );

      # Fixup JSON
      if (    defined $ref->{dvf_data_attributes} 
           && $ref->{dvf_data_attributes} ne '' ) {
        my @json_items = split( ',', $ref->{dvf_data_attributes} );
        foreach my $json_item ( @json_items ) {
          (my $key, my $val) = split(':', $json_item);
          $dvf_field->{$key} = $val;
        } 
      }

      push( @dvf_fields, $dvf_field);
    }
  }  ### While

  return @dvf_fields;

}

sub menu {
  my $company_id = shift;
  my $menu;

  my $sth_menu = database->prepare( $SQL_LIB->{MENU} );

  $sth_menu->execute( $company_id, $company_id );

  while ( my $ref = $sth_menu->fetchrow_hashref ) {
    push( @{$menu}, $ref);
  }  

  return $menu;

}



1;
#############



my $SQL_LIB = {
     DV => 
         qq( INSERT INTO cldl_dv 
               \( company_id, dv_db_table, dv_name, dv_title, 
                  dv_data_attributes \) 
                 VALUES 
               \( ?, ?, ?, ?, ? \)
                                    
           ),
     DVF => 
         qq( INSERT INTO cldl_dvf 
               \( dv_id, dvf_db_column, dvf_key, dvf_label, dvf_name, ordr \)
                 VALUES 
               \( ?, ?, ?, ?, ?, ? \)
         ),
     LAST_ID => 
         qq( SELECT LAST_INSERT_ID() AS id ),

};

my $SRC_COLS = {
  DV => 
         {
              'dv_data_attributes' => '
                 buttonAlign: \'left\',
                 cache: true, 
                 cardView: false,
                 contentType: \'json\',
                 iconPrefix: \'fa\',
                 icons:{
                   refresh: \'glyphicon-refresh icon-refresh\',
                   toggle: \'glyphicon-list-alt icon-list-alt\',
                   columns: \'glyphicon-th icon-th\'
                 },
                 maintainSelected: true,
                 method: \'get\',
                 countColumns: 1,
                 pagination: true,
                 pageList: [ 50, 100, 250, 500],
                 pageSize: 50,
                 showHeader: true,
                 showColumns: false,
                 showRefresh: false,
                 showToggle: false,
                 sidePagination: \'client\',
                 singleSelect: false,
                 smartDisplay: true,
                 striped: true,
                 search: true',
            },
  DVF => 
            {
                  'dvf_db_column' => '',
                  'dvf_key'       => '0',
                  'dvf_label'     => '',
                  'dvf_name'      => '',
                  'dvf_sortable'  => '0',
                  'dvf_type'      => '1',
                  'ordr'          => ''
            },
};

prefix '/cldl/dvfromtable';

get '/' => sub {
  debug "IN fromtable";

  my @tbl = CLDL::Base::tables;

  template 'cldl/dvfromtable.tt', {
                           'title'  => 'Create DataView from Table List ',
                           tbl_list => \@tbl,
                        };
};

post '/' => sub {
  debug "IN fromtable";

  # DataView
  my $sth_idv = database->prepare( $SQL_LIB->{DV} );

  $sth_idv->execute( session->{company_id}, 
                     params->{dv_db_table}, params->{dv_name}, 
                     params->{dv_title}, 
                     $SRC_COLS->{DV}->{dv_data_attributes} );

  my $sth_last_id = database->prepare( $SQL_LIB->{LAST_ID} ) ;
  $sth_last_id->execute();
  my $dv = $sth_last_id->fetchrow_hashref ;

  my $schema = config->{Plugins}->{Database}->{database};
  my $working_table = params->{dv_db_table};

  debug "SCHEMA: $schema";
  debug "TABLE:  $working_table";
  
  my $column_info = database->column_info(undef, $schema, $working_table, '%');
  my $column_list = $column_info->fetchall_arrayref( 
                      { TABLE_NAME       => 1, 
                        COLUMN_NAME      => 1, 
                        mysql_type_name  => 1, 
                        TYPE_NAME        => 1, 
                        NULLABLE         => 1, 
                        mysql_is_auto_increment => 1, 
                        IS_NULLABLE      => 1, 
                        ORDINAL_POSITION => 1, 
                        mysql_is_pri_key => 1 } );


  my @sorted_column_list;
  my $sth_idvf = database->prepare( $SQL_LIB->{DVF} );
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

  redirect 'cldl/dv/display/' .  params->{dv_name};

};

1;

