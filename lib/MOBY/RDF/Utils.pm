#-----------------------------------------------------------------
# MOBY::RDF::Utils
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Utils.pm,v 1.4 2008/03/05 17:39:43 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Utils;

use XML::LibXML;
use LWP::UserAgent;
use HTTP::Request;

use strict;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------

=head1 NAME

MOBY::RDF::Utils - Create RDF/OWL for Moby datatypes

=head1 SYNOPSIS

	use MOBY::RDF::Utils;


=head1 DESCRIPTION

This module contains utility methods

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
	my ($class) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	$self->{xslt} = <<END;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:output method="xml" version="1.0" encoding="UTF-8" omit-xml-declaration="yes" indend="yes"/>
   <xsl:param name="indent-increment" select="'  '" />
   <xsl:template match="*">
      <xsl:param name="indent" select="'&#xA;'"/>
      <xsl:value-of select="\$indent"/>
      <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:apply-templates>
          <xsl:with-param name="indent"
               select="concat(\$indent, \$indent-increment)"/>
        </xsl:apply-templates>
        <xsl:if test="*">
          <xsl:value-of select="\$indent"/>
        </xsl:if>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="comment()|processing-instruction()">
      <xsl:copy ></xsl:copy>
   </xsl:template>
   <!-- WARNING: this is dangerous. Handle with care -->
   <xsl:template match="text()[normalize-space(.)='']"/>
</xsl:stylesheet>
END

	# done
	return $self;
}

=head2 prettyPrintXML

Return a string of XML that is formatted nicely 

=cut

sub prettyPrintXML {
	my ( $self, $hash ) = @_;
	my $xml = $hash->{xml};
	unless ($xml) {
		$xml = <<END;
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"></rdf:RDF>
END
	}

	eval "require XML::LibXSLT";
	if ($@) {
		my $parser = XML::LibXML->new();
		my $source = $parser->parse_string($xml);
		$xml = $source->toString(0);
		return $xml;
	} else {
		my $parser     = XML::LibXML->new();
		my $xslt       = XML::LibXSLT->new();
		my $source     = $parser->parse_string($xml);
		my $style_doc  = $parser->parse_string( $self->{xslt} );
		my $stylesheet = $xslt->parse_stylesheet($style_doc);
		my $results    = $stylesheet->transform($source);
		$xml = $stylesheet->output_string($results);
		return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" . $xml;
	}
}

=head2 getHttpRequestByURL

returns a scalar of text obtained from the url or dies if there was no success

=cut

sub getHttpRequestByURL {
	my ( $self, $url ) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->agent( "pMOBY/Central/1.0");

	my $req =
	  HTTP::Request->new( GET =>
		  $url );

	# accept gzip encoding
	$req->header( 'Accept-Encoding' => 'gzip' );

	# send request
	my $res = $ua->request($req);

	# check the outcome
	if ( $res->is_success ) {
		if ( $res->header('content-encoding') and $res->header('content-encoding') eq 'gzip' ) {
			return $res->decoded_content;
		} else {
			return $res->content;
		}
	} else {
		die "Error getting data from URL:\n\t" . $res->status_line;
	}    
}

1;
__END__
