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

#pragma IndependentModule=KES
strconstant cKESCoreVer = "1.7.0a"

#pragma version = 20190711
#include ":KES_Core_Struct", version >= 20190711
#include ":KES_Core_Aliases", version >= 20190711
#include ":KES_Core_Log", version >= 20190711
#include ":KES_Core_Progress", version >= 20190711
#include ":KES_Core_Flow", version >= 20190711
#include ":KES_Core_Integrator", version >= 20190711

threadsafe function /S getCoreVer()
	return cKESCoreVer
end

//----------------------------------------------------------
// thread safe verison with I/O
// called by simSet_FullSimPrlPrg
//
threadsafe function Sim_Core_Seq(SWave, CWave, PWave, ERxnsW, GRxnsW, RxnsTmp, OWave, idx, LogWave, logMode )  
	wave SWave, CWave, PWave;
	wave /WAVE GRxnsW, ERxnsW;
	wave RxnsTmp;
	wave OWave
	variable idx 
	wave LogWave
	variable logMode; 

	string commName = nameofwave(SWave);
	
	OWave[idx][9] = 0 // sim started
		
	variable i, cN = dimsize(CWave, 1); // number of mediators in the wave

	// generic setup method first...
	STRUCT simTmpDataT tmpData;
	string result = prepSimTmp(commName, cN, tmpData) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -101;
	endif
	
	// now call model-specific setup function from template
	SimRateSetup(SWave, CWave, ERxnsW, GRxnsW, PWave, tmpData.TWave) 

 	result = prepSimRxns(commName, cN, tmpData,  GRxnsW, ERxnsW,CWave, PWave) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -102;
	endif	

	result = prepSimAliases(commName, cN, tmpData, CWave, logMode >= 0 ) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -103;
	endif	
	
	STRUCT stepStatsT stepStats;
	STRUCT simPointStats PntStats;
	
	SetStatWaves(logMode, commName, CWave, tmpData.RKSolW, stepStats);
	stepStats.DoLog = SetLogWave(LogWave, logMode, commName, cN); 
	if (waveexists(LogWave))
		print "Sim_Core_Seq logMode=", logMode, " passed LogWave is ", GetWavesDataFolder(LogWave, 2)	, " ";
	endif
	// ~~~~~~~~~~~~~~~ simulation prep  ~~~~~~~~~~~~~~~ 
	variable NPnts =DimSize(SWave,0);
	variable curr_i = 1; // reference to this or latest output data index
	variable curr_t = SWave[0][0];
	variable curr_E = SWave[0][1]; // this value should be calculated from this and next discrete potential considering progress of simulation time
	variable curr_s = 0;
	

	// group prep must be done before sim is advanced!
	InitAliasGroup(tmpData.AliasW, tmpData.TWave) 
	
	advanceSim(0, stepStats, SWave, tmpData.TWave, PntStats) // set initial entry 

	STRUCT simStatsT stats;
	stats.startTime = DateTime;
	stats.points = NPNts;

	variable lastDesiredStep = SWave[1][0]; // attempt to sim to the next step	
	variable SimStep = lastDesiredStep; 
	variable stepHold = 0;

	do
		// interpolate current potential
		variable next_S_t = SWave[curr_i][0];
		variable prev_S_t = SWave[curr_i-1][0];

		curr_E = SWave[curr_i-1][1] + (SWave[curr_i][1] - SWave[curr_i-1][1]) * ((curr_t - prev_S_t) / (next_S_t - prev_S_t))

		// do the sim...
		RK4RatesSeq(PWave, CWave, tmpData.RSolW, tmpData.RKSolW, tmpData.TWave, tmpData.RKWave, curr_E, simStep, next_S_t - curr_t, lastDesiredStep, stepHold, curr_s, stepStats) ;

		// check for aliases here; Concentration of all aliases should be the same, rates should be the same
		tmpData.RKWave[][3][][0] = 0; // flag
		
		// integrate group data here
		CombAliasGroup(tmpData.AliasW, tmpData.RKWave) 

		SimCompleteStep(stepStats, PntStats, stats, tmpData)

		if  (curr_s < DbgLen)	
			reportDbgCommon(LogWave, curr_s, curr_t, curr_i, SimStep, stepStats,  tmpData.TWave); 
		endif
		
		curr_t += SimStep; 
		if (curr_t >= next_S_t) // time to save data
			advanceSim(curr_i, stepStats, SWave, tmpData.TWave, PntStats);
			curr_i +=1;
		endif 

		
		reportProgress(curr_i, curr_t, curr_s, stepStats, curr_t >= next_S_t ? 1 : 0)
		
		curr_s +=1;
  		
		OWave[idx][4] = curr_s; 
		OWave[idx][5] = curr_i; 
		OWave[idx][10] = stats.holds_count_cum; 
		OWave[idx][11] = stats.restart_count_cum;	
		OWave[idx][12] = stats.limit_count_cum;	
		
	while (curr_i< NPnts)
	
	// clean up and report
	string flags = "";
	if (strlen(flags)) 
		flags = "Flags: "+flags;
	endif
	wave TWave = tmpData.TWave
	killWaves /Z TWave

	stats.stopTime = DateTime;
	stats.runTime = stats.stopTime - stats.startTime;
	stats.steps = curr_s;

	SimStats2Wave(stats, OWave, idx)

	if (waveexists(RxnsTmp))
		RxnsTmp=NaN;
		RxnsTmp[, dimsize(tmpData.RSolW,0)-1][, dimsize(tmpData.RSolW,1)-1][] = tmpData.RSolW[p][q][r]
	endif
