use inc::Module::Install;

name 'MOBY-Client';

# all_from 'lib/MOBY/Client/Central.pm';
author 'Mark Wilkinson <markw@illuminae.com>';
version '1.01';
license 'perl';

build_requires 'Test::More' => 0;
build_requires 'Test::Pod'  => 0;

requires( perl => 5.005 );

# MOBY::Client::* depends
requires 'SOAP::Lite'            => '0.60';
requires 'XML::LibXML'           => 0;
requires 'LWP::UserAgent'        => 0;
requires 'CGI'                   => 0;
requires 'HTTP::Request::Common' => 0;
requires 'URI::Escape'           => 0;
requires 'RDF::Core'             => '0.51';

# MOBY::CommonSubs depends
requires 'HTML::Entities' => 0;

# MOBY::Async requires
if ( not( $^O =~ /MSWin32|Windows_NT/i ) ) {

	# check for WSRF
	eval "require WSRF::Lite";
	if ($@) {
		# WSRF not installed ... tell them where to get it
		print STDOUT <<'END_OF_TEXT';

################### IMPORTANT ###################

	WSRF lite is not installed on your system.
	Unfortunately, at this time, this Makefile
	cannot automatically find and install it for
	you. You will have to install it manually.
	
	The last known URL of where you could find
	this package is @
	http://www.rcs.manchester.ac.uk/research/wsrflite
	
	If that url does not exist, please search with
	google using the phrase 'WSRF-Lite'. 

	Sorry for any inconvenience caused!

##################################################

END_OF_TEXT

		
	}
	requires 'WSRF::Lite'               => '0.8.2.2';
	requires 'XML::DOM'                 => '';
	requires 'DateTime::Format::Epoch'  => '';
	requires 'DateTime::Format::W3CDTF' => '';
	requires 'HTTP::Daemon'             => '';
	requires 'HTTP::Daemon::SSL'        => '';
	requires 'MIME::Base64'             => '';
	requires 'Digest::SHA1'             => '';
	requires 'Crypt::OpenSSL::RSA'      => '';
	requires 'XML::CanonicalizeXML'     => '0.02';
	requires 'Sys::Hostname::Long'      => '';
	requires 'Crypt::OpenSSL::X509'     => '0';
} else {
	print STDOUT <<'END_OF_TEXT';
			
################### IMPORTANT ###################

	Windows is not a suitable platform for those 
	wishing to construct asynchronous moby services 
	due to the lack of support for that platform of 
	some of the required libraries.
	
	The libraries in question are as follows:
		WSRF-Lite & Crypt-OpenSSL-X509
		
	Sorry for any inconvenience caused!
	
##################################################

END_OF_TEXT

}

# dont want to install the test services ... better just to document that they are here
#install_share 'share';

auto_install;

WriteAll;

