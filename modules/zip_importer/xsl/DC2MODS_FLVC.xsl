<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.loc.gov/mods/v3" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    exclude-result-prefixes="dc" 
    version="1.0">
    <!--
        
        FLVC DC 2 MODS
        version 2.0: Sept 19, 2013: This version has been cleaned up for dual use in DigiTool conversion and Islandora GUI use.  Functionality
                    remains the same (diff b/w DigiTool and FLVC versions is the insertion of a digitool pid in the former).
        version 1.4: June 19, 2013: This version checks for a PURL and inserts one from an inc file if there isn't one in the record itself.
                    NOTE: version 1.4 no longer requires an external "digitool.xsl" stylesheet.
                    NOTE: version 1.4 requires a "purl.xml" file to be present if there is no PURL in the <identifier> field.
        version 1.3: May 28, 2013: This version fixes originInfo and physicalDescription from putting out blank elements as a result of blanks in the DC.
                                    Also, got rid of the normalize.xsl and have incorporated changes directly into this document (e.g. dc:accessrights)
        
        
        ********
        
        This stylesheet will transform Dublin Core to MODS version 3.4.
        
        Based on LOC
        Version 1.1 2012-08-12 WS  
        Upgraded to MODS 3.4
        
        Version 1.0 2006-11-01 cred@loc.gov
        
        This stylesheet will transform simple Dublin Core (DC) expressed in either OAI DC [1] or SRU DC [2] schemata to MODS 
        version 3.2.
        
        Reasonable attempts have been made to automatically detect and process the textual content of DC elements for the purposes 
        of outputting to MODS.  Because MODS is more granular and expressive than simple DC, transforming a given DC element to the 
        proper MODS element(s) is difficult and may result in imprecise or incorrect tagging.  Undoubtedly local customizations will 
        have to be made by those who utilize this stylesheet in order to achieve deisred results.  No attempt has been made to 
        ignore empty DC elements.  If your DC contains empty elements, they should either be removed, or local customization to 
        detect the existence of text for each element will have to be added to this stylesheet.
        
        MODS also often encourages content adhering to various data value standards.  The contents of some of the more widely used value 
        standards, such as IANA MIME types, ISO 3166-1, ISO 639-2, etc., have been added into the stylesheet to facilitate proper 
        mapping of simple DC to the proper MODS elements.  A crude attempt at detecting the contents of DC identifiers and outputting them
        to the proper MODS elements has been made as well.  Common persistent identifier schemes, standard numbers, etc., have been included.
        To truly detect these efficiently, XSL/XPath 2.0 or XQuery may be needed in order to utilize regular expressions.
        
        [1] http://www.openarchives.org/OAI/openarchivesprotocol.html#MetadataNamespaces
        [2] http://www.loc.gov/standards/sru/record-schemas.html
        
    -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/dcmiType.xsl"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/mimeType.xsl"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/csdgm.xsl"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/forms.xsl"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/iso3166-1.xsl"/>
    <xsl:include href="http://www.loc.gov/standards/mods/inc/iso639-2.xsl"/>
    
  
    <!-- Do you have a Handle server?  If so, specify the base URI below including the trailing slash a la: http://hdl.loc.gov/ -->
    <xsl:variable name="handleServer">
		<xsl:text>http://hdl.loc.gov/</xsl:text>
    </xsl:variable>
    
    <xsl:template match="*[not(node())]"/> <!-- strip empty DC elements that are output by tools like ContentDM -->
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="record">
        <mods version="3.4" xmlns="http://www.loc.gov/mods/v3" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">
            <xsl:call-template name="dcMain_flvc"/>
        </mods>
    </xsl:template>
    
    <xsl:template name="dcMain_flvc">
        <!-- titleInfo -->
        <xsl:apply-templates select="dc:title"/>
        <xsl:apply-templates select="dcterms:alternative"/>
        
        <!-- identifier -->
        <xsl:apply-templates select="dc:identifier"/>
        <!-- <xsl:call-template name="digitool_pid"/> digitool conversion only -->
        
        <!-- name -->
        <xsl:apply-templates select="dc:creator"/>
        <xsl:apply-templates select="dc:contributor"/>
        <xsl:apply-templates select="dcterms:rightsHolder"/>
        
        <!-- type of resource -->
        <xsl:apply-templates select="dc:type"/>
        
        <!-- originInfo -->
        <xsl:call-template name="originInfo"/>
        <!-- the following elements are called within originInfo 
            dc:publisher
            dc:date
            dcterms:available
            dcterms:created
            dcterms:dateAccepted
            dcterms:dateCopyrighted
            dcterms:dateSubmitted
            dcterms:issued
            dcterms:modified
            dcterms:valid
        -->
                
        <!-- language -->
        <xsl:apply-templates select="dc:language"/>
        
        <!-- physical description -->
        <xsl:call-template name="physicalDescription"/>
        <!-- the following elements are called within physicalDescription
            dc:format
            dcterms:extent
            dcterms:medium
        -->
        
        <!-- abstract -->
        <xsl:apply-templates select="dcterms:abstract"/>
        <xsl:apply-templates select="dc:description"/>
        
        <!-- table of contents -->
        <xsl:apply-templates select="dcterms:tableOfContents"/>        
        
        <!-- target audience -->
        <xsl:apply-templates select="dcterms:audience"/>
        <xsl:apply-templates select="dcterms:educationLevel"/>
        <xsl:apply-templates select="dcterms:mediator"/>
        
        <!-- note -->
        <xsl:apply-templates select="dcterms:bibliographicCitation"/>
        <xsl:apply-templates select="dcterms:conformsTo"/>
        <xsl:apply-templates select="dcterms:provenance"/>
        <xsl:apply-templates select="dcterms:thesisDiscipline"/>
        <xsl:apply-templates select="dcterms:thesisDivision"/>
        
        <!-- subects -->
        <xsl:apply-templates select="dc:subject"/>
        <xsl:apply-templates select="dc:coverage"/>
        <xsl:apply-templates select="dcterms:spatial"/>
        <xsl:apply-templates select="dcterms:temporal"/>
        
        <!-- classification -->
        
        <!-- related item(s) -->
        <xsl:apply-templates select="dc:source" />
        <xsl:apply-templates select="dc:relation"/>
        <xsl:apply-templates select="dcterms:hasFormat"/> 
        <xsl:apply-templates select="dcterms:hasPart"/>
        <xsl:apply-templates select="dcterms:hasVersion"/> 
        <xsl:apply-templates select="dcterms:isFormatOf"/> 
        <xsl:apply-templates select="dcterms:isPartOf"/> 
        <xsl:apply-templates select="dcterms:isReferencedBy"/> 
        <xsl:apply-templates select="dcterms:isReplacedBy"/> 
        <xsl:apply-templates select="dcterms:isRequiredBy"/> 
        <xsl:apply-templates select="dcterms:isVersionOf"/>
        <xsl:apply-templates select="dcterms:references"/> 
        <xsl:apply-templates select="dcterms:replaces"/> 
        <xsl:apply-templates select="dcterms:requires"/>
        <xsl:apply-templates select="dc:link" />
        
        <!-- location -->
        <xsl:apply-templates select="dcterms:physicalLocation"/>
        <xsl:call-template name="PURL_location"/>
        <xsl:call-template name="URL_location"/>
        <xsl:apply-templates select="dcterms:catlink"/>
        
        <!-- access condition -->
        <xsl:apply-templates select="dc:rights"/>
        <xsl:apply-templates select="dcterms:accessRights"/>
        <!-- <xsl:apply-templates select="dc:accessRights"/> normalization for DigiTool materials only -->
        <xsl:apply-templates select="dcterms:license"/>
        
        
        <!-- record info -->
        
        <!-- extension -->
       <!--  <xsl:call-template name="normalize_errExtension"/> Creates notes for each field found and normalized -->
        
    </xsl:template>

