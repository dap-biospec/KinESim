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


//-----------------------------------------------
//
threadsafe function SetStatWaves(logMode, name, CWave, RxRKWave, stepStats)
	variable logMode; 
	string name;
	wave CWave;
	wave RxRKWave;
	STRUCT stepStatsT &stepStats	

	if (logMode > 1)
		variable cN = dimsize(CWave, 1)
		variable rxN = dimsize(RxRKWave, 0);
		variable RKOrder = dimsize(RxRKWave, 1);
		make /O /N=(cN, rxN, RKOrder  + 1) $name+"_RiseStat", $name+"_DropStat";
		wave stepStats.StatRiseWave = $name+"_RiseStat";
		wave stepStats.StatDropWave = $name+"_DropStat";
		make /O /N=(cN, 4) $name+"_StepStat"
		wave stepStats.StatStepWave = $name+"_StepStat";
	else
		killwaves /Z $name+"_RiseStat", $name+"_DropStat", $name+"_StepStat"
		wave stepStats.StatRiseWave = NULL;
		wave stepStats.StatDropWave = NULL;
		wave stepStats.StatStepWave = NULL;
	endif 
	
end 


//-----------------------------------------------
//
threadsafe function SetLogWave(logwave, logMode, logNameS, cN)
	wave logWave;
	variable logMode; 
	string logNameS;
	variable cN;

	if (!waveexists(LogWave))
		return 0;
	endif
	
	variable logCols = 0
	switch (logMode)
		case 3: 
			logCols += DbgM * cN;
		case 2: 
			logCols += DbgExt;
		case 1: 
			logCols += DbgBase;
		case 0: 
	endswitch;
	if (logCols)
		redimension /N=(DbgLen, logCols) LogWave
		LogWave = 0;
print "\nSetLogWave dims: ", DbgLen, ":", logCols, " for mode ",logMode, " and wave  ", GetWavesDataFolder(logWave,2)
		return logMode;
	else
		redimension /N=(0) LogWave
		return 0;
	endif
end 


//---------------------------------------------------------------------------------------
// Debugging log
//---------------------------------------------------------------------------------------
//
//
threadsafe  function reportDbgCommon(dbg, StepsCount, curr_t, curr_i, SimStep, stepStats, TWave) 
	wave dbg;
	variable StepsCount, curr_t, curr_i, SimStep;
	STRUCT stepStatsT &stepStats;
	wave TWave;
	
	if (StepsCount >= DbgLen)
		return 1;
	endif
	
	switch (stepStats.doLog) 
		case 3:
			variable i;
			for (i=0; i<dimsize(TWave, 1); i+=1)	
				variable dbgOffs = DbgBase + DbgExt+i*DbgM;
				dbg[StepsCount][dbgOffs+0, dbgOffs+2] = TWave[23 + q - (dbgOffs+0)][i]; 
				dbg[StepsCount][dbgOffs+3] = NaN
				dbg[StepsCount][dbgOffs+4, dbgOffs+7] = TWave[1 + q - (dbgOffs+4)][i]; 
				dbg[StepsCount][dbgOffs+8, dbgOffs+11] = TWave[7 + q - (dbgOffs+8)][i]; 
				dbg[StepsCount][dbgOffs+12, dbgOffs+15] = TWave[11+q - (dbgOffs+12)][i]; 
				dbg[StepsCount][dbgOffs+15, (DbgBase + DbgExt+(i+1)*DbgM -1)] = NaN; 
			endfor
			
		case 2:
			dbg[StepsCount][7] = stepStats.lim_code_outer; 
			dbg[StepsCount][8] = stepStats.lim_rel_outer;
			dbg[StepsCount][9] = stepStats.lim_code_inner0; 
			dbg[StepsCount][10] = stepStats.lim_rel_inner0;
			dbg[StepsCount][11] = stepStats.lim_code_inner1; 
			dbg[StepsCount][12] = stepStats.lim_rel_inner1;
			dbg[StepsCount][13] = stepStats.lim_code_inner2; 
			dbg[StepsCount][15] = stepStats.lim_rel_inner2;
			dbg[StepsCount][15] = stepStats.lim_code_inner3; 
			dbg[StepsCount][16] = stepStats.lim_rel_inner3;
		case 1:
			dbg[StepsCount][0] = curr_t;
			dbg[StepsCount][1] =curr_i; 
			dbg[StepsCount][2] = stepStats.final_step_t; 
			dbg[StepsCount][3] = stepStats.init_step_t; 
			dbg[StepsCount][4] = stepStats.restart_count;
			dbg[StepsCount][5] = stepStats.steps_count; 
			dbg[StepsCount][6] = stepStats.rates_count; 
		case 0:
	endswitch
end


//----------------------------------------------------------
// 
threadsafe function SimStats2Wave(stats, OWave, idx)
	STRUCT simStatsT &stats;
	wave OWave;
	variable idx

	OWave[idx][0] = stats.startTime;
	OWave[idx][1] = stats.stopTime;
	OWave[idx][2] = stats.runTime;
	OWave[idx][3] = stats.points;
	OWave[idx][4] = stats.steps;
	OWave[idx][5] = stats.points; // all complete here.... stats.compeltePoints;
//	OWave[idx][6] = ??
	OWave[idx][7] = stats.flags;
	OWave[idx][8] = stats.error;
	OWave[idx][9] = 1; // sim complete
	OWave[idx][10] = stats.holds_count_cum; 
	OWave[idx][11] = stats.restart_count_cum;	
	OWave[idx][12] = stats.limit_count_cum;	
	
end

 

//-----------------------------------------------
//
function SetLogWaveS(simData, RxRKWave, stepStats)
	STRUCT simDataT &simData;
	wave RxRKWave;
	STRUCT KES#stepStatsT &stepStats	

	// wave simData.StatWave	= 
	KES#SetStatWaves(simData.logMode, simData.name, SimData.CWave, RxRKWave, stepStats);
	
	wave simData.LogWave	= KES#MakeLogWave(simData.logMode, simData.name, dimsize(SimData.CWave, 1));
	if (waveexists(simData.LogWave))
		return simData.logMode;
	else
		return 0;
	endif;
end 
	
	

//========================================================================
//
// optional debugging log - enable in code as needed

function dbg_up(RK4TmpW, RKWave) 
	wave RK4TmpW, RKWave;
	variable RKStep
	
	RK4TmpW[][0,4] = RKWave[p][q][0][0]; // conc
	RK4TmpW[][5] = NaN;
	RK4TmpW[][6,9] = RKWave[p][q-6][0][1]; // rates
	RK4TmpW[][10] = RKWave[p][4][0][0]; // dC RK7
	RK4TmpW[][11] = RKWave[p][4][0][1]; // dC Euler
	if (DoDbgUpdate)
		DoUpdate ////W=$"tmp_RK4Wnd";
	endif
end



//-----------------------------------------------
//
threadsafe function /WAVE MakeLogWave(logMode, logNameS, cN)
	variable logMode; 
	string logNameS;
	variable cN;

	
	variable logCols = 0
	switch (logMode)
		case 3: 
			logCols += DbgM * cN;
		case 2: 
			logCols += DbgExt;
		case 1: 
			logCols += DbgBase;
		case 0: 
	endswitch;
	if (logCols)
		make /O /N=(DbgLen, logCols) $logNameS +"_log"
		wave logWave = $logNameS +"_log";
		logWave = 0;
print "\nMakeLogWave dims: ", DbgLen, ":", logCols, " for mode ",logMode, " and wave  ", GetWavesDataFolder(logWave,2)
		return logWave;
	else
		return $"";
	endif
end 


