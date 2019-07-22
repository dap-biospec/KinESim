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

//========================================================================
//
structure RKParamsT 
		variable cN;
		variable cF
		variable RKi_drop_max_Sol	
		variable RKi_rise_max_Sol
		variable RKi_drop_max_El
		variable RKi_rise_max_El
		
		variable RK_drop_lim_time_X
		variable RK_rise_lim_time_X
		variable StepIncrement

		variable RKFull_drop_max_Sol
		variable RKFull_rise_max_Sol
		
		variable RKFull_drop_max_El
		variable RKFull_rise_max_El

		
		wave RK4TmpW
			
endstructure

//========================================================================
// main entry point for singlethreaded integration
// this function must be threadsafe to permit parallelization of preceeding steps and cannot be replaced by RK4RatesPrl
//

threadsafe  function RK4RatesSeq(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, curr_E, simStep,  maxStep, lastDesiredStep, stepHold, StepsCount, stepStats) 
	// adjusts sim step, all rates are in TWave
	wave PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E, &simStep;
	variable maxStep; 
	variable StepsCount;
	STRUCT stepStatsT &stepStats;
	wave RxInWave, RxRKWave
	variable &lastDesiredStep
	variable &stepHold
	
	variable cN = dimsize(CWave, 1);
	variable i,j; //, j, k;	

	string RK4TmpWN = "tmp_RK4"
	wave RK4TmpW = $RK4TmpWN;
	variable RK_order = 4;
	
	RKPrepCmps(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E);

	variable sol_height = PWave[10]; 
	variable RK4_time_step = PWave[20];
	variable RKStep = 0;
	variable Euler_done = 0;

	// attempt to boost the time
	if (stepHold > 0)
		stepHold -=1;
		simStep = lastDesiredStep;
	else
		simStep = lastDesiredStep * RK4_time_step;
	endif

	lastDesiredStep = simStep;
	if (maxStep > 0 && simStep > maxStep)
		simStep = maxStep;
	endif 
	
	stepStats.init_step_t = simStep;
	resetStepStats(stepStats);
	
	STRUCT RKParamsT params;
	prepRKParams(params, PWave, RKWave);
	
	for (RKStep=0 ; RKStep<4; RKStep+=1)
		if (RKStep > 0 || !Euler_done)
			RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) ;
			Euler_done = 1;
			stepStats.rates_count +=1;
		endif;

		if (RKStep == RK_Order -1)
				if (finishRK(params, RK_Order, RKWave, TWave, simStep, stepStats))
					continue;
				endif	// else do it over....
				RKStep = 0; // values of C0_i do not change with iteration! simply restart with smaller step
				stepStats.restart_count +=1;
		endif
		stepRK(params, RK_Order, RKStep, RKWave, TWave, simStep,  stepStats);
	endfor 

	RKWave[][1][][0] =  RKWave[p][0][r][0] + RKWave[p][RK_order][r][0] 
	RKWave[][2][][0] =  RKWave[p][RK_order][r][0] / RKWave[p][0][r][0]; 
	// p is the form of this component (Ox, Rd, sol, el);
	// q is RK order
	// r is individual component
	
	// RKWave[][0][i][0] contains C0
	// RKWave[][1][i][0] contains C(+1) for this simStep
	// RKWave[][2][i][0] contains dC/C for this simStep
	// RKWave[][RKOrder][i][0] contains dC for this simStep
	
	RKPostCmps(RK_order, CWave,  TWave, RKWave) 
	stepStats.final_Step_t = simStep;
	stepStats.counter +=1;
	if (stepStats.final_Step_t < stepStats.init_step_t) // step was reduced
		lastDesiredStep = 	simStep;
		stepHold = PWave[16] 
		stepStats.holds_count +=1;
	endif 
end

