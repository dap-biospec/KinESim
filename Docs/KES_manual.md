Return to the [readme](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/readme.md)

See the [API](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/Docs/KES_API.md)

## Installation:
- Clone the git repository and open the KES/KinESim.ipf in IgorPro.  The necessary dependencies are included and are loaded by KinESim.ipf. See [API](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_API.md#Structure) for more details of file structure. 
	- Open Igor Pro. Select `File` -> `Open File` -> `Procedure…`
	- Locate the folder containing the necessary files. Select `KinESim.ipf` and `Open`. 
	- A window containing the procedure will appear within the Igor workspace. Close the window. A dialog box will appear. Select `Hide`. This will compile the procedure and hide the procedure from view. Selecting `Kill` will permenantly remove the procedure from the current Igor experiment.
- Once Kin-E-Sim is loaded and compiled, it can be accessed by selecting `Analysis` -> `Kin-E-Sim` -> `Control Panel`. The `Control Panel` will appear.  
- Finally, select `Analysis` -> `Kin-E-Sim` -> `Create Set`. A dialog box will appear asking for a name. Any name can be entered here. Click `Continue`. All necessary waves will be generated.
- From the `Control Panel` select the job that you just named to load the waves into the `Control Panel`.

The code consists of three units:
- KES_Core: simulation engine, implemented as KES independent module; Includes:
	- KES_Core_Aliases.ipf
	- KES_Core_FLow.ipf
	- KES_Core_Integrator.ipf
	- KES_Core_Log.ipf
	- KES_Core_Progress.ipf
	- KES_Core_Struct.ipf
	
- KES_Sets: handles preparation and processing of individual simulations and their sets; hands simulations off to KES_Core, which is required; implemented as KES_Sets module; Includes:
	- KES_Sets_Aux.ipf
	- KES_Sets_Flow.ipf
	- KES_Sets_Progress.ipf
	- KES_Sets_Proxy.ipf
	- KES_Sets_Struct.ipf
	
- KES_GUI: Implements users interface; requires KES_Core and KES_Sets; implemented as KES_GUI module; includes:
	- KES_GUI_Aux.ipf
	- KES_GUI_Comp.ipf
	- KES_GUI_Rxns.ipf

## Kin-E-Sim Demo
A demo of Kin-E-Sim containing pre-loaded simulations is available [here](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/Demo).

## Performance Testing
A performance test is available [here](https://github.com/dap-biospec/KinESim/tree/master/Demo/PerformanceTest.md).

## Control Panel
![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/Docs/Figures/ControlPanel.png)
The `Control Panel` used to perform Kin-E-Sim simulations is shown above. Each sub-panel and its functions are described below:
### Top-left corner
![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/Docs/Figures/TLC.png)
- ![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/TLC_i.png): Shows the current version of Kin-E-Sim kinetic simulator
- ![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/TLC_refresh.png): Reloads selected job
- `job`: Allows for the selection of a user-defined job set that specifies all values, methods, and waves for the simulation. Job sets are stored in text waves. Multiple job waves can be made to easily switch between experiments. 
- `sets=>`: Defines parameters of single simulation or simulation sets.
- `ctrl. table`: Creates a table showing the names and contents of all parameter waves for the selected job. Parameters can be edited from this table. Press   to update changes in the Control Panel.
- `log`: Used for debugging purposes only.
- `flags`: miscellaneous flags
- `esim =>`: Defines the configuration of the electrochemical system and parameters of the numerical integrator. 
### Simulation
![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/simulation_sp.png)
- `prep`: function that generates the potential waveform or performs other pre-simulation steps
- `process`: function that performs step-wise simulation and integration
- `plot`: function for post-processing of a single simulation, including preparation of a report graphs.
- `base name`: Name of the current simulation provided by the user. Multiple wave names will be derived from this name. Each new simulation performed must have a unique `base name` or previous results will be overwritten. 
- `CPU threads`: Controls the number of CPU threads used during a simulation and determines if simulations will be performed in parallel or sequentially (see **Multi-threaded simulations**)
- `do this sim`: A button used to start a single simulation.
- `rel. layer`: The layer thickness in centimeters
- `Bi-dir`: Allows the user to run the simulation as unidirectional or bidirectional (reversible) modes. Exact interpretation depends on the potential waveform. 
	- `No`: Simulation will run in unidirectional mode and perform the simulation once using the potential profile described under the method settings.
	- `Yes`: Simulation will run in bidirectional mode and perform two simulations, the first following the potential profile as described under the method settings, and the second following the potential profile in the opposite direction.
- `ET rate vs. E`: Specifies electron transfer rate on the electrode as a function of applied potential relative to redox potential of this component. 
- `rate limit`: Allows the user to select whether the simulation is run using the complete model or the reduced model. 
### Integrator
Parameters for Runge-Kutta integration

![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/integrator_sp.png)
- **RK limits in solution/electrode**: limit of changes in concertation of any component relative to that at the beginning of the step.
	- `i-th drop`: maximal reduction in the concentration during incremental RK step. 
	- `i-th rise`: maximal rise in the concentration during incremental RK step.
	- `step drop`: maximal reduction in the concentration during complete RK step.
	- `step rise`: maximal rise in the concentration during complete RK step.
- **RK timing changes**: Parameters used to control the step size of each iteration of the RK integrator. The RK integrator attempts a certain step size. If the step violates the indicated barriers, the step is recalculated at a smaller step size. If a step is performed successfully, the step size in increased to reduce the amount of time required to complete simulations. 
	- `mult. on drop limit`: Reduction in simulation step if maximal allowed concentration decrease limit has been violated in the preceding attempt.  
	- `mult. on rise limit`: Reduction in simulation step if maximum allowed concentration rise limit has been violated in the preceding attempt.
	- `hold on limit`: The number of iterations performed with no attempt at increasing the step size.
	- `mult. next step`: Increase in the next simulation step after successful completion of the current step. 
### Components
This section is used to define the components that make up the simulated reaction, including all mediators and analytes.

![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/components_sp.png)
- `=>`: Drop down menu to select the wave containing the list of components and their properties, including interactions with the electrode.
- `C#`: Drop down menu to select ID of an individual component in this set, followed by its literal name
- `+ C#`: add a component
- `- C#`: remove the currently selected component
- `[ox.]`: The initial molar concentration of the oxidized state of the component
- `[rd.]`: The initial molar concentration of the reduced state of the component
- `E0`: The redox potential of the component in volts
- `n`: The electron transfer coefficient of the component
- `alpha`: The α of the component
- `ET rate`: The intrinsic rate constant for the electron transfer at the electrode (k°el)
- `Binding K`: The equilibrium constant that controls the population of the component in solution versus bound to the electrode surface (only used for the complete model)
- `Binding rate`: The rate constant that control the rate at which the component binds to the electrode surface (only used for the complete model). 
- `lim. rate`: The maximum effective rate constant for the electrolysis (only used for the simplified model).
- `flags`: determines if the simulated concentration profiles of this component should be processed further. Input is 0 or 1.
- `alias this`: Allows two or more components to be treated as the same species. Used for mediators or analytes that have multiple redox potentials or are involved in other equilibria.
	- `none`: no alias is provided for this component
	- `ox`: the oxidized form of this component is the same species as another component in the component list.
	- `To C#`: Allows the user to select the alias component and its oxidation state
	- `rd`: the reduced form of this component is the same species as another component within the component list.

### Method settings 
User selects an Igor wave containing the method parameters. These parameters are used by the preparation function to generate a potential waveform.

![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/MethodSettings_sp.png)

### Echem reactions
This section defines the electrochemical reactions that take place in solution between mediators and analytes.

![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/EchemRxns_sp.png)
- ![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/Rxns_create.png): Pressing this button creates the waves needed to set up the reactions 
- `Rx#`: Drop down menu used to select reactions to be edited, followed by the literal name of the reaction.
- `+ Rx`: add a reaction to the list
- `- Rx`: remove the currently selected reaction.
- `Keq`: The equilibrium constant of the electrochemical reaction. This read-only value is calculated based on the E0 of the components involved in the reaction.
- `k(fwd)`: The forward rate of the reaction (user input)
- `w`  and `Thermo w.`: Read-only names of waves used internally to describe current reaction. 
- **Reaction table**
![alt text](https://github.com/dap-biospec/UTEIU1dq7RRTfvV9/blob/master/test/docs/Figures/Rxns_table.png)
	- Each row is used to describe how a single component is changed during a reaction. Rows can be added for reactions that involve multiple components by pressing the “+ row” button or removed by pressing the “- row” button. 
	- Columns:
		- `->|#..`: ID of the reactant component
		- `->|Ox..`: stoichiometric coefficient of the oxidized form as a reactant
		- `->|Rd..`: stoichiometric coefficient of the reduced form as a reactant
		- `..#|->`: ID of the product component
		- `..Ox|->`: stoichiometric coefficient of the oxidized form as a product
		- `..Rd|->`: stoichiometric coefficient of the reduced form as a product
		
		>**Hint:** A stoichiometric coefficient of “0” is used for non-participating forms of reactants or products.
		
		>**Example:** In the table shown above, components 0 and 1 are participating in an electrochemical reaction. As written, one mole of oxidized component 0 reacts with one mole of reduced component 1 to form one mole each of reduced component 0 and oxidized component 1. 

### General reactions
Used to set up non-electrochemical reactions that take place in solution. This section can be used to simulate the conversion of one component into another, or the reaction between two or more components to form new components. 
- See **Echem reactions** for an in depth explanation of each element of this section not listed below:
- `Keq`: The equilibrium constant of the general reaction. This value is set by the user. 

### sim. set 
This section is used to automate a series of simulations that change a single variable such as the E0, concentration, ET rate, or lim. rate of a component. A set yields a 1D variation in the model. 
- `In setup`: Method that performs preparation of the set; called ones per set. 
- `In assign`: Method that performs assignment prior to each simulation. 
- `Out setup`: Method that prepares output set data; called once per set.
- `Out assign`: Method that saves the results of each simulation.
- `Cleanup`: Method for general maintenance at the completion of the set. 
- `Plot setup`: Method to prepare graphical report; called once per set. 
- `Append`: Method append results of the simulation to the graphical report. 
- `From`: The initial value of the variable to be changed
- `To`: The final value of the variable to be changed
- `Steps`: The total number of simulations to be performed. This also controls how much the variable is varied between each step.
- `Vary C#`: Identifies the component that will be altered during each step.
- `Plot C#`: Identifies the component to be appended to the graphical report. 
- `CPU thr.`: Sets the maximum number of threads that may be used during the simulation.
- `Do single set`: Press this button to perform the simulation set.

### kilo set
This section is used to automate a series of simulations that alter a second variable. All **sim. set** simulations are repeated for each value of **kilo set** variable, which yields a 2D variation in the model.
- Values of `param 1`, `param 2` and `flags` can be used and interpreted by the assignment methods.  

### mega set
This section is used to automate a series of simulations that alter a third variable. All **kilo set** simulations are repeated for each value of **mega set** variable, which yields a 3D variation in the model.  
- Values of `param 1`, `param 2` and `flags` can be used and interpreted by the assignment methods.  