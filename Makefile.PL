use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Clydesdale',
    AUTHOR           => q{Hagop "Jack" Bilemjian <jck000@gmail.com>},
    VERSION_FROM     => 'lib/CLDL.pm',
#    ABSTRACT_FROM    => 'lib/CLDL.pod',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                      => 0,
        'Config::Crontab'           => 0,
        'Dancer2'                   => 0,
        'Dancer2::Plugin'           => 0,
        'Dancer2::Plugin::Database' => 0,
        'Dancer2::Plugin::EditFile' => 0,
        'Dancer2::Plugin::JWT'      => 0,
        'Dancer2::Plugin::Redis'    => 0,
        'Dancer2::Plugin::Tail'     => 0,
        'Dancer2::Session::Redis'   => 0,
        'Digest::MD5'               => 0,
        'File::Copy'                => 0,
        'File::Path'                => 0,
        'JSON'                      => 0,
        'JSON::XS'                  => 0,
        'Moo'                       => 0,
        'Moo::Role'                 => 0,
        'Session::Token'            => 0,
        'String::Random'            => 0,
        'Template'                  => 0,
        'Try::Tiny'                 => 0,
        'YAML'                      => 0, 
        'YAML::XS'                  => 0, 

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CLDL-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jck000/Clydesdale',
            bugtracker => 'https://github.com/jck000/Clydesdale/issues',
            homepage   => 'https://github.com/jck000/Clydesdale/',
        },
    },
);

