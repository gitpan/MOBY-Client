use inc::Module::Install;

name     'MOBY-Client';
# all_from 'lib/MOBY/Client/Central.pm';
author   'Mark Wilkinson <markw@illuminae.com>';
version '1.0';
license 'perl';

build_requires 'Test::More' => 0;
build_requires 'Test::Pod' => 0;

# MOBY::Client::* depends
requires 'SOAP::Lite' => '0.60';
requires 'XML::LibXML' => 0;
requires 'LWP::UserAgent' => 0;
requires 'CGI' => 0;
requires 'HTTP::Request::Common' => 0;
requires 'URI::Escape' => 0;

# MOBY::CommonSubs depends
requires 'HTML::Entities' => 0;

auto_install;

WriteAll;

