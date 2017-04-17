package CLDL::Cache;

use Dancer2 appname => 'CLDL';
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Redis;

use CLDL::Menu;

prefix '/cache';

get '/reset/all' => sub {

  &CLDL::Menu::update_caches();
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

get '/reset/company' => sub {

  &CLDL::Menu::update_caches(session('company_id') );
  redirect config->{cldl}->{base_url} . config->{cldl}->{splash_url} ;

};

1;
