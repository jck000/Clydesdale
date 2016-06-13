package CLDL::Helpers::Defaults;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;

our $VERSION = '0.00001';

my $DV_DATA_ATTRIBURES = qq(
                 buttonAlign: 'left',
                 cache: true, 
                 cardView: false,
                 contentType: 'json',
                 iconPrefix: 'fa',
                 icons:{
                   refresh: 'glyphicon-refresh icon-refresh',
                   toggle: 'glyphicon-list-alt icon-list-alt',
                   columns: 'glyphicon-th icon-th'
                 },
                 maintainSelected: true,
                 method: 'get',
                 countColumns: 1,
                 pagination: true,
                 pageList: [ 50, 100, 250, 500],
                 pageSize: 50,
                 showHeader: true,
                 showColumns: false,
                 showRefresh: false,
                 showToggle: false,
                 sidePagination: 'client',
                 singleSelect: false,
                 smartDisplay: true,
                 striped: true,
                 search: true',
            );
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
                       dvf_values        => qq( { 0 => 'Inactive', 
                                                  1 => 'Active' } ),
                       dvf_default_value => '1'
                     },
           dv_type => { 
                        dvf_values        => qq( { 0 => 'DataTable', 
                                                   1 => 'Form' } ),
                        dvf_default_value => '0'
                      },
           dt_del  => { 
                        dvf_values        => qq( { 0 => 'No', 
                                                   1 => 'Yes' } ),
                        dvf_default_value => '1'
                      },
           dt_edit => { dvf_values       => qq( { 0 => 'Not Editable', 
                                                  1 => '1-Click', 
                                                  2 => '2-Clicks' } ),
                        dvf_default_value => '2'},
          }; 







1;
