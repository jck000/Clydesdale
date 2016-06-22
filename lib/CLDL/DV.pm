package CLDL::DV;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

prefix '/cldl/dv' ;

#
# Display DataView
#
get '/select/:dv_name_id' => sub {

  my ($dv, $dvf, @dvf_fields, $data, $ref, $multi_values,
      @select, $key, $sort, $SQL, $sth_dv, $sth_dvf, $sth_data, @data_values) ;

  # Set defaults
  my $cldl_sql_limit  = params->{limit}      ||= 'all';
  my $cldl_sql_offset = params->{offset}     ||= 0;
  my $cldl_sql_sort   = params->{sort}       ||= "";
  my $cldl_sql_order  = params->{order}      ||= "ASC";
  my $cldl_addrecord  = params->{addrecord}  ||= 0;
  my $cldl_dv_name    = params->{dv_name_id} ||= params->{dv_name_override} ;

  ### DataView
  $dv = get_dv( $cldl_dv_name, session('company_id') );

  # Use DB value unless there's a param value
  my $cldl_dv_type = $dv->{'dv_type'};
  $cldl_dv_type = params->{dv_type} if ( params->{dv_type} ) ;

  my $cldl_template   = $dv->{dv_template} ||= 'dv_form'; # defaults to dv_form

  ### DataView Fields
  $dvf = get_dvf( $dv->{dv_id} );

  debug $dvf;

  # If Delete records is enabled, then add a checkbox
  if (    int($dv->{dt_del}) == 1 
       && $cldl_dv_type == 0 ) {
    push ( @dvf_fields, { field    => 'state',
                          checkbox => 'true' } );
  }

# from get_dvf  $dvf->{dvf_fields} = \@dvf_fields;
  foreach my $ref ( @{$dvf->{dvf_fields}} ) {

    ### Must be set in order to edit
    $dv->{idField} = $ref->{dvf_db_column} if ( $ref->{dvf_key} == 1 );

    # Array if it's a regular form
    if ( $cldl_dv_type == 1 ) {

      push( @dvf_fields, $ref);

    } else {
      #  Make a Datatable specific array
      my $dvf_field = { field => $ref->{dvf_db_column}, 
                        title => $ref->{dvf_label} };

#      $qis_svryq->{fbegnoyr} = 'gehr' vs ($ers->{qis_fbegnoyr} == 1);

      
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
  }  ### foreach

  ### Combine with loop above?
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

  }  ### foreach


  if ( $cldl_addrecord == 1 ) {
    $data = { company_id => session('company_id'),
              addrecord  => 1,
              dv_name_id => $cldl_dv_name } ;
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

      debug "\n\nDV DT SQL:\n$SQL";
  
      $sth_data   = database->prepare( $SQL );
      if ( @where ) {
        $sth_data->execute( @where_values  );
      } else {
        $sth_data->execute(  );
      }

      while ( $ref = $sth_data->fetchrow_hashref ) {
        foreach my $key ( keys %{$ref} ) {
          if (    ref($dvf->{ $key }->{dvf_values}) eq 'HASH' 
               && $ref->{$key} ne "" ) {

            $ref->{$key} = $dvf->{$key}->{dvf_values}->{$ref->{$key}};
          }
        }
        push( @data_values, $ref);
      }


      $data = to_json( \@data_values );

debug "DATA:";
debug @data_values;
debug "\n";
debug $data;

    } ### If/ELSIF cldl_dv_type
  }   ### NOT Add Record

  ### Form
  if ( $cldl_dv_type == 1 ) {

  
    $cldl_template = 'cldl/dv_form.tt' if ( $cldl_template eq 'dv_form' ) ;

    return template $cldl_template, { 
                               cldl_dv_name_id => $cldl_dv_name,
                               dv              => $dv, 
                               dvf             => \@dvf_fields, 
                               data            => $data,
                               cldl_menu       => session('cldl_menu'),
                             };


  } elsif (    $cldl_dv_type == 0 
            || $cldl_dv_type == 2 
            || $cldl_dv_type == 3 ) {

    # Datatable is always 'dv_dt'
    return template 'cldl/dv_dt.tt', { 
                                 cldl_dv_name_id => $cldl_dv_name,
                                 dv              => $dv, 
                                 dvf             => to_json( \@dvf_fields ),
                                 cldl_menu       => session('cldl_menu'),
                                 data            => $data,
                               },
                               { layout  => 'dv_dt.tt' };  # Specify layout to 
                                                           #   get other libraries
  }
};


