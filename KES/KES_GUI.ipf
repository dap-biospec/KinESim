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
#pragma ModuleName = KES_GUI
#pragma hide=1
strconstant cKESGUIVer = "1.7.0a"

#include ":KES_Core", version >= 20190711
#include ":KES_Sets", version >= 20190711
#include ":KES_GUI_Comp", version >= 20190711
#include ":KES_GUI_Rxns", version >= 20190711
#include ":KES_GUI_Aux", version >= 20190711

//--------------------------------------------------------------------
//
Function AfterCompiledHook()
	if (WinType("KinESimCtrl") != 7) // no such window or a wrong type
		return 0;
	endif 
	
	string actKESVer= GetUserData("KinESimCtrl", "InfoButton", "KESVer" )  
	if (cmpstr(actKESVer, getGUIVer()))
		// version of loaded panel is different
		print "updating KineSim panel to version ", getGUIVer() 
		ControlInfo /W=$("KinESimCtrl") $"jobListWSelect"

		DoWindow /K KinESimCtrl
		Execute /Q "makeKinESimCtrl()"
		PopupMenu jobListWSelect, popmatch=S_value, win=$"KinESimCtrl"

		simReloadPanelJob("KinESimCtrl", "jobListWSelect")
	endif 
end


//--------------------------------------------------------------------
//
Menu "Analysis"
	Submenu "Kin-E-Sim"
		"Control Panel", /Q,makeKinESimCtrl ()
		"Create set", /Q, simCreateMenu();
		"Copy set", /Q, simCopyMenu();
		"Stop all threads", /Q, simStopThreads();
		"Unload", /Q, UnloadKES()
	end
end


//--------------------------------------------------------------------
//

Function simCopyMenu() 
	simCopySet("KinESimCtrl");
end

//--------------------------------------------------------------------
//

Function simCreateMenu() 
	simCreateSet("KinESimCtrl")	
end

//--------------------------------------------------------------------
//
Function UnloadKES()
	if (WinType("KinESimCtrl") == 7)
		DoWindow/K KinESimCtrl
	endif
	Execute/P "COMPILEPROCEDURES "
end



