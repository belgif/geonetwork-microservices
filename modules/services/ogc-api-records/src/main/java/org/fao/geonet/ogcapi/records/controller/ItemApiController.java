/**
 * (c) 2020 Open Source Geospatial Foundation - all rights reserved This code is licensed under the
 * GPL 2.0 license, available at the root application directory.
 */

package org.fao.geonet.ogcapi.records.controller;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiParam;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.io.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Marshaller;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.ListUtils;
import org.apache.commons.lang.StringUtils;
import org.eclipse.rdf4j.rio.RDFFormat;
import org.eclipse.rdf4j.rio.Rio;
import org.fao.geonet.common.search.ElasticSearchProxy;
import org.fao.geonet.common.search.GnMediaType;
import org.fao.geonet.common.search.SearchConfiguration;
import org.fao.geonet.common.search.SearchConfiguration.Format;
import org.fao.geonet.common.search.SearchConfiguration.Operations;
import org.fao.geonet.common.search.domain.es.EsSearchResults;
import org.fao.geonet.common.xml.XsltUtil;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.domain.Source;
import org.fao.geonet.index.JsonUtils;
import org.fao.geonet.index.converter.DcatConverter;
import org.fao.geonet.index.converter.SchemaOrgConverter;
import org.fao.geonet.index.model.dcat2.CatalogRecord;
import org.fao.geonet.index.model.dcat2.DataService;
import org.fao.geonet.index.model.dcat2.Dataset;
import org.fao.geonet.index.model.gn.IndexRecord;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames;
import org.fao.geonet.ogcapi.records.model.Item;
import org.fao.geonet.ogcapi.records.model.XsltModel;
import org.fao.geonet.ogcapi.records.service.CollectionService;
import org.fao.geonet.ogcapi.records.util.MediaTypeUtil;
import org.fao.geonet.ogcapi.records.util.RecordsEsQueryBuilder;
import org.fao.geonet.ogcapi.records.util.XmlUtil;
import org.fao.geonet.repository.MetadataRepository;
import org.fao.geonet.view.ViewUtility;
import org.jdom.Element;
import org.jdom.Namespace;
import org.jdom.output.XMLOutputter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.View;
import org.springframework.web.servlet.ViewResolver;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import springfox.documentation.annotations.ApiIgnore;


@Api(tags = "OGC API Records")
@Controller
@Slf4j(topic = "org.fao.geonet.ogcapi.records")
public class ItemApiController {

  @Autowired
  ElasticSearchProxy proxy;
  @Autowired
  MetadataRepository metadataRepository;
  @Autowired
  ViewUtility viewUtility;
  @Autowired
  @Qualifier("xsltViewResolver")
  ViewResolver viewResolver;
  @Autowired
  CollectionService collectionService;
  @Autowired
  MessageSource messages;
  @Autowired
  RecordsEsQueryBuilder recordsEsQueryBuilder;
  @Autowired
  SearchConfiguration searchConfiguration;
  @Autowired
  MediaTypeUtil mediaTypeUtil;
  @Autowired
  DcatConverter dcatConverter;

  /**
   * Describe a collection item.
   *
   */
  @io.swagger.v3.oas.annotations.Operation(
      summary = "Describe a collection item.",
      description = "Collection Information is the set of metadata that describes a "
          + "single collection. An abbreviated copy of this information is returned for each "
          + "Collection in the /collections response.")
  @GetMapping(value = "/collections/{collectionId}/items/{recordId}",
      produces = {MediaType.APPLICATION_JSON_VALUE,
          MediaType.TEXT_HTML_VALUE,
          MediaType.APPLICATION_RSS_XML_VALUE,
          MediaType.APPLICATION_ATOM_XML_VALUE,
          MediaType.APPLICATION_XML_VALUE,
          GnMediaType.APPLICATION_JSON_LD_VALUE,
          GnMediaType.APPLICATION_RDF_XML_VALUE,
          GnMediaType.APPLICATION_DCAT2_XML_VALUE,
          GnMediaType.TEXT_TURTLE_VALUE})
  @ResponseStatus(HttpStatus.OK)
  @ApiResponses(value = {
      @ApiResponse(responseCode = "200", description = "Describe a collection item.")
  })
  public ResponseEntity<Void> collectionsCollectionIdItemsRecordIdGet(
      @ApiParam(value = "Identifier (name) of a specific collection", required = true)
      @PathVariable("collectionId") String collectionId,
      @ApiParam(value = "Identifier (name) of a specific record", required = true)
      @PathVariable("recordId")String recordId,
      @ApiIgnore HttpServletRequest request,
      @ApiIgnore HttpServletResponse response,
      @ApiIgnore Model model) {

    Source source = collectionService.retrieveSourceForCollection(collectionId);

    if (source == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND,
          messages.getMessage("ogcapir.exception.collection.notFound",
              new String[]{collectionId},
              request.getLocale()));
    }

