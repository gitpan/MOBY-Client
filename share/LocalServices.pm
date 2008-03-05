#$Id: LocalServices.pm,v 1.1 2008/02/22 16:32:43 kawas Exp $
package Services::LocalServices;

use strict;
use LWP::UserAgent;
use MIME::Base64;
use SOAP::Lite;
use DBD::mysql;
use MOBY::CommonSubs qw(:all);  # this provides the following vars and functions

my $debug = 0;


##################################################
##################################################
#  ALL BROWSERS PLEASE NOTE!!
#  Most of the subroutines in this module use the
#  following basic template for service
#  provision.  They add a few more lines to do
#  error_checking and validations, but generally
#  speaking the few lines below are all
#  that a service requires :-)
##################################################
##################################################


 sub generic_service_template {
    my ($caller, $incoming_message) = @_;
    my $MOBY_RESPONSE; # holds the response raw XML

    my $inputs= serviceInputParser($incoming_message);
        # or fail properly with an empty response if there is no input
    return SOAP::Data->type('base64' => responseHeader("my.authURI.com") . responseFooter()) unless (keys %$inputs);

    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
        my $output = "";
	if (my $input = $this_invocation->{incomingRequest}){  # there must be an article with the articleName we expect, or we will return an empty response
                my ($namespace) = @{$input->namespaces}; # this is returned as a list!
                my $id = $input->id;
                my $XML_LibXML = $input->XML_DOM;  # if I need to get the rest of the content

                # here is where you do whatever manipulation you need to do
                # with namespace/id for your particular service.
                # you will be building an XML document into $output
		$output = "<SomeObject namespace='' id=''>....</SomeObject>";
	} 
        $MOBY_RESPONSE .= simpleResponse(
			$output,       # appending individual responses for each query
                    , "myArticleName"  # the article name of that output object
                    , $queryID);       # the queryID of the input that we are responding to
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));
 }



sub generic_collection_output_template {


    my($caller, $message) = @_;
    my $inputs = serviceInputParser($message);
    my $MOBY_RESPONSE = "";           # set empty response

    # return empty SOAP envelope if ther is no moby input

    return SOAP::Data->type('base64' => responseHeader().responseFooter()) unless (keys %$inputs);

    foreach my $queryID(keys %$inputs){  # $inputs is a hashref of $input{queryid}->{articlename} = input object
        my $this_invocation = $inputs->{$queryID};
        my @outputs;
        if (my $input = $this_invocation->{incomingArticleName}){ # $input is a MOBY::Client::Simple|Collection|Parameter object
                my $id = $input->id;
                my @agis = &_getMyOutputList($id);  # this subroutine contains your business logic and returns a list of ids
                foreach (@agis){
                        push @outputs, "<Object namespace='MyNamespace' id='$_'/>";
                }
        }
        $MOBY_RESPONSE .= collectionResponse (\@outputs, "myOutputArticleName", $queryID);
    }
    return SOAP::Data->type('base64' => (responseHeader("my.authority.org") . $MOBY_RESPONSE . responseFooter));
 }




##################################################
##################################################
##################################################
##################################################


# another example using GO terms

 sub getGoTerm {
    my ($caller, $incoming_message) = @_;
    my $MOBY_RESPONSE; # holds the response raw XML
    my @validNS = validateNamespaces("GO");  # do this if you intend to be namespace aware!

    my $dbh = _connectToGoDatabase();  # connect to some database
    return SOAP::Data->type('base64' => responseHeader('my.authURI.com') . responseFooter()) unless $dbh;
    my $sth = $dbh->prepare(q{   # prepare your query
       select name, term_definition
       from term, term_definition
       where term.id = term_definition.term_id
       and acc=?});

    my $inputs= serviceInputParser($incoming_message); # get incoming invocations
        # or fail properly with an empty response if there is no input
    return SOAP::Data->type('base64' => responseHeader("my.authURI.com") . responseFooter()) unless (keys %$inputs);

    foreach my $queryID(keys %$inputs){
        my $this_invocation = $inputs->{$queryID};  # this is the <mobyData> block with this queryID
        my $invocation_output; # prepare a variable to hold the output XML from this invocation

        if (my $input = $this_invocation->{"GO_id"}){  # we're looking for the input article with articleName "GO_id"
            my ($namespace) = @{$input->namespaces}; # this is returned as a list!
            my $id = $input->id;
            
            # optional - if we want to ENSURE that the incoming ID is in the GO namespace
            # we can validate it using the validateThisNamespace routine of CommonSubs
            # @validNS comes from validateNamespaces routine of CommonSubs (called above)
            if (validateThisNamespace($namespace, @validNS)){ 

	        # here's our business logic...
        	$sth->execute($id);
            	my ($term, $def) = $sth->fetchrow_array;
            	if ($term){
                	 $invocation_output =
                 	"<moby:GO_Term namespace='GO' id='$id'>
                  	<moby:String namespace='' id='' articleName='Term'>$term</moby:String>
                  	<moby:String namespace='' id='' articleName='Definition'>$def</moby:String>
                 	</moby:GO_Term>";
            	}
	    }
        }
        # was our service execution successful?
        # if so, then build an output message
        # if not, build an empty output message
        if ($invocation_output){ # we need to append the data to the MOBY_RESPONSE
            $MOBY_RESPONSE .= simpleResponse( # simpleResponse is exported from CommonSubs
                $invocation_output   # response for this query
                , "A_GoTerm"  # the article name of that output object
                , $queryID);    # the queryID of the input that we are responding to
        } else {
            $MOBY_RESPONSE .= simpleResponse( # create an empty response for this queryID
                ""   # response for this query
                , "A_GoTerm"  # the article name of that output object
                , $queryID);    # the queryID of the input that we are responding to
        }
    }
    # now return the result
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));
}

sub _dbAccess {
    my ($dbname) = @_;
    return undef unless $dbname;
	
	my ($dsn) = "DBI:mysql:go:example.com:3306";
	my $dbh = DBI->connect($dsn, 'user', 'pass', {RaiseError => 1}) or die "can't connect to database";
	
	return ($dbh);
}
    
1;
