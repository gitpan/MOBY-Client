#!/usr/bin/perl -w

#
# $Id: GetDump.pl,v 1.1 2005/11/02 13:18:29 pieter Exp $
# $Source: /home/repository/moby/moby-live/Perl/scripts/GetDump.pl,v $
#

use strict;
use Getopt::Std;
use SOAP::Lite;
#use SOAP::Lite + 'trace';
use MOBY::Client::Central;

# Get options.
my %opts;
getopt('c', \%opts);

my $central;
my $central_uri;
my $central_url;

if ( $opts{'c'} ) {

	($central_uri, $central_url) = split '@', $opts{'c'};

	print "Using MOBY Central:\n\t$central_uri @ $central_url\n";

	# Set this to wherever your MOBY Central is.
	$central = MOBY::Client::Central->new(
   		Registries => {
       		mobycentral => {
				URL => $central_url,
				URI => $central_uri
			}
		}
	);

} else {

	print "Using default BioMOBY Central.\n\n";
	print "If you want to get a dump from a different BioMOBY Central use:\n";
	print "GetDump.pl -c [Central]     Specify which BioMOBY Central to use.\n";
	print "                            [Central] = [CentralURI]@[CentralURL].\n\n";

	$central = MOBY::Client::Central->new();

}

#
# Create the SQL dump dir.
#

my $dumpdir = './sqldump/';
print "Creating sql dump directory $dumpdir...\n";
mkdir $dumpdir,0755 or die "\tcouldn't create output directory $dumpdir: $!\n";

#
# Get data dump
#

print "MOBY Central data dump:\n";

# A simple MOBY_Central call to get a complete dump of registered stuff.
my ($mobycentral, $mobyobject, $mobyservice, $mobynamespace, $mobyrelationship) = $central->MOBY::Client::Central::DUMP();

DumpSQL('mobycentral', $mobycentral);
DumpSQL('mobyobject', $mobyobject);
DumpSQL('mobyservice', $mobyservice);
DumpSQL('mobynamespace', $mobynamespace);
DumpSQL('mobyrelationship', $mobyrelationship);

sub DumpSQL {
	my ($db, $data) = @_;
	print "Dumping $db...";
	my $pathto   = $dumpdir .+ $db .+ '.sql';
	open (SQLSAVE,">>$pathto") or die " can't open output file $pathto: $!";
	print SQLSAVE $data or die " can't save output to file $pathto: $!";
	print " done.\n";
	close SQLSAVE;
}

print "Finished!\n";
