#!/usr/bin/perl -w
use strict;
use lib '/usr/local/apache/cgi-bin/BIO/moby-live/Perl';

use MOBY::Client::Central;
use MOBY::Client::Service;
use MIME::Base64;
use XML::DOM;
use Data::Dumper;
use CGI qw/:standard/;

use vars qw($debug $ERROR_FLAG);

$debug = 0; # change to '1' to get debugging messages in /tmp
if ($debug) {
  # refreshes the debugging log
  open (OUT, ">/tmp/Client05LogOut.txt")
    || die "cant open logfile\n";
  print OUT "Client Initializing\nINC is @INC\n";
  close OUT;
}


if (param('start')) {
  # user has already started, but needs to turn namespaces and ID's into
  # objects before presenting the "results"
  &Begin; &Continue;
} elsif (param('continue')) {
  # user has objects in hand, and has chosen a service for them.
  # Execute the service and present the results
  &Execute; &Continue;
} elsif (param('reinitialize')) {
    &Initialize;&Begin;&Continue;
} else {
    &Initialize;&SendOpeningPage
}


sub Initialize {	
    # set this to wherever your MOBY Central is.  At the moment, it is @
    # mobycentral.cbr.nrc.ca

    my $Central = MOBY::Client::Central->new();
    
    my (@ValidNamespaces);
    my $NameSpaces = $Central->retrieveNamespaces;
    while (my ($k, $v) = each %{$NameSpaces}) {
        push @ValidNamespaces, $k."~~~".$v;	# name and description
    }
#	_LOG("INITIALIZING");
    @ValidNamespaces = sort @ValidNamespaces;

	param('ValidNamespaces', @ValidNamespaces);
#	_LOG("GOT MOBY CENTRAL DATA @ValidObjects ::: @ValidServices ::: @ValidNamespaces\n");
}