//--------------------------------------------------------------------
//
function makeKinESimCtrl() // : Panel
	if (WinType("KinESimCtrl") == 7)
		DoWindow/F KinESimCtrl
		return 0
	endif
	
	variable v;
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(0,0,1188,510) /N=KinESimCtrl as "Kin-E-Sim control panel"
	ModifyPanel fixedSize=1
	ShowTools/A
	Button InfoButton,pos={4,6},size={20,20},proc=KESInfoProc,title="\\K(0,12800,52224)\\f03\\F'Times'i"
	Button InfoButton,help={"About current version of analysis."},fSize=20
	Button InfoButton,fColor=(65535,65535,65535)
	Button InfoButton, userdata(KESVer)=cKESGUIVer
	Button simReload,pos={25,6},size={20,20},proc=simReloadProc,title="\\F'Wingdings 3'P"
	Button simReload,help={"Read and re-interpret content of the job wave. This overries all other settigns. Same as selecting the same wave job again."}
	Button makeCtrlTbl,pos={2,31},size={60,19},proc=makeCtrlTableProc,title="ctrl. table"
	
	PopupMenu logOpt, pos={65,31}, title="log",proc=LogProc,value="none;min;exp;full"
	PopupMenu logOpt, help={"Enable and select logging level."}	

	PopupMenu jobListWSelect,pos={50,5},size={167,21},bodyWidth=150,proc=jobListWProc,title="job"
	PopupMenu jobListWSelect,help={"This is the main job wave, which contains the list of options. This wave is updated when options on this dialog are changed. Manual changes to this wave outside of this panel are not reflected automatically."}
	PopupMenu jobListWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:1\")"

	PopupMenu jobParamWSelect,pos={231,5},size={187,21},bodyWidth=150,proc=jobParamWProc,title="sets =>"
	PopupMenu jobParamWSelect,help={"Numeric parameters of the job, including individual, kilo- and mega- sets."}
	PopupMenu jobParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"

	SetVariable jobFlagsEdit,pos={142,32},size={71,16},bodyWidth=45,proc=setJobFlagsEditProc,title="flags"
	SetVariable jobFlagsEdit,help={"Miscellenious flags that appy to entire simulaiton."}
	SetVariable jobFlagsEdit,limits={-inf,inf,0},value= _STR:"-"
	
	PopupMenu esimParamWSelect,pos={229,31},size={189,21},bodyWidth=150,proc=esimParamWProc,title="esim =>"
	PopupMenu esimParamWSelect,help={"Electrochemical parameters of the simulaiton. These values are found under \"simulation\" section."}
	PopupMenu esimParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"
	
	NewPanel/W=(425,0,975,90)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=0
	SetDrawLayer UserBack
	TitleBox simTitle,pos={0,0},size={96,14},title="simulation"
	TitleBox simTitle,help={"Electrochemical parameters of the sumulation."},frame=0
	TitleBox simTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC

	v=16;
	PopupMenu simWPrepFSelect,pos={40,v   },size={174,21},bodyWidth=150,proc=simWPrepFProc,title="prep"
	PopupMenu simWPrepFSelect,help={"Method that defines the waveform for electrochemical process; called before the sim to set up sim wave; required. This method should use parameters in \"Method settings\" section."}
	PopupMenu simWPrepFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simWSetupProto\" )"
	PopupMenu simWProcFSelect,pos={24,v+24},size={190,21},bodyWidth=150,proc=simWProcFProc,title="process"
	PopupMenu simWProcFSelect,help={"Method that processes results of individual sim after it is finsihed."}
	PopupMenu simWProcFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simWProcessProto\" )"
	PopupMenu simPlotBuildFSelect,pos={44,v+48},size={170,21},bodyWidth=150,proc=simPlotBuildFProc,title="plot"
	PopupMenu simPlotBuildFSelect,help={"Method that builds a plot to display desults of individual sim. Beware of large number fo plots that can be build in kilo- and mega-sets."}
	PopupMenu simPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simPlotBuildProto\" )"
	

	SetVariable simCommName,pos={234,v},size={116,16},bodyWidth=60,proc=simBaseNameEditProc,title="base name"
	SetVariable simCommName,help={"Base name of the simulation wave. Names of all output waves will start with this name. "}
	SetVariable simCommName,limits={1,inf,1},value= _STR:""
	SetVariable simNThrds,pos={236,v+24},size={109,16},bodyWidth=45,proc=simNThreadsEditProc,title="CPU threads"
	SetVariable simNThrds,help={"Number of threads to use in single sim. Any value other than 1 causes simulation set to be run sequentially in favor of sim multithreading."}
	SetVariable simNThrds,limits={1,inf,1},value= _STR:"-"
	Button simDoIt,pos={235,v+48},size={110,20},proc=simDoIt,title="do this sim"
	Button simDoIt,help={"Start individual simulation, either undi- or bi-direftional as selected. "}
	Button simDoIt,fStyle=1

	SetVariable simLayerThick,pos={364,v},size={88,16},bodyWidth=45,proc=simLayerThicknessEditProc,title="rel. layer"
	SetVariable simLayerThick,help={"Relative thickness of the solution per unit of volume. A 1L volume is 100x100x100 mm and a x0.01 layer is 1mm thick."}
	SetVariable simLayerThick,limits={0,inf,0},value= _STR:"-"
	PopupMenu simIsBiDir,pos={461,v},size={47,21},proc=simIsBiDirEditProc,title="Bi-dir"
	PopupMenu simIsBiDir,help={"Generate two simulations - in forward and reverse directions. Each particular prep function may interpret this flag differently.This option may override initial concentrations of components when set to Pool."}
	PopupMenu simIsBiDir,mode=2147483647,popvalue="",value= #"\"No;Yes;Pool\""
	PopupMenu simETRateMode,pos={369,v+24},size={165,21},bodyWidth=100,proc=simETRateModePopupProc,title="ET rate vs. E"
	PopupMenu simETRateMode,help={"Method for calculating effective rates of ET at imposed potential by either holding forward or reverse rate constant ot changing both rates equally."}
	PopupMenu simETRateMode,mode=2147483647,popvalue="",value= #"\"fix oxidation;symmetrical;fix reduction\""
	PopupMenu simLimRateMode,pos={373,v+48},size={161,21},bodyWidth=120,proc=simLimRateModePiopupProc,title="rate limit"
	PopupMenu simLimRateMode,help={"Mode of limiting the rate of electrochemical reaction. Any option other than none causes the sim to ignore lectrode binding.  "}
	PopupMenu simLimRateMode,mode=2147483647,popvalue="",value= #"\"no limit (full);limit both;lim, correct both;lim. fast, corr. slow; balanced corr.\""
	RenameWindow #,Sim
	SetActiveSubwindow ##
	
	
	NewPanel/W=(0,60,420,175)/FG=(FL,,,)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrTitle,pos={1,1},size={96,14},title=" integrator "
	TitleBox intgrTitle,help={"Integrator panel specifies the integration method for the system of differential equations that describe the reaction."}
	TitleBox intgrTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC

	NewPanel/W=(7,15,125,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrSolTitle,pos={1,1},size={116,14},title="RK limits in solution"
	TitleBox intgrSolTitle,help={"Limiting conditions for solution equilibria."},frame=0
	TitleBox intgrSolTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKiDrop,pos={19,16},size={87,16},bodyWidth=45,proc=simRKiDropMaxSol,title="i-th drop"
	SetVariable RKiDrop,help={"Maximal relative drop of population over any RK order."}
	SetVariable RKiDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKiRise,pos={24,35},size={82,16},bodyWidth=45,proc=simRKiRiseMaxSol,title="i-th rise"
	SetVariable RKiRise,help={"Maximal relative rise of population over any RK order."}
	SetVariable RKiRise,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullDrop,pos={13,54},size={93,16},bodyWidth=45,proc=simRKFullDropMaxSol,title="step drop"
	SetVariable RKFullDrop,help={"Maximal relative drop of population over the entire sim step."}
	SetVariable RKFullDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullRise,pos={18,73},size={88,16},bodyWidth=45,proc=simRKFullRiseMaxSol,title="step rise"
	SetVariable RKFullRise,help={"Maximal relative rise of population over the entire sim step."}
	SetVariable RKFullRise,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKSol
	SetActiveSubwindow ##
	NewPanel/W=(125,15,245,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrElclTitle,pos={1,1},size={118,14},title="RK limits on electr."
	TitleBox intgrElclTitle,help={"Limiting conditions for electrode equilibria."},frame=0
	TitleBox intgrElclTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKiDrop,pos={19,16},size={87,16},bodyWidth=45,proc=simRKiDropMaxElec,title="i-th drop"
	SetVariable RKiDrop,help={"Maximal relative drop of population over any RK order."}
	SetVariable RKiDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKiRise,pos={24,35},size={82,16},bodyWidth=45,proc=simRKiRiseMaxElec,title="i-th rise"
	SetVariable RKiRise,help={"Maximal relative rise of population over any RK order."}
	SetVariable RKiRise,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullDrop,pos={13,54},size={93,16},bodyWidth=45,proc=simRKFullDropMaxElec,title="step drop"
	SetVariable RKFullDrop,help={"Maximal relative drop of population over the entire sim step."}
	SetVariable RKFullDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullRise,pos={18,73},size={88,16},bodyWidth=45,proc=simRKFullRiseMaxElec,title="step rise"
	SetVariable RKFullRise,help={"Maximal relative rise of population over the entire sim step."}
	SetVariable RKFullRise,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKElec
	SetActiveSubwindow ##
	NewPanel/W=(245,15,415,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrTimeTitle,pos={1,1},size={168,14},title="RK timing changes"
	TitleBox intgrTimeTitle,help={"Handling of simulation timing on limiting conditions and step advance."}
	TitleBox intgrTimeTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKTimeDropX,pos={22,16},size={137,16},bodyWidth=45,proc=simRKTimeDropX,title="mult. on drop limit"
	SetVariable RKTimeDropX,help={"Reduciton of the simulation step on the population drop limit."}
	SetVariable RKTimeDropX,limits={0,inf,0},value= _STR:"-"

	SetVariable RKTimeRiseX,pos={27,35},size={132,16},bodyWidth=45,proc=simRKTimeRiseX,title="mult. on rise limit"
	SetVariable RKTimeRiseX,help={"Reduciton of the simulation step on the population rise limit."}
	SetVariable RKTimeRiseX,limits={0,inf,0},value= _STR:"-"


	SetVariable RKTimeDropOver,pos={12,54},size={147,16},bodyWidth=45,proc=simRKTimeDropOver,title="hold on limit"
	SetVariable RKTimeDropOver,help={"How many steps to hold timing following limit conditions before attemting to advance it."}
	SetVariable RKTimeDropOver,limits={0,inf,0},value= _STR:"-"

	SetVariable RKTimeNextX,pos={35,73},size={124,16},bodyWidth=45,proc=simRKTimeNextX,title="mult. next step"
	SetVariable RKTimeNextX,help={"Initial change in the duration of the subsequent step."}
	SetVariable RKTimeNextX,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKComm
	SetActiveSubwindow ##
	RenameWindow #,Integr
	SetActiveSubwindow ##
	
	NewPanel/W=(425,92,975,185)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox compTitle,pos={1,1},size={128,14},title=" Components "
	TitleBox compTitle,help={"Properies of chemical components for the simulation."}
	TitleBox compTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	PopupMenu compParamWSelect,pos={10,v},size={165,21},bodyWidth=150,proc=compParamWProc,title="=>"
	PopupMenu compParamWSelect,help={"Selection of wave describing components and their properties."}
	PopupMenu compParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:2,TEXT:0,WAVE:0\")"
	Button addCmpBtn,pos={178,v+2},size={36,17},proc=addCmpProc,title="+ C#"
	Button addCmpBtn,help={"Add a component."}
	Button delCmpBtn,pos={214,v+2},size={36,17},proc=delCmpProc,title="- C#"
	Button delCmpBtn,help={"Delete current component."}
	
	PopupMenu cmpSelect,pos={12,v+25},size={52,21},proc=cmpSelectProc,title="C #"
	PopupMenu cmpSelect,help={"Currently selected component, whose properties are displayed."}
	PopupMenu cmpSelect,mode=1,popvalue="-",value= #"\"-\""
	SetVariable cmpName,pos={65,v+23},size={95,20},bodyWidth=95,proc=cmpNameEditProc
	SetVariable cmpName,help={"Literal name of this component."},fSize=14,fStyle=1
	SetVariable cmpName,limits={1,inf,1},value= _STR:"-"
	SetVariable cmpFlags,pos={165,v+25},size={56,16},bodyWidth=30,proc=compFlagsEditProc,title="flags"
	SetVariable cmpFlags,help={"Simulation-depended flags for his component, such as whether it should be analyzed further. "}
	SetVariable cmpFlags,limits={0,inf,0},value= _STR:"-"
	
	PopupMenu cmpAliasThisState,pos={10,v+48},size={93,21},bodyWidth=50,proc=cmpAliasThisStateProc,title="alias this"
	PopupMenu cmpAliasThisState,help={"Enable aliasing for one of the redox states of current component."}
	PopupMenu cmpAliasThisState,mode=1,popvalue="none",value= #"cmpAliasThisState()"
	PopupMenu cmpAliasThatCmp,pos={115,v+48},size={124,21},bodyWidth=95,disable=0,proc=cmpAliasThatSelectProc,title="to C#"
	PopupMenu cmpAliasThatCmp,help={"Identify another comonent which is an alias to currently selected component."}
	PopupMenu cmpAliasThatCmp,mode=1,value= #"\"\""
	PopupMenu cmpAliasThatState,pos={242,v+48},size={45,21},bodyWidth=45,disable=0,proc=cmpAliasThatStateProc
	PopupMenu cmpAliasThatState,help={"The redox state of the alias component."}
	PopupMenu cmpAliasThatState,mode=1,popvalue="ox.",value= #"cmpAliasThatState()"

	
	SetVariable intOx,pos={261,v},size={79,16},bodyWidth=55,proc=compInitOxEditProc,title="[ox.]"
	SetVariable intOx,help={"Initial concentration of the oxidzed form of this component."}
	SetVariable intOx,limits={0,inf,0},value= _STR:"-"
	SetVariable intRd,pos={263,v+24},size={77,16},bodyWidth=55,proc=compInitRdEditProc,title="[rd.]"
	SetVariable intRd,help={"Initial concentration of the reduced form of this component."}
	SetVariable intRd,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpE,pos={354,v},size={62,16},bodyWidth=45,proc=compE0EditProc,title="E0"
	SetVariable cmpE,help={"Standard reduction potential of this component."}
	SetVariable cmpE,limits={-inf,inf,0},value= _STR:"-"
	SetVariable cmpN,pos={428,v},size={40,16},bodyWidth=30,proc=compNEditProc,title="n"
	SetVariable cmpN,help={"The number of electrons required for reduction/oxidation of this component. No electrochemistry (solution or electrode) is considered if it is zero."}
	SetVariable cmpN,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpA,pos={480,v},size={60,16},bodyWidth=30,proc=compAlphaEditProc,title="alpha"
	SetVariable cmpA,help={"Charge transfer coefficient for this component; No electrode chemistry is considered if it is zero."}
	SetVariable cmpA,limits={0,inf,0},value= _STR:"-"
	SetVariable cmp_k0,pos={348,v+24},size={84,16},bodyWidth=45,proc=compET_kEditProc,title="ET rate"
	SetVariable cmp_k0,help={"The rate of reduction/oxidation on the electrode at standard potential. Must be >0 for electrode chemistry to be considered."}
	SetVariable cmp_k0,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpLim_k,pos={335,v+48},size={85,16},bodyWidth=45,proc=compLimRateEditProc,title="lim. rate"
	SetVariable cmpLim_k,help={"The limiting rate of the electrode reaction.  Must be >0 and rate limit mode msut be set to use fast simulation. Overrides electrode binding."}
	SetVariable cmpLim_k,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpBindK,pos={447,v+24},size={93,16},bodyWidth=45,proc=compBindKEditProc,title="binding K"
	SetVariable cmpBindK,help={"Equilibrium constant for component binding to the electrode. Must be >0  to consider electrode chemistry."}
	SetVariable cmpBindK,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpOnRate,pos={436,v+48},size={104,16},bodyWidth=45,proc=compBindRateEditProc,title="binding rate"
	SetVariable cmpOnRate,help={"The rate of binding of component to the electrode. Must be >0  to consider electrode chemistry."}
	SetVariable cmpOnRate,limits={0,inf,0},value= _STR:"-"

	
	RenameWindow #,Comp
	SetActiveSubwindow ##
	NewPanel/W=(0,187,485,317)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox rxnsTitle,pos={1,1},size={128,14},title="General reactions"
	TitleBox rxnsTitle,help={"Description of general chemical equilibria in the solution. These reactions are defined by equilibrium constants. "}
	TitleBox rxnsTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	Button InfoButton,pos={3,v},size={18,18},proc=makeGRxnWaveProc,title="\\W560"
	Button InfoButton,help={"Create a new reactions set, which includes two shared waves (summary and thermodynamics wave) and a single empty stiochiometry wave. "}
	Button InfoButton,fSize=10,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu gRxnsParamWSelect,pos={24,v},size={165,21},bodyWidth=150,proc=gRxnsParamWProc,title="=>"
	PopupMenu gRxnsParamWSelect,help={"Selection of wave describing general reactions. This is a wave of wave references; first entry is the wave with a list of rates & Ks, other - wave with reaciton stoichiometries."}
	PopupMenu gRxnsParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,WAVE:1\")"
	
	Button tableInfo,pos={190,v+2},size={11,17},proc=GRxnsInfoProc ,title=" i "
	Button tableInfo,help={"Stoichiometry table: identify reactant (left) and product (right) components and number of equivalents of their reduced and oxidized forms involved in the reaction. Any section with amounts of Ox and Rd set at 0 is ignored."}
	Button tableInfo,labelBack=(0,0,0),frame=0,fStyle=1,fColor=(0,0,65535)

	PopupMenu rxnSelect,pos={5,v+24},size={55,21},proc=gRxnSelectProc,title="Rx#"
	PopupMenu rxnSelect,help={"Currently selected reaction, whose properties are displayed."}
	PopupMenu rxnSelect, mode=1,popvalue="-",value= #"\"-\""

	SetVariable rxnName,pos={70,v+22},size={90,16},bodyWidth=90,proc=rxnNameEditProc
	SetVariable rxnName,help={"Literal name of this reaction."}
	SetVariable rxnName,limits={1,inf,1},value= _STR:"-"

	SetVariable rxnWaveName,pos={55,v+44},size={105,21},bodyWidth=90,disable=2,title="w:"
	SetVariable rxnWaveName,help={"Name of wave for selected reaction."},fSize=12
	SetVariable rxnWaveName,limits={1,inf,1},value= _STR:"-"

	SetVariable tdWaveName,pos={75,v+66},size={120,16},bodyWidth=90,disable=2,title="thermo w"
	SetVariable tdWaveName,help={"Name of wave for thermodynamic parameters for all reactions."}
	SetVariable tdWaveName,fSize=12,limits={1,inf,1},value= _STR:"-",noedit= 1

	SetVariable rxn_K_eq,pos={54,v+88},size={63,16},bodyWidth=40,proc=gRxnKeqEditProc,title="Keq"
	SetVariable rxn_K_eq,help={"Equilibrium constant for this reaction."}
	SetVariable rxn_K_eq,limits={0,inf,0},value= _STR:"-"
	SetVariable rxn_k_fwd,pos={125,v+88},size={73,16},bodyWidth=40,proc=gRxnkfwdEditProc,title="k(fwd)"
	SetVariable rxn_k_fwd,help={"Forward rate for this reaction. Rate order is determined by the reaction stoichiometry. "}
	SetVariable rxn_k_fwd,limits={0,inf,0},value= _STR:"-"
	
	Button addRxnRowBtn,pos={164,v+22},size={36,18},proc=addRxnRowProc,title="+row"
	Button addRxnRowBtn,help={"Add row to this reaction."}
	Button delRxnRowBtn,pos={164,v+44},size={36,18},proc=delRxnRowProc,title="-row"
	Button delRxnRowBtn,help={"Delete current row in this reaction."}

	Button addRxnBtn,pos={5,v+48},size={35,20},proc=addGRxnProc,title="+ Rx"
	Button addRxnBtn,help={"Add a reaction."}
	Button delRxnBtn,pos={5,v+70},size={35,20},proc=delGRxnProc,title="- Rx"
	Button delRxnBtn,help={"Delet this reaction."}


	Edit/W=(200,5,475,120)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xED
	ModifyTable statsArea=34
	ModifyTable horizontalIndex=2
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,GRxns
	
	SetActiveSubwindow ##
	NewPanel/W=(490,187,975,317)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox eRxnsTitle,pos={1,1},size={128,14},title="E-chem reactions"
	TitleBox eRxnsTitle,help={"Description of electrochemical equilibria in the solution. These reactions are defined by E0 and n of components. "}
	TitleBox eRxnsTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	Button InfoButton,pos={3,v},size={18,18},proc=makeERxnWaveProc,title="\\W560"
	Button InfoButton,help={"Create a new reactions set, which includes two shared waves (summary and thermodynamics wave) and a single empty stiochiometry wave. "}
	Button InfoButton,fSize=10,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu eRxnsParamWSelect,pos={24,v},size={165,21},bodyWidth=150,proc=eRxnsParamWProc,title="=>"
	PopupMenu eRxnsParamWSelect,help={"Selection of wave describing echeml reactions. This is a wave of wave references; first entry is the wave with a list of rates, other - wave with reaciton stoichiometires."}
	PopupMenu eRxnsParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,WAVE:1\")"
	
	Button tableInfo,pos={190,v+2},size={11,17},proc=ERxnsInfoProc, title=" i "
	Button tableInfo,help={"Stoichiometry table: identify reactant (left) and product (right) components and number of equivalents of their reduced and oxidized forms involved in the reaction. Any section with amounts of Ox and Rd set at 0 is ignored."}
	Button tableInfo,labelBack=(0,0,0),frame=0,fStyle=1,fColor=(0,0,65535)

	PopupMenu rxnSelect,pos={5,v+24},size={55,21},proc=eRxnSelectProc,title="Rx#"
	PopupMenu rxnSelect,help={"Currently selected reaction, whose properties are displayed."}
	PopupMenu rxnSelect,mode=1,popvalue="-",value= #"\"-\""

	SetVariable rxnName,pos={70,v+22},size={90,21},bodyWidth=90,proc=eRxnNameEditProc
	SetVariable rxnName,help={"Literal name of this reaction."}
	SetVariable rxnName,limits={1,inf,1},value= _STR:"-"

	SetVariable rxnWaveName,pos={55,v+44},size={105,16},bodyWidth=90,disable=2,title="w:"
	SetVariable rxnWaveName,help={"Name of wave for selected reaction."},fSize=12
	SetVariable rxnWaveName,limits={1,inf,1},value= _STR:"-",noedit= 1

	SetVariable tdWaveName,pos={75,v+66},size={120,16},bodyWidth=90,disable=2,title="thermo w"
	SetVariable tdWaveName,help={"Name of wave for thermodynamic parameters for all reactions."}
	SetVariable tdWaveName,fSize=12,limits={1,inf,1},value= _STR:"-",noedit= 1


	SetVariable rxn_K_eq,pos={54,v+88},size={63,16},bodyWidth=40,disable=2,title="Keq"
	SetVariable rxn_K_eq,help={"Equilibrium constant for this reaction. This a read-only value for electrochemical reactions, which is calculated and updated during sim from E0 and n of components."}
	SetVariable rxn_K_eq,limits={0,inf,0},value= _STR:"-"
	SetVariable rxn_k_fwd,pos={125,v+88},size={73,16},bodyWidth=40,proc=eRxnkfwdEditProc,title="k(fwd)"
	SetVariable rxn_k_fwd,help={"Forward rate for this reaction. Rate order is determined by the reaction stoichiometry."}
	SetVariable rxn_k_fwd,limits={0,inf,0},value= _STR:"-"

	Button addRxnRowBtn,pos={164,v+22},size={36,18},proc=addRxnRowProc,title="+row"
	Button addRxnRowBtn,help={"Add row to this reaction."}
	Button delRxnRowBtn,pos={164,v+44},size={36,18},proc=delRxnRowProc,title="-row"
	Button delRxnRowBtn,help={"Delete current row in this reaction."}
	Button addRxnBtn,pos={5,v+48},size={35,20},proc=addERxnProc,title="+ Rx"
	Button addRxnBtn,help={"Add a reaction."}
	Button delRxnBtn,pos={5,v+70},size={35,20},proc=delERxnProc,title="- Rx"
	Button delRxnBtn,help={"Delet this reaction."}

	Edit/W=(200,5,475,120)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xED
	ModifyTable statsArea=34
	ModifyTable horizontalIndex=2
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,ERxns
	SetActiveSubwindow ##
	
	
	NewPanel/W=(975,0,1185,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox methodTitle,pos={1,1},size={120,14},title="Method settings"
	TitleBox methodTitle,help={"Section describing parameters of a particular method. "}
	TitleBox methodTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu methodParamWSelect,pos={28,16},size={165,21},bodyWidth=150,proc=methodParamWProc,title="=>"
	PopupMenu methodParamWSelect,help={"Numerical wave describing inividual method parameters. Use row dimension labels to idenitify the meaning of parameters. Any user function have access to them, but the number and meaning of parameters is not managed."}
	PopupMenu methodParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"
	Edit/W=(5,39,205,503)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xE9
	ModifyTable statsArea=85
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,Method
	SetActiveSubwindow ##
	
	
	NewPanel/W=(0,320,325,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox setTitle,pos={1,1},size={64,14},title=" sim. set "
	TitleBox setTitle,help={"Parameters of a 1D set of simulaitons."},frame=0
	TitleBox setTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	PopupMenu setInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=setInSetupFProc,title="in setup"
	PopupMenu setInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu setInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setInputSetupProto\" )"
	PopupMenu setInAssignFSelect,pos={17,v+24},size={194,21},bodyWidth=150,proc=setInAssignFProc,title="in assign"
	PopupMenu setInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu setInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setInputAssignProto\" )"
	PopupMenu setOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=setOutSetupFProc,title="out setup"
	PopupMenu setOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu setOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu setOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=setOutAssignFProc,title="out assign"
	PopupMenu setOutAssignFSelect,help={"Method that processes and saves results of individual simulations in this set."}
	PopupMenu setOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultAssignProto\" )"
	PopupMenu setOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=setOutCleanupFProc,title="cleanup"
	PopupMenu setOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu setOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultCleanupProto\" )"
	PopupMenu setPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=setPlotSetupFProc,title="plot setup"
	PopupMenu setPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu setPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu setPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=setPlotAppendFProc,title="append"
	PopupMenu setPlotAppendFSelect,help={"Method that appends results of an individual simulation to this set's plot."}
	PopupMenu setPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotAppendProto\" )"
	SetVariable setFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=setFromEditProc,title="from"
	SetVariable setFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable setFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable setToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=setToEditProc,title="to"
	SetVariable setToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable setToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable setStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=setStepsEditProc,title="steps"
	SetVariable setStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable setStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable setVarCmpNo,pos={228,v+61},size={86,16},bodyWidth=45,proc=setVarCmpNoEditProc,title="vary C#"
	SetVariable setVarCmpNo,help={"Optional set parameter #1."},value= _STR:"-"
	SetVariable setPlotCmpNo,pos={231,v+81},size={83,16},bodyWidth=45,proc=setPlotCmpNoEditProc,title="plot C#"
	SetVariable setPlotCmpNo,help={"Optional set parameter #2."},value= _STR:"-"
	SetVariable setNThrds,pos={225,v+122},size={89,16},bodyWidth=45,proc=setNThreadsEditProc,title="CPU thr."
	SetVariable setNThrds,help={"Number of threads to use for this set. This value is effective only if individual simulations are performed in a single-threaded mode."}
	SetVariable setNThrds,limits={1,inf,1},value= _STR:"-"
	Button setDoIt,pos={220,v+142},size={90,22},proc=setDoIt,title="do single set"
	Button setDoIt,help={"Start a set of individual simulations. "},fStyle=1
	RenameWindow #,Set
	SetActiveSubwindow ##
	NewPanel/W=(325,320,650,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox kiloTitle,pos={1,1},size={64,13},title=" kilo set "
	TitleBox kiloTitle,help={"Parameters of a 2D kilo-set of simulaitons."},frame=0
	TitleBox kiloTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu kiloInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=kiloInSetupFProc,title="in setup"
	PopupMenu kiloInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu kiloInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputSetupProto\" )"
	PopupMenu kiloInAssignFSelect,pos={16,v+24},size={194,21},bodyWidth=150,proc=kiloInAssignFProc,title="in assign"
	PopupMenu kiloInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu kiloInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputAssignProto\" )"
	PopupMenu kiloOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=kiloOutSetupFProc,title="out setup"
	PopupMenu kiloOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu kiloOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu kiloOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=kiloOutAssignFProc,title="out assign"
	PopupMenu kiloOutAssignFSelect,help={"Method that processes and saves results of individual sets in this kilo-set."}
	PopupMenu kiloOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultAssignProto\" )"
	PopupMenu kiloOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=kiloOutCleanupFProc,title="cleanup"
	PopupMenu kiloOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu kiloOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultCleanupProto\" )"
	PopupMenu kiloPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=kiloPlotSetupFProc,title="plot setup"
	PopupMenu kiloPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu kiloPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu kiloPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=kiloPlotAppendFProc,title="append"
	PopupMenu kiloPlotAppendFSelect,help={"Method that appends results of an individual set to this kilo-set's plot"}
	PopupMenu kiloPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupPlotAppendProto\" )"
	SetVariable kiloFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=kiloFromEditProc,title="from"
	SetVariable kiloFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable kiloFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=kiloToEditProc,title="to"
	SetVariable kiloToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable kiloToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=kiloStepsEditProc,title="steps"
	SetVariable kiloStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable kiloStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable kiloParam1Edit,pos={226,v+61},size={87,16},bodyWidth=45,proc=kiloParam1EditProc,title="param 1"
	SetVariable kiloParam1Edit,help={"Optional set parameter #1."}
	SetVariable kiloParam1Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloParam2Edit,pos={226,v+81},size={87,16},bodyWidth=45,proc=kiloParam2EditProc,title="param 2"
	SetVariable kiloParam2Edit,help={"Optional set parameter #2."}
	SetVariable kiloParam2Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloFlagsEdit,pos={242,v+101},size={71,16},bodyWidth=45,proc=kiloFlagsEditProc,title="flags"
	SetVariable kiloFlagsEdit,help={"Simulation-depended flags for his set. The meaning of this flag varies between slelected setup and processing functions."}
	SetVariable kiloFlagsEdit,limits={1,inf,1},value= _STR:"-"
	Button kiloDoIt,pos={220,v+142},size={90,22},proc=kiloDoIt,title="do kilo set"
	Button kiloDoIt,help={"Start a kilo-set of simulation sets. "},fStyle=1
	RenameWindow #,Kilo
	SetActiveSubwindow ##
	NewPanel/W=(650,320,975,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox megaTitle,pos={0,0},size={64,13},title=" mega set "
	TitleBox megaTitle,help={"Parameters of a 3D mega-set of simulaitons."},frame=0
	TitleBox megaTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu megaInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=megaInSetupFProc,title="in setup"
	PopupMenu megaInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu megaInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputSetupProto\" )"
	PopupMenu megaInAssignFSelect,pos={16,v+24},size={194,21},bodyWidth=150,proc=megaInAssignFProc,title="in assign"
	PopupMenu megaInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu megaInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputAssignProto\" )"
	PopupMenu megaOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=megaOutSetupFProc,title="out setup"
	PopupMenu megaOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu megaOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu megaOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=megaOutAssignFProc,title="out assign"
	PopupMenu megaOutAssignFSelect,help={"Method that processes and saves results of individual kilo-sets in this mega-set."}
	PopupMenu megaOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultAssignProto\" )"
	PopupMenu megaOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=megaOutCleanupFProc,title="cleanup"
	PopupMenu megaOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu megaOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultCleanupProto\" )"
	PopupMenu megaPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=megaPlotSetupFProc,title="plot setup"
	PopupMenu megaPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu megaPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu megaPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=megaPlotAppendFProc,title="append"
	PopupMenu megaPlotAppendFSelect,help={"Method that appends results of an individual kilo-set to this mega-set's plot"}
	PopupMenu megaPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupPlotAppendProto\" )"
	SetVariable megaFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=megaFromEditProc,title="from"
	SetVariable megaFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable megaFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=megaToEditProc,title="to"
	SetVariable megaToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable megaToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=megaStepsEditProc,title="steps"
	SetVariable megaStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable megaStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable megaParam1Edit,pos={227,v+61},size={87,16},bodyWidth=45,proc=megaParam1EditProc,title="param 1"
	SetVariable megaParam1Edit,help={"Optional set parameter #1."}
	SetVariable megaParam1Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaParam2Edit,pos={227,v+81},size={87,16},bodyWidth=45,proc=megaParam2EditProc,title="param 2"
	SetVariable megaParam2Edit,help={"Optional set parameter #2."}
	SetVariable megaParam2Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaFlagsEdit,pos={243,v+101},size={71,16},bodyWidth=45,proc=megaFlagsEditProc,title="flags"
	SetVariable megaFlagsEdit,help={"Simulation-depended flags for his set. The meaning of this flag varies between slelected setup and processing functions."}
	SetVariable megaFlagsEdit,limits={1,inf,1},value= _STR:"-"
	Button megaDoIt,pos={220,v+142},size={90,22},proc=megaDoIt,title="do mega set"
	Button megaDoIt,help={"Start a mega-set of simulation kilo-sets. "},fStyle=1
	RenameWindow #,Mega
	SetActiveSubwindow ##
EndMacro



//--------------------------------------------------------------------
//
Function KESInfoProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
			NewPanel /W=(250,200,615,294)  /N=KESAbout as "About KES"
			SetDrawEnv fsize= 14
			DrawText 22,33,"Kin-E-Sim kinetic simulator."
			SetDrawEnv fsize= 14
			DrawText 10,60,"GUI "+cKESGUIVer
			SetDrawEnv fsize= 14
			DrawText 130,60,"Sets "+cKESSetsVer
			SetDrawEnv fsize= 14
			DrawText 250,60,"Core "+KES#getCoreVer()
			// get current status
			execute "SetIgorOption IndependentModuleDev=?"
			NVAR status = V_flag
			CheckBox IMDevelopButton title="Enable IM development",pos={10,67}, value=status, proc=setIMDevelop		
			Button CloseButton,pos={290,67},size={50,20},proc=KESAboutCloseProc,title="Close"
			// click code here
			PauseForUser KESAbout
	endif 
	return 0
End

//--------------------------------------------------------------------
//

Function KESAboutCloseProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode ==  2) // mouse up
			DoWindow /K KESAbout
	endif 
	return 0
End

//--------------------------------------------------------------------
//

Function setIMDevelop(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			execute "SetIgorOption IndependentModuleDev="+num2str(cba.checked);
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
Function simETRateModePopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 2, -2)
End

//--------------------------------------------------------------------
//
Function simLimRateModePiopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 3, -1)
End

//--------------------------------------------------------------------
//
Function rxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End



//--------------------------------------------------------------------
//
Function ERxnsInfoProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string ctrlName = "eRxnsParamWSelect"
			ControlInfo /W=$(ba.win) $ctrlName
			
			wave rxnsParamW = $S_Value;
			
			RxnInfoTable(ba.win, rxnsParamW, "EChem reactions")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
Function GRxnsInfoProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string ctrlName = "gRxnsParamWSelect"
			ControlInfo /W=$(ba.win) $ctrlName
			
			wave rxnsParamW = $S_Value;
			
			RxnInfoTable(ba.win, rxnsParamW, "General reactions")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



//--------------------------------------------------------------------
//
Function RxnsInfoDoneProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DoWindow /K $ba.win
			KillWaves /Z $"RxnsInfoListW"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




//--------------------------------------------------------------------
//
// after simIsBiDirEditProc
Function rxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//
// after compE0EditProc
Function rxnKeqEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtOffset = 0;
	variable refOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refOffset, tgtOffset,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 
	

//--------------------------------------------------------------------
//
Function rxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//

Function cmpSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable curval = pa.popnum - 1
	setCmpVals(pa.win, curval);
End



//--------------------------------------------------------------------
//
Function compInitRdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 1, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compInitOxEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 0, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compE0EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 2,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compNEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 3,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compAlphaEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 5,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compET_kEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 4,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compLimRateEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 8, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compBindKEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 10, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compBindRateEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 11,  ctrlSelectorPos(sva.win, "cmpSelect"))
End



//--------------------------------------------------------------------
//
Function addRxnRowProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string tblName = ba.win+"#Tbl"
	GetSelection table, $tblName, 1
	variable theRow = V_startRow;
	
	wave theWave = WaveRefIndexed(tblName, 0, 3)
	if (waveexists(theWave))
		insertpoints /M=0 theRow, 1, theWave
	endif  
	
	return 0
End

//--------------------------------------------------------------------
//
Function delRxnRowProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string tblName = ba.win+"#Tbl"
	GetSelection table, $tblName, 1
	variable theRow = V_startRow;
	
	wave theWave = WaveRefIndexed(tblName, 0, 3)
	if (waveexists(theWave))
		deletepoints /M=0 theRow, 1, theWave
	endif  

	return 0
End

//--------------------------------------------------------------------
//

Function rxnNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(sva.win, "rxnSelect")
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			string thisName = sva.sVal				
			SetDimLabel 0,currRxn, $sva.sVal, rxParamsW
		endif 
	endif 	
End

//--------------------------------------------------------------------
//
Function addCmpProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(ba.win, "cmpSelect")
		insertpoints /M=1 currCmp+1, 1, cmpParamW
		simReloadCompParamPanel(ba.win, cmpParamW, setCmpNo =currCmp+1 )
	endif  
	
	return 0
End

//--------------------------------------------------------------------
//
Function delCmpProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(ba.win, "cmpSelect")
		deletepoints /M=1 currCmp, 1, cmpParamW
		if (currCmp >= dimsize(cmpParamW, 1))
			currCmp =  dimsize(cmpParamW, 1) -1;
		endif 
		simReloadCompParamPanel(ba.win, cmpParamW, setCmpNo =currCmp )
	endif  

	return 0
End

//--------------------------------------------------------------------
//
Function cmpNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(sva.win, "cmpSelect")
		string thisName = sva.sVal				
		SetDimLabel 1,currCmp, $sva.sVal, cmpParamW
	endif 	
End


//--------------------------------------------------------------------
//

Function compFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 6, ctrlSelectorPos(sva.win, "cmpSelect"))
End


//--------------------------------------------------------------------
//

Function gRxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//

Function addGRxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	addRxnProc(ba.win, "gRxnsParamWSelect", "GRxn")
	return 0
End

//--------------------------------------------------------------------
//
Function gRxnKeqEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtOffset = 0;
	variable refOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refOffset, tgtOffset,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function gRxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function eRxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 5) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function eRxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//
Function eRxnNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(sva.win, "rxnSelect")
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			string thisName = sva.sVal				
			SetDimLabel 0,currRxn, $sva.sVal, rxParamsW
		endif 
	endif 	
End

//--------------------------------------------------------------------
//
Function addERxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	addRxnProc(ba.win, "eRxnsParamWSelect", "ERxn")
	return 0
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;
	
	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		variable newRxIndex = currRxn+2;
		
		InsertPoints /M=0 newRxIndex, 1, rxnsParamW;
		variable i
		for (i=0; i<99; i+=1)
			string rxWName
			sprintf  rxWName "Rxn%02d", i
			if (!waveexists($rxWName))
				make /N=(1, 6) $rxWName
				rxnsParamW[newRxIndex] = $rxWName
				break;
			endif 
		endfor
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			InsertPoints /M=0 currRxn+1, 1, rxParamsW;
			rxParamsW[currRxn+1][] = 0;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn+1)		
	endif 
	
	return 0
End

//--------------------------------------------------------------------
//
Function delERxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		
		DeletePoints /M=0 currRxn+1, 1, rxnsParamW;
		
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			DeletePoints /M=0 currRxn, 1, rxParamsW;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn)		
	endif 	

	return 0
