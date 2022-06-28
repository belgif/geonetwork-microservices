/**
 * (c) 2020 Open Source Geospatial Foundation - all rights reserved
 * This code is licensed under the GPL 2.0 license,
 * available at the root application directory.
 */

package org.fao.geonet.common.xml;


import java.io.*;
import java.net.URL;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.util.JAXBResult;
import javax.xml.stream.XMLStreamWriter;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.s9api.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component
public class XsltUtil {

  /**
   * Transform XML string to Object.
   */
  public static <T> T transformXmlToObject(
      String inputXmlString,
      File xsltFile,
      Class<T> objectClass
  ) {
    TransformerFactory factory = new net.sf.saxon.TransformerFactoryImpl();
    StreamSource xslt = new StreamSource(xsltFile);
    StreamSource text = new StreamSource(new StringReader(inputXmlString));
    try {
      JAXBContext jaxbContext = JAXBContext.newInstance(objectClass);
      JAXBResult result = new JAXBResult(jaxbContext);

      Transformer transformer = factory.newTransformer(xslt);
      transformer.transform(text, result);
      Object o = result.getResult();
      if (objectClass.isInstance(o)) {
        return (T) o;
      } else {
        return null;
      }
    } catch (TransformerConfigurationException e) {
      e.printStackTrace();
    } catch (TransformerException e2) {
      e2.printStackTrace();
    } catch (JAXBException e) {
      e.printStackTrace();
    }
    return null;
  }


  /**
   * Transform XML string and write result to XMLStreamWriter.
   */
  public static void transformAndStreamInDocument(
      String inputXmlString,
      InputStream xsltFile,
      XMLStreamWriter streamWriter) {
    try {
      Processor proc = new Processor(false);
      XsltCompiler compiler = proc.newXsltCompiler();

      XsltExecutable xsl = compiler.compile(new StreamSource(xsltFile));
      Xslt30Transformer transformer = xsl.load30();
      transformer.transform(
          new StreamSource(new StringReader(inputXmlString)),
          new XmlStreamWriterDestinationInDocument(streamWriter));
    } catch (SaxonApiException e) {
      e.printStackTrace();
    }
  }

  /**
   * Transform XML string and write result as a string
   */
  public static String transformToString(String inputXmlString, ClassPathResource xsltFile, Map<QName, XdmValue> parameters) throws Exception {
    Processor proc = new Processor(false);
    StringWriter stringWriter = new StringWriter();
    Serializer out = proc.newSerializer(stringWriter);
    out.setOutputProperty(Serializer.Property.METHOD, "xml");
    out.setOutputProperty(Serializer.Property.INDENT, "yes");
    out.setOutputProperty(Serializer.Property.VERSION, "1.0");
    out.setOutputProperty(Serializer.Property.ENCODING, "UTF-8");
    var resolver = new URIResolver() {
      @Override
      public Source resolve(String href, String base) {
        try {
          if (href.startsWith("http://") || href.startsWith("https://")) {
            return new StreamSource(new URL(href).openStream());
          } else {
            String path = Paths.get(xsltFile.getPath()).getParent().resolve(href).toString();
            return new StreamSource(new ClassPathResource(path).getInputStream());
          }
        } catch (IOException e) {
          throw new RuntimeException(e);
        }
      }
    };

    XsltCompiler compiler = proc.newXsltCompiler();
    compiler.setURIResolver(resolver);
    XsltExecutable xsl = compiler.compile(new StreamSource(xsltFile.getInputStream()));
    Xslt30Transformer transformer = xsl.load30();
    transformer.setURIResolver(resolver);
    if (parameters != null) {
      transformer.setStylesheetParameters(parameters);
    }
    transformer.transform(new StreamSource(new StringReader(inputXmlString)), out);
    return stringWriter.getBuffer().toString();

  }
  public static String transformToString(String inputXmlString, ClassPathResource xsltFile) throws Exception {
    return transformToString(inputXmlString, xsltFile, null);
  }

  public static XdmValue stringToParam(String str) {
    return new XdmValue(List.of(new XdmAtomicValue(str)));
  }
}
