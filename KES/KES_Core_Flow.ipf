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
//
threadsafe function /S checkSimInput(SWave, CWave, ERxnsW, GRxnsW) 
	wave SWave, CWave
	wave /WAVE ERxnsW, GRxnsW

	if (!WaveExists(CWave))
		return "Components wave does not exist. Exiting..." 
	endif 

	variable cN = dimSize(CWave, 1);
	
	if (!WaveExists(SWave))
		return "Simulation wave does not exist. Exiting..." 
	endif 

	redimension /N=(-1, S_C_Offs + cN * S_C_Num ) SWave //get_S_C_Offet
	SWave[][2,] = NaN;
	
	SetDimLabel 1, 0, 'time', SWave
	SetDimLabel 1, 1, 'E', SWave 
	SetDimLabel 1, 2, 'sub-steps', SWave
	SetDimLabel 1, 3, 'n rates', SWave
	SetDimLabel 1, 4, 'RK steps', SWave
	SetDimLabel 1, 5, 'RK overhead', SWave
	SetDimLabel 1, 6, 'n holds', SWave
	SetDimLabel 1, 7, 'n restarts', SWave
	SetDimLabel 1, 8, 'n limits', SWave
	SetDimLabel 1, 9, 'lim Cmp', SWave
	SetDimLabel 1, 10, 'lim Rxn', SWave
	SetDimLabel 1, 11, 'lim RKStep', SWave
	SetDimLabel 1, 12, 'lim inst', SWave
	SetDimLabel 1, 13, 'total Q', SWave
	
	variable i;
	for (i=0; i< cN; i++)
		string CmpName;
		sprintf CmpName, "Cmp%01u", i
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  0, $CmpName+"[Ox Sol]", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  1, $CmpName+"[Rd Sol]", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  2, $CmpName+"[Ox Elc]", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  3, $CmpName+"[Rd Elc]", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  4, $CmpName+" dC Ox Sol", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  5, $CmpName+" dC Rd Sol", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  6, $CmpName+" dC Ox Ele", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  7, $CmpName+" dC Rd Ele", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  8, $CmpName+" lim Rxn", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num +  9, $CmpName+" lim RKStep", SWave
		SetDimLabel 1, S_C_Offs+i*S_C_Num + 10, $CmpName+" lim number", SWave
		
	endfor
	

	if (!WaveExists(ERxnsW))
		// return "Rates wave does not exist. Exiting..." 
	endif 

	if (!WaveExists(GRxnsW))
		// return "Rates wave does not exist. Exiting..." 
	endif 

	return "";
end




//----------------------------------------------------------
//
threadsafe  function /S prepSimTmp(commName, cN,  simTmpData) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	
	string tempWN = commName +"_tmp" //nameofwave(CWave)
	if (waveexists($tempWN))	
		redimension /D /N=(TWaveLen, cN) $tempWN
	else 
		make /D /N=(TWaveLen, cN) $tempWN
	endif
	wave simTmpData.TWave = $tempWN


	string RK4WN = commName+"_RK4" //nameofwave(CWave)
	if (waveexists($RK4WN))	
		redimension /D /N=(4, 6, cN, 2) $RK4WN
	else 
		make /D /N=(4, 6, cN, 2) $RK4WN
	endif
	wave simTmpData.RKWave = $RK4WN

	string RK4TmpWN = "tmp_RK4"
	if (waveexists($RK4TmpWN))	
		redimension /D /N=(4, 12) $RK4TmpWN
	else 
		make /D /N=(4, 12) $RK4TmpWN
	endif
	wave simTmpData.RKTmpWave = $RK4TmpWN
	simTmpData.RKTmpWave = 0;	
			
	variable nRxns = 0;
	variable RKOrder = 4;

	string RKSolWN = commName+"_RKs" 
	if (waveexists($RKSolWN))	
		redimension /D /N=(nRxns, RKOrder) $RKSolWN
	else 
		make /D /N=(nRxns, RKOrder) $RKSolWN
	endif
	wave simTmpData.RKSolW = $RKSolWN


	string RxnsWN = commName+"_Rxn" 
	if (waveexists($RxnsWN))	
		redimension /D /N=(nRxns, cN+1, 2) $RxnsWN
	else 
		make /D /N=(nRxns, , cN+1, 2) $RxnsWN
	endif
	wave simTmpData.RKSolW = $RxnsWN


	string AliasWN = commName+"_Al" 
	if (waveexists($AliasWN))	
		redimension /D /N=(cN, 1, 2) $AliasWN
	else 
		make /D /N=(cN, 1, 2) $AliasWN
	endif
	wave simTmpData.AliasW = $AliasWN
	
	return ""
