package CLDL::Cache;

=head1 CLDL::Cache


=head1 Description

This module handles all cache related functions.


=cut  

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

use CLDL::Menu;

prefix '/cache';

=head2 /reset/all

  Resets the cache settings for all company ids

=cut
get '/reset/all' => sub {

  &CLDL::Menu::update_caches();
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

=head2 /reset/company

  Resets the cache for a specified company id

=cut
get '/reset/company' => sub {

  &CLDL::Menu::update_caches(session('company_id') );
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

1;
