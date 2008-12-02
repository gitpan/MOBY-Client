use inc::Module::Install;

name 'MOBY-Client';

# all_from 'lib/MOBY/Client/Central.pm';
author 'Mark Wilkinson <markw@illuminae.com>';
version '1.03';
license 'perl';
abstract 'This distribution is for communicating with a MOBY Central registry';

build_requires 'Test::More' => 0;
build_requires 'Test::Pod'  => 0;

# MOBY::Client::* depends
requires 'SOAP::Lite'            => '0.60';
requires 'XML::LibXML'           => 0;
requires 'LWP::UserAgent'        => 0;
requires 'CGI'                   => 0;
requires 'HTTP::Request::Common' => 0;
requires 'URI::Escape'           => 0;
requires 'RDF::Core'             => '0.51';
# MOBY::Client::MobyUnitTest depends
requires 'XML::Simple'           => '2.18';
requires 'XML::SemanticCompare'  => '0.91';

# MOBY::CommonSubs depends
requires 'HTML::Entities' => 0;

# MOBY::Async requires
requires 'WSRF::Lite'            => '0.8.2.5';

auto_install;

WriteAll;