post '/update/:dv_name_id' => sub {
  debug "IN DV UPDATE";

  my ($dv, $dvf, $data, $ref, @select, $key, $SQL, $sth_data, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @update_columns, @update_values, $key_column, $key_value, 
      $sth_update);

  debug "DV_NAME:" . params->{dv_name_id};

  my $cldl_dv_name    = params->{dv_name_id} ||= params->{dv_name_override} ;

  ### DataView
  $dv = get_dv( $cldl_dv_name, session('company_id') );

  ### DataView Fields
  $dvf = get_dvf( $dv->{dv_id} );

  foreach my $ref ( @{$dvf->{dvf_fields}} ) {
    # If it's a key, save it to add to the end of the column list
    if ( $ref->{dvf_key} == 1 ) {

      $key_column = $ref->{dvf_db_column} ;
      $key_value  = params->{ $ref->{dvf_db_column} } ;

    } elsif ( defined params->{ $ref->{dvf_db_column} } ) {

      # If it's not a key column, add it to the column list
      push( @update_columns, $ref->{dvf_db_column}) ;
      push( @update_values,  params->{ $ref->{dvf_db_column} }) ;

    }
  }

  # Add column at the end
  if ( defined $key_value && $key_value ne '' ) {
    push( @update_values, $key_value ) ;
  }

  $SQL = qq(UPDATE ) . $dv->{dv_db_table} 
           . qq(\n SET ) . join(' = ?, ', @update_columns) . ' = ? '
           . qq(\n   WHERE ) . $key_column . qq( = ? );


  debug "SQL:";
  debug $SQL;

  $sth_update = database->prepare( $SQL );

  debug "Executing:";
  debug @update_values;

  $sth_update->execute( @update_values );

  redirect config->{cldl}->{base_url} 
             . '/dv/select/' 
             .  $cldl_dv_name;
};


post '/insert/:dv_name_id' => sub {
  debug "IN DV UPDATE";

  my ($dv, $dvf, $data, $key, $SQL, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @insert_columns, @insert_values, $key_column, $key_value, 
      $sth_insert);

  debug "DV_NAME:" . params->{dv_name_id};

  my $cldl_dv_name    = params->{dv_name_id} ||= params->{dv_name_override} ;

  ### DataView
  $dv = get_dv( $cldl_dv_name, session('company_id') );

  ### DataView Fields
  $dvf = get_dvf( $dv->{dv_id} );

  foreach my $ref ( @{$dvf->{dvf_fields}} ) {
    if ( params->{ $ref->{dvf_db_column} } ) {
      # add it to the column list
      push( @insert_columns, $ref->{dvf_db_column}) ;
      push( @insert_values,  params->{ $ref->{dvf_db_column} }) ;
    }
  }

  $SQL = qq(INSERT INTO ) . $dv->{dv_db_table} 
           . qq(\n    \( ) . join(', ', @insert_columns )         . qq( \) ) 
           . qq(\n VALUES ) 
           . qq(\n    \( ) . join(', ', ('?') x @insert_columns ) . qq( \) );


  debug "SQL:";
  debug $SQL;

  $sth_insert = database->prepare( $SQL );

  debug "Executing:";
  debug @insert_values;

  $sth_insert->execute( @insert_values );

  redirect config->{cldl}->{base_url} 
             . '/dv/select/' 
             .  $cldl_dv_name;
};



### NOT DONE AT ALL
post '/delete/:dv_name_id' => sub {
  debug "IN DV DELETE";

  my ($dv, $dvf, $data, $ref, @select, $key, $SQL, $sth_data, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @delete_columns, @delete_values, $key_column, $key_value, 
      $sth_delete);

  debug "DV_NAME:" . params->{dv_name_id};

  my $cldl_dv_name    = params->{dv_name_id} ||= params->{dv_name_override} ;

  foreach my $ref ( @dvf_fields ) {
    # If it's a key, save it to add to the end of the column list
    if ( $ref->{dvf_key} == 1 ) {

      $key_column = $ref->{dvf_db_column} ;
      $key_value  = params->{ $ref->{dvf_db_column} } ;

    } else {

    # If it's just a column, add it to the column list
      push( @delete_columns, $ref->{dvf_db_column}) ;
      push( @delete_values,  params->{ $ref->{dvf_db_column} }) ;

    }
  }

  # Add column at the end
  if ( defined $key_value && $key_value ne '' ) {
    push( @delete_values, $key_value ) ;
  }

  $SQL = qq(DELETE FROM ) . $dv->{dv_db_table} 
           . qq(\n   WHERE ) . $key_column . qq( = ? );


  debug "SQL:";
  debug $SQL;

  $sth_delete = database->prepare( $SQL );

  debug "Executing:";
  debug @delete_values;

  $sth_delete->execute( @delete_values );

  redirect config->{cldl}->{base_url} 
             . '/dv/select/' 
             .  $cldl_dv_name;
};