    List<MediaType> allowedMediaTypes =
        ListUtils.union(MediaTypeUtil.defaultSupportedMediaTypes,
            MediaTypeUtil.ldSupportedMediaTypes);

    MediaType mediaType =
        mediaTypeUtil.calculatePriorityMediaTypeFromRequest(request, allowedMediaTypes);


    if (mediaType.equals(MediaType.APPLICATION_JSON)) {
      try {
        JsonNode record = getRecordAsJson(collectionId, recordId, request, source, "json");

        streamResult(response,
            record.toPrettyString(),
            MediaType.APPLICATION_JSON_VALUE);
        return ResponseEntity.ok().build();
      } catch (Exception ex) {
        // TODO: Log exception
        throw new RuntimeException(ex);
      }

    } else if (MediaTypeUtil.ldSupportedMediaTypes.contains(mediaType)) {
      return collectionsCollectionIdItemsRecordIdGetAsJsonLd(collectionId, recordId,
          mediaType.toString(), request, response);

    } else if (MediaTypeUtil.xmlMediaTypes.contains(mediaType)) {
      return collectionsCollectionIdItemsRecordIdGetAsXml(collectionId, recordId,
          request, response);

    } else {
      return collectionsCollectionIdItemsRecordIdGetAsHtml(collectionId, recordId,
          request, response, model);
    }
  }


  /**
   * Describe the collection items.
   *
   */
  @io.swagger.v3.oas.annotations.Operation(
      summary = "Describe the collection items.",
      description = "Collection Information is the set of metadata that describes a "
          + "single collection. An abbreviated copy of this information is returned for each "
          + "Collection in the /collections response.")
  @GetMapping(value = "/collections/{collectionId}/items",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE,
          GnMediaType.APPLICATION_JSON_LD_VALUE,
          MediaType.APPLICATION_RSS_XML_VALUE,
          MediaType.TEXT_HTML_VALUE,
          GnMediaType.APPLICATION_RDF_XML_VALUE,
          GnMediaType.APPLICATION_DCAT2_XML_VALUE,
          GnMediaType.TEXT_TURTLE_VALUE
      })
  @ResponseStatus(HttpStatus.OK)
  @ApiResponses(value = {
      @ApiResponse(responseCode = "200", description = "Describe a collection item.")
  })
  public ResponseEntity<Void> collectionsCollectionIdItemsGet(
      @ApiParam(value = "Identifier (name) of a specific collection", required = true)
      @PathVariable("collectionId")
          String collectionId,
      @ApiParam(value = "")
      @RequestParam(value = "bbox", required = false)
          List<BigDecimal> bbox,
      @ApiParam(value = "")
      @RequestParam(value = "datetime", required = false)
          String datetime,
      @ApiParam(value = "", defaultValue = "10")
      @RequestParam(value = "limit", required = false, defaultValue = "10")
          Integer limit,
      @ApiParam(value = "", defaultValue = "0")
      @RequestParam(value = "startindex", required = false, defaultValue = "0")
          Integer startindex,
      @ApiParam(value = "")
      @RequestParam(value = "type", required = false)
          String type,
      @ApiParam(value = "")
      @RequestParam(value = "q", required = false)
          List<String> q,
      @ApiParam(value = "")
      @RequestParam(value = "externalids", required = false)
          List<String> externalids,
      @ApiParam(value = "")
      @RequestParam(value = "sortby", required = false)
          List<String> sortby,
      @ApiIgnore HttpServletRequest request,
      @ApiIgnore HttpServletResponse response,
      @ApiIgnore Model model) throws Exception {

    if (startindex < 0 || limit <= 0) {
      throw new HttpClientErrorException(HttpStatus.BAD_REQUEST, "Limit must be superior to 0 and startindex must be equal or greater then 0");
    }

    List<MediaType> allowedMediaTypes = ListUtils.union(
        MediaTypeUtil.defaultSupportedMediaTypes,
        Arrays.asList(
            GnMediaType.APPLICATION_JSON_LD,
            MediaType.APPLICATION_RSS_XML,
            GnMediaType.APPLICATION_RDF_XML,
            GnMediaType.APPLICATION_DCAT2_XML,
            GnMediaType.TEXT_TURTLE
        )
    );
    MediaType mediaType = mediaTypeUtil.calculatePriorityMediaTypeFromRequest(request, allowedMediaTypes);

    if (mediaType.equals(MediaType.APPLICATION_XML)
        || mediaType.equals(MediaType.APPLICATION_JSON)
        || mediaType.equals(GnMediaType.APPLICATION_JSON_LD)
        || mediaType.equals(MediaType.APPLICATION_RSS_XML)
        || mediaType.equals(GnMediaType.APPLICATION_RDF_XML)
        || mediaType.equals(GnMediaType.APPLICATION_DCAT2_XML)
        || mediaType.equals(GnMediaType.TEXT_TURTLE)) {

      return collectionsCollectionIdItemsGetInternal(
          collectionId, bbox, datetime, limit, startindex, type, q, externalids, sortby,
          request, response);

    } else {
      return collectionsCollectionIdItemsGetAsHtml(collectionId, bbox, datetime, limit,
          startindex, type, q, externalids, sortby, request, response, model);
    }
  }


  private ResponseEntity<Void> collectionsCollectionIdItemsRecordIdGetAsJsonLd(
      String collectionId,
      String recordId,
      String acceptHeader,
      HttpServletRequest request,
      HttpServletResponse response) {

    Source source = collectionService.retrieveSourceForCollection(collectionId);

    try {
      String formatParameter = request.getParameter("f");
      boolean isTurtle = "dcat_turtle".equals(formatParameter) ||
          GnMediaType.TEXT_TURTLE_VALUE.equals(acceptHeader);
      boolean isDcat = "dcat".equals(formatParameter) ||
          GnMediaType.TEXT_TURTLE_VALUE.equals(acceptHeader);
      boolean isRdfXml = "rdfxml".equals(formatParameter) ||
          GnMediaType.APPLICATION_RDF_XML_VALUE.equals(acceptHeader);
      boolean isLinkedData = (isTurtle || isRdfXml || isDcat);

      JsonNode record = getRecordAsJson(collectionId, recordId, request, source,
          isLinkedData ? "json" : "schema.org");

      if (isLinkedData) {
        IndexRecord indexRecord = new ObjectMapper()
            .enable(DeserializationFeature.ACCEPT_SINGLE_VALUE_AS_ARRAY)
            .readValue(record.get(IndexRecordFieldNames.source).toString(), IndexRecord.class);

        String xsltFileName = String.format("xslt/ogcapir/formats/dcat/dcat-%s.xsl", indexRecord.getDocumentStandard());
        ClassPathResource xsltFile = new ClassPathResource(xsltFileName);

        String dcatXml;
        if (xsltFile.exists()) {
          Node metadataXml = getRecordAsXml(collectionId, recordId, request, source);
          dcatXml = XsltUtil.transformToString(XmlUtil.getNodeString(metadataXml), xsltFile);
        } else {
          JAXBContext context = null;
          context = JAXBContext.newInstance(
              CatalogRecord.class, Dataset.class, DataService.class);
          Marshaller marshaller = context.createMarshaller();
          marshaller.setProperty(Marshaller.JAXB_FRAGMENT, Boolean.TRUE);
          marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);

          CatalogRecord catalogRecord = dcatConverter.convert(indexRecord);
          StringWriter sw = new StringWriter();
          marshaller.marshal(catalogRecord, sw);
          dcatXml = sw.toString();
        }

        if (isTurtle) {
          org.eclipse.rdf4j.model.Model model = Rio.parse(
              new ByteArrayInputStream(dcatXml.getBytes()),
              "",
              RDFFormat.RDFXML
          );
          StringWriter turtleWriter = new StringWriter();
          Rio.write(model, turtleWriter, RDFFormat.TURTLE);
          streamResult(response, turtleWriter.toString(), GnMediaType.TEXT_TURTLE_VALUE);
        } else {
          streamResult(response, dcatXml, MediaType.APPLICATION_XML_VALUE);
        }
      } else {
        streamResult(response,  record.toString(), GnMediaType.APPLICATION_JSON_LD_VALUE);
      }
      return ResponseEntity.ok().build();
    } catch (Exception ex) {
      // TODO: Log exception
      throw new RuntimeException(ex);
    }

  }


  private ResponseEntity<Void> collectionsCollectionIdItemsRecordIdGetAsXml(
      String collectionId,
      String recordId,
      HttpServletRequest request,
      HttpServletResponse response) {

    Source source = collectionService.retrieveSourceForCollection(collectionId);

    if (source == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND,
          messages.getMessage("ogcapir.exception.collection.notFound",
              new String[]{collectionId},
              request.getLocale()));
    }

    try {
      Node metadataResult = getRecordAsXml(collectionId, recordId, request, source);

      streamResult(response, XmlUtil.getNodeString(metadataResult),
          MediaType.APPLICATION_XML_VALUE);

      return ResponseEntity.ok().build();
    } catch (Exception ex) {
      // TODO: Log exception
      throw new RuntimeException(ex);
    }
  }


  private ResponseEntity<Void> collectionsCollectionIdItemsRecordIdGetAsHtml(
      String collectionId,
      String recordId,
      HttpServletRequest request,
      HttpServletResponse response,
      Model model) {
    Locale locale = LocaleContextHolder.getLocale();
    String language = locale.getISO3Language();
    Source source = collectionService.retrieveSourceForCollection(collectionId);

    if (source == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unable to find collection");
    }

    try {
      JsonNode recordAsJson = getRecordAsJson(collectionId, recordId, request, source, "json");

      Metadata record = metadataRepository.findOneByUuid(recordId);
      if (record == null) {
        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
            messages.getMessage("ogcapir.exception.collectionItem.notFound",
                new String[]{recordId, collectionId},
                request.getLocale()));
      }

      XsltModel modelSource = new XsltModel();
      try {
        IndexRecord recordPojo = JsonUtils.getObjectMapper().readValue(
            recordAsJson.get(IndexRecordFieldNames.source).toPrettyString(),
            IndexRecord.class);
        modelSource.setSeoJsonLdSnippet(
            SchemaOrgConverter.convert(recordPojo).toString());
      } catch (Exception e) {
        log.error(String.format(
            "An error occurred while building JSON-LD representation of record '%s'. Error is: %s",
            recordId, e.getMessage()));
      }
      modelSource.setRequestParameters(request.getParameterMap());
      modelSource.setOutputFormats(searchConfiguration.getFormats(Operations.item));
      modelSource.setCollection(source);
      modelSource.setItems(List.of(
          new Item(recordId, null, record.getData())
      ));

      model.addAttribute("source", modelSource.toSource());
      viewUtility.addi18n(model, locale, List.of(record.getDataInfo().getSchemaId()), request);

      View view = viewResolver.resolveViewName("ogcapir/item", locale);
      view.render(model.asMap(), request, response);

      return ResponseEntity.ok().build();
    } catch (Exception ex) {
      // TODO: Log exception
      throw new RuntimeException(ex);
    }
  }


  private JsonNode getRecordAsJson(
      String collectionId,
      String recordId,
      HttpServletRequest request,
      Source source,
      String type) throws Exception {
    String collectionFilter = collectionService.retrieveCollectionFilter(source);
    String query = recordsEsQueryBuilder.buildQuerySingleRecord(recordId, collectionFilter, null);

    String queryResponse = proxy.searchAndGetResult(request.getSession(), request, query, null);

    ObjectMapper mapper = new ObjectMapper();
    JsonFactory factory = mapper.getFactory();
    JsonParser parser = factory.createParser(queryResponse);
    JsonNode actualObj = mapper.readTree(parser);

    JsonNode totalValue =
        "json".equals(type)
            ? actualObj.get("hits").get("total").get("value")
            : actualObj.get("size");

    if ((totalValue == null) || (totalValue.intValue() == 0)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND,
          messages.getMessage("ogcapir.exception.collectionItem.notFound",
              new String[]{recordId, collectionId},
              request.getLocale()));
    }

    return "json".equals(type)
        ? actualObj.get("hits").get("hits").get(0)
        : actualObj.get("dataFeedElement").get(0);
  }

  private Node getRecordAsXml(String collectionId, String recordId, HttpServletRequest request, Source source) throws Exception {
    String collectionFilter = collectionService.retrieveCollectionFilter(source);
    String query = recordsEsQueryBuilder.buildQuerySingleRecord(recordId, collectionFilter, null);
    String queryResponse = proxy.searchAndGetResult(request.getSession(), getXmlRequestWrapper(request), query, null);

    Document queryResult = XmlUtil.parseXmlString(queryResponse);
    String total = queryResult.getChildNodes().item(0).getAttributes().getNamedItem("total")
        .getNodeValue();

    if (Integer.parseInt(total) == 0) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND,
          messages.getMessage("ogcapir.exception.collectionItem.notFound",
              new String[]{recordId, collectionId},
              request.getLocale()));
    }

    return queryResult.getChildNodes().item(0).getFirstChild();
  }


  private List<String> setDefaultRssSortBy(List<String> sortby, HttpServletRequest request) {
    boolean isRss = "rss".equals(request.getParameter("f"))
        || (request.getHeader("Accept") != null
            && request.getHeader("Accept").contains(MediaType.APPLICATION_RSS_XML_VALUE));
    if (isRss
        && (sortby == null || sortby.size() == 0)) {
      sortby = new ArrayList<>();
      sortby.add("-" + IndexRecordFieldNames.dateStamp);
    }
    return sortby;
  }


  private String search(
      String collectionId,
      List<BigDecimal> bbox,
      String datetime,
      Integer limit,
      Integer startindex,
      String type,
      List<String> q,
      List<String> externalids,
      List<String> sortby,
      HttpServletRequest request) {

    Source source = collectionService.retrieveSourceForCollection(collectionId);

    if (source == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unable to find collection");
    }

    String collectionFilter = collectionService.retrieveCollectionFilter(source);
    String query = recordsEsQueryBuilder
        .buildQuery(q, externalids, bbox, startindex, limit, collectionFilter, sortby);
    try {
      return proxy.searchAndGetResult(request.getSession(), request, query, null);
    } catch (Exception ex) {
      // TODO: Log exception
      throw new RuntimeException(ex);
    }
  }


  private ResponseEntity<Void> collectionsCollectionIdItemsGetInternal(
      String collectionId,
      List<BigDecimal> bbox,
      String datetime,
      Integer limit,
      Integer startindex,
      String type,
      List<String> q,
      List<String> externalids,
      List<String> sortby,
      HttpServletRequest request,
      HttpServletResponse response) {

    sortby = setDefaultRssSortBy(sortby, request);

    var linkedDataHeaders = Arrays.asList(
        GnMediaType.APPLICATION_RDF_XML_VALUE,
        GnMediaType.APPLICATION_DCAT2_XML_VALUE,
        GnMediaType.TEXT_TURTLE_VALUE
    );
    var isLinkedData = linkedDataHeaders.contains(getResponseContentType(request));
    var isTurtle = GnMediaType.TEXT_TURTLE_VALUE.equals(getResponseContentType(request));

    HttpServletRequestWrapper requestWrapper = null;

    if (isLinkedData) {
      requestWrapper = getXmlRequestWrapper(request);
    }

    String queryResponse = search(collectionId, bbox, datetime, limit, startindex, type, q,
        externalids, sortby, isLinkedData ? requestWrapper: request);

    if (isLinkedData) {
      ClassPathResource xsltFile = new ClassPathResource("xslt/ogcapir/formats/dcat/dcat-iso19139.xsl");
      try {
        var dcatXml = XsltUtil.transformToString(queryResponse, xsltFile);

        dcatXml = addPaging(request, queryResponse, limit, startindex, dcatXml);

        if (isTurtle) {
          org.eclipse.rdf4j.model.Model model = Rio.parse(new ByteArrayInputStream(dcatXml.getBytes()), "", RDFFormat.RDFXML);
          StringWriter turtleWriter = new StringWriter();
          Rio.write(model, turtleWriter, RDFFormat.TURTLE);
          dcatXml = turtleWriter.toString();
        }

        queryResponse = dcatXml;

      } catch (Exception e) {
        throw new RuntimeException(e);
      }
    }

    try {
      streamResult(response, queryResponse, getResponseContentType(request));
    } catch (IOException ioException) {
      throw new RuntimeException(ioException);
    }

    return ResponseEntity.ok().build();
  }

  private String addPaging(HttpServletRequest request, String queryResponse, Integer limit, Integer startindex, String dcatXml) {
    var hydraNS = Namespace.getNamespace("hydra", "http://www.w3.org/ns/hydra/core#");
    var rdfNS = Namespace.getNamespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
    var total = queryResponse.substring(queryResponse.indexOf("total=\"") + 7);
    total = total.substring(0, total.indexOf("\""));
    var totalInt = Integer.parseInt(total);
    var parameters = request.getParameterMap();
    StringBuilder baseUrlBuilder = new StringBuilder(request.getRequestURL().toString() + "?");
    for (var param: parameters.entrySet()) {
      if (!"limit".equalsIgnoreCase(param.getKey()) && !"startindex".equalsIgnoreCase(param.getKey())) {
        baseUrlBuilder.append(param.getKey())
            .append("=")
            .append(String.join(",", param.getValue()))
            .append("&");
      }
    }
    String baseUrl = baseUrlBuilder.toString();

    var paging = new Element("PagedCollection", hydraNS);
    paging.setAttribute("about", baseUrl + "startindex=" + startindex + "&limit=" + limit, rdfNS);

    var type = new Element("type", rdfNS);
    type.setAttribute("resource", "hydra:PartialCollectionView", rdfNS);
    paging.addContent(type);

    var totalItems = new Element("totalItems", hydraNS);
    totalItems.setAttribute("datatype", "http://www.w3.org/2001/XMLSchema#integer", rdfNS);
    paging.addContent(totalItems);
    totalItems.addContent(total);

    var itemsPerPage = new Element("itemsPerPage", hydraNS);
    itemsPerPage.setAttribute("datatype", "http://www.w3.org/2001/XMLSchema#integer", rdfNS);
    paging.addContent(itemsPerPage);
    itemsPerPage.addContent(limit.toString());

    var firstPage = new Element("firstPage", hydraNS);
    firstPage.addContent(baseUrl + "startindex=0&limit=" + limit);
    paging.addContent(firstPage);

    var lastPage = new Element("lastPage", hydraNS);
    lastPage.addContent(baseUrl + "startindex=" + (totalInt - (totalInt % limit)) + "&limit=" + limit);
    paging.addContent(lastPage);

    if (totalInt > (startindex + limit)) {
      var nextPage = new Element("nextPage", hydraNS);
      nextPage.addContent(baseUrl + "startindex=" + (startindex + limit) + "&limit=" + limit);
      paging.addContent(nextPage);
    }

    if (startindex > 0) {
      var previousPage = new Element("previousPage", hydraNS);
      previousPage.addContent(baseUrl + "startindex=" + Math.max((startindex - limit), 0) + "&limit=" + limit);
      paging.addContent(previousPage);
    }

    var insertAtIndex = dcatXml.indexOf("<dcat:Catalog");
    var pagingStr = this.getXmlString(paging).replaceAll(" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"", "");
    dcatXml = dcatXml.substring(0, insertAtIndex)
        + pagingStr
        + "\n   "
        + dcatXml.substring(insertAtIndex);
    return dcatXml;
  }


  /**
   * Collection items as HTML.
   */
  private ResponseEntity<Void> collectionsCollectionIdItemsGetAsHtml(
      String collectionId,
      List<BigDecimal> bbox,
      String datetime,
      Integer limit,
      Integer startindex,
      String type,
      List<String> q,
      List<String> externalids,
      List<String> sortby,
      HttpServletRequest request,
      HttpServletResponse response,
      Model model) throws Exception {

    Locale locale = LocaleContextHolder.getLocale();
    String language = locale.getISO3Language();
    Source source = collectionService.retrieveSourceForCollection(collectionId);

    if (source == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unable to find collection");
    }

    String collectionFilter = collectionService.retrieveCollectionFilter(source);
    String query = recordsEsQueryBuilder
        .buildQuery(q, externalids, bbox, startindex, limit, collectionFilter, sortby);
    EsSearchResults results = new EsSearchResults();
    try {
      results = proxy
          .searchAndGetResultAsObject(request.getSession(), request, query, null);
    } catch (Exception ex) {
      // TODO: Log exception
      throw new RuntimeException(ex);
    }

    XsltModel modelSource = new XsltModel();
    Map<String, String[]> parameterMap = new HashMap<>(request.getParameterMap());
    if (request.getParameter("limit") == null) {
      parameterMap.put("limit", new String[]{limit + ""});
    }
    if (request.getParameter("startindex") == null) {
      parameterMap.put("startindex", new String[]{startindex + ""});
    }
    modelSource.setRequestParameters(parameterMap);
    modelSource.setCollection(source);
    modelSource.setResults(results);
    modelSource.setOutputFormats(searchConfiguration.getFormats(Operations.items));
    model.addAttribute("source", modelSource.toSource());
    viewUtility.addi18n(model, locale, request);

    View view = viewResolver.resolveViewName("ogcapir/collection", locale);
    view.render(model.asMap(), request, response);

    return ResponseEntity.ok().build();
  }


  /**
   * Streams the content body in the response stream using the content-type provided.
   */
  private void streamResult(
      HttpServletResponse response,
      String content,
      String contentType) throws IOException {
    PrintWriter out = response.getWriter();
    try {
      response.setContentType(contentType);
      response.setCharacterEncoding("UTF-8");
      out.print(content);
    } finally {
      out.flush();
    }
  }


  /**
   * Calculates the response content type.
   */
  private String getResponseContentType(HttpServletRequest request) {
    String mediaType = "";
    String formatParam = request.getParameter("f");

    if (StringUtils.isNotEmpty(formatParam)) {
      Optional<Format> format = searchConfiguration.getFormats()
          .stream().filter(f -> f.getName().equals(formatParam)).findFirst();

      if (format.isPresent()) {
        mediaType = format.get().getMimeType();
      }
    } else {
      mediaType = request.getHeader("Accept");
    }

    if (StringUtils.isEmpty(mediaType)) {
      mediaType = MediaType.APPLICATION_JSON_VALUE;
    }

    return mediaType;
  }

  private HttpServletRequestWrapper getXmlRequestWrapper(HttpServletRequest request) {
    return new HttpServletRequestWrapper(request) {
      @Override
      public String getHeader(String name) {
        if ("accept".equalsIgnoreCase(name)) {
          return MediaType.APPLICATION_XML_VALUE;
        } else {
          return ((HttpServletRequest) getRequest()).getHeader(name);
        }
      }

      @Override
      public String getParameter(String name) {
        if ("f".equalsIgnoreCase(name)) {
          return getRequest().getParameter(name) != null ? "xml" : null;
        } else {
          return getRequest().getParameter(name);
        }
      }
    };
  }

  public String getXmlString(Element data) {
    XMLOutputter outputter = new XMLOutputter(org.jdom.output.Format.getPrettyFormat());
    return outputter.outputString(data);
  }
}