End

//--------------------------------------------------------------------
//
Function eRxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="eRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "eRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function gRxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 6) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function jobParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 1) ;

	if ( pa.eventCode == 2)  // mouse up
		simReloadJParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function esimParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 3) ;

	if ( pa.eventCode == 2)  // mouse up
		 simReloadESimParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function compParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 4) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadCompParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function methodParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 2) ;
	if ( pa.eventCode == 2)  // mouse up
		simReloadMethodParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeCtrlTableProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
			ControlInfo /W=$(StringFromList(0,ba.win,"#")) $"jobListWSelect"
			wave /T jobListW = $S_Value;
		
		SimCtrlTable(jobListW)
	endif 
	return 0
end


//--------------------------------------------------------------------
//
Function simWPrepFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "esimParamWSelect", 1);  
end 

//--------------------------------------------------------------------
//
Function simWProcFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 8);  
end 

//--------------------------------------------------------------------
//
Function simPlotBuildFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 9);  
end 


//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Set
//--------------------------------------------------------------------
//
Function setInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 11);  
end 

//--------------------------------------------------------------------
//
Function setInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 12);  
end 

//--------------------------------------------------------------------
//
Function setOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 13);  
end 

//--------------------------------------------------------------------
//
Function setOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 14);  
end 

