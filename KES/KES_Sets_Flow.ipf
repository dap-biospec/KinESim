// Copyright © 2019, Denis A. Proshlyakov, dapro@chemistry.msu.edu
// This file is part of Kin-E-Sim project. 
// For citation, attribution and illustrations see <https://pubs.acs.org/doi/10.1021/acs.analchem.9b00859> 
//
// Kin-E-Sim is free software: you can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 3 as published by the Free Software Foundation.
//
// Kin-E-Sim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied 
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with this file.  If not, see <https://www.gnu.org/licenses/>.


#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma version = 20190711
#pragma ModuleName = KES_Sets
#pragma hide=1


//-----------------------------------------------
// default prep of the simSet, called once; specific handing can be done after by template function
//
function simSetPrepData(jobListW, setData, entries, prefix, [justOne]) 
	wave /T jobListW;
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &entries;
	string prefix;
	variable justOne; 
	
	if (paramIsDefault(justOne))
		justOne = 0
	endif
	
	setData.commName =prefix+jobListW[0]; 	
	setData.text = ""; // initialize to avoid errors
	
	wave setData.JParWave = $jobListW[1];
	if (!waveexists(setData.JParWave))
		setData.text = "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 

	wave setData.MWave = $jobListW[2];
	if (!waveexists(setData.MWave))
		setData.text = "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 

	wave setData.PWave = $jobListW[3];
	if (!waveexists(setData.PWave))
		setData.text = "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 

	wave setData.CWave = $ jobListW[4];
	if (!waveexists(setData.CWave))
		setData.text = "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 

	wave /WAVE setData.ERxnsW = $ jobListW[5];
	wave /WAVE setData.GRxnsW = $ jobListW[6];

	setData.rootFldr = GetDataFolder(1);
	setData.dataFldr = setData.rootFldr +"SimData:"; 
	
	variable setLen;
	if (justOne) 
		setLen = 1; 
	else
		setLen =  setData.JParWave[4];
		if (setLen <= 1)
			setLen = 1;
			setData.JParWave[4] = 1;
		endif
	endif

	setData.BiDir = setData.PWave[1] ;
	if (setData.BiDir != 0 )
		setData.BiDir = 1;
		setData.PWave[1] = 1;
	endif 
	
	string setValueClbN = setData.rootFldr+setData.commName + "_SetClb";	
	make /N=(setLen) /O $setValueClbN
	wave setData.setValueClb = $setValueClbN
	

	NewDataFolder /O SimData 
	SetDataFolder $(setData.dataFldr) 
	
	variable doLog = setData.PWave[4];
	
	variable i, s;
	for (i=0, s=0; i<setLen; s+=1, i +=  setData.BiDir ? 0.5 : 1)
		variable theDir = setData.BiDir *  (floor(i)==i ? 1 : -1); // 0 or integer 
		string fmtStr
		string thisSimName
		if (justOne)
			if (theDir > 0)
				thisSimName = setData.commName+"f"
			elseif (theDir < 0) 
				thisSimName = setData.commName+"r"
			else
				thisSimName = setData.commName
			endif
		else
			if (theDir > 0)
				fmtStr = "%s%02df"
			elseif (theDir < 0) 
				fmtStr = "%s%02dr"
			else
				fmtStr = "%s%02d"
			endif
			
			sprintf thisSimName fmtStr  setData.commName, i
		endif
		
		entries.sims[s].name=thisSimName;
		
		// default param waves; specific setup function can override these references
		wave entries.sims[s].PWave = setData.PWave;
		wave entries.sims[s].CWave = setData.CWave;
		wave entries.sims[s].ERxnsW = setData.ERxnsW;
		wave entries.sims[s].GRxnsW = setData.GRxnsW;
		wave entries.sims[s].MWave = setData.MWave;
		if (doLog > 0)
			make /O /N=(0,0) $thisSimName+"_log";
			WAVE entries.sims[s].LogWave=$thisSimName+"_log";
		else
			WAVE entries.sims[s].LogWave=$"";
//			entries.sims[s].LogMode = 0;
		endif
		entries.sims[s].LogMode = doLog;
		
		
		// is simW already prepared? Save it here...
		entries.sims[s].direction = theDir;
		entries.sims[s].index = s;
		entries.sims[s].group = floor(i);

		entries.sims[s].text = "";
		entries.sims[s].result = NaN;
		
		// pass internal constant across module barrier 
		entries.sims[s].S_C_Offs =  KES#get_S_C_Offs(); // offset of 1st component in the SimWave
		entries.sims[s].S_C_Num =  KES#get_S_C_Num();  // number of parameters per component

	endfor
	
	entries.count = s;
	
	// zero out the rest...
	for (i=s; i<maxSims; i+=1)
		entries.sims[i].name ="";
		entries.sims[i].text = "";
		entries.sims[i].result = NaN;
		entries.sims[i].index = i;
		entries.sims[i].group = -1;
	endfor
	
	setData.error = -1;
