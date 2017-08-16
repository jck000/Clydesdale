requires "Config::Crontab";
requires "Dancer2";
requires "Dancer2::Plugin::Database";
requires "Dancer2::Plugin::Email";
requires "Dancer2::Plugin::JWT";
requires "Dancer2::Plugin::Redis";
requires "Dancer2::Plugin::EditFile";
requires "Dancer2::Plugin::Tail";
requires "Dancer2::Session::Redis";
requires "DateTime";
requires "DBD::mysql";
requires "Digest::MD5";
requires "File::Copy";
requires "File::Path";
requires "JSON";
requires "JSON::XS";
requires "POSIX";
requires "Session::Token";
requires "String::Random";
requires "Template";
requires "YAML";
requires "YAML::XS";

recommends "URL::Encode::XS";
recommends "CGI::Deurl::XS";
recommends "HTTP::Parser::XS";

on "test" => sub {
    requires "Test::More";
    requires "HTTP::Request::Common";
};

