package DVQuery;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

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

sub get_data {

}

1;