end


//-----------------------------------------------
//

function simSet_PrepMethods(setData, jobListW, simM, setM, simMode, offset, prefix, [justOne])
	STRUCT simSetDataT &setData;
	wave /T jobListW;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	variable simMode;
	string offset, prefix;
	variable justOne

	variable sysNThreads = ThreadProcessorCount
	
	if (paramIsDefault(justOne))
		justOne = 0;
	endif

	// single sim methods
	//
	variable tgtThreads = setData.PWave[0];
	if (numType(tgtThreads)!=0)
		tgtThreads = 1;
	endif	
	switch (tgtThreads)
		case 0: // no threads
		case 1:
			simM.simNThreads = 1;
			break;
		case -1: // max up to nComp
			simM.simNThreads = min (dimsize(setData.CWave, 1), sysNThreads);
			break;			
		default: // up to physical threads
			simM.simNThreads = min (tgtThreads, sysNThreads);
	endswitch 

	// IM workaround
//	FUNCREF simWSetupProto simM.theSimWSetupFN = jobListW[7] ;  
	simM.theSimWSetupFN = jobListW[7] ; 
	if ( strlen(simM.theSimWSetupFN))
		FUNCREF simWSetupProto theSimWSetupF = $("ProcGlobal#"+simM.theSimWSetupFN)
		if (NumberByKey("ISPROTO", FuncRefInfo (theSimWSetupF)))
			setM.text = "== Reference to function \""+(simM.theSimWSetupFN)+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimWSetup = 1;
	endif

