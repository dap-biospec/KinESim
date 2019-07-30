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
function /S getGUIVer()
	return cKESGUIVer;
end

//--------------------------------------------------------------------
//
function EUpdateHook(WinNameStr, theWave)
	string WinNameStr
	wave theWave
	// print "Value updated for window ", WinNameStr, " and reactions wave ", nameofwave(theWave) ;
	// use this hook to update effective K for the reaction
end


//--------------------------------------------------------------------
//
Function getJobWave(win, jobW)
		STRING win;
		wave /T &jobW;
		ControlInfo /W=$(StringFromList(0,win,"#")) jobListWSelect
		wave /T jobW = $(S_value);
		if (waveexists(jobW))
			return 1;
		elseif (cmpstr(S_value, "-")!=0)
			DoAlert /T="Oops!", 0, "The wave ["+S_value+"] is not found. Please check the location and try again."
			return 0;
		endif
end


//--------------------------------------------------------------------
//
Function ctrlSelectorPos(wName, selectorWCtrlN)
	string wName
	string selectorWCtrlN

	ControlInfo /W=$wName $selectorWCtrlN
	if (cmpstr(S_value,"-") == 0 ||  strlen(S_value) == 0)
		return -1;
	endif 
	return  V_Value -1;
end


	
//--------------------------------------------------------------------
//
	
Function ctrlSetVar2WaveRef2DByValue(sva, refWCtrl, refOffset, tgtCol, tgtRow)
	STRUCT WMSetVariableAction &sva
	variable refOffset; 
	variable tgtCol ;
	string refWCtrl 
	variable tgtRow; 

	if (sva.eventCode != 1 &&  sva.eventCode != 2)
		return 0;
	endif

	ControlInfo /W=$(sva.win) $refWCtrl
	
	wave /WAVE rxnsParamW = $S_Value;
	if (!waveexists(rxnsParamW))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 
	
	wave ratesW = rxnsParamW[0]
	if (!waveexists(ratesW))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 

	if (tgtRow > dimSize(ratesW, 0))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 
	ratesW[tgtRow][tgtCol] = sva.dval;
	return 0;
End


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

function SimCtrlTable(jobListW)
	wave /T jobListW;
	
	string jobName = nameofwave(jobListW);
	
	string jobFldr = GetWavesDataFolder(jobListW, 1);
	
	if (!waveexists($jobListW[1]))
		print  "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 
	wave JobParams = $jobListW[1];

	if (!waveexists($jobListW[2]))
		print "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 
	wave MethodParams = $jobListW[2];

	if (!waveexists($jobListW[3]))
		print "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 
	wave ESimParams = $jobListW[3];

	if (!waveexists($jobListW[4]))
		print "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 
	wave  ESimComp = $jobListW[4];

	string title = jobName+" control table";

	Edit /W=(5.25,43.25,1277.25,716) jobListW.ld, JobParams.ld,MethodParams.ld,ESimParams.ld, ESimComp.ld as title
	
	ModifyTable format(Point)=1,width(Point)=23,style( jobListW.l)=1,width( jobListW.l)=95
	ModifyTable width( jobListW.d)=129,style(JobParams.l)=1,width(JobParams.d)=50,style(MethodParams.l)=1
	ModifyTable width(MethodParams.d)=45,style(ESimParams.l)=1,width(ESimParams.l)=122
	ModifyTable width(ESimParams.d)=41,style(ESimComp.l)=1,width(ESimComp.d)=45

	if (!waveexists($jobListW[5]))
//		print "rates wave "+jobListW[5]+" is not found\r";
//		return 1;
	else
		wave Rates = $jobListW[5];
		AppendToTable Rates.ld
		ModifyTable style(Rates.l)=1,width(Rates.l)=53,width(Rates.d)=27
	endif 

end



//--------------------------------------------------------------------
//
function simReloadPanelJob(wName, jListWCtrl)
	string wName, jListWCtrl
	ControlInfo /W=$(StringFromList(0,wName,"#")) $jListWCtrl
	if (strlen(S_value)) 
		 wave /T jListW= $S_Value;
		 simReloadJob(wName, jListW)
	else
		 simReloadJob(wName, $(""))
	endif
	
end


//--------------------------------------------------------------------
//

