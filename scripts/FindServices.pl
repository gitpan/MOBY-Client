#!/usr/bin/perl -w

#
# $Id: FindServices.pl,v 1.1 2008/02/21 00:14:33 kawas Exp $
# $Source: /home/repository/moby/moby-live/Perl/MOBY-Client/scripts/FindServices.pl,v $
#

use strict;
use Getopt::Std;
use FileHandle;
use MOBY::Client::Central;

# Get options.
my %opts;
getopts('dc:i:o:a:n:t:k:', \%opts);

my $central;
my $input;
my $output;
my $secondary;
my $auth;
my $name;
my $type;
my $kword;

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

$input  = $opts{'i'};
$output = $opts{'o'};
$auth   = $opts{'a'};
$name   = $opts{'n'};
$type   = $opts{'t'};
$kword  = $opts{'k'};

Usage() unless defined $central;

sub Usage {
	print "Usage: FindServices.pl [options]\n";
	print "available options are:\n";
	print " -d             Use the default BioMOBY Central.\n";
	print " -c [Central]   Specify which BioMOBY Central to use.\n";
	print "                Format for [Central] = [CentralURI]@[CentralURL].\n";
	print "\n";
	print "You can limit your search with the filter options below.\n";
	print "If no filter options are specified all registered services will be returned.\n";
	print "\n";
	print " -i [Object]    Find services that consume [Object] as input\n";
	print " -o [Object]    Find services that provide [Object] as output\n";
	print " -a [Authority] Find services hosted by service provider [Authority]\n";
	print " -n [Name]      Find services with a certain name.\n";
	print " -t [type]      Find services based on the service type.\n";
	print " -k [keyword]   Find services based on a keyword.\n";
	print "\n\n";
	exit;
}

my %filter;
$filter{category} = "moby";

if (defined $input) {
		$filter{input} = [ [$input] ];
}
if (defined $output) {
		$filter{output} = [ [$output] ];
}
if (defined $auth) {
		$filter{authURI} = $auth;
}
if (defined $name) {
		$filter{serviceName} = $name;
}
if (defined $type) {
		$filter{serviceType} = $type;
}
if (defined $kword) {
		$filter{keywords} = [$kword];
}

my ($service_instances, $reg_object) = $central->findService(%filter);

unless ($service_instances) {
	print "Service discovery failed: ", $reg_object->message;
	exit(1);
}

my @service_instances = @{$service_instances};
my $service_count = 0;
my $description;

format SERVICE =
@>>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
"$service_count:", $name
        @<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        "Authority:   ", $auth
        @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        "Description: ", $description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                     $description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                     $description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                     $description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
                     $description
.