end


//---------------------------------------------------------------------------------
//  The follwing function is an example of implementing kinetic model;
//	 Another model may provide different versions

//---------------------------------------------- 
//  proto: SimSetupProto
//
threadsafe  function SimRateSetup(SWave, CWave, ERxnsW, GRxnsW, PWave,  TWave)  
	wave SWave, CWave, PWave
	wave /WAVE ERxnsW, GRxnsW
	wave TWave;
	
	variable curr_E;
	variable mN = dimsize(CWave, 1);
	
	variable i, j;	
	variable F_RT = 38.94;
	
	for (i=0; i<mN ; i+=1)		
		variable total_C_i = CWave[0][i] + CWave[1][i];
		if (total_C_i <= 0)
			TWave[1,4][i]  = NaN; 
			TWave[11, 14][i]  = NaN; 
			TWave[26, 30][i] = NaN; 
			continue;
		endif 
		TWave[0][i] = total_C_i; 
		TWave[1][i]  = CWave[0][i]; 
		TWave[2,3][i] = 0; // surface concentration of oxidized component
		TWave[4][i]  = total_C_i - TWave[1][i]; 
		TWave[11, 14][i]  = 0; 
		
		variable do_surface; 
		if (CWave[4][i] > 0 && CWave[3][i] > 0) // there is electrchemistry
			TWave[21][i] = CWave[5][i] * CWave[3][i] * F_RT * 2; 
			if (CWave[8][i] > 0 && PWave[3] > 0) // there is a limit; any binding is ignored
				do_surface = 0;
			else // no rate limit, maybe binding
				if ((CWave[10][i] > 0) && (CWave[11][i] > 0)) // there is binding
					variable k_on = CWave[11][i]
					variable k_off = CWave[11][i] / CWave[10];
					TWave[28][i] = k_on;
					TWave[29][i] =k_off;
					TWave[27][i] =CWave[10] * PWave[10]; 
					do_surface = 1;
				else // no binding, no echem
					do_surface = 0;
				endif
				TWave[24,25][i] = 0 // no lmiting rates
			endif
		else // no echem!
			do_surface = 0;
			TWave[23, 29][i] = 0; 
		endif
		
		
		variable C_tot_adj 
		if (do_surface)
			C_tot_adj = (TWave[1][i] +TWave[2][i]+ TWave[3][i] + TWave[4][i]) / TWave[0][i];
			TWave[1,4][i] /=C_tot_adj
		else
			C_tot_adj = (TWave[1][i]+ TWave[4][i]) / TWave[0][i];
			TWave[1,4; 3][i] /=C_tot_adj
			TWave[2,3][i] = -1; // no bound fraction
			TWave[26, 30][i] = NaN; 
		endif
		
	endfor; 
end




//----------------------------------------------------------
//
threadsafe function /S prepSimRxns(commName, cN,  simTmpData, GRxnsW, ERxnsW, CWave, PWave) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	wave /WAVE GRxnsW
	wave /WAVE  ERxnsW;
	wave CWave;
	wave PWave;
	
	variable nSolRxns = 0;
	variable RKOrder = 4;
	
	variable i, j; 
	
	if (waveexists(simTmpData.RSolW))	
		simTmpData.RSolW[][][] = 0;
		redimension /D /N=(nSolRxns, cN+1, 2) simTmpData.RSolW
	else 
		string GRxnsWN = commName+"XRxn" 
		if (waveexists($GRxnsWN))	
			redimension /D /N=(nSolRxns , cN+1, 2) $GRxnsWN
		else
			make /D /N=(nSolRxns , cN+1, 2) $GRxnsWN
		endif
		wave simTmpData.RSolW = $GRxnsWN
	endif


	string  resStr = appendRxnsTable(simTmpData.RSolW, GRxnsW, CWave, PWave[2], 0);
	if (strlen(resStr) > 0)
		return resStr;
	endif
	
	resStr = appendRxnsTable(simTmpData.RSolW, ERxnsW, CWave, PWave[2], 1);
	if (strlen(resStr) > 0)
		return resStr;
	endif
	
	
	nSolRxns = dimsize(simTmpData.RSolW, 0)
	string RKSolWN = commName+"_RKs" 
	if (waveexists($RKSolWN))	
		redimension /D /N=(nSolRxns, RKOrder) $RKSolWN 
	else 
		make /D /N=(nSolRxns, RKOrder) $RKSolWN 
	endif
	wave simTmpData.RKSolW = $RKSolWN
	
	return ""