//========================================================================
// main entry point for multithreaded integration
//
function RK4RatesPrl(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E, simStep,  maxStep, lastDesiredStep, stepHold, StepsCount, stepStats, threadGroupID) // adjusts sim step, all rates are in TWave
	wave PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E, &simStep;
	variable maxStep; 
	variable StepsCount;
	STRUCT stepStatsT &stepStats;
	variable threadGroupID;
	wave RxInWave, RxRKWave;
	variable &lastDesiredStep;
	variable &stepHold;
	

	
	variable cN = dimsize(CWave, 1);
	variable i,j; //, j, k;	

	string RK4TmpWN = "tmp_RK4"
	wave RK4TmpW = $RK4TmpWN;
	variable RK_order = 4;
	
	RKPrepCmps(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E); //, i) 

	variable sol_height = PWave[10]; 
	variable RK4_time_step = PWave[20];
	variable RKStep = 0;
	variable Euler_done = 0;

	// attempt to boost the time
	if (stepHold > 0)
		stepHold -=1;
		simStep = lastDesiredStep;
	else
		simStep = lastDesiredStep * RK4_time_step;
	endif

	lastDesiredStep = simStep;
	if (maxStep > 0 && simStep > maxStep)
		simStep = maxStep;
	endif 

	stepStats.init_step_t = simStep;
	resetStepStats(stepStats);

	STRUCT RKParamsT params;
	prepRKParams(params, PWave, RKWave);
		
	for (RKStep=0 ; RKStep<4; RKStep+=1)
		if (RKStep > 0 || !Euler_done)
			if (threadGroupID >= 0)
				RKCmpRatesMT(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep, threadGroupID) ;
			else
				RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) ;
			endif 
			Euler_done = 1;
			stepStats.rates_count +=1;
		endif;

		if (RKStep == RK_Order -1)
				if (finishRK(params, RK_Order, RKWave, TWave, simStep, stepStats))
					continue;
				endif	// else do it over....
				RKStep = 0; // values of C0_i do not change with iteration! simply restart with smaller step
				stepStats.restart_count +=1;
		endif
		stepRK(params, RK_Order, RKStep, RKWave, TWave, simStep,  stepStats);
	endfor 

	RKWave[][1][][0] =  RKWave[p][0][r][0] + RKWave[p][RK_order][r][0] 
	RKWave[][2][][0] =  RKWave[p][RK_order][r][0] / RKWave[p][0][r][0];
	// p is the form of this component (Ox, Rd, sol, el);
	// q is RK order
	// r is individual component

	// RKWave[][0][i][0] contains C0
	// RKWave[][1][i][0] contains C(+1) for this simStep
	// RKWave[][2][i][0] contains dC/C for this simStep
	// RKWave[][RKOrder][i][0] contains dC for this simStep
	
	RKPostCmps(RK_order, CWave, TWave, RKWave) 

	stepStats.final_Step_t = simStep;
	stepStats.counter +=1;
	if (stepStats.final_Step_t < stepStats.init_step_t) // step was reduced
		lastDesiredStep = 	simStep;
		stepHold = PWave[16] 
		stepStats.holds_count +=1;
	endif 
end

//========================================================================
//
threadsafe function RKPrepCmps(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, curr_E) 
	wave CWave,  TWave, PWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E;
	wave RxInWave, RxRKWave;
	variable i // index of the component

	variable k_on, k_off, E_k0, k_ET_ox, k_ET_rd
	variable cN = dimsize(CWave, 1);

	RKWave[][][][1] = 0;
	RxRKWave[][] = 0;
		
	// values in CWave must be balanced against total
	for (i=0; i<cN ; i+=1)		
		E_k0 = CWave[4][i];
		
		if (TWave[0][i]  > 0 ) 	// 1. component is present in the solution
			RKWave[0, 3; 3][0][i][0] = TWave[p+1][i]; // Ox and Rd in solution
			if (E_k0 > 0) 		// 2. rate of the electrode reaction is set 
				// check for previous Eapp and see if recaclulation is necessary							
				variable K_ET_0  = exp(TWave[21][i] * (curr_E - CWave[2][i])); // ET eq. constant  <- this can be done once per RK4 and stored in 
				k_ET_ox = E_k0 * K_ET_0; // forward
				k_ET_rd = E_k0 / K_ET_0; // reverse
				variable limRate = CWave[8][i];
				variable limMode = PWave[3];
				if ((limRate > 0) && (limMode > 0)) // there is limiting rate; no binding 
					variable k_ET_rd_lim, k_ET_ox_lim;
					k_ET_rd_lim = 1.0/((1.0/k_ET_rd) + (1.0/limRate)); 
					k_ET_ox_lim = 1.0/((1.0/k_ET_ox) + (1.0/limRate)); 
					switch (floor(limMode))
						case 1: // limit both
							TWave[24][i] = k_ET_rd_lim;
							TWave[25][i] = k_ET_ox_lim;
							break;
						case 2: // limit,correct both
							variable K_corr_sym = sqrt((k_ET_ox_lim / k_ET_rd_lim) / K_ET_0);
							TWave[24][i] = k_ET_rd_lim * K_corr_sym;
							TWave[25][i] = k_ET_ox_lim / K_corr_sym;
							break;
						case 3: // limit fast, correct slow
							variable K_corr_asm = ((k_ET_ox_lim / k_ET_rd_lim ) / K_ET_0);
							if (k_ET_ox < k_ET_rd) // limit reduction, correct oxidation
								TWave[24][i] = k_ET_rd_lim;
								TWave[25][i] = k_ET_ox_lim / K_corr_asm;
							else // limit oxidation, correct reduction
								TWave[24][i] = k_ET_rd_lim * K_corr_asm;
								TWave[25][i] = k_ET_ox_lim ;
							endif 
							break;
						case 5:
						case 4: // balanced correction
							variable K_corr_flex = ((k_ET_ox_lim / k_ET_rd_lim ) / K_ET_0);
							variable currK = k_ET_ox_lim/ k_ET_rd_lim;
							variable corrPower = currK / (1+currK)
							TWave[24][i] = k_ET_rd_lim *  (K_corr_flex ^ corrPower) ;
							TWave[25][i] = k_ET_ox_lim / (K_corr_flex ^ (1-corrPower));
							break;
						default:
					endswitch 
					TWave[23][i] = K_ET_0;
					RKWave[1,2][0][i][0] = -1;
				else // no limiting rate, maybe binding?
					k_on = TWave[28][i];
					k_off = TWave[29][i];
					if (k_on > 0 && k_off > 0) // 3. binding does occur
						TWave[23][i] = K_ET_0;
						TWave[24][i] =  k_ET_rd;
						TWave[25][i] =  k_ET_ox;
						RKWave[1,2][0][i][0] = TWave[p+1][i]; // Ox and Rd on the electrode
					else // no limit and no binding 
						TWave[23][i] = NaN;
						TWave[24, 25][i] = 0;
						RKWave[1,2][0][i][0] = -1;
					endif 
					TWave[23][i] =  K_ET_0;

				endif
			else // no echem, no binding to consider; but solution txn may still go on
				TWave[23][i] = NaN;
				TWave[24, 25][i] = NaN;
				RKWave[0, 3; 3][0][i][0] = TWave[p+1][i]; // Ox sol 
			endif
		else // there is no component in the system
			TWave[23][i] = NaN;
			RKWave[][0][i][0] = -1; // to avoid division by zero error
		endif 
	endfor

