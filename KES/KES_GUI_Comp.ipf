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
#pragma ModuleName = KES_GUI
#pragma hide=1

//--------------------------------------------------------------------
//
function simReloadCompParamPanel(wName, compParamW, [setCmpNo])
	string wName
	wave compParamW
	variable setCmpNo
	
	if (paramisdefault(setCmpNo))
		setCmpNo = 0;
	endif

	if (waveexists(compParamW))
	
		PopupMenu $"compParamWSelect", popmatch=nameofwave(compParamW), win=$(wName)
		
		variable nCmp = dimsize(compParamW,1);
		string cmpList = "\"";
		variable i;
		for (i=0; i<nCmp; i+=1)
			cmpList += num2str(i)+";";		
		endfor
		cmpList+="\"";
		PopupMenu $"cmpSelect", value=#cmpList, mode = (setCmpNo+1), win=$(wName)
		setCmpVals(wName, setCmpNo);
		
	else
		PopupMenu $"cmpSelect", value="-", mode = (1), win=$(wName)
		setCmpVals(wName, 0);
	endif	
	
end 


//--------------------------------------------------------------------
//
function setCmpVals(wName,  cmpNo)
	string wName;
	variable cmpNo;

	ControlInfo /W=$(wName) $"compParamWSelect"
	wave cmpParamW =$(S_value)
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 0,cmpNo, "intOx")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 1,cmpNo, "intRd")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 2,cmpNo, "cmpE")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 3,cmpNo, "cmpN")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 5,cmpNo, "cmpA")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 4,cmpNo, "cmp_k0")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 6,cmpNo, "cmpFlags")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 8,cmpNo, "cmpLim_k")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 10,cmpNo, "cmpBindK")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 11,cmpNo, "cmpOnRate")

	if (waveexists(cmpParamW))
		string thisLabel = GetDimLabel(cmpParamW, 1,cmpNo)
		SetVariable  $"cmpName", value= _STR:thisLabel, win=$(wName) 
	else
		SetVariable  $"cmpName", value= _STR:"-", win=$(wName) 
	endif

	setCmpAlias(cmpParamW, cmpNo, wName)
end


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function setCmpAlias(cmpParamW, cmpNo, win)
	wave cmpParamW
	variable cmpNo
	string win
	// display alias

	string thatList = "";
	variable i;
	for ( i=0; i< dimsize(cmpParamW, 1); i+= 1)
		if (i== cmpNo)
			continue;
		endif 
		if (strlen(thatList) >0 )
			thatList += ";";
		endif 
		string thatLabel = GetDimLabel(cmpParamW, 1,i)
		if (strlen(thatLabel) <= 0)
			sprintf thatLabel, "cmp #%d", i; 
		endif
		thatList += thatLabel;
			
	endfor; 
	 thatList  = "\""+thatList+"\""
	PopupMenu 	$"cmpAliasThatCmp", value=#thatList, win=$(win)

	
	if (waveexists(cmpParamW))
		variable anAliasCmp = cmpParamW[13][cmpNo];
		variable thisState = 1;
		if (anAliasCmp == 0)
			anAliasCmp = cmpParamW[14];
			thisState = 2;
		endif 

		variable thatState = anAliasCmp > 0 ? 1 : 2;
		variable thatCmp = abs(anAliasCmp);
		if (thatCmp == cmpNo) // self-reference!
			anAliasCmp = 0;
		endif 
	else
		anAliasCmp = 0;
	endif
	
	if (anAliasCmp == 0) // no alias or no data
		PopupMenu 	$"cmpAliasThatState" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThatCmp" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThisState" mode=1, win=$(win)
		return 0; 		
	endif
	
	//alias exists
	PopupMenu 	$"cmpAliasThatState" disable=0, win=$(win)
	PopupMenu 	$"cmpAliasThisState", mode=(1+thisState), win=$(win)

	variable aliasIndex = thatCmp;
	if (thatCmp > (cmpNo+1)) // reduce the index 
		aliasIndex =  thatCmp -1;
	endif  

	PopupMenu 	$"cmpAliasThatCmp", disable=0,  mode=(aliasIndex), win=$(win)
	PopupMenu 	$"cmpAliasThatState", disable=0, mode=(thatState), win=$(win)
end


//--------------------------------------------------------------------
//
function /S cmpAliasThisState()
	string validFNameStr = "none;ox.;red."
	return validFNameStr;
end


//--------------------------------------------------------------------
//
function /S cmpAliasThatState()
	string validFNameStr = "ox.;red."
	return validFNameStr;
end


//--------------------------------------------------------------------
//

function assignAllias(currState, aliasState, aliasCmp, win)
	variable currState,  aliasState, aliasCmp;
	string win;
	
	// name of components wave
	ControlInfo /W=$(win) $"compParamWSelect"
	wave cmpParamW =$(S_value)

	variable currCmp =  ctrlSelectorPos(win, "cmpSelect")

	
	if (currState == 0) // slected "none"
		PopupMenu 	$"cmpAliasThatState" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThatCmp" disable=1, win=$(win)
		cmpParamW[13,14][currCmp] = 0;
		return 0;
	endif

	if (aliasCmp >= currCmp)
		aliasCmp +=1;
	endif
	aliasCmp +=1;

	PopupMenu 	$"cmpAliasThatState" disable=0, win=$(win)
	PopupMenu 	$"cmpAliasThatCmp" disable=0, win=$(win)

	if (currState == 1) // set oxidized 
		cmpParamW[13][currCmp] = aliasCmp * ((aliasState == 0)? 1: -1);
		cmpParamW[14][currCmp] = 0;
	else // set reduced 
		cmpParamW[13][currCmp] = 0;
		cmpParamW[14][currCmp] = aliasCmp * ((aliasState == 0)? 1: -1);
	endif 

end