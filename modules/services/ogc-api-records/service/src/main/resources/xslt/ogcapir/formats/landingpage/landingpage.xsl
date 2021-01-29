<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                exclude-result-prefixes="#all"
                version="3.0">

  <xsl:include href="../../html-util.xsl"/>
  <xsl:include href="landingpage-iso19115-3.2018.xsl"/>
  <xsl:include href="landingpage-iso19139.xsl"/>

  <xsl:template mode="getTitle" match="*"/>
  <xsl:template mode="getOverviews" match="*"/>
  <xsl:template mode="getShortAbstract" match="*"/>
  <xsl:template mode="getAfterShortAbstract" match="*"/>

  <!-- Browse the tree here and add specific schema templates
  to catch what should be displayed in that mode. -->
  <xsl:template match="@*|node()" mode="landingpage">
    <xsl:apply-templates mode="landingpage" select="*|@*"/>
  </xsl:template>
</xsl:stylesheet>