<!-- ************************* titleInfo ************************** -->
    
    <xsl:template match="dc:title">
        <titleInfo>
            <title>
                <xsl:apply-templates/>
            </title>
        </titleInfo>
    </xsl:template>
    
    <xsl:template match="dcterms:alternative">
        <titleInfo type="alternative">
            <title>
                <xsl:apply-templates/>
            </title>
        </titleInfo>
    </xsl:template>

<!-- ******************************* identifier ***************************** -->
    
    <xsl:template match="dc:identifier">
        <xsl:variable name="iso-3166Check">
            <xsl:value-of select="substring(text(), 1, 2)"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="starts-with(text(), 'http://')">
                <!-- This is handled by <xsl:template name="URL_location"> below -->
            </xsl:when>
            <xsl:when test="not(starts-with(text(), 'http://')) and (
                ('.jpg' = substring(text(), string-length() - string-length('.jpg') +1))
                or ('.jpeg' = substring(text(), string-length() - string-length('.jpeg') +1)) 
                or ('.jpg' = substring(text(), string-length() - string-length('.jpg') +1))
                or ('.jp2' = substring(text(), string-length() - string-length('.jp2') +1))
                or ('.pdf' = substring(text(), string-length() - string-length('.pdf') +1))
                or ('.tif' = substring(text(), string-length() - string-length('.tif') +1))
                or ('.tiff' = substring(text(), string-length() - string-length('.tiff') +1))
                )">
                <!-- removes dc:identifiers with filenames in them -->
            </xsl:when>
            <xsl:when test="not(starts-with(text(), 'http://'))">
                <identifier>
                    <xsl:attribute name="type">
                        <xsl:choose>
                            <!-- handled by location/url -->
                            <xsl:when test="starts-with(text(), 'http://') and (not(contains(text(), $handleServer) or not(contains(substring-after(text(), 'http://'), 'hdl'))))">
                                <xsl:text>uri</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(),'urn:hdl') or starts-with(text(),'hdl') or starts-with(text(),'http://hdl.')">
                                <xsl:text>hdl</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(), 'doi')">
                                <xsl:text>doi</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(), 'ark')">
                                <xsl:text>ark</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(text(), 'purl')">
                                <xsl:text>purl</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(), 'tag')">
                                <xsl:text>tag</xsl:text>
                            </xsl:when>
                            <!--NOTE:  will need to update for ISBN 13 as of January 1, 2007, see XSL tool at http://isbntools.com/ -->
                            <xsl:when test="(starts-with(text(), 'ISBN') or starts-with(text(), 'isbn')) or ((string-length(text()) = 13) and contains(text(), '-') and (starts-with(text(), '0') or starts-with(text(), '1'))) or ((string-length(text()) = 10) and (starts-with(text(), '0') or starts-with(text(), '1')))">
                                <xsl:text>isbn</xsl:text>
                            </xsl:when>
                            <xsl:when test="(starts-with(text(), 'ISRC') or starts-with(text(), 'isrc')) or ((string-length(text()) = 12) and (contains($iso3166-1, $iso-3166Check))) or ((string-length(text()) = 15) and (contains(text(), '-') or contains(text(), '/')) and contains($iso3166-1, $iso-3166Check))">
                                <xsl:text>isrc</xsl:text>
                            </xsl:when>
                            <xsl:when test="(starts-with(text(), 'ISMN') or starts-with(text(), 'ismn')) or starts-with(text(), 'M') and ((string-length(text()) = 11) and contains(text(), '-') or string-length(text()) = 9)">
                                <xsl:text>ismn</xsl:text>
                            </xsl:when>
                            <xsl:when test="(starts-with(text(), 'ISSN') or starts-with(text(), 'issn')) or ((string-length(text()) = 9) and contains(text(), '-') or string-length(text()) = 8)">
                                <xsl:text>issn</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(), 'ISTC') or starts-with(text(), 'istc')">
                                <xsl:text>istc</xsl:text>
                            </xsl:when>
                            <xsl:when test="(starts-with(text(), 'UPC') or starts-with(text(), 'upc')) or (string-length(text()) = 12 and not(contains(text(), ' ')) and not(contains($iso3166-1, $iso-3166Check)))">
                                <xsl:text>upc</xsl:text>
                            </xsl:when>
                            <xsl:when test="(starts-with(text(), 'SICI') or starts-with(text(), 'sici')) or ((starts-with(text(), '0') or starts-with(text(), '1')) and (contains(text(), ';') and contains(text(), '(') and contains(text(), ')') and contains(text(), '&lt;') and contains(text(), '&gt;')))">
                                <xsl:text>sici</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with(text(), 'LCCN') or starts-with(text(), 'lccn')">
                                <!-- probably can't do this quickly or easily without regexes and XSL 2.0 -->
                                <xsl:text>lccn</xsl:text>
                            </xsl:when>
                            <!-- This grabs the contents of the () before the local id -->
                            <xsl:when test="starts-with(text(), '(')">
                                <xsl:value-of select="substring-before(substring-after(text(), '('),')')" />
                            </xsl:when>
                            <!-- no default type needed
                        <xsl:otherwise>
                            <xsl:text>local</xsl:text>
                        </xsl:otherwise> --> 
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="starts-with(text(),'urn:hdl') or starts-with(text(),'hdl') or starts-with(text(),$handleServer)">
                            <xsl:value-of select="concat('hdl:',substring-after(text(),$handleServer))"/>
                        </xsl:when>
                        <xsl:when test="starts-with(text(), '(')">
                            <xsl:value-of select="substring-after(text(), ')')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </identifier>
            </xsl:when>
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template name="digitool_pid">
        <identifier type="digitool">
            <xsl:value-of select="document('info.xml')/root/pid"/>
        </identifier>
    </xsl:template>

