package MOBY::Services::HelloWorldService;

# the helloWorld service simply echo's back
# to you what you send it... in proper MOBY
# message format of course :-)

use MOBY::CommonSubs qw(:all);

sub helloWorld {
	my ($caller, $message) = @_;  # get the incoming MOBY query XML
	my @queries = getInputs($message);  # returns XML::DOM nodes
        my $MOBY_RESPONSE = "";           # set empty response

        foreach my $query(@queries){
            my $queryID = getInputID($query);  # get the queryID attribute of the queryInput
            my @input_articles = getArticles($query); # get the Simple/Collection articles making up this query
            foreach my $input(@input_articles){       # input is a listref
               my ($articleName, $article) = @{$input}; # get the named article

               my $simple = isSimpleArticle($article);  # articles may be simple or collection
               my $collection = isCollectionArticle($article);

               if ($collection){
                   my @simples = getCollectedSimples($article); # XML::DOM nodes!
		   my @simpleobjects = map {extractRawContent($_)} @simples; # convert the DOM to a string
		   $MOBY_RESPONSE .=collectionResponse(\@simpleobjects, $articleName, $queryID);
               } elsif ($simple){
                   $MOBY_RESPONSE .= simpleResponse(extractRawContent($article), $articleName, $queryID);
               }
            }
          }
          return responseHeader("hello.world.com") . $MOBY_RESPONSE . responseFooter;
}

1;

