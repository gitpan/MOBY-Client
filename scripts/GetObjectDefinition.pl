#!/usr/bin/perl

#
# $Id: GetObjectDefinition.pl,v 1.1 2008/02/21 00:14:33 kawas Exp $
# $Source: /home/repository/moby/moby-live/Perl/MOBY-Client/scripts/GetObjectDefinition.pl,v $
#

use strict;
use Getopt::Std;
use FileHandle;
use MOBY::Client::Central;

# Get options.
my %opts;
getopt('oc', \%opts);

my $central;

print "\n";

if ( $opts{'c'} ) {

	my ($central_uri, $central_url) = split '@', $opts{'c'};
	
	print "Using BioMOBY Central:\n\t$central_uri @ $central_url\n\n";

	# set this to wherever your MOBY Central is.
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
	$central = MOBY::Client::Central->new;

}

# Check if the essential options are set
if ( !$opts{'o'} && !$opts{'l'} ) {

	print "Usage: GetObjectDefinition.pl [options]\n";
	print "available options are:\n";
	print "\n";
	print "-c [Central]    Specify which BioMOBY Central to use.\n";
	print "                [Central] = [CentralURI]@[CentralURL].\n";
	print "-l              Get a list of all registered objects.\n";
	print "-o [object]     Get the definition for a specific object.\n\n";

}

if ( $opts{'l'} ) {

	my $object;
	my $description;

format LIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<... ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$object $description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$description
~                                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
$description
.

	STDOUT->format_name("LIST");

	my $names = $central->MOBY::Client::Central::retrieveObjectNames();

	print "Registered objects:\n";

	foreach $object (sort keys %{$names}) { 
	
		$description = ${$names}{$object};

		write;		
		
	}

} elsif ( $opts{'o'} ) {

	my $object = $opts{'o'};

	# A simple MOBY_Central call to get the definition of an BioMOBY object.
	my $definitions = $central->MOBY::Client::Central::retrieveObjectDefinition(objectType => $object);

	#use Data::Dumper;
	#my $dumper = Data::Dumper->new($definitions);
	#print $dumper->Dump;

	unless ($definitions) {
		print "No definition found for object $object\n";
		exit(1);
	}

	my $relation;

format OBJECT =
    @<<<<<<<<<<<<<<<<<<<<<<<<<... @<<<<<<<<<<<<<<<<<<<<<<<<<... @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
${$relation}{object} ${$relation}{articleName} ${$relation}{lsid}            
.

	STDOUT->format_name("OBJECT");

	print "Object definition for $object:\n";

	while (my ($type, $def) = each %{$definitions}){

		if ($type =~ m/XML/i) {

			#print "$type:\t$def\n";	

		} elsif ($type =~ m/Relationships/i) {

			print "$type:\n";

			while (my ($relation_type, $relation_object) = each %{$def}){

				print "  $relation_type\n";
				print "    ObjectName:                   ArticleName:                  LSID:\n";

				foreach $relation (@{$relation_object}) {

					write;	
					
				}
			}
		
		} else {

			print "$type:\t$def\n";		

		}
	}
}