<!-- ***************************** name ******************************* -->

    <xsl:template match="dc:creator">
        <name>
            <namePart>
                <xsl:apply-templates/>
            </namePart>
            <role>
                <roleTerm type="text" authority="marcrelator">
                    <xsl:text>creator</xsl:text>
                </roleTerm>
            </role>
            <!--<displayForm>
                <xsl:value-of select="."/>
            </displayForm>-->
        </name>
    </xsl:template>
    
    <xsl:template match="dc:contributor">
        <name>
            <namePart>
                <xsl:apply-templates/>
            </namePart>
            <!-- <role>
                <roleTerm type="text">
                <xsl:text>contributor</xsl:text>
                </roleTerm>
                </role> -->
        </name>
    </xsl:template>
    
    <xsl:template match="dcterms:rightsHolder">
        <name>
            <namePart>
                <xsl:apply-templates/>
            </namePart>
            <role>
                <roleTerm type="text" authority="marcrelator">
                    <xsl:text>copyright holder</xsl:text>
                </roleTerm>
            </role>
        </name>
    </xsl:template>
 
 <!-- *********************************** type of resource **************************************** -->

    <xsl:template match="dc:type">
        <!--2.0: Variable test for any dc:type with value of collection for mods:typeOfResource -->
        <xsl:variable name="collection">
            <xsl:if test="../dc:type[string(text()) = 'collection' or string(text()) = 'Collection']">true</xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains(text(), 'Collection') or contains(text(), 'collection')">
                <genre authority="dct">
                    <xsl:text>collection</xsl:text>
                </genre>
            </xsl:when>
            <xsl:otherwise>
                <!-- based on DCMI Type Vocabulary as of 2012-08-09 at http://dublincore.org/documents/dcmi-type-vocabulary/ ...  see also the included dcmiType.xsl serving as variable $types -->
                <xsl:choose>
                    <xsl:when test="string(text()) = 'Dataset' or string(text()) = 'dataset'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>	
                            <!-- 2.0: changed software to software, multimedia re: mappings 2012-08-09 -->
                            <xsl:text>software, multimedia</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <!-- 2.0: chanded dataset to database, re: mappings 2012-08-09 -->
                            <xsl:text>database</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Event' or string(text()) = 'event'">
                        <genre authority="dct">
                            <xsl:text>event</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Image' or string(text()) = 'image'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>still image</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>image</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'InteractiveResource' or string(text()) = 'interactiveresource' or string(text()) = 'Interactive Resource' or string(text()) = 'interactive resource' or string(text()) = 'interactiveResource'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>software, multimedia</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>interactive resource</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'MovingImage' or string(text()) = 'movingimage' or string(text()) = 'Moving Image' or string(text()) = 'moving image' or string(text()) = 'movingImage'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>moving image</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>moving image</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'PhysicalObject' or string(text()) = 'physicalobject' or string(text()) = 'Physical Object' or string(text()) = 'physical object' or string(text()) = 'physicalObject'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>three dimensional object</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>physical object</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Service' or string(text()) = 'service'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>software, multimedia</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <!-- WS: chanded service to online system or service, re: mappings 2012-08-09 -->
                            <xsl:text>online system or service</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Software' or string(text()) = 'software'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>software, multimedia</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>software</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Sound' or string(text()) = 'sound'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>sound recording</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>sound</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'StillImage' or string(text()) = 'stillimage' or string(text()) = 'Still Image' or string(text()) = 'still image' or string(text()) = 'stillImage'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>still image</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>still image</xsl:text>
                        </genre>
                    </xsl:when>
                    <!-- FLVC edit - not controlled vocab, but will catch a lot of materials -->
                    <xsl:when test="contains(text(),'photo') or contains(text(),'Photo')">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>still image</xsl:text>
                        </typeOfResource>
                    </xsl:when>
                    <xsl:when test="string(text()) = 'Text' or string(text()) = 'text'">
                        <typeOfResource>
                            <xsl:if test="$collection='true'">
                                <xsl:attribute name="collection">
                                    <xsl:text>yes</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:text>text</xsl:text>
                        </typeOfResource>
                        <genre authority="dct">
                            <xsl:text>text</xsl:text>
                        </genre>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="not(string($types) = text())">
                            <xsl:variable name="lowercaseType" select="translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
                            <!--<typeOfResource>
                                <xsl:text>mixed material</xsl:text>
                                </typeOfResource>-->
                            <genre>
                                <xsl:value-of select="$lowercaseType"/>
                            </genre>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>   
    
