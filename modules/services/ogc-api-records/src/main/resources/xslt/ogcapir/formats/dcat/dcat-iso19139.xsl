<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright 2015-2020 EUROPEAN UNION
  Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
  the European Commission - subsequent versions of the EUPL (the "Licence");
  You may not use this work except in compliance with the Licence.
  You may obtain a copy of the Licence at:

  https://joinup.ec.europa.eu/collection/eupl

  Unless required by applicable law or agreed to in writing, software
  distributed under the Licence is distributed on an "AS IS" basis,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the Licence for the specific language governing permissions and
  limitations under the Licence.

  Contributors: ISA GeoDCAT-AP Working Group <https://github.com/SEMICeu/geodcat-ap>

  This work was originally supported by the EU Interoperability Solutions for
  European Public Administrations Programme (http://ec.europa.eu/isa)
  through Action 1.17: Re-usable INSPIRE Reference Platform
  (http://ec.europa.eu/isa/actions/01-trusted-information-exchange/1-17action_en.htm).

-->
<xsl:stylesheet
  xmlns:adms   = "http://www.w3.org/ns/adms#"
  xmlns:cnt    = "http://www.w3.org/2011/content#"
  xmlns:dc     = "http://purl.org/dc/elements/1.1/"
  xmlns:dcat   = "http://www.w3.org/ns/dcat#"
  xmlns:dct    = "http://purl.org/dc/terms/"
  xmlns:dctype = "http://purl.org/dc/dcmitype/"
  xmlns:earl   = "http://www.w3.org/ns/earl#"
  xmlns:foaf   = "http://xmlns.com/foaf/0.1/"
  xmlns:gco    = "http://www.isotc211.org/2005/gco"
  xmlns:gmd    = "http://www.isotc211.org/2005/gmd"
  xmlns:gml    = "http://www.opengis.net/gml"
  xmlns:gmx    = "http://www.isotc211.org/2005/gmx"
  xmlns:gsp    = "http://www.opengis.net/ont/geosparql#"
  xmlns:i      = "http://inspire.ec.europa.eu/schemas/common/1.0"
  xmlns:i-gp   = "http://inspire.ec.europa.eu/schemas/geoportal/1.0"
  xmlns:locn   = "http://www.w3.org/ns/locn#"
  xmlns:owl    = "http://www.w3.org/2002/07/owl#"
  xmlns:org    = "http://www.w3.org/ns/org#"
  xmlns:prov   = "http://www.w3.org/ns/prov#"
  xmlns:rdf    = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs   = "http://www.w3.org/2000/01/rdf-schema#"
  xmlns:schema = "http://schema.org/"
  xmlns:skos   = "http://www.w3.org/2004/02/skos/core#"
  xmlns:srv    = "http://www.isotc211.org/2005/srv"
  xmlns:vcard  = "http://www.w3.org/2006/vcard/ns#"
  xmlns:wdrs   = "http://www.w3.org/2007/05/powder-s#"
  xmlns:xlink  = "http://www.w3.org/1999/xlink"
  xmlns:xsi    = "http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsl    = "http://www.w3.org/1999/XSL/Transform"
  xmlns:dqv    = "http://www.w3.org/ns/dqv#"
  xmlns:geodcat="http://data.europa.eu/930/"
  xmlns:sdmx-attribute="http://purl.org/linked-data/sdmx/2009/attribute#"
  exclude-result-prefixes="earl gco gmd gml gmx i i-gp srv xlink xsi xsl wdrs"
  version="2.0">

  <xsl:output method="xml"
              indent="yes"
              encoding="utf-8"
              cdata-section-elements="locn:geometry dcat:bbox" />

  <!--
    Mapping parameters
    ==================
      This section includes mapping parameters by the XSLT processor used, or, possibly, manually.
  -->

  <!-- Parameter $CoupledResourceLookUp -->
  <!--
    This parameter specifies whether the coupled resource, referenced via @xlink:href, should be looked up to fetch the resource's  unique resource identifier (i.e., code and code space). More precisely:
    - value "enabled": The coupled resource is looked up
    - value "disabled": The coupled resource is not looked up
    CAVEAT: Using this feature may cause the transformation to hang, in case the URL in @xlink:href is broken, the request hangs indefinitely, or does not return the expected resource (e.g., and HTML page, instead of an XML-encoded ISO 19139 record). It is strongly recommended that this issue is dealt with by using appropriate configuration parameters and error handling (e.g., by specifying a timeout on HTTP calls and by setting the HTTP Accept header to "application/xml").
  -->
  <xsl:variable name="CoupledResourceLookUp" select="'disabled'" />

  <!--
    Global variables
    =======================
  -->

  <!-- Variables to be used to convert strings into lower/uppercase by using the translate() function. -->
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

  <!-- URIs, URNs and names for spatial reference system registers. -->
  <xsl:variable name="EpsgSrsBaseUri" select="'http://www.opengis.net/def/crs/EPSG/0'"/>
  <xsl:variable name="EpsgSrsBaseUrn" select="'urn:ogc:def:crs:EPSG'"/>
  <xsl:variable name="EpsgSrsName" select="'EPSG Coordinate Reference Systems'"/>
  <xsl:variable name="OgcSrsBaseUri" select="'http://www.opengis.net/def/crs/OGC'"/>
  <xsl:variable name="OgcSrsBaseUrn" select="'urn:ogc:def:crs:OGC'"/>
  <xsl:variable name="OgcSrsName" select="'OGC Coordinate Reference Systems'"/>

  <!-- URI and URN for CRS84. -->
  <xsl:variable name="Crs84Uri" select="concat($OgcSrsBaseUri,'/1.3/CRS84')"/>
  <xsl:variable name="Crs84Urn" select="concat($OgcSrsBaseUrn,':1.3:CRS84')"/>

  <!-- URI and URN for ETRS89. -->
  <xsl:variable name="Etrs89Uri" select="concat($EpsgSrsBaseUri,'/4258')"/>
  <xsl:variable name="Etrs89Urn" select="concat($EpsgSrsBaseUrn,'::4258')"/>

  <!-- URI and URN of the spatial reference system (SRS) used in the bounding box.
       The default SRS is CRS84. If a different SRS is used, also parameter
       $SrsAxisOrder must be specified. -->

  <!-- The SRS URI is used in the WKT and GML encodings of the bounding box. -->
  <xsl:variable name="SrsUri" select="$Crs84Uri"/>
  <!-- The SRS URN is used in the GeoJSON encoding of the bounding box. -->
  <xsl:variable name="SrsUrn" select="$Crs84Urn"/>

  <!-- Axis order for the reference SRS:
       - "LonLat": longitude / latitude
       - "LatLon": latitude / longitude.
       The axis order must be specified only if the reference SRS is different from CRS84.
       If the reference SRS is CRS84, this parameter is ignored. -->
  <xsl:variable name="SrsAxisOrder" select="'LonLat'"/>

  <!-- Namespaces -->
  <xsl:variable name="xsd" select="'http://www.w3.org/2001/XMLSchema#'"/>
  <xsl:variable name="dct" select="'http://purl.org/dc/terms/'"/>
  <xsl:variable name="dctype" select="'http://purl.org/dc/dcmitype/'"/>
  <xsl:variable name="dcat" select="'http://www.w3.org/ns/dcat#'"/>
  <xsl:variable name="gsp" select="'http://www.opengis.net/ont/geosparql#'"/>
  <xsl:variable name="foaf" select="'http://xmlns.com/foaf/0.1/'"/>
  <xsl:variable name="vcard" select="'http://www.w3.org/2006/vcard/ns#'"/>
  <xsl:variable name="skos" select="'http://www.w3.org/2004/02/skos/core#'"/>
  <xsl:variable name="op" select="'http://publications.europa.eu/resource/authority/'"/>
  <xsl:variable name="opcountry" select="concat($op,'country/')"/>
  <xsl:variable name="oplang" select="concat($op,'language/')"/>
  <xsl:variable name="opcb" select="concat($op,'corporate-body/')"/>
  <xsl:variable name="opfq" select="concat($op,'frequency/')"/>
  <xsl:variable name="cldFrequency" select="'http://purl.org/cld/freq/'"/>

  <!-- This is used as the datatype for the GeoJSON-based encoding of the bounding box. -->
  <xsl:variable name="geojsonMediaTypeUri" select="'https://www.iana.org/assignments/media-types/application/vnd.geo+json'" />
  <xsl:variable name="geojsonLiteralMediaTypeUri" select="'http://www.opengis.net/ont/geosparql#geoJSONLiteral'" />

  <!-- INSPIRE code list URIs -->
  <xsl:variable name="INSPIRECodelistUri" select="'http://inspire.ec.europa.eu/metadata-codelist/'"/>
  <xsl:variable name="SpatialDataServiceCategoryCodelistUri" select="concat($INSPIRECodelistUri,'SpatialDataServiceCategory')"/>
  <xsl:variable name="DegreeOfConformityCodelistUri" select="concat($INSPIRECodelistUri,'DegreeOfConformity')"/>
  <xsl:variable name="ResourceTypeCodelistUri" select="concat($INSPIRECodelistUri,'ResourceType')"/>
  <xsl:variable name="ResponsiblePartyRoleCodelistUri" select="concat($INSPIRECodelistUri,'ResponsiblePartyRole')"/>
  <xsl:variable name="SpatialDataServiceTypeCodelistUri" select="concat($INSPIRECodelistUri,'SpatialDataServiceType')"/>
  <xsl:variable name="TopicCategoryCodelistUri" select="concat($INSPIRECodelistUri,'TopicCategory')"/>

  <!-- INSPIRE code list URIs (not yet supported; the URI pattern is tentative) -->
  <xsl:variable name="SpatialRepresentationTypeCodelistUri" select="concat($INSPIRECodelistUri,'SpatialRepresentationType')"/>
  <xsl:variable name="MaintenanceFrequencyCodelistUri" select="concat($INSPIRECodelistUri,'MaintenanceFrequencyCode')"/>

  <!-- INSPIRE glossary URI -->
  <xsl:variable name="INSPIREGlossaryUri" select="'http://inspire.ec.europa.eu/glossary/'"/>

  <!-- Other variables -->
  <xsl:variable name="OgcAPIUrl" select="'http://localhost:8081'" />
  <xsl:variable name="allThesauri">
    <xsl:copy-of select="document('./thesauri/language.rdf')"/>
    <xsl:copy-of select="document('./thesauri/TopicCategory.rdf')"/>
    <xsl:copy-of select="document('./thesauri/frequency.rdf')"/>
    <xsl:copy-of select="document('./thesauri/access-rights.rdf')"/>
    <xsl:copy-of select="document('./thesauri/SpatialRepresentationType.rdf')"/>
  </xsl:variable>


  <!--
    Master template
    ===============
   -->
  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates select="gmd:MD_Metadata|//gmd:MD_Metadata"/>
    </rdf:RDF>
  </xsl:template>

  <!--
    Metadata template
    =================
   -->
  <xsl:template match="gmd:MD_Metadata|//gmd:MD_Metadata">

    <xsl:variable name="ResourceUri" select="concat($OgcAPIUrl, '/collections/main/items/', gmd:fileIdentifier/gco:CharacterString)" />

    <xsl:variable name="MetadataUri">
      <xsl:variable name="mURI" select="gmd:fileIdentifier/gco:CharacterString"/>
      <xsl:if test="$mURI != '' and ( starts-with($mURI, 'http://') or starts-with($mURI, 'https://') )">
        <xsl:value-of select="$mURI"/>
      </xsl:if>
    </xsl:variable>

    <!--

      Other parameters
      ================

    -->

    <!-- Metadata language: corresponding Alpha-2 codes -->

    <xsl:variable name="ormlang">
      <xsl:choose>
        <xsl:when test="gmd:language/gmd:LanguageCode/@codeListValue != ''">
          <xsl:value-of select="translate(gmd:language/gmd:LanguageCode/@codeListValue,$uppercase,$lowercase)"/>
        </xsl:when>
        <xsl:when test="gmd:language/gmd:LanguageCode != ''">
          <xsl:value-of select="translate(gmd:language/gmd:LanguageCode,$uppercase,$lowercase)"/>
        </xsl:when>
        <xsl:when test="gmd:language/gco:CharacterString != ''">
          <xsl:value-of select="translate(gmd:language/gco:CharacterString,$uppercase,$lowercase)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="MetadataLanguage">
      <xsl:choose>
        <xsl:when test="$ormlang = 'bul'">
          <xsl:text>bg</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'cze'">
          <xsl:text>cs</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'dan'">
          <xsl:text>da</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'ger'">
          <xsl:text>de</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'gre'">
          <xsl:text>el</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'eng'">
          <xsl:text>en</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'spa'">
          <xsl:text>es</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'est'">
          <xsl:text>et</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'fin'">
          <xsl:text>fi</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'fre'">
          <xsl:text>fr</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'gle'">
          <xsl:text>ga</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'hrv'">
          <xsl:text>hr</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'ita'">
          <xsl:text>it</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'lav'">
          <xsl:text>lv</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'lit'">
          <xsl:text>lt</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'hun'">
          <xsl:text>hu</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'mlt'">
          <xsl:text>mt</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'dut'">
          <xsl:text>nl</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'pol'">
          <xsl:text>pl</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'por'">
          <xsl:text>pt</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'rum'">
          <xsl:text>ru</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'slo'">
          <xsl:text>sk</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'slv'">
          <xsl:text>sl</xsl:text>
        </xsl:when>
        <xsl:when test="$ormlang = 'swe'">
          <xsl:text>sv</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$ormlang"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Resource language: corresponding Alpha-2 codes -->

    <xsl:variable name="IsoScopeCode">
      <xsl:value-of select="normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)"/>
    </xsl:variable>

    <xsl:variable name="InspireResourceType">
      <xsl:if test="$IsoScopeCode = 'dataset' or $IsoScopeCode = 'series' or $IsoScopeCode = 'service'">
        <xsl:value-of select="$IsoScopeCode"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="ResourceType">
      <xsl:choose>
        <xsl:when test="$IsoScopeCode = 'dataset' or $IsoScopeCode = 'nonGeographicDataset'">
          <xsl:text>dataset</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$IsoScopeCode"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="ServiceType">
      <xsl:value-of select="gmd:identificationInfo/*/srv:serviceType/gco:LocalName"/>
    </xsl:variable>

    <xsl:variable name="ResourceTitle">
      <xsl:for-each select="gmd:identificationInfo[1]/*/gmd:citation/*/gmd:title">
        <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString)"/></dct:title>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">dct:title</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ResourceAbstract">
      <xsl:for-each select="gmd:identificationInfo[1]/*/gmd:abstract">
        <dct:description xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString)"/></dct:description>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">dct:description</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Lineage">
      <xsl:for-each select="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:statement">
        <dct:provenance>
          <dct:ProvenanceStatement>
            <rdfs:label xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString)"/></rdfs:label>
            <xsl:call-template name="LocalisedString">
              <xsl:with-param name="term">rdfs:label</xsl:with-param>
              <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
            </xsl:call-template>
          </dct:ProvenanceStatement>
        </dct:provenance>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="MetadataDate">
      <xsl:choose>
        <xsl:when test="gmd:dateStamp/gco:Date">
          <xsl:value-of select="gmd:dateStamp/gco:Date"/>
        </xsl:when>
        <xsl:when test="gmd:dateStamp/gco:DateTime">
          <xsl:value-of select="normalize-space(gmd:dateStamp/gco:DateTime/text())"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="ResourceCharacterEncoding">
      <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification">
        <xsl:apply-templates select="gmd:characterSet/gmd:MD_CharacterSetCode"/>
      </xsl:for-each>
    </xsl:variable>

    <!-- Metadata description (metadata on metadata) -->
    <xsl:variable name="MetadataDescription">
      <!-- Metadata language -->
      <xsl:if test="$ormlang != ''">
        <dct:language rdf:resource="{concat($oplang, translate($ormlang, $lowercase, $uppercase))}"/>
      </xsl:if>
      <!-- Metadata date -->
      <xsl:if test="$MetadataDate != ''">
        <xsl:variable name="data-type">
          <xsl:call-template name="DateDataType">
            <xsl:with-param name="date" select="$MetadataDate"/>
          </xsl:call-template>
        </xsl:variable>
        <dct:modified rdf:datatype="{$xsd}{$data-type}">
          <xsl:value-of select="$MetadataDate"/>
        </dct:modified>
      </xsl:if>
      <!-- Metadata file identifier (tentative) -->
      <xsl:for-each select="gmd:fileIdentifier/gco:CharacterString">
        <dct:identifier rdf:datatype="{$xsd}string">
          <xsl:value-of select="."/>
        </dct:identifier>
      </xsl:for-each>
    </xsl:variable>

    <!-- Resource description (resource metadata) -->
    <xsl:variable name="ResourceDescription">

      <xsl:if test="$InspireResourceType != ''">
        <dct:type rdf:resource="{$ResourceTypeCodelistUri}/{$ResourceType}"/>
      </xsl:if>

      <xsl:copy-of select="$ResourceTitle"/>
      <xsl:copy-of select="$ResourceAbstract"/>

      <!-- Metadata point of contact -->
      <xsl:apply-templates select="gmd:contact/gmd:CI_ResponsibleParty">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        <xsl:with-param name="ResourceType" select="$ResourceType"/>
      </xsl:apply-templates>

      <!-- Maintenance information (tentative) -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:resourceMaintenance">
        <xsl:apply-templates select="gmd:MD_MaintenanceInformation/gmd:maintenanceAndUpdateFrequency/gmd:MD_MaintenanceFrequencyCode"/>
      </xsl:for-each>

      <!-- Topic category -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:topicCategory">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Keyword -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:descriptiveKeywords/gmd:MD_Keywords">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        <xsl:with-param name="ResourceType" select="$ResourceType"/>
        <xsl:with-param name="ServiceType" select="$ServiceType"/>
      </xsl:apply-templates>

      <!-- Unique Resource Identifier -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:citation/*/gmd:identifier/*"/>

      <!-- HTML landing page -->
      <xsl:apply-templates select="gmd:fileIdentifier/gco:CharacterString" />

      <!-- Coupled resources -->
      <xsl:apply-templates select="gmd:identificationInfo[1]/*/srv:operatesOn">
        <xsl:with-param name="ResourceType" select="$ResourceType"/>
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Resource Language -->
      <xsl:if test="$ResourceType = 'dataset' or $ResourceType = 'series'">
        <xsl:apply-templates select="gmd:identificationInfo/*/gmd:language" />
      </xsl:if>

      <!-- Spatial service type -->
      <xsl:if test="$ResourceType = 'service'">
        <dct:type rdf:resource="{$SpatialDataServiceTypeCodelistUri}/{$ServiceType}"/>
      </xsl:if>

      <!-- Spatial extent -->
      <xsl:apply-templates select="gmd:identificationInfo[1]/*/*[self::gmd:extent|self::srv:extent]/*/gmd:geographicElement">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Temporal extent -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent"/>

      <!-- Creation date, publication date, date of last revision -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation"/>

      <!-- Lineage -->
      <xsl:if test="$ResourceType != 'service' and $Lineage != ''">
        <xsl:copy-of select="$Lineage"/>
      </xsl:if>

      <!-- Coordinate and temporal reference systems (tentative) -->
      <xsl:if test="$ResourceType = 'service'">
        <xsl:apply-templates select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier">
          <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        </xsl:apply-templates>
      </xsl:if>

      <!-- Spatial resolution -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:spatialResolution/gmd:MD_Resolution"/>

      <!-- Conformity -->
      <xsl:apply-templates select="gmd:dataQualityInfo/*/gmd:report/*/gmd:result/*/gmd:specification/gmd:CI_Citation">
        <xsl:with-param name="ResourceUri" select="$ResourceUri"/>
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Spatial representation type -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode"/>

      <!-- Resource access rights and licenses -->
      <xsl:apply-templates select="gmd:identificationInfo[1]/*/gmd:resourceConstraints">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Parent dataset -->
      <xsl:if test="$ResourceType = 'dataset' or $ResourceType = 'series'">
        <xsl:apply-templates select="gmd:identificationInfo/*/gmd:aggregationInfo/gmd:MD_AggregateInformation" />
      </xsl:if>

      <!-- Responsible organisation -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:pointOfContact/gmd:CI_ResponsibleParty">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        <xsl:with-param name="ResourceType" select="$ResourceType"/>
      </xsl:apply-templates>

      <xsl:for-each select="gmd:distributionInfo/gmd:MD_Distribution">
        <!-- Encoding -->
        <xsl:variable name="Encoding">
          <xsl:apply-templates select="gmd:distributionFormat/gmd:MD_Format/gmd:name/*"/>
        </xsl:variable>
        <!-- Resource locators (access / download URLs) -->
        <xsl:for-each select="gmd:transferOptions/*/gmd:onLine/*">
          <xsl:variable name="url" select="gmd:linkage/gmd:URL"/>
          <xsl:variable name="protocol" select="string(gmd:protocol/*)"/>
          <xsl:variable name="function" select="string(gmd:function/gmd:CI_OnLineFunctionCode/@codeListValue)"/>
          <xsl:variable name="Title">
            <xsl:for-each select="gmd:name">
              <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString)"/></dct:title>
              <xsl:call-template name="LocalisedString">
                <xsl:with-param name="term">dct:title</xsl:with-param>
                <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <xsl:variable name="Description">
            <xsl:for-each select="gmd:description">
              <dct:description xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString)"/></dct:description>
              <xsl:call-template name="LocalisedString">
                <xsl:with-param name="term">dct:description</xsl:with-param>
                <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <xsl:variable name="TitleAndDescription">
            <xsl:copy-of select="$Title"/>
            <xsl:copy-of select="$Description"/>
          </xsl:variable>

          <xsl:choose>
            <xsl:when test="$ResourceType = 'service'">
              <xsl:call-template name="service-endpoint">
                <xsl:with-param name="function" select="$function"/>
                <xsl:with-param name="protocol" select="$protocol"/>
                <xsl:with-param name="url" select="$url"/>
              </xsl:call-template>
              <xsl:call-template name="service-protocol">
                <xsl:with-param name="function" select="$function"/>
                <xsl:with-param name="protocol" select="$protocol"/>
                <xsl:with-param name="url" select="$url"/>
              </xsl:call-template>
            </xsl:when>
            <!-- Distributions -->
            <xsl:when test="$ResourceType = 'dataset' or $ResourceType = 'series'">
              <xsl:variable name="points-to-service">
                <xsl:call-template name="detect-service">
                  <xsl:with-param name="function" select="$function"/>
                  <xsl:with-param name="protocol" select="$protocol"/>
                  <xsl:with-param name="url" select="$url"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$points-to-service = 'yes' or $function = 'download' or $function = 'offlineAccess' or $function = 'order'">
                  <dcat:distribution>
                    <dcat:Distribution>
                      <!-- Title and description -->
                      <xsl:copy-of select="$TitleAndDescription"/>
                      <!-- Access URL -->
                      <dcat:accessURL rdf:resource="{$url}"/>
                      <xsl:choose>
                        <xsl:when test="$points-to-service = 'yes'">
                          <dcat:accessService rdf:parseType="Resource">
                            <xsl:call-template name="service-endpoint">
                              <xsl:with-param name="function" select="$function"/>
                              <xsl:with-param name="protocol" select="$protocol"/>
                              <xsl:with-param name="url" select="$url"/>
                            </xsl:call-template>=
                            <xsl:call-template name="service-protocol">
                              <xsl:with-param name="function" select="$function"/>
                              <xsl:with-param name="protocol" select="$protocol"/>
                              <xsl:with-param name="url" select="$url"/>
                            </xsl:call-template>
                          </dcat:accessService>
                        </xsl:when>
                      </xsl:choose>

                      <!-- Encoding -->
                      <xsl:copy-of select="$Encoding"/>
                      <!-- Resource character encoding -->
                      <xsl:copy-of select="$ResourceCharacterEncoding"/>
                    </dcat:Distribution>
                  </dcat:distribution>
                </xsl:when>
                <xsl:when test="$function = 'information' and $protocol = 'WWW:LINK-1.0-http--link'">
                  <xsl:for-each select="gmd:linkage/gmd:URL">
                    <foaf:page>
                      <foaf:Document rdf:about="{.}">
                        <xsl:copy-of select="$TitleAndDescription"/>
                      </foaf:Document>
                    </foaf:page>
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Nothing ? -->
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="resourceElementName">
      <xsl:choose>
        <xsl:when test="$ResourceType = 'dataset'">
          <xsl:value-of select="'dcat:Dataset'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'dcat:DataService'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$ResourceUri != ''">
        <xsl:choose>
          <xsl:when test="$MetadataUri != ''">
            <dcat:CatalogRecord rdf:about="{$MetadataUri}">
              <foaf:primaryTopic rdf:resource="{$ResourceUri}"/>
              <xsl:copy-of select="$MetadataDescription"/>
            </dcat:CatalogRecord>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="normalize-space($MetadataDescription)">
              <dcat:CatalogRecord>
                <foaf:primaryTopic rdf:resource="{$ResourceUri}"/>
                <xsl:copy-of select="$MetadataDescription"/>
              </dcat:CatalogRecord>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:element name="{$resourceElementName}">
          <xsl:attribute name="rdf:about" >
            <xsl:value-of select="$ResourceUri"/>
          </xsl:attribute>
          <xsl:copy-of select="$ResourceDescription"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$resourceElementName}">
          <xsl:if test="normalize-space($MetadataDescription)">
            <foaf:isPrimaryTopicOf>
              <dcat:CatalogRecord>
                <xsl:copy-of select="$MetadataDescription"/>
              </dcat:CatalogRecord>
            </foaf:isPrimaryTopicOf>
          </xsl:if>
          <xsl:copy-of select="$ResourceDescription"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--

    Templates for specific metadata elements
    ========================================

  -->

  <!-- Unique Resource Identifier -->
  <xsl:template name="UniqueResourceIdentifier" match="gmd:identificationInfo/*/gmd:citation/*/gmd:identifier/*">
    <xsl:if test="normalize-space(gmd:code/gco:CharacterString) != ''">
      <dct:identifier><xsl:value-of select="normalize-space(gmd:code/gco:CharacterString)"/></dct:identifier>
    </xsl:if>
  </xsl:template>

  <!-- HTML landing page -->
  <xsl:template name="HtmlLandingPage" match="gmd:fileIdentifier/gco:CharacterString">
    <dcat:landingPage>
      <xsl:attribute name="rdf:resource" select="concat('https://www.geo.be/catalog/details/', normalize-space())" />
    </dcat:landingPage>
  </xsl:template>

  <!-- Languages -->
  <xsl:template name="ResourceLanguage" match="gmd:identificationInfo/*/gmd:language">
    <xsl:variable name="orrlang">
      <xsl:choose>
        <xsl:when test="gmd:LanguageCode/@codeListValue != ''">
          <xsl:value-of select="translate(gmd:LanguageCode/@codeListValue, $lowercase, $uppercase)"/>
        </xsl:when>
        <xsl:when test="gmd:LanguageCode != ''">
          <xsl:value-of select="translate(gmd:LanguageCode, $lowercase, $uppercase)"/>
        </xsl:when>
        <xsl:when test="gco:CharacterString != ''">
          <xsl:value-of select="translate(gco:CharacterString, $lowercase, $uppercase)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="mappedLang">
      <xsl:choose>
        <xsl:when test="$orrlang = 'GER'">
          <xsl:value-of select="'DEU'"/>
        </xsl:when>
        <xsl:when test="$orrlang = 'FRE'">
          <xsl:value-of select="'FRA'"/>
        </xsl:when>
        <xsl:when test="$orrlang = 'DUT'">
          <xsl:value-of select="'NLD'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$orrlang"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <dct:language>
      <xsl:copy-of select="$allThesauri//skos:Concept[@rdf:about = concat($oplang, $mappedLang)]"/>
    </dct:language>
  </xsl:template>

  <!-- Responsible Organisation VCARD -->
  <xsl:template name="ResponsibleOrganisationVCard" match="gmd:contact/gmd:CI_ResponsibleParty">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="ResourceType"/>
    <xsl:variable name="role" select="string(gmd:role/gmd:CI_RoleCode/@codeListValue)" />
    <xsl:variable name="IndividualName" select="normalize-space(gmd:individualName/*)" />
    <xsl:variable name="OrganisationName" select="normalize-space(gmd:organisationName/*[self::gco:CharacterString|gmx:Anchor])" />
    <xsl:variable name="OrganisationURI" select="normalize-space(gmd:organisationName/*/@xlink:href)" />

    <xsl:variable name="IndividualName-vCard">
      <xsl:for-each select="gmd:individualName">
        <vcard:fn xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(*[self::gco:CharacterString|gmx:Anchor])"/></vcard:fn>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">vcard:fn</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="OrganisationName-vCard">
      <xsl:for-each select="gmd:organisationName">
        <vcard:organization-name xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(*[self::gco:CharacterString|gmx:Anchor])"/></vcard:organization-name>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">vcard:organization-name</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="OrganisationNameAsIndividualName-vCard">
      <xsl:for-each select="gmd:organisationName">
        <vcard:fn xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(*[self::gco:CharacterString|gmx:Anchor])"/></vcard:fn>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">vcard:fn</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Email-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/*[normalize-space() != '']">
        <vcard:hasEmail rdf:resource="mailto:{normalize-space(.)}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="URL-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL[normalize-space() != '']">
        <vcard:hasURL rdf:resource="{normalize-space(.)}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Telephone-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/*[normalize-space() != '']">
        <vcard:hasTelephone rdf:resource="tel:+{translate(translate(translate(translate(translate(normalize-space(.),' ',''),'(',''),')',''),'+',''),'.','')}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Address-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address">
        <xsl:variable name="deliveryPoint" select="normalize-space(gmd:deliveryPoint/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="city" select="normalize-space(gmd:city/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="administrativeArea" select="normalize-space(gmd:administrativeArea/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="postalCode" select="normalize-space(gmd:postalCode/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="country" select="normalize-space(gmd:country/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:if test="$deliveryPoint != '' or $city != '' or $administrativeArea != '' or $postalCode != '' or $country != ''">
          <vcard:hasAddress>
            <vcard:Address>
              <xsl:if test="$deliveryPoint != ''">
                <xsl:for-each select="gmd:deliveryPoint">
                  <vcard:street-address xml:lang="{$MetadataLanguage}"><xsl:value-of select="$deliveryPoint"/></vcard:street-address>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">vcard:street-address</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$city != ''">
                <xsl:for-each select="gmd:city">
                  <vcard:locality xml:lang="{$MetadataLanguage}"><xsl:value-of select="$city"/></vcard:locality>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">vcard:locality</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$administrativeArea != ''">
                <xsl:for-each select="gmd:administrativeArea">
                  <vcard:region xml:lang="{$MetadataLanguage}"><xsl:value-of select="$administrativeArea"/></vcard:region>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">vcard:region</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$postalCode != ''">
                <vcard:postal-code><xsl:value-of select="$postalCode"/></vcard:postal-code>
              </xsl:if>
              <xsl:if test="$country != ''">
                <xsl:for-each select="gmd:country">
                  <vcard:country-name xml:lang="{$MetadataLanguage}"><xsl:value-of select="$country"/></vcard:country-name>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">vcard:country-name</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
            </vcard:Address>
          </vcard:hasAddress>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ResponsibleParty-vCard">
      <vcard:Organization>
        <xsl:if test="$OrganisationURI != ''">
          <xsl:attribute name="rdf:about" select="$OrganisationURI" />
        </xsl:if>
        <xsl:if test="$IndividualName != ''">
          <xsl:copy-of select="$IndividualName-vCard"/>
        </xsl:if>
        <xsl:if test="$IndividualName != '' and $OrganisationName != ''">
          <xsl:copy-of select="$OrganisationName-vCard"/>
        </xsl:if>
        <xsl:if test="$IndividualName = '' and $OrganisationName != ''">
          <xsl:copy-of select="$OrganisationNameAsIndividualName-vCard"/>
        </xsl:if>
        <xsl:copy-of select="$Telephone-vCard"/>
        <xsl:copy-of select="$Email-vCard"/>
        <xsl:copy-of select="$URL-vCard"/>
        <xsl:copy-of select="$Address-vCard"/>
      </vcard:Organization>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$role = 'pointOfContact'">
        <dcat:contactPoint>
          <xsl:copy-of select="$ResponsibleParty-vCard"/>
        </dcat:contactPoint>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="ResponsibleOrganisation" match="gmd:pointOfContact/gmd:CI_ResponsibleParty">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="ResourceType"/>
    <xsl:variable name="role" select="string(gmd:role/gmd:CI_RoleCode/@codeListValue)" />
    <xsl:variable name="IndividualName" select="normalize-space(gmd:individualName/*)" />
    <xsl:variable name="OrganisationName" select="normalize-space(gmd:organisationName/*[self::gco:CharacterString|gmx:Anchor])" />
    <xsl:variable name="OrganisationURI" select="normalize-space(gmd:organisationName/*/@xlink:href)" />

    <xsl:variable name="IndividualName-FOAF">
      <xsl:for-each select="gmd:individualName">
        <foaf:name xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(*[self::gco:CharacterString|gmx:Anchor])"/></foaf:name>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">foaf:name</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="OrganisationName-FOAF">
      <xsl:for-each select="gmd:organisationName">
        <foaf:name xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(*[self::gco:CharacterString|gmx:Anchor])"/></foaf:name>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">foaf:name</xsl:with-param>
          <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Email-FOAF">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/*[normalize-space() != '']">
        <foaf:mbox rdf:resource="mailto:{normalize-space(.)}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="URL-FOAF">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL[normalize-space() != '']">
        <foaf:workplaceHomepage rdf:resource="{normalize-space(.)}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Telephone-FOAF">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/*[normalize-space() != '']">
        <foaf:phone rdf:resource="tel:+{translate(translate(translate(translate(translate(normalize-space(.),' ',''),'(',''),')',''),'+',''),'.','')}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="Address-FOAF">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address">
        <xsl:variable name="deliveryPoint" select="normalize-space(gmd:deliveryPoint/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="city" select="normalize-space(gmd:city/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="administrativeArea" select="normalize-space(gmd:administrativeArea/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="postalCode" select="normalize-space(gmd:postalCode/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:variable name="country" select="normalize-space(gmd:country/*[name() = ('gco:CharacterString', gmx:Anchor)])"/>
        <xsl:if test="$deliveryPoint != '' or $city != '' or $administrativeArea != '' or $postalCode != '' or $country != ''">
          <locn:address>
            <locn:Address>
              <xsl:if test="$deliveryPoint != ''">
                <xsl:for-each select="gmd:deliveryPoint">
                  <locn:thoroughfare xml:lang="{$MetadataLanguage}"><xsl:value-of select="$deliveryPoint"/></locn:thoroughfare>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">locn:thoroughfare</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$city != ''">
                <xsl:for-each select="gmd:city">
                  <locn:postName xml:lang="{$MetadataLanguage}"><xsl:value-of select="$city"/></locn:postName>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">locn:postName</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$administrativeArea != ''">
                <xsl:for-each select="gmd:administrativeArea">
                  <locn:adminUnitL2 xml:lang="{$MetadataLanguage}"><xsl:value-of select="$administrativeArea"/></locn:adminUnitL2>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">locn:adminUnitL2</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$postalCode != ''">
                <locn:postCode><xsl:value-of select="$postalCode"/></locn:postCode>
              </xsl:if>
              <xsl:if test="$country != ''">
                <xsl:for-each select="gmd:country">
                  <locn:adminUnitL1 xml:lang="{$MetadataLanguage}"><xsl:value-of select="$country"/></locn:adminUnitL1>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">locn:adminUnitL1</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:if>
            </locn:Address>
          </locn:address>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ResponsibleParty-FOAF">
      <foaf:Organization>
        <xsl:if test="$OrganisationURI != ''">
          <xsl:attribute name="rdf:about" select="$OrganisationURI" />
        </xsl:if>
        <xsl:if test="$OrganisationName != ''">
          <xsl:copy-of select="$OrganisationName-FOAF"/>
        </xsl:if>
        <xsl:if test="$OrganisationName = '' and $IndividualName != ''">
          <xsl:copy-of select="$IndividualName-FOAF"/>
        </xsl:if>
        <xsl:copy-of select="$Telephone-FOAF"/>
        <xsl:copy-of select="$Email-FOAF"/>
        <xsl:copy-of select="$URL-FOAF"/>
        <xsl:copy-of select="$Address-FOAF"/>
      </foaf:Organization>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$role = 'publisher'">
        <dct:publisher>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </dct:publisher>
      </xsl:when>
      <xsl:when test="$role = 'custodian'">
        <geodcat:custodian>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:custodian>
      </xsl:when>
      <xsl:when test="$role = 'author'">
        <dct:creator>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </dct:creator>
      </xsl:when>
      <xsl:when test="$role = 'distributor'">
        <geodcat:distributor>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:distributor>
      </xsl:when>
      <xsl:when test="$role = 'originator'">
        <geodcat:originator>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:originator>
      </xsl:when>
      <xsl:when test="$role = 'principalInvestigator'">
        <geodcat:principalInvestigator>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:principalInvestigator>
      </xsl:when>
      <xsl:when test="$role = 'processor'">
        <geodcat:processor>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:processor>
      </xsl:when>
      <xsl:when test="$role = 'resourceProvider'">
        <geodcat:resourceProvider>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:resourceProvider>
      </xsl:when>
      <xsl:when test="$role = 'user'">
        <geodcat:user>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </geodcat:user>
      </xsl:when>
      <xsl:when test="$role = 'owner'">
        <dct:rightsHolder>
          <xsl:copy-of select="$ResponsibleParty-FOAF"/>
        </dct:rightsHolder>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Resource locator -->
  <xsl:template name="ResourceLocator" match="gmd:transferOptions/*/gmd:onLine/*/gmd:linkage">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="ResourceType"/>
    <xsl:choose>
      <xsl:when test="$ResourceType = 'dataset' or $ResourceType = 'series'">
        <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="../gmd:description/gco:CharacterString"/></dct:title>
        <dcat:accessURL rdf:resource="{gmd:URL}"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Coupled resource -->
  <xsl:template name="CoupledResource" match="gmd:identificationInfo[1]/*/srv:operatesOn">
    <xsl:param name="href" select="@xlink:href"/>
    <xsl:param name="code">
      <xsl:choose>
        <xsl:when test="$CoupledResourceLookUp = 'enabled' and $href != '' and (starts-with($href, 'http://') or starts-with($href, 'https://'))">
          <xsl:value-of select="document($href)//gmd:identificationInfo/*/gmd:citation/*/gmd:identifier/*/gmd:code/gco:CharacterString"/>
        </xsl:when>
        <xsl:when test="*/gmd:citation/*/gmd:identifier/*/gmd:code/gco:CharacterString != ''">
          <xsl:value-of select="*/gmd:citation/*/gmd:identifier/*/gmd:code/gco:CharacterString"/>
        </xsl:when>
        <xsl:when test="@uuidref != ''">
          <xsl:value-of select="@uuidref"/>
        </xsl:when>
      </xsl:choose>
    </xsl:param>
    <xsl:param name="codespace">
      <xsl:choose>
        <xsl:when test="$CoupledResourceLookUp = 'enabled' and $href != '' and (starts-with($href, 'http://') or starts-with($href, 'https://'))">
          <xsl:value-of select="document($href)//gmd:identificationInfo/*/gmd:citation/*/gmd:identifier/*/gmd:codeSpace/gco:CharacterString"/>
        </xsl:when>
        <xsl:when test="*/gmd:citation/*/gmd:identifier/*/gmd:codeSpace/gco:CharacterString != ''">
          <xsl:value-of select="*/gmd:citation/*/gmd:identifier/*/gmd:codeSpace/gco:CharacterString"/>
        </xsl:when>
      </xsl:choose>
    </xsl:param>
    <xsl:param name="resID" select="concat($codespace, $code)"/>
    <xsl:param name="uriref" select="@uriref"/>
    <xsl:choose>
      <!-- The use of @uriref is still under discussion by the INSPIRE MIG. -->
      <xsl:when test="$uriref != ''">
        <dcat:servesDataset rdf:resource="{@uriref}"/>
        <!-- DEPRECATED: Mapping kept for backward compatibility with GeoDCAT-AP v1.* -->
        <dct:hasPart rdf:resource="{@uriref}"/>
      </xsl:when>
      <xsl:when test="$code != ''">
        <xsl:choose>
          <xsl:when test="starts-with($code, 'http://') or starts-with($code, 'https://')">
            <dcat:servesDataset rdf:resource="{$code}"/>
            <!-- DEPRECATED: Mapping kept for backward compatibility with GeoDCAT-AP v1.* -->
            <dct:hasPart rdf:resource="{$code}"/>
          </xsl:when>
          <xsl:otherwise>
            <dcat:servesDataset rdf:parseType="Resource">
              <xsl:choose>
                <xsl:when test="starts-with($resID, 'http://') or starts-with($resID, 'https://')">
                  <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$resID"/></dct:identifier>
                </xsl:when>
                <xsl:otherwise>
                  <dct:identifier rdf:datatype="{$xsd}string"><xsl:value-of select="$resID"/></dct:identifier>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$href != '' and $href != '' and (starts-with($href, 'http://') or starts-with($href, 'https://'))">
                <foaf:isPrimaryTopicOf>
                  <dcat:CatalogRecord rdf:about="{$href}"/>
                </foaf:isPrimaryTopicOf>
              </xsl:if>
            </dcat:servesDataset>
            <!-- DEPRECATED: Mapping kept for backward compatibility with GeoDCAT-AP v1.* -->
            <dct:hasPart rdf:parseType="Resource">
              <xsl:choose>
                <xsl:when test="starts-with($resID, 'http://') or starts-with($resID, 'https://')">
                  <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$resID"/></dct:identifier>
                </xsl:when>
                <xsl:otherwise>
                  <dct:identifier rdf:datatype="{$xsd}string"><xsl:value-of select="$resID"/></dct:identifier>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$href != '' and $href != '' and (starts-with($href, 'http://') or starts-with($href, 'https://'))">
                <foaf:isPrimaryTopicOf>
                  <dcat:CatalogRecord rdf:about="{$href}"/>
                </foaf:isPrimaryTopicOf>
              </xsl:if>
            </dct:hasPart>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Conformity -->
  <xsl:template name="Conformity" match="gmd:dataQualityInfo/*/gmd:report/*/gmd:result/gmd:DQ_ConformanceResult/gmd:specification/gmd:CI_Citation">
    <xsl:param name="ResourceUri"/>
    <xsl:param name="MetadataLanguage"/>
    <dct:conformsTo>
      <dct:Standard>
        <xsl:if test="gmd:title/gmx:Anchor/@xlink:href != '' or gmd:title/gmx:Anchor/@gmx:Anchor != ''">
          <xsl:choose>
            <xsl:when test="gmd:title/gmx:Anchor/@xlink:href != ''">
              <xsl:attribute name="rdf:about" select="gmd:title/gmx:Anchor/@xlink:href"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="rdf:about" select="gmd:title/gmx:Anchor/@gmx:Anchor"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        <xsl:for-each select="gmd:title">
          <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/></dct:title>
          <xsl:call-template name="LocalisedString">
            <xsl:with-param name="term">dct:title</xsl:with-param>
            <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
          </xsl:call-template>
        </xsl:for-each>
        <xsl:apply-templates select="gmd:date/gmd:CI_Date"/>
      </dct:Standard>
    </dct:conformsTo>
  </xsl:template>

  <!-- Geographic extent -->
  <xsl:template name="GeographicExtent" match="gmd:identificationInfo[1]/*/*[self::gmd:extent|self::srv:extent]/*/gmd:geographicElement">
    <xsl:param name="MetadataLanguage"/>
    <xsl:apply-templates select="gmd:EX_GeographicDescription/gmd:geographicIdentifier/*">
      <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="gmd:EX_GeographicBoundingBox"/>
  </xsl:template>

  <!-- Geographic bounding box -->
  <xsl:template name="GeographicBoundingBox" match="gmd:EX_GeographicBoundingBox">
    <xsl:variable name="north" select="gmd:northBoundLatitude/gco:Decimal"/>
    <xsl:variable name="east"  select="gmd:eastBoundLongitude/gco:Decimal"/>
    <xsl:variable name="south" select="gmd:southBoundLatitude/gco:Decimal"/>
    <xsl:variable name="west"  select="gmd:westBoundLongitude/gco:Decimal"/>

    <!-- Bbox as GML (GeoSPARQL) -->
    <xsl:variable name="GMLLiteral">
      <xsl:choose>
        <xsl:when test="$SrsUri = 'http://www.opengis.net/def/crs/OGC/1.3/CRS84'">&lt;gml:Envelope srsName="<xsl:value-of select="$SrsUri"/>"&gt;&lt;gml:lowerCorner&gt;<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>&lt;/gml:lowerCorner&gt;&lt;gml:upperCorner&gt;<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>&lt;/gml:upperCorner&gt;&lt;/gml:Envelope&gt;</xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LonLat'">&lt;gml:Envelope srsName="<xsl:value-of select="$SrsUri"/>"&gt;&lt;gml:lowerCorner&gt;<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>&lt;/gml:lowerCorner&gt;&lt;gml:upperCorner&gt;<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>&lt;/gml:upperCorner&gt;&lt;/gml:Envelope&gt;</xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LatLon'">&lt;gml:Envelope srsName="<xsl:value-of select="$SrsUri"/>"&gt;&lt;gml:lowerCorner&gt;<xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>&lt;/gml:lowerCorner&gt;&lt;gml:upperCorner&gt;<xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>&lt;/gml:upperCorner&gt;&lt;/gml:Envelope&gt;</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- Bbox as WKT (GeoSPARQL) -->
    <xsl:variable name="WKTLiteral">
      <xsl:choose>
        <xsl:when test="$SrsUri = 'http://www.opengis.net/def/crs/OGC/1.3/CRS84'">POLYGON((<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>))</xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LonLat'">&lt;<xsl:value-of select="$SrsUri"/>&gt; POLYGON((<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>))</xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LatLon'">&lt;<xsl:value-of select="$SrsUri"/>&gt; POLYGON((<xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>,<xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>,<xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>,<xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>,<xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>))</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- Bbox as GeoJSON -->
    <xsl:variable name="GeoJSONLiteral">{"type":"Polygon","crs":{"type":"name","properties":{"name":"<xsl:value-of select="$SrsUrn"/>"}},"coordinates":[[[<xsl:value-of select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>],[<xsl:value-of select="$east"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>],[<xsl:value-of select="$east"/><xsl:text>,</xsl:text><xsl:value-of select="$south"/>],[<xsl:value-of select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$south"/>],[<xsl:value-of select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>]]]}</xsl:variable>

    <dct:spatial rdf:parseType="Resource">
      <dct:Location>
        <!-- Recommended geometry encodings -->
        <locn:geometry rdf:datatype="{$gsp}wktLiteral"><xsl:value-of select="$WKTLiteral"/></locn:geometry>
        <locn:geometry rdf:datatype="{$gsp}gmlLiteral"><xsl:value-of select="$GMLLiteral"/></locn:geometry>
        <!-- Additional geometry encodings -->
        <locn:geometry rdf:datatype="{$geojsonMediaTypeUri}"><xsl:value-of select="$GeoJSONLiteral"/></locn:geometry>
        <locn:geometry rdf:datatype="{$geojsonLiteralMediaTypeUri}"><xsl:value-of select="$GeoJSONLiteral"/></locn:geometry>

        <!-- Recommended geometry encodings -->
        <dcat:bbox rdf:datatype="{$gsp}wktLiteral"><xsl:value-of select="$WKTLiteral"/></dcat:bbox>
        <dcat:bbox rdf:datatype="{$gsp}gmlLiteral"><xsl:value-of select="$GMLLiteral"/></dcat:bbox>
        <!-- Additional geometry encodings -->
        <dcat:bbox rdf:datatype="{$geojsonMediaTypeUri}"><xsl:value-of select="$GeoJSONLiteral"/></dcat:bbox>
        <dcat:bbox rdf:datatype="{$geojsonLiteralMediaTypeUri}"><xsl:value-of select="$GeoJSONLiteral"/></dcat:bbox>
      </dct:Location>
    </dct:spatial>
  </xsl:template>

  <!-- Temporal extent -->
  <xsl:template name="TemporalExtent" match="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent">
    <xsl:for-each select="gmd:extent/*[local-name() = 'TimeInstant']|gmd:extent/*[local-name() = 'TimePeriod']">
      <xsl:if test="local-name(.) = 'TimeInstant' or ( local-name(.) = 'TimePeriod' and *[local-name() = 'beginPosition'] and *[local-name() = 'endPosition'] )">
        <xsl:variable name="dateStart">
          <xsl:choose>
            <xsl:when test="local-name(.) = 'TimeInstant'">
              <xsl:value-of select="normalize-space(*[local-name() = 'timePosition'])"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(*[local-name() = 'beginPosition'])"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dateStart-data-type">
          <xsl:call-template name="DateDataType">
            <xsl:with-param name="date" select="$dateStart"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dateEnd">
          <xsl:choose>
            <xsl:when test="local-name(.) = 'TimeInstant'">
              <xsl:value-of select="normalize-space(*[local-name() = 'timePosition'])"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(*[local-name() = 'endPosition'])"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dateEnd-data-type">
          <xsl:call-template name="DateDataType">
            <xsl:with-param name="date" select="$dateEnd"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$dateStart != '' or $dateEnd != ''">
          <dct:temporal>
            <dct:PeriodOfTime>
              <!-- DEPRECATED: Mapping kept for backward compatibility with GeoDCAT-AP v1.* -->
              <xsl:if test="$dateStart != ''">
                <schema:startDate rdf:datatype="{$xsd}{$dateStart-data-type}">
                  <xsl:value-of select="$dateStart"/>
                </schema:startDate>
              </xsl:if>
              <xsl:if test="$dateEnd != ''">
                <schema:endDate rdf:datatype="{$xsd}{$dateStart-data-type}">
                  <xsl:value-of select="$dateEnd"/>
                </schema:endDate>
              </xsl:if>
              <xsl:if test="$dateStart != ''">
                <dcat:startDate rdf:datatype="{$xsd}{$dateEnd-data-type}">
                  <xsl:value-of select="$dateStart"/>
                </dcat:startDate>
              </xsl:if>
              <xsl:if test="$dateEnd != ''">
                <dcat:endDate rdf:datatype="{$xsd}{$dateEnd-data-type}">
                  <xsl:value-of select="$dateEnd"/>
                </dcat:endDate>
              </xsl:if>
            </dct:PeriodOfTime>
          </dct:temporal>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Dates of publication, last revision, creation -->
  <xsl:template name="ResourceDates" match="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation">
    <xsl:apply-templates select="gmd:date/gmd:CI_Date"/>
  </xsl:template>

  <!-- Generic date template -->
  <xsl:template name="Dates" match="gmd:date/gmd:CI_Date">
    <xsl:param name="date">
      <xsl:value-of select="normalize-space(gmd:date/gco:Date)"/>
    </xsl:param>
    <xsl:param name="type">
      <xsl:value-of select="gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
    </xsl:param>
    <xsl:param name="data-type">
      <xsl:call-template name="DateDataType">
        <xsl:with-param name="date" select="$date"/>
      </xsl:call-template>
    </xsl:param>
    <xsl:choose>
      <xsl:when test="$type = 'publication'">
        <dct:issued rdf:datatype="{$xsd}{$data-type}">
          <xsl:value-of select="$date"/>
        </dct:issued>
      </xsl:when>
      <xsl:when test="$type = 'revision'">
        <dct:modified rdf:datatype="{$xsd}{$data-type}">
          <xsl:value-of select="$date"/>
        </dct:modified>
      </xsl:when>
      <xsl:when test="$type = 'creation'">
        <dct:created rdf:datatype="{$xsd}{$data-type}">
          <xsl:value-of select="$date"/>
        </dct:created>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Generic date data type template -->
  <xsl:template name="DateDataType">
    <xsl:param name="date"/>
    <xsl:choose>
      <xsl:when test="string-length($date) = 4">
        <xsl:text>gYear</xsl:text>
      </xsl:when>
      <xsl:when test="string-length($date) = 10">
        <xsl:text>date</xsl:text>
      </xsl:when>
      <xsl:when test="string-length($date) &gt; 10">
        <xsl:text>dateTime</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>date</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Constraints related to access and use -->
  <xsl:template name="ConstraintsRelatedToAccesAndUse" match="gmd:identificationInfo[1]/*/gmd:resourceConstraints">
    <xsl:param name="MetadataLanguage"/>

    <xsl:if test="gmd:MD_LegalConstraints/*/gmd:MD_RestrictionCode/@codeListValue = 'otherRestrictions'">
      <xsl:choose>
        <xsl:when test="starts-with(gmd:MD_LegalConstraints/gmd:otherConstraints/gmx:Anchor/@*[name() = ('xlink:href', 'gmx:Anchor')], 'http://inspire.ec.europa.eu/metadata-codelist/LimitationsOnPublicAccess')">
          <xsl:variable name="xlink" select="string(gmd:MD_LegalConstraints/gmd:otherConstraints/gmx:Anchor/@*[name() = ('xlink:href', 'gmx:Anchor')])"/>
          <xsl:variable name="accessRightId">
            <xsl:choose>
              <xsl:when test="ends-with($xlink, 'noLimitations')">
                <xsl:value-of select="'PUBLIC'"/>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          <xsl:if test="normalize-space($accessRightId) != ''">
            <dct:accessRights>
              <xsl:copy-of copy-namespaces="no" select="$allThesauri//skos:Concept[@rdf:about = concat('http://publications.europa.eu/resource/authority/access-right/', $accessRightId)]"/>
            </dct:accessRights>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <dct:license>
            <dct:LicenseDocument>
              <xsl:for-each select="gmd:MD_LegalConstraints/gmd:otherConstraints">
                <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/></dct:title>
                <xsl:call-template name="LocalisedString">
                  <xsl:with-param name="term">dct:title</xsl:with-param>
                  <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                </xsl:call-template>
              </xsl:for-each>
            </dct:LicenseDocument>
          </dct:license>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Keyword -->
  <xsl:template name="Keyword" match="gmd:identificationInfo/*/gmd:descriptiveKeywords/gmd:MD_Keywords">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="ResourceType"/>
    <xsl:param name="ServiceType"/>

    <xsl:variable name="originatingControlledVocabulary">
      <xsl:for-each select="gmd:thesaurusName/gmd:CI_Citation">
        <xsl:choose>
          <xsl:when test="gmd:title/gmx:Anchor/@xlink:href != '' or gmd:title/gmx:Anchor/@gmx:Anchor != ''">
            <xsl:choose>
              <xsl:when test="gmd:title/gmx:Anchor/@xlink:href != ''">
                <skos:inScheme rdf:resource="{gmd:title/gmx:Anchor/@xlink:href}"/>
              </xsl:when>
              <xsl:otherwise>
                <skos:inScheme rdf:resource="{gmd:title/gmx:Anchor/@gmx:Anchor}"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <skos:inScheme>
              <skos:ConceptScheme>
                <xsl:for-each select="gmd:title">
                  <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gmd:title/*[name() = ('gmx:Anchor', 'gco:CharacterString')])"/></dct:title>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">dct:title</xsl:with-param>
                    <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
                  </xsl:call-template>
                </xsl:for-each>
                <xsl:apply-templates select="gmd:date/gmd:CI_Date"/>
                <xsl:for-each select="gmd:identifier">
                  <dct:identifier><xsl:value-of select="gmd:MD_Identifier/gmd:code/*"/></dct:identifier>
                </xsl:for-each>
              </skos:ConceptScheme>
            </skos:inScheme>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:for-each select="gmd:keyword">
      <xsl:choose>
        <xsl:when test="count($originatingControlledVocabulary/skos:inScheme) > 0 and (gmx:Anchor/@gmx:Anchor != '' or gmx:Anchor/@xlink:href  != '')">
          <dcat:theme>
            <skos:Concept>
              <xsl:attribute name="rdf:about" select="if (gmx:Anchor/@gmx:Anchor != '') then gmx:Anchor/@gmx:Anchor else gmx:Anchor/@xlink:href"/>
              <skos:prefLabel xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gmx:Anchor)"/></skos:prefLabel>
              <xsl:call-template name="LocalisedString">
                <xsl:with-param name="term">skos:prefLabel</xsl:with-param>
                <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
              </xsl:call-template>
              <xsl:copy-of select="$originatingControlledVocabulary"/>
            </skos:Concept>
          </dcat:theme>
        </xsl:when>
        <xsl:otherwise>
          <dcat:keyword xml:lang="{$MetadataLanguage}"><xsl:value-of select="normalize-space(gmx:Anchor|gco:CharacterString)"/></dcat:keyword>
          <xsl:call-template name="LocalisedString">
            <xsl:with-param name="term">dcat:keyword</xsl:with-param>
            <xsl:with-param name="mdLang" select="$MetadataLanguage"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- Topic category -->
  <xsl:template name="TopicCategory" match="gmd:identificationInfo/*/gmd:topicCategory">
    <xsl:param name="TopicCategory"><xsl:value-of select="normalize-space(gmd:MD_TopicCategoryCode)"/></xsl:param>
    <xsl:if test="$TopicCategory != ''">
      <dct:subject>
        <xsl:copy-of select="$allThesauri//skos:Concept[@rdf:about = concat($TopicCategoryCodelistUri, '/', $TopicCategory)]"/>
      </dct:subject>
    </xsl:if>
  </xsl:template>

  <!-- Spatial resolution (unstable - to be replaced with a standard-based solution, when available) -->
  <xsl:template name="SpatialResolution" match="gmd:identificationInfo/*/gmd:spatialResolution/gmd:MD_Resolution">
    <xsl:variable name="spatialType" select="string(../../gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue)"/>
    <xsl:choose>
      <xsl:when test="$spatialType = 'grid'">
        <dcat:spatialResolutionInMeters>
          <dqv:QualityMeasurement>
            <sdmx-attribute:unitMeasure>
              <skos:Concept rdf:about="http://qudt.org/vocab/unit/M">
                <skos:prefLabel xml:lang="en">Meter</skos:prefLabel>
                <skos:prefLabel xml:lang="fr">Mètre</skos:prefLabel>
                <skos:prefLabel xml:lang="nl">Meter</skos:prefLabel>
                <skos:prefLabel xml:lang="de">Meter</skos:prefLabel>
                <skos:inScheme rdf:resource="http://qudt.org/vocab/unit"/>
              </skos:Concept>
            </sdmx-attribute:unitMeasure>
            <dqv:value>
              <xsl:value-of select="normalize-space(gmd:distance/gco:Distance)"/>
            </dqv:value>
          </dqv:QualityMeasurement>
        </dcat:spatialResolutionInMeters>
      </xsl:when>
      <xsl:when test="$spatialType = 'vector'">
        <dqv:hasQualityMeasurement>
          <dqv:QualityMeasurement>
            <geodcat:spatialResolutionAsScale>
              <xsl:value-of select="normalize-space(gmd:equivalentScale/gmd:MD_RepresentativeFraction/gmd:denominator/gco:Integer)"/>
            </geodcat:spatialResolutionAsScale>
          </dqv:QualityMeasurement>
        </dqv:hasQualityMeasurement>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Character encoding -->
  <xsl:template name="CharacterEncoding" match="gmd:characterSet/gmd:MD_CharacterSetCode">
    <xsl:variable name="CharSetCode">
      <xsl:choose>
        <xsl:when test="@codeListValue = 'ucs2'">
          <xsl:text>ISO-10646-UCS-2</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'ucs4'">
          <xsl:text>ISO-10646-UCS-4</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf7'">
          <xsl:text>UTF-7</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf8'">
          <xsl:text>UTF-8</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf16'">
          <xsl:text>UTF-16</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part1'">
          <xsl:text>ISO-8859-1</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part2'">
          <xsl:text>ISO-8859-2</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part3'">
          <xsl:text>ISO-8859-3</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part4'">
          <xsl:text>ISO-8859-4</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part5'">
          <xsl:text>ISO-8859-5</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part6'">
          <xsl:text>ISO-8859-6</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part7'">
          <xsl:text>ISO-8859-7</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part8'">
          <xsl:text>ISO-8859-8</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part9'">
          <xsl:text>ISO-8859-9</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part10'">
          <xsl:text>ISO-8859-10</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part11'">
          <xsl:text>ISO-8859-11</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part12'">
          <xsl:text>ISO-8859-12</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part13'">
          <xsl:text>ISO-8859-13</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part14'">
          <xsl:text>ISO-8859-14</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part15'">
          <xsl:text>ISO-8859-15</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part16'">
          <xsl:text>ISO-8859-16</xsl:text>
        </xsl:when>
        <!-- Mapping to be verified: multiple candidates are available in the IANA register for jis -->
        <xsl:when test="@codeListValue = 'jis'">
          <xsl:text>JIS_Encoding</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'shiftJIS'">
          <xsl:text>Shift_JIS</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'eucJP'">
          <xsl:text>EUC-JP</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'usAscii'">
          <xsl:text>US-ASCII</xsl:text>
        </xsl:when>
        <!-- Mapping to be verified: multiple candidates are available in the IANA register ebcdic  -->
        <xsl:when test="@codeListValue = 'ebcdic'">
          <xsl:text>IBM037</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'eucKR'">
          <xsl:text>EUC-KR</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'big5'">
          <xsl:text>Big5</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'GB2312'">
          <xsl:text>GB2312</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <cnt:characterEncoding rdf:datatype="{$xsd}string"><xsl:value-of select="$CharSetCode"/></cnt:characterEncoding>
  </xsl:template>

  <!-- Encoding -->
  <xsl:template name="Encoding" match="gmd:distributionFormat/gmd:MD_Format/gmd:name/*">
    <xsl:choose>
      <xsl:when test="@xlink:href and @xlink:href != ''">
        <dct:format rdf:resource="{@xlink:href}"/>
      </xsl:when>
      <xsl:otherwise>
        <dct:format rdf:parseType="Resource">
          <rdfs:label><xsl:value-of select="."/></rdfs:label>
        </dct:format>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Maintenance information -->
  <xsl:template name="MaintenanceInformation" match="gmd:MD_MaintenanceInformation/gmd:maintenanceAndUpdateFrequency/gmd:MD_MaintenanceFrequencyCode">
    <!-- The following parameter maps frequency codes used in ISO 19139 metadata to the corresponding ones of the Dublin Core Collection Description Frequency Vocabulary (when available). -->
    <xsl:param name="FrequencyCodeURI">
      <xsl:if test="@codeListValue != ''">
        <xsl:choose>
          <xsl:when test="@codeListValue = 'continual'">
            <xsl:value-of select="concat($opfq,'CONT')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'daily'">
            <xsl:value-of select="concat($opfq,'DAILY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'weekly'">
            <xsl:value-of select="concat($opfq,'WEEKLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'fortnightly'">
            <xsl:value-of select="concat($opfq,'BIWEEKLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'monthly'">
            <xsl:value-of select="concat($opfq,'MONTHLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'quarterly'">
            <xsl:value-of select="concat($opfq,'QUARTERLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'biannually'">
            <xsl:value-of select="concat($opfq,'ANNUAL_2')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'annually'">
            <xsl:value-of select="concat($opfq,'ANNUAL')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'asNeeded'">
            <!--  A mapping is missing in Dublin Core -->
            <!--  A mapping is missing in MDR Freq NAL -->
            <xsl:value-of select="concat($MaintenanceFrequencyCodelistUri,'/',@codeListValue)"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'irregular'">
            <xsl:value-of select="concat($opfq,'IRREG')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'notPlanned'">
            <!--  A mapping is missing in Dublin Core -->
            <!--  A mapping is missing in MDR Freq NAL -->
            <xsl:value-of select="concat($MaintenanceFrequencyCodelistUri,'/',@codeListValue)"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'unknown'">
            <!--  A mapping is missing in Dublin Core -->
            <xsl:value-of select="concat($opfq,'UNKNOWN')"/>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:param>
    <xsl:if test="$FrequencyCodeURI != ''">
      <dct:accrualPeriodicity>
        <xsl:copy-of select="$allThesauri//skos:Concept[@rdf:about = $FrequencyCodeURI]"/>
      </dct:accrualPeriodicity>
    </xsl:if>
  </xsl:template>

  <!-- Coordinate and temporal reference system (tentative) -->
  <xsl:template name="ReferenceSystem" match="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="code" select="gmd:code/*[self::gco:CharacterString|gmx:Anchor]"/>
    <xsl:param name="link" select="gmd:code/gmx:Anchor/@xlink:href"/>
    <xsl:param name="codespace" select="gmd:codeSpace/*[self::gco:CharacterString|gmx:Anchor]"/>
    <xsl:param name="version" select="gmd:version/*[self::gco:CharacterString|gmx:Anchor]"/>
    <xsl:param name="version-statement">
      <xsl:if test="$version != ''">
        <owl:versionInfo xml:lang="{$MetadataLanguage}"><xsl:value-of select="$version"/></owl:versionInfo>
      </xsl:if>
    </xsl:param>

    <xsl:choose>
      <xsl:when test="starts-with($link, 'http://') or starts-with($link, 'https://')">
        <dct:conformsTo>
          <dcat:Standard rdf:about="{$link}">
              <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
          </dcat:Standard>
        </dct:conformsTo>
      </xsl:when>
      <xsl:when test="starts-with($code, 'http://') or starts-with($code, 'https://')">
        <dct:conformsTo>
          <dcat:Standard  rdf:about="{$code}">
              <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
          </dcat:Standard>
        </dct:conformsTo>
      </xsl:when>
      <xsl:when test="starts-with($code, 'urn:')">
        <xsl:variable name="srid">
          <xsl:if test="starts-with(translate($code,$uppercase,$lowercase), translate($EpsgSrsBaseUrn,$uppercase,$lowercase))">
            <xsl:value-of select="substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($code,':'),':'),':'),':'),':'),':')"/>
          </xsl:if>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$srid != '' and string(number($srid)) != 'NaN'">
            <dct:conformsTo>
              <dcat:Standard rdf:about="{$EpsgSrsBaseUri}/{$srid}">
                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$code"/></dct:identifier>
                <skos:notation rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$code"/></skos:notation>
                <skos:inScheme>
                  <skos:ConceptScheme rdf:about="{$EpsgSrsBaseUri}">
                    <dct:title xml:lang="en"><xsl:value-of select="$EpsgSrsName"/></dct:title>
                  </skos:ConceptScheme>
                </skos:inScheme>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>
            </dct:conformsTo>
          </xsl:when>
          <xsl:otherwise>
            <dct:conformsTo rdf:parseType="Resource">
              <dcat:Standard>
                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$code"/></dct:identifier>
                <xsl:if test="$codespace != ''">
                  <skos:notation rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$code"/></skos:notation>
                  <skos:inScheme>
                    <skos:ConceptScheme>
                      <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="$codespace"/></dct:title>
                    </skos:ConceptScheme>
                  </skos:inScheme>
                </xsl:if>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>

            </dct:conformsTo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$code != '' and matches($code, '^\d+$') and (translate($codespace,$uppercase,$lowercase) = 'epsg' or starts-with(translate($codespace,$uppercase,$lowercase),translate($EpsgSrsBaseUrn,$uppercase,$lowercase)))">
            <dct:conformsTo>
              <dcat:Standard rdf:about="{$EpsgSrsBaseUri}/{$code}">
                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="concat($EpsgSrsBaseUrn,':',$version,':',$code)"/></dct:identifier>
                <skos:notation rdf:datatype="{$xsd}anyURI"><xsl:value-of select="concat($EpsgSrsBaseUrn,':',$version,':',$code)"/></skos:notation>
                <skos:inScheme>
                  <skos:ConceptScheme rdf:about="{$EpsgSrsBaseUri}">
                    <dct:title xml:lang="en"><xsl:value-of select="$EpsgSrsName"/></dct:title>
                  </skos:ConceptScheme>
                </skos:inScheme>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>
            </dct:conformsTo>
          </xsl:when>
          <xsl:when test="translate(normalize-space(translate($code,$uppercase,$lowercase)),': ','') = 'etrs89'">
            <dct:conformsTo>
              <dcat:Standard rdf:about="{$Etrs89Uri}">
                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$Etrs89Urn"/></dct:identifier>
                <skos:notation rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$Etrs89Urn"/></skos:notation>
                <dct:title xml:lang="en">ETRS89 - European Terrestrial Reference System 1989</dct:title>
                <skos:prefLabel xml:lang="en">ETRS89 - European Terrestrial Reference System 1989</skos:prefLabel>
                <skos:inScheme>
                  <skos:ConceptScheme rdf:about="{$EpsgSrsBaseUri}">
                    <dct:title xml:lang="en"><xsl:value-of select="$EpsgSrsName"/></dct:title>
                  </skos:ConceptScheme>
                </skos:inScheme>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>
            </dct:conformsTo>
          </xsl:when>
          <xsl:when test="translate(normalize-space(translate($code,$uppercase,$lowercase)),': ','') = 'crs84'">
            <dct:conformsTo>
              <dcat:Standard rdf:about="{$Crs84Uri}">
                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:identifier rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$Crs84Urn"/></dct:identifier>
                <skos:notation rdf:datatype="{$xsd}anyURI"><xsl:value-of select="$Crs84Urn"/></skos:notation>
                <dct:title xml:lang="en">CRS84</dct:title>
                <skos:prefLabel xml:lang="en">CRS84</skos:prefLabel>
                <skos:inScheme>
                  <skos:ConceptScheme rdf:about="{$OgcSrsBaseUri}">
                    <dct:title xml:lang="en"><xsl:value-of select="$OgcSrsName"/></dct:title>
                  </skos:ConceptScheme>
                </skos:inScheme>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>
            </dct:conformsTo>
          </xsl:when>
          <xsl:otherwise>
            <dct:conformsTo rdf:parseType="Resource">
              <dcat:Standard>

                <dct:type rdf:resource="{$INSPIREGlossaryUri}SpatialReferenceSystem"/>
                <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="$code"/></dct:title>
                <xsl:if test="$codespace != ''">
                  <skos:prefLabel xml:lang="{$MetadataLanguage}"><xsl:value-of select="$code"/></skos:prefLabel>
                  <skos:inScheme>
                    <skos:ConceptScheme>
                      <dct:title xml:lang="{$MetadataLanguage}"><xsl:value-of select="$codespace"/></dct:title>
                    </skos:ConceptScheme>
                  </skos:inScheme>
                </xsl:if>
                <xsl:copy-of select="$version-statement"/>
              </dcat:Standard>
            </dct:conformsTo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Spatial representation type (tentative) -->
  <xsl:template name="SpatialRepresentationType" match="gmd:identificationInfo/*/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode">
    <xsl:variable name="spatialRepresentationUri" select="concat($SpatialRepresentationTypeCodelistUri, '/', @codeListValue)"/>
    <xsl:variable name="spatialRepresentationConcept" select="$allThesauri//skos:Concept[@rdf:about = $spatialRepresentationUri]"/>
    <xsl:if test="normalize-space($spatialRepresentationConcept)">
      <adms:representationTechnique>
        <xsl:copy-of copy-namespaces="no" select="$spatialRepresentationConcept"/>
      </adms:representationTechnique>
    </xsl:if>
  </xsl:template>

  <!-- Source metadata -->
  <xsl:template name="AggregationInfo" match="gmd:identificationInfo/*/gmd:aggregationInfo/gmd:MD_AggregateInformation">
    <dct:source rdf:resource="{concat($OgcAPIUrl, '/collections/main/items/', normalize-space(../../../../gmd:fileIdentifier/gco:CharacterString))}" />
  </xsl:template>

  <!-- Multilingual text -->
  <xsl:template name="LocalisedString">
    <xsl:param name="term"/>
    <xsl:param name="mdLang" />
    <xsl:for-each select="gmd:PT_FreeText/*/gmd:LocalisedCharacterString">
      <xsl:variable name="value" select="normalize-space(.)"/>
      <xsl:variable name="langs">
        <xsl:call-template name="Alpha3-to-Alpha2">
          <xsl:with-param name="lang" select="translate(translate(@locale, $uppercase, $lowercase), '#', '')"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="$value != '' and $langs != $mdLang">
        <xsl:element name="{$term}">
          <xsl:attribute name="xml:lang" select="$langs"/>
          <xsl:value-of select="$value"/>
        </xsl:element>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="Alpha3-to-Alpha2">
    <xsl:param name="lang"/>
    <xsl:choose>
      <xsl:when test="$lang = 'bul'">
        <xsl:text>bg</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'cze'">
        <xsl:text>cs</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'dan'">
        <xsl:text>da</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'ger'">
        <xsl:text>de</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'gre'">
        <xsl:text>el</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'eng'">
        <xsl:text>en</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'spa'">
        <xsl:text>es</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'est'">
        <xsl:text>et</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'fin'">
        <xsl:text>fi</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'fre'">
        <xsl:text>fr</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'gle'">
        <xsl:text>ga</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'hrv'">
        <xsl:text>hr</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'ita'">
        <xsl:text>it</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'lav'">
        <xsl:text>lv</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'lit'">
        <xsl:text>lt</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'hun'">
        <xsl:text>hu</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'mlt'">
        <xsl:text>mt</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'dut'">
        <xsl:text>nl</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'pol'">
        <xsl:text>pl</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'por'">
        <xsl:text>pt</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'rum'">
        <xsl:text>ru</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'slo'">
        <xsl:text>sk</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'slv'">
        <xsl:text>sl</xsl:text>
      </xsl:when>
      <xsl:when test="$lang = 'swe'">
        <xsl:text>sv</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lang"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Templates for services and distributions pointing to services -->
  <xsl:template name="detect-service">
    <xsl:param name="function"/>
    <xsl:param name="protocol"/>
    <xsl:param name="url"/>
    <xsl:choose>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'request=getcapabilities')">
        <xsl:text>yes</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>no</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="service-protocol-code">
    <xsl:param name="function"/>
    <xsl:param name="protocol"/>
    <xsl:param name="url"/>
    <xsl:choose>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=csw')">
        <xsl:text>csw</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:csw'">
        <xsl:text>csw</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=sos')">
        <xsl:text>sos</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:sos'">
        <xsl:text>sos</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=sps')">
        <xsl:text>sps</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:sps'">
        <xsl:text>sps</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=wcs')">
        <xsl:text>wcs</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:wcs'">
        <xsl:text>wcs</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=wfs')">
        <xsl:text>wfs</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:wfs'">
        <xsl:text>wfs</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=wms')">
        <xsl:text>wms</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:wms'">
        <xsl:text>wms</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=wmts')">
        <xsl:text>wmts</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:wmts'">
        <xsl:text>wmts</xsl:text>
      </xsl:when>
      <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'service=wps')">
        <xsl:text>wps</xsl:text>
      </xsl:when>
      <xsl:when test="translate($protocol, $uppercase, $lowercase) = 'ogc:wps'">
        <xsl:text>wps</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="service-protocol-url">
    <xsl:param name="protocol"/>
    <xsl:choose>
      <xsl:when test="$protocol = 'csw'">
        <xsl:text>http://www.opengeospatial.org/standards/cat</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'sos'">
        <xsl:text>http://www.opengeospatial.org/standards/sos</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'sps'">
        <xsl:text>http://www.opengeospatial.org/standards/sps</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'wcs'">
        <xsl:text>http://www.opengeospatial.org/standards/wcs</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'wfs'">
        <xsl:text>http://www.opengeospatial.org/standards/wfs</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'wms'">
        <xsl:text>http://www.opengeospatial.org/standards/wms</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'wmts'">
        <xsl:text>http://www.opengeospatial.org/standards/wmts</xsl:text>
      </xsl:when>
      <xsl:when test="$protocol = 'wps'">
        <xsl:text>http://www.opengeospatial.org/standards/wps</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="service-protocol">
    <xsl:param name="function"/>
    <xsl:param name="protocol"/>
    <xsl:param name="url"/>
    <xsl:param name="protocol-url">
      <xsl:call-template name="service-protocol-url">
        <xsl:with-param name="protocol">
          <xsl:call-template name="service-protocol-code">
            <xsl:with-param name="function" select="$function"/>
            <xsl:with-param name="protocol" select="$protocol"/>
            <xsl:with-param name="url" select="$url"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:param>
    <xsl:if test="$protocol-url != ''">
      <dct:conformsTo rdf:resource="{$protocol-url}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="service-endpoint">
    <xsl:param name="function"/>
    <xsl:param name="protocol"/>
    <xsl:param name="url"/>
    <xsl:param name="endpoint-url">
      <xsl:choose>
        <xsl:when test="contains($url, '?')">
          <xsl:value-of select="substring-before($url, '?')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$url"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name="endpoint-description">
      <xsl:choose>
        <xsl:when test="contains(substring-after(translate($url, $uppercase, $lowercase), '?'), 'request=getcapabilities')">
          <xsl:value-of select="$url"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$url"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name="service-type">
    </xsl:param>
    <xsl:if test="$endpoint-url != ''">
      <dcat:endpointURL rdf:resource="{$endpoint-url}"/>
    </xsl:if>
    <xsl:if test="$endpoint-description != ''">
      <dcat:endpointDescription rdf:resource="{$endpoint-description}"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>