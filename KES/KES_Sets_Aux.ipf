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


//--------------------------------------------------------------------
//
Function simStopThreads()
	variable i, dummy, lastThread;
	lastThread = ThreadGroupCreate(1);
	for (i=0; i<99 || i< lastThread; i+=1)
		dummy = ThreadGroupRelease(i);
	endfor
end


//-----------------------------------------------
//
function waitForThreadGroup(groupID, StOWave, hostPrg, wait)	
	variable groupID
	STRUCT KES#SetProgDataT &hostPrg;
	wave StOWave;
	variable wait
	
	Variable threadGroupStatus = ThreadGroupWait(groupID,wait)
	variable count = dimsize(StOWave, 0);
	variable i;
	
	// check on total returns and current count and update
	variable completedSims = 0;
	variable totalPoints = 0 ;
	variable completedSteps = 0 ;
	variable completedPoints = 0;
	variable completedLims = 0;
	variable completedHolds = 0;
	variable completedRestats = 0;
	for (i=0; i < count; i+=1)
		completedSims += (StOWave[i][9] > 0 ) ? 1 : 0;
		totalPoints += StOWave[i][3]; 
		completedSteps += StOWave[i][4]; 
		completedPoints += StOWave[i][5]; 
		completedHolds += StOWave[i][10]; 
		completedRestats += StOWave[i][11]; 
		completedLims += StOWave[i][12]; 
	endfor
	hostPrg.set_curr_sim_out = completedSims
	hostPrg.set_curr_sim_in = hostPrg.set_sims - completedSims;
	hostPrg.set_curr_s = completedSteps
	hostPrg.set_curr_i = completedPoints
	hostPrg.set_curr_hold = completedHolds;
	hostPrg.set_curr_restart = completedRestats;
	hostPrg.set_curr_lim = completedLims;
	
	return threadGroupStatus;
end


//-----------------------------------------------
//

function /S childWCopy(theWName, oldSetName, newSetName, tgtPath, thisSetW, index)
			string theWName
			string oldSetName;
			string newSetName;
			
			string tgtPath;
			wave /T thisSetW;
			variable index;

			string thisRWN =newSetName+ReplaceString(oldSetName, theWName, "");
			string thisRWP=tgtPath+thisRWN
			duplicate /O  $theWName $thisRWP
			if (index >=0)
				thisSetW[index] = thisRWN;
			endif;
			return thisRWP
		end


//-----------------------------------------------
//
// not currently being used
//
Function AbortTheSimProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR kill_sim 
			kill_sim = 1;
			print "Killed #2"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------------------------------------------
//
function /S funcSelByProto(protoName)
	string protoName
	string fName; 
	string validFNameStr = "-none-;"
	variable i, j;
	
	string protoInfo = FunctionInfo(""+protoName);
	string isTS = StringByKey("THREADSAFE", protoInfo)
	variable returnType = NumberByKey("RETURNTYPE", protoInfo);
	variable nPar =  NumberByKey("N_PARAMS", protoInfo);
	variable nOptPar =  NumberByKey("N_OPT_PARAMS", protoInfo);

	string searchStr;
	sprintf searchStr, "KIND:2,NPARAMS:%u,VALTYPE:%u,WIN:[ProcGlobal]", nPar, (returnType == 4) ? 1 : ((returnType == 5) ? 2 : ((returnType == 16384) ? 8 : 4))
	string allFnameStr = FunctionList("*",";",searchStr)
	for (i = 0; 1; i+=1)
		fname = stringfromlist(i,allFNameStr);
		if (strlen(fName) == 0)
			return validFNameStr;
		endif
		if (cmpstr(fName, protoName) == 0)
			continue;
		endif 
		// ends withProto?
		if (stringmatch(fName, "*proto"))
			continue
		endif
		string funcInfo = FunctionInfo("ProcGlobal#"+fName);
		if (cmpstr( isTS, StringByKey("THREADSAFE", protoInfo)))
			continue;
		endif
		if (returnType != NumberByKey("RETURNTYPE", funcInfo))
			continue;
		endif
		if (nPar != NumberByKey("N_PARAMS", funcInfo))
			continue;
		endif
		if (nOptPar != NumberByKey("N_OPT_PARAMS", funcInfo))
			continue;
		endif
		string parKey;
		variable parsMatch = 1;
		for (j=0; j< nPar; j+=1)
			sprintf parKey "PARAM_%u_TYPE", j
			if (NumberByKey(parKey, protoInfo) != NumberByKey(parKey, funcInfo))
				parsMatch = 0;
				break;
			endif
		endfor
		if (parsMatch)
			validFNameStr += fName+";";
		endif
	endfor;
end


//--------------------------------------------------------------------
//
Function PopFuncSelect(pa, ctrlName , jobField) : PopupMenuControl
	STRUCT WMPopupAction &pa
	string ctrlName;
	variable jobField;
	
	switch( pa.eventCode )
		case 2: // mouse up
			setJobField(pa.win, ctrlName , jobField, pa.popStr);
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------------------------------------------
//
function setJobField(win, ctrlName , jobField, valStr)
	string win;
	string ctrlName;
	variable jobField;
	string valStr; 

			ControlInfo /W=$(StringFromList(0,win,"#")) $ctrlName
			wave /T jobListW = $S_Value;
			if (waveexists(jobListW)) 
				if (cmpstr(valStr, "-none-") == 0)
					jobListW[jobField] = "";
				else
					jobListW[jobField] = valStr;
				endif 
				//ControlUpdate?
			else
				DoAlert /T="Beware..." 0, "You selected element of the job but the job wave does not exist. You will need to repeat this selction before the job can be executed"
			endif 

