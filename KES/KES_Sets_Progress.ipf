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


//-----------------------------------------------
//
function defaultSetPrg(thePrg, len, wName) //hosted
	STRUCT KES#SetProgDataT &thePrg;
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


//-----------------------------------------------
//
function defaultKiloPrg(thePrg, hosted, len, wName)
	STRUCT KES#KiloProgDataT &thePrg;
	variable hosted;
	variable len;
	string wName; // only if not hosted!

	thePrg.set_sets = len;
	thePrg.set_curr_set_out = 0;
	thePrg.set_last_update = -1;
	thePrg.hosted = hosted ? 1: 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.set.wName = wName;
		else
			thePrg.set.wName = "myKiloProgress";
		endif			
	endif
end

//-----------------------------------------------
//
function defaultMegaPrg(thePrg, hosted, len, wName)
	STRUCT KES#MegaProgDataT &thePrg;
	variable hosted;
	variable len;
	string wName; // only if not hosted!

	thePrg.kilo_sets = len;
	thePrg.kilo_curr_set_out = 0;
	thePrg.kilo_last_update = -1;
	thePrg.hosted = hosted ? 1: 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.kilo.set.wName = wName;
		else
			thePrg.kilo.set.wName = "myKiloProgress";
		endif			
	endif
end


//------------------------------------------------------------------------------------
//
//
function KiloProgressSetup(prg)
	STRUCT KES#KiloProgDataT &prg;

	ValDisplay kiloSetDone, win=$prg.set.wName, pos={20+prg.x,5+prg.y}, size={200,14},title="   kilo set", limits={0,prg.set_sets,0},barmisc={0,40},mode= 3
	ValDisplay kiloSetDone, win=$prg.set.wName,  value= _NUM:prg.set_curr_set_out;
	
	SetVariable kiloETA, win=$prg.set.wName,  value= _STR:"-pending 1st set-",noedit= 1, pos={230+prg.x, 4+prg.y},size={175,16},title="ETA",frame=0
	
	prg.set.x = prg.x+0;
	prg.set.y = prg.y+18;
	
end 


//-----------------------------------------------
//

function KiloProgressStart(prg) 
	STRUCT KES#KiloProgDataT &prg;
	
	prg.set_last_update  = -1;
	prg.set_start_time = DateTime;
	prg.set_stop_time = -1;

	if (prg.hosted) // name is set, use as sub-pane;
		return KiloProgressSetup(prg);
	endif 		
	if (strlen(prg.set.wName) == 0)
		prg.set.wName = "myKiloProgress";
	endif
	prg.x = 0;
	prg.y=0;
	NewPanel/FLT /N=$prg.set.wName /W=(285,111,739,200) as "Simulating a Kilo..."
	KiloProgressSetup(prg);
	DoUpdate/W=$prg.set.wName/E=1 // mark this as our progress window
	SetWindow $prg.set.wName, hook(spinner)=MySetHook
End

//-----------------------------------------------
//

function doKiloProgressUpdate(prg) 
	STRUCT KES#KiloProgDataT &prg;

	if (prg.set_curr_set_out > 0 )
		variable now = DateTime;
		variable elapsed_time = (now - prg.set_start_time);

		variable newTime =((prg.set_sets - prg.set_curr_set_out) / prg.set_curr_set_out)*elapsed_time;
		string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
		SetVariable kiloETA  value=_STR:ETAStr, win=$prg.set.wName
	else
		// not known...
	endif;
	
	ValDisplay kiloSetDone, win=$prg.set.wName, value= _NUM:prg.set_curr_set_out

	return KES#doSetProgressUpdate(prg.set) 
end



//-----------------------------------------------
//

Function KiloProgressStop(prg)
	STRUCT KES#KiloProgDataT &prg;
	
	prg.set_stop_time = DateTime;
	KES#SetProgressStop(prg.set);
	if (!prg.hosted)
		KiloProgressCleanup(prg);
	endif;	
End

//-----------------------------------------------
//

Function KiloProgressCleanup(prg)
	STRUCT KES#KiloProgDataT &prg;

	KES#SetProgressCleanup(prg.set);
End



//------------------------------------------------------------------------------------
//

function MegaProgressSetup(prg)
	STRUCT KES#MegaProgDataT &prg;
	
	ValDisplay megaSetDone, win=$prg.kilo.set.wName, pos={20,5},size={200,14},title="mega set", limits={0,prg.kilo_sets,0},barmisc={0,40},mode= 3
	ValDisplay megaSetDone, win=$prg.kilo.set.wName,  value= _NUM:0
	SetVariable megaETA, win=$prg.kilo.set.wName, pos={230,4},size={175,16},title="ETA",frame=0, value= _STR:"-pending 1st kilo-",noedit= 1

	prg.kilo.x = prg.x+0;
	prg.kilo.y = prg.y+18;
end 

//-----------------------------------------------
//
function MegaProgressStart(prg) 
	STRUCT KES#MegaProgDataT &prg;

	prg.kilo_last_update  = -1;
	prg.kilo_start_time = DateTime;
	prg.kilo_stop_time = -1;

	if (prg.hosted) // name is set, use as sub-pane;
		return MegaProgressSetup(prg);
	endif
	if (strlen(prg.kilo.set.wName) == 0)
		prg.kilo.set.wName = "myMegaProgress";
	endif
	prg.x = 0;
	prg.y=0;
	NewPanel/FLT /N=$prg.kilo.set.wName /W=(285,111,739,220) as "Simulating a Mega..."
	MegaProgressSetup(prg);
	DoUpdate/W=$prg.kilo.set.wName/E=1 // mark this as our progress window
	SetWindow $prg.kilo.set.wName, hook(spinner)=MySetHook
End


//-----------------------------------------------
//

function doMegaProgressUpdate(prg) 
	STRUCT KES#MegaProgDataT &prg;

	if (prg.kilo_curr_set_out > 0 )
		variable now = DateTime;
		variable elapsed_time = (now - prg.kilo_start_time);

		variable newTime =((prg.kilo_sets - prg.kilo_curr_set_out) / prg.kilo_curr_set_out)*elapsed_time;
		string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
		SetVariable megaETA  value=_STR:ETAStr, win=$prg.kilo.set.wName
	else
		// not known...
	endif;
	
	ValDisplay megaSetDone, win=$prg.kilo.set.wName, value= _NUM:prg.kilo_curr_set_out

	return doKiloProgressUpdate(prg.kilo) 
end

//-----------------------------------------------
//

Function MegaProgressStop(prg)
	STRUCT KES#MegaProgDataT &prg;
	
	prg.kilo_stop_time = DateTime;
	KiloProgressStop(prg.kilo);
	if (!prg.hosted)
		MegaProgressCleanup(prg);
	endif;	
End

//-----------------------------------------------
//
//
Function MegaProgressCleanup(prg)
	STRUCT KES#MegaProgDataT &prg;
	KiloProgressCleanup(prg.kilo);
End