<!-- ************************************* originInfo ***************************************** -->
<!-- We want only one originInfo element, which then contains any subelements -->

    <xsl:template name="originInfo">
        <xsl:if test="dc:publisher[.!=''] | dc:date[.!=''] | dcterms:available[.!=''] | dcterms:created[.!=''] | dcterms:dateAccepted[.!=''] | dcterms:dateCopyrighted[.!=''] | dcterms:dateSubmitted[.!=''] | dcterms:issued[.!=''] | dcterms:modified[.!=''] | dcterms:valid[.!='']">
           <originInfo>
               <xsl:apply-templates select="dc:publisher"/>
               <xsl:apply-templates select="dc:date"/>
               <xsl:apply-templates select="dcterms:available"/>
               <xsl:apply-templates select="dcterms:created"/>
               <xsl:apply-templates select="dcterms:dateAccepted"/>
               <xsl:apply-templates select="dcterms:dateCopyrighted"/>
               <xsl:apply-templates select="dcterms:dateSubmitted"/>
               <xsl:apply-templates select="dcterms:issued"/>
               <xsl:apply-templates select="dcterms:modified"/>
               <xsl:apply-templates select="dcterms:valid"/>
           </originInfo>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="dc:publisher">
        <publisher>
            <xsl:apply-templates/>
        </publisher>
    </xsl:template>
    
    <!-- These when statements check to see if the date value is a 4-digit number, in which case we apply the encoding="w3cdtf" (otherwise not) -->
    <xsl:template match="dc:date">
        <xsl:choose>
            <!-- <xsl:when test="(number(.)=.) and (string-length(string(.))=4)"> -->
            <xsl:when test="(string(number(.)) != 'NaN') and (string-length(string(.))=4)">
              <dateIssued encoding="w3cdtf" keyDate="yes">
                  <xsl:apply-templates/>
              </dateIssued>
            </xsl:when>
            <xsl:otherwise>
                <dateIssued keyDate="yes">
                    <xsl:apply-templates/>
                </dateIssued>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="dcterms:available">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateOther encoding="w3cdtf" type="available">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:when>
            <xsl:otherwise>
                <dateOther type="available">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dcterms:created">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateCreated encoding="w3cdtf">
                    <xsl:apply-templates/>
                </dateCreated>
            </xsl:when>
            <xsl:otherwise>
              <dateCreated>
                  <xsl:apply-templates/>
              </dateCreated>
           </xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    
    <xsl:template match="dcterms:dateAccepted">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateOther encoding="w3cdtf" type="accepted">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:when>
            <xsl:otherwise>
                <dateOther type="accepted">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template> 
    
    <xsl:template match="dcterms:dateCopyrighted">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <copyrightDate encoding="w3cdtf">
                    <xsl:apply-templates/>
                </copyrightDate>
            </xsl:when>
            <xsl:otherwise>
                <copyrightDate>
                    <xsl:apply-templates/>
                </copyrightDate>
            </xsl:otherwise>
            </xsl:choose>
     </xsl:template> 
    
    <xsl:template match="dcterms:dateSubmitted">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateOther encoding="w3cdtf" type="submitted">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:when>
            <xsl:otherwise>
                <dateOther type="submitted">
                    <xsl:apply-templates/>
                </dateOther>
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template> 
    
    <xsl:template match="dcterms:issued">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateIssued encoding="w3cdtf">
                    <xsl:apply-templates/>
                </dateIssued>
            </xsl:when>
            <xsl:otherwise>
                <dateIssued>
                    <xsl:apply-templates/>
                </dateIssued>          
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template> 
    
    <xsl:template match="dcterms:modified">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateModified encoding="w3cdtf">
                    <xsl:apply-templates/>
                </dateModified>
            </xsl:when>
            <xsl:otherwise>
                <dateModified>
                    <xsl:apply-templates/>
                </dateModified>
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dcterms:valid">
        <xsl:choose>
            <xsl:when test="(number(.)=.) and (string-length(string(.))=4)">
                <dateValid encoding="w3cdtf">
                    <xsl:apply-templates/>
                </dateValid>
            </xsl:when>
            <xsl:otherwise>
                <dateValid>
                    <xsl:apply-templates/>
                </dateValid>
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    
<!-- ********************************* language ************************************** -->
    <xsl:template match="dc:language">
        <language>
            <xsl:choose>
                <xsl:when test="string-length(text()) = 3 and contains($iso639-2, text())">
                    <languageTerm type="code">
                        <xsl:apply-templates/>
                    </languageTerm>
                </xsl:when>
                <xsl:otherwise>
                    <languageTerm type="text">
                        <xsl:apply-templates/>
                    </languageTerm>
                </xsl:otherwise>
            </xsl:choose>
        </language>
    </xsl:template>

