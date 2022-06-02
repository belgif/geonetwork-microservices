<xsl:stylesheet xmlns:dct="http://purl.org/dc/terms/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

  <!-- XSLT stylesheet used to build the file-types.rdf thesaurus -->

  <xsl:output method="xml" indent="yes" encoding="utf-8"/>
  
  <xsl:variable name="fileTypes" select="document('https://publications.europa.eu/resource/authority/file-type')"/>

  <xsl:variable name="schemes">
    <xsl:copy-of select="$fileTypes//rdf:Description[rdf:type/@rdf:resource = 'http://www.w3.org/2004/02/skos/core#ConceptScheme']"/>
  </xsl:variable>

  <xsl:template match="/">
    <rdf:RDF>
      <skos:ConceptScheme>
        <xsl:attribute name="rdf:about" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/@rdf:about" />
        <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')]/skos:prefLabel"/>
        <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/dct:issued"/>
        <xsl:copy-of copy-namespaces="no" select="$schemes//*[name() = ('rdf:Description', 'skos:ConceptScheme')][1]/skos:hasTopConcept"/>
      </skos:ConceptScheme>
      
      <xsl:for-each select="$fileTypes//rdf:Description[skos:inScheme]">
        <xsl:message select="concat('Building concept ', string(@rdf:about))"/>
        <xsl:variable name="concept" select="document(string(@rdf:about))"/>
        <skos:Concept rdf:about="{string(@rdf:about)}">
          <xsl:copy-of copy-namespaces="no" select="$concept//skos:prefLabel[@xml:lang = ('en', 'fr', 'nl', 'de')]"/>
          <xsl:copy-of copy-namespaces="no" select="$concept//skos:inScheme"/>
          <xsl:for-each select="$concept//dct:conformsTo">
            <dct:conformsTo rdf:datatype="http://purl.org/dc/terms/URI">
              <xsl:value-of select="string()"/>
            </dct:conformsTo>
          </xsl:for-each>
        </skos:Concept>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:template>
</xsl:stylesheet>
