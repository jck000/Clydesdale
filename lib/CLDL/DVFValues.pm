package DVFValues;

sub dvf_values {

  my $cldl_values = { 
                'status'    => { 0 => 'Inactive',     1 => 'Active'},
                'dv_type'   => { 0 => 'DataTable',    1 => 'Form'},
                'edit_type' => { 0 => 'Not Editable', 1 => '1-Click', 2 => '2-Clicks'},
                'dvf_type'  => { 
                                  0 => 'text', 
                                  1 => 'textarea', 
                                  2 => 'password', 
                                  3 => 'hidden',
                                  4 => 'checkbox',
                                  5 => 'radio',
                                  6 => 'select',
                                  7 => 'span',
                                  8 => 'paragraph', },
# ff.dvf_type: 0=text, 1=textarea, 2=password, 3=hidden, 4=checkbox,  
#              5=radio, 6=select, 7=span, 8=paragraph,               
#              *9=submit, *10=button                                 
#  *color, *date *datetime, *datetime-local *email *month *number    
#  *range *search *tel *time url week                                
# *=Future     


             };




1;

