#!perl -w
use strict;
use File::Copy;
use File::Path;
use Cwd;


# this module copies the files from MOBY-Server/lib/*.pm that are required for MOBY-Client to create a distribution
use Data::Dumper;

my @MOBY 		= qw ( Async.pm CommonSubs.pm CrossReference.pm MobyXMLConstants.pm );
my @Async 		= qw ( LSAE.pm Service.pm SimpleServer.pm WSRF.pm );
my @Client		= qw ( Central.pm CollectionArticle.pm OntologyServer.pm Registration.pm SecondaryArticle.pm Service.pm ServiceInstance.pm SimpleArticle.pm SimpleInput.pm MobyUnitTest.pm );
my @Exception 	= qw ( MobyException.pm MobyExceptionCodes.pm );
my @RDF 		= qw ( Utils.pm );
my @Parsers 	= qw ( ServiceTypeParser.pm NamespaceParser.pm DatatypeParser.pm ServiceParser.pm );
my @predicates  = qw ( DC_PROTEGE.pm MOBY_PREDICATES.pm OMG_LSID.pm RDF.pm RDFS.pm FETA.pm OWL.pm );

# current working directory ...
my $dir = getcwd;

# the directory that files will be coming from, usually ../MOBY-Server/lib/
my $origin_directory 		= "$dir/../MOBY-Server/lib";
# the destination directory, usually ./lib/
my $destination_directory 	= "$dir/lib";

# directory structure for ../lib/
my @main_dirs = qw( MOBY MOBY/Async MOBY/Client MOBY/Client/Exception MOBY/RDF MOBY/RDF/Predicates MOBY/RDF/Parsers );

#create main directories as needed ...
foreach my $dir (@main_dirs) {
	my @created = mkpath( ("$destination_directory/$dir")  , {verbose => 1, mode => 0777} );
	print "created $_\n" for @created;
}

# copy files into their respective directories ...
#populate MOBY directory
foreach my $file (@MOBY) {
	my $subpath = "MOBY";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy files into Async dir
foreach my $file (@Async) {
	my $subpath = "MOBY/Async";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy files into Client dir
foreach my $file (@Client) {
	my $subpath = "MOBY/Client";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy files into Exception dir
foreach my $file (@Exception) {
	my $subpath = "MOBY/Client/Exception";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy the RDF files
foreach my $file (@RDF) {
	my $subpath = "MOBY/RDF";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy the Parsers files
foreach my $file (@Parsers) {
	my $subpath = "MOBY/RDF/Parsers";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# copy the Predicates files
foreach my $file (@predicates) {
	my $subpath = "MOBY/RDF/Predicates";
	warn "couldn't copy file $file: $!\n" unless copy("$origin_directory/$subpath/$file","$destination_directory/$subpath/$file") == 1;
}

# Directory Structure is:
#
#./lib/
# +---MOBY
#    ¦   CommonSubs.pm
#    ¦   CrossReference.pm
#    ¦   MobyXMLConstants.pm
#    ¦
#    +---Async
#    ¦       LSAE.pm
#    ¦       Service.pm
#    ¦       SimpleServer.pm
#    ¦       WSRF.pm
#    ¦
#    +---Client
#    ¦   ¦   Central.pm
#    ¦   ¦   CollectionArticle.pm
#    ¦   ¦   OntologyServer.pm
#    ¦   ¦   Registration.pm
#    ¦   ¦   SecondaryArticle.pm
#    ¦   ¦   Service.pm
#    ¦   ¦   ServiceInstance.pm
#    ¦   ¦   SimpleArticle.pm
#    ¦   ¦   SimpleInput.pm
#    ¦   ¦   MobyUnitTest.pm   
#    ¦   ¦
#    ¦   +---Exception
#    ¦           MobyException.pm
#    ¦           MobyExceptionCodes.pm
#    ¦
#    +---RDF
#    ¦   ¦   Utils.pm
#    ¦   ¦   
#    ¦   +---Parsers
#    ¦   ¦       ServiceTypeParser.pm
#    ¦   ¦       NamespaceParser.pm
#    ¦   ¦       ServiceParser.pm
#    ¦   ¦       DatatypeParser.pm
#    ¦   ¦
#    ¦   +---Predicates
#    ¦           DC_PROTEGE.pm
#    ¦           FETA.pm
#    ¦           MOBY_PREDICATES.pm
#    ¦           OMG_LSID.pm
#    ¦           OWL.pm
#    ¦           RDF.pm
#    ¦           RDFS.pm
