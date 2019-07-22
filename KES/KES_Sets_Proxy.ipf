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


//----------------------------------------------------------
// Proxy for  user-supplied function performing preparation of inpur waveform wave

threadsafe  function simWSetupProto(setData, simData) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simDataT &simData;
	
end

//----------------------------
//

function KES_userSimSetup(simWSetupFN, setData, simData)
	string simWSetupFN;
	STRUCT simSetDataT &setData;
	STRUCT KES#simDataT &simData;
	
	FUNCREF simWSetupProto simWSetupF = $simWSetupFN;
	if (NumberByKey("ISPROTO", FuncRefInfo (simWSetupF)))
		simData.text = "== Reference to function \""+(simWSetupFN)+"\" has not been resolved! ==\r"
		setData.error = 1
		return 0; 
	endif
	simWSetupF(setData, simData)
	return 1	
end


//----------------------------------------------------------
// Proxy for  user-supplied function performing post-processing of simulated wave

threadsafe  function /WAVE simWProcessProto(ResultWNSuffix, simData) 
	string ResultWNSuffix
	STRUCT KES#simDataT &simData;	
	
end

//----------------------------
//

function KES_userSimProcess(simWProcessFN, ResultWNSuffix, simData)
	string simWProcessFN;
	string ResultWNSuffix
	STRUCT KES#simDataT &simData;

	
	FUNCREF simWProcessProto simWProcessF = $simWProcessFN;
	if (NumberByKey("ISPROTO", FuncRefInfo (simWProcessF)))
		simData.text = "== Reference to function \""+(simWProcessFN)+"\" has not been resolved! ==\r"
		return 0; 
	endif
	simWProcessF(ResultWNSuffix, simData)
	
 	return 1;
 end



//----------------------------------------------------------------------------------------------
//
//			 prototype function for creating a single sim plot in a series
//	
//-----------------------------------------------
//
// this function does not return a value 

 function simPlotBuildProto(plotNameS, SimData, SetData) 
	string plotNameS // name of the plot/window
	STRUCT simSetDataT &SetData;
	STRUCT KES#simDataT &SimData;
	
	print "Prototype Plot Build functions called. "
end



//----------------------------------------------------------------------------------------------
//
// 		prototype function for set input variable value setup & calculation
//
//-----------------------------------------------
//
// this function returns status string

threadsafe function /S setInputSetupProto(setData, setEntries) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &setEntries;

	variable Set_From =  setData.JParWave[2];
	variable Set_To =  setData.JParWave[3];
	variable Set_Steps =  setData.JParWave[4];
	setData.setValueClb = Set_From + p * (Set_To - Set_From) / (Set_Steps-1);
	
	return "This is a set setup template function. It should not be called directly. "
end

//-----------------------------------------------
//
// this function returns status string
threadsafe function /S groupInputSetupProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	variable Set_From =  setData.JParWave[2];
	variable Set_To =  setData.JParWave[3];
	variable Set_Steps =  setData.JParWave[4];
	setData.setValueClb = Set_From + p * (Set_To - Set_From) / (Set_Steps-1);
	
	return "This is a set setup template function. It should not be called directly. "
end


//-----------------------------------------------
//
// this function does not return a value

threadsafe function setInputAssignProto(setData, setEntries) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &setEntries;

	// create copies of parametric waves that contain variable parameter; 
	// RWave must be duplicated for threaded cacluclation regardless of whether values are changed by the assignement 
	
	// most applicaitons will modify only one of these waves and only such wave need to be copied
	variable i;
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		duplicate /O setData.PWave $(tgtSimPath+"P")
		WAVE setEntries.sims[i].PWave = $(tgtSimPath+"P")
		duplicate /O setData.MWave $(tgtSimPath+"M")
		WAVE setEntries.sims[i].MWave = $(tgtSimPath+"M")
	endfor
end


//-----------------------------------------------
//
// this function does not return a value