foreach my $service_instance (@service_instances) {

	$service_count++;

	$name = $service_instance->name;
	$auth = $service_instance->authority;
	$description = $service_instance->description; 
	$description =~ s/\s+/ /g; 
	$description =~ s/^[ \t\n.]+//;
	$description =~ s/[ \t\n]+$//;
	print "\n";

	#my $WSDL = $central->retrieveService($service_instance);
	#print "WSDL: $WSDL\n";
	
	STDOUT->format_name("SERVICE");
	write;

	#
	# List the Input.
	#

	foreach $input (@{$service_instance->input}) {

		my $object_in;
		my $articleName_in;
		my $namespaces_in;

		$articleName_in = $input->articleName || "-" ;

		unless($input->isSimple) {

			$object_in = 'Is a collection';
			$namespaces_in = 'n/a';

		} else {

			$object_in = $input->objectType;
			$object_in =~ s/.*://;

			if ((scalar (@{$input->namespaces})) >= 1) {

				$namespaces_in = '';

				foreach my $ns (@{$input->namespaces}) {

					$ns =~ s/.*://;
					$namespaces_in .= $ns. " ";

				}

				$namespaces_in =~ s/ $//;

			} else {

				$namespaces_in = '-';
			}
		}

format INPUT =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<... @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
        "Input:       $object_in",                 "ArticleName: $articleName_in"
                                                   @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		                                           "Namespaces:",$namespaces_in
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		                                                         $namespaces_in
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
		                                                         $namespaces_in
.
			STDOUT->format_name("INPUT");
			write;

	}
	
	#
	# List the Output.
	#

	foreach $output (@{$service_instance->output}) {

		my $object_out;
		my $articleName_out;
		my $namespaces_out;

		$articleName_out = $output->articleName || "-" ;

		unless($output->isSimple) {

			$object_out = 'Is a collection';
			$namespaces_out = 'n/a';

		} else {

			$object_out = $output->objectType;
			$object_out =~ s/.*://;

			if ((scalar (@{$output->namespaces})) >= 1) { 

				$namespaces_out = '';

				foreach my $ns (@{$output->namespaces}) {

					$ns =~ s/.*://;
					$namespaces_out .= $ns . " ";

				}

				$namespaces_out =~ s/ $//;

			} else {

				$namespaces_out = '-';

			}
		}

format OUTPUT =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<... @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
        "Output:      $object_out",                "ArticleName: $articleName_out"
                                                   @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		                                           "Namespaces:",$namespaces_out
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		                                                         $namespaces_out
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
		                                                         $namespaces_out
.
			STDOUT->format_name("OUTPUT");
			write;
			
	}
	
	#
	# List the optional Secondaries.
	#
	
	foreach $secondary (@{$service_instance->MOBY::Client::ServiceInstance::secondary}) {

		my $secondary_articlename = $secondary->MOBY::Client::SecondaryArticle::articleName || "" ;
		my $secondary_datatype = $secondary->MOBY::Client::SecondaryArticle::datatype || "" ;
		my $secondary_description = $secondary->MOBY::Client::SecondaryArticle::description || "" ;
		my $secondary_min = defined($secondary->MOBY::Client::SecondaryArticle::min) ? $secondary->MOBY::Client::SecondaryArticle::min : "" ;
		my $secondary_max = defined($secondary->MOBY::Client::SecondaryArticle::max) ? $secondary->MOBY::Client::SecondaryArticle::max : "" ;
		my $secondary_default = defined($secondary->MOBY::Client::SecondaryArticle::default) ? $secondary->MOBY::Client::SecondaryArticle::default : "" ;
		my $secondary_enum = '';

		if ((scalar (@{$secondary->MOBY::Client::SecondaryArticle::enum})) >= 1) {

			foreach my $val (sort (@{$secondary->MOBY::Client::SecondaryArticle::enum})) {		

				$secondary_enum .= "$val, ";

			}

			$secondary_enum =~ s/, $//;

		}

		my $namespaces_secondary = '';

		if ((scalar (@{$secondary->MOBY::Client::SecondaryArticle::namespaces})) >= 1) {

			$namespaces_secondary = '';

			foreach my $ns (@{$secondary->MOBY::Client::SecondaryArticle::namespaces}) {

				$ns =~ s/.*://;
				$namespaces_secondary .= $ns. " ";

			}

			$namespaces_secondary =~ s/ $//;

		} else {

			$namespaces_secondary = '-';
		}

format SECONDARY =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<... @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        "Parameter:   $secondary_articlename",     "Namespaces:",$namespaces_secondary
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		                                                         $namespaces_secondary
~                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
		                                                         $namespaces_secondary
             @<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
             "Desc:",$secondary_description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                     $secondary_description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                     $secondary_description
~                    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
                     $secondary_description
             @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
             "Type:   $secondary_datatype"
              @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
              "Min:   $secondary_min"
              @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
              "Max:   $secondary_max"
          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
          "Default:   $secondary_default"
             @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
             "Enum:   $secondary_enum"
.
			STDOUT->format_name("SECONDARY");
			write;

	}
}

print "\n";
