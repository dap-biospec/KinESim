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


constant maxSims=64 // this is a duplicate of constant defined in KES_Core_Struct because Igor does not allow to access it


//-------------------------------------------------------------------
// This datafield is for use in a single sub-set
//
structure setDataT
	string name; // object name of this sim
	string folder; // location of the sub-set
	wave JParWave // set/kilo/mega numerical parameters wave 
	wave PWave // Simulation parameters wave
	wave CWave // components wave
	wave MWave // method parameters wave 
	wave /WAVE ERxnsW //list of electrochemical reaction waves 
	wave /WAVE GRxnsW; //list of general reaction waves
	
	wave /T JListWave // text job parameters wave

	variable index; // index of this sim in the set

	// output
	string text; // verbose report to be printed in the history
	variable result; // optional result 
endstructure


//-------------------------------------------------------------------
// a list of setDataT structures of given length
structure setSetDataArrT
	variable count;
	STRUCT setDataT sets[maxSims];
endstructure


//-------------------------------------------------------------------
//
structure simSetDataT
	string commName; // common name of simulations in this set

	variable error; // report errors occuring during simulations
	string rootFldr; // where this set was executed
	string dataFldr; // where subset data are stored
	variable biDir; // enable bi-directional simulation

	wave setValueClb // calbration wave for the parameter that is varied in this set

	// ancestor waves, sim entries may modify them
	wave JParWave // set/kilo/mega numerical parameters wave 
	wave PWave // Simulation parameters wave
	wave CWave // components wave
	wave MWave // method parameters wave 
	wave /WAVE ERxnsW //list of electrochemical reaction waves 
	wave /WAVE GRxnsW; //list of general reaction waves

	// output
	string text; // verbose report to be printed in the history
	variable result; // optional result 
	
endstructure





//-------------------------------------------------------------------
// methods used for a single simulation

structure simMethodsT
	variable simNThreads; // number of CPU threads to use in the sim,
								// value can be forced to 1 by the set 

	// workaround for IM
//	FUNCREF simWSetupProto theSimWSetupF; 
	string theSimWSetupFN; // jobListW[7]; waveform setup user function 
	variable doSimWSetup;
	
//	FUNCREF simWProcessProto theSimWProcessF;
	string theSimWProcessFN; // jobListW[8]; sim processig user fuction
	variable doSimWProcess;
	
		
	FUNCREF simPlotBuildProto theSimPlotBuildF; // jobListW[17]
	variable doSimPlotBuild;
endstructure

//-------------------------------------------------------------------
// methods used for a set of simulations

structure setMethodsT
	string text; // verbose report to be printed in the history 
	string modeName; // text indicating the mode (simulation, processing, re-assmbly of data) 
	string offset; // verbose report offset to visualize hierarchy
	
	variable setNThreads; // number of CPU threads to use in the set,
								// value >1 forces individual simulations to be done in a single thread

	
	FUNCREF setInputSetupProto theSetInSetupF;  // jobListW[11];
	variable doSetInSetup;
	
	FUNCREF setInputAssignProto theSetInAssignF;  // jobListW[12];
	variable doSetInAssign;
	
	FUNCREF setResultSetupProto theSetResultSetupF; // jobListW[13];
	variable doSetOutSetup;
	
	FUNCREF setResultAssignProto theSetResultAssignF; // jobListW[14];
	variable doSetOutAssign;
	
	FUNCREF setResultCleanupProto theSetResultCleanupF; // jobListW[15];
	variable doSetOutCleanup;

	FUNCREF setPlotSetupProto theSetPlotSetupF; //  jobListW[16]
	variable doSetPlotBuild;
	
	FUNCREF setPlotAppendProto theSetPlotAppendF; 
	variable doSetPlotAppend;
endstructure

//------------------------------------------------------------------------------------
// methods used for a group of simulations

structure groupMethodsT
	string text; // verbose report to be printed in the history

	string theGroupInSetupFN
	FUNCREF GroupInputSetupProto theGroupInSetupF;  
	variable doGroupInSetup;
	
	string theGroupInAssignFN;
	FUNCREF GroupInputAssignProto theGroupInAssignF;  
	variable doGroupInAssign;
	
	string theGroupResultSetupFN
	FUNCREF groupResultSetupProto theGroupResultSetupF; ;
	variable doGroupOutSetup;

	string theGroupResultAssignFN;
	FUNCREF GroupResultAssignProto theGroupResultAssignF; 
	variable doGroupOutAssign;

	string theGroupResultCleanupFN;
	FUNCREF GroupResultCleanupProto theGroupResultCleanupF; 
	variable doGroupOutCleanup;

	string theSetPlotSetupFN
	FUNCREF setPlotSetupProto theGroupPlotSetupF; 
	variable doGroupPlotBuild;

	string theSetPlotAppendFN;
	FUNCREF GroupPlotAppendProto theGroupPlotAppendF; 
	variable doGroupPlotAppend;
endstructure

