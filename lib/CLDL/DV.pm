package CLDL::DV;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

use CLDL::DVQuery;

our $VERSION = '0.00002';

prefix '/dv' ;

#
# Display DataView
#
get '/select/:dv_name_id' => sub {

  my ($dv, $dvf, @dvf_fields, $data, $ref, $multi_values,
      @select, $key, $sort, $SQL, $sth_dv, $sth_dvf, $sth_data, @data_values) ;

  # Set defaults
  my $cldl_sql_limit   = params->{limit}       ||= 'all';
  my $cldl_sql_offset  = params->{offset}      ||= 0;
  my $cldl_sql_sort    = params->{sort}        ||= "";
  my $cldl_sql_order   = params->{order}       ||= "ASC";
  my $cldl_addrecord   = params->{addrecord}   ||= 0;
  my $cldl_dv_name     = params->{dv_name_id}  ||= params->{dv_name_override} ;
  
  var generate_tt     => params->{generate_tt} ||= 0;

#  debug "SELECT: " . vars->{generate_tt};

  ### DataView
  $dv = get_dv( $cldl_dv_name, session('company_id') );

  # Use DB value unless there's a param value
  my $cldl_dv_type = $dv->{'dv_type'};
  $cldl_dv_type = params->{dv_type} if ( params->{dv_type} ) ;

  my $cldl_template   = $dv->{dv_template} ||= 'dv_form'; # defaults to dv_form

  ### DataView Fields
  $dvf = get_dvf( $dv->{dv_id} );

#  debug $dvf;

  # If Delete records is enabled, then add a checkbox
  if (    int($dv->{dt_del}) == 1 
       && $cldl_dv_type == 0 ) {
    push ( @dvf_fields, { field    => 'state',
                          checkbox => 'true' } );
  }

# [

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
    if ( $ref->{field} && (    $ref->{field} ne 'state'
                            && $ref->{field} ne 'actionmenu' ) ) {
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

#      debug "\n\nDV DT SQL:\n$SQL";
  
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

# debug "DATA:";
# debug @data_values;
# debug "\n";
# debug $data;

    } ### If/ELSIF cldl_dv_type
  }   ### NOT Add Record

  ### Form
  if ( $cldl_dv_type == 1 ) {

  
    $cldl_template = 'cldl/dv_form.tt' if ( $cldl_template eq 'dv_form' ) ;

    return template $cldl_template, { 
                               cldl_dv_name_id  => $cldl_dv_name,
                               dv               => $dv, 
                               dvf              => \@dvf_fields, 
                               data             => $data,
#                               cldl_menu        => CLDL::Menu::get_menu( session('menu_id') ),
                             };


  } elsif (    $cldl_dv_type == 0 
            || $cldl_dv_type == 2 
            || $cldl_dv_type == 3 ) {

    my $ret_dvf_fields = undef;
#    if (    $dv->{dv_name} eq 'dv_list' 
#         || $dv->{dv_name} eq 'dvf_list' ) {
#      $ret_dvf_fields = '[';
#
#      my $cnt=0;
#      foreach my $dvf_entry ( @dvf_fields ) {
#        $ret_dvf_fields .= ',' if ( $cnt > 0 );
#        $ret_dvf_fields .= to_json( $dvf_entry );
#        $cnt++;
#      }
#      $ret_dvf_fields .= ',{"field":"actionmenu","title":"Actions","align":"center","formatter":actionmenu, "events":actionevents}';
#      $ret_dvf_fields .= ']';
#    } else {
      $ret_dvf_fields = to_json( \@dvf_fields ),
#    }

    # Datatable is always 'dv_dt'
    return template 'cldl/dv_dt.tt', { 
                                 cldl_dv_name_id => $cldl_dv_name,
                                 dv              => $dv, 
#                                 dvf             => to_json( \@dvf_fields ),
                                 dvf             => $ret_dvf_fields,
#                                 cldl_menu       => CLDL::Cache::get_menu( session('company_id'), session('role_id') ),
#                                 cldl_menu       => session('cldl_menu'),
                                 data            => $data,
                               },
                               { layout  => 'dv_dt.tt' };  # Specify layout to 
                                                           #   get other libraries
  }
};

post '/:action/:dv_name_id' => sub {
#  debug "In update-insert-delete ";

#  debug "ACTION: " . params->{action};
#  debug "DV_ID:  " . params->{dv_name_id};

  if ( params->{action} !~ 'update|insert|delete' ) {

#    debug "Return error";
            status '404';
            return "The page you are trying to reach does not exist. ";
  }

  &updates_to_db;

};


get '/select/:dv_id/permissions' => sub {

  my $dv_id   = params->{dv_id};
  my $dv_name = params->{dv_name};

  my $sql_select_role = undef;

  if ( session('role_id') == 5 ) {
    $sql_select_role = q( 
          SELECT role_id,
                 role_name
            FROM cldl_role
              WHERE (    company_id = ?
                      OR company_id = 1 )
                    AND active = 1  );
  } else {
    $sql_select_role = q( 
          SELECT role_id,
                 role_name
            FROM cldl_role
              WHERE     company_id = ?
                    AND active     = 1  );

  }

  my $sth_select_roles = database->prepare( $sql_select_role );

  my $dv_perms;

  $sth_select_roles->execute( session('company_id') );
  while ( my $ref = $sth_select_roles->fetchrow_hashref ) {
    $dv_perms->{ $ref->{role_id} } = $ref;
  }

  my $sth_select_roles_for_dv = database->prepare(
         'SELECT role_permission_id,
                 role_id,
                 dv_id
            FROM cldl_role_permission_dv
              WHERE dv_id = ?'
  );

  $sth_select_roles_for_dv->execute( $dv_id );
  while ( my $ref = $sth_select_roles_for_dv->fetchrow_hashref ) {
    $dv_perms->{ $ref->{role_id} }->{role_checked} = 1 ;
  }

  my @ret_array_perms;

  foreach my $dv_key ( sort keys $dv_perms ) {
    push( @ret_array_perms, $dv_perms->{$dv_key} );
  }

  return to_json( \@ret_array_perms );

};




