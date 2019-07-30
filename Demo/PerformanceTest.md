
# Performance Test

A performance test file is provided to test the behavior of the program after changes are made to the core programming. 

Load the file: KES_Test.pxp

The file will load with a simulation already prepared to run.
This simulation simulates the interaction of an analyte with a mediator during an normal pulsed voltammetery experiment. 
The redox potential of the mediator is varied between five values: -0.2, -0.1, 0.0, 0.1, and 0.2 V while the redox potential of the analyte remains constant at 0.0 V. 

This simulation has already been performed under the name "Control_Ox". The data is saved in the Igor expeirment in the folder titled "ControlData" which can be found in the Data Browser. 

The results of this simulation are shown in five separate graphs titled Control_Ox_00, Control_Ox_01, Control_Ox_02, Control_Ox_03, and Control_Ox_04. Images of these graphs are shown at the end of this document.

To perform the simulation click make sure that the PerformanceTest folder is the active folder in the Data Browser and then click `do single set` in the `sim. set` subpanel.

The simulation will generate 5 new graphs with the names Test_Ox_00, Test_Ox_01, Test_Ox_02, Test_Ox_03, and Test_Ox_04 that can be compared directly with their corresponding Control_Ox_## graph.

### Control_Ox_00
![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Control_Ox_C00.png)

### Control_Ox_01
![alt_text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Control_Ox_C01.png)

### Control_Ox_02
![alt_text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Control_Ox_C02.png)

### Control_Ox_03
![alt_text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Control_Ox_C03.png)

### Control_Ox_04
![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Control_Ox_C04.png)