<!-- ********************************** physical description *********************************** -->
    <xsl:template name="physicalDescription">
        <xsl:if test="dc:format[.!=''] | dcterms:extent[.!=''] | dcterms:medium[.!='']">
            <physicalDescription>
                <xsl:apply-templates select="dc:format"/>
                <xsl:apply-templates select="dcterms:extent"/>
                <xsl:apply-templates select="dcterms:medium"/>
            </physicalDescription>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="dc:format">
        <xsl:choose>
            <xsl:when test="contains(text(), '/')">
                <note>
                    <xsl:apply-templates/>
                </note>
            </xsl:when>
            <xsl:when test="starts-with(.,'1') or starts-with(.,'2') or starts-with(.,'3') or starts-with(.,'4') or starts-with(.,'5') or starts-with(.,'6') or starts-with(.,'7') or starts-with(.,'8') or starts-with(.,'9')">
                <extent>
                    <xsl:apply-templates/>
                </extent>
            </xsl:when>
            <xsl:when test="contains($forms, text())">
                <form>
                    <xsl:apply-templates/>
                </form>
            </xsl:when>
            <xsl:otherwise>
                <note>
                    <xsl:apply-templates/>
                </note>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dcterms:extent">
        <extent>
            <xsl:apply-templates/>
        </extent>
    </xsl:template>
    
    <xsl:template match="dcterms:medium">
        <form>
            <xsl:apply-templates/>
        </form>
    </xsl:template>
    
