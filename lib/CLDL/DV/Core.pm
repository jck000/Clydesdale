package CLDL::DV::Core;

use Moo;
use DBI;

my ($cldl_sql_limit, 
    $cldl_sql_offset,
    $cldl_sql_sort,
    $cldl_sql_order,
    $cldl_addrecord,
    $cldl_dv_name,
    $cldl_dv,
    $cldl_dvf,
    $dbh);

has dbh             => ( is = rw );
has cldl_sql_limit  => ( is => rw, isa => Str, default => sub { 'all' } );
has cldl_sql_offset => ( is => rw, isa => Str, default => sub ( 0 } );
has cldl_sql_sort   => ( is => rw, isa => Str );
has cldl_sql_order  => ( is => rw, isa => Str, default => sub { 'ASC' } );
has cldl_add_record => ( is => rw, isa => Str, default => sub { 0 }  );
has cldl_dv_name    => ( is => rw, isa => Str );
has cldl_dv         => ( is => rw, isa => Str );
has cldl_dvf        => ( is => rw, isa => Str );

sub init {

    $cldl_sql_limit  = "";
    $cldl_sql_offset = "";
    $cldl_sql_sort   = "";
    $cldl_sql_order  = "";
    $cldl_addrecord  = "";
    $cldl_dv_name    = "";
    $cldl_dv         = {}
    $cldl_dvf        = {}
  
};



