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
function simReloadRxnsParamPanel(wName, rxnsParamW, [currRxn])
	string wName
	wave /WAVE rxnsParamW
	variable currRxn;
	
	if (paramisdefault(currRxn)) 	
		currRxn = 0; 
	endif

	setRxn(wName, rxnsParamW, currRxn)
end

//--------------------------------------------------------------------
//
function setRxn(wName, rxnsParamW, currRxn)
	string wName
	wave /WAVE rxnsParamW
	variable currRxn;
	
	variable nRx = 0;
	variable i;
	if (waveexists(rxnsParamW))
		wave ratesW = rxnsParamW[0]
		if (waveexists(ratesW))
			nRx = dimsize(ratesW, 0);
			for (i=0; i < nRx; i += 1 )
				wave theRxW = rxnsParamW[i+1];
				if (!waveexists(theRxW))
					nRx = i;
					break;
				endif 
			endfor
		endif
	endif	
	
	if (nRx>0)
		if (currRxn >= nRx)
			currRxn = 0;
		endif
		string rxnList = "\"";
		for (i=0; i<nRx; i+=1)
			rxnList += num2str(i)+";";		
		endfor
		rxnList+="\"";
		PopupMenu $"rxnSelect", value=#rxnList, mode = (currRxn+1), win=$(wName)
		SetVariable $"rxn_K_Eq", value =_NUM: ratesW[currRxn][0], win=$(wName)
		SetVariable $"rxn_k_fwd", value =_NUM: ratesW[currRxn][1], win=$(wName)
		loadRxnTbl(wName, rxnsParamW[currRxn+1] )
		
		string thisLabel = GetDimLabel(ratesW, 0,currRxn)
		SetVariable  $"rxnName", value= _STR:thisLabel, win=$(wName) 
		SetVariable  $"rxnWaveName", value= _STR:nameofwave(rxnsParamW[currRxn+1]), win=$(wName) 
		SetVariable  $"tdWaveName", value= _STR:nameofwave(ratesW), win=$(wName) 
		
	else
		PopupMenu $"rxnSelect", value="-", mode = 1, win=$(wName)
		SetVariable $"rxn_K_Eq", value =_STR:"-", win=$(wName)
		SetVariable $"rxn_k_fwd", value =_STR:"-", win=$(wName)
		loadRxnTbl(wName, $"")
		SetVariable  $"rxnName", value= _STR:"-", win=$(wName) 
		SetVariable  $"rxnWaveName", value= _STR:"-", win=$(wName) 
		SetVariable  $"tdWaveName", value= _STR:"-", win=$(wName) 
	endif
	

end 


//--------------------------------------------------------------------
//
function RxnInfoTable(wName, rxnsParamW, caption)
	string wName
	wave /WAVE rxnsParamW
	string Caption
	
	variable nRx = 0;
	variable i;
	if (!waveexists(rxnsParamW))
		DoAlert /T="Can't do it!" 2, "There is no reactions wave selected and nothing to show!"
		return 0;
	endif 

	wave ratesW = rxnsParamW[0]
	if (waveexists(ratesW))
		nRx = dimsize(ratesW, 0);
		make /T /O /N=(nRx ) $"RxnsInfoListW"
		wave /T infoList = $"RxnsInfoListW"
		for (i=0; i < nRx; i += 1 )
			wave theRxW = rxnsParamW[i+1];
			if (waveexists(theRxW))
				infoList[i] = GetWavesDataFolder(theRxW,2) 
			else
				infoList[i] = "invalid reaction wave reference #"+num2str(i);
				nRx = i;
				break;
			endif 
		endfor
	else
		DoAlert /T="Can't do it!" 2, "Reactions wave exists but thermodynamics wave is missing.\n You may need to assign it manually."
		return 0;
	endif

	
	NewPanel /W=(150,50,610,400) /N=KES_RxnsInofPanel as Caption + " information" 
	AutoPositionWindow /R=KinESimCtrl KES_RxnsInofPanel
	DrawText 6,18,"Thermodynamic wave:"
	TitleBox TDWaveName,pos={5,16},size={450,24},title=GetWavesDataFolder(rxnsParamW,2),frame=5
	DrawText 9,58,"Reactions waves:"
	TitleBox TDWaveName,fixedSize=1
	ListBox RxnsWavesList,pos={5,60},size={450,250}
	ListBox RxnsWavesList,listWave=$nameofwave(infoList)
	Button RxnsInfoDoneBtn,pos={5,315},size={450,20},proc=RxnsInfoDoneProc,title="Done", fColor=(19456,39168,0)
	Pauseforuser KES_RxnsInofPanel	
end 