end

//========================================================================
//
// placefolder function for checking and adjusting RK parameters, if necessary

threadsafe function RKPostCmps(RK_Order, CWave, TWave, RKWave) 
	variable RK_Order
	wave CWave, TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	
	return 0;
end




//========================================================================
//
// obtain rates based on specified concentrations. 
//

function RKCmpRatesMT(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep, threadGroupID) // returns sim step, all rates are in TWave
	wave  PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable RKStep;
	variable threadGroupID
	wave RxInWave // reaction rates annd stoichiometry
	wave RxRKWave // wave to store solution RK values

	variable i, j;
	variable cN = dimsize(CWave, 1);	
	variable sol_height = PWave[10]; 

	// calculate current vectors for each solution rxn
	 RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 
	 
	Variable dummy

	// now generate total vectors for each component
	for (i=0; i<cN ; i+=1)	
		if (TWave[0][i]  <= 0) // component is present in the system
			continue;
		endif
		Variable threadIndex = ThreadGroupWait(threadGroupID,-2) - 1		
		if (threadIndex < 0)
			dummy = ThreadGroupWait(threadGroupID, 10)// Let threads run a while
			i -= 1 // Try again for the same column
			continue // No free threads yet
		endif
		ThreadStart threadGroupID, threadIndex,  getCmpVector(i, RKStep, sol_height, PWave, CWave, RxInWave, RxRKWave, TWave, RKWave)		
	endfor
	do
		Variable threadGroupStatus = ThreadGroupWait(threadGroupID,0)
		if (threadGroupStatus == 0)
			threadGroupStatus = ThreadGroupWait(threadGroupID,10)
		endif
	while(threadGroupStatus != 0)
end


//========================================================================
//
threadsafe  function RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) // returns sim step, all rates are in TWave
	wave  PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable RKStep;
	wave RxInWave, RxRKWave
	
	
	variable i, j;
	variable cN = dimsize(CWave, 1);	
	variable sol_height = PWave[10]; 

	// calculate current vectors for each solution pair
	 RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 

	// now generate total vectors for each component
	for (i=0; i<cN ; i+=1)	
		if (TWave[0][i]  <= 0) // component is present in the system
			continue;
		endif
		getCmpVector(i, RKStep, sol_height, PWave, CWave, RxInWave, RxRKWave, TWave, RKWave);
	endfor
end


