(
-- Set debuging to 0 (off) state and define the node struct beeing used in this relinker
-- ****************************************************************************		
XRefAssetResolverDebug = 0	
Struct theNode ( filePath, nodeLevel = 1, nodeDetails = #(), assetsList = #(), nodeChildren = #() )
	
-- ****************************************************************************
-- *******   THE HDD READ FUNCTIONS	
-- ****************************************************************************	
-- Initialize the TreeBased data model and load 'root node' asset info and xrefs
-- ****************************************************************************	
fn createDependencyTree theRootNode = 
(  	
	if doesfileexist theRootNode.filePath then (
		theRecursiveLoader theRootNode
	)
	else (
		format "CRITICAL ERROR: The main scene file does not exists or could not been opened for read/wrtite.\n FILEPATH:: %\n" theSourceFile
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
-- *******   THE HDD WRITE METEADATA FUNCTIONS	
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
-- Write the changes to HDD drive -- Whole one XRef-file
-- ****************************************************************************
fn writeUpdatedNode myNode = (
	writeUpdatedAssets myNode
	writeUpdatedXRefs myNode	
)
-- ****************************************************************************
-- Write the changes to HDD drive -- the assets only;]
-- ****************************************************************************
fn writeUpdatedAssets myNode = (
	if doesfileexist myNode.filePath do
		setMAXFileAssetMetadata myNode.filePath myNode.assetsList 
)
-- ****************************************************************************
-- Write the changes to HDD drive -- the XrefFiles info only
-- ****************************************************************************
fn writeUpdatedXRefs myNode = (
	if doesfileexist myNode.filePath then
	(
		if myNode.nodeChildren.size > 0 then
		(
			temp=#();
			for pt in myNode.nodeChildren do
			(
				appendIfUnique temp pt.nodeDetails
			)	
			setMAXFileAssetMetadata myNode.filePath temp							
		)
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

theSourceFile = @"C:\Users\milos\Desktop\xRefScript\mainScene.max"
	
myMainNode = theNode theSourceFile 0			-- create main (the root) node item and set file path to theSourceFile
createDependencyTree myMainNode				-- create full dependency list on TreeBased stgruct 

-- CHANGE THE FILE PATHS AND CONSTRAINS HERE
-- TO-DO !!

writeUpdatedTree myMainNode 	-- save meta data back 

-- ADD HDD FILES COPY FUNCTION with eventual TheNode.filePath update
-- INFO: Is it beeing done by the RenderBeamer?

)