function simReloadJob(wName, jobListW)
	string wName
	 wave /T jobListW

		wave2CtrlSetVarByStr(wName+"#Sim", jobListW, 0, "simCommName")

		wave2PopMenuStr(wName+"#Sim", "simWPrepFSelect", jobListW, 7); 
		wave2PopMenuStr(wName+"#Sim", "simWProcFSelect", jobListW, 8); 
		wave2PopMenuStr(wName+"#Sim", "simPlotBuildFSelect", jobListW, 9); 
		
		wave2PopMenuStr(wName+"#Set", "setInSetupFSelect", jobListW, 11); 
		wave2PopMenuStr(wName+"#Set", "setInAssignFSelect", jobListW, 12); 
		wave2PopMenuStr(wName+"#Set", "setOutSetupFSelect", jobListW, 13); 
		wave2PopMenuStr(wName+"#Set", "setOutAssignFSelect", jobListW, 14); 
		wave2PopMenuStr(wName+"#Set", "setOutCleanupFSelect", jobListW, 15); 
		wave2PopMenuStr(wName+"#Set", "setPlotBuildFSelect", jobListW, 16); 
		wave2PopMenuStr(wName+"#Set", "setPlotAppendFSelect", jobListW, 17); 
	
		wave2PopMenuStr(wName+"#Kilo", "kiloInSetupFSelect", jobListW, 20); 
		wave2PopMenuStr(wName+"#Kilo", "kiloInAssignFSelect", jobListW, 21); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutSetupFSelect", jobListW, 22); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutAssignFSelect", jobListW, 23); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutCleanupFSelect", jobListW, 24); 
		wave2PopMenuStr(wName+"#Kilo", "kiloPlotBuildFSelect", jobListW, 25); 
		wave2PopMenuStr(wName+"#Kilo", "kiloPlotAppendFSelect", jobListW, 26); 

		wave2PopMenuStr(wName+"#Mega", "megaInSetupFSelect", jobListW, 29); 
		wave2PopMenuStr(wName+"#Mega", "megaInAssignFSelect", jobListW, 30); 
		wave2PopMenuStr(wName+"#Mega", "megaOutSetupFSelect", jobListW, 31); 
		wave2PopMenuStr(wName+"#Mega", "megaOutAssignFSelect", jobListW, 32); 
		wave2PopMenuStr(wName+"#Mega", "megaOutCleanupFSelect", jobListW, 33); 
		wave2PopMenuStr(wName+"#Mega", "megaPlotBuildFSelect", jobListW, 34); 
		wave2PopMenuStr(wName+"#Mega", "megaPlotAppendFSelect", jobListW, 35); 


		// reload params wave
		wave2PopMenuWave(wName, "jobParamWSelect", jobListW, 1);
		wave2PopMenuWave(wName+"#Method", "methodParamWSelect", jobListW, 2);
		wave2PopMenuWave(wName, "esimParamWSelect", jobListW, 3);
		wave2PopMenuWave(wName+"#Comp", "compParamWSelect", jobListW, 4);
		wave2PopMenuWave(wName+"#ERxns", "eRxnsParamWSelect", jobListW, 5);
		wave2PopMenuWave(wName+"#GRxns", "gRxnsParamWSelect", jobListW, 6);
	
	if (waveexists(jobListW))
		// reload functions
		simReloadJParamPanel(wName, $(jobListW[1]));
		simReloadMethodParamPanel(wName+"#Method", $(jobListW[2]))
		simReloadESimParamPanel(wName, $(jobListW[3]));
		simReloadCompParamPanel(wName+"#Comp", $(jobListW[4]))
		simReloadRxnsParamPanel(wName+"#ERxns", $(jobListW[5]))
		simReloadRxnsParamPanel(wName+"#GRxns", $(jobListW[6]))		
	else
		simReloadJParamPanel(wName, $(""));
		simReloadMethodParamPanel(wName+"#Method", $(""))
		simReloadESimParamPanel(wName, $(""));
		simReloadCompParamPanel(wName+"#Comp", $(""))
		simReloadRxnsParamPanel(wName+"#ERxns", $(""))
		simReloadRxnsParamPanel(wName+"#GRxns", $(""))		

	endif

end