threadsafe function groupInputAssignProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	// create copies of parametric waves that contain variable parameter; 
	// RWave must be duplicated for threaded cacluclation regardless of whether values are changed by the assignement 
	
	// most applicaitons will modify only one of these waves and only such wave need to be copied
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+groupEntries.sets[i].name
		duplicate /O setData.PWave $(tgtSimPath+"P")
		WAVE groupEntries.sets[i].PWave = $(tgtSimPath+"P")
		duplicate /O setData.CWave $(tgtSimPath+"C")
		WAVE groupEntries.sets[i].CWave = $(tgtSimPath+"C")
		duplicate /O setData.ERxnsW $(tgtSimPath+"ER")
		WAVE /WAVE groupEntries.sets[i].ERxnsW = $(tgtSimPath+"ER")
		duplicate /O setData.GRxnsW $(tgtSimPath+"GR")
		WAVE /WAVE groupEntries.sets[i].GRxnsW = $(tgtSimPath+"GR")
		duplicate /O setData.MWave $(tgtSimPath+"M")
		WAVE groupEntries.sets[i].MWave = $(tgtSimPath+"M")
	endfor
end

//----------------------------------------------------------------------------------------------
//
//			 prototype function for set input variable value assignment
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 

threadsafe function /S simInputAssignProto(setData, simData) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simDataT &simData;
	
	return "Prototype set input assign function called. "
end


//----------------------------------------------------------------------------------------------
//
// 		prototype function for set result wave setup 
//
//-----------------------------------------------
//
// this function does not return a value

function setResultSetupProto(setData, setEntries) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &setEntries;

	Print "This is a set setup template function. It should not be called directly. "
end

//-----------------------------------------------
//

function groupResultSetupProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	Print "This is a set setup template function. It should not be called directly. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for set result wave assignment
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 
threadsafe function setResultAssignProto(setData,simData) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simDataT &simData;

	print "Prototype set result assign functions called. "
end


//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 
threadsafe function groupResultAssignProto(groupData,setData) 
	STRUCT simSetDataT &groupData;
	STRUCT setDataT &setData;

	print "Prototype set result assign functions called. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for set result final steps
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 

function setResultCleanupProto(setData, setEntries, setResultWN) 
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &setEntries;
	string setResultWN; // common name for the set....

	// only temp waves that were created in setInputSetupProto need to be deleted here
	variable i;
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		killwaves /Z $(tgtSimPath+"P"),  $(tgtSimPath+"C"),  $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M"), $(tgtSimPath+"RK4") //,  $(tgtSimPath+"M")
	endfor

	print "Prototype result cleanup functions called. "
end

//-----------------------------------------------
//

function groupResultCleanupProto(setData, groupEntries, setResultWN) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;
	string setResultWN; // common name for the set....

	// only temp waves that were created in setInputSetupProto need to be deleted here
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+groupEntries.sets[i].name
		killwaves /Z $(tgtSimPath+"P"),  $(tgtSimPath+"C"),  $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M")
	endfor

	print "Prototype result cleanup functions called. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for preparing data to plot in a set 
//	
//-----------------------------------------------
//
// this does not return a value 

function setPlotSetupProto(setData, plotNameS) 
	STRUCT simSetDataT &setData;
	string plotNameS // name of the plot/window

	// prepare a plot (or plots)  here to append results later
	print "Prototype Plot Setup functions called. "
end



//----------------------------------------------------------------------------------------------
//
//			 prototype function for appending data to plot in a set 
//	
//-----------------------------------------------
//
// this does not return a value 

function setPlotAppendProto(setData, setEntries, plotNameS, iteration)
	STRUCT simSetDataT &setData;
	STRUCT KES#simSetDataArrT &setEntries;
	string plotNameS // name of the plot/window
	variable iteration // call # in this superset

	print "Prototype Plot Append functions called. "
end

//-----------------------------------------------
//
function groupPlotAppendProto(setData, setEntries, plotNameS, iteration)
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &setEntries;
	string plotNameS // name of the plot/window
	variable iteration // call # in this superset

	print "Prototype Plot Append functions called. "
end