//--------------------------------------------------------------------
//
Function setOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 15);  
end 

//--------------------------------------------------------------------
//
Function setPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 16);  
end 

//--------------------------------------------------------------------
//
Function setPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 17);  
end 

//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Kilo
//--------------------------------------------------------------------
//
Function kiloInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 20);  
end 

//--------------------------------------------------------------------
//
Function kiloInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 21);  
end 

//--------------------------------------------------------------------
//
Function kiloOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 22);  
end 

//--------------------------------------------------------------------
//
Function kiloOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 23);  
end 

//--------------------------------------------------------------------
//
Function kiloOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 24);  
end 

//--------------------------------------------------------------------
//
Function kiloPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 25);  
end 

//--------------------------------------------------------------------
//
Function kiloPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 26);  
end 


//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Mega
//--------------------------------------------------------------------
//
Function megaInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 29);  
end 

//--------------------------------------------------------------------
//
Function megaInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 30);  
end 

//--------------------------------------------------------------------
//
Function megaOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 31);  
end 

//--------------------------------------------------------------------
//
Function megaOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 32);  
end 

//--------------------------------------------------------------------
//
Function megaOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 33);  
end 

//--------------------------------------------------------------------
//
Function megaPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 34);  
end 

//--------------------------------------------------------------------
//
Function megaPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 35);  
end 