end




//----------------------------------------------------------
//
threadsafe  function /S appendRxnsTable(RxnsTblW, RxnsListW, CWave, rateMode, KMode)
	wave RxnsTblW;
	wave /WAVE RxnsListW;
	wave CWave
	variable rateMode; 
	variable KMode; // 0 - use K from wave; 1 use E, n from CWave
	
	if (!waveexists(RxnsListW))
		return "";
	endif
	
	variable nRxns = dimsize(RxnsTblW, 0);
	variable cN = dimsize(RxnsTblW, 1) -1;
	variable i, j;
	
		wave inERxnsW =RxnsListW[0];
		for (i=1; i < dimsize (RxnsListW, 0); i+=1 )
			if ((i-1) >= dimsize (inERxnsW, 0))
				break;
			endif		
			if ((inERxnsW[i-1][0] > 0 || KMode !=0) && inERxnsW[i-1][1] > 0)
				wave theRxnW = RxnsListW[i];
				if (waveexists(theRxnW))
					variable rxnRows = dimsize (theRxnW, 0);
					redimension /D /N=(nRxns+1, -1, -1) RxnsTblW
					RxnsTblW[nRxns][][] = 0;
					for (j = 0; j< rxnRows; j+=1)
						variable cReact = theRxnW[j][0] ;// reactants
						if ( cReact >= 0 &&  cReact < cN )
							variable nOxR = theRxnW[j][1] 
							if (nOxR > 0) // participating and valid
								RxnsTblW[nRxns][cReact+1][0] += nOxR;															
							endif 
							variable nRdR = theRxnW[j][2] 
							if (nRdR > 0) // participating and valid
								RxnsTblW[nRxns][cReact+1][0] -= nRdR;															
							endif 
						endif 
						
						// products
						variable cProd = theRxnW[j][3] ;
						if ( cProd >= 0 &&  cProd < cN )
							variable nOxP = theRxnW[j][4] 
							if (nOxP > 0) // participating and valid
								RxnsTblW[nRxns][cProd+1][1] += nOxP;															
							endif 
							variable nRdP = theRxnW[j][5] 
							if (nRdP > 0) // participating and valid
								RxnsTblW[nRxns][cProd+1][1] -= nRdP;															
							endif 
						endif 
												
					endfor 

					variable isValid = 0
					variable eCh_nE = 0;
					for (j=1; j<cN+1; j+=1)
						if (RxnsTblW[nRxns][j][0] != 0 || RxnsTblW[nRxns][j][1] != 0)
							if (KMode != 0)
								if (CWave[3][j-1] >0 )
									variable nCmp_i = 0.5*(RxnsTblW[nRxns][j][0]  -  RxnsTblW[nRxns][j][1])
									eCh_nE += nCmp_i * CWave[3][j-1] * CWave[2][j-1];
									isValid = 1;
								else
									string errorStr;
									sprintf errorstr, "Component  #%d is specified in e-chem but it's n<=0.", j-1	
									return errorStr
								endif
							else
								isValid = 1;
							endif
						endif 
					endfor
					
					if (isValid)
						if (KMode != 0)
							variable F_RT = 38.94;
							variable K_eChem = exp( eCh_nE* F_RT) ;
							inERxnsW[i-1][0] = K_eChem;
						endif 
						calcCorrRates(RxnsTblW, nRxns,rateMode, inERxnsW[i-1][1], inERxnsW[i-1][0])
						nRxns += 1;	
					else
						redimension /D /N=(nRxns, -1, -1) RxnsTblW // kill last row
					endif 
				endif ; 
			endif ; 
		endfor
	return ""