<!-- ******************************** abstract ****************************** -->


    <xsl:template match="dcterms:abstract">
        <abstract>
            <xsl:apply-templates/>
        </abstract>
    </xsl:template>
    
    <!-- description is in this section because either it contains an abstract-like summary
        or because it contains a physical description, either way, it belongs in this part -->
    <xsl:template match="dc:description"> 
        <!--<abstract>
            <xsl:apply-templates/>
            </abstract>-->
        <note>
            <xsl:apply-templates/>
        </note>
        <!--<tableOfContents>
            <xsl:apply-templates/>
            </tableOfContents>-->
    </xsl:template>
    
    
<!-- ************************************** table of contents ************************************* -->    
    
    <xsl:template match="dcterms:tableOfContents"> 
        <tableOfContents>
            <xsl:apply-templates/>
        </tableOfContents>
    </xsl:template>    
    
<!-- **************************************** target audience **************************************** -->    

    <xsl:template match="dcterms:audience">
        <targetAudience>
            <xsl:apply-templates/>
        </targetAudience>
    </xsl:template>
    
    <xsl:template match="dcterms:educationLevel">
        <targetAudience displayLabel="education level">
            <xsl:apply-templates/>
        </targetAudience>
    </xsl:template>
    
    <xsl:template match="dcterms:mediator">
        <targetAudience displayLabel="mediator">
            <xsl:apply-templates/>
        </targetAudience>
    </xsl:template>

<!-- *************************************** Note *********************************************** -->
    
    <xsl:template match="dcterms:bibliographicCitation">
        <note type="citation/reference">
            <xsl:apply-templates/>
        </note>
    </xsl:template>
    
    <xsl:template match="dcterms:conformsTo">
        <note type="conformsToStandard">
            <xsl:apply-templates/>
        </note>
    </xsl:template>
    
    <xsl:template match="dcterms:provenance">
        <note type="provenance">
            <xsl:apply-templates/>
        </note>
    </xsl:template>
    
    <xsl:template match="dcterms:thesisDiscipline">
        <note type="thesisDiscipline">
            <xsl:apply-templates/>
        </note>
    </xsl:template>
    
    <xsl:template match="dcterms:thesisDivision">
        <note type="thesisDiscipline">
            <xsl:apply-templates/>
        </note>
    </xsl:template>

