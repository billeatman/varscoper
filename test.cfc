<cfcomponent extends="commandbox.system.BaseCommand">

<cfset variables.totalFiles = 0>
<cfset variables.totalMethods = 0>

<cfscript>
	function CSVFormat(col){
				/* Look for quotes */
				if (Find("""", col)) {
					return_string = """" & Replace(col, """", """""", "All") & """";
				} //if
				/* Look for spaces */
				else if (Find(" ", col)) {
					return_string = """" & col & """";
				} //else if
				/* Look for commans */
				else if (Find(",", col)) {
					return_string = """" & col & """";
				} //else if
				else {
					return_string = col;
				} //else
				return return_String;
			}
</cfscript>

<cffunction name="processDirectory" hint="used to traverse a directory structure">
	<cfargument name="startingDirectory" type="string" required="true">
	<cfargument name="recursive" type="boolean" required="false" default="false">
	
	<cfset var fileQuery = "" />
	<cfset var scoperFileName = "" />
	<cfset var xmlDoc = "" />
	<cfset var xmlDocData = "" />
	<cfset var directoryexcludelistXML = arrayNew(1) />
	<cfset var directoryexcludelist = "" />
	<cfset var fileexcludelistXML = arrayNew(1) />
	<cfset var fileexcludelist = "" />
	<cfset var pathsep = "\" />
	
	<!--- get properties --->
	<cfif fileExists("#getDirectoryFromPath(getCurrentTemplatePath())#properties.xml")>

		<!--- read xml file --->
		<cffile action="read" file="#getDirectoryFromPath(getCurrentTemplatePath())#properties.xml" variable="xmlDocData">

		<!--- get file to parse --->
		<cfset xmlDoc = XmlParse(xmlDocData) />
		
		<!--- get directory exclusion list --->
		<cfset directoryexcludelistXML = XmlSearch(xmlDoc, "/properties/directoryexcludelist") />
		<!--- if array size GT 0 the get the value --->
		<cfif arrayLen(directoryexcludelistXML) GT 0>
			<cfset directoryexcludelist = trim(directoryexcludelistXML[1].XmlText) />
		</cfif>
		
		<!--- get file exclusion list --->
		<cfset fileexcludelistXML = XmlSearch(xmlDoc, "/properties/fileexcludelist") />
		<!--- if array size GT 0 the get the value --->
		<cfif arrayLen(fileexcludelistXML) GT 0>
			<cfset fileexcludelist = trim(fileexcludelistXML[1].XmlText) />
		</cfif>
	</cfif>
		
	<cfdirectory directory="#arguments.startingDirectory#" name="fileQuery"  >
	<cfloop query="fileQuery">
		<cfset scoperFileName = "#arguments.startingDirectory##pathsep##name#" />
		<cfset fileInfo = getFileInfo(scoperFileName)>

		<!--- check to see if we want to exclude the diretory or file (from properties file) --->
		<cfif fileInfo.type IS "directory">
<!---			<cfset print.line(scoperFileName).toConsole()> --->
			<cfif arguments.recursive EQ true>
				<cfset processDirectory(startingDirectory:scoperFileName, recursive:true) />			
			</cfif>
		<cfelseif NOT listFindNoCase(directoryExcludeList, listLast(replace(arguments.startingDirectory, "\", "/", "ALL"), pathsep))
			AND NOT listFindNoCase(fileExcludeList, "#name#") AND (findNoCase('.cfc', scoperFileName, len(scoperfileName) - 4) OR findNoCase('.cfm', scoperFileName, len(scoperfileName) - 4)) 
			>
<!---			<cfset print.greenline(scoperFileName).toConsole()> --->
				
<!---			<cftry> --->
				<cfif NOT fileExists(scoperFileName)>
					<cfthrow type="noFile">
				</cfif>
				
				<cffile action="read" file="#scoperFileName#" variable="fileParseText">
				
				<cfset showDuplicates = FALSE >
				<cfset showLineNumbers = TRUE >				
				<cfset parseCfscript = TRUE >
			
				<cfset varscoper = createObject("component","varScoper").init(fileParseText:fileParseText,showDuplicates:showDuplicates,showLineNumbers:showLineNumbers,parseCfscript:parseCfscript) />
				<!--- <cftimer label="Scope Checking Execution" type="comment"> --->
				<cfset varscoper.runVarscoper() />
				<!--- </cftimer> --->

				<cfparam name="variables.totalMethods" default="0">
				<cfset variables.totalMethods = variables.totalMethods + structCount(varscoper.getResultsStruct()) />
			
				<cfset displayFormat = "screen" />

				<cfset variables.totalFiles = variables.totalFiles + 1 />
		
				<cfset csvData="">
				<cfset csvRow="">

				<cfset currentFileName = scoperFileName />
				<cfset scoperResults = varscoper.getResultsArray() />

				<cfset newLine = Chr(13)&Chr(10)>

				<cfloop from="1" to="#arrayLen(scoperResults)#" index="scoperIdx">
					<cfset tempUnscopedArray = scoperResults[scoperIdx].unscopedArray />
					<cfif NOT ArrayIsEmpty(tempUnscopedArray)>	
						<cfloop from="1" to="#arrayLen(tempUnscopedArray)#" index="unscopedIdx">				
							<cfscript>
								print.line("");
								print.redline(currentFileName);
								print.greyline("  Function: " & scoperResults[scoperIdx].functionName);
								if (structKeyExists(scoperResults[scoperIdx],"LineNumber")) {
									print.greyline("    Line ##: " & scoperResults[scoperIdx].LineNumber);
								} 
								print.greyline("  Variable: " & tempUnscopedArray[unscopedIdx].VariableName);
								if (structKeyExists(scoperResults[scoperIdx],"LineNumber")) {
									print.greyline("    Line ##: " & tempUnscopedArray[unscopedIdx].LineNumber);
								}
								print.greyline("    " & tempUnscopedArray[unscopedIdx].VariableContext);
							</cfscript>
							<!---<cfset csvRow = "" />
							<cfset csvRow = listAppend(csvRow,CSVFormat(currentFileName))>
							<cfset csvRow = listAppend(csvRow,CSVFormat(scoperResults[scoperIdx].functionName))>
							<cfif structKeyExists(scoperResults[scoperIdx],"LineNumber")>
								<cfset csvRow = listAppend(csvRow,CSVFormat(scoperResults[scoperIdx].LineNumber))>
							<cfelse>
								<cfset csvRow = listAppend(csvRow,CSVFormat(0))>
							</cfif>			
							<cfset csvRow = listAppend(csvRow,CSVFormat(tempUnscopedArray[unscopedIdx].VariableName))>

							<cfif structKeyExists(tempUnscopedArray[unscopedIdx],"LineNumber")>
								<cfset csvRow = listAppend(csvRow,CSVFormat(tempUnscopedArray[unscopedIdx].LineNumber))>
							<cfelse>
								<cfset csvRow = listAppend(csvRow,CSVFormat(0))>
							</cfif>
							<cfset csvRow = listAppend(csvRow,CSVFormat(tempUnscopedArray[unscopedIdx].VariableContext))>
							<cfset csvData="#csvData##csvRow##newLine#">
							--->
						</cfloop>			
					</cfif>
				</cfloop>

<!---				<cfset print.greyline(csvData) > --->

<!---
				<cfcatch type="noFile">
					<cfset print.redLine("No file exists for the path specified (#htmlEditFormat(scoperFileName)#)")>
					<cfset print.redLine(scoperFileName)>
				</cfcatch>
				<cfcatch type="functionWithoutName">
					<cfset print.redLine("There was a parsing error with one of the functions - the function did not have a name, exiting processing")>
					<cfset print.redLine(scoperFileName)>
				</cfcatch>
				<cfcatch type="any">
					<cfset print.redline("#cfcatch#")>
					<cfset print.redLine(scoperFileName)>
				</cfcatch>
			</cftry>
--->
		<cfelse>
				<cfset print.text('.').toConsole()>
<!---			<cfset print.yellowline(scoperFileName).toConsole()> --->
		</cfif>	
		
	</cfloop>
</cffunction>

<cfscript>
	
function run(){
	print.greenLine(fileSystemUtil.resolvePath(getCWD()));
	
	processDirectory(fileSystemUtil.resolvePath(getCWD()), true);
	return;
}


</cfscript>

</cfcomponent>
