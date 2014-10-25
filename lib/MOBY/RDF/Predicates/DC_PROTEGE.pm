package MOBY::RDF::Predicates::DC_PROTEGE;

use strict;

BEGIN {

	use constant DC_PROTEGE_PREFIX => 'protege-dc';

	use constant DC_PROTEGE_URI =>
	  'http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#';

################################
## Predicates for DC_PROTEGE  ##
################################

	use constant identifier => DC_PROTEGE_URI . 'identifier';
	use constant creator    => DC_PROTEGE_URI . 'creator';
	use constant publisher  => DC_PROTEGE_URI . 'publisher';
	use constant format  	=> DC_PROTEGE_URI . 'format';

}
1;