//========================================================================
//
threadsafe function RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	wave TWave
	wave RxInWave // reaction rates annd stoichiometry
	wave RxRKWave // wave to store solution RK values
	variable cN ; 
	variable RKStep;

	variable rxn, cmp;

	// calculate current vectors for each solution pair
	variable nRxns = dimsize(RxRKWave, 0);
	RxRKWave[][RKStep] = 0;
	for (rxn=0; rxn< nRxns; rxn+= 1)
		variable fwdRxnRate = RxInWave[rxn][0][0] ;
		variable fwdRxnMode = -1;
		variable revRxnRate = RxInWave[rxn][0][1] ;
		variable revRxnMode = -1;
		
		for (cmp=0; cmp< cN; cmp+=1)
			if (TWave[0][cmp] > 0) // componet is present in the solution 
				if (fwdRxnMode != 0)
					variable nReact = RxInWave[rxn][cmp+1][0];
					variable cReact = 0;
					if (nReact > 0) // oxidized form
						cReact =  RKWave[0][RKStep][cmp][0] 
					elseif (nReact < 0) // reduced form
						nReact = -nReact;
						cReact =  RKWave[3][RKStep][cmp][0]
					// else // not participating - skip
					endif 
					if (nReact > 0) // must be involved
						if (cReact > 0)
							fwdRxnRate *= cReact ^ nReact;	
							fwdRxnMode = 1;
						elseif (cReact == 0) // reverse rate is zero, not need to continue calcs
							fwdRxnMode = 0;
						endif 
					// else  no n, not participating 
					endif
				elseif (revRxnMode == 0)
					break; // both rates are zero, regardless of other components; break the loop
				endif 	
				
				if (revRxnMode != 0)
					variable nProd = RxInWave[rxn][cmp+1][1];
					variable cProd = 0;
					if (nProd > 0) // oxidized form
 						cProd =  RKWave[0][RKStep][cmp][0];
					elseif (nProd < 0) // reduced form
						nProd = -nProd;
						cProd =  RKWave[3][RKStep][cmp][0];
					endif 

					if (nProd > 0) // must be involved
						if (cProd > 0)
							revRxnRate *= cProd ^ nProd;	
							revRxnMode = 1;
						elseif (cProd == 0) // reverse rate is zero, not need to continue calcs
							revRxnMode = 0;
						endif 
					// else  no n, not participating 
					endif
				endif // revRxnMode != 0
			endif
		endfor
		
		variable totRxnRate = 0;
		if (revRxnMode > 0 )
			totRxnRate += revRxnRate;
		endif
		if (fwdRxnMode > 0 )
			totRxnRate -= fwdRxnRate;
		endif
		
		RxRKWave[rxn][RKStep] =totRxnRate;
	endfor 
end 

//========================================================================
//