end


//-----------------------------------------------
// worker function using structure for results reporting
//
 function Sim_Core_Prl(simData, OWave, idx, nMT, hostPrg)
	STRUCT simDataT &simData;
	variable idx;
	variable nMT;
	wave OWave;
	STRUCT SetProgDataT &hostPrg;
 
 	STRUCT simStatsT stats;
	
	variable i, cN = dimsize(simData.CWave, 1); // number of mediators in the wave

	// generic setup method first...
	STRUCT simTmpDataT tmpData;
	string result = prepSimTmp(simData.name, cN, tmpData) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -101;
	endif

	// now call model-specific setup function from template
	SimRateSetup(simData.SWave, simData.CWave, simData.ERxnsW, simData.GRxnsW, simData.PWave, tmpData.TWave) 

	result = prepSimRxns(simData.name, cN, tmpData,  simData.GRxnsW, simData.ERxnsW, simData.CWave, simData.PWave) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -102;
	endif	
	
	// this is currently not enabled,see MT version
	result = prepSimAliases(simData.name, cN, tmpData, simData.CWave, simData.stealth) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -103;
	endif	

	STRUCT stepStatsT stepStats;
	STRUCT simPointStats PntStats;

	stepStats.DoLog = setLogWaveS(SimData, tmpData.RKSolW, stepStats);
	
	if (stepStats.doLog)
		print "Sim_Core_Prl logMode=", SimData.logMode	
	endif
	
	
	// ~~~~~~~~~~~~~~~ simulation prep  ~~~~~~~~~~~~~~~ 
	variable NPnts =DimSize(simData.SWave,0);
	variable curr_i = 1; // reference to this or latest output data index
	variable curr_t = simData.SWave[0][0];
	variable curr_E = simData.SWave[0][1]; // this value should be calculated from this and next discrete potential considering progress of simulation time
	variable curr_s = 0;

	// MT version does group concentrations combine here...
	// group prep must be done before sim is advanced!
	
	InitAliasGroup(tmpData.AliasW, tmpData.TWave) 
	
	
	advanceSim(0, stepStats, simData.SWave, tmpData.TWave, PntStats) // set initial entry 
	// STRUCT simStatsT stats is supplied
	
	stats.startTime = DateTime;
	stats.points = NPNts;

	stats.holds_count_cum = 0;
	stats.restart_count_cum = 0;
	stats.limit_count_cum = 0;	 




	// set up multithreading 
	Variable threadGroupID = (nMT > 1) ? ThreadGroupCreate(nMT) : -1
	


	variable reportPool = 0;
	variable lastDesiredStep = simData.SWave[1][0]; // attempt to sim to the next step	
	variable SimStep = lastDesiredStep; 

	variable stepHold = 0;

	do
		// interpolate current potential
		variable next_S_t = simData.SWave[curr_i][0];
		variable prev_S_t = simData.SWave[curr_i-1][0];
		
		curr_E = simData.SWave[curr_i-1][1] + (simData.SWave[curr_i][1] - simData.SWave[curr_i-1][1]) * ((curr_t - prev_S_t) / (next_S_t - prev_S_t))

		// do the sim...
		RK4RatesPrl(simData.PWave, simData.CWave, tmpData.RSolW, tmpData.RKSolW, tmpData.TWave, tmpData.RKWave, curr_E, simStep, next_S_t - curr_t, lastDesiredStep, stepHold, curr_s, stepStats, threadGroupID) ;

		// sequential method processes group data here
		CombAliasGroup(tmpData.AliasW, tmpData.RKWave)
		
		SimCompleteStep(stepStats, PntStats, stats, tmpData)

		reportDbgCommon(SimData.LogWave, curr_s, curr_t, curr_i, SimStep, stepStats, tmpData.TWave); 
		
		curr_t += SimStep; 
		if (curr_t >= next_S_t) // time to save data
			advanceSim(curr_i, stepStats, simData.SWave, tmpData.TWave, PntStats);
			curr_i +=1;
		endif 

		reportProgress(curr_i, curr_t, curr_s, stepStats, curr_t >= next_S_t ? 1 : 0)

		curr_s +=1;
		reportPool +=1;
		if (reportPool >=1000)
			hostPrg.set_curr_s += reportPool;
			hostPrg.set_curr_i =curr_i; 
//			OWave[s][10] = stats.holds_count_cum;
//			OWave[s][11] = stats.restart_count_cum;
//			OWave[s][12] = stats.limit_count_cum;
			
			hostPrg.set_curr_hold = stats.holds_count_cum;
			hostPrg.set_curr_restart = stats.restart_count_cum;
			hostPrg.set_curr_lim = stats.limit_count_cum;
			doSetProgressUpdate(hostPrg);
			reportPool = 0;
		endif
	while (curr_i< NPnts)
	
	Variable dummyThread= ( threadGroupID >= 0 ) ? ThreadGroupRelease(threadGroupID) : 0;
	
	// clean up and report
	string flags = "";
	if (strlen(flags)) 
		flags = "Flags: "+flags;
	endif
	wave TWave = tmpData.TWave
	killWaves /Z TWave

	stats.stopTime = DateTime
	stats.runTime = stats.stopTime - stats.startTime;
	stats.steps = curr_s;
	
	SimStats2Wave(stats, OWave, idx);

end