end



//----------------------------------------------------------
//
threadsafe function calcCorrRates(kWave, RxnRow, rateMode, kFwd, Keq)
	wave kWave
	variable RxnRow, rateMode, kFwd, Keq
	
	if (rateMode == 0)
		kWave[RxnRow][0][0] = kFwd * sqrt(Keq);  
		kWave[RxnRow][0][1] = kFwd /  sqrt(Keq); 
	elseif (rateMode > 0)
		kWave[RxnRow][0][0] = kFwd;
		kWave[RxnRow][0][1] = kFwd / Keq; 
	else 
		kWave[RxnRow][0][0] = kFwd * Keq; 
		kWave[RxnRow][0][1] = kFwd;
	endif
end


//----------------------------------------------------------
//
threadsafe function advanceSim(curr_i, stepStats, SWave, TWave, PntStats)
	variable curr_i
	STRUCT stepStatsT &stepStats;
	STRUCT simPointStats &PntStats;

	wave SWave
	wave TWave
	
	variable i, cN= DimSize(TWave, 1)
	// do stats here...
	if (stepStats.DoLog > 1) 
		variable rxN = dimsize(stepStats.statRiseWave, 1);
		variable rkN = dimsize(stepStats.statRiseWave, 2);
		variable c, r, k;
		stepStats.statStepWave = 0;
		for (c = 0; c < cN; c++)
			for (r = 0; r < rxN; r++)
				for (k = 0; k < rkN; k++)
					variable nRise = stepStats.statRiseWave[c][r][k];
					variable nDrop = stepStats.statDropWave[c][r][k];
					if (nDrop > 0 && nDrop > nRise)
						if (stepStats.statStepWave[c][2] < nDrop) // new max
							stepStats.statStepWave[c][0] = r;
							stepStats.statStepWave[c][1] = k;
							stepStats.statStepWave[c][2] = nDrop;
							stepStats.statStepWave[c][3] = -1;
						endif 
					elseif (nRise > 0)
						if (stepStats.statStepWave[c][2] < nRise) // new max
							stepStats.statStepWave[c][0] = r;
							stepStats.statStepWave[c][1] = k;
							stepStats.statStepWave[c][2] = nRise;
							stepStats.statStepWave[c][3] = 1;
						endif 
					endif
				endfor 
			endfor 
		endfor
		variable iMax = 0, dMax = 0;
		for (c = 0; c < cN; c++)
			if (stepStats.statStepWave[c][2] > dMax)
				iMax = c;
				dMax = stepStats.statStepWave[c][2];
			endif 
		endfor
		if (dMax > 0)
			stepStats.lim_Worst_Cmp = iMax;
		else
			stepStats.lim_Worst_Cmp = -1;
		endif	
	endif
	
	variable Q_cum_tot = 0;
	variable dC_cum_Ox_sol =0, dC_cum_Rd_sol =0, dC_cum_Ox_el =0, dC_cum_Rd_el =0
	for (i=0; i<cN ; i+=1)	// save current component parameters
		if (TWave[0][i] > 0)
			SWave[curr_i][S_C_Offs+i*S_C_Num+0] = TWave[1][i]; // Ox_sol
			SWave[curr_i][S_C_Offs+i*S_C_Num+1] = TWave[4][i] // Rd_sol 

			dC_cum_Ox_sol = TWave[11][i];
			SWave[curr_i][S_C_Offs+i*S_C_Num+4] = dC_cum_Ox_sol; 

			dC_cum_Rd_sol = TWave[14][i];
			SWave[curr_i][S_C_Offs+i*S_C_Num+5] = dC_cum_Rd_sol;
			
			Q_cum_tot += dC_cum_Ox_sol; 
			
			variable C_Ox_el = TWave[2][i]; // Ox_el
			if (C_Ox_el >= 0)
				SWave[curr_i][S_C_Offs+i*S_C_Num+2] = C_Ox_el
				dC_cum_Ox_el = TWave[12][i];
				SWave[curr_i][S_C_Offs+i*S_C_Num+6] = dC_cum_Ox_el; 
				Q_cum_tot += dC_cum_Ox_el;
			endif 
			
			variable C_Rd_el = TWave[3][i]; // Rd_el
			if (C_Rd_el >= 0)
				SWave[curr_i][S_C_Offs+i*S_C_Num+3] = C_Rd_el
				dC_cum_Rd_el = TWave[13][i];
				SWave[curr_i][S_C_Offs+i*S_C_Num+7] = dC_cum_Rd_el
			endif
			if ((stepStats.DoLog > 2) && (stepStats.statStepWave[i][2] > 0))
				SWave[curr_i][S_C_Offs+i*S_C_Num+8] = stepStats.statStepWave[i][0]; // Rxn
				SWave[curr_i][S_C_Offs+i*S_C_Num+9] = stepStats.statStepWave[i][1]; // RKStep
				SWave[curr_i][S_C_Offs+i*S_C_Num+10] = stepStats.statStepWave[i][2] * stepStats.statStepWave[i][3]; // number and direction
			else
				SWave[curr_i][S_C_Offs+i*S_C_Num+8, S_C_Offs+(i + 1)*S_C_Num -1] = NaN;
			endif 
			TWave[11,14][i]=0;
		else // no compound in the system
			SWave[curr_i][(S_C_Offs+i*S_C_Num+0),(S_C_Offs+(i+1)*S_C_Num -1)]=NaN;
		endif
	endfor

		
	// total charge needs to be divided by the step length
	SWave[curr_i][2] = stepStats.counter; 
	SWave[curr_i][3] = PntStats.rates_count;
	SWave[curr_i][4] = PntStats.steps_count; 
	SWave[curr_i][5] = PntStats.rates_count / 4 / stepStats.counter; // should define RKOrder;
	SWave[curr_i][6] = PntStats.holds_count; 
	SWave[curr_i][7] = PntStats.restart_count; 
	SWave[curr_i][8] = PntStats.limit_count; 
	if ((stepStats.DoLog > 1) && (stepStats.lim_worst_Cmp >= 0))
		SWave[curr_i][9] = stepStats.lim_worst_Cmp; 
		SWave[curr_i][10] = stepStats.statStepWave[stepStats.lim_worst_Cmp][0]; // worst reaction
		SWave[curr_i][11] = stepStats.statStepWave[stepStats.lim_worst_Cmp][1]; // worst RK step
		SWave[curr_i][12] = stepStats.statStepWave[stepStats.lim_worst_Cmp][2]* stepStats.statStepWave[stepStats.lim_worst_Cmp][3]; // number (+ rise, - drop)
	else
		SWave[curr_i][9,12] = NaN;
	endif
	SWave[curr_i][13] = Q_cum_tot; // total charge from all sources, this should account for variation in sim step
	stepStats.counter  = 0;
	if (stepStats.DoLog > 1)
		stepStats.statStepWave = 0;
		stepStats.statRiseWave = 0;
		stepStats.statDropWave = 0;
	endif
	
	PntStats.rates_count = 0;
	PntStats.steps_count = 0;
	PntStats.holds_count = 0;
	PntStats.restart_count = 0;
	PntStats.limit_count = 0;
end
 
//----------------------------------------------------------
// 
threadsafe function SimCompleteStep(stepStats, PntStats, stats, tmpData)
	STRUCT stepStatsT &stepStats;
	STRUCT simPointStats &PntStats;
	STRUCT simStatsT &stats;
	STRUCT simTmpDataT &tmpData;

	// update temp values with the result of sim
	tmpData.TWave[1,4][] = tmpData.RKWave[p-1][0][q][0] + tmpData.RKWave[p-1][4][q][0];
	tmpData.TWave[7,10][]  = tmpData.RKWave[p-7][4][q][0]; // calculated rate of change
	tmpData.TWave[11,14][] += tmpData.RKWave[p-11][4][q][0]; 

	PntStats.steps_count += stepStats.steps_count;
	PntStats.rates_count += stepStats.rates_count;
	PntStats.holds_count += stepStats.holds_count;
	PntStats.restart_count += stepStats.restart_count;
	PntStats.limit_count += stepStats.limit_count;
	stats.holds_count_cum += stepStats.holds_count;
	stats.restart_count_cum +=stepStats.restart_count;
	stats.limit_count_cum += stepStats.limit_count;	


end

