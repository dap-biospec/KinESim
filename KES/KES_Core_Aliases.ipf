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
// prepare alias wave from alias settings in the CWave
//
threadsafe  function /S prepSimAliases(commName, cN,  simTmpData, CWave, stealth) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	wave CWave;
	variable stealth;
	
	string result = "";
	variable i,j,k; 
	redimension /N=( -1, cN+1, -1) simTmpData.AliasW
	simTmpData.AliasW[][1,][] = NaN
	
	// 1st pass - copy aliases as-is
	variable thisCmpRow;
	variable thisCmpState; 

	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			simTmpData.AliasW[thisCmpRow][0][thisCmpState]  = NaN; // default to no alias
			variable AliasVal = CWave[13+thisCmpState][thisCmpRow] ;
			if ((numType(AliasVal) == 0) )
				variable AliasCmp = abs(AliasVal) ; // This must be 1- based or informartion on cmp 0 is lost!
				if ( AliasCmp > cN || AliasCmp <=0 ) // this is an invalid condition!
					result += "Alias for ";
					if (thisCmpState > 0)
						result += "Rd";
					else
						result += "Ox";
					endif
					result += " C"+num2istr(thisCmpRow)+" is out of range ("+num2str( AliasVal - 1)+");"; 
				else
					simTmpData.AliasW[thisCmpRow][0][thisCmpState] =  AliasVal;
				endif
			endif
		endfor
	endfor
	
	// 2nd pass - sort aliases 
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			if (!numtype(simTmpData.AliasW[thisCmpRow][0][thisCmpState]) ) // this is an alias, reduced or oxidized
				variable thisAliasRow = abs(simTmpData.AliasW[thisCmpRow][0][thisCmpState])-1; // aliases in CWave are 1-based
				variable thisAliasState = simTmpData.AliasW[thisCmpRow][0][thisCmpState] > 0 ? 0 : 1; 
				variable toRow, toState, aliasRow, aliasState; 
				
				if (thisAliasRow <= thisCmpRow) // this is an alias to preceeeding component  - move it there
					toRow= thisAliasRow;
					toState =thisAliasState;
					aliasRow =  thisCmpRow;
					aliasState = thisCmpState;
				else
					toRow= thisCmpRow;
					toState =thisCmpState;
					aliasRow =  thisAliasRow;
					aliasState = thisAliasState;
				
				endif
				for (j=1; j<dimsize(simTmpData.AliasW, 1); j+=1)
					if (numtype ( simTmpData.AliasW[toRow][j][toState])) // this position is empty
						simTmpData.AliasW[toRow][j][toState] = (aliasRow +1)* ((aliasState > 0) ? -1 : 1) ; // positive or negative
						simTmpData.AliasW[thisCmpRow][0][thisCmpState] = NaN;
						break;
					endif
				endfor
			endif 
		endfor 	
	endfor
	
	// 3rd pass - combine aliases 
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			variable nAliases = dimsize(simTmpData.AliasW, 1);
			variable firstEmpty = 1;
			for (firstEmpty=1; firstEmpty<nAliases; firstEmpty+=1) // find first empty slot in the base compound list 
				if (numtype ( simTmpData.AliasW[thisCmpRow][firstEmpty][thisCmpState])) // this position is empty
					break;
				endif
			endfor
			// firstEmpty may be beyond dimensions of current array!
			for (j=1; j<firstEmpty; j+=1)
				// check if there are other aliases at that position and copy all over 
				variable testCmpRow = abs(simTmpData.AliasW[thisCmpRow][j][thisCmpState])-1; 
				variable testCmpState = simTmpData.AliasW[thisCmpRow][j][thisCmpState] > 0? 0 : 1;
					
				for (k=1; k<nAliases; k+=1)
					if (!numtype ( simTmpData.AliasW[testCmpRow][k][testCmpState])) // this position is not empty
						if (testCmpRow == thisCmpRow && testCmpState == thisCmpState)
						else
							// copy it to first empty and reset that position
							if (firstEmpty >=  nAliases )
								nAliases +=1;
								redimension /N=(-1,nAliases, -1) simTmpData.AliasW
								simTmpData.AliasW[][nAliases -1][] = NaN;
							endif
							simTmpData.AliasW[thisCmpRow][firstEmpty][thisCmpState] = simTmpData.AliasW[testCmpRow][k][testCmpState];
							simTmpData.AliasW[testCmpRow][k][testCmpState] = NaN;	
							firstEmpty +=1;
						endif
					endif
				endfor
			endfor
		endfor
	endfor	
	
	// 4th pass - check for merger points
	// A - create merger table 
	make /N=(cN, cN, 2) /FREE MergerW;
	
	MergerW[][][] = NaN;
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			for (i=1; i<cN; i+=1)
				if (!numtype(simTmpData.AliasW[thisCmpRow][i][thisCmpState])) // there is a reference to anther component
					testCmpRow = abs(simTmpData.AliasW[thisCmpRow][i][thisCmpState])-1; 
					testCmpState = simTmpData.AliasW[thisCmpRow][i][thisCmpState] > 0? 0 : 1;
					for (j=0; j< cN; j+=1)
						if (numtype(MergerW[testCmpRow][j][testCmpState])) // no value here 
							MergerW[testCmpRow][j][testCmpState] = (thisCmpRow+1)* (thisCmpState>0 ? -1 :1);
							break;
						endif
					endfor
				endif
			endfor
		endfor
	endfor
	
	
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			if (numtype(MergerW[thisCmpRow][1][thisCmpState])) // there are less than two entries!
				continue;
			endif
			// merger needs to be done to that address 
			variable baseCmpRow =  abs(MergerW[thisCmpRow][0][thisCmpState])-1; 
			variable baseCmpState =  (MergerW[thisCmpRow][0][thisCmpState] < 0) ? 1 : 0;
			if (thisCmpState >0)
				string thisSign = "-";
			else
				thisSign = "+";
			endif
			
			if (baseCmpState >0)
				string baseSign = "-";
			else
				baseSign = "+";
			endif

			for (i=1; i<cN;  i+=1)
				if (numtype(MergerW[thisCmpRow][i][thisCmpState])) // no more groups to copy
					break;
				endif 
				
				variable siblingCmpRow =  abs(MergerW[thisCmpRow][i][thisCmpState])-1; 
				variable siblingCmpState =  (MergerW[thisCmpRow][i][thisCmpState] < 0) ? 1 : 0;
				
				if (siblingCmpState >0)
					string siblingSign = "-";
				else
					siblingSign = "+";
				endif
				
				// copy aliases of that compound into this base compound
				// find empty slot in the base compund list
				nAliases = dimsize(simTmpData.AliasW, 1);
				firstEmpty = 1;
				for (firstEmpty=1; firstEmpty<nAliases; firstEmpty+=1) // find first empty slot in the base compound list 
					if (numtype ( simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState])) // this position is empty
						break;
					endif
				endfor

				// firstEmpty may be beyond current array!
				// first copy the base of sibling
				if (firstEmpty >=  nAliases )
					nAliases +=1;
					redimension /N=(-1,nAliases, -1) simTmpData.AliasW
					simTmpData.AliasW[][nAliases -1][] = NaN;
				endif
				simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState] =  (siblingCmpRow+1)*(siblingCmpState > 0? -1:1);
				firstEmpty+=1;
				// then copy alias chain of sibling
				for (k=1; k<nAliases; k+=1)
					if (!numtype ( simTmpData.AliasW[siblingCmpRow][k][siblingCmpState])) // this position is not empty
						variable siblingEntryRow = abs(simTmpData.AliasW[siblingCmpRow][k][siblingCmpState]) -1
						variable siblingEntryState = simTmpData.AliasW[siblingCmpRow][k][siblingCmpState] > 0 ? 0: 1;
						if (siblingEntryState >0)
							string entrySign = "-";
						else
							entrySign = "+";
						endif

						if (siblingEntryRow == thisCmpRow && siblingEntryState == thisCmpState) 
						else
							// copy it to first empty and reset that position
							if (firstEmpty >=  nAliases )
								nAliases +=1;
								redimension /N=(-1,nAliases, -1) simTmpData.AliasW
								simTmpData.AliasW[][nAliases -1][] = NaN;
							endif
							simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState] =  simTmpData.AliasW[siblingCmpRow][k][siblingCmpState];
							firstEmpty +=1;
						endif
					endif
				endfor
				// now erase the copied alias string
				simTmpData.AliasW[siblingCmpRow][][siblingCmpState] = NaN;
			endfor
		endfor
	endfor
	
	
	// 4th pass - write self and remove self-references
	variable longestAlias = 0;
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow <  cN; thisCmpRow += 1)
			if (!numtype ( simTmpData.AliasW[thisCmpRow][1][thisCmpState])) // this position is empty; there are no aliases
				simTmpData.AliasW[thisCmpRow][0][thisCmpState] = (thisCmpRow +1)  * (thisCmpState > 0 ? -1 : 1);
				if (1<2)
				nAliases = dimsize(simTmpData.AliasW, 1);
				for (i=0; i< nAliases; i+=1)
					if (numtype (simTmpData.AliasW[thisCmpRow][i][thisCmpState])) // this is empty
						continue;
					endif
					for (j=i+1; j<nAliases; j+=1)
						if (numtype (simTmpData.AliasW[thisCmpRow][j][thisCmpState])) // this is empty
							break;
						endif
						if (simTmpData.AliasW[thisCmpRow][i][thisCmpState] == simTmpData.AliasW[thisCmpRow][j][thisCmpState]) // this is a duplicate
							simTmpData.AliasW[thisCmpRow][j,nAliases - 2][thisCmpState] = simTmpData.AliasW[thisCmpRow][q+1][thisCmpState];
							simTmpData.AliasW[thisCmpRow][nAliases - 1][thisCmpState] = NaN;
						
						endif
					endfor
					if (i >= longestAlias)
						longestAlias = i+1;
					endif
				endfor
				endif
			endif 
		endfor
	endfor	

	// 5th pass - group aliases
	variable nAliasGroups = dimsize(simTmpData.AliasW, 0);
	variable nextAliasGroup = 0; // row to store next found group
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow <  nAliasGroups; thisCmpRow += 1)
			if (numtype ( simTmpData.AliasW[thisCmpRow][1][thisCmpState])) // this position is empty; there are no aliases
				simTmpData.AliasW[thisCmpRow][][thisCmpState] = NaN; // deletepoints /M=0 thisCmpRow, 1,  simTmpData.AliasW
			else
				if (thisCmpRow != nextAliasGroup || thisCmpState != 0)
					if (nextAliasGroup >=nAliasGroups )
						redimension /N=(nextAliasGroup+1, -1, -1) simTmpData.AliasW
						nAliasGroups = dimsize(simTmpData.AliasW, 0);
					endif
					simTmpData.AliasW[nextAliasGroup][][0] = simTmpData.AliasW[thisCmpRow][q][thisCmpState];
					simTmpData.AliasW[thisCmpRow][][thisCmpState] = NaN;
				endif
				nextAliasGroup +=1;
			endif 
		endfor
	endfor
	
	// 6th pass - trim alias set

	  
	// ..th pass - prep for simulation
	// trim set to just aliases
	redimension /N=(nextAliasGroup, longestAlias) simTmpData.AliasW
	if (!stealth)	
		for (	thisCmpState = 0; thisCmpState <=dimSize(simTmpData.AliasW,2); thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
			for (thisCmpRow=0; thisCmpRow<dimSize(simTmpData.AliasW,0);  thisCmpRow+=1)
				string thisCmp =  "\rAlias group#"+num2istr(thisCmpRow)+" ";
				string thisAliases = "";
				string thisRaw = " (raw "
				for (j=0; j< dimSize(simTmpData.AliasW,1); j+=1)
					if (!numtype(simTmpData.AliasW[thisCmpRow][j][thisCmpState]))
						if (strlen(thisAliases))
							thisAliases += ", ";
						endif
						if (simTmpData.AliasW[thisCmpRow][j][thisCmpState] >= 0)
							thisAliases += "+";
						else
							thisAliases += "-";
						endif
						thisAliases += num2istr(abs(simTmpData.AliasW[thisCmpRow][j][thisCmpState])-1)
					endif
					if (j >0)
						thisRaw += ",";
					endif
					thisRaw +=  num2str(simTmpData.AliasW[thisCmpRow][j][thisCmpState])
				endfor
				if (strlen(thisAliases))
					thisCmp += thisAliases;
				else
					thisCmp += " no aliases";
				endif
				thisCmp+= thisRaw+")";
				print thisCmp;
			endfor 
		endfor 	
	
		if (1>2) // for debugging
			Print " "
			for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
				Print "Merger points for state ", thisCmpState, " of ", commName
				for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
					thisCmp =  "Cmp#"+num2istr(thisCmpRow)+" ";
					thisRaw = " raw "
					for (j=0; j< cN+1; j+=1)
						if (j >0)
							thisRaw += ",";
						endif
						thisRaw +=  num2str(MergerW[thisCmpRow][j][thisCmpState])
					endfor
					thisCmp+= thisRaw+"";
					print thisCmp;
				endfor
			endfor 	
		endif
	endif	
	return ""
end




//----------------------------------------------------------
// combine all concentraions in the group and set them all equal to it
//
threadsafe function InitAliasGroup(AliasW, TWave)
	wave AliasW
	wave TWave
	
	variable aGr, aEntry, entryCmp, gr_C0tot_sol //, gr_dC_sol
		
	for (aGr = 0; aGr < dimsize (AliasW, 0); aGr +=1)
		gr_C0tot_sol = 0;
		for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
			if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
				break;
			endif
			entryCmp = abs(AliasW[aGr][aEntry] )-1;
			if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
				gr_C0tot_sol += TWave[1][entryCmp]; 
			else // use reduced form of that alias
				gr_C0tot_sol += TWave[4][entryCmp]; 
			endif 
		endfor
		
		for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
			if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
				break;
			endif
			entryCmp = abs(AliasW[aGr][aEntry])-1 ;
			if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
				TWave[1][entryCmp]= gr_C0tot_sol; 
			else // use reduced form of that alias
				TWave[4][entryCmp]= gr_C0tot_sol; 
			endif 
			
		endfor		
	endfor
	
end

//----------------------------------------------------------
//
threadsafe function CombAliasGroup(AliasW, RKWave)
	wave AliasW
	wave RKWave
		
	variable aGr, aEntry, entryCmp, gr_C0tot_sol, gr_dC_sol
			
		for (aGr = 0; aGr < dimsize (AliasW, 0); aGr +=1)
			if (numtype(AliasW[aGr][0]))
				continue; // this should not be - group with no members!
			endif  
			gr_dC_sol = 0;

			// add up al the changes
			for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
				if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
					break;
				endif
				entryCmp = abs(AliasW[aGr][aEntry])-1;
				if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
					gr_dC_sol +=  RKWave[0][4][entryCmp][0];
					RKWave[0][3][entryCmp][0] = 1;
					if (entryCmp == 0)
						gr_C0tot_sol = RKWave[0][0][entryCmp][0];
					endif
				else // use reduced form of that alias
					gr_dC_sol +=  RKWave[3][4][entryCmp][0];
					RKWave[3][3][entryCmp][0] = 1;
					if (entryCmp == 0)
						gr_C0tot_sol = RKWave[3][0][entryCmp][0];
					endif
				endif 
			endfor
			// assign total changes to each member of the alias group
			variable gr_C1tot_sol = gr_C0tot_sol + gr_dC_sol;
			
			for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
				if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
					break;
				endif
				entryCmp = abs(AliasW[aGr][aEntry])-1;
				if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
					RKWave[0][1][entryCmp][0] = gr_C1tot_sol;
					RKWave[0][4][entryCmp][0] = gr_dC_sol;
				else // use reduced form of that alias
					RKWave[3][1][entryCmp][0] = gr_C1tot_sol;
					RKWave[3][4][entryCmp][0] = gr_dC_sol;
				endif 
			endfor
		endfor
	
end