threadsafe  function getCmpVector(i,  RKStep, sol_height, PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave) 
		variable i, RKStep, sol_height; //r1Nx, 
		wave PWave, CWave,  TWave, RKWave;
		wave RxInWave, RxRKWave

		variable j
		
		// get all solution echem rates for this component
		// for pure echem reduction and oxidation rates are the same, but for rxns with isomerization it may not be!
		variable C_soln_Rd_rate = 0; 
		variable C_soln_Ox_rate = 0; 
		for (j=0; j< dimsize(RxRKWave, 0); j+=1)
			variable nReact = RxInWave[j][i+1][0]
			variable nProd = RxInWave[j][i+1][1]

			variable netRate = -RxRKWave[j][RKStep] // fwdRate - revRate;
				
				if (nReact>0) // gain of oxidized 
					C_soln_Ox_rate -=nReact  * netRate
				elseif (nReact<0) // gain of reduced
					C_soln_Rd_rate += nReact  * netRate
				endif;

				if (nProd>0) // gain of oxidized 
					C_soln_Ox_rate +=nProd  * netRate
				elseif (nProd<0) // gain of reduced
					C_soln_Rd_rate -=nProd  * netRate
				endif;			
		endfor  

		// now the electrode					
		variable limRate = CWave[8][i];
		variable limMode = PWave[3];

		variable ET_rate = 0; // effective ET rate, limited or not
		if (limRate > 0 && limMode > 0) // there is limiting rate and no binding
			variable k_ET_rd_lim = TWave[24][i];
			variable k_ET_ox_lim  = TWave[25][i];
			variable C_ox_tot = RKWave[0][RKStep][i][0];// , TWave[1][i];
			variable C_rd_tot = RKWave[3][RKStep][i][0];// TWave[4][i];
			if (k_ET_rd_lim > 0 && k_ET_ox_lim > 0) // there is ET
				ET_rate = (C_ox_tot * k_ET_rd_lim -  C_rd_tot * k_ET_ox_lim);
			endif 
			RKWave[0][RKStep][i][1] = +C_soln_Ox_rate - ET_rate;  // Ox sol
			RKWave[3][RKStep][i][1] = +C_soln_Rd_rate + ET_rate; // Rd sol
		else  // no limiting rate; does binding occur?
			variable k_on = TWave[28][i];
			variable k_off = TWave[29][i];
			if (k_on > 0 && k_off > 0 ) // binding does occur
				variable C_ox_sol = RKWave[0][RKStep][i][0];// , TWave[1][i];
				variable C_rd_sol = RKWave[3][RKStep][i][0];// TWave[4][i];
				variable C_ox_el = RKWave[1][RKStep][i][0];// TWave[2][i];
				variable C_rd_el = RKWave[2][RKStep][i][0];// TWave[3][i];
					
				// calculate redox rates for oxidized / reduced species
				variable k_ET_rd = TWave[24][i];
				variable k_ET_ox  = TWave[25][i];
				if (k_ET_rd > 0 && k_ET_ox > 0) // there is ET
					ET_rate = (C_ox_el * k_ET_rd -  C_rd_el * k_ET_ox);
				endif 
					
				variable Bind_Ox_rate = C_ox_sol * k_on -  C_ox_el * k_off / sol_height; // net binding rate of the oxidized component
				variable Bind_Rd_rate = C_rd_sol * k_on -  C_rd_el * k_off / sol_height; // net binding rate of the reduced component
					
				RKWave[0][RKStep][i][1] = +C_soln_Ox_rate - Bind_Ox_rate;  // Ox sol
				RKWave[1][RKStep][i][1] = -ET_rate + Bind_Ox_rate;  // Ox el
				RKWave[2][RKStep][i][1] = +ET_rate + Bind_Rd_rate; // Rd el 
				RKWave[3][RKStep][i][1] = +C_soln_Rd_rate - Bind_Rd_rate; // Rd sol
			else // no binding, no echem
				RKWave[0][RKStep][i][1] = +C_soln_Ox_rate;  // Ox sol
				RKWave[3][RKStep][i][1] = +C_soln_Rd_rate ; // Rd sol
			endif			
		endif

end


//--------------------------------------------------------------------------
//
threadsafe function resetStepStats(stepStats)
	STRUCT stepStatsT &stepStats;
	stepStats.lim_code_inner0 = NaN;
	stepStats.lim_code_inner1 = NaN;
	stepStats.lim_code_inner2 = NaN;
	stepStats.lim_code_inner3 = NaN;
	stepStats.lim_rel_inner0 = NaN;
	stepStats.lim_rel_inner1 = NaN;
	stepStats.lim_rel_inner2 = NaN;
	stepStats.lim_rel_inner3 = NaN;
	stepStats.lim_code_outer = NaN;
	stepStats.lim_rel_outer = NaN;
	
	// stepStats.init_step_t  - this is set in calling function
	// stepStats.final_step_t  - this is set in calling function

	stepStats.steps_count = 0;
	stepStats.rates_count = 0
	stepStats.holds_count = 0;
	stepStats.restart_count = 0;
	stepStats.limit_count = 0;	
	
	// stepStats.doLog - is maintained
	if (stepStats.doLog > 1)
		stepStats.StatRiseWave = 0;
		stepStats.StatDropWave = 0;
		// stepStats.StatStepWave is fully computed at the end
		// stepStats.lim_Worst_Cmp is also determined at the end		
	endif
	
	// stepStats.counter is continous
	
	
end






//========================================================================
//
threadsafe function prepRKParams(params, PWave, RKWave)
	STRUCT RKParamsT &params;
	wave PWave, RKWave
	
			
		params.cN=dimsize(RKWave, 2);
		params.cF= dimsize(RKWave, 0);
		params.RKi_drop_max_Sol=PWave[5];	
		params.RKi_rise_max_Sol=PWave[6];	
		params.RKi_drop_max_El=PWave[11];	
		params.RKi_rise_max_El=PWave[12];	
		
		params.RK_drop_lim_time_X = PWave[17];	
		params.RK_rise_lim_time_X = PWave[18];	
		params.StepIncrement = PWave[20];

		string RK4TmpWN = "tmp_RK4"
		wave params.RK4TmpW = $RK4TmpWN;


		params.RKFull_drop_max_Sol =PWave[7];	
		params.RKFull_rise_max_Sol=PWave[8];	
		
		params.RKFull_drop_max_El=PWave[13];	
		params.RKFull_rise_max_El=PWave[14];	

		params.RK_drop_lim_time_X = PWave[17];	
		params.RK_rise_lim_time_X = PWave[18];	
		params.StepIncrement = PWave[20];
		
