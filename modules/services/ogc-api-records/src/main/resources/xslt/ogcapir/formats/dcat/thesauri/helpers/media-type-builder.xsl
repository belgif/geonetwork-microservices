<xsl:stylesheet xmlns:dct="http://purl.org/dc/terms/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:iana="http://www.iana.org/assignments"
                version="2.0">

  <!-- XSLT stylesheet used to build the media-types.rdf thesaurus -->

  <xsl:output method="xml" indent="yes" encoding="utf-8"/>

  <xsl:variable name="ianaMediaType" select="document('https://www.iana.org/assignments/media-types/media-types.xml')"/>

  <xsl:template match="/">
    <rdf:RDF>
      <skos:ConceptScheme rdf:about="https://www.iana.org/assignments/media-types">
        <skos:prefLabel xml:lang="en">
          <xsl:value-of select="string($ianaMediaType/iana:registry/iana:title[1])"/>
        </skos:prefLabel>
      </skos:ConceptScheme>

      <!--
        possible registry:
        - application
        - audio
        - font
        - examples
        - image
        - message
        - model
        - multipart
        - text
        - video
      -->
      <xsl:for-each select="$ianaMediaType/iana:registry/iana:registry[@id != 'examples']/iana:record[iana:file]">
        <skos:Concept>
          <xsl:attribute name="rdf:about" select="concat('https://www.iana.org/assignments/media-types/', string(iana:file))"/>
          <skos:prefLabel xml:lang="en">
            <xsl:value-of select="string(iana:name)"/>
          </skos:prefLabel>
          <skos:inScheme rdf:resource="https://www.iana.org/assignments/media-types" />
        </skos:Concept>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:template>
</xsl:stylesheet>