end

//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	dialog service
//--------------------------------------------------------------------
//

Function ctrlSetVar2WaveByValue(sva, ctrlName , theRow) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo /W=$(StringFromList(0,sva.win,"#")) $ctrlName
			if (strlen(S_value)) 
				wave jobParamW = $S_Value;
				jobParamW[theRow] = dval
			endif 
			if (numtype(dval)==2) 
				SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
			endif
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End

 
//--------------------------------------------------------------------
//
Function ctrlSetVar2Wave2DByValue(sva, ctrlName , theRow, theCol) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow, theCol;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo /W=$(sva.win) $ctrlName
			if (strlen(S_value)) 
				wave jobParamW = $S_Value;
				jobParamW[theRow][theCol] = dval
			endif 
			if (numtype(dval)==2) 
				SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
			endif
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End



//--------------------------------------------------------------------
//
Function ctrlSetVar2WaveByStr(sva, ctrlName , theRow) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			ControlInfo /W=$(StringFromList(0,sva.win,"#")) $ctrlName
			if (strlen(S_value)) 
				wave /T jobParamW = $S_Value;
				jobParamW[theRow] =  sva.sval
			endif 
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
Function ctrlSetList2WaveByValue(pa, ctrlName , theRow, offset) 
	STRUCT WMPopupAction &pa
	string ctrlName;
	variable theRow;
	variable offset; // correction from popup index to wave value
	
	switch( pa.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = pa.popNum +offset;
			String sval = pa.popStr
			ControlInfo /W=$(StringFromList(0,pa.win,"#")) $ctrlName
			wave jobParamW = $S_Value;
			if (waveexists(jobParamW)) 
				if (numtype(dval)==0)
					jobParamW[theRow] = dval
				else
					PopupMenu $pa.ctrlName,mode = jobParamW[theRow], win=$(pa.win)
				endif
			else
				PopupMenu $pa.ctrlName,mode = inf, win=$(pa.win)
			endif 
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch
	return 0
end



//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
function wave2CtrlSetVarBylValue(winNStr, paramWave, theRow, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow;
	wave paramWave

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]
		if (numtype(theValue)==2) 
			SetVariable  $ctrlNStr, value= _STR:"", win=$(winNStr) 
		else	
			SetVariable $ctrlNStr, value= _NUM:theValue, win=$(winNStr) 
		endif
	else
			SetVariable  $ctrlNStr, value= _STR:"-", win=$(winNStr) 
	endif
	
end

//--------------------------------------------------------------------
//
function wave2D2CtrlSetVarBylValue(winNStr, paramWave, theRow, theCol, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow, theCol;
	wave paramWave

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow][theCol]
		if (numtype(theValue)==2) 
			SetVariable  $ctrlNStr, value= _STR:"", win=$(winNStr) 
		else	
			SetVariable $ctrlNStr, value= _NUM:theValue, win=$(winNStr) 
		endif
	else
			SetVariable  $ctrlNStr, value= _STR:"-", win=$(winNStr) 
	endif
	
end

//--------------------------------------------------------------------
//
function wave2CtrlSetVarByStr(winNStr, paramWave, theRow, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow;
	wave /T paramWave

	string theValue = "";
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]
	endif
	SetVariable  $ctrlNStr, value= _STR:theValue, win=$(winNStr) 
end

//--------------------------------------------------------------------
//
function wave2CtrlPopupByValue(winNStr, paramWave, theRow, ctrlNStr, offset)
	string winNStr, ctrlNStr;
	variable theRow;
	wave paramWave
	variable offset; // correction between popup index and wave value

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]-offset
		if (numtype(theValue)==2) 
			PopupMenu $ctrlNStr,mode = inf, win=$(winNStr)
		else	
			PopupMenu $ctrlNStr, mode = (theValue), win=$(winNStr)
		endif
	else
			PopupMenu $ctrlNStr, mode = inf, win=$(winNStr)
	endif
	
end



//--------------------------------------------------------------------
//

function wave2PopMenuStr(winN, ctrlName, paramW, paramField)
	string winN, ctrlName
	wave /T paramW
	variable paramField

	if (waveexists(paramW))
		PopupMenu  $ctrlName, mode=1, win=$(winN)
		PopupMenu  $ctrlName, popmatch =  paramW[paramField], win=$(winN)
	else
		PopupMenu  $ctrlName, popmatch =  "-none-", win=$(winN)
	endif
end

//--------------------------------------------------------------------
//

function wave2PopMenuWave(winN, ctrlName, paramW, paramField)
	string winN, ctrlName
	wave /T paramW
	variable paramField

	if (waveexists(paramW))
		string tgtWN = paramW[paramField];
		if (waveexists($tgtWN))
			PopupMenu  $ctrlName, popmatch =  tgtWN, win=$(winN)
		else
			PopupMenu  $ctrlName, popmatch = "-", win=$(winN)
		endif
	else
		PopupMenu  $ctrlName, popmatch =  "-", win=$(winN)
	endif
end


