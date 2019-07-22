Return to the [readme](https://github.com/dap-biospec/KinESim/blob/master/readme.md)

See the [manual](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_manual.md)
## Structure
The main procedure file (KineSim.ipf) includes several dependencies on separate untis:
- Core: the main simulation engine. It is implemented as a independent module using namespace KES. Includes:
	- KES_Core.ipf
		- KES_Core_Aliases.ipf
		- KES_Core_Flow.ipf
		- KES_Core_Integrator.ipf
		- KES_Core_Log.ipf
		- KES_Core_Struct.ipf
	
- Sets: handles preparation and processing of individual simulations as well as one-, two-, and three-dimensional sets of simulations. It is implemented as a named module KES_Sets. Sets hands simulations off to KES core, which is required. Includes:
	- KES_Sets.ipf
		- KES_Sets_Aux.ipf
		- KES_Sets_Flow.ipf
		- KES_Sets_Progress.ipf
		- KES_Sets_Proxy.ipf
		- KES_Sets_Struct.ipf
		
- GUI: implements user interface for preparation of simulations. It is implemented as a named module KES_GUI. GUI executes functions in Sets, which reqiured. Includes:
	- KES_GUI.ipf
		- KES_GUI_Aux.ipf
		- KES_GUI_Comp.ipf
		- KES_GUI_Rxns.ipf
		
Upon loading, only KineSim.ipf is visible in the list of procedure files to keep user workspace clean. Visibility of all loaded units can be enabled using "SetIgorOption IndependentModuleDev=1" command or from the information panel in GUI as described in the [manual](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_manual.md).

## API

### Contents

#### [KES_Core](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_API.md#KES_Core)

#### [KES_Sets](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_API.md#KES_Sets)

#### [KES_GUI](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_API.md#KES_GUI)

#### [Data Structures](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_API.md#Data_Structures)

### KES_Core
#### threadsafe function `Sim_Core_Seq(SWave, CWave, PWave, ERxnsW, GRxnsW, RxnsTmp, OWave, idx, LogWave, logMode)
- Description: 
- Input:
	- `WAVE /T SWave`: 
	- `WAVE /T CWave`: name of the components wave
	- `WAVE /T PWave`: name of the parameters wave
	- `WAVE /WAVE GRxnsW`: name of the GRxns wave
	- `WAVE /WAVE ERxnsW`: name of the ERxns wave
	- `WAVE RxnsTmp`: 
	- `WAVE OWave`:
	- `variable idx`: The row in which data is reported. Default start value is 0. 
	- `WAVE LogWave`:
	- `variable logMode`: 
- Output: None

#### function `Sim_Core_Prl(simData, OWave, idx, nMT, hostPrg)
- Description:
- Input:
	- `STRUCT simDataT simData`:
	- `WAVE OWave`:
	- `variable idx`: The row in which data is reported. Default start value is 0.
	- `variable nMT`: 
	- `STRUCT SetProgDataT hostPRG`: 
- Output: None



### KES_Sets
#### function `Set_MedEChem(jobW, doSingle=int)`
- Description: Performs a simulation set or single simulation. Equivalent to pressing the `do single set` or `do this sim` buttons on the KinESim `Control Panel`.
- Input:
	- `Wave /T jobW`: name of the text job wave. Name is set by the user.
	- `Variable doSingle=int`: Determines if the program should perform a single simulation (`do this sim`) or a simulation set (`do single set`). Int` = `1` (true) or `Int` = `0` (false).
	- Example: `Set_MedEchem(NPVJob, doSingle=1)`
		- This command would perform a single simulation (`doSingle=1`) using the parameters given by the `NPVJob` wave.
		- Return: none
		- History report: Output folder location. Simulation time and number of steps performed.

#### function `Kilo_MedEChem05(jobW)`
- Description: Performs a simulation kilo set. Equivalent to pressing the `do kilo set` button on the KinESim `Control Panel`.
- Input:
	- `WAVE /T jobW`: name of the text job wave. Name is set by the user.
	- Example: `Kilo_MedEChem05(NPVJob)`
- Return: none
- History report: Output folder location. Simulation time and number of steps performed.

#### function `Mega_MedEChem05(jobW)`
- Description: Performs a simulation mega set. Equivalent to pressing the `do mega set` button on the KinESim `Control Panel`.
- Input:
	- `WAVE /T jobW`: name of the text job wave. Name is set by the user.
	- Example: `Mega_MedEChem05(NPVJob)`
- Return: none
- History report: Output folder location. Simulation time and number of steps performed.

### Prototype functions for automated setup and processing:

***Individual simulations***

#### Threadsafe function `simWSetupProto(SetData, SimData)`
- Description: prepare method waveform
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simDataT SetData`: data structure for a single simulation.
- Return: none

#### Threadsafe function `simWProcessProto(ResultWNSuffix, SimData)`
- Description: prepare method waveform
- Input:
	- `ResultWNSuffix`: name suffix for processed waves; based off simulation set name.
	- `STRUCT simDataT SetData`: data structure for a single simulation.
- Return: `WAVE` IWave: processed data

#### function `simPlotBuildProto(plotNamesS, SimData, SetData)`
- Description: build or update results plot
- Input:
	- String `plotNameS`: Name assigned to the plot.
	- `STRUCT simDataT SetData`: data structure for a single simulation.
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
- Return: none

***Sets of simulations***
#### Threadsafe function `setInputProto(setData, setEntries)`
- Description: set up the set, for example prepare calibration of a variable parameter
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simSetDataArrT SetEntries`: array of data structures for individual simulations.
- Return: string error; null/empty string or description error

#### Threadsafe function `setInputProto(setData, setEntries)`
- Description: perform parameter assignment for current simulation that follows
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simSetDataArrT SetEntries`: array of data structures for individual simulations.
- Return: none

#### function `setResultSetupProto(setData, setEntries)`
- Description: prepare output structures to save results of the set
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simSetDataArrT SetEntries`: array of data structures for individual simulations.
- Return: none

#### Threadsafe function `setResultAssignProto(setData, simData)`
- Description: save results of the simulation that was just executed
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simDataT SimData`: data structure for a single simulation
- Return: none

#### function `setResultCleanupProto(setData, setEntries, setResultWN)`
- Description: final cleanup after set is completed
- Input:
	- `STRUCT` `simSetDataT` `SetData`: data structure for a simulation set.
	- `STRUCT` `simSetDataArrT` `SetEntries`: array of data structures for individual simulations.
	- `string setResultWN`: common name for the set
- Return: none

#### function `setPlotSetupProto(setData, plotNameS)`
- Description: initial preparation of the plot to display set results
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `string plotNameS`: name of the plot to build
- Return: none

#### function `setPlotAppendProto(setData, setEntries, plotNameS, iteration)`
- Description: append results of just completed simulation to the plot
- Input:
	- `STRUCT simSetDataT SetData`: data structure for a simulation set.
	- `STRUCT simSetDataArrT SetEntries`: array of data structures for individual simulations.
	- `string plotNameS`: name of the plot window
	- `variable iteration`: index of this iteration in the set
- Return: none

***Kilo and Mega groups of simulations***
#### Threadsafe function `groupInputSetupProto(setData, groupEntries)`
- Description: set up the set, for example prepare calibration of a variable parameter
- Input: in setup (kilo set or mega set subsection)
	- `STRUCT simSetDataT setData`: data structure for a simulation set
	- `STRUCT simSetDataArrT groupEntries`: array of data structures for individual simulations
- Return: None

#### Threadsafe function `groupInputAssignProto(setData, groupEntries)`
- Description: perform parameter assignment for current simulation  that follows
- Input:
	- `STRUCT simSetDataT setData`: data structure for a simulation set
	- `STRUCT simSetDataArrT groupEntries`: array of data structures for individual simulations
- Return: None

#### function `groupResultSetupProto(setData, groupEntries)`
- Description: prepare output structures to save results of the set 
- Input:
	- `STRUCT simSetDataT setData`: data structure for a simulation set.
	- `STRUCT simSetDataArrT groupEntries`: array of data structures for individual simulations
- Return: None

#### Threadsafe function `groupResultAssignProto(groupData, simData)`
- Description: save results of the sub-set  that was just executed
- Input:
	- `STRUCT simSetDataT groupData`: data structure for a simulation set 
	- `STRUCT simDataT SimData`: data structure for a single simulation
- Return: None

#### function `groupResultCleanupProto(setData, groupEntries, setResultWN)`
- Descrption: final cleanup after set is completed
- Input:
	- `STRUCT simSetDataT setData`: data structure for a simulation set
	- `STRUCT simSetDataArrT groupEntries`: array of data structures for individual simulations 
	- `string setResultWN`: common name foe the set
- Return: None

#### function `groupPlotSetupProto(setData, plotNameS)`
- Use setPlotSetupProto instead

#### function `groupPlotAppendProto(setData, groupEntries, plotNameS, iteration)` 
- Description: append results of just completed simulation subset to the plot
- Input:
	- `STRUCT simSetDataT setData`: data structure for a simulation set
	- `STRUCT simSetDataArrT groupEntries`: array of data structures for individual simulations
	- `String plotNameS`: name of the plot window
	- `variable iteration`: index of this iteration in the set
- Return: None



### KES_GUI
Most of GUI operation involves triggering of KES_Sets functions from the control panel.

#### function `SimCtrlTable(jobW)`
- Description: Used to open a table showing the names and contents of all parameter waves for the indicated job. Parameters can be edited directly from this table.
- Input:
	- `WAVE /T jobW`: name of the text job wave. Name is set by the user.
- Return: none

### Data Structures:
***This datafield describes a single simulation***
```structure simDataT
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
	variable group; // group index, this may a position in the set or may indicate index of plot etc...
	
	// output
	string text; // verbose report to be printed in the history
	variable result; // optional result 
	// output waves 					
	wave SWave; // simulation wave containing all components at all time points
	wave ProcSWave; // wave containing results of processing of SWave by a custom user function  
	variable misc; // flags for hosting function purposes
	variable stealth; // supress output if fucntion is hosted in multiple interation fit function, for example
endstructure
```

***a list of `simDataT` structures of given length***
```structure simSetDataArrT
	variable count;
	STRUCT simDataT sims[maxSims];
Endstructure
```

***This datafield describes a single sub-set***
```structure setDataT
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
```

***a list of `setDataT` structures of given length***
```structure setSetDataArrT
	variable count;
	STRUCT setDataT sets[maxSims];
Endstructure
```

***This datafield describes a group of sets***
```structure simSetDataT
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
```