//	FUNCREF simWProcessProto simM.theSimWProcessF = $(jobListW[8]); 
	simM.theSimWProcessFN = jobListW[8]; 
	if ( strlen(simM.theSimWProcessFN))
		FUNCREF simWProcessProto theSimWProcessF = $("ProcGlobal#"+simM.theSimWProcessFN)
		if (NumberByKey("ISPROTO", FuncRefInfo (theSimWProcessF)))
			setM.text = "== Reference to function \""+(simM.theSimWProcessFN)+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimWProcess = 1;
	endif

	FUNCREF simPlotBuildProto simM.theSimPlotBuildF = $(jobListW[9]); 
	if ( strlen(jobListW[9]))
		if (NumberByKey("ISPROTO", FuncRefInfo (simM.theSimPlotBuildF)))
			setM.text = "== Reference to function \""+(jobListW[9])+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimPlotBuild = 1;
	endif

	string simStr = "";
	if (simM.doSimWSetup || simM.doSimWProcess || simM.doSimPlotBuild)
		simStr += "\r"+offset+"Method";
		if (simM.doSimWSetup)
			simStr += " setup:"+jobListW[7]+",";
		endif
		if (simM.doSimWProcess)
			simStr += " process:"+jobListW[8]+",";
		endif
		if (simM.doSimPlotBuild)
			simStr += " plot:"+jobListW[9]+",";
		endif
	endif 


	// set of sims methods....
	setM.text = "";
	setM.offset = offset;
	
	tgtThreads = setData.JParWave[1];
	
	if (numType(tgtThreads)!=0 || simM.simNThreads > 1)
		tgtThreads = 1;
	endif	

	switch (tgtThreads)
		case 0: // no threads
		case 1:
			setM.setNThreads = 0;
			break;
		case -1: // max number up to nSims		
			setM.setNThreads = setData.JParWave[4]; // set steps
			break;
		default: // use one thread per cmp
			setM.setNThreads = tgtThreads;
	endswitch 
	setM.setNThreads = min (setM.setNThreads, sysNThreads);
	

	if (!justOne)
		FUNCREF setInputSetupProto setM.theSetInSetupF = $(jobListW[11]);  
		if ( strlen(jobListW[11]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetInSetupF)))
				setM.text = "== Reference to function \""+(jobListW[11])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetInSetup = 1;
		endif
	
		FUNCREF setInputAssignProto setM.theSetInAssignF = $(jobListW[12]);  
		if ( strlen(jobListW[12]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetInAssignF)))
				setM.text = "== Reference to function \""+(jobListW[12])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetInAssign = 1;
		endif

		FUNCREF setResultSetupProto setM.theSetResultSetupF = $(jobListW[13]); 
		if ( strlen(jobListW[13]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultSetupF)))
				setM.text = "== Reference to function \""+(jobListW[13])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutSetup = 1;
		endif

		FUNCREF setResultAssignProto setM.theSetResultAssignF = $(jobListW[14]); 
		if ( strlen(jobListW[14]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultAssignF)))
				setM.text = "== Reference to function \""+(jobListW[14])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutAssign = 1;
		endif

		FUNCREF setResultCleanupProto setM.theSetResultCleanupF = $(jobListW[15]); 
		if ( strlen(jobListW[15]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultCleanupF)))
				setM.text = "== Reference to function \""+(jobListW[15])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutCleanup = 1;
		endif

		FUNCREF setPlotSetupProto setM.theSetPlotSetupF = $(jobListW[16]); 
		if ( strlen(jobListW[16]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetPlotSetupF)))
				setM.text = "== Reference to function \""+(jobListW[16])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetPlotBuild = 1;
		endif

		FUNCREF setPlotAppendProto setM.theSetPlotAppendF = $(jobListW[17]);
		if ( strlen(jobListW[17]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetPlotAppendF)))
				setM.text = "== Reference to function \""+(jobListW[17])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetPlotAppend = 1;
		endif

		switch (simMode)
			case 0:
				if (!simM.doSimWSetup)
					setM.text = "Function that should prepare sumulation wave is not specified. Cannot continue... :-("	
					setData.error=0;
					return -1
				endif
				sprintf  setM.text "\r%s~~~~~~~~~~~~~~~~~~ Kin-E-Set %s %s ~~~~~~~~~~~~~~~~~~\r", offset, cKESSetsVer, prefix
				setM.modeName = "simulations";
				break;
			case 1:
				sprintf setM.text "%sProcessing a set from previous simulations ", offset
				setM.modeName = "processings"
				setM.doSetInSetup = 0;
				setM.doSetInAssign = 0;
				break;
			case 2:
				sprintf setM.text "%sAssmbly of a set from previous simulations ", offset;
				setM.doSetInSetup = 0;
				setM.doSetInAssign = 0;
				setM.doSetOutSetup = 0;
				setM.doSetOutAssign = 0;
				setM.doSetOutCleanup = 0;			
				break;
			case 3: // no re-processing
				return 0;
				break;
			default:
				sprintf setM.text"%sUknown flag %g! cannot continue", offset, simMode;
				return -1;
		endswitch
		string setStr = "";
		if (setM.doSetInSetup || setM.doSetInAssign)
			setStr += "\r"+offset+"Input";
			if (setM.doSetInSetup)
				setStr += " setup:"+jobListW[11]+",";
			endif
			if (setM.doSetInAssign)
				setStr += " assign:"+jobListW[12]+",";
			endif
		endif 
	
		if (setM.doSetOutSetup || setM.doSetOutAssign || setM.doSetOutCleanup)
			setStr += "\r"+offset+"Result: ";
			if (setM.doSetOutSetup)
				setStr += "setup:"+jobListW[13]+"; "
			endif 
			if (setM.doSetOutAssign)
				setStr +=  "assign:"+jobListW[14]+"; "
			endif
			if (setM.doSetOutCleanup)
				setStr +=  "cleanup:"+jobListW[15]+"; "
			endif
		endif
	
		if (setM.doSetPlotBuild || setM.doSetPlotAppend )
			setStr += "\r"+offset+"Plot: ";
			if (setM.doSetPlotBuild)
				setStr += "setup:"+jobListW[16]+"; "
			endif 
			if (setM.doSetPlotAppend)
				setStr +=  "append:"+jobListW[17]+"; "
			endif
		endif
		if (strlen(setStr) > 0) // there is a report
			setData.text = offset + setStr;	
		endif
		
	else // justOne
			switch (simMode)
			case 0:
				if (!simM.doSimWSetup)
					setM.text = "Function that should prepare sumulation wave is not specified. Cannot continue... :-("	
					setData.error=0;
					return -1
				endif
				sprintf  setM.text "\r%s~~~~~~~~~~~~~~~~~~ Kin-E-Sim %s %s ~~~~~~~~~~~~~~~~~~\r", offset, cKESSetsVer, prefix
				setM.modeName = "simulations";
				break;
			case 1:
				sprintf setM.text "%sProcessing data from previous simulations ", offset
				setM.modeName = "processings"
				break;
			case 2:
				sprintf setM.text "%sAssmbly of data from previous simulations ", offset;
				break;
			case 3: // no re-processing
				return 0;
				break;
			default:
				sprintf setM.text"%sUknown flag %g! cannot continue", offset, simMode;
				return -1;
		endswitch
		setM.doSetInSetup = 0;
		setM.doSetInAssign = 0;
		setM.doSetOutSetup = 0;
		setM.doSetOutAssign = 0;
		setM.doSetOutCleanup = 0;
		setM.doSetPlotBuild = 0;
		setM.doSetPlotAppend = 0;
	endif 
	setData.text  += "\r"+offset+"Output folder: "+setData.rootFldr;