//----------------------------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------------------------
//
// job set service
//
//--------------------------------------------------------------------
//

Function setJobFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 0)
End

//--------------------------------------------------------------------
//
Function setFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 2)
End

//--------------------------------------------------------------------
//
Function setToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 3)
End

//--------------------------------------------------------------------
//
Function setStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 4)
End
//--------------------------------------------------------------------
//
Function setVarCmpNoEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 6)
End

//--------------------------------------------------------------------
//
Function setIsBiDirEditProc_old(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 1)
End

//--------------------------------------------------------------------
//
Function simIsBiDirEditProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 1, -1)
End


//--------------------------------------------------------------------
//
Function setPlotCmpNoEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 8)
End

//--------------------------------------------------------------------
//
Function setNThreadsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 1)
End

//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function kiloFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 10)
End

//--------------------------------------------------------------------
//
Function kiloToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 11)
End

//--------------------------------------------------------------------
//
Function kiloStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 12)
End

//--------------------------------------------------------------------
//
Function kiloParam1EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 14)
End

//--------------------------------------------------------------------
//
Function kiloParam2EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 15)
End

//--------------------------------------------------------------------
//
Function kiloFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 16)
End

//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function megaFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 19)
End

//--------------------------------------------------------------------
//
Function megaToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 20)
End

