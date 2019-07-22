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


//----------------------------------------------------------
//      Progress tracking
//----------------------------------------------------------
//

//-----------------------------------------------
//

structure SetProgDataT
	string wName;
	variable x, y;
	variable  set_start_time;
	variable  set_stop_time;
	variable  set_sims;
	variable  set_points;
	variable  set_curr_sim_in, set_curr_sim_out;
	variable  set_curr_i, set_curr_s;
	variable  set_curr_lim, set_curr_hold, set_curr_restart;
	variable  set_last_update
	variable thGroupID;
	variable hosted;
	variable aborted;
endstructure;

//-----------------------------------------------
//

structure KiloProgDataT
	STRUCT SetProgDataT set;
	variable x, y;
	variable  set_sets;
	variable  set_curr_set_out;
	variable 	set_last_update;
	variable 	set_start_time
	variable  set_stop_time
	variable hosted;
endstructure;

//-----------------------------------------------
//

structure MegaProgDataT
	STRUCT KiloProgDataT kilo;
	variable x, y;
	variable  kilo_sets;
	variable  kilo_curr_set_out;
	variable 	kilo_last_update;
	variable 	kilo_start_time
	variable  kilo_stop_time
	variable hosted;
endstructure;

//-----------------------------------------------
//



threadsafe function reportProgress(curr_i, curr_t, StepsCount, stepStats, reset)
	variable curr_i, curr_t, StepsCount, reset
	STRUCT stepStatsT &stepStats;

	variable /G sim_curr_i = curr_i;
	variable /G sim_curr_t = curr_t;
	variable /G sim_curr_step = StepsCount;
	variable /G sim_i_step = (reset)? 0: sim_i_step+1
	if (reset)
		sim_i_step = 0;
	else
		sim_i_step += 1;
	endif 
		sim_curr_i = curr_i;
		sim_curr_t = curr_t;
		sim_curr_step = StepsCount;

end




//-----------------------------------------------
//

function SetProgressStart(prg) // iSetSims, iPoints, iCurrI, iCurrStep, [winPropRef])
	STRUCT SetProgDataT &prg;
	
	prg.set_last_update  = -1;
	prg.set_start_time = DateTime;
	prg.set_stop_time = -1;
	if (prg.hosted) // name is set, use as sub-pane;
		return SetProgressSetup(prg);
	endif 
	
	if (strlen(prg.wName) == 0)
		prg.wName = "mySetProgress";
	endif
	prg.x = 0;
	prg.y=0;

	NewPanel/FLT /N=$prg.wName /W=(285,111,739,185) as "Simulating a set..."
	SetProgressSetup(prg);
	DoUpdate/W=mySetProgress/E=1 // /SPIN=60 // mark this as our progress window
	SetWindow mySetProgress,hook(spinner)=MySetHook
	variable /G kill_sim = -1;
End


//-----------------------------------------------
//

function SetProgressSetup(prg)
	STRUCT SetProgDataT &prg;
	
	ValDisplay inSimDisp, win=$prg.wName, title="started", pos={18+prg.x,4+prg.y},size={190,14}, limits={0,prg.set_sims,0}, barmisc={0,40}, mode=3 
	ValDisplay inSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_in

	ValDisplay outSimDisp, win=$prg.wName, title="finished", pos={210+prg.x,4+prg.y},size={190,14}, limits={0,prg.set_sims,0}, barmisc={0,40}, mode=3 
	ValDisplay outSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_out

	ValDisplay stepDisp, win=$prg.wName,  title="point", pos={25+prg.x,23+prg.y},size={377,14}, bodyWidth=350, limits={0,(prg.set_points < 0? 0 : prg.set_points),0}, barmisc={0,50}, mode=3 
	ValDisplay stepDisp, win=$prg.wName, value= _NUM:prg.set_curr_i
	
	SetVariable EstDisp win=$prg.wName, title="Est", value=_STR:"-?-", noedit=1, pos={10+prg.x,40+prg.y},fixedSize=1,size={200,16},frame=0
	SetVariable ETADisp win=$prg.wName, title="ETA", value=_STR:"-?-", noedit=1, pos={210+prg.x,40+prg.y},fixedSize=1,size={150,16},frame=0

	Button bStop,pos={350+prg.x,45+prg.y},size={50,20},title="Abort", proc=simStopThreadsProc
	SetActiveSubwindow _endfloat_
end 