end


//========================================================================
//
//
//
threadsafe function stepRK(params, RK_Order, RKStep, RKWave, TWave, simStep, stepStats) 
	STRUCT RKParamsT &params;
	variable RK_Order, RKStep;
	
	wave RKWave
	wave TWave
	variable &simStep
	STRUCT stepStatsT &stepStats;

	
	variable Cref = 0;
	
		
		variable i, j
//		, cN=dimsize(RKWave, 2);
//		variable cF= dimsize(RKWave, 0);
//		variable RKi_drop_max_Sol=PWave[5];	
//		variable RKi_rise_max_Sol=PWave[6];	
//		variable RKi_drop_max_El=PWave[11];	
//		variable RKi_rise_max_El=PWave[12];	
//		
//		variable RK_drop_lim_time_X = PWave[17];	
//		variable RK_rise_lim_time_X = PWave[18];	
//		variable StepIncrement = PWave[20];
//
//		string RK4TmpWN = "tmp_RK4"
//		wave RK4TmpW = $RK4TmpWN;

//		variable RK_steps_count;
		do 
			variable reset  =  0;
			variable rise_rel_max = 0;
			variable drop_rel_max = 0;
			variable rise_rel_ref = 0;
			variable drop_rel_ref = 0;
			variable max_rise_Cmp = -1;
			variable max_drop_Cmp = -1;
			variable max_rise_Rxn = -1;
			variable max_drop_Rxn = -1;
			variable TStep;
			stepStats.steps_count += 1;
			switch (RKStep)
				case 0:
				case 1: 	
					TStep = 0.5 * simStep;
					break
				case 2: 
					TStep = simStep;
					break
				case 3: 
			endswitch

			for (i=0; i<params.cN && reset == 0 ; i+=1)		
				if (TWave[0][i]  <=  0) // component is NOT present in the solution
					continue; 
				endif
				for (j=0; j < params.cF; j+=1)
					variable theC_i = RKWave[j][Cref][i][0] 
					if (theC_i < 0) // negative initial concentration means there is no need to consider it.
						continue
					endif 
					variable theR_i = RKWave[j][RKStep][i][1];
					if (theR_i !=0 ) // concentration is changing
						if (theC_i>0 )  // compund is present, may estimate realtive change
							variable thedC_rel_i = abs(theR_i * TStep / theC_i);
							 if (theR_i > 0 ) // rise 
							 	if (j == 0 || j == 3) // solution 
									if ((thedC_rel_i > params.RKi_rise_max_Sol) && (thedC_rel_i > rise_rel_max))
										rise_rel_max = thedC_rel_i;
										rise_rel_ref = params.RKi_rise_max_Sol;
										max_rise_Cmp = i;
										max_rise_Rxn = j;
										reset = 1;
										break; 
									endif
							 	else // electrode 
									if ((thedC_rel_i > params.RKi_rise_max_El) && (thedC_rel_i > rise_rel_max))
										rise_rel_max = thedC_rel_i;
										rise_rel_ref = params.RKi_rise_max_El;
										max_rise_Cmp = i;
										max_rise_Rxn = j;
										reset = 1;
										break; 
									endif
							 	endif 
							elseif (theR_i < 0 ) // fall 
							 	if (j == 0 || j == 3) // solution 
									if ((thedC_rel_i > params.RKi_drop_max_Sol) && (thedC_rel_i > drop_rel_max))
										drop_rel_max =thedC_rel_i;
										drop_rel_ref = params.RKi_drop_max_Sol;
										max_drop_Cmp = i;
										max_drop_Rxn = j;
										reset = 1;
										break; 
									endif
							 	else // electrode 
									if ((thedC_rel_i > params.RKi_drop_max_El) && (thedC_rel_i > drop_rel_max))
										drop_rel_max =thedC_rel_i;
										drop_rel_ref = params.RKi_drop_max_El;
										max_drop_Cmp = i;
										max_drop_Rxn = j;
										reset = 1;
										break; 
									endif
							 	endif 
							endif
						endif
						RKWave[j][RKStep+1][i][0] = RKWave[j][RKStep][i][0] + theR_i * TStep;
					else
						RKWave[j][RKStep+1][i][0] = RKWave[j][RKStep][i][0]; // no rate, conditions remain
					endif 
				endfor
			endfor 
			
			variable newSimStep 
			if (max_drop_Cmp >= 0)
				if (stepStats.limit_count == 0)
					SimStep  /=  params.StepIncrement; //PWave[20]; //RK4_time_step
				else
					if (RKStep == 0 ) 
						newSimStep = SimStep / (drop_rel_max / drop_rel_ref) ;
						if (newSimStep < SimStep)
							SimStep = newSimStep;
						else
							SimStep = newSimStep / params.StepIncrement; 
						endif
					else
						SimStep  *= params.RK_drop_lim_time_X; 
					endif
				endif
			elseif (max_rise_Cmp >= 0)
				if (stepStats.limit_count == 0)
					SimStep  /=  params.StepIncrement; // PWave[20]; //RK4_time_step
				else
					if (RKStep == 3)		
						newSimStep = SimStep / (rise_rel_max / rise_rel_ref) ;
						if (newSimStep < SimStep)
							SimStep = newSimStep;
						else
							SimStep = newSimStep / params.StepIncrement; 
						endif
					else 
						SimStep  *= params.RK_rise_lim_time_X; 
					endif
				endif
			endif

			if (max_rise_Cmp >=0 || max_drop_Cmp >=0)
				RKWave[][1,][][] = 0; // reset all previous values except C0 and Euler rates
				RKStep = 0; // values of C0_i do not change with iteration! simply restart with smaller step
				
				if (stepStats.DoLog > 0)
					stepStats.limit_count += 1;
					if (rise_rel_max > drop_rel_max)
						if (stepStats.DoLog > 1)		
								stepStats.statRiseWave[max_rise_Cmp][max_rise_Rxn][RKStep] += 1;
						endif
						switch (RKStep)
							case 0: 
								stepStats.lim_code_inner0  = max_rise_Cmp * 10 + max_rise_Rxn;
								stepStats.lim_rel_inner0 =  rise_rel_max;
								break;
							case 1: 
								stepStats.lim_code_inner1  = max_rise_Cmp * 10 + max_rise_Rxn;
								stepStats.lim_rel_inner1 =  rise_rel_max				
								break;
							case 2: 
								stepStats.lim_code_inner2  = max_rise_Cmp * 10 + max_rise_Rxn;
								stepStats.lim_rel_inner2 =  rise_rel_max			
								break;
							case 3: 
								stepStats.lim_code_inner3  = max_rise_Cmp * 10 + max_rise_Rxn;
								stepStats.lim_rel_inner3 =  rise_rel_max			
								break;
							endswitch
					else
						if (stepStats.DoLog > 1)		
							stepStats.statDropWave[max_drop_Cmp][max_drop_Rxn][RKStep] += 1;
						endif 					
						switch (RKStep)
							case 0: 
								stepStats.lim_code_inner0  = -(max_drop_Cmp * 10 + max_drop_Rxn);
								stepStats.lim_rel_inner0 =  -drop_rel_max; 
								break;
							case 1: 
								stepStats.lim_code_inner1  = -(max_drop_Cmp * 10 + max_drop_Rxn);
								stepStats.lim_rel_inner1 =  -drop_rel_max; 
								break;
							case 2: 
								stepStats.lim_code_inner2  = -(max_drop_Cmp * 10 + max_drop_Rxn);
								stepStats.lim_rel_inner2 =  -drop_rel_max;
								break;
							case 3: 
								stepStats.lim_code_inner3  = -(max_drop_Cmp * 10 + max_drop_Rxn);
								stepStats.lim_rel_inner3 = -drop_rel_max;
								break;
							endswitch
					endif
				endif
			else
				return 0;
			endif 
		while (1) 