end



//-----------------------------------------------
//

function simGroupPrepData(jobListW, setData, entries, prefix, sizeField, waveSuffix, FolderFmtStr) 
	wave /T jobListW;
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &entries;
	string prefix;
	variable sizeField  // in JParWave 
	string waveSuffix
	string FolderFmtStr
	
	
	setData.commName = jobListW[0];
	wave setData.JParWave = $jobListW[1];
	if (!waveexists(setData.JParWave))
		setData.text = "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 

	wave setData.MWave = $jobListW[2];
	if (!waveexists(setData.MWave))
		setData.text = "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 

	wave setData.PWave = $jobListW[3];
	if (!waveexists(setData.PWave))
		setData.text = "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 

	wave setData.CWave = $ jobListW[4];
	if (!waveexists(setData.CWave))
		setData.text = "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 

	wave /WAVE setData.ERxnsW = $ jobListW[5];
	wave /WAVE setData.GRxnsW = $ jobListW[6];
	
	variable setLen;
	if (dimsize(setData.JParWave, 0) < (sizeField+1)) 
		setLen = 1;
	elseif (setData.JParWave[sizeField] <=0)
		setData.JParWave[sizeField] = 1;
		setLen = 1
	else 
		setLen = setData.JParWave[sizeField];
	endif 
	
	setData.rootFldr = GetDataFolder(1);
	setData.dataFldr = ""; 

	string setValueClbN = setData.rootFldr+prefix+setData.commName + "_"+waveSuffix+"Clb";	
	make /N=(setLen) /O $setValueClbN
	wave setData.setValueClb = $setValueClbN
	
	variable s;
	for (s=0; s < setLen; s+=1)
		string thisFldrName
		sprintf thisFldrName FolderFmtStr,  s
		entries.sets[s].name=thisFldrName; 
		string thisPrefix = prefix + thisFldrName;
		
		NewDataFolder /O $thisFldrName
		string tgtPath = setData.rootFldr + thisFldrName+":";
		entries.sets[s].folder= tgtPath;

		wave /T setJobListW = $(childWCopy(nameofwave(jobListW), prefix, thisPrefix, tgtPath, $"", -1)); 
		wave /T entries.sets[s].JListWave = setJobListW

		// default param waves; specific setup function can override these references
		wave entries.sets[s].JParWave = $(childWCopy(nameofwave(setData.JParWave), prefix, thisPrefix, tgtPath, setJobListW, 1));
		wave entries.sets[s].MWave = $(childWCopy(nameofwave(setData.MWave), prefix, thisPrefix, tgtPath, setJobListW, 2));
		wave entries.sets[s].PWave = $(childWCopy(nameofwave(setData.PWave), prefix, thisPrefix, tgtPath, setJobListW, 3)); 
		wave entries.sets[s].CWave = $(childWCopy(nameofwave(setData.CWave), prefix, thisPrefix, tgtPath, setJobListW, 4)); 
		wave entries.sets[s].ERxnsW = $(childWCopy(nameofwave(setData.ERxnsW),prefix, thisPrefix, tgtPath, setJobListW, 5)); 
		wave entries.sets[s].GRxnsW = $(childWCopy(nameofwave(setData.GRxnsW),prefix, thisPrefix, tgtPath, setJobListW, 6)); 
		
		entries.sets[s].index = s;
		entries.sets[s].text = "";
		entries.sets[s].result = NaN;
	endfor
	
	entries.count = s;
	
	// zero out the rest...
	for (s=setLen; s<maxSims; s+=1)
		entries.sets[s].name ="";
		entries.sets[s].folder ="";
		entries.sets[s].text = "";
		entries.sets[s].result = NaN;
		entries.sets[s].index = NaN;
	endfor
	
	setData.error = -1;
	return 0
end





//------------------------------------------------------------------------------------
//
//

