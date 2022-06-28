<xsl:stylesheet xmlns:dct="http://purl.org/dc/terms/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

  <xsl:output method="xml" indent="yes" encoding="utf-8"/>

  <!--
  Helper XSL which can be used to combine multiple versions of the same thesauri in different language
  into a single skos only thesaurus
  -->

  <xsl:variable name="thesauri">
    <thesauri>
      <xsl:copy-of select="document('https://inspire.ec.europa.eu/metadata-codelist/SpatialScope/SpatialScope.en.rdf')"/>
      <xsl:copy-of select="document('https://inspire.ec.europa.eu/metadata-codelist/SpatialScope/SpatialScope.fr.rdf')"/>
      <xsl:copy-of select="document('https://inspire.ec.europa.eu/metadata-codelist/SpatialScope/SpatialScope.nl.rdf')"/>
      <xsl:copy-of select="document('https://inspire.ec.europa.eu/metadata-codelist/SpatialScope/SpatialScope.de.rdf')"/>
    </thesauri>
  </xsl:variable>

  <xsl:variable name="schemes">
    <xsl:copy-of select="$thesauri//rdf:Description[rdf:type/@rdf:resource = 'http://www.w3.org/2004/02/skos/core#ConceptScheme']"/>
  </xsl:variable>

  <xsl:variable name="flatConcepts">
    <xsl:copy-of select="$thesauri//*[name() = ('rdf:Description', 'skos:Concept') and skos:inScheme/@rdf:resource = $schemes//rdf:Description[1]/@rdf:about]"/>
  </xsl:variable>


  <xsl:template match="/">
    <rdf:RDF>
      <xsl:call-template name="ConceptScheme"/>
      <xsl:call-template name="Concepts"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template name="ConceptScheme">
    <skos:ConceptScheme>
      <xsl:attribute name="rdf:about" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/@rdf:about" />
      <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')]/skos:prefLabel"/>
      <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')]/dct:title"/>
      <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/dct:issued"/>
      <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/dct:identifier"/>
      <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/skos:hasTopConcept"/>
    </skos:ConceptScheme>
  </xsl:template>

  <xsl:template name="Concepts">
    <xsl:for-each-group select="$flatConcepts/*[name() = ('rdf:Description', 'skos:Concept')]" group-by="@rdf:about">
      <skos:Concept>
        <xsl:attribute name="rdf:about" select="current-grouping-key()"/>
        <xsl:choose>
          <xsl:when test="count(current-group()/skos:prefLabel) > 0">
            <xsl:copy-of copy-namespaces="no" select="current-group()/skos:prefLabel"/>
          </xsl:when>
          <xsl:when test="count(current-group()/dct:title) > 0">
            <xsl:for-each select="current-group()/dct:title">
              <skos:prefLabel>
                <xsl:attribute name="xml:lang" select="@xml:lang"/>
                <xsl:value-of select="string()"/>
              </skos:prefLabel>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="doc" select="document(current-grouping-key())"/>
            <xsl:copy-of copy-namespaces="no" select="$doc//*[@rdf:about = current-grouping-key()]//skos:prefLabel[@xml:lang = 'en']"/>
            <xsl:copy-of copy-namespaces="no" select="$doc//*[@rdf:about = current-grouping-key()]//skos:prefLabel[@xml:lang = 'fr']"/>
            <xsl:copy-of copy-namespaces="no" select="$doc//*[@rdf:about = current-grouping-key()]//skos:prefLabel[@xml:lang = 'nl']"/>
            <xsl:copy-of copy-namespaces="no" select="$doc//*[@rdf:about = current-grouping-key()]//skos:prefLabel[@xml:lang = 'de']"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of copy-namespaces="no" select="current-group()[1]/skos:inScheme"/>
      </skos:Concept>
    </xsl:for-each-group>
  </xsl:template>

</xsl:stylesheet>