//--------------------------------------------------------------------
//
Function megaStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 21)
End
//--------------------------------------------------------------------
//
Function megaParam1EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 23)
End

//--------------------------------------------------------------------
//
Function megaParam2EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 24)
End

//--------------------------------------------------------------------
//
Function megaFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 25)
End


//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//

Function simReloadProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			simReloadPanelJob(ba.win, "jobListWSelect")			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End





//----------------------------------------------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------
//


Function simNThreadsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 0)
End


//--------------------------------------------------------------------
//
Function simLayerThicknessEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 10)
End

//--------------------------------------------------------------------
//
Function simRKiDropMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 5)
End

//--------------------------------------------------------------------
//
Function simRKiRiseMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 6)
End

//--------------------------------------------------------------------
//
Function simRKFullDropMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 7)
End

//--------------------------------------------------------------------
//
Function simRKFullRiseMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 8)
End



//--------------------------------------------------------------------
//
Function simRKiDropMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 11)
End

//--------------------------------------------------------------------
//
Function simRKiRiseMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 12)
End

//--------------------------------------------------------------------
//
Function simRKFullDropMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 13)
End

//--------------------------------------------------------------------
//
Function simRKFullRiseMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 14)
End

//--------------------------------------------------------------------
//
Function simRKTimeDropX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 17)
End

