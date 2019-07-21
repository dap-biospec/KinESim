# KinESim
Igor procedures and examples for simulation of homogeneous and heterogeneous electrochemical reactions

Copyright © 2019, Denis A. Proshlyakov, dapro@chemistry.msu.edu

Kin-E-Sim is a set procedures for Igor Pro designed to predict the characteristic response of an analyte in various electrochemical methods, including normal pulsed voltammetry (illustrated below), cyclic voltammetry, etc. This document is intended to provide a new user the information they need to begin using the Kin-E-Sim program. See [citation] for further details on the implemented algorithms. 

Two versions of Kin-E-Sim are provided: `KES__complete.ipf` includes complete code in a single procedure file and is intended for end users.  `KES__Main.ipf` loads the same code which is split over several procedure files. It is intended for programmers who want to examine and revise the code.  Only one version can be loaded at a time. 

## Installation:
- Download `KES_complete.ipf` from the KES folder and `NPV_Illustration.ipf` and `Spectroechem.ipf` from the EChem folder. Store these files in the same folder in any location.  
- Open Igor Pro. Select `File` -> `Open File` -> `Procedure…`
- Locate the folder containing the necessary files. Select `KES_complete.ipf` and `Open`. 
- A window containing the procedure will appear within the Igor workspace. Close the window. A dialog box will appear. Select `Hide`. This will compile the procedure and hide the procedure from view. Selecting `Kill` will permenantly remove the procedure from the current Igor experiment.
- Repeat this step for `NPV_Illustrations.ipf` and `Spectroechem.ipf`.  
- Once Kin-E-Sim is loaded and compiled, it can be accessed by selecting `Analysis` -> `Kin-E-Sim` -> `Control Panel`. The `Control Panel` will appear.  
- Finally, select `Analysis` -> `Kin-E-Sim` -> `Create Set`. A dialog box will appear asking for a name. Any name can be entered here. Click `Continue`. All necessary waves will be generated.
- From the `Control Panel` select the job that you just named to load the waves into the `Control Panel`.

## Kin-E-Sim Demo
A demo with pre-loaded simulations is provided in the `KES_Demo.pxp` file. A description of each pre-loaded simulation and instructions on how to perform them are provided below. Kin-E-Sim simulations are performed using the `Control Panel`. Full details of the `Control Panel` are provided in the following section. 

- **Single analyte direct electrochemistry:** This simulation simulates normal pulsed voltammetry of a single analyte that undergoes direct electrochemistry on the electrode. As loaded, the analyte has a redox potential of -0.1 V. 
		 
- **Single analyte mediated electrochemistry:** This simulates NPV of a single analyte and mediator. The analyte is unable to perform any electron transfer on the electrode and is completely dependent on the mediator for redox transitions. As loaded, both the analyte and mediator have a redox potential of -0.1 V. The concentration of the analyte is 1 mM and the concentration of the mediator is 200 µM. 
- **Single analyte mediator with two redox transitions:** This simulation simulates NPV of a single analyte and mediator where the mediator has two distinct redox transitions. As loaded, the analyte has a redox potential of -0.1 V and the mediator has two redox potentials at 0.0 V and -0.2 V. The concentration of the analyte is 1 mM and concentration of the mediator is 200 µM total. 
>**Hint:** A single mediator with two distinct redox transitions is accomplished by making two separate components and connecting them using the `alias this` function. Each component must start with a concentration value greater than 0 and the sum of the two concentrations is the total concentration of the mediator.

### Performing a single simulation

- First, use the `Data Browser` (`Data` -> `Data Browser`) in Igor to select the folder with the title of the simulation you would like to run. This is done by clicking and dragging the red arrow to the desired experiment folder. Then click **[insert image]** in the top-left corner of the Kin-E-Sim `Control Panel`. The simulation should now be loaded containing all the pre-set commands and parameters.
 
- To run a single simulation using the specified parameters, press the `do this sim` button in the `simulation` sub-panel. Note that the name of the simulation can be changed using the `base name` text box found in the simulation panel. Each simulation must have a unique `base name`. A new window should appear that displays the amount of time needed for the simulation to complete. Once the simulation has completed, a graph will appear containing the potential profile and concentration profiles of each component present in the simulation. 

- After the simulation is completed for the first time, a new folder `SimData` will appear as a sub-folder of the selected simulation root folder and will contain Igor waves. The Igor wave with the same title as the simulation will contain all of the simulated data, including the applied potential and the concentration of each component in both the reduced and oxidized states for each time point.

### Performing a set of simulations
- The `sim. set` sub-panel of both pre-loaded simulations has been set up to perform three simulations where the redox potential of the analyte is varied between -0.2, -0.1, and 0.0 V. 

- First, use the `Data Browser` in Igor to select the folder with the title of the simulation you would like to run. Then click   in the top-left corner of the Kin-E-Sim `Control Panel`. The simulation should now be loaded containing all the pre-set commands and parameters.

- To perform a set of simulations, press the `do single set` button in the `sim. set` sub-panel. Once clicked, a window will appear showing the progress of the simulation.

- After the simulation is complete, a separate graph will be built for each simulation and will show the potential profile and concentration profiles of all components. A new folder `SimData` will appear as a sub-folder of the selected simulation root folder and will contain sets of Igor waves. Wave names will contain numerical suffixes that reflect the order in the set (ex. simname00, simname01, etc.). Format of output waves is the same as for a single simulation. 

- New waves will also appear in the main simulation folder
	- `simname_EappClb`: contains the list of applied potentials (no reference potentials included). 
	- `simname_SetClb`: reports the value of the varied variable (in this case, the redox potential of the analyte) for each simulation. 
	- `simname_OxC00_NPV`: contains the concentration of component 0 at each applied potential for all three experiments. This data can be transposed into a vertical column and plotted versus `simname_EappClb` to visualize the Nernstian profile. 

### Altering simulation parameters
Kin-E-Sim is a flexible framework that can simulate any experimental method that can be programmatically described. This is accomplished by passing a list of parameters (defined in Method Settings wave) to several template functions (simulation prep, process and plot). Users can write their own prep and process function or re-define any of parameters as long there is consistency between parameters and functions. Notice that for a function to be recognized by Kin-E-Sim, it must have exact same order and type of parameters as defined in the template or the example. 

### Altering reaction schemes
Kin-E-Sim was originally developed to simulate changes in homogeneous solution in response to applied potentials. However, it can simulate any combination of multiple reactions on the electrode, in the solution, or the mixture of two types of reactions. This includes branching, isomerization and multi-step reactions, that can be defined using component aliases. Method parameters and setup functions may be irrelevant for simulations involving homogenous reactions only. 

### Multi-threaded simulations
Kin-E-Sim is multithreaded (MT) simulation. This is accomplished differently depending on whether a single or multiple simulations are carries out. 
- Single simulation: multiple threads can be used for RK integration. Notice, however, that MT carries an overhead that my make parallel integration more time consuming than a single threaded. Compare results of using 0-1 cores vs 2+ cores on your particular computer. 
- Sets of simulations: 
	- If single simulation is set to a ST mode (nthreads < 2), simulations in the set will be carried out in parallel. This is the recommended mode.  
	- If single simulation is set to a MT mode (nthreads > 1), simulations in the set will be carried out sequentially. 

## Control Panel