//--------------------------------------------------------------------
//
function simReloadJParamPanel(wName, jParamW)
	string wName
	wave jParamW
	
	wave2CtrlSetVarBylValue(wName+"", jParamW, 0, "jobFlagsEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 1, "setNThrds")

	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 2, "setFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 3, "setToEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 4, "setStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 6, "setVarCmpNo")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 8, "setPlotCmpNo")

	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 10, "kiloFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 11, "kiloToEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 12, "kiloStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 14, "kiloParam1Edit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 15, "kiloParam2Edit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 16, "kiloFlagsEdit")

	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 19, "megaFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 20, "megaToEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 21, "megaStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 23, "megaParam1Edit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 24, "megaParam2Edit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 25, "megaFlagsEdit")
	
end

//--------------------------------------------------------------------
//
function simReloadESimParamPanel(wName, eSimParamW)
	string wName
	wave eSimParamW
	
	wave2CtrlSetVarBylValue(wName+"#Sim", eSimParamW, 0, "simNThrds")
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 1, "simIsBiDir", -1);
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 2, "simETRateMode", -2)
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 3, "simLimRateMode", -1)
	wave2CtrlSetVarBylValue(wName+"#Sim", eSimParamW, 10, "simLayerThick")

	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 5, "RKiDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 6, "RKiRise")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 7, "RKFullDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 8, "RKFullRise")

	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 11, "RKiDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 12, "RKiRise")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 13, "RKFullDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 14, "RKFullRise")


	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 17, "RKTimeDropX")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 16, "RKTimeDropOver")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 18, "RKTimeRiseX")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 20, "RKTimeNextX")
end



//--------------------------------------------------------------------
//
function simReloadMethodParamPanel(wName, methodParamW)
	string wName
	wave methodParamW
	string tblName = wName+"#Tbl"
	variable i;
	for (i=0; 1; i+=1)	
		wave theWave = WaveRefIndexed(tblName, i, 3)
		if (waveexists(theWave))
			RemoveFromTable /W=$tblName theWave.ld
		else
			break;
		endif  
	endfor
	if (waveexists(methodParamW))
		AppendToTable /W=$tblName methodParamW.ld
		ModifyTable /W=$tblName width(methodParamW.l)=64,width(methodParamW.d)=40
	endif
end 



//--------------------------------------------------------------------
//

Function simCopySet(win) 
	string win;
	ControlInfo /W=$win $"jobListWSelect"
	wave /T jobListW= $S_Value;
	if (!waveexists(jobListW))
		DoAlert /T="Oops!" 0, "The job wave that you want to copy is not found."
		return 0;
	endif 

	String cdfBefore = GetDataFolder(1)		
	string BrowserCmd = " CreateBrowser prompt=\"Select new folder to copy set to\", showWaves=1, showVars=0, showStrs=0 ";

	Execute BrowserCmd;
	String cdfAfter = GetDataFolder(1)	// Save current data folder after.
	SetDataFolder cdfBefore			// Restore current data folder.
	SVAR S_BrowserList=S_BrowserList
	NVAR dlg_Flag=V_Flag
	if(V_Flag==0)
		return 0;
	endif

	// check if folder is the same
	if (cmpstr(cdfBefore, cdfAfter) == 0)
		DoAlert /T="Oops!" 0, "Please select target folder other than the source folder."
		return 0;
	endif 
	string jListWName = nameofwave(jobListW);
	string newName = cdfAfter+jListWName
	duplicate /O $jListWName $(cdfAfter+jListWName);

	string jParamWName = jobListW[1];
	if (waveexists($jParamWName))
		duplicate /O $jParamWName $(cdfAfter+jParamWName);
	endif 

	 string methodWName = jobListW[2];
	if (waveexists($methodWName))
		duplicate /O $methodWName $(cdfAfter+methodWName);
	endif 

	 string esimWName = jobListW[3];
	if (waveexists($esimWName))
		duplicate /O $esimWName $(cdfAfter+esimWName);
	endif 

	 string compWName = jobListW[4];
	if (waveexists($compWName))
		duplicate /O $compWName $(cdfAfter+compWName);
	endif 
	
	copyRxnsSet( jobListW[5], cdfAfter)
	copyRxnsSet( jobListW[6], cdfAfter)
end

//--------------------------------------------------------------------
//