<!-- ********************************* subject(s) ****************************************** -->

    <xsl:template match="dc:subject">
        <subject>
            <topic>
                <xsl:apply-templates/>
            </topic>
        </subject>
    </xsl:template>
    
    <xsl:template match="dc:coverage">
        <xsl:choose>
            <xsl:when test="contains(text(), '°') 
                or contains(text(), 'geo:lat') 
                or contains(text(), 'geo:lon') 
                or contains(text(), ' N ') 
                or contains(text(), ' S ') 
                or contains(text(), ' E ') 
                or contains(text(), ' W ')">
                <!-- predicting minutes and seconds with ' or " might break if quotes used for other purposes exist in the text node -->
                <subject>
                    <cartographics>
                        <coordinates>
                            <xsl:apply-templates/>
                        </coordinates>
                    </cartographics>
                </subject>
            </xsl:when>
            <xsl:when test="contains(text(), ':') and starts-with(text(), '1') and (contains(substring-after(text(), ':'), '1') or contains(substring-after(text(), ':'), '2') or contains(substring-after(text(), ':'), '3') or contains(substring-after(text(), ':'), '4') or contains(substring-after(text(), ':'), '5') or contains(substring-after(text(), ':'), '6') or contains(substring-after(text(), ':'), '7') or contains(substring-after(text(), ':'), '8') or contains(substring-after(text(), ':'), '9'))">                    
                <subject>
                    <cartographics>
                        <scale>
                            <xsl:apply-templates/>
                        </scale>
                    </cartographics>
                </subject>
            </xsl:when>
            <xsl:when test="starts-with(.,'Scale')">
                <subject>
                    <cartographics>
                        <scale>
                            <xsl:apply-templates/>
                        </scale>
                    </cartographics>
                </subject>
            </xsl:when>
            <xsl:when test="contains($projections, text())">
                <subject>
                    <cartographics>
                        <projection>
                            <xsl:apply-templates/>
                        </projection>
                    </cartographics>
                </subject>
            </xsl:when>
            <xsl:when test="string-length(text()) >= 3 and (starts-with(text(), '1') or starts-with(text(), '2') or starts-with(text(), '3') or starts-with(text(), '4') or starts-with(text(), '5') or starts-with(text(), '6') or starts-with(text(), '7') or starts-with(text(), '8') or starts-with(text(), '9') or starts-with(text(), '-') or contains(text(), 'AD') or contains(text(), 'BC')) and not(contains(text(), ':'))">
                <subject> 
                    <temporal>
                        <xsl:apply-templates/>
                    </temporal>
                </subject>
            </xsl:when>
            <xsl:otherwise>
                <subject>
                    <geographic>
                        <xsl:apply-templates/>
                    </geographic>
                </subject>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="dcterms:spatial">
        <subject>
            <geographic>
                <xsl:apply-templates/>
            </geographic>
        </subject>
    </xsl:template>
    
    <xsl:template match="dcterms:temporal">
        <subject>
            <temporal>
                <xsl:apply-templates/>
            </temporal>
        </subject>
    </xsl:template>
<!-- ****************************** classification ******************************* -->

<!-- ******************************** relatedItem(s) *********************************** -->
    
    <xsl:template match="dc:source">
        <!-- 2.0: added a choose statement to test for url -->
        <relatedItem type="original">
            <xsl:choose>
                <xsl:when test="starts-with(normalize-space(.),'http://')">
                    <location>
                        <url>
                            <xsl:apply-templates/>
                        </url>
                    </location>
                    <identifier type="uri">
                        <xsl:apply-templates/>
                    </identifier>
                </xsl:when>
                <xsl:otherwise>
                    <titleInfo>
                        <title>
                            <xsl:apply-templates/>
                        </title>
                    </titleInfo>
                </xsl:otherwise>
            </xsl:choose>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dc:relation">
        <relatedItem>
            <xsl:choose>
                <xsl:when test="starts-with(text(), 'http://')">
                    <location>
                        <url>
                            <xsl:value-of select="."/>
                        </url>
                    </location>
                    <identifier type="uri">
                        <xsl:apply-templates/>
                    </identifier>
                </xsl:when>
                <xsl:otherwise>
                    <titleInfo>
                        <title>
                            <xsl:apply-templates/>
                        </title>
                    </titleInfo>
                </xsl:otherwise>
            </xsl:choose>            
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:hasFormat">
        <relatedItem type="otherFormat">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:hasPart">
        <relatedItem type="constituent">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:hasVersion">
        <relatedItem type="otherVersion">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:isFormatOf">
        <relatedItem type="otherFormat">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:isPartOf">
        <relatedItem type="host">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
 
    <xsl:template match="dcterms:isReferencedBy">
        <relatedItem type="isReferencedBy">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:isReplacedBy">
        <relatedItem displayLabel="isReplacedBy">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:isRequiredBy">
        <relatedItem displayLabel="isRequiredBy">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>

    <xsl:template match="dcterms:isVersionOf">
        <relatedItem type="otherVersion">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:references">
        <relatedItem type="references">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:replaces">
        <relatedItem displayLabel="replaces">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
    
    <xsl:template match="dcterms:requires">
        <relatedItem displayLabel="requires">
            <titleInfo>
                <title>
                    <xsl:apply-templates/>
                </title>
            </titleInfo>
        </relatedItem>
    </xsl:template>
        
    <xsl:template match="dc:link">
        <relatedItem displayLabel="Related Resource">
            <xsl:attribute name="xlink:href">
                <xsl:value-of select="." />
            </xsl:attribute>
        </relatedItem>
    </xsl:template>

