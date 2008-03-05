#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use SOAP::Lite;
#use SOAP::Lite + 'trace';
use MOBY::Client::Central;

my $central;
my $central_uri;
my $central_url;

#
# Get options.
#

my %opts;
getopts('dc:', \%opts);

print "\n";

if ( $opts{'d'} ) {
	
	if ($ENV{MOBY_URI} && $ENV{MOBY_SERVER}) {

		my$central_uri = $ENV{MOBY_URI};
		my$central_url = $ENV{MOBY_SERVER};

		print "Using default BioMOBY Central from env vars:\n";
		print "\t$central_uri\@$central_url\n";

	} else {
	
		print "Using default BioMOBY Central.\n";

	}

	$central = MOBY::Client::Central->new;

} elsif ( $opts{'c'} ) {

	my ($central_uri, $central_url) = split '@', $opts{'c'};
	
	print "Using BioMOBY Central:\n";
	print "\t$central_uri\@$central_url\n";
		
	# Set this to wherever your BioMOBY Central is.
	$central = MOBY::Client::Central->new(
    	Registries => {
      		mobycentral => {
				URL => $central_url,
				URI => $central_uri
			}
		}
	);
}

Usage() unless defined $central;

#
# Get service types.
#

print "Known service types:\n\n";

my $types = $central->retrieveServiceTypes();

my $type;
my $description;

format =
    @<<<<<<<<<<<<<<<<<<<<<<<<<... ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    "$type:",                     $description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                  $description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
                                  $description
.

while (($type, $description) = each %{$types}){
	write;
}

print "\nFinished!\n";

#
# Subs.
#

sub Usage {
	print "Usage: GetServiceTypes.pl [options]\n";
	print "available options are:\n";
	print " -d             Use the default BioMOBY Central.\n";
	print " -c [Central]   Specify which BioMOBY Central to use.\n";
	print "                Format for [Central] = [CentralURI]@[CentralURL].\n";
	print "\n";
	exit;
}