//-----------------------------------------------
//
Function MySetHook(s)
	STRUCT WMWinHookStruct &s
	if( s.eventCode == 23 )
		variable /G set_curr_i;
		variable /G set_last_update;	
		variable /G set_points;
		if (set_points < 0)
			set_points *= -1;
			ValDisplay stepDisp limits={0,set_points,0}, win=$s.winName 
		endif 
		if (set_curr_i != set_last_update)
			variable /G set_curr_sim_in;
			variable /G set_curr_sim_out;

			variable /G set_curr_i
			variable /G set_start;
			variable now = DateTime;
		
			set_last_update = set_curr_i;

		endif	
		DoUpdate/W=$s.winName
		if( V_Flag == 2 ) // we only have one button and that means abort
			Button bStop,title="wait...", win=$(s.winName), disable=2
			NVAR kill_sim 
			kill_sim = 1;
			print "Killed #1"
			return 1
		endif
		
	endif
	return 0
end


//-----------------------------------------------
//

function doSetProgressUpdate(prg) 
	STRUCT SetProgDataT &prg;

	variable now = DateTime;
	variable elapsed_time = (now - prg.set_start_time);

	variable newTime =((prg.set_points - prg.set_curr_i) / prg.set_curr_i)*elapsed_time;
	variable estTime = (prg.set_points / prg.set_curr_i)*elapsed_time;
	variable relHold = prg.set_curr_hold / prg.set_curr_s;
	variable relRestart = prg.set_curr_restart / prg.set_curr_s;
	variable relLim = prg.set_curr_lim / prg.set_curr_s;
	
	string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
	string EstStr
	sprintf EstStr "%s, H%.3f R%.3f L%.3f", Secs2Time(estTime,5), relHold, relRestart, relLim ;
	
	ValDisplay inSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_in
 
	ValDisplay outSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_out

	ValDisplay stepDisp, win=$prg.wName, value= _NUM:prg.set_curr_i

	SetVariable ETADisp  value=_STR:ETAStr, win=$prg.wName
	SetVariable EstDisp  value=_STR:EstStr, win=$prg.wName
	NVAR kill_sim
	prg.aborted = kill_sim;
	
	if( kill_sim > 0) // we only have one button and that means abort
			Button bStop,title="wait...", win=$(prg.wName), disable=2
		endif
	DoUpdate/W=$prg.wName

	
	return (kill_sim > 0); 
end

//-----------------------------------------------
//

function doSetProgressSteps(prg) 
	STRUCT SetProgDataT &prg;

	ValDisplay stepDisp, win=$prg.wName, limits= {0,(prg.set_points < 0? 0 : prg.set_points),0}, value= _NUM:prg.set_curr_i
end



//-----------------------------------------------
//

Function SetProgressStop(prg)
	STRUCT SetProgDataT &prg;

	prg.set_stop_time = DateTime;
	
	if (prg.thGroupId < 0)
		variable 	dummy= ThreadGroupRelease(prg.thGroupId)
		prg.thGroupId = -1;
	endif

	if (!prg.hosted)
		SetProgressCleanup(prg)
	endif;

End


//-----------------------------------------------
//

Function SetProgressCleanup(prg)
	STRUCT SetProgDataT &prg;

	KillWindow $prg.wName;
	
	variable /G set_points
	variable /G set_curr_i
	variable /G set_curr_t
	variable /G set_curr_lim
	variable /G set_curr_hold
	variable /G set_curr_restart
	variable /G set_i_step
	variable /G set_last_update
	variable /G set_start
	killvariables /Z set_points, set_curr_i, set_curr_t, set_curr_lim, set_curr_hold, set_curr_restart, set_curr_step,  set_i_step, set_last_update, set_start, kill_sim 
End
 
//-----------------------------------------------
//
function defaultSetPrg(thePrg, len, wName) //hosted
	STRUCT SetProgDataT &thePrg;
	variable len;
	string wName; // only if not hosted!
//	variable hosted;

	thePrg.set_sims = len;
	thePrg.set_points = 0;
	thePrg.set_curr_sim_in = 0;
	thePrg.set_curr_sim_out = 0;
	thePrg.set_curr_i = 0;
	thePrg.set_curr_s = 0;
	thePrg.set_curr_lim = 0;
	thePrg.set_curr_hold = 0;
	thePrg.set_curr_restart = 0;
	thePrg.thGroupId = -1;
	thePrg.set_last_update = -1;
	// thePrg.hosted = hosted ? 1: 0; must be pre-set
	thePrg.aborted = 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.wName = wName;
		else
			thePrg.wName = "mySetProgress";
		endif			
	endif
end