### Maybe?
sub return_dv_dt {

}

### Maybe?
sub return_dv_form {

}



sub get_dv {
  my $dv_name_id = shift;
  my $company_id = shift;

  my $sth_dv = database->prepare( 
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
                       AND active = 1 )
  );

  $sth_dv->execute( $dv_name_id, $company_id );
  my $dv = $sth_dv->fetchrow_hashref ;

  return $dv;

}


sub get_dvf {
  my $dv           = shift;

  my @dvf_fields;
  my $dvf;

  # DataView Fields
  my $sth_dvf = database->prepare( 
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
                    dvf_default_value,
                    dvf_js_functions,
                    dvf_data_attributes
               FROM cldl_dvf 
                 WHERE dv_id      = ?
                       AND active = 1 
                   ORDER BY ordr  )
  );
  $sth_dvf->execute( $dv );

  while ( my $ref = $sth_dvf->fetchrow_hashref ) {
    ### If there's a hash that's used to lookup values
    if (    defined $ref->{dvf_values} 
         && $ref->{dvf_values} ne '' ) {
      my $dvf_values_hash=eval($ref->{dvf_values});
      $ref->{dvf_values} = $dvf_values_hash;
    }

    $dvf->{ $ref->{dvf_db_column} } = $ref;
    push( @dvf_fields, $ref);

  }  ### While

  $dvf->{dvf_fields} = \@dvf_fields;

  return $dvf;
}




1;


### # Return an array of table names
### sub tables {
###     my @tbl;
### 
###     my @table_list = database->tables('', '', '', 'TABLE');
### 
###     for my $table ( @table_list) {
###       $table =~ s/`//g;
###       my @tmp_tbl = split( /\./, $table);
###       push @tbl, $tmp_tbl[1];
###     }
### 
###     return @tbl;
### }
### 
### sub selectedvalue {
###   my $ref        = shift;
###   my $dvf_d_id   = shift;
###   my $company_id = shift;
### 
###   my $sth_df_dt  = database->prepare( $SQL_LIB->{DF_DT}  );
### 
###   # loop through each field and see if there's a lookup value for it
###   #   if there is, then get it's value from the DB
###   foreach my $skey ( keys %{$ref} ) {
### 
###     # Grab unique keys for lookup
###     if ( defined $dvf_d_id->{ $skey } ) {
### 
###       $sth_df_dt->execute( $dvf_d_id->{ $skey }, 
###                            $company_id, 
###                            $ref->{ $skey } );
### 
###       my $tmp_ref = $sth_df_dt->fetchrow_hashref ;
###       $ref->{ $skey } = $tmp_ref->{df_label};
###     }
###   }
### 
###   return $ref;
### }
### 

