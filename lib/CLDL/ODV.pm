package CLDL::ODV;

use Dancer2;
use Dancer2::Plugin::Database;

use base qw( CLDL::OBase );

our $VERSION = '0.00001';

prefix '/dv';

get '/display/:dv_name' => sub {

  my ($dv, $dvf, $dvf_d_id, $d, $df, $data, $ref, $d_ref, $multi_values,
      @select, $key, $sort, $SQL, @dvf_fields, $dvf_field,
      $sth_dv, $sth_dvf, $sth_data, @data_values, $sth_d, $sth_df) ;

  my $cldl_sql_limit  = params->{limit}     ||= 'all';
  my $cldl_sql_offset = params->{offset}    ||= 0;
  my $cldl_sql_sort   = params->{sort}      ||= "";
  my $cldl_sql_order  = params->{order}     ||= "ASC";

  my $cldl_addrecord  = params->{addrecord} ||= 0;
  my $cldl_dv_name    = params->{dv_name}   ||= params->{dv_name_override} ;
  my $cldl_dv_type    = undef;
  my $cldl_template   = undef;

  ### DataView
  $sth_dv = database->prepare( 
            'SELECT dv_id,
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
                       AND active = 1 '
  );

  $sth_dv->execute( $cldl_dv_name, session('company_id') );
  $dv = $sth_dv->fetchrow_hashref ;



  # Use DB value unless there's a param value
  $cldl_dv_type = $dv->{'dv_type'};
  $cldl_dv_type = params->{dv_type} if ( params->{dv_type} ) ;

  $cldl_template   = $dv->{dv_template}  ||= 'dv_form'; # defaults to dv_form

  ### DataView Fields
  $sth_dvf = database->prepare( 
          q( SELECT dvf_id, 
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
  );
  $sth_dvf->execute( $dv->{dv_id} );

  # If Delete records is enabled, then add a checkbox
  if (    defined $dv->{dt_del} 
       && $dv->{dt_del} == 1 
       && $cldl_dv_type == 0 ) {
    push ( @dvf_fields, { field    => 'state',
                          checkbox => 'true' } );
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

  $dv->{idField} = $dvf_field->{idField};
  $key           = $dvf_field->{idField};

  foreach my $ref ( @dvf_fields ) {

    # DB Column to select from DB
    if ( $ref->{field} && $ref->{field} ne 'state') {
      push( @select, $ref->{field}) ;
    } elsif ( ! $ref->{field} && $ref->{dvf_db_column} ) {
      push( @select, $ref->{dvf_db_column}) ;
    }

    # Is it checkbox, radio or select?
    if ( defined $ref->{d_id} ) { 
      $dvf_d_id->{ $ref->{dvf_name} } = $ref->{d_id};
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

  # Grab Values for display in form to build checkbox, radio, select)
  if (    defined $cldl_dv_type 
       && $cldl_dv_type == 1 ) {

    $d = {};

    # DataView Field Values ( checkbox, radio, select)
    $sth_d  = database->prepare( 
          q( SELECT d_id, 
                    d_name
               FROM cldl_d
                 WHERE d_id           = ? 
                       AND (    company_id = ? 
                             OR company_id = 1 )
                       AND active     = 1 )
    );
    $sth_df = database->prepare( 
          q( SELECT df_id, 
                    ordr,
                    df_label,
                    df_value,
                    df_default
               FROM cldl_df 
                 WHERE d_id       = ?
                       AND active = 1 
                   ORDER BY ordr  )
   );

    foreach my $skey ( keys %{$dvf_d_id} ) { # skey   = field name (s=search)
      my $s_d_id = $dvf_d_id->{ $skey };     # s_d_id = key to data(s=search)
      $sth_d->execute( $s_d_id, session('company_id') );
      $d->{ $s_d_id } = $sth_d->fetchrow_hashref ;

      my @d_fields = ();
      $sth_df->execute( $s_d_id );
      while ( my $d_ref = $sth_df->fetchrow_hashref ) {
        push( @d_fields, $d_ref);
      }
      $d->{ $s_d_id }->{dtl} = \@d_fields;
    }
  }

  if ( $cldl_addrecord == 1 ) {
    $data = { company_id => session('company_id') } ;
  } else {
    # Data
    debug "SQL_ID: " . $dv->{sql_id};
    if ( $dv->{sql_id} && $dv->{sql_id} ne '' ) {
#      $SQL = CLDL::OBase::sql_stmt( $dv->{sql_id}, session->{company_id} );
    } else {
      $SQL = qq(SELECT ) . join(', ', @select) 
           . qq(\n  FROM ) . $dv->{dv_db_table};
    }
  
    # Additional criteria
    my ( @where, @where_values );
    my %cond_params = params;
    my @conditions  = grep {$_ =~ /cond_/} keys %cond_params;
  
    foreach my $key ( @conditions ) {
      next if $cond_params{ $key } eq '';
  
      my $cond_field = $key;
      $cond_field =~ s/cond_//g;
  
      push( @where, "$cond_field = ?");
      push( @where_values, $cond_params{ $key });
    }
  
    # 1 = form
    if ( $cldl_dv_type == 1 ) {
  
      $SQL .= qq( WHERE ) . $key . qq( = ? ) ;
  
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
        my $sth_df_dt  = database->prepare( 
          q( SELECT df_label
               FROM cldl_d d,
                    cldl_df df
                 WHERE d.d_id           = ?
                       AND (    d.company_id = ?
                             OR d.company_id = 1 )
                       AND d.active     = 1

                       AND df.df_value  = ?
                       AND df.d_id      = d.d_id
                       AND df.active    = 1  )
        );

        # loop through each field and see if there's a lookup value for it
        #   if there is, then get it's value from the DB
        foreach my $skey ( keys %{$ref} ) {

          # Grab unique keys for lookup
          if ( defined $dvf_d_id->{ $skey } ) {

            $sth_df_dt->execute( $dvf_d_id->{ $skey }, 
                                 session('company_id'), 
                                 $ref->{ $skey } );

            my $tmp_ref = $sth_df_dt->fetchrow_hashref ;
            $ref->{ $skey } = $tmp_ref->{df_label};
          }
        }





        push( @data_values, $ref);
      }

      $data = to_json( \@data_values );

    } ### If/ELSIF cldl_dv_type
  }   ### NOT Add Record



  ### Form
  if ( $cldl_dv_type == 1 ) {
  
    $cldl_template = 'cldl/dv_form.tt' if ( $cldl_template eq 'dv_form' ) ;

    template $cldl_template,
                           { 
                             app_nav => vars->{app_nav},
                             d       => $d,
                             dv      => $dv, 
                             dvf     => \@dvf_fields, 
                             menu    => session->{cldl_menu},
                             data    => $data,
                             save_to => params->{dv_name} };


  } elsif (    $cldl_dv_type == 0 
            || $cldl_dv_type == 2 
            || $cldl_dv_type == 3 ) {

    #debug "dv_dt.tt";

    # Datatable is always 'dv_dt'
    template 'cldl/dv_dt.tt', 
                         { 
                           app_nav => vars->{app_nav},
                           dv      => $dv, 
                           dvf     => to_json( \@dvf_fields ),
                           menu    => session->{cldl_menu},
                           data    => $data,
                         },
                         { layout  => 'dv_dt.tt' };  # Specify layout to 
                                                     #   get other libraries
  }
};


get '/existing/:dv_name' => sub {
  debug "IN DV EXISTING";

  # DataView
  my $sth_dv_ex = database->prepare(
                 qq( SELECT dv_name FROM cldl_dv WHERE dv_name = ?  ) );

  $sth_dv_ex->execute( params->{dv_name} );
  my $dv = $sth_dv_ex->fetchrow_hashref ;

  to_json( $dv ) ;

};

post '/save/:xdv_name' => sub {
  debug "IN DV SAVE";

  my ($dv, $dvf, $data, $ref, @select, $key, $SQL, $sth_data, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @update_columns, @update_values, $key_column, $key_value, 
      $sth_update);

  debug "XDV_NAME:" . params->{xdv_name};

########  $dv = CLDL::OBase::dv( params->{xdv_name}, session->{company_id} );

#  # DataView Fields
#  $sth_dvf = database->prepare( $SQL_LIB->{DVF} );
#  $sth_dvf->execute( $dv->{dv_id} );

#  while ( $ref = $sth_dvf->fetchrow_hashref ) {

#  my $ret_params = CLDL::OBase::dvf( $dv, $cldl_dv_type );

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
             . '/cldl/dv/display/' 
             .  params->{xdv_name};
};

get '/delete/:dv_name' => sub {
  debug "IN DV DELETE";

};


1;