//--------------------------------------------------------------------
//
Function simRKTimeRiseX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 18)
End

//--------------------------------------------------------------------
//
Function simRKTimeNextX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 20)
End

//--------------------------------------------------------------------
//
Function simRKTimeDropOver(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 16)
End

//--------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function jobListWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if ( pa.eventCode == 2)  // mouse up
		wave /T jListW = $pa.popStr;
		simReloadJob(pa.win, jListW)
	endif 
	return 0
End

//--------------------------------------------------------------------
//

Function simBaseNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByStr(sva, "jobListWSelect" , 0)
End




//----------------------------------------------------------------------------------------------------------------------------------------
//

//--------------------------------------------------------------------
//
Function simDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		wave /T jobW;
		if (getJobWave(ba.win, jobW))
			Set_MedEChem(jobW, doSingle = 1)
		endif;
	endif
	return 0
End
//--------------------------------------------------------------------
//
Function setDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		wave /T jobW;
		if (getJobWave(ba.win, jobW))
			Set_MedEChem(jobW)
		endif;
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function kiloDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		wave /T jobW;
		if (getJobWave(ba.win, jobW))
			Kilo_MedEChem05(jobW);
		endif;
	
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function megaDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		wave /T jobW;
		if (getJobWave(ba.win, jobW))
			Mega_MedEChem05(jobW);
		endif;

	endif
	return 0