end


//========================================================================
//
threadsafe function finishRK(params, RK_Order, RKWave, TWave, simStep, stepStats) 
	STRUCT RKParamsT &params;
	variable RK_Order
	wave RKWave
	wave TWave
	variable &simStep
	STRUCT stepStatsT &stepStats;

	

//		string RK4TmpWN = "tmp_RK4"
//		wave RK4TmpW = $RK4TmpWN;
	
//		variable RKFull_drop_max_Sol =PWave[7];	
//		variable RKFull_rise_max_Sol=PWave[8];	
//		
//		variable RKFull_drop_max_El=PWave[13];	
//		variable RKFull_rise_max_El=PWave[14];	
//
//		variable RK_drop_lim_time_X = PWave[17];	
//		variable RK_rise_lim_time_X = PWave[18];	
//		variable StepIncrement = PWave[20];
//		
//	
//		variable cN= dimsize(RKWave, 2); // # of components
//		variable cF= dimsize(RKWave, 0); // # of forms for this componnt

		variable i, j

	
		// calculate weighted rate per RK4 model
		switch (RK_order)
			case 4:
				RKWave[][RK_order-1][][1] =  (RKWave[p][0][r][1] + 2*RKWave[p][1][r][1] + 2*RKWave[p][2][r][1] + 2*RKWave[p][3][r][1]) / 6;
				break;
			case 1:
				// no need to do anything, RKWave[][0][][1] already contains intial rates
				break;
			default:
				// this is a problem, must abort
		endswitch
				
		// calculate RK4 change in concentrations at full step after adjustments
		RKWave[][RK_order+0][][0] = SimStep * RKWave[p][RK_order-1][r][1];
				
		// final rates are in, check if they comply with the limits
		variable rise_rel_max = 0
		variable drop_rel_max = 0	
		variable rise_rel_ref = 0;
		variable drop_rel_ref = 0;
		variable max_rise_Cmp = -1;
		variable max_drop_Cmp = -1;
		variable max_rise_Rxn = -1;
		variable max_drop_Rxn = -1;

		variable reset = 0;
		
		for (i=0; i<params.cN ; i+=1)		//&& reset == 0
			if (TWave[0][i]  > 0) // component is present in the solution
				for (j=0; j < params.cF ; j+=1)
					variable theC_i = RKWave[j][0][i][0] //RKWave[j][Cref][i][0] 
					if (theC_i>0)
						variable thedC_i = RKWave[j][RK_order][i][0] // RKWave[j][1][i][0];
						variable thedC_rel_i = abs(thedC_i / theC_i);
						 if (thedC_i > 0 ) // rise 
						 	if (j == 0 || j == 3) // solution 
								if (thedC_rel_i > params.RKFull_rise_max_Sol)
									if (thedC_rel_i > rise_rel_max)
										rise_rel_max = thedC_rel_i;
										max_rise_Cmp = i;
										max_rise_Rxn = j;
									endif
								endif
						 	else // electrode 
								if (thedC_rel_i > params.RKFull_rise_max_El) 
									if (thedC_rel_i > rise_rel_max)
										rise_rel_max = thedC_rel_i;
										max_rise_Cmp = i;
										max_rise_Rxn = j;
									endif
								endif
						 	endif 
						elseif (thedC_i < 0 ) // fall 
						 	if (j == 0 || j == 3) // solution 
								if (thedC_rel_i > params.RKFull_drop_max_Sol)
									if (thedC_rel_i > drop_rel_max)
										drop_rel_max = thedC_rel_i;
										max_drop_Cmp = i;
										max_drop_Rxn = j;
									endif 
								endif
						 	else // electrode 
								if (thedC_rel_i > params.RKFull_drop_max_El)
									if (thedC_rel_i > drop_rel_max)
										drop_rel_max = thedC_rel_i;
										max_drop_Cmp = i;
										max_drop_Rxn = j;
									endif
								endif
						 	endif 
						endif
					endif 
				endfor
			endif
		endfor // components, RK order 0

		variable newSimStep
		if (max_drop_Cmp >= 0 )
			if (stepStats.limit_count == 0)
				SimStep /= params.StepIncrement;
			else
				SimStep *= params.RK_drop_lim_time_X
			endif 
		elseif (max_rise_Cmp >= 0)
			if (stepStats.limit_count == 0)
				SimStep /= params.StepIncrement;
			else
				SimStep *= params.RK_rise_lim_time_X;				
			endif;
		endif

		if (max_rise_Cmp >=0 || max_drop_Cmp >=0 )
			RKWave[][1,][][] = 0; // reset all previous values except C0 and Euler rates
			stepStats.limit_count += 1;

			if (stepStats.DoLog > 0)
				if (rise_rel_max > drop_rel_max)
					if (stepStats.DoLog > 1)
						stepStats.statRiseWave[max_rise_Cmp][max_rise_Rxn][RK_Order] += 1;
					endif 
					stepStats.lim_code_outer = max_rise_Cmp * 10 + max_rise_Rxn;
					stepStats.lim_rel_outer = rise_rel_max;
				else
					if (stepStats.DoLog > 1)
						stepStats.statDropWave[max_drop_Cmp][max_drop_Rxn][RK_Order] += 1;
					endif 
					stepStats.lim_code_outer = -(max_drop_Cmp * 10 + max_drop_Rxn);
					stepStats.lim_rel_outer = -drop_rel_max;
				endif 
			endif
			
			return 0;
		else // all good - carry on
			return 1; 
		endif 
end



