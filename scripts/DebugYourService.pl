#!/usr/bin/perl -w

# $Id: DebugYourService.pl,v 1.2 2006/02/28 16:28:29 fgibbons Exp $
# $Source: /home/repository/moby/moby-live/Perl/scripts/DebugYourService.pl,v $

=head1 Quick debugging script

This will execute a service in SOAP::Lite trace mode.  This will show
you the messages being passed back and forth between you and
MOBY::Central, and you and the service you are trying to invoke.

This works with services that take Simple and/or Collection and/or
Secondary articles as input.

If you only quickly want to test the communication with a BioMOBY
Central and a service and not the functionality of the service itself
you can combine this script with the test service "Boomerang" from
authorithy "www.bioinformatics.nl". That service will simply echo back
whatever you send it as long as it is valid BioMOBY data.

=head2 Usage

 DebugYourService.pl -a serviceAuthorityURI -n serviceName -i mobyDataFileName

The combination of serviceAuthorityURI and serviceName is a unique key
to identify the service you are trying to test.  mobyDataFilename is
the name of a file that contains a mobyData block you wish to pass to
the service.

e.g. 

 DebugYourService.pl -a www.illuminae.com -n GetGoTerm -i ./service_input

Example of a mobyData input file with a single Simple article:

  <mobyData>
    <Simple>
       <moby:Object moby:namespace="GO" moby:id="0008303" />
    </Simple>
  </mobyData>

Example of a mobyData input file with Simple, Collection and Secondary
articles:

  <mobyData>
    <Simple>
      <SomeObject namespace='some.namespace' id='00001' />
    </Simple>
    <Collection>
      <Simple>
        <AnotherObject namespace='another.namespace' id='11111' />
      </Simple>
      <Simple>		
        <AnotherObject namespace='another.namespace' id='11112' />
      </Simple>
    </Collection>
    <Parameter articleName='SomeOption'>
      <Value>7</Value>
    </Parameter>
</mobyData>

=cut

use strict;
use Getopt::Std;
#use SOAP::Lite;
use SOAP::Lite +trace => 'debug';
use MOBY::Client::Central; 
use MOBY::Client::Service;
use MOBY::CommonSubs qw(:all);

my @input_list;

#
# Get options.
#

my %opts;
getopts('a:c:i:n:', \%opts);
my $authority = $opts{'a'};
my $name = $opts{'n'};
my $input = $opts{'i'};
my $central = $opts{'c'}; 

unless ($authority && $name && $input) {
  print <<HELP;
Usage:
DebugYourService.pl -a serviceAuthorityURI -n serviceName 
                    -i service_input_file [-c centralURI\@centralURL]
-a serviceAuthorityURI : Authority (URI of service provider)
-n serviceName         : Name of the service
-i service_input_file  : File containing the mobyData block you want 
                         to send to the service
-c central             : Optional. The Central you want to use to find the service.
                         Central must be in format [centralURI]\@[centralURL]

Example of a mobyData input file with a single Simple article:

<mobyData>
  <Simple>
    <moby:Object moby:namespace='GO' moby:id='0008303' />
  </Simple>
</mobyData>

Example of a mobyData input file with Simple, Collection 
and Secondary articles:

<mobyData>
  <Simple>
    <SomeObject namespace='some.namespace' id='00001' />
  </Simple>
  <Collection>
    <Simple>
      <AnotherObject namespace='another.namespace' id='11111' />
    </Simple>
    <Simple>		
      <AnotherObject namespace='another.namespace' id='11112' />
    </Simple>
  </Collection>
  <Parameter articleName='SomeOption'>
    <Value>7</Value>
  </Parameter>
</mobyData>
HELP
  exit;
}

#
# Get mobyData block from input file.
#

open (IN, $input) || die "Can't open your object file $input $!\n";
my $data = join "", <IN>;

#
# Find and execute service.
#

if ( $central ) {

	my ($central_uri, $central_url) = split '@', $central;
	
	print "Using BioMOBY Central:\n\t$central_uri @ $central_url\n";

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
	print "Using default BioMOBY Central.\n";
	$central = MOBY::Client::Central->new;
}

my ($service_instances, $reg_object) = $central->findService(authURI => $authority, serviceName => $name);
my $service_instance = shift @{$service_instances};

$name = $service_instance->name;
$authority = $service_instance->authority;

my $description = $service_instance->description; 
$description =~ s/\s+/ /g; 
$description =~ s/^[ \t\n.]+//;
$description =~ s/[ \t\n.]+$//; 
print "\n---------------\nUsing service:\n\tname: $name\n\tauthority: $authority\n\tDescription: \u$description\n---------------\n"; 

my $wsdl = $central->retrieveService($service_instance);
my $service = MOBY::Client::Service->new(service => $wsdl); 

my @input_articles = getArticles($data);
foreach (@input_articles) {
	my ($article_name, $article_dom) = @{$_};

	my $simple = isSimpleArticle($article_dom);	# articles may be Simple, Collection or Secondary.
	my $collection = isCollectionArticle($article_dom);
	my $secondary = isSecondaryArticle($article_dom);

	if ($collection) {

		#print "found collection\n";

		my @simples = getCollectedSimples($article_dom); # XML::LibXML nodes!
		my @raw_xml = map {extractRawContent($_)} @simples; # convert the DOM to a string
		my $raw_xml = \@raw_xml;
		push @input_list, $article_name, \@raw_xml;			

	} elsif ($simple or $secondary) {

		my $raw_xml = extractRawContent($article_dom);
		push @input_list, $article_name, $raw_xml;
		
	}
}

my $result = $service->execute(XMLinputlist => [\@input_list]);
print "\n#\n";
print "##\n";
print "### ---------------- Service output: ---------------------------------------------------------------\n";
print "##\n";
print "#\n\n";
print "$result\n\n";