//--------------------------------------------------------------------
//
// after simReloadRatesParamPanel
function loadRxnTbl(wName, rxnW )
	wave rxnW
	string wName

	string tblName = wName+"#Tbl"
	variable i;
	string WatcherNameS
	for (i=0; 1; i+=1)	
		wave theWave = WaveRefIndexed(tblName, i, 3)
		if (!waveexists(theWave))
			break;
		endif  
		RemoveFromTable /W=$tblName theWave.ld
		// delete dependence
		WatcherNameS = nameofwave( theWave)+"Dep";
		SetFormula $WatcherNameS, ""
		killvariables  /Z $WatcherNameS
	endfor
	if (waveexists(rxnW))
		SetDimLabel 1,0, $"-›¦#..", rxnW
		SetDimLabel 1,1, $"-›¦Ox..", rxnW
		SetDimLabel 1,2, $"-›¦Rd..", rxnW
		SetDimLabel 1,3, $"..#¦-›", rxnW
		SetDimLabel 1,4, $"..Ox¦-›", rxnW
		SetDimLabel 1,5, $"..Rd¦-›", rxnW
		
		AppendToTable /W=$tblName rxnW //.ld
		ModifyTable /W=$tblName horizontalIndex=2, format(Point)=1,width(Point)=20,sigDigits(rxnW)=1,width(rxnW)=38 
		ModifyTable /W=$tblName font[1] ="Arial Black", font[4] ="Arial Black"
		ModifyTable /W=$tblName style[1] =0, style[4] =0
		ModifyTable /W=$tblName format[1] =1, format[4] =1
		ModifyTable /W=$tblName rgb[1] =(0,0,65535), rgb[4] =(0,0,65535)
		ModifyTable /W=$tblName alignment[1,3] =0, alignment[4,6]=2
		// add dependence
		WatcherNameS = nameofwave(rxnW)+"Dep";
		Variable/G $WatcherNameS
		SetFormula $WatcherNameS, "EUpdateHook(\""+wName+"\", "+nameofwave(rxnW)+")"
	endif	
	
end


//--------------------------------------------------------------------
//
function addRxnProc(win, ctrlName, prefix)
	string win, ctrlName, prefix
	
	ControlInfo /W=$(win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;
	
	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(win, "rxnSelect")
		variable newRxIndex = currRxn+2;
		
		InsertPoints /M=0 newRxIndex, 1, rxnsParamW;
		variable i
		for (i=0; i<99; i+=1)
			string rxWName
			sprintf  rxWName "%s%02d", prefix, i
			if (!waveexists($rxWName))
				make /N=(1, 6) $rxWName
				rxnsParamW[newRxIndex] = $rxWName
				break;
			endif 
		endfor
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			InsertPoints /M=0 currRxn+1, 1, rxParamsW;
			rxParamsW[currRxn+1][] = 0;
		endif 
		 simReloadRxnsParamPanel(win, rxnsParamW, currRxn = currRxn+1)		
	endif 

end



//--------------------------------------------------------------------
//
Function delGRxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		
		DeletePoints /M=0 currRxn+1, 1, rxnsParamW;
		
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			DeletePoints /M=0 currRxn, 1, rxParamsW;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn)		
	endif 	

	return 0
End

//--------------------------------------------------------------------
//
function copyRxnsSet(eRxnsWName, cdfAfter)
	string eRxnsWName, cdfAfter

			variable i;

			if (waveexists($eRxnsWName))
				duplicate /O $eRxnsWName $(cdfAfter+eRxnsWName);
				wave /WAVE eRxnsW = $eRxnsWName;
				wave eRxnsRDW =  eRxnsW[0]
				if (waveexists(eRxnsRDW))
					duplicate /O eRxnsRDW $(cdfAfter+nameofwave(eRxnsRDW));
				endif
				for (i=1; i<dimsize(eRxnsW, 0); i+=1)
					wave theRxnW =  eRxnsW[i]
					if (waveexists(theRxnW))
						duplicate /O theRxnW $(cdfAfter+nameofwave(theRxnW));
					endif 
				endfor
			endif 
			
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

function makeRxnWave(win, prefix, popupName, jobListCtrlName, jobIndex)
	string win, prefix, popupName, jobListCtrlName
	variable jobIndex;

		variable i
		for (i=0; i<99; i+=1)
			string rxListWName
			sprintf  rxListWName "%ss%02d", prefix, i
			string rxTDWaveName = rxListWName+"_TD";
			if (!waveexists($rxListWName) && !waveexists($rxTDWaveName))
				make /WAVE  /N=(2) $rxListWName
				make  /N=(1,2) $rxTDWaveName
				wave /WAVE rxnsParamW = $rxListWName;
				rxnsParamW[0] = $rxTDWaveName
				// now make 1st reaction
				for (i=0; i<99; i+=1)
					string rxWName
					sprintf  rxWName "%s%02d", prefix, i
					if (!waveexists($rxWName))
						make /N=(1, 6) $rxWName
						rxnsParamW[1] = $rxWName
						break;
					endif 
				endfor
				
				break;
			endif 
		endfor
		 setJobField(win, jobListCtrlName , jobIndex , rxListWName)			
		PopupMenu $popupName, win=$win, popmatch=rxListWName
		setRxn(win, rxnsParamW, 0)
end