sub SendOpeningPage {
    # send out initialization screen... a bit "flat" at the moment, but we can make it pretty later
    my ($NameSpaces) = &extractInitializedParams(); # these are the MOBY-Central reported objects, services and namespaces
        
    print header,
    start_html(-title => 'A Simple MOBY Client', -bgcolor => "white"),
    "<table BGCOLOR='#AAAAFF' width = '100%'><TR><TD><center>",
    "<IMG SRC=http://www.biomoby.org/moby1.gif>",
    h1('MOBY Client Initialization'),"(sample values have been selected for you for demonstration purposes)</center></TD></TR></table><p>",
    start_form,
    "<h2>What namespace do you have? ";
    my %nslabels = (%{$NameSpaces});
    print popup_menu(-name => 'namespace',
    '-values' => ["select", (sort (keys %{$NameSpaces}))],
#    '-values' => ["select", (keys %{$NameSpaces})],
    '-default' => 'GO',
    );

    print p,
    "Which ID(s) within this namespace? (one per line)</h2>",
    p,
    textarea(-name => 'id', -rows => 10, -cols => 20, -value =>
"GO:0008303
GO:0001662",);

    print p,
    &InitializeParams,
    submit("Initialize with this seed data"),

    end_form,
    end_html,
    hr;
}


sub Begin {
    my $ns = param('namespace');	# get the selected namespace 
    my @Objects;
    foreach (split "\n", param('id')) { # take one ID per line
        $_ =~ s/^\s//g;		# remove spaces
        $_ =~ s/\s$//g;		# remove spaces
        push @Objects, encode_base64(&constructRootObject($ns, $_)); # Construct the objects from namespace & id
        # just in case we have weird characters in the namespace, base64 encode it
    }
    param('CurrentObjects', @Objects); # fill the CurrentObjects CGI parameter; this is always used to hold the list of "current" objects
}

sub setInitializedParams {
    # shortcut to write persistence fields into the CGI form.
    hidden(-name => 'continue', value => 1),"\n",    
}
sub InitializeParams {
    hidden(-name => 'ValidNamespaces'),"\n",
    hidden(-name => 'start', -value => 1), # set the "start" flag for the next time the script is called
}

sub extractInitializedParams {
    # get's the persistence data out of the CGI form input.
    # returns hash of {name}="definition" for each of Object, Service and Namespace
    my @ValidNamespaces = param('ValidNamespaces');
    my (%NameSpaces);
    foreach (@ValidNamespaces) {
        my ($key, $value) = split "~~~", $_; # the persistent data is in the form name~~~definition. Use Regexp to split them   
        $NameSpaces{$key} = $value;
    }
    return (\%NameSpaces);
}


sub constructRootObject {
  # used by the "Begin" subroutine to create root objects from
  # namespace and ID
  my ($ns, $id) = @_;
  return "<Object namespace='$ns' id='$id'/>"; # simple XML root object
}


sub writeCurrentObjects {
    # takes list of current objects and generates HTML table, including checkbox form elements
    # object name and namespace are extracted from XML by regexp
    # they are HTML escaped to ensure that they print properly
    # **the entire object itself is passed as the checkbox value!! base64 encoded**
    # Subroutine returns HTML string to generate this table
    my (@Objects) = @_;
    my $response;
    $response .= "<table border=0 width = '100%' BGCOLOR='#FFCCFF'><TR><TH align='center'>OBJECT</TH><TH align='center'>CONTENTS</TH></TR>";
    foreach (@Objects) {
        my $b64Obj = encode_base64($_);

        my $Parser = new XML::DOM::Parser;
        my $doc = $Parser->parse($_);
        my $Object = $doc->getDocumentElement();
        my $obj = $Object->getTagName;
        my $ns = $Object->getAttributeNode("namespace");
        next unless $ns;
        $ns = $ns->getValue();
        my $id = $Object->getAttributeNode("id");
        next unless $id;
        $id = $id->getValue();
        my $name = $Object->getAttributeNode("articleName");
        $name &&=($name->getValue());
        $name ||="";
        _LOG("writeCurrentObjects: $name Object was $obj namespace was $ns id was $id\n");
        $obj = escapeHTML($obj);	# escape the name, namespace, and object XML
        $ns = escapeHTML($ns);
        $id = escapeHTML($id);
        $name = escapeHTML($name);
        
        $response .= "<tr><td valign='top' align='left' width = '20%'>";
        $response .= checkbox(-name => "CurrentObjects",
                  -value => "$b64Obj", # the actual object, encoded
                  -label => "$name ($obj) : $ns",
                 );
        $response .="</td>";
        
        my $CRIB = $Object->getElementsByTagName("CrossReference");
        # should be only one CRIB per object, so...
        my $XrefString = "";
        if ($CRIB->item(0)){
            $XrefString .="<b>Cross References:</b> ";
            my @XrefsXML;
            foreach my $child ($CRIB->item(0)->getChildNodes()){
                next unless $child->getNodeType == ELEMENT_NODE;
                my $ns = $child->getAttributeNode("namespace")->getValue();
                my $id = $child->getAttributeNode("id")->getValue();
                if (($ENV{HTTP_HOST} =~ /localhost/) || ($ENV{HTTP_HOST} =~ /192\.168\.1\./)){               
                    $XrefString .= "<a href='http://localhost/cgi-bin/MOBY-Client.cgi?namespace=$ns;id=$id;reinitialize=1' target ='new'>$ns : $id</a>,&nbsp;&nbsp;&nbsp;&nbsp;"; 
                } else {
                    $XrefString .= "<a href='http://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}?namespace=$ns;id=$id;reinitialize=1' target ='new'>$ns : $id</a>,&nbsp;&nbsp;&nbsp;&nbsp;"; 
                }
            }
            $XrefString .="<br>\n";
        }
        
        my $OBJ = "";
        $OBJ .= "<b>NameSpace: </b>$ns<br>
                 <b>ID:$id</b><br>";
        
        my $type = &_what_am_i($Object); # returns b64jpeg, b64gif, TEXT
        my $alldata;
        foreach ($Object->getChildNodes()){  # this is TERRIBLE parsing of a MOBY Object!!  It only goes one level deep, but it is sufficient for a prototype client
            my $data;
            if (($_->getNodeType == TEXT_NODE) || ($_->getNodeType == CDATA_SECTION_NODE)){
                $alldata .= $_->toString;  # deal with the text content of this node separately from the object content
            } elsif ($_->getNodeType == ELEMENT_NODE){
                next if  ($_->getTagName =~ /CrossReference/);
                my $article = $_->getAttributeNode('articleName');
                if ($article){
                    $article = escapeHTML($article->getValue());
                } else {
                    $article = "";
                }
                $OBJ .= "<b>$article (".escapeHTML($_->getTagName).")</b> : ";
                foreach my $content($_->getChildNodes){
                    $data .= $content->toString if (($content->getNodeTypeName eq "TEXT_NODE") || ($_->getNodeTypeName eq "CDATA_SECTION_NODE"));
                }
            }            
#                $OBJ .= "".escapeHTML($Payload->item($_)->toString)."<br>";
            $data && ($OBJ .= "$data<br>");
        }
        if ($alldata){
            use MIME::Base64;
            use File::Temp qw/ tempfile /;
            if ($type =~ /b64/){
                $alldata = decode_base64($alldata);
                my ($fh, $filename);
                ($fh, $filename) = tempfile( DIR => "/usr/local/apache/htdocs/tmp", SUFFIX=> ".jpeg" ) if ($type =~ /b64jpeg/);
                ($fh, $filename) = tempfile( DIR => "/usr/local/apache/htdocs/tmp", SUFFIX=> ".gif" ) if ($type =~ /b64gif/);
                binmode $fh;
                print $fh $alldata;
                close $fh;
                $filename =~ s"^/usr/local/apache/htdocs/tmp/"";
                $OBJ .="<br><IMG src=http://mobycentral.cbr.nrc.ca/tmp/$filename><br>";
            } else {
                $OBJ .= "<pre>$alldata</pre><BR>";
            }
        }
        $response .= "<td BGCOLOR = '#CCCCFF' valign='top' align='left'><SMALL>$XrefString$OBJ</SMALL></td></tr>\n"; #  HTML escaped XML of the object
    }
    $response .="</table>";
    #_LOG("\n\n************** HTML TABLE WAS ************\n$response\n\n");
    return $response;
}
	
sub Execute {
    # EXECUTE SELECTED SERVICE
    my $SelectedService = param('SelectedService');
    unless ($SelectedService){$ERROR_FLAG = "You didn't select a service to execute"; return};

    my ($URI, $name) = (($SelectedService =~ /(.*?)#(.*)/) && ($1, $2));
    _LOG("Executing\n");

    my $Central = MOBY::Client::Central->new();
    my ($SIs, $REG) = $Central->findService(  # should only retrieve one service instance
        authURI => $URI,
        serviceName => $name,
                                           );
    die "Retrieval of service $name from $URI failed for unknown reasons\n" if $REG;
    
    my $wsdl =  $Central->retrieveService($SIs->[0]);  # get the WSDL for the first (only) serviceInstance
    $wsdl || die "Failed to Retrieve WSDL for service $name at $URI\n";
    _LOG("WSDL\n\n___________________________________________________$wsdl\n_______________________________________");
    my @CurrentObjects =  &extractCurrentObjects(); # get the object XML list (in human-readable form if possible for logging purposes)
    my @CurrentObjectList = map {[undef, $_]} @CurrentObjects;  # the format for $Service->execute is (articleName, "<XML...>) so make the mapping.  This script ignores article names entirely... too bad!
    _LOG("MOBY_REQUEST_INPUT\n\n___________________________________________________\n@CurrentObjects\n_______________________________________");

    my $Service = MOBY::Client::Service->new(service => $wsdl); # create the service
    _LOG("Service $Service created from WSDL\n");
#    my $data = SOAP::Data->type(base64 => "$MOBY_Request"); # base64 encode the request to speed up the SOAP parsing of the message at the server end

    my $result = "";
    eval {$result =  $Service->execute(XMLinputlist => \@CurrentObjectList)}; # execute the service
    if ($@ || !$result){_LOG("!!!!!!!!!!!!!!!!  ERROR $! !!!!!!!!!!!!!!!!!!!");$ERROR_FLAG = "Service Unavailable"; return};
    _LOG("Service $Service Executed Successfully\nRESULT===================================================
$result\n
         ===================================================================================================");

    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parse($result);
    my $moby = $doc->getDocumentElement();

    my @objects;
    my @collections;
    my @Xrefs;
    my $success = 0;
    my $responses = $moby->getElementsByTagName('moby:queryResponse');
    $responses ||= $moby->getElementsByTagName('queryResponse');
    foreach my $n(0..($responses->getLength - 1)){
        my $resp = $responses->item($n);
        foreach my $response_component($resp->getChildNodes){ 
            next unless $response_component->getNodeType == ELEMENT_NODE;
            if (($response_component->getTagName eq "Simple") || ($response_component->getTagName eq "moby:Simple")){
                foreach my $Object($response_component->getChildNodes) {
                    next unless $Object->getNodeType == ELEMENT_NODE;
                    $success = 1;
                    my $Object_text = $Object->toString;
                    push @objects,$Object_text;
                    _LOG("Found response object $Object_text .\n");
                }
            } elsif (($response_component->getTagName eq "Collection") || ($response_component->getTagName eq "moby:Collection")){
                my @objects;
                foreach my $simple($response_component->getChildNodes){
                    next unless $simple->getNodeType == ELEMENT_NODE;
                    next unless (($simple->getTagName eq "Simple") || ($simple->getTagName eq "moby:Simple"));
                    foreach my $Object($simple->getChildNodes) {
                        next unless $Object->getNodeType == ELEMENT_NODE;
                        $success = 1;
                        my $Object_text = $Object->toString;
                        push @objects,$Object_text;
                        _LOG("Found response object $Object_text .\n");
                    }
                }
                push @collections, \@objects;    #I'm not using collections yet, so we just use Simples.
            }
        }
    }

    unless ($success){$ERROR_FLAG = "MOBY Response Contained No Data"; return};
    # fill the CurrentObjects CGI parameter; this is always used to hold
    # the list of "current" objects as base64 encoded strings
    my @all_objects;
    push @all_objects, map {encode_base64($_)} @objects;
    foreach (@collections){
        push @all_objects, map {encode_base64($_)} @{$_};
    }
    param('CurrentObjects', @all_objects);
}


sub Continue {
    # called after the service has been executed
    # gets the new current object types, as well as the cached object/service/namespace data
    # presents the new possibilities to the client.
    my ($NameSpaces) = &extractInitializedParams(); # these are the MOBY-Central reported objects, services and namespaces
    my @Objects = extractCurrentObjects();  # simply base64 decodes the CurrentObjects CGI parameter
    my @CurrentObjectTypes = extractObjectTypes(@Objects);
    my @CurrentNamespaces = extractNamespaceTypes(@Objects);
        
    print header;
    my $JS= "
        function toggle(checkboxes) {
            for (i=0; i<checkboxes.length; ++i) {
                    alert('i');
                    checkboxes[i].checked = 0;
            }
        }";
    
    print start_html(
        -script => $JS,
        -title => 'A Simple MOBY Client',
        -bgcolor => "white"),
    "<table BGCOLOR='#AAAAFF' width = '100%'><TR><TD><center>",
    "<IMG SRC=http://www.biomoby.org/moby1.gif>",
    h1('MOBY Service Search'),"</center></TD></TR></table><p>";
    
    if ($ERROR_FLAG){&_sendError("$ERROR_FLAG");$ERROR_FLAG = 0; }
    print h3("Chose a service from the list below...\n"),
	start_form(-name => "Objects"),
	
	&getAllServices(\@CurrentObjectTypes, \@CurrentNamespaces), # find the valid services for this object/namespace combination
	p,"\n",
	h3("Select the Objects below that you wish to send to this service<br>\n"),
    p,"\n",
	submit("Send Selected Objects to Service")," ",reset," ", 
	#button(-value=>'All Off', -onClick=>'toggle(form.CurrentObjects);'),
    p,
	&writeCurrentObjects(@Objects), # allow them to chose which objects to send into this service (checkbox)
	p,"\n",

	submit("Send Selected Objects to Service")," ",reset," ",
    #button(-value=>'All Off', -onClick=>'toggle(form.CurrentObjects);'),
    
	&setInitializedParams, # set the hidden persistence fields
	end_form,
	end_html;
}
	
sub extractCurrentObjects {
  # objects are passed as base64 encoded, need to decode them back to XML
  my @objects = param("CurrentObjects");
  &_LOG("CURRENT_OBJECTS__________________\n@objects\n___________________");
  return map {decode_base64($_)} @objects;
}


sub extractObjectTypes {
    # gets the object names out of the XML 
    # returns list of object names
    my (@Objects) = @_;
    my @Types;
    foreach (@Objects) {
        my $Parser = new XML::DOM::Parser;
        my $doc = $Parser->parse($_);
        my $Object = $doc->getDocumentElement();
        my $object_name = $Object->getTagName;
        _LOG("extractObjectTypes:  Object was $object_name\n");
        my $CRIB = $Object->getElementsByTagName("CrossReference");
        $CRIB->item(0) || ($CRIB = $Object->getElementsByTagName("moby:CrossReference"));
        # should be only one CRIB per object, so...
        if ($CRIB->item(0)){
            my @XrefsXML;
            my $Xref_list = $CRIB->item(0)->getChildNodes();
            foreach (0..$Xref_list->getLength-1){
                    next unless $Xref_list->item($_)->getNodeType == ELEMENT_NODE;
                    push @XrefsXML, $Xref_list->item($_)->toString;
            }
            push @Types, [$object_name, \@XrefsXML];
        } else {
            push @Types, [$object_name, []];
        }
    }
    return @Types;
}

sub extractNamespaceTypes {
  # gets the namespace names out of the XML
  # returns list of namespace names
  my (@Objects) = @_;
  my @namespaces;
  foreach (@Objects) {
	my $Parser = new XML::DOM::Parser;
	my $doc = $Parser->parse($_);
	my $Object = $doc->getDocumentElement();
	my $ns = $Object->getAttributeNode("namespace");
	$ns ||= $Object->getAttributeNode("moby:namespace");
    $ns ||="";
    if ($ns){_LOG("extractObjectTypes:  Namespace was ".$ns->getValue."\n");}
    if ($ns){push @namespaces, $ns->getValue;}
    else {push @namespaces, undef}
  }
  return @namespaces;	
}



sub getAllServices {
    # getAllService that can deal with this type of object in this type
    # of namespace.  returns HTML - a string to create an *HTML popup
    # menu* of valid services!!
    my ($objects, $namespace) = @_;
    my @objects = @{$objects};  # has the format @([object_type, \@XREF_XML], [...]...)
    _LOG("getAllServices:  \n\tInitial Object List @objects\n");

    my %types;
    foreach (@objects){
        my ($type, $xrefs) = @{$_};
        next unless $type;
        $types{$type} = 1;
    }
      
    my $response;

    my $Central = MOBY::Client::Central->new();

    #_LOG("getAllServices:  \n\tObjects @types\n\tNamespaces @{$namespace}");
    #my @services = $Central->locateServiceByInput(\@types, $namespace);
    # I'm not sure why the call commented out above
    # used a list ref of types...  I'm too tired to think about it.
    my %popup_services;
    foreach (keys %types){
        my ($SI, $Reg) = $Central->findService(input => [[$_, $namespace]], authoritative => 0, expandServices => 1, expandObjects => 1);
        if ($Reg){
            return "<p><b>".($Reg->message).'<\b><p>';
        }
        foreach (@{$SI}) {
            my ($URI) = $_->authority;
            my ($name) = $_->name;
            my ($type) = $_->type;
            my $objs = $_->output;
            my $output = "(";
            foreach my $param(@{$objs}){
                if ($param->isSimple){
                    my $type = (($param->objectType =~ /\:(\S+)$/) && $1);
                    $type = $param->objectType unless $type;
                    $output .= "Simple: $type ,";
                } else {
                    $output .= "Collection:[";
                    foreach my $simp(@{$param->Simples}){
                        my $type = (($simp->objectType =~ /\:(\S+)$/) && $1);
                        $type = $simp->objectType unless $type;
                        $output .= "$type,";
                    }
                    chop $output;
                    $output .="],";
                }
            }
            chop $output;
            $output .=") ";
            my $desc = $_->description;
            $URI ||=""; $name ||=""; $type ||=""; $output ||=""; $desc ||="";  # set default for next print statement or we choke!
            $popup_services{"$URI#$name"} = "$type returns $output  @"."$URI : $desc";
        }
    }
    $response .= popup_menu(-name => 'SelectedService',
              -values => [keys %popup_services],
              -labels => \%popup_services,
             );
    return $response;
}

sub _what_am_i {
    my ($ObjectDOM) = @_;
    return "TEXT" unless $ObjectDOM;
    my $OntologyTerm = $ObjectDOM->getTagName;
    _LOG("Found type $OntologyTerm\n");
    #my $MC = MOBY::Client::Central->new()
    #$relationships = $MC->Relationships(objectType => $OntolgyTerm, Relationships => ["ISA"]);
    # this SHOULD be done to traverse the ontology to check whether we have derived Image classes
    # but to do this for every object would be painfully slow, so I am
    # hard-coding the known image object types for now.  THIS IS NOT HOW IT SHOULD BE DONE!!!
    return "b64gif" if $OntologyTerm =~ /b64_encoded_gif/;
    return "b64jpeg" if $OntologyTerm =~ /b64_encoded_jpeg/;
    return "TEXT";
    
}

sub _sendError{
	my ($mess) = @_;
    print h1('MOBY Error'),
    p,"\n",
    "The Client encountered an error.<br>Message was <b><i>$mess</i></b>\n",
	p,"\n",
	"Below is the current data in-hand.  Please make another selection based on the message above<hr><br>",
    end_html;
}


sub _LOG {
  return unless $debug;
  open LOG, ">>/tmp/Client05LogOut.txt" or die "can't open logfile $!\n";
  print LOG join "\n", @_;
  print LOG "\n---\n";
  close LOG;
}

sub to_string {
  my $object = shift;
  my $data_dumper = new Data::Dumper([$object]);
  $data_dumper->Purity(1)->Terse(1)->Deepcopy(1);
  return $data_dumper->Dump();
}
