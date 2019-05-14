(
-- Set debuging to 0 (off) state and define the node struct beeing used in this relinker
-- ****************************************************************************		
XRefAssetResolverDebug = 1
ct = 1	
Struct theNode ( filePath, nodeLevel = 1, nodeDetails = #(), assetsList = #(), nodeChildren = #() )
	
-- ****************************************************************************
-- *******   THE HDD READ FUNCTIONS	
-- ****************************************************************************
-- READ and DISPLAY IF NEEDED all avalible info on one nodes assets
-- ****************************************************************************	
fn listAssetsRecurency myNode = 
	(		
		if doesfileexist myNode.filePath then
		(
			-- CAN DELATE IT -> IT IS DECORATION ONLY
			if XRefAssetResolverDebug != 0 then (
				thisSpace =" "
				thisStar ="*"
				for i = 0 to myNode.nodeLevel do (
					append thisSpace "  "
					append thisStar "**"
				)			
				if myNode.nodeLevel == 0 then (
					format "** THE ROOT NODE (Level 0 node)\n"
					format "** FILE: %\n" myNode.filePath
				)
				else (
					format "% THE CHILD NODE (Level % node) ::\n" (thisStar as string) myNode.nodeLevel
					format "% ID: %   TYPE: %   FILE: %\n" (thisStar as string) (myNode.nodeDetails.assetId) (myNode.nodeDetails.type) (getFilenameFile myNode.nodeDetails.filename)
					format "% FILE: %\n" (thisStar as string) (myNode.filePath) 
				)
			)
			-- END OF CAN DELATE IT -> IT IS DECORATION ONLY
			
			local tempList = getMAXFileAssetMetadata myNode.filePath		
			for theItem in tempList do
			(
				local theType = theItem.type as string
			
				if stricmp theType "xref" == 0 then
				(
					tmp = theNode (theItem.resolvedFilename) (myNode.nodeLevel+1) theItem
					append myNode.nodeChildren tmp
				)
				else
				(
					append myNode.assetsList theItem
					if XRefAssetResolverDebug == 1 then ( format "%ID:%     TYPE: %\n%   orgPath.....: %%%\n%   resolvedPath: %\n" (thisSpace as string) theItem.assetId theItem.type (thisSpace as string) (getFilenamePath theItem.filename) (getFilenameFile theItem.filename) (getFilenameType theItem.filename) (thisSpace as string) theItem.resolvedFilename )
				)			
			)
		)
		else
		(
			format "WARNING:: The XRef file was omitted. \n FILEPATH:: %\n" myNode.filePath
		)
	)
-- ****************************************************************************
-- READ and DISPLAY IF NEEDED all avalible info on one node, and step through all child items
-- ****************************************************************************	
fn theRecursiveLoader myNode =
	(
		listAssetsRecurency myNode		
		for nodeItem in myNode.nodeChildren do
		(
			theRecursiveLoader nodeItem
		)
	)		
-- ****************************************************************************	
-- Initialize the TreeBased data model and load 'root node' asset info and xrefs
-- ****************************************************************************	
fn createDependencyTree theRootNode = 
(  	
	if doesfileexist theRootNode.filePath then 
	(
		theRecursiveLoader theRootNode
	)
	else (
		format "CRITICAL ERROR: The main scene file does not exists or could not been opened for read/wrtite.\n FILEPATH:: %\n" theRootNode.filePath
	)
)
-- ****************************************************************************
-- *******   THE HDD WRITE METEADATA FUNCTIONS	
-- ****************************************************************************
-- Write the changes to HDD drive -- the assets only;]
-- ****************************************************************************
fn writeUpdatedAssets myNode = (
	if doesfileexist myNode.filePath do
	(
		setMAXFileAssetMetadata myNode.filePath myNode.assetsList
	)
)
-- ****************************************************************************
-- Write the changes to HDD drive -- the XrefFiles info only
-- ****************************************************************************
fn writeUpdatedXRefs myNode = (
	if doesfileexist myNode.filePath then
	(
		temp=#();
		for pt in myNode.nodeChildren do
		(
			appendIfUnique temp pt.nodeDetails
		)	
		setMAXFileAssetMetadata myNode.filePath temp							
	)
)
-- ****************************************************************************
-- Write the changes to HDD drive -- Whole one XRef-file
-- ****************************************************************************
fn writeUpdatedNode myNode = (
	writeUpdatedAssets myNode
	writeUpdatedXRefs myNode	
)
-- ****************************************************************************
-- WRITE WHOLE UPDATED TREE TO HDD
-- ****************************************************************************	
fn writeUpdatedTree myRootNode = (
	writeUpdatedNode myRootNode
	
	for pt in myRootNode.nodeChildren do (
		writeUpdatedTree pt;
	)
)

-- ****************************************************************************
-- *******   THE COPY AND UPDATE FUNCTIONS
-- ****************************************************************************
-- GENERATE UNIQUE XREF FILES LIST
-- ****************************************************************************	
fn generateXrefsList myRootNode theXrefsList = 
(
	appendIfUnique theXrefsList (myRootNode.filepath as string)
	
	for pt in myRootNode.nodeChildren do (
		generateXrefsList pt theXrefsList;
	)	
)
-- ****************************************************************************
-- GENERATE UNIQUE ASSETS FILES LIST
-- ****************************************************************************	
fn generateAssetsList myRootNode theAssetsList = 
(
	for pt in myRootNode.assetsList do (
		appendIfUnique theAssetsList (pt.resolvedFilename as string)
	)
	
	for pt in myRootNode.nodeChildren do (
		generateAssetsList pt theAssetsList;
	)	
)

-- ****************************************************************************
-- COPY AND RELINK FUNCTION
-- ****************************************************************************	
fn copyTheNode myNode xrefDir = (
	for theItem in myNode.assetsList do
		(
			if doesfileexist theItem.filename then
			(
				ct= ct+1
				tmp =  xrefDir + "\\" + (ct as string) + (filenameFromPath theItem.filename)
				copyFile theItem.filename tmp
				theItem.filename = (filenameFromPath theItem.filename)
				theItem.resolvedFilename = tmp
			)		
		)
	if doesfileexist myNode.filepath then
	(
		ct= ct+1
		tmp =  xrefDir + "\\" + (ct as string) + (filenameFromPath myNode.filepath)
		copyFile myNode.filepath tmp
		myNode.filepath = tmp
		
		if myNode.nodeDetails != undefined then
		(
			myNode.nodeDetails.filename = (filenameFromPath myNode.filepath)
			myNode.nodeDetails.resolvedFilename = tmp
		)
	)
)
-- ****************************************************************************
-- WRITE WHOLE UPDATED TREE TO HDD
-- ****************************************************************************	
fn copyTheTree myRootNode xrefDir = (
	copyTheNode myRootNode xrefDir
	
	for pt in myRootNode.nodeChildren do (
		copyTheTree pt xrefDir;
	)
)
-- ****************************************************************************
-- *******   MAIN LOGIC STARTS HERE	
-- ****************************************************************************
-- ****************************************************************************	
-- Struct theNode [			      		-- the node model implementation
----- string filePath			[no meta]	-- existing on HDD Xref file resolved filePath
----- integer nodeLevel 		[no meta]	-- (int) the level of recurance / the item in-tree hight
----- nodeDetails			[D][META]	--(data) the actual node informations			
----- assetsList			[D][META]	-- (list) actual node assets lists with paths
----- nodeChildren ]		     [META]	-- (list) actual node children xrefs 
-- ****************************************************************************
-- ******* [no meta] *** labeled items are for internal use only with no effect on meta-data
-- ******* [META]   *** labeled items will update meta-data on node saving  
-- ******* [D]         *** labeled are AssetMetadataStructDef ( assetId, type, filename, resolvedFilename )
-- ******* 		    *** (getFilenamePath) (getFilenameFile) (getFilenameType) 
-- ****************************************************************************

theSourceFile = @"C:\Users\milos\Desktop\xRefScript\mainScene.max"		-- the source file 
theNewXRefsDir = "d:\\_____"																	-- new directory with dependencies

myMainNode = theNode theSourceFile 0			-- create main (the root) node item and set file path to theSourceFile
createDependencyTree myMainNode				-- create full dependency list on TreeBased stgruct 

makeDir theNewXRefsDir all:true				-- create dir if it doesn't exist
copyTheTree myMainNode theNewXRefsDir			-- tree copy the xrefs and asse4ts
writeUpdatedTree myMainNode				-- tree write updated paths to copied assets

-- For checking only - lists all dependencies in new location
myMainNodeCopy = theNode myMainNode.filePath 0
createDependencyTree myMainNodeCopy

-- TO-DO:  unique copy files. Now there can be many same-files copied

--theXrefsList =#()
--generateAssetsList myMainNode theXrefsList 
--generateXrefsList myMainNode theXrefsList 
--for pt in theXrefsList do
--(
	--format "path: %\n" pt
--)

)