<!-- ************************************** location ************************************** -->
    
    <xsl:template match="dcterms:physicalLocation">
        <location>
            <physicalLocation>
                <xsl:apply-templates/>
            </physicalLocation>
        </location>
    </xsl:template>

    <xsl:template name="PURL_location">
        <xsl:choose>
            <xsl:when test="./dc:identifier[starts-with(text(), 'http://') and contains(text(), 'purl')]">
                <xsl:for-each select="./dc:identifier[starts-with(text(), 'http://') and contains(text(), 'purl')]">
                    <location>
                        <xsl:attribute name="displayLabel">
                            <xsl:text>purl</xsl:text>
                        </xsl:attribute>
                        <url>
                            <!-- 1.0 way to replace 'fcla.edu' with 'flvc.org' -->
                            <xsl:call-template name="replace-string">
                                <xsl:with-param name="text" select="."/>
                                <xsl:with-param name="replace" select="'fcla.edu'" />
                                <xsl:with-param name="with" select="'flvc.org'"/>
                            </xsl:call-template>
                        </url>
                    </location>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="document('purl.xml')/root/purl">
                  <location>
                      <xsl:attribute name="displayLabel">
                          <xsl:text>purl</xsl:text>
                      </xsl:attribute>
                      <url>
                          <xsl:value-of select="."/>
                      </url>
                  </location>
                </xsl:for-each>
            </xsl:otherwise>              
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="URL_location">    
        <xsl:for-each select="./dc:identifier[starts-with(text(), 'http://') and not(contains(text(), 'purl'))]">
            <location>
                <url>
                    <xsl:value-of select="."/>
                </url>
            </location>
        </xsl:for-each>
    </xsl:template>    
    
    <xsl:template match="dcterms:catlink">
        <location displayLabel="Catalog Link">
            <url>
                <xsl:value-of select="."/>
            </url>
        </location>
    </xsl:template>


<!-- ********************************************* access condition ******************************************** -->
    <xsl:template match="dc:rights">
        <accessCondition>
            <xsl:apply-templates/>
        </accessCondition>
    </xsl:template>
    
    <xsl:template match="dcterms:accessRights">
        <accessCondition type="restriction on access">
            <xsl:apply-templates/>
        </accessCondition>
    </xsl:template>
    
    <xsl:template match="dcterms:license">
        <accessCondition type="use and reproduction">
            <xsl:apply-templates/>
        </accessCondition>
    </xsl:template>
    
    <!-- note: not a real element, DigiTool only -->
    <xsl:template match="dc:accessRights">
        <accessCondition type="restriction on access">
            <xsl:apply-templates/>
        </accessCondition>
    </xsl:template>
    
    
<!-- ******************************************* record info *********************************************** -->

<!-- **************************************************** FLVC extension *********************************************** -->
    
<!-- ******************************************* Other useful templates ****************************************** -->

    <xsl:template name="replace-string">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="with"/>
        <xsl:choose>
            <xsl:when test="contains($text,$replace)">
                <xsl:value-of select="substring-before($text,$replace)"/>
                <xsl:value-of select="$with"/>
                <xsl:call-template name="replace-string">
                    <xsl:with-param name="text"
                        select="substring-after($text,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="with" select="$with"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
