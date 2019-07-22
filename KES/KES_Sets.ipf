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

#include ":KES_Core", version >= 20190711
#include ":KES_Sets_Struct", version >= 20190711
#include ":KES_Sets_Flow", version >= 20190711
#include ":KES_Sets_Proxy", version >= 20190711
#include ":KES_Sets_Progress", version >= 20190711
#include ":KES_Sets_Aux", version >= 20190711

strconstant cKESSetsVer =  "1.7.0a"


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Set_MedEChem(jobListW, [prefix, offset, hostPrg, doSingle] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KES#SetProgDataT &hostPrg;
	variable doSingle;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif

	if (paramIsDefault(hostPrg))
		variable noPrg = 1
	endif

	if (paramIsDefault(doSingle))
		doSingle = 0;
	endif
	
	
	STRUCT simSetDataT setData;

	// prepare data structures
	try
		STRUCT KES#simSetDataArrT setEntries;
		simSetPrepData(jobListW, setData, setEntries, prefix,  justOne = doSingle);
		
	
		// prepare method strcutures
		STRUCT simMethodsT simM;
		STRUCT setMethodsT setM;
		if (simSet_PrepMethods(setData, jobListW, simM, setM, setData.JParWave[0], offset, prefix,  justOne = doSingle) < 0)
			return -1; // there was a problem
		endif
		
		variable i, j  
		for (i=0 ; i<setEntries.count; i+=1)
			setEntries.sims[i].text = prefix;
		endfor 
	
		if (setM.doSetInSetup && !doSingle)
			string outStr = setM.theSetInSetupF(setData, setEntries) 
			if (strlen(outStr) >0)
				setData.text += "\r"+offset+outStr;
			endif;
		endif;
		 
		// duplicate CWave and RWaves
		for (i=0; i< setEntries.count; i+=1)
			string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
			duplicate /O setData.CWave $(tgtSimPath+"C")
			WAVE setEntries.sims[i].CWave = $(tgtSimPath+"C")
		endfor
	 
	
		if (setM.doSetInAssign && !doSingle)
			setM.theSetInAssignF(setData, setEntries) 
		endif;
		
		if (setM.doSetOutSetup && !doSingle)
			setM.theSetResultSetupF(setData, setEntries) 
		endif;
		
		Variable setSimStartTime = DateTime
		
		string thisSimName; 
		variable result = 0;
		
		if (noPrg)
			STRUCT KES#SetProgDataT locPrg;
			if (setM.setNThreads > 1) // parallel MT sims 
				result = simSet_FullSimPrl(setData, setEntries, simM, setM, locPrg)
			else // sequential sims 
				result = simSet_FullSimSeq(setData, setEntries, simM, setM, locPrg)
			endif 			
		else
			hostPrg.hosted = 1;
			if (setM.setNThreads > 1) // parallel MT sims 
				result = simSet_FullSimPrl(setData, setEntries, simM, setM, hostPrg)
			else // sequential sims 
				result = simSet_FullSimSeq(setData, setEntries, simM, setM, hostPrg)
			endif 
		endif 
	
		// Simulation is done, clean up and process results
		for (i=setEntries.count; i<99; i+=1) // clean up unused waves //Set_Steps
			sprintf thisSimName "%s%02d" setData.commName, i
			string killListS = wavelist(thisSimName+"_*", ";","") 
			string killNameS;
			j = 0
			do
				killNameS= StringFromList(j,killListS)
				if( strlen(killNameS) == 0 )
					break
				endif
				killwaves /Z 	$killNameS;
				j += 1
			while (1)	// exit is via break statement
			// killwaves /Z 	$(thisSimName), $(thisSimName+"_i"), $(thisSimName+"f"), $(thisSimName+"f_i"),$(thisSimName+"r"), $(thisSimName+"r_i")			
		endfor
			
		SetDataFolder $setData.rootFldr
	
		variable setSimEndTime = DateTime;
			
		// print output
		if (result >=0) 
			if (noPrg)
				print offset, setM.text
			endif 
			print setData.text;
			for (i=0; i < setEntries.count; i+=1)
				print offset, setEntries.sims[i].text;
			endfor
		
			string BiDirS = "";
			if (setData.BiDir)
				BiDirS = "x2 ";
			endif;
			
			Printf "%sTotal time: %0.2fs for %s%d %s", offset , (setSimEndTime - setSimStartTime), BiDirS, setEntries.count, setM.modeName;
			
			// Plot the results after simulation is complete
			// this is non-thread safe operation
			
			if (simM.doSimPlotBuild) // individual plots for each sim
				for (i=0; i < setEntries.count; i+=1)
					simM.theSimPlotBuildF(setData.commName, setEntries.sims[i], setData) 
				endfor
			endif
		
			string gizmoN = prefix+setData.commName+"Set";
			if (setM.doSetPlotBuild && !doSingle)
				setM.theSetPlotSetupF(setData, gizmoN); //, MWave,  JParWave, setValueClb);
			endif
		
			if (setM.doSetPlotAppend  && !doSingle)
				for (i=0; i < setEntries.count; i+=1)
					setM.theSetPlotAppendF(setData, setEntries, gizmoN, i); 
				endfor
			endif 
		
			if (setM.doSetOutCleanup && !doSingle)
				setM.theSetResultCleanupF(setData, setEntries,  setData.rootFldr+setData.commName)
			endif
		
			variable setProcessEndTime = DateTime
			
			printf "\r%sProcessing time: %.2f sec", offset, (setProcessEndTime - setSimEndTime);
		else 
			print setData.text;
		endif 
		printf "\r%s#\r",offset 
	
	catch
		switch (V_AbortCode)
			endswitch
		SetDataFolder $setData.rootFldr
		print " sim aborted";
		if (noPrg)
			killwindow /Z mySetProgress
		else
			killwindow /Z $hostPrg.wName 
		endif 
	endtry	 
 	
	// cleanup C and R waves!
	for (i=0; i< setEntries.count; i+=1)
		tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		killwaves /Z $(tgtSimPath+"P"),   $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M"), $(tgtSimPath+"RK4")
	endfor

end

 

//-----------------------------------------------
//
function simSet_FullSimPrl(setData, setEntries, simM, setM, prgDlg) 
	STRUCT simSetDataT &setData; 
	STRUCT KES#simSetDataArrT &setEntries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT KES#SetProgDataT &prgDlg;

	defaultSetPrg(prgDlg,  setEntries.count, "")
	
	variable i, dummy
	
	string StOutWaveN = setData.dataFldr+setData.commName+"_RES";
	make  /O  /N=(setEntries.count, 13) $StOutWaveN
	wave  StOWave =  $StOutWaveN;
	StOWave[][]=NaN;
	StOWave[][4,5]=0;
	StOWave[][10,12]=0;
	
	// prepare set
	variable points_total;
	for (i=0; i<setEntries.count; i+=1) 
		if (simM.doSimWSetup) 	// prepare wave
			KES_userSimSetup(simM.theSimWSetupFN, setData, setEntries.sims[i])
			setEntries.sims[i].text += "=>"+setEntries.sims[i].name+" ";				
		endif
		points_total += dimsize(setEntries.sims[i].SWave, 0)
		
		string result = KES#checkSimInput(setEntries.sims[i].SWave, setEntries.sims[i].CWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW) 
		if (strlen(result))
			print result;
			setData.error = i;
			return -104;
		endif
		
		string tmpName = setEntries.sims[i].name + "_Rx"
		make  /O /N=(0,(dimSize(setEntries.sims[i].CWave,1)+1),2) $tmpName
		wave setEntries.sims[i].RxnsTmp = $tmpName
		setEntries.sims[i].RxnsTmp[][][] = -1;

		string  resStr = KES#appendRxnsTable(setEntries.sims[i].RxnsTmp, setEntries.sims[i].GRxnsW, setEntries.sims[i].CWave, setEntries.sims[i].PWave[2], 0);
		if (strlen(resStr) > 0)
			print resStr;
			setData.error = i;
			return -105;
		endif
	
		resStr = KES#appendRxnsTable(setEntries.sims[i].RxnsTmp, setEntries.sims[i].ERxnsW, setEntries.sims[i].CWave, setEntries.sims[i].PWave[2], 1);
		if (strlen(resStr) > 0)
			print resStr;
			setData.error = i;
			return -106;
		endif
		
		if (dimsize(setEntries.sims[i].RxnsTmp, 0) <=0)
			wave theW =setEntries.sims[i].RxnsTmp  
			killwaves /Z theW
			wave setEntries.sims[i].RxnsTmp = $""
		endif
//		setLogWaveS(setEntries.sims[i]);
	endfor	

	Variable setGroupID= ThreadGroupCreate(setM.setNThreads > 0 ? setM.setNThreads : 1)
	prgDlg.set_points = points_total;
	prgDlg.thGroupId = setGroupID;
	KES#SetProgressStart(prgDlg); 

	// perform sim 	
	variable killFlag = 0;
	Variable threadGroupStatus;
	try 
		if (simM.doSimWSetup)
			for (i=0; i<setEntries.count; i+=1) 
				if (setM.setNThreads > 0)
					Variable threadIndex;
					do
						threadIndex = ThreadGroupWait(setGroupID,-2) - 1
						if (threadIndex < 0)// Let threads run a while
							threadGroupStatus=waitForThreadGroup(setGroupID, StOWave, prgDlg, 100)
							killFlag = KES#doSetProgressUpdate(prgDlg); 
						endif
					while (!killFlag &&  threadIndex < 0)
					if (!killFlag && threadIndex >= 0) // 
						// parallel set uses sequential integration
						ThreadStart setGroupID, threadIndex,  KES#Sim_Core_Seq(	setEntries.sims[i].SWave, 	setEntries.sims[i].CWave, setEntries.sims[i].PWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW, setEntries.sims[i].RxnsTmp, StOWave, i, setEntries.sims[i].LogWave, setEntries.sims[i].logMode) 
						prgDlg.set_curr_sim_in +=1;
					else
						break
					endif 
				else
					killFlag = KES#doSetProgressUpdate(prgDlg); 
					// this needs to be modified to conform to the single sim verions before two methods can be merged
	//				Sim_Core_MT(	setEntries.sims[i].SWave, 	setEntries.sims[i].CWave, setEntries.sims[i].PWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW, setEntries.sims[i].RxnsTmp, prepF, ratesF, StOWave, i, setEntries.sims[i].LogWave) 
					prgDlg.set_curr_sim_in +=1;			
				endif
			endfor
			if (setM.setNThreads > 1 &&  !killFlag) // wait for completion 
				do
					threadGroupStatus=waitForThreadGroup(setGroupID, StOWave, prgDlg, 100)
					killFlag = KES#doSetProgressUpdate(prgDlg); 
				while(!killFlag && threadGroupStatus != 0)
			endif
		endif;
		
		KES#SetProgressStop(prgDlg)
		
		// process results
		variable cpuTime = 0;
		for (i=0; i<setEntries.count; i+=1) 
			// retreive sim output
			string flags = ""
			string OutStr; 
			sprintf OutStr, "Simulation time: %0.2f sec for %u points over %u steps (%0.2fus/step); %u holds, %u resets, %u setbacks; Parallel, IntThr=%u; %s", \
					( StOWave[i][2]), StOWave[i][3], StOWave[i][4], (StOWave[i][2])*1e6 /StOWave[i][3],  StOWave[i][10],  StOWave[i][11],  StOWave[i][12], simM.simNThreads, flags \
	
			cpuTime += StOWave[i][2];
			setEntries.sims[i].text += outStr;
		
			 if (simM.doSimWProcess) // continue to process data
			 	KES_userSimProcess(simM.theSimWProcessFN, "_i", setEntries.sims[i]);
				setEntries.sims[i].text += "=> " + nameofwave(setEntries.sims[i].ProcSWave)
			else
				WAVE setEntries.sims[i].ProcSWave =setEntries.sims[i].SWave; 
			endif 
			 
			 if (setM.doSetOutAssign) // continue to save results
				setM.theSetResultAssignF(setData, setEntries.sims[i]) 
			endif 
			setEntries.sims[i].text = setM.offset + setEntries.sims[i].text
		endfor	
		
		string summaryText;
		if (setM.setNThreads > 1)
			sprintf summaryText, "Set real time %0.2f sec for %0.2f sec CPU time; x%0.1f over %g threads", (prgDlg.set_stop_time - prgDlg.set_start_time ), cpuTime, cpuTime/(prgDlg.set_stop_time - prgDlg.set_start_time ), setM.setNThreads
		else
			sprintf summaryText, "Set real time %0.2f sec, single thread;"
		endif; 
		if (prgDlg.aborted > 0)
			summaryText += " =Aborted= ";
		endif 
		setData.text += "\r"+setM.offset+summaryText;
		if (prgDlg.thGroupId > 0)
			dummy= ThreadGroupRelease(prgDlg.thGroupId)
		endif
		// clean up output waves!
		killwaves /Z StOWave
		return 0;
	catch	// sim failed or killed
		threadIndex = ThreadGroupRelease	(setGroupID);		
		KES#SetProgressStop(prgDlg)
		// clean up output waves!
		killwaves /Z StOWave
		switch (V_AbortCode)
			case -3:
			case -1:
				setData.text += "\r = Aborted by user = ";
				break;
			default: 
				setData.text += "\r = Aborted with code "+num2str(V_AbortCode)+" = ";
		endswitch
		return V_AbortCode		
	endtry
	
end


////-----------------------------------------------
////
function simSet_FullSimSeq(setData, entries, simM, setM, prgDlg)  
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &entries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT KES#SetProgDataT &prgDlg;

	KES#defaultSetPrg(prgDlg, entries.count, "")
	
	string StOutWaveN = setData.dataFldr+setData.commName+"_RES";
	make  /O  /N=(entries.count, 13) $StOutWaveN
	wave  StOWave =  $StOutWaveN;
	StOWave=NaN;

	variable nMT;
	variable s

	KES#SetProgressStart(prgDlg);
	try
		for (s=0; s<entries.count; s+=1) 
			prgDlg.set_curr_sim_in +=1;
			if (simM.doSimWSetup) 	// prepare wave
				KES_userSimSetup(simM.theSimWSetupFN, setData, entries.sims[s])
				// data have been set up, can update progress stats
				if (prgDlg.set_points == 0)
					prgDlg.set_points= dimsize(entries.sims[s].SWave, 0)*entries.count;
					KES#doSetProgressSteps(prgDlg);				
				endif
				
				
				entries.sims[s].text += "=>"+entries.sims[s].name+" ";				
			
				string result = KES#checkSimInput(entries.sims[s].SWave, entries.sims[s].CWave, entries.sims[s].ERxnsW, entries.sims[s].GRxnsW) 
				if (strlen(result))
					print result;
					setData.error = s;
					return -104;
				endif
			
				// perform  simulation
				KES#doSetProgressUpdate(prgDlg);
				// sequential sim uses parallel integration
			   KES#Sim_Core_Prl(entries.sims[s], StOWave, s, simM.simNThreads, prgDlg) 
			   string flags = "" // retreive form stats structure
				string OutStr; 
				sprintf OutStr, "Simulation time: %0.2f sec for %u points over %u steps (%0.2fus/step); %u holds, %u resets, %u setbacks; Sequential, IntThr=%u; %s", \
						StOWave[s][2], StOWave[s][3], StOWave[s][4], (StOWave[s][2])*1e6 /StOWave[s][3],  StOWave[s][10],  StOWave[s][11],  StOWave[s][12], simM.simNThreads, flags
				
				entries.sims[s].text += outStr;
				prgDlg.set_curr_s += StOWave[s][4]; 
				prgDlg.set_curr_i += StOWave[s][5];
				prgDlg.set_curr_hold = StOWave[s][10];
				prgDlg.set_curr_restart = StOWave[s][11];
				prgDlg.set_curr_lim = StOWave[s][12];
			endif
			prgDlg.set_curr_sim_out +=1;
			KES#doSetProgressUpdate(prgDlg);
			 
			 if (simM.doSimWProcess) // continue to process data
			 	KES_userSimProcess(simM.theSimWProcessFN, "_i", entries.sims[s]);
				entries.sims[s].text += "=> " + nameofwave(entries.sims[s].ProcSWave)
			else
				WAVE entries.sims[s].ProcSWave =entries.sims[s].SWave; 
			endif 
			 
			 if (setM.doSetOutAssign) // continue to save results
				setM.theSetResultAssignF(setData, entries.sims[s]) 
			endif 
	
			KES#doSetProgressUpdate(prgDlg);
			
		endfor
		KES#SetProgressStop(prgDlg);
		return 0
	catch	// sim failed or killed
		KES#SetProgressStop(prgDlg)
		// clean up output waves!
		killwaves /Z StOWave
		switch (V_AbortCode)
			case -3:
			case -1:
				setData.text += "\r = Aborted by user = ";
				break;
			default: 
				setData.text += "\r = Aborted with code "+num2str(V_AbortCode)+" = ";
		endswitch
		return V_AbortCode		
	endtry

	// do not do plotting here!
end


//------------------------------------------------------------------------------------
//
//
function Kilo_MedEChem05(jobListW, [prefix, offset, hostPrg] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KES#KiloProgDataT &hostPrg;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif
	
	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT KES#KiloProgDataT locPrg;
		defaultKiloPrg(locPrg, 0, 0, "")
		return Kilo_MedEChem05Prg(jobListW, prefix, offset,   locPrg);
	else // progress dialog is hosted
		defaultKiloPrg(hostPrg, 1, 0, "")
		return Kilo_MedEChem05Prg(jobListW, prefix, offset,  hostPrg);
	endif
end


//------------------------------------------------------------------------------------
//
//
function Mega_MedEChem05(jobListW, [prefix, offset, hostPrg] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KES#MegaProgDataT &hostPrg;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif
	
	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT KES#MegaProgDataT locPrg;
		defaultMegaPrg(locPrg, 0, 0, "")
		return Mega_MedEChem05Prg(jobListW, prefix, offset,   locPrg);
	else // progress dialog is hosted
		defaultMegaPrg(hostPrg, 1, 0, "")
		return Mega_MedEChem05Prg(jobListW, prefix, offset,  hostPrg);
	endif
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//								  																					 //
//									Sets of simulations section												 //
//																													 //
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//




//-----------------------------------------------
//

function Kilo_MedEChem05Prg(jobListW, prefix, offset,  hostPrg)
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KES#KiloProgDataT &hostPrg;

	if (!waveexists(jobListW))
		printf "%sJob wave (%s) was not found...\r", offset, nameofwave(jobListW);
		return 1;
	endif

	// this struct must be initialized!
	STRUCT simSetDataT setData;
	STRUCT setSetDataArrT setEntries;
	if (simGroupPrepData(jobListW, setData, setEntries, prefix, 12, "Kilo", "K%02d"))
		print offset+setData.text+"\r"
		return 1;
	endif; 
	
	STRUCT groupMethodsT grMethods;
	if (prepGroupMethods(grMethods, jobListW, 20)) 
		print offset + grMethods.text+"\r";
		return 1;
	endif

	reportGroupMethods(grMethods, setData,  "Kilo", offset, prefix );

	if (grMethods.doGroupInSetup)
		grMethods.text += "\r"+offset+ grMethods.theGroupInSetupF(setData, setEntries);
	endif
	if (grMethods.doGroupInAssign)
		grMethods.theGroupInAssignF(setData, setEntries);
	endif
	
	if (grMethods.doGroupOutSetup)
		grMethods.theGroupResultSetupF(setData, setEntries)
	endif 
	
	string plotName = prefix+setData.commName+"Kilo"+"Set";
	if (grMethods.doGroupPlotBuild)
		grMethods.theGroupPlotSetupF(setData, plotName) 
	endif 

	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r"
	printf grMethods.text+"\r";

	hostPrg.set_sets = setEntries.count;
	hostPrg.set_curr_set_out = 0;
	KiloProgressStart(hostPrg); 
	
	variable i;
	for (i=0; i < setEntries.count; i+=1)
		SetDataFolder  $(setEntries.sets[i].folder);

		switch (setEntries.sets[i].JParWave[0]) // mode of sim
			case 0:
			case 1: 				
				printf "%s~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r", offset
				printf "%sSet:%s\r",  offset, setEntries.sets[i].name
				printf "%s%s\r",  offset, setEntries.sets[i].text
				break;
			default:
		endswitch		
		Set_MedEChem(setEntries.sets[i].JListWave, prefix=setEntries.sets[i].name, offset=offset+"\t", hostPrg = hostPrg);

		if (grMethods.doGroupOutAssign)
			grMethods.theGroupResultAssignF(setData, setEntries.sets[i]) 
		endif
		if (grMethods.doGroupPlotAppend)
			grMethods.theGroupPlotAppendF(setData, setEntries, plotName,  i);
		endif
		// restore folder
		SetDataFolder $setData.rootFldr
		hostPrg.set_curr_set_out  = i+1;
		doKiloProgressUpdate(hostPrg)
	endfor
	KiloProgressStop(hostPrg);	

	if (grMethods.doGroupOutCleanup)
		grMethods.theGroupResultCleanupF(setData, setEntries, setData.rootFldr+setData.commName);
	endif
end




//-----------------------------------------------
//

function Mega_MedEChem05Prg(jobListW, prefix, offset,  hostPrg)
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KES#MegaProgDataT &hostPrg;
	
	if (!waveexists(jobListW))
		printf "%sJob wave (%s) was not found...\r", offset, nameofwave(jobListW);
		return 1;
	endif

	// this struct must be initialized!
	STRUCT simSetDataT setData;
	STRUCT setSetDataArrT setEntries;
	if (simGroupPrepData(jobListW, setData, setEntries, prefix, 21, "Mega", "M%02d"))
		print offset+setData.text+"\r"
		return 1;
	endif; 
	
	STRUCT groupMethodsT grMethods;
	if (prepGroupMethods(grMethods, jobListW, 29)) 
		// report error
		print offset + grMethods.text+"\r";
		return 1;
	endif

	reportGroupMethods(grMethods, setData,  "Mega", offset, prefix );

	
	if (grMethods.doGroupInSetup)
		print "\r"+offset+ grMethods.theGroupInSetupF(setData, setEntries)
	endif
	if (grMethods.doGroupInAssign)
		grMethods.theGroupInAssignF(setData, setEntries);
	endif
	
	if (grMethods.doGroupOutSetup)
		grMethods.theGroupResultSetupF(setData, setEntries)
	endif 
	
	string plotName = prefix+setData.commName+"Mega"+"Set";
	if (grMethods.doGroupPlotBuild)
		grMethods.theGroupPlotSetupF(setData, plotName) 
	endif 

	
	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	printf grMethods.text+"\r";

	hostPrg.kilo_sets = setEntries.count;
	hostPrg.kilo_curr_set_out = 0;
	MegaProgressStart(hostPrg); 

	String currFldr= GetDataFolder(1)
	variable i;
	for (i=0; i<setEntries.count; i+=1)
		SetDataFolder  $(setEntries.sets[i].folder);
	
		switch (setEntries.sets[i].JParWave[0]) // mode of sim
			case 0:
			case 1: 				
				printf "%s~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r",offset
				printf "%sSet:%s \r",   offset, setEntries.sets[i].name
				printf "%s%s\r",  offset, setEntries.sets[i].text
				break;
			default:
		endswitch			
		
		Kilo_MedEChem05(setEntries.sets[i].JListWave, prefix = setEntries.sets[i].name, offset = offset+"\t", hostPrg = hostPrg);
		
		if (grMethods.doGroupOutAssign)
			grMethods.theGroupResultAssignF(setData, setEntries.sets[i]) 
		endif
		if (grMethods.doGroupPlotAppend)
			grMethods.theGroupPlotAppendF(setData, setEntries, PlotName,  i);
		endif

		// restore folder
		SetDataFolder $currFldr
		hostPrg.kilo_curr_set_out  = i+1;
		doMegaProgressUpdate(hostPrg)
	endfor
	MegaProgressStop(hostPrg);	

	if (grMethods.doGroupOutCleanup)
		grMethods.theGroupResultCleanupF(setData, setEntries, currFldr+setData.commName);
	endif

end