function prepGroupMethods(grMethods, jobListW, paramOffset)
	STRUCT groupMethodsT &grMethods;
	wave /T jobListW;
	variable paramOffset;
	
	grMethods.theGroupInSetupFN = jobListW[paramOffset+0];
	FUNCREF groupInputSetupProto grMethods.theGroupInSetupF = $(grMethods.theGroupInSetupFN);
	if ( strlen(grMethods.theGroupInSetupFN))
		if (NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupInSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupInSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupInSetup = 1;
	endif
	
	grMethods.theGroupInAssignFN = jobListW[paramOffset+1];
	FUNCREF groupInputAssignProto grMethods.theGroupInAssignF = $(grMethods.theGroupInAssignFN);
	if ( strlen(grMethods.theGroupInAssignFN) )
		if (NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupInAssignF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupInAssignFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupInAssign = 1;
	endif

	
	grMethods.theGroupResultSetupFN = jobListW[paramOffset+2];
	FUNCREF groupResultSetupProto grMethods.theGroupResultSetupF = $grMethods.theGroupResultSetupFN;
	if ( strlen(grMethods.theGroupResultSetupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutSetup = 1;
	endif


	grMethods.theGroupResultAssignFN = jobListW[paramOffset+3];
	FUNCREF groupResultAssignProto grMethods.theGroupResultAssignF = $grMethods.theGroupResultAssignFN;
	if ( strlen(grMethods.theGroupResultAssignFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultAssignF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultAssignFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutAssign = 1;
	endif


	grMethods.theGroupResultCleanupFN = jobListW[paramOffset+4];
	FUNCREF groupResultCleanupProto grMethods.theGroupResultCleanupF = $grMethods.theGroupResultCleanupFN;
	if ( strlen(grMethods.theGroupResultCleanupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultCleanupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultCleanupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutCleanup = 1;
	endif


	grMethods.theSetPlotSetupFN  = jobListW[paramOffset+5];
	FUNCREF setPlotSetupProto grMethods.theGroupPlotSetupF = $grMethods.theSetPlotSetupFN;
	if ( strlen(grMethods.theSetPlotSetupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupPlotSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theSetPlotSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupPlotBuild = 1;
	endif

	grMethods.theSetPlotAppendFN = jobListW[paramOffset+6];
	FUNCREF groupPlotAppendProto grMethods.theGroupPlotAppendF = $grMethods.theSetPlotAppendFN;
	if ( strlen(grMethods.theSetPlotAppendFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupPlotAppendF)))
			grMethods.text += "== Reference to function \""+grMethods.theSetPlotAppendFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupPlotAppend = 1;
	endif
end


//------------------------------------------------------------------------------------
//
//
function reportGroupMethods(grMethods, setData,  grName, offset, prefix )
	STRUCT groupMethodsT &grMethods;
	STRUCT simSetDataT &setData;
	string grName, offset, prefix;

	grMethods.text = "";
	switch (setData.JParWave[0]) // mode of sim
		case 0:
		case 1: 				
			grMethods.text += offset+ "~~~~~~~~~~~~~~~~~~~~~~ "+grName+"Set "+prefix+" full model ~~~~~~~~~~~~~~~~~~~~~~"
			if (grMethods.doGroupInSetup || grMethods.doGroupInAssign)
				grMethods.text +=  "\r"+offset+"Input "
				if (grMethods.doGroupInSetup)
					grMethods.text +=  "setup:"+ grMethods.theGroupInSetupFN+";";
				endif
				if (grMethods.doGroupInAssign)
					grMethods.text +=  " assign "+ grMethods.theGroupInAssignFN+";"
				endif
			endif
			
			break;
		case 2: 				
			string tmpStr;
			sprintf tmpStr, "Set patial model, mode %d", (setData.JParWave[0])
			grMethods.text +=  offset+grName+tmpStr
			break;
		case 3: 				
			grMethods.text +=  offset+grName+"Set re-plotting"
			break;
		default:
	endswitch		


	if (grMethods.doGroupOutSetup || grMethods.doGroupOutAssign || grMethods.doGroupOutCleanup)
		grMethods.text +=  "\r"+offset+"Result ";
		if (grMethods.doGroupOutSetup)
			grMethods.text +=  "setup: "+ grMethods.theGroupResultSetupFN+";";
		endif 
		if (grMethods.doGroupOutAssign)
			grMethods.text +=  "assign: "+ grMethods.theGroupResultAssignFN+";";
		endif
		if (grMethods.doGroupOutCleanup)
			grMethods.text +=  "cleanup: "+ grMethods.theGroupResultCleanupFN+";";
		endif
	endif
	
	if (grMethods.doGroupPlotBuild || grMethods.doGroupPlotAppend)
		grMethods.text +=   "\r"+offset+"Plot "
		if (grMethods.doGroupPlotBuild)
			grMethods.text +=  " setup:"+ grMethods.theSetPlotSetupFN+";";
		endif 
		if (grMethods.doGroupPlotAppend)
			grMethods.text +=  " append:"+ grMethods.theSetPlotAppendFN+";";
		endif
	endif

end 

