<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:mods="http://www.loc.gov/mods/v3" exclude-result-prefixes="mods"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:srw_dc="info:srw/schema/1/dc-schema"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- **************************************************************************************
 
This stylesheet transforms MODS version 3.2 records and collections of records to simple Dublin Core (DC) records, based on the Library of Congress' MODS to simple DC mapping Revision 1.1 (2007-05-18)  <http://www.loc.gov/standards/mods/mods-dcsimple.html> 

It was revised by Priscilla Caplan 10/23/2013 to include the following changes:

1) For  mods:subject elements with any of the following subelements: <topic>, <geographic>, <temporal>, <genre>, create a dc:subject by concatenating the values of each subelement in mods:subject in the order that they occur, separated by dash-dash  For all mods:geographic within a single mods:subject create a dc:coverage with their values, separated by dash-dash.  For each mods:temporal create a dc:coverage with that value.

2) For the first occurence of the <date> subelement <dateCreated>, create dc:date with the value of dateCreated.  (There should be zero or one dateCreated.)  If there is no subelement <dateCreated> and there is a subelement <dateIssued>, create dc:date with the value of <dateIssued>.  If there are no subelements <dateIssued> or <dateCreated> but there is a subelement <copyrightDate>, create dc:date with the value of copyrightDate.  If there are no subelements <dateIssued>, <dateCreated> or <copyrightDate> but there is a subelement <dateOther>, create dc:date with the value of <dateOther>.

3) If there is a <date> subelement <dateIssued> and also a subelement <dateCreated>, create dc:description with the value of <dateCreated> prefaced by "Creation date: ".  E.g. if MODS contains <originInfo><dateIssued>2012</dateIssued><dateCreated>2011</dateCreated></originInfo> create DC <date>2012</date><description>Creation date: 2011</description.

4) If there is a <date> subelement <dateIssued> or <dateCreated> and also a subelement <copyrightDate>, create a dc:description with the value of <copyrightDate> prefaced by "Copyright date: ".

5) For each <date> sublement <dateCaptured>, <dateValid> and <dateModified>, create dc:description with the valude of the subelement preceded by the label "Capture date: ", "Date valid: ", and/or "Modification date: " respectively.

6) If MODS contains both <originInfo> subelements <place> and <publisher>, format dc:publisher with the value of <place>, space, colon, space, value of <publisher>.  E.g. MODS <place>Boston</place><publisher>Harper & Row</publisher> create DC <publisher>Boston : Harper & Row</publisher>. 

7)  If MODS contains only <publisher> and not <place>, format dc:publisher with the value of <publisher>.

8) If MODS contains only <place> and not <publisher>, format dc:description with the value of <place> preceded by "Place of publication: ".

9) If MODS contains the subelement <frequency>, format dc:description with the value of <frequency> preceded by "Frequency: ".

10) Do not create dc:format for the subelement <internetMediaType>.

11) If there is a type attribute to <identifier> put the type attribute in parens before the identifier value, e.g. <identifier>(ISSN) 2431-2938</identifier>.

12) If there is a <url> subelement in <location>, put the value into dc:identifier preceded by "(URL)".  The LC xslt maps <url> to dc:identifier but does not supply the prefix. 