Function simCreateSet(win) 
	string win;
	string jListWName;
	Prompt jListWName, "Job wave name:"
	DoPrompt "Create new job set", jListWName
	
	ControlInfo /W=$win $"jobListWSelect"
	wave /T jobListW= $S_Value;
	if (waveexists(jobListW)) // there is a wave, ensure that we do not override it
		if (!cmpstr(S_Value, jListWName))
			DoAlert /T="Oops!" 0, "Job wave with such name alredy exists. Please try again with a unique name."
			return 0;
		endif
	endif 

	make /T /N=36 $jListWName
	wave /T jobListW= $jListWName;
	PopupMenu  $"jobListWSelect" win=$win, popmatch=jListWName
	
	SetDimLabel 0,0,  $"Sim base name (s)", jobListW
	SetDimLabel 0,1,  $"Job params (w)", jobListW
	SetDimLabel 0,2,  $"Method params (w)", jobListW
	SetDimLabel 0,3,  $"Sim params (w)", jobListW
	SetDimLabel 0,4,  $"Components (w)", jobListW
	SetDimLabel 0,5,  $"EChem reactions (w)", jobListW
	SetDimLabel 0,6,  $"Gen reactions (w)", jobListW
	SetDimLabel 0,7,  $"Sim w. prep (f)", jobListW
	SetDimLabel 0,8,  $"Sim w. process (f)", jobListW
	SetDimLabel 0,9,  $"Sim plot build (f)", jobListW
	SetDimLabel 0,10, $"---", jobListW
	SetDimLabel 0,11, $"Set input setup (f)", jobListW
	SetDimLabel 0,12, $"Set input assign (f)", jobListW
	SetDimLabel 0,13, $"Set result setup (f)", jobListW
	SetDimLabel 0,14, $"Set result save (f)", jobListW
	SetDimLabel 0,15, $"Set cleanup (f)", jobListW
	SetDimLabel 0,16, $"Set plot setup (f)", jobListW
	SetDimLabel 0,17, $"Set plot append (f)", jobListW
	SetDimLabel 0,18, $"---", jobListW
	SetDimLabel 0,19, $"---", jobListW
	SetDimLabel 0,20, $"Kilo input setup (f)", jobListW
	SetDimLabel 0,21, $"Kilo input assign (f)", jobListW
	SetDimLabel 0,22, $"Kilo result setup (f)", jobListW
	SetDimLabel 0,23, $"Kilo result save (f)", jobListW
	SetDimLabel 0,24, $"Kilo cleanup (f)", jobListW
	SetDimLabel 0,25, $"Kilo plot setup (f)", jobListW
	SetDimLabel 0,26, $"Kilo plot append (f)", jobListW
	SetDimLabel 0,27, $"---", jobListW
	SetDimLabel 0,28, $"---", jobListW
	SetDimLabel 0,29, $"Mega input setup (f)", jobListW
	SetDimLabel 0,30, $"Mega input assign (f)", jobListW
	SetDimLabel 0,31, $"Mega result setup (f)", jobListW
	SetDimLabel 0,32, $"Mega result save (f)", jobListW
	SetDimLabel 0,33, $"Mega cleanup (f)", jobListW
	SetDimLabel 0,34, $"Mega plot setup (f)", jobListW
	SetDimLabel 0,35, $"Mega plot append (f)", jobListW

	
	string jParamWName = jListWName+"_JobParams";
	jobListW[1] = jParamWName;
	if (!waveexists($jParamWName))
		make /N=28 $jParamWName;
		SetDimLabel 0,0,  $"flags", $jParamWName
		SetDimLabel 0,1,  $"n threads", $jParamWName
		SetDimLabel 0,2,  $"set from", $jParamWName
		SetDimLabel 0,3,  $"set to", $jParamWName
		SetDimLabel 0,4,  $"set steps", $jParamWName
		SetDimLabel 0,5,  $"---", $jParamWName
		SetDimLabel 0,6,  $"cmp to vary E0", $jParamWName
		SetDimLabel 0,7,  $"bi-directional", $jParamWName
		SetDimLabel 0,8,  $"set plot Comp#", $jParamWName
		SetDimLabel 0,9,  $"---", $jParamWName
		SetDimLabel 0,10, $"kilo from", $jParamWName
		SetDimLabel 0,11, $"kilo to", $jParamWName
		SetDimLabel 0,12, $"kilo steps", $jParamWName
		SetDimLabel 0,13, $"---", $jParamWName
		SetDimLabel 0,14, $"kilo param 1", $jParamWName
		SetDimLabel 0,15, $"kilo param 2", $jParamWName
		SetDimLabel 0,16, $"kilo flags", $jParamWName
		SetDimLabel 0,17, $"---", $jParamWName
		SetDimLabel 0,18, $"---", $jParamWName
		SetDimLabel 0,19, $"mega from", $jParamWName
		SetDimLabel 0,20, $"mega to", $jParamWName
		SetDimLabel 0,21, $"mega steps", $jParamWName
		SetDimLabel 0,22, $"---", $jParamWName
		SetDimLabel 0,23, $"mega param 1", $jParamWName
		SetDimLabel 0,24, $"mega param 2", $jParamWName
		SetDimLabel 0,25, $"mega flags", $jParamWName
		SetDimLabel 0,26, $"---", $jParamWName
		SetDimLabel 0,27, $"---", $jParamWName
	endif 

	string methodWName = jListWName+"_MethodParams";
	jobListW[2] = methodWName;
	if (!waveexists($methodWName))
		make /N=1 $methodWName 
		SetDimLabel 0,0,  $"name as needed", $methodWName
	endif 

	string esimWName = jListWName+"_ESimParams";
	jobListW[3] = esimWName;
	if (!waveexists($esimWName))
		make /N=21 $esimWName 
		SetDimLabel 0,0,  $"n threads", $esimWName
		SetDimLabel 0,1,  $"bi-directional", $esimWName
		SetDimLabel 0,2,  $"rate mode", $esimWName
		SetDimLabel 0,3,  $"lim rate mode", $esimWName
		SetDimLabel 0,4,  $"log mode", $esimWName
		SetDimLabel 0,5,  $"RKi drop max Sol", $esimWName
		SetDimLabel 0,6,  $"RKi rise max Sol", $esimWName
		SetDimLabel 0,7,  $"RKFull drop max Sol", $esimWName
		SetDimLabel 0,8,  $"RKFull rise max Sol", $esimWName
		SetDimLabel 0,9,  $"---", $esimWName
		SetDimLabel 0,10, $"layer thickness", $esimWName
		SetDimLabel 0,11, $"RKi drop max El", $esimWName
		SetDimLabel 0,12, $"RKi rise max El", $esimWName
		SetDimLabel 0,13, $"RKFull drop max El", $esimWName
		SetDimLabel 0,14, $"RKFull rise max El", $esimWName
		SetDimLabel 0,15, $"---", $esimWName
		SetDimLabel 0,16, $"RK hold on limit", $esimWName
		SetDimLabel 0,17, $"RK drop lim time X", $esimWName
		SetDimLabel 0,18, $"RK rise lim time X", $esimWName
		SetDimLabel 0,19, $"---", $esimWName
		SetDimLabel 0,20, $"RK4 next step X", $esimWName
	endif 

	string compWName = jListWName+"_Components";
	jobListW[4] = compWName;
	if (!waveexists($compWName))
		make /N=(15,1) $compWName 
		SetDimLabel 0,0,  $"init [Cox]", $compWName
		SetDimLabel 0,1,  $"init [Crd]", $compWName
		SetDimLabel 0,2,  $"E0", $compWName
		SetDimLabel 0,3,  $"n", $compWName
		SetDimLabel 0,4,  $"electr. k0", $compWName
		SetDimLabel 0,5,  $"alpha", $compWName
		SetDimLabel 0,6,  $"flags", $compWName
		SetDimLabel 0,7,  $"---", $compWName
		SetDimLabel 0,8,  $"el. max rate", $compWName
		SetDimLabel 0,9,  $"---", $compWName
		SetDimLabel 0,10, $"binding K", $compWName
		SetDimLabel 0,11, $"on rate", $compWName
		SetDimLabel 0,12, $"---", $compWName
		SetDimLabel 0,13, $"alias", $compWName
		SetDimLabel 0,14, $"---", $compWName
	endif 

	string eRxnsWName = jListWName+"_ERxns";
	jobListW[5] = eRxnsWName;
	if (!waveexists($eRxnsWName))
		make /WAVE /N=1 $eRxnsWName 
		wave /WAVE ERxns = $eRxnsWName;
		if (!waveexists($eRxnsWName+"_TD"))
			make /N=(0,2) $eRxnsWName+"_TD"
		endif
		
		ERxns[0] = $eRxnsWName+"_TD" 
	endif 	

	string gRxnsWName = jListWName+"_GRxns";
	jobListW[6] = gRxnsWName;
	if (!waveexists($gRxnsWName))
		make /WAVE /N=1 $gRxnsWName 
		wave /WAVE GRxns = $gRxnsWName;
		if (!waveexists($gRxnsWName+"_TD"))
			make /N=(0,2) $gRxnsWName+"_TD"
		endif
		GRxns[0] = $gRxnsWName+"_TD" 
	endif 	
	simReloadJob(win, jobListW)
end