### package CLDL::Base;
### 
### use Dancer ':syntax';
### use Dancer::Plugin::Database;
### 
### our $VERSION = '0.00001';
### 
### 
### # SQL statements
### my $SQL_LIB = {
###      DV => 
###          qq( SELECT dv_id,
###                     dv_name,
###                     dv_db_table,
###                     dv_type,
###                     dv_title,
###                     dt_add,
###                     dt_del,
###                     dt_edit, 
###                     dv_name_add, 
###                     dv_name_edit, 
###                     dv_template,
###                     dv_js_functions,
###                     dv_data_attributes
###                FROM cldl_dv
###                  WHERE dv_name    = ? 
###                        AND (    company_id = ? 
###                              OR company_id = 1 )
###                        AND active = 1 ),
###      DVF => 
###          qq( SELECT dvf_id, 
###                     ordr,
###                     dvf_db_column,
###                     dvf_name,
###                     dvf_label, 
###                     dvf_type,
###                     dvf_key,
###                     dvf_placeholder,
###                     dvf_help,
###                     dvf_sortable,
###                     dvf_sort_ordr,
###                     dvf_sort_asc_desc,
###                     d_id,
###                     dvf_js_functions,
###                     dvf_data_attributes
###                FROM cldl_dvf 
###                  WHERE dv_id      = ?
###                        AND active = 1 
###                    ORDER BY ordr  ),
###      D => 
###          qq( SELECT d_id, 
###                     d_name
###                FROM cldl_d
###                  WHERE d_id           = ? 
###                        AND (    company_id = ? 
###                              OR company_id = 1 )
###                        AND active     = 1 ),
###      DF => 
###          qq( SELECT df_id, 
###                     ordr,
###                     df_label,
###                     df_value,
###                     df_default
###                FROM cldl_df 
###                  WHERE d_id       = ?
###                        AND active = 1 
###                    ORDER BY ordr  ),
###      DF_DT => 
###          qq( SELECT df_label
###                FROM cldl_d d,
###                     cldl_df df
###                  WHERE d.d_id           = ? 
###                        AND (    d.company_id = ? 
###                              OR d.company_id = 1 )
###                        AND d.active     = 1 
### 
###                        AND df.df_value  = ?
###                        AND df.d_id      = d.d_id 
###                        AND df.active    = 1  ),
###      DF_DT =>
###          qq( SELECT df_label
###                FROM cldl_d d,
###                     cldl_df df
###                  WHERE d.d_id           = ? 
###                        AND (    d.company_id = ? 
###                              OR d.company_id = 1 )
###                        AND d.active     = 1 
### 
###                        AND df.df_value  = ?
###                        AND df.d_id      = d.d_id 
###                        AND df.active    = 1  ),
###      MENU => qq( 
###                 SELECT menu_id,
###                        ordr,
###                        menu_label,
###                        menu_link,
###                        menu_js_functions,
###                        menu_data_attributes,
###                        menu_notes
###                   FROM cldl_menu
###                     WHERE (    company_id = ?
###                             OR company_id = 1 )
###                           AND pmenu_id IS NULL
###                           AND active   = 1
###                   UNION
###                 SELECT pmenu_id AS menu_id,
###                        ordr,
###                        menu_label,
###                        menu_link,
###                        menu_js_functions,
###                        menu_data_attributes,
###                        menu_notes
###                   FROM cldl_menu
###                     WHERE (    company_id = ?
###                             OR company_id = 1 )
###                           AND pmenu_id IS NOT NULL
###                           AND active   = 1
###                    ORDER BY menu_id, ordr ),
### };
### 
### # Return an array of table names
### sub tables {
###     my @tbl;
### 
###     my @table_list = database->tables('', '', '', 'TABLE');
### 
###     for my $table ( @table_list) {
###       $table =~ s/`//g;
###       my @tmp_tbl = split( /\./, $table);
###       push @tbl, $tmp_tbl[1];
###     }
### 
###     return @tbl;
### }
### 
### sub formdatalists {
###   my $dvf_d_id   = shift;
###   my $company_id = shift;
### 
###   my $d = {};
### 
###   # DataView Field Values ( checkbox, radio, select)
###   my $sth_d  = database->prepare( $SQL_LIB->{D}  );
###   my $sth_df = database->prepare( $SQL_LIB->{DF} );
### 
###   foreach my $skey ( keys %{$dvf_d_id} ) { # skey   = field name (s=search)
###     my $s_d_id = $dvf_d_id->{ $skey };     # s_d_id = key to data(s=search)
###     $sth_d->execute( $s_d_id, $company_id );
###     $d->{ $s_d_id } = $sth_d->fetchrow_hashref ;
### 
###     my @d_fields = ();
###     $sth_df->execute( $s_d_id );
###     while ( my $d_ref = $sth_df->fetchrow_hashref ) {
###       push( @d_fields, $d_ref);
###     }
###     $d->{ $s_d_id }->{dtl} = \@d_fields;
###   }
### 
###   return $d;
### }
### 
### sub selectedvalue {
###   my $ref        = shift;
###   my $dvf_d_id   = shift;
###   my $company_id = shift;
### 
###   my $sth_df_dt  = database->prepare( $SQL_LIB->{DF_DT}  );
### 
###   # loop through each field and see if there's a lookup value for it
###   #   if there is, then get it's value from the DB
###   foreach my $skey ( keys %{$ref} ) {
### 
###     # Grab unique keys for lookup
###     if ( defined $dvf_d_id->{ $skey } ) {
### 
###       $sth_df_dt->execute( $dvf_d_id->{ $skey }, 
###                            $company_id, 
###                            $ref->{ $skey } );
### 
###       my $tmp_ref = $sth_df_dt->fetchrow_hashref ;
###       $ref->{ $skey } = $tmp_ref->{df_label};
###     }
###   }
### 
###   return $ref;
### }
### 


### 
### sub menu {
###   my $company_id = shift;
###   my $menu;
### 
###   my $sth_menu = database->prepare( $SQL_LIB->{MENU} );
### 
###   $sth_menu->execute( $company_id, $company_id );
### 
###   while ( my $ref = $sth_menu->fetchrow_hashref ) {
###     push( @{$menu}, $ref);
###   }  
### 
###   return $menu;
### 
### }
### 
### 
### 
### 1;
### 