************************************************************************************ -->

	<xsl:output method="xml" indent="yes"/>
	<xsl:strip-space elements="*"/>

	<xsl:template match="/">
		<xsl:choose>
		<xsl:when test="//mods:modsCollection">			
			<srw_dc:dcCollection xsi:schemaLocation="info:srw/schema/1/dc-schema http://www.loc.gov/standards/sru/dc-schema.xsd">
				<xsl:apply-templates/>
			<xsl:for-each select="mods:modsCollection/mods:mods">			
				<srw_dc:dc xsi:schemaLocation="info:srw/schema/1/dc-schema http://www.loc.gov/standards/sru/dc-schema.xsd">
				<xsl:apply-templates/>
			</srw_dc:dc>
			</xsl:for-each>
			</srw_dc:dcCollection>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="mods:mods">
			<oai_dc:dc xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
				<xsl:apply-templates/>
			</oai_dc:dc>
			</xsl:for-each>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="mods:titleInfo">
		<dc:title>
			<xsl:value-of select="mods:nonSort"/>
			<xsl:if test="mods:nonSort">
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:value-of select="mods:title"/>
			<xsl:if test="mods:subTitle">
				<xsl:text>: </xsl:text>
				<xsl:value-of select="mods:subTitle"/>
			</xsl:if>
			<xsl:if test="mods:partNumber">
				<xsl:text>. </xsl:text>
				<xsl:value-of select="mods:partNumber"/>
			</xsl:if>
			<xsl:if test="mods:partName">
				<xsl:text>. </xsl:text>
				<xsl:value-of select="mods:partName"/>
			</xsl:if>
		</dc:title>
	</xsl:template>

	<xsl:template match="mods:mods/mods:name">
		<xsl:choose>
			<xsl:when
				test="mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre' ">
				<dc:creator>
					<xsl:call-template name="name"/>
				</dc:creator>
			</xsl:when>

			<xsl:when
                                test="mods:role/mods:roleTerm[@type='text']='photographer' or mods:role/mods:roleTerm[@type='code']='pht'">
                                <xsl:choose>
                                       <xsl:when test="/mods:mods/mods:typeOfResource='still image'">
	                                    <dc:creator>
					         <xsl:call-template name="name"/>
                                        </dc:creator>													               </xsl:when>
                                </xsl:choose>
                        </xsl:when>

			<xsl:otherwise>
				<dc:contributor>
					<xsl:call-template name="name"/>
				</dc:contributor>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:classification">
		<dc:subject>
			<xsl:value-of select="."/>
		</dc:subject>
	</xsl:template>

        <xsl:template match="mods:subject[mods:topic | mods:geographic | mods:temporal | mods:genre | mods:occupation] ">
             <dc:subject>
                 <xsl:for-each select="*" >
                      <xsl:if test="position()!=1">--</xsl:if>
                      <xsl:value-of select="."/>
                 </xsl:for-each>
             </dc:subject>

             <xsl:if test="mods:geographic">
                 <dc:coverage>
                 <xsl:for-each select="mods:geographic" >
                     <xsl:if test="position()!=1">--</xsl:if>
                     <xsl:value-of select="." />
                 </xsl:for-each>
                 </dc:coverage>
             </xsl:if>
            
             <xsl:for-each select="mods:temporal">
                 <dc:coverage><xsl:value-of select="."/></dc:coverage>
             </xsl:for-each>
             
        </xsl:template>


	<xsl:template match="mods:subject[mods:hierarchicalGeographic | mods:cartographics] ">
		<xsl:for-each select="mods:hierarchicalGeographic">
			<dc:coverage>
				<xsl:for-each
					select="mods:continent|mods:country|mods:provence|mods:region|mods:state|mods:territory|mods:county|mods:city|mods:island|mods:area">
					<xsl:value-of select="."/>
					<xsl:if test="position()!=last()">--</xsl:if>
				</xsl:for-each>
			</dc:coverage>
		</xsl:for-each>

		<xsl:for-each select="mods:cartographics/*">
			<dc:coverage>
				<xsl:value-of select="."/>
			</dc:coverage>
		</xsl:for-each>
	</xsl:template>

        <xsl:template match="mods:subject[mods:titleInfo]">
	        <dc:subject>
			<xsl:value-of select="mods:titleInfo/mods:title"/>
		</dc:subject>
	</xsl:template>

        <xsl:template match="mods:subject[mods:name]">
                <xsl:for-each select="mods:name">
                <dc:subject>
			<xsl:call-template name="name"/>
                </dc:subject>
                </xsl:for-each>
        </xsl:template>


	<xsl:template match="mods:abstract | mods:tableOfContents | mods:note">
		<dc:description>
		   <xsl:if test="@displayLabel"><xsl:value-of select="./@displayLabel"/>: </xsl:if>
	           <xsl:value-of select="."/>
		</dc:description>
	</xsl:template>

	<xsl:template match="mods:originInfo">
		

                <xsl:choose>
		   <xsl:when test="mods:publisher and mods:place" >
		      <dc:publisher>
                         <xsl:value-of select="mods:place/mods:placeTerm" />: <xsl:value-of select="mods:publisher"/>    
	              </dc:publisher>
		   </xsl:when>
                   <xsl:when test="mods:publisher" >
                      <dc:publisher>
                         <xsl:value-of select="mods:publisher" />
                      </dc:publisher>
                   </xsl:when>
                   <xsl:when test="mods:place" >
                       <dc:publisher>Place of publication: <xsl:value-of select="mods:place/mods:placeTerm" />
                       </dc:publisher>
                   </xsl:when>
                   <xsl:otherwise />      
		</xsl:choose>

                <xsl:if test="mods:frequency != ''">
                  <dc:description>Frequency: <xsl:value-of select="mods:frequency" /></dc:description>
                </xsl:if>

                
                <xsl:choose>
                   <xsl:when test="mods:dateCreated" >
                       <xsl:choose>
                          <xsl:when test="mods:dateCreated[@point='start']">
                              <dc:date>
		              <xsl:value-of select="mods:dateCreated[@point='start']"/>-<xsl:value-of select="mods:dateCreated[@point='end']"/>
			      </dc:date>
                          </xsl:when>
                          <xsl:otherwise>
                              <dc:date>
                              <xsl:value-of select="mods:dateCreated" />
                              </dc:date>
                          </xsl:otherwise>
                        </xsl:choose>
                   </xsl:when>
                   <xsl:otherwise/>
                </xsl:choose>
              
                <xsl:choose>
                 <xsl:when test="mods:dateIssued">
                     <xsl:choose>
                          <xsl:when test="/mods:mods/mods:originInfo/mods:dateCreated" >
                              <xsl:choose>
                                 <xsl:when test="mods:dateIssued[@point='start']">
                                     <dc:description>Date issued: <xsl:value-of select="mods:dateIssued[@point='start']"/>-<xsl:value-of select="mods:dateIssued[@point='end']"/></dc:description>
                                 </xsl:when>
                                 <xsl:otherwise>
                                     <dc:description>
                                          <xsl:value-of select="mods:dateIssued"/>
                                     </dc:description>
                                 </xsl:otherwise>
                              </xsl:choose>
                          </xsl:when> 
                          <xsl:otherwise>  <!-- if no dateCreated -->
                              <xsl:choose>
                                  <xsl:when test="mods:dateIssued[@point='start']">
                                      <dc:date>
                                          <xsl:value-of select="mods:dateIssued[@point='start']"/>-<xsl:value-of select="mods:dateIssued[@point='end']"/>
                                      </dc:date>
                                  </xsl:when>
                                  <xsl:otherwise>
                                      <dc:date>
                                          <xsl:value-of select="mods:dateIssued" />
                                      </dc:date>
                                  </xsl:otherwise>
                             </xsl:choose>
                
                          </xsl:otherwise>
                     </xsl:choose>
                 </xsl:when>
              </xsl:choose>

              <xsl:choose>
                 <xsl:when test="mods:copyrightDate">
                     <xsl:choose>
                          <xsl:when test="/mods:mods/mods:originInfo/mods:dateCreated or /mods:mods/mods:originInfo/mods:dateIssued" >
                              <xsl:choose>
                                 <xsl:when test="mods:copyrightDate[@point='start']">
                                     <dc:description>Copyright date: <xsl:value-of select="mods:copyrightDate[@point='start']"/>-<xsl:value-of select="mods:copyrightDate[@point='end']"/></dc:description>
                                 </xsl:when>
                                 <xsl:otherwise>
                                     <dc:description>Copyright date: <xsl:value-of select="mods:copyrightDate"/></dc:description>
                                 </xsl:otherwise>
                              </xsl:choose>
                          </xsl:when> 
                          <xsl:otherwise>  <!-- if no dateCreated or dateIssued -->
                              <xsl:choose>
                                  <xsl:when test="mods:copyrightDate[@point='start']">
                                      <dc:date>
                                          <xsl:value-of select="mods:copyrightDate[@point='start']"/>-<xsl:value-of select="mods:copyrightDate[@point='end']"/>
                                      </dc:date>
                                  </xsl:when>
                                  <xsl:otherwise>
                                      <dc:date>
                                          <xsl:value-of select="mods:copyrightDate" />
                                      </dc:date>
                                  </xsl:otherwise>
                             </xsl:choose>
                
                          </xsl:otherwise>
                     </xsl:choose>
                 </xsl:when>
              </xsl:choose>

              <xsl:choose>
                 <xsl:when test="mods:dateOther">
                     <xsl:choose>
                          <xsl:when test="/mods:mods/mods:originInfo/mods:dateCreated or /mods:mods/mods:originInfo/mods:dateIssued or /mods:mods/mods:originInfo/mods:copyrightDate" >
                              <xsl:choose>
                                 <xsl:when test="mods:dateOther[@point='start']">
                                     <dc:description>Other date: <xsl:value-of select="mods:dateOther[@point='start']"/>-<xsl:value-of select="mods:dateOther[@point='end']"/></dc:description>
                                 </xsl:when>
                                 <xsl:otherwise>
                                     <dc:description>Other date: <xsl:value-of select="mods:dateOther"/></dc:description>
                                 </xsl:otherwise>
                              </xsl:choose>
                          </xsl:when> 
                          <xsl:otherwise>  <!-- if no dateCreated, dateIssued, or copyrightDate -->
                              <xsl:choose>
                                  <xsl:when test="mods:dateOther[@point='start']">
                                      <dc:date>
                                          <xsl:value-of select="mods:dateOther[@point='start']"/>-<xsl:value-of select="mods:dateOther[@point='end']"/>
                                      </dc:date>
                                  </xsl:when>
                                  <xsl:otherwise>
                                      <dc:date>
                                          <xsl:value-of select="mods:dateOther" />
                                      </dc:date>
                                  </xsl:otherwise>
                             </xsl:choose>
                
                          </xsl:otherwise>
                     </xsl:choose>
                 </xsl:when>
              </xsl:choose>
          
              <xsl:if test="mods:dateCaptured">
                  <xsl:choose>
                      <xsl:when test="mods:dateCaptured[@point='start']">
                          <dc:description>Capture date: <xsl:value-of select="mods:dateCaptured[@point='start']"/>-<xsl:value-of select="mods:dateCaptured[@point='end']"/></dc:description>
                       </xsl:when>
                       <xsl:otherwise>
                           <dc:description>Capture date: <xsl:value-of select="mods:dateCaptured"/></dc:description>
                       </xsl:otherwise>
                   </xsl:choose>
               </xsl:if> 

               <xsl:if test="mods:dateValid">
                  <xsl:choose>
                      <xsl:when test="mods:dateValid[@point='start']">
                          <dc:description>Date valid: <xsl:value-of select="mods:dateValid[@point='start']"/>-<xsl:value-of select="mods:dateValid[@point='end']"/></dc:description>
                       </xsl:when>
                       <xsl:otherwise>
                           <dc:description>Date valid: <xsl:value-of select="mods:dateValid"/></dc:description>
                       </xsl:otherwise>
                   </xsl:choose>
               </xsl:if> 


               <xsl:if test="mods:dateModified">
                  <xsl:choose>
                      <xsl:when test="mods:dateModified[@point='start']">
                          <dc:description>Modification date: <xsl:value-of select="mods:dateModified[@point='start']"/>-<xsl:value-of select="mods:dateModified[@point='end']"/></dc:description>
                       </xsl:when>
                       <xsl:otherwise>
                           <dc:description>Date modified: <xsl:value-of select="mods:dateModified"/></dc:description>
                       </xsl:otherwise>
                   </xsl:choose>
               </xsl:if> 

	</xsl:template>   <!-- originInfo -->

	<xsl:template name="startEnd">
		<dc:date>
			<xsl:choose>
				<xsl:when test="@point='start'">
					<xsl:value-of select="."/>
					<xsl:text> - </xsl:text>
				</xsl:when>
				<xsl:when test="@point='end'">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</dc:date>
	</xsl:template>


	<xsl:template match="mods:genre">
		<xsl:choose>
			<xsl:when test="@authority='dct'">
				<dc:type>
					<xsl:value-of select="."/>
				</dc:type>
				<xsl:for-each select="mods:typeOfResource">
					<dc:type>
						<xsl:value-of select="."/>
					</dc:type>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<dc:type>
					<xsl:value-of select="."/>
				</dc:type>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:typeOfResource">
		<xsl:if test="@collection='yes'">
			<dc:type>Collection</dc:type>
		</xsl:if>
		<xsl:if test=". ='software' and ../mods:genre='database'">
			<dc:type>DataSet</dc:type>
		</xsl:if>
		<xsl:if test=".='software' and ../mods:genre='online system or service'">
			<dc:type>Service</dc:type>
		</xsl:if>
		<xsl:if test=".='software'">
			<dc:type>Software</dc:type>
		</xsl:if>
		<xsl:if test=".='cartographic material'">
			<dc:type>Image</dc:type>
		</xsl:if>
		<xsl:if test=".='multimedia'">
			<dc:type>InteractiveResource</dc:type>
		</xsl:if>
		<xsl:if test=".='moving image'">
			<dc:type>MovingImage</dc:type>
		</xsl:if>
		<xsl:if test=".='three-dimensional object'">
			<dc:type>PhysicalObject</dc:type>
		</xsl:if>
		<xsl:if test="starts-with(.,'sound recording')">
			<dc:type>Sound</dc:type>
		</xsl:if>
		<xsl:if test=".='still image'">
			<dc:type>StillImage</dc:type>
		</xsl:if>
		<xsl:if test=". ='text'">
			<dc:type>Text</dc:type>
		</xsl:if>
		<xsl:if test=".='notated music'">
			<dc:type>Text</dc:type>
		</xsl:if>
	</xsl:template>

	<xsl:template match="mods:physicalDescription">
		<xsl:if test="mods:extent">
			<dc:format>
				<xsl:value-of select="mods:extent"/>
			</dc:format>
		</xsl:if>
		<xsl:if test="mods:form">
			<dc:format>
				<xsl:value-of select="mods:form"/>
			</dc:format>
		</xsl:if>
		<!-- note: removed test for mods:internetMediaType here -->
	</xsl:template>

	<xsl:template match="mods:mimeType">
		<dc:format>
			<xsl:value-of select="."/>
		</dc:format>
	</xsl:template>

	<xsl:template match="mods:identifier">
            <xsl:variable name="idtype" select="@type" />
            <dc:identifier><xsl:if test='string-length($idtype)>0'>(<xsl:value-of select="$idtype" />) </xsl:if><xsl:value-of select="."/></dc:identifier>
	</xsl:template>

	<xsl:template match="mods:location">
		<xsl:for-each select="mods:url"><dc:identifier>(URL) <xsl:value-of select="."/></dc:identifier>
		</xsl:for-each>	
	</xsl:template>

	<xsl:template match="mods:language">
            <xsl:for-each select="mods:languageTerm">
		<dc:language>
			<xsl:value-of select="normalize-space(.)"/>
		</dc:language>
            </xsl:for-each>
	</xsl:template>

	<xsl:template match="mods:relatedItem[mods:titleInfo | mods:name | mods:identifier | mods:location]">
		<xsl:choose>
			<xsl:when test="@type='original'">
				<dc:source>
					<xsl:for-each
						select="mods:titleInfo/mods:title | mods:identifier | mods:location/mods:url">
						<xsl:if test="normalize-space(.)!= ''">
							<xsl:value-of select="."/>
							<xsl:if test="position()!=last()">--</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</dc:source>
			</xsl:when>
			<xsl:when test="@type='series'"/>
			<xsl:otherwise>
				<dc:relation>
					<xsl:for-each
						select="mods:titleInfo/mods:title | mods:identifier | mods:location/mods:url">
						<xsl:if test="normalize-space(.)!= ''">
							<xsl:value-of select="."/>
							<xsl:if test="position()!=last()">--</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</dc:relation>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:accessCondition">
		<dc:rights>
			<xsl:value-of select="."/>
		</dc:rights>
	</xsl:template>

	<xsl:template name="name">
		<xsl:variable name="name">
			<xsl:for-each select="mods:namePart[not(@type)]">
				<xsl:value-of select="."/>
				<xsl:text> </xsl:text>
			</xsl:for-each>
			<xsl:value-of select="mods:namePart[@type='family']"/>
			<xsl:if test="mods:namePart[@type='given']">
				<xsl:text>, </xsl:text>
				<xsl:value-of select="mods:namePart[@type='given']"/>
			</xsl:if>
			<xsl:if test="mods:namePart[@type='date']">
				<xsl:text>, </xsl:text>
				<xsl:value-of select="mods:namePart[@type='date']"/>
				<xsl:text/>
			</xsl:if>
			<xsl:if test="mods:displayForm">
				<xsl:text> (</xsl:text>
				<xsl:value-of select="mods:displayForm"/>
				<xsl:text>) </xsl:text>
			</xsl:if>
			<xsl:for-each select="mods:role[mods:roleTerm[@type='text']!='creator']">
				<xsl:text> (</xsl:text>
				<xsl:value-of select="normalize-space(.)"/>
				<xsl:text>) </xsl:text>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="normalize-space($name)"/>
	</xsl:template>

	<xsl:template match="mods:dateIssued[@point='start'] | mods:dateCreated[@point='start'] | mods:dateCaptured[@point='start'] | mods:dateOther[@point='start'] ">
		<xsl:variable name="dateName" select="local-name()"/>
			<dc:date>
				<xsl:value-of select="."/>-<xsl:value-of select="../*[local-name()=$dateName][@point='end']"/>
			</dc:date>
	</xsl:template>
	
	<xsl:template match="mods:temporal[@point='start']  ">
		<xsl:value-of select="."/>-<xsl:value-of select="../mods:temporal[@point='end']"/>
	</xsl:template>
	
	<xsl:template match="mods:temporal[@point!='start' and @point!='end']  ">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<!-- suppress all else:-->
	<xsl:template match="*"/>
		

	
</xsl:stylesheet>

