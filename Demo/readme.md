# Kin-E-Sim Demo
The KinESim Demo file (KES_Demo.pxp) is included with the KinESim instillation. See the [manual](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_manual.md) for instillation instructions.

## Performing a simulation
Open KES_Demo.pxp file. 

To open the KinESim control panel click `Analysis -> Kin-E-Sim -> Control Panel`

A simulation is already set up, it just needs to be loaded into the panel. 

In the top-left corner of the panel, click the drop down menu labeled `job` and select `NPVJob`.

The preset simulation performs normal pulsed voltammetry of an analyte with a redox potential of -0.1 V. The properties of this analyte have been preset so that it has fast electrochemical kinetics with the electrode. 

Click `do this sim` in the simulation panel to see how this analyte performs.

The following graph should appear showing you the potential profile of the NPV method (grey) and the concentration profile of the analyte in its oxidized form (red).

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig1.png)

*Figure 1*


This gives us a good idea of the behavior of our analyte but we can change the NPV parameters to get a more informative picture. 

## Modifying Parameters
Under the `Method Settings` panel, change `NPV Low E` to -0.4. This will change the initial applied potential from -0.2 V to -0.4 V giving us a wider view of the analyte behavior.

Also change `NPV StepsE` to 20. This will reduce the size of the potential step and give us more data points. 

Click `do this sim` and the graph should change to look like this:

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig2.png)

*Figure 2*

This gives us a much better view of how our analyte behaves. 

Now let’s try simulating a scenario.

In this scenario, we have a single analyte with slow electrochemical kinetics on the electrode. 

In the `Components` panel change `ET rate` to 0.001 and `lim. rate` to 0.001.

Click `do this sim` and see how the analyte behaves:

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig3.png)

*Figure 3*

Notice that our analyte is no longer being completely reduced or oxidized at each potential step. 

Our goal now is to find a mediator that will improve the rate of electron transfer to and from the analyte so that we can achieve a profile like we saw in Figure 2.

## Adding Components
Let’s add a new component that will represent our mediator to our components panel.
To do this click the `+C#` button in the `components` panel

A new component has been made but it needs a name. Type “Mediator 1” into the text box.

You can switch between the analyte and mediator 1 by clicking the drop down menu labeled `C #` and selecting `0` (the analyte) or `1` (the mediator). 

Let’s give our mediator some electrochemical properties. The default value for the redox potential (`E0`) is 0 V. Keep this value 0. Change `n` to 1. This means that the mediator transfers 1 electron per mediator molecule. Change `alpha` to 0.5. This represents the alpha of the mediator. This value is typically assumed to be 0.5 for most electrochemically active species.

We want a mediator with fast kinetics so change `ET rate` to 0.2 and `lim. Rate` to 0.5.

Now that we’ve described our mediator we still need to add some amount of the mediator to our simulated electrochemical reaction. Since we are performing oxidation, we will start with a completely reduced sample. `[ox.]` is the concentration of oxidized mediator in the sample in molarity and should remain 0. Change `[rd.]`, the concentration of reduced mediator in the sample to 0.0002 M. 

Click `do this sim` and see how it looks:

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig4.png)

*Figure 4*

Our mediator is shown in red and our analyte in purple. Notice the profile of the mediator demonstrates fast electrochemical kinetics, just what we wanted. But our analyte is still showing slow kinetics. This is because we have not told KinESim how the mediator and analyte interact. So KinESim is simulating the two components as if they have no interaction in solution. 

To fix this we need to add an E-chem reaction.

To do this, click the ![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/Rxns_create.png) button in the `E-Chem reactions` panel. This will generate the Igor waves needed to describe an E-Chem reaction. 

Name the reaction “M1+A” by typing the name in the text box of the `E-chem reactions` panel. 

Below is a table that describes the E-chem reaction. See the [manual](https://github.com/dap-biospec/KinESim/blob/master/Docs/KES_manual.md#Echem-reactions) for a description of the table. 

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig5.png)

*Figure 5*

Each row in the table represents a component changing from one state to the next. 

We need to add a row so that there is one row for the analyte and one row for the mediator.

Click the `+ row` button to add a row. 

Now fill in the table as shown below:

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig6.png)

*Figure 6*

This E-chem reaction table tells KinESim that component 0 (the analyte) and component 1 (the mediator) will perform an electrochemical reaction where 1 oxidized molecule of component 0 + 1 reduced molecule of component 1 will become 1 reduced molecule of component 0 + 1 oxidized molecule of component 1. 

KinESim automatically understands that this reaction can occur in the reverse order. 

Now we just need to input a value for the rate constant of the forward reaction. Change `k(fwd)` to 500. This will make the electron transfer between the mediator and analyte fast. 

Click `do this sim` and let’s see how well our mediator works.
 
![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig7.png) 
 
The concentration of the analyte profile has improved but the reduction process still seems a bit sluggish.

## Performing a set of simulations
Let’s see what effect the redox potential of the mediator has on its ability to perform electron transfer with the analyte. We’ll want to sample a range of redox potential values. We can do all of this at once using the `sim. set` panel. 

The `sim. set` panel is already set up to change the redox potential from -0.2 to 0 in 3 steps for component number 0. This means that three simulations will be performed where the analyte redox potential is varied between -0.2 V, -0.1 V, and 0.0 V. But we want to vary the redox potential of the mediator, not the analyte. Change `vary C#` to 1. 

Before we run the simulation we should change the name of the simulation. KinESim uses this name when it generates waves and graphs of simulated data. Therefore, performing a simulation with the same name as the previous will overwrite the previous data. For this reason, it is good practice to use a different name for every simulation you perform. 

Change the `base name` in the `simulation` section to “M_Ox_set”

Now click `do single set`

Three profiles will appear. They may be stacked so if you only see one, try moving the top window to reveal the other profiles. 

They should look like the following:

![alt text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig8a.png)

![alt_text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig8b.png)

![alt_text](https://github.com/dap-biospec/KinESim/blob/master/Docs/Figures/demoFig8c.png)
 
Notice that the mediator profile shifts as its redox potential changes. 

The second simulation gives us the result we were looking for. Therefore, we should use a mediator that has a redox potential of -0.1 V which is the same as that of our analyte. 