sub get_dv {
  my $self   = shift; 
  my $dbh    = shift;
  my $params = shift;

  # Set defaults
  $cldl_sql_limit  = $params->{limit}     ||= 'all';
  $cldl_sql_offset = $params->{offset}    ||= 0;
  $cldl_sql_sort   = $params->{sort}      ||= "";
  $cldl_sql_order  = $params->{order}     ||= "ASC";
  $cldl_addrecord  = $params->{addrecord} ||= 0;
  $cldl_dv_name    = $params->{dv_name}   ||= params->{dv_name_override} ;

  ### DataView
  $SQL = 
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
                    dv_select_sql,
                    dv_insert_sql,
                    dv_update_sql,
                    dv_template,
                    dv_js_functions,
                    dv_data_attributes
               FROM cldl_dv
                 WHERE dv_name    = ? 
                       AND (    company_id = ? 
                             OR company_id = 1 )
                       AND active = 1 );

  $sth_dv = database->prepare( $SQL ) ;

  $sth_dv->execute( $cldl_dv_name, session('company_id') );
  $dv = $sth_dv->fetchrow_hashref ;

  # Use DB value unless there's a param value
  my $cldl_dv_type = $dv->{'dv_type'};
  $cldl_dv_type = params->{dv_type} if ( params->{dv_type} ) ;

  my $cldl_template   = $dv->{dv_template}  ||= 'dv_form'; # defaults to dv_form


  ### DataView Fields
  my @dvf_fields;

  $SQL = 
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
                    dvf_before_display,
                    dvf_before_save,
                    dvf_values,
                    dvf_js_functions,
                    dvf_data_attributes
               FROM cldl_dvf 
                 WHERE dv_id      = ?
                       AND active = 1 
                   ORDER BY ordr  );


  # DataView Fields
  $sth_dvf = database->prepare( $SQL );
  $sth_dvf->execute( $dv->{dv_id} );

  # If Delete records is enabled, then add a checkbox
  if (    int($dv->{dt_del}) == 1 
       && $cldl_dv_type == 0 ) {
    push ( @dvf_fields, { field    => 'state',
                          checkbox => 'true' } );
  }

  while ( my $ref = $sth_dvf->fetchrow_hashref ) {

    ### Must be set in order to edit
    $dv->{idField}         = $ref->{dvf_db_column}       if ($ref->{dvf_key}      == 1);

    # Array if it's a regular form
    if ( $cldl_dv_type == 1 ) {

      push( @dvf_fields, $ref);

    } else {
      #  Make a Datatable specific array
      my $dvf_field = { field => $ref->{dvf_db_column}, 
                        title => $ref->{dvf_label} };

      $dvf_field->{sortable} = 'true' if ($ref->{dvf_sortable} == 1);

      # If it's a radio/checkbox/select AND there's a dvf_values hash, 
      # lookup the value to display
      if (  (    $ref->{dvf_type} == 4      # Radio
              || $ref->{dvf_type} == 5      # Checkbox
              || $ref->{dvf_type} == 6 )    # Select
           && $ref->{dvf_values} ne ''  ) { 
        $dvf_lookup->{ $ref->{dvf_db_column} } = eval( $ref->{dvf_values} );
      }
      
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

  foreach my $ref ( @dvf_fields ) {

    # DB Column to select from DB
    if ( $ref->{field} && $ref->{field} ne 'state') {
      push( @select, $ref->{field}) ;
    } elsif ( ! $ref->{field} && $ref->{dvf_db_column} ) {
      push( @select, $ref->{dvf_db_column}) ;
    }

    if ( defined $ref->{dvf_sort_ordr} && int($ref->{dvf_sort_ordr}) > 0 ) {
      $sort->{ $ref->{dvf_sort_ordr} } = 
                                         { 
                                           column   => $ref->{dvf_db_column}, 
                                           ordr     => $ref->{dvf_sort_ordr},
                                           sort_dir => $ref->{dvf_sort_asc_desc}
                                         };
    }

  }  ### While







  if ( $cldl_addrecord == 1 ) {
    $data = { company_id => session('company_id') } ;
  } else {


    # SQL
    if ( $dv->{dv_select_sql} && $dv->{dv_select_sql} ne '' ) {
      $SQL = $dv->{dv_select_sql};
    } else {
      $SQL = qq(SELECT ) . join(', ', @select) 
           . qq(\n  FROM ) . $dv->{dv_db_table};
    }
  
    # Additional criteria
    my ( @where, @where_values );
    my %search_params = params;
    my @search  = grep {$_ =~ /search_/} keys %search_params;
  
    foreach my $key ( @search ) {
      next if $search_params{ $key } eq '';
  
      my $search_field = $key;
      $search_field =~ s/search_//g;
  
      push( @where, "$search_field = ?");
      push( @where_values, $search_params{ $key });
    }

    # 1 = form
    if ( $cldl_dv_type == 1 ) {
  
      $SQL .= qq( WHERE ) . $dv->{idField} . qq( = ? ) ;
  
      $sth_data = database->prepare( $SQL );
      if ( params->{id} ) {
        $sth_data->execute( params->{id} );
      } else {
        $sth_data->execute( params->{$key} );
      }
      $data = $sth_data->fetchrow_hashref ;
  
    # List
    } elsif ( $cldl_dv_type == 0 ) {
  
      if ( @where ) {
        $SQL .= qq(\n WHERE ) . join('\n AND ', @where);
      }
  
      if ( $cldl_sql_sort ne "" ) {
        $SQL .= qq(\n    ORDER BY ) 
             .  $cldl_sql_sort . ' ' 
             .  $cldl_sql_order;
          
      } elsif ( keys %{$sort} ) {
  
        $SQL .= qq(\n    ORDER BY ) ;
  
        my $scnt=0;
        foreach my $skey ( sort keys %{$sort} ) {
          if ( $scnt != 0 ) {
            $SQL .= ", " . $sort->{ $skey }->{ column } ;
          } else {
            $SQL .= $sort->{ $skey }->{ column } ;
          }
          $SQL .= ' DESC' if ( $sort->{ $skey } == 1 ) ;
          $scnt++;
        }
      }
  
      if ( $cldl_sql_limit ne 'all' ) {
        $SQL .= qq(\n      LIMIT )  . $cldl_sql_limit
             .  qq( OFFSET ) . $cldl_sql_offset;
      }

      debug "\n\nSQL:\n$SQL";
  
      $sth_data   = database->prepare( $SQL );
      if ( @where ) {
        $sth_data->execute( @where_values  );
      } else {
        $sth_data->execute(  );
      }

      while ( $ref = $sth_data->fetchrow_hashref ) {

        # loop through each field and see if there's a lookup value for it
        #   if there is, then get it's value from $dvf_lookup
        foreach my $skey ( keys %{$ref} ) {
          # If there's a lookup hash, replace the value of the column
          $ref->{$skey} = $dvf_lookup->{$skey}->{ $ref->{$skey} } 
                  if ( $dvf_lookup->{$skey} );
        }

        push( @data_values, $ref);
      }

      $data = to_json( \@data_values );

    } ### If/ELSIF cldl_dv_type
  }   ### NOT Add Record


# open(my $LOG, ">", "/tmp/dv.log");
# print $LOG "DV:\n";
# print $LOG Dumper( $dv );
# print $LOG "DVF:\n";
# print $LOG Dumper( @dvf_fields );
# print $LOG "DVF_LOOKUP:\n";
# print $LOG Dumper( $dvf_lookup );
# print $LOG "DATA:\n";
# print $LOG Dumper( $data );
# close($LOG);


  ### Form
  if ( $cldl_dv_type == 1 ) {
  
    $cldl_template = 'cldl/dv_form.tt' if ( $cldl_template eq 'dv_form' ) ;

    template $cldl_template, { 
                               app_nav   => vars->{app_nav},
                               dv        => $dv, 
                               dvf       => \@dvf_fields, 
                               data      => $data,
                               save_to   => params->{dv_name},
                               cldl_menu => session('cldl_menu'),
                             };


  } elsif (    $cldl_dv_type == 0 
            || $cldl_dv_type == 2 
            || $cldl_dv_type == 3 ) {

    #debug "dv_dt.tt";

    # Datatable is always 'dv_dt'
    template 'cldl/dv_dt.tt', { 
                                 app_nav   => vars->{app_nav},
                                 dv        => $dv, 
                                 dvf       => to_json( \@dvf_fields ),
                                 cldl_menu => session('cldl_menu'),
                                 data      => $data,
                               },
                               { layout  => 'dv_dt.tt' };  # Specify layout to 
                                                           #   get other libraries
  }
}


sub existing {
  debug "IN DV EXISTING";

  # DataView
  my $sth_dv_ex = database->prepare(
                 qq( SELECT dv_name FROM cldl_dv WHERE dv_name = ?  ) );

  $sth_dv_ex->execute( params->{dv_name} );
  my $dv = $sth_dv_ex->fetchrow_hashref ;

  to_json( $dv ) ;

}


#
# save
#
sub save {
  debug "IN DV SAVE";

  my ($dv, $dvf, $data, $ref, @select, $key, $SQL, $sth_data, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @update_columns, @update_values, $key_column, $key_value, 
      $sth_update);

  debug "SAVE_DV_NAME:" . params->{save_dv_name};

####  $dv = CLDL::Helpers::Dataviews::dv( params->{save_dv_name}, session('company_id') );

#  # DataView Fields
#  $sth_dvf = database->prepare( $SQL_LIB->{DVF} );
#  $sth_dvf->execute( $dv->{dv_id} );

#  while ( $ref = $sth_dvf->fetchrow_hashref ) {

#  @dvf_fields = @{$ret_params->{dvf_fields}};
##  $dv->{idField} = $ret_params->{idField};
##  $key           = $ret_params->{idField};

  foreach my $ref ( @dvf_fields ) {
    # If it's a key, save it to add to the end of the column list
    if ( $ref->{dvf_key} == 1 ) {

      $key_column = $ref->{dvf_db_column} ;
      $key_value  = params->{ $ref->{dvf_db_column} } ;

    } else {

    # If it's just a column, add it to the column list
      push( @update_columns, $ref->{dvf_db_column}) ;
      push( @update_values,  params->{ $ref->{dvf_db_column} }) ;

    }
  }

  # Add column at the end
  if ( defined $key_value && $key_value ne '' ) {
    push( @update_values, $key_value ) ;
  }

  if ( defined $key_value && $key_value ne '' ) { 
    $SQL = qq(UPDATE ) . $dv->{dv_db_table} 
             . qq(\n SET ) . join(' = ?, ', @update_columns) . ' = ? '
             . qq(\n   WHERE ) . $key_column . qq( = ? );

  } else {
    $SQL = qq(INSERT INTO ) . $dv->{dv_db_table} 
             . qq(\n    \( ) . join(', ', @update_columns )         . qq( \) ) 
             . qq(\n VALUES ) 
             . qq(\n    \( ) . join(', ', ('?') x @update_columns ) . qq( \) );

  }

  debug "SQL:";
  debug $SQL;

  $sth_update = database->prepare( $SQL );

  debug "Executing:";
  debug @update_values;

  $sth_update->execute( @update_values );

  redirect config->{cldl}->{base_url} 
             . '/dv/display/' 
             .  params->{xdv_name};
};

get '/delete/:dv_name' => sub {
  debug "IN DV DELETE";

};

prefix 





sub display() {

}

prefix '/dv' -> sub {
  get  '/display/:dv_name'   => \&display;
  get  '/existing/:dv_name'  => \&existing;
  post '/save/:save_dv_name' => \&save;
  get  '/delete/:dv_name'    => \&delete
};


1;