End


//--------------------------------------------------------------------
//
Function simStopThreadsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Abort
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeGRxnWaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
		makeRxnWave(ba.win, "GRxn", "gRxnsParamWSelect", "jobListWSelect", 6)
	endif 
	return 0
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeERxnWaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
		makeRxnWave(ba.win, "ERxn", "eRxnsParamWSelect", "jobListWSelect", 5)
	endif 
	return 0
End






//--------------------------------------------------------------------
//
Function cmpAliasThisStateProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable currState = pa.popnum-1;
	variable aliasState =  ctrlSelectorPos(pa.win, "cmpAliasThatState")
	variable aliasCmp =  ctrlSelectorPos(pa.win, "cmpAliasThatCmp")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)
	
End




//--------------------------------------------------------------------
//
Function cmpAliasThatStateProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable aliasState = pa.popnum-1 
	variable currState =  ctrlSelectorPos(pa.win, "cmpAliasThisState")
	variable aliasCmp =  ctrlSelectorPos(pa.win, "cmpAliasThatCmp")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)
End





//--------------------------------------------------------------------
//
Function cmpAliasThatSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable aliasCmp = pa.popnum-1
	variable currState =  ctrlSelectorPos(pa.win, "cmpAliasThisState")
	variable aliasState =  ctrlSelectorPos(pa.win, "cmpAliasThatState")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)

End

//--------------------------------------------------------------------
//

Function LogProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			wave /T jobW;
			if (getJobWave(pa.win, jobW))
				//wave PSet_MedEChem(jobW, doSingle = 1)
				wave PWave = $jobW[3];
				PWave[4] = popNum -1;
			endif;

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