# Save permissions
get '/update/:dv_id/permissions' => sub {

  my $dv_id   = params->{dv_id};
  my $dv_name = params->{dv_name};

  my $sql_delete_permissions = undef;
  if ( session('role_id') == 5 ) {
    $sql_delete_permissions = q(
                DELETE FROM cldl_role_permission_dv
                  WHERE     dv_id = ?
                        AND role_id IN 
                            ( SELECT role_id
                                FROM cldl_role
                                  WHERE (    company_id = ?
                                          OR company_id = 1 )
                                        AND active = 1  ));
  } else {
    $sql_delete_permissions = q(
                DELETE FROM cldl_role_permission_dv
                  WHERE     dv_id = ?
                        AND role_id IN 
                            ( SELECT role_id
                                FROM cldl_role
                                  WHERE     company_id = ?
                                        AND active     = 1  ));

  }
  my $sth_delete_permissions = database->prepare( $sql_delete_permissions );

  my $sth_insert_role_permission = database->prepare(
    'INSERT INTO cldl_role_permission_dv ( role_id, dv_id) VALUES ( ?, ?)'
  );

  $sth_delete_permissions->execute( $dv_id, session('company_id') );

  my $role_ids = params;

  delete $role_ids->{dv_id};
  foreach my $key ( keys %{$role_ids} ) {
    $key =~ m/(\d+)_.*/;
    $sth_insert_role_permission->execute( $1, $dv_id );
  }

  return to_json({ status => 0 });

};


sub updates_to_db {
#  debug "IN DV UPDATES TO DB";

  my ($dv, $dvf, $data, $ref, @select, $key, $SQL, $sth_data, 
      @dvf_fields, @data_values, $sth_dv, $sth_dvf, 
      @upd_db_columns, @upd_db_values, $key_column, $key_value, 
      $sth_upd_db);

#  debug "DV_NAME:" . params->{dv_name_id};

  my $cldl_dv_name    = params->{dv_name_id} ||= params->{dv_name_override} ;

  ### DataView
  $dv = get_dv( $cldl_dv_name, session('company_id') );

  ### DataView Fields
  $dvf = get_dvf( $dv->{dv_id} );

  if ( params->{action} eq 'update' ) {

    foreach my $ref ( @{$dvf->{dvf_fields}} ) {
      #
      # If it's a key, save it to add to the end of the column list
      if ( $ref->{dvf_key} == 1 ) {

        $key_column = $ref->{dvf_db_column} ;
        $key_value  = params->{ $ref->{dvf_db_column} } ;
  
      } elsif ( defined params->{ $ref->{dvf_db_column} } ) {
  
        # If it's not a key column, add it to the column list
        push( @upd_db_columns, $ref->{dvf_db_column}) ;
        push( @upd_db_values,  params->{ $ref->{dvf_db_column} }) ;
  
      }
    }

    # Add column at the end
    if ( defined $key_value && $key_value ne '' ) {
      push( @upd_db_values, $key_value ) ;
    }

    $SQL = qq(UPDATE ) . $dv->{dv_db_table} 
             . qq(\n SET ) . join(' = ?, ', @upd_db_columns) . ' = ? '
             . qq(\n   WHERE ) . $key_column . qq( = ? );

  } elsif ( params->{action} eq 'insert' ) {

    foreach my $ref ( @{$dvf->{dvf_fields}} ) {
      if ( params->{ $ref->{dvf_db_column} } ) {
        # add it to the column list
        push( @upd_db_columns, $ref->{dvf_db_column}) ;
        push( @upd_db_values,  params->{ $ref->{dvf_db_column} }) ;
      }
    }
    $SQL = qq(INSERT INTO ) . $dv->{dv_db_table} 
             . qq(\n    \( ) . join(', ', @upd_db_columns )         . qq( \) ) 
             . qq(\n VALUES ) 
             . qq(\n    \( ) . join(', ', ('?') x @upd_db_columns ) . qq( \) );
    

  } elsif ( params->{action} eq 'delete' ) {

    foreach my $ref ( @dvf_fields ) {
      # If it's a key, save it to add to the end of the column list
      if ( $ref->{dvf_key} == 1 ) {
    
        $key_column = $ref->{dvf_db_column} ;
        $key_value  = params->{ $ref->{dvf_db_column} } ;
      }
    }

    # Add column at the end
    if ( defined $key_value && $key_value ne '' ) {
      push( @upd_db_values, $key_value ) ;
    }

    $SQL = qq(DELETE FROM ) . $dv->{dv_db_table} 
             . qq(\n   WHERE ) . $key_column . qq( = ? );
    

  } 


#  debug "SQL:";
#  debug $SQL;

  $sth_upd_db = database->prepare( $SQL );

#  debug "Executing:";
#  debug @upd_db_values;

  $sth_upd_db->execute( @upd_db_values );

  my $save_status = 0;  ## Success
  if ( $sth_upd_db->err ) { 
    $save_status = 1;
  } 

  my $dv_next = $dv->{dv_next} || session('cldl_return_to_page'); 

  header( 'Content-Type'  => 'text/json' );
  header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );

  to_json( { status         => $save_status,
             cldl_next_page => $dv_next });

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
                    dv_next,
                    dv_data_attributes
               FROM cldl_dv
                 WHERE     dv_name = ? 
                       AND active  = 1 
                       AND (    company_id = ? 
                             OR company_id = 1 ) 
           )
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
