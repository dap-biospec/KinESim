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
#pragma IndependentModule=KES 
  
constant  DbgBase =9
constant  DbgExt =8
constant  DbgM = 24 
constant  DbgLen = 150000 
//constant  DoDbg = 1; // on/off flag for debug logging
constant  DoDbgUpdate = 0;
constant TWaveLen = 50  

constant S_C_Offs = 14 // offset of 1st component in the SimWave
constant S_C_Num = 11 // number of parameters per component

constant maxSims=64

//-------------------------------------------------------------------

threadsafe function get_S_C_Offet4i(i)
	variable i
	return S_C_Offs + i * S_C_Num
end

//-------------------------------------------------------------------

threadsafe function get_S_C_Offs()
	return S_C_Offs
end

//-------------------------------------------------------------------

threadsafe function get_S_C_Num()
	return S_C_Num
end

//-------------------------------------------------------------------

threadsafe function get_MaxSims()
	return maxSims
end

//-------------------------------------------------------------------
// This datafield is for use in a single simulation
//
structure simDataT
	string name; // object name of this sim
	wave PWave // Simulation parameters wave
	wave CWave // components wave
	wave MWave // method parameters wave 
	wave /WAVE ERxnsW //list of electrochemical reaction waves 
	wave /WAVE GRxnsW; //list of general reaction waves
	wave RxnsTmp // internal use
	wave LogWave; // logging wave reference for debugging, if mode is set to on
	variable logMode; // logging mode

	variable direction; 	// 0 - no dir
								// >0 positive, forward
								// <0 negative, reverse
								
	variable index; // running order of this sim in the set
	variable group; // group index, this may be the same as position in the set or may inidicate index of plot etc...
	
	
	// output
	string text; // verbose report to be printed in the history
	variable result; // optional result 

	// output waves 					
	wave SWave; // simulation wave containing all components at all points defined by method setup
	wave ProcSWave; // wave containing results of processing of SWave by a custom user function  
	variable misc; // flags for hosting function purposes
	variable stealth; // supress output if fucntion is hosted in multiple interation fit function, for example
	
	// to overcome thread barrier
	variable S_C_Offs // offset of 1st component in the SimWave
	variable S_C_Num  // number of parameters per component

endstructure

//-------------------------------------------------------------------
// a list of simDataT structures of given length
structure simSetDataArrT
	variable count;
	STRUCT simDataT sims[maxSims];
endstructure


//-------------------------------------------------------------------
// This datafield is for internal use by RK4 integrator
//
structure simTmpDataT
	wave TWave;
	wave RKWave;
	wave RKTmpWave; 
	wave RSolW;
	wave RKSolW;
	wave AliasW;
endstructure


//-------------------------------------------------------------------
//
structure stepStatsT
	variable lim_code_inner0;
	variable lim_rel_inner0;
	variable lim_code_inner1;
	variable lim_rel_inner1;
	variable lim_code_inner2;
	variable lim_rel_inner2;
	variable lim_code_inner3;
	variable lim_rel_inner3;
	variable lim_code_outer;
	variable lim_rel_outer;
	
	variable steps_count;
	variable rates_count;
	variable counter;
	variable init_step_t;
	variable final_step_t;
	
	variable holds_count;
	variable restart_count;
	variable limit_count;
	
	variable doLog;
	
	WAVE StatRiseWave;
	WAVE StatDropWave;
	WAVE StatStepWave;
	variable lim_Worst_Cmp;
endstructure

//-------------------------------------------------------------------
//
structure simPointStats
	variable steps_count;
	variable rates_count;
	
	variable holds_count;
	variable restart_count;
	variable limit_count;
endstructure

//-------------------------------------------------------------------
//
//
structure simStatsT
	variable startTime;
	variable stopTime;
	variable runTime;
	variable steps;
	variable points;
	variable flags;
	variable error;
	variable holds_count_cum;
	variable restart_count_cum;	
	variable limit_count_cum;	
	
endstructure
