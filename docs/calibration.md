# Calibration inputs (from Excel)

This file documents how one calibrates the model using the Excel workbook `ModelSimulationandCalibration5Sectorsand1Regionsssp185.xlsx`. I separate (i) **data inputs used to pin down the steady state** from (ii) **structural model parameters**.

> Note: some cells in the Excel file contain external references (e.g., `=[1]Data!J2`). When those links are not available, Excel may show zeros or blanks. In the tables below I report the cell contents as they appear in this workbook.

## 📘 Documentation Overview

- **Project overview:** [Home](index.md)
- **Model structure & equations:** [Model documentation](model.md)
- **Scenario design & assumptions:** [Scenarios](scenario.md)
- **Calibration & data sources:** [Calibration](calibration.md)
- **How to run the model:** [Running the model](running.md)


## A. Data inputs for the steady state

### A1. Sectoral calibration targets and SAM-style shares

| Sector     | Region   |   Initial Employment (phiN0) |   Initial Value Added (phiY0) |   Labour Cost (phiW) |   Exports (phiX) |   Import Intermediate (phiM_I) |   Import final (phiM_F) |   Intermediate (phiQI) | emission share (sE)   |
|:-----------|:---------|-----------------------------:|------------------------------:|---------------------:|-----------------:|-------------------------------:|------------------------:|-----------------------:|:----------------------|
| Primary    | VNM      |                     0.435028 |                     0.0425029 |          0.0386909   |        0.0191328 |                      0.0784777 |             0.00255391  |             0.0094822  | =[1]Data!J2           |
| Fossil     | VNM      |                     0.0061   |                     0.02      |          0.000460171 |        0.002     |                      0.0321253 |             0.00180434  |             0.00886213 | =SUM([1]Data!J3:J4)   |
| Renewables | VNM      |                     0.0009   |                     0.005     |          0.000230086 |        0.001     |                      0.01      |             0.000318412 |             0.0015639  | =[1]Data!J5           |
| Secondary  | VNM      |                     0.224638 |                     0.11653   |          0.0304453   |        0.241271  |                      0.492783  |             0.0297085   |             0.174331   | =[1]Data!J6           |
| Tertiary   | VNM      |                     0.333333 |                     0.0956956 |          0.0789588   |        0.0265966 |                      0.114727  |             0.0162442   |             0.0454525  | =[1]Data!J7           |


### A2. Intermediate-input shares by subsector and origin sector

| Subsector   | Region   | Sector of Origin   |   intermediate input share (phiQI) |   share of emissions (sEI) |
|:------------|:---------|:-------------------|-----------------------------------:|---------------------------:|
| Primary     | VNM      | Primary            |                        0.326716    |                          0 |
| Primary     | VNM      | Energy             |                        0.012461    |                          0 |
| Primary     | VNM      | Secondary          |                        0.524014    |                          0 |
| Primary     | VNM      | Tertiary           |                        0.136809    |                          0 |
| Fossil      | VNM      | Primary            |                        5.27121e-05 |                          0 |
| Fossil      | VNM      | Energy             |                        0.231886    |                          0 |
| Fossil      | VNM      | Secondary          |                        0.623421    |                          0 |
| Fossil      | VNM      | Tertiary           |                        0.14464     |                          0 |
| Renewables  | VNM      | Primary            |                        4.9975e-05  |                          0 |
| Renewables  | VNM      | Energy             |                        0.423338    |                          0 |
| Renewables  | VNM      | Secondary          |                        0.455647    |                          0 |
| Renewables  | VNM      | Tertiary           |                        0.120965    |                          0 |
| Secondary   | VNM      | Primary            |                        0.122953    |                          0 |
| Secondary   | VNM      | Energy             |                        0.0430974   |                          0 |
| Secondary   | VNM      | Secondary          |                        0.694896    |                          0 |
| Secondary   | VNM      | Tertiary           |                        0.139054    |                          0 |
| Tertiary    | VNM      | Primary            |                        0.028367    |                          0 |
| Tertiary    | VNM      | Energy             |                        0.0297153   |                          0 |
| Tertiary    | VNM      | Secondary          |                        0.513588    |                          0 |
| Tertiary    | VNM      | Tertiary           |                        0.428329    |                          0 |


### A3. Interregional demand shares

| Subsector   | Region of Origin   | Region of Destination   |   demand of products from different regions (phiQ_D) |
|:------------|:-------------------|:------------------------|-----------------------------------------------------:|
| Primary     | VNM                | VNM                     |                                                    1 |
| Fossil      | VNM                | VNM                     |                                                    1 |
| Renewables  | VNM                | VNM                     |                                                    1 |
| Secondary   | VNM                | VNM                     |                                                    1 |
| Tertiary    | VNM                | VNM                     |                                                    1 |


### A4. Regional initial levels (placeholders)

| Region   | initial price level imports (P0_MR)   | initial domestic price level (P0_D)   | initial population (PoP0)   | initial labour force (LF0)   | initial employment (N0)   | initial stocks of houses (H0)   |
|:---------|:--------------------------------------|:--------------------------------------|:----------------------------|:-----------------------------|:--------------------------|:--------------------------------|
| VNM      | enter value here                      | enter value here                      | enter value here            | enter value here             | enter value here          | enter value here                |


### A5. Climate initial condition (placeholders)

| Region   | initial surface temperature (Celsius) (tas0)   |
|:---------|:-----------------------------------------------|
| VNM      | enter value here                               |


### A6. Additional initial conditions (placeholders)

| Name              | Value            |
|:------------------|:-----------------|
| initial Sea level | enter value here |


### A7. Normalizations / scalars used in calibration

| Name                                                |   Value |
|:----------------------------------------------------|--------:|
| initial employment                                  |   0.25  |
| initial value added                                 |   5     |
| import share                                        |   0.2   |
| investmetns in residential building relative to GDP |   0.001 |
| tax on labour                                       |   0     |
| tax on capital income                               |   0     |
| tax on consumption                                  |   0.2   |


### A8. Aggregate/initial steady-state values (Start sheet)

| Name / Parameter                                                           | Value              | Description                                                        |
|:---------------------------------------------------------------------------|:-------------------|:-------------------------------------------------------------------|
| Y0_p                                                                       | 5                  | initial GDP                                                        |
| Parameter values for initial sum of hours worked to potential hours worked |                    |                                                                    |
| N0_1_p                                                                     | =15/100            | initial sum of hours worked to potential hours worked in  region 1 |
| Parameter values for initial emission price                                |                    |                                                                    |
| P0_1_p                                                                     | =0/100             | initial emission price in  region 1                                |
| Parameter values for initial emissionss                                    |                    |                                                                    |
| E0_1_p                                                                     | 1                  | initial emissionss in  region 1                                    |
| PE0_1_p                                                                    | 0.01               | initial price for emissions                                        |
| Parameter values for investmetns in residential building relative to GDP   |                    |                                                                    |
| sH_1_p                                                                     | =1/100             | investmetns in residential building relative to GDP in  region 1   |
| Parameter values for initial population                                    |                    |                                                                    |
| PoP0_1_p                                                                   | 1                  | initial population in  region 1                                    |
| Parameter values for initial labour force                                  |                    |                                                                    |
| LF0_1_p                                                                    | =0.96*B13          | initial labour force in  region 1                                  |
| Parameter values for initial housing                                       |                    |                                                                    |
| H0_1_p                                                                     | =25                | initial housing  in  region 1                                      |
| Parameter values for initial value for tas                                 |                    |                                                                    |
| tas0_1_p                                                                   | =0                 | initial value for tas in  region 1                                 |
| SL0_p                                                                      | =0                 | initial value for SL                                               |
| Parameter values for initial share of value added                          |                    |                                                                    |
| phiY0_1_1_p                                                                | 0.0425029247021817 | initial share of value added in sector 1 and region 1              |
| phiY0_2_1_p                                                                | 0.02               | initial share of value added in sector 2 and region 1              |
| phiY0_3_1_p                                                                | 0.005              | initial share of value added in sector 3 and region 1              |
| phiY0_4_1_p                                                                | 0.116529566303951  | initial share of value added in sector 4 and region 1              |
| phiY0_5_1_p                                                                | 0.0956955915258092 | initial share of value added in sector 5 and region 1              |
| Parameter values for initial share of employment                           |                    |                                                                    |
| phiN0_1_1_p                                                                | 0.435028225183487  | initial share of employment in sector 1 and region 1               |
| phiN0_2_1_p                                                                | 0.0061             | initial share of employment in sector 2 and region 1               |
| phiN0_3_1_p                                                                | 0.0009             | initial share of employment in sector 3 and region 1               |
| phiN0_4_1_p                                                                | 0.224638431549072  | initial share of employment in sector 4 and region 1               |
| phiN0_5_1_p                                                                | 0.333333343267441  | initial share of employment in sector 5 and region 1               |


## B. Model parameters (Structural Parameters sheet)

| Parameter                                                                                                              | Value                | Description                                                                                                                              |
|:-----------------------------------------------------------------------------------------------------------------------|:---------------------|:-----------------------------------------------------------------------------------------------------------------------------------------|
| beta_p                                                                                                                 | 0.97                 | discount factor                                                                                                                          |
| delta_p                                                                                                                | =45/1000             | depreciation rate                                                                                                                        |
| deltaB_p                                                                                                               | =45/1000             | depreciation rate                                                                                                                        |
| phiB_p                                                                                                                 | 1                    | foreign bond adjustment cost                                                                                                             |
| phiadjB_p                                                                                                              | 0.1                  | foreign bond adjustment cost                                                                                                             |
| phiK_p                                                                                                                 | 40                   | investment adjustment cost                                                                                                               |
| sigmaL_p                                                                                                               | =5/10                | inverse Frisch elasticity                                                                                                                |
| sigmaC_p                                                                                                               | =1                   | intertemporal elasticity of substitution for consumption                                                                                 |
| etaQ_p                                                                                                                 | 0.6                  | elasticity of substitution between sectors                                                                                               |
| etaF_p                                                                                                                 | 0.6                  | elasticity of substitution between imports and domestic products                                                                         |
| etaX_p                                                                                                                 | 0.6                  | supply price elasticity of exports                                                                                                       |
| tauC_p                                                                                                                 | 0.2                  | consumption tax rate                                                                                                                     |
| tauNH_p                                                                                                                | 0                    | tax rate on labour income                                                                                                                |
| tauKH_p                                                                                                                | 0                    | tax rate on capital income                                                                                                               |
| Parameter values for elasticity of substitution between subsectors in one sector                                       |                      |                                                                                                                                          |
| etaQA_1_p                                                                                                              | 1                    | elasticity of substitution between subsectors in one sector in sector 1                                                                  |
| etaQA_2_p                                                                                                              | 5                    | elasticity of substitution between subsectors in one sector in sector 2                                                                  |
| etaQA_3_p                                                                                                              | 1                    | elasticity of substitution between subsectors in one sector in sector 3                                                                  |
| etaQA_4_p                                                                                                              | 1                    | elasticity of substitution between subsectors in one sector in sector 4                                                                  |
| etaQA_5_p                                                                                                              | 1                    | elasticity of substitution between subsectors in one sector in sector 5                                                                  |
| Parameter values for elasticity of substitution between regions in one subsector                                       |                      |                                                                                                                                          |
| etaQ_1_p                                                                                                               | 2                    | elasticity of substitution between regions in one subsector in sector 1                                                                  |
| etaQ_2_p                                                                                                               | 2                    | elasticity of substitution between regions in one subsector in sector 2                                                                  |
| etaQ_3_p                                                                                                               | 2                    | elasticity of substitution between regions in one subsector in sector 3                                                                  |
| etaQ_4_p                                                                                                               | 2                    | elasticity of substitution between regions in one subsector in sector 4                                                                  |
| etaQ_5_p                                                                                                               | 2                    | elasticity of substitution between regions in one subsector in sector 5                                                                  |
| Parameter values for cost share of intermediate goods                                                                  |                      |                                                                                                                                          |
| phiQI_1_1_p                                                                                                            | 0.0784777058202289   | cost share of intermediate goods in sector 1 and region 1                                                                                |
| phiQI_2_1_p                                                                                                            | 0.0321252755732743   | cost share of intermediate goods in sector 2 and region 1                                                                                |
| phiQI_3_1_p                                                                                                            | 0.01                 | cost share of intermediate goods in sector 3 and region 1                                                                                |
| phiQI_4_1_p                                                                                                            | 0.492783102071734    | cost share of intermediate goods in sector 4 and region 1                                                                                |
| phiQI_5_1_p                                                                                                            | 0.114726697583448    | cost share of intermediate goods in sector 5 and region 1                                                                                |
| Parameter values for final use import shares                                                                           |                      |                                                                                                                                          |
| phiM_F_1_1_p                                                                                                           | 0.00255391369847977  | final use import shares in sector 1 and region 1                                                                                         |
| phiM_F_2_1_p                                                                                                           | 0.00180433607915587  | final use import shares in sector 2 and region 1                                                                                         |
| phiM_F_3_1_p                                                                                                           | 0.000318412249262801 | final use import shares in sector 3 and region 1                                                                                         |
| phiM_F_4_1_p                                                                                                           | 0.0297085187037294   | final use import shares in sector 4 and region 1                                                                                         |
| phiM_F_5_1_p                                                                                                           | 0.0162441867931541   | final use import shares in sector 5 and region 1                                                                                         |
| Parameter values for intermediate import shares                                                                        |                      |                                                                                                                                          |
| phiM_I_1_1_p                                                                                                           | 0.00948220438474694  | intermediate import shares in sector 1 and region 1                                                                                      |
| phiM_I_2_1_p                                                                                                           | 0.00886212517256058  | intermediate import shares in sector 2 and region 1                                                                                      |
| phiM_I_3_1_p                                                                                                           | 0.00156390444221657  | intermediate import shares in sector 3 and region 1                                                                                      |
| phiM_I_4_1_p                                                                                                           | 0.174331250149512    | intermediate import shares in sector 4 and region 1                                                                                      |
| phiM_I_5_1_p                                                                                                           | 0.0454525216192177   | intermediate import shares in sector 5 and region 1                                                                                      |
| Parameter values for share of exports on revenues                                                                      |                      |                                                                                                                                          |
| phiX_1_1_p                                                                                                             | 0.0191327747844086   | share of exports on revenues  in sector 1 and region 1                                                                                   |
| phiX_2_1_p                                                                                                             | 0.002                | share of exports on revenues  in sector 2 and region 1                                                                                   |
| phiX_3_1_p                                                                                                             | 0.001                | share of exports on revenues  in sector 3 and region 1                                                                                   |
| phiX_4_1_p                                                                                                             | 0.241270610102402    | share of exports on revenues  in sector 4 and region 1                                                                                   |
| phiX_5_1_p                                                                                                             | =0.29-SUM(B47:B50)   | share of exports on revenues  in sector 5 and region 1                                                                                   |
| Parameter values for elasticity of subsitution between primary production factors and intermediate products            |                      |                                                                                                                                          |
| etaI_1_p                                                                                                               | 1                    | elasticity of subsitution between primary production factors and intermediate products in sector 1                                       |
| etaI_2_p                                                                                                               | 1                    | elasticity of subsitution between primary production factors and intermediate products in sector 2                                       |
| etaI_3_p                                                                                                               | 1                    | elasticity of subsitution between primary production factors and intermediate products in sector 3                                       |
| etaI_4_p                                                                                                               | 1                    | elasticity of subsitution between primary production factors and intermediate products in sector 4                                       |
| etaI_5_p                                                                                                               | 1                    | elasticity of subsitution between primary production factors and intermediate products in sector 5                                       |
| Parameter values for elasticity of subsitution between intermeidates                                                   |                      |                                                                                                                                          |
| etaIA_1_p                                                                                                              | 0.1                  | elasticity of subsitution between intermeidates in sector 1                                                                              |
| etaIA_2_p                                                                                                              | 0.1                  | elasticity of subsitution between intermeidates in sector 2                                                                              |
| etaIA_3_p                                                                                                              | 0.1                  | elasticity of subsitution between intermeidates in sector 3                                                                              |
| etaIA_4_p                                                                                                              | 0.1                  | elasticity of subsitution between intermeidates in sector 4                                                                              |
| etaIA_5_p                                                                                                              | 0.1                  | elasticity of subsitution between intermeidates in sector 5                                                                              |
| Parameter values for labour cost share                                                                                 |                      |                                                                                                                                          |
| phiW_1_1_p                                                                                                             | 0.0386909096516785   | labour cost share in sector 1 and region 1                                                                                               |
| phiW_2_1_p                                                                                                             | 0.000460171456623585 | labour cost share in sector 2 and region 1                                                                                               |
| phiW_3_1_p                                                                                                             | 0.000230085728311792 | labour cost share in sector 3 and region 1                                                                                               |
| phiW_4_1_p                                                                                                             | 0.0304453344282896   | labour cost share in sector 4 and region 1                                                                                               |
| phiW_5_1_p                                                                                                             | 0.0789587865453611   | labour cost share in sector 5 and region 1                                                                                               |
| Parameter values for elasticity of subsitution between labour and captial                                              |                      |                                                                                                                                          |
| etaNK_1_1_p                                                                                                            | 1                    | elasticity of subsitution between labour and captial in sector 1 and region 1                                                            |
| etaNK_2_1_p                                                                                                            | 1                    | elasticity of subsitution between labour and captial in sector 2 and region 1                                                            |
| etaNK_3_1_p                                                                                                            | 1                    | elasticity of subsitution between labour and captial in sector 3 and region 1                                                            |
| etaNK_4_1_p                                                                                                            | 1                    | elasticity of subsitution between labour and captial in sector 4 and region 1                                                            |
| etaNK_5_1_p                                                                                                            | 1                    | elasticity of subsitution between labour and captial in sector 5 and region 1                                                            |
| Parameter values for tax rate on capital expenditures                                                                  |                      |                                                                                                                                          |
| tauKF_1_1_p                                                                                                            | =0                   | tax rate on capital expenditures in sector 1 and region 1                                                                                |
| tauKF_2_1_p                                                                                                            | =0                   | tax rate on capital expenditures in sector 2 and region 1                                                                                |
| tauKF_3_1_p                                                                                                            | =0                   | tax rate on capital expenditures in sector 3 and region 1                                                                                |
| tauKF_4_1_p                                                                                                            | =0                   | tax rate on capital expenditures in sector 4 and region 1                                                                                |
| tauKF_5_1_p                                                                                                            | =0                   | tax rate on capital expenditures in sector 5 and region 1                                                                                |
| Parameter values for tax rate on labour costs                                                                          |                      |                                                                                                                                          |
| tauNF_1_1_p                                                                                                            | =0                   | tax rate on labour costs in sector 1 and region 1                                                                                        |
| tauNF_2_1_p                                                                                                            | =0                   | tax rate on labour costs in sector 2 and region 1                                                                                        |
| tauNF_3_1_p                                                                                                            | =0                   | tax rate on labour costs in sector 3 and region 1                                                                                        |
| tauNF_4_1_p                                                                                                            | =0                   | tax rate on labour costs in sector 4 and region 1                                                                                        |
| tauNF_5_1_p                                                                                                            | =0                   | tax rate on labour costs in sector 5 and region 1                                                                                        |
| Parameter values for share of emissions on total emissions for each sector                                             |                      |                                                                                                                                          |
| sE_1_1_p                                                                                                               | 0                    | share of emissions on total emissions for each sector in sector 1 and region 1                                                           |
| sE_2_1_p                                                                                                               | 1                    | share of emissions on total emissions for each sector in sector 2 and region 1                                                           |
| sE_3_1_p                                                                                                               | 0                    | share of emissions on total emissions for each sector in sector 3 and region 1                                                           |
| sE_4_1_p                                                                                                               | 0                    | share of emissions on total emissions for each sector in sector 4 and region 1                                                           |
| sE_5_1_p                                                                                                               | 0                    | share of emissions on total emissions for each sector in sector 5 and region 1                                                           |
| Parameter values for share of inputs from another sector for each subsector                                            |                      |                                                                                                                                          |
| phiQI_1_1_1_p                                                                                                          | 0.326715528592644    | share of inputs from another sector for each subsector in sector 1 and region 1 from sector 1                                            |
| phiQI_1_1_2_p                                                                                                          | 0.0124609936327178   | share of inputs from another sector for each subsector in sector 1 and region 1 from sector 2                                            |
| phiQI_1_1_3_p                                                                                                          | 0.52401409339883     | share of inputs from another sector for each subsector in sector 1 and region 1 from sector 3                                            |
| phiQI_1_1_4_p                                                                                                          | 0.136809384375808    | share of inputs from another sector for each subsector in sector 1 and region 1 from sector 4                                            |
| phiQI_2_1_1_p                                                                                                          | 5.27121108092967e-05 | share of inputs from another sector for each subsector in sector 2 and region 1 from sector 1                                            |
| phiQI_2_1_2_p                                                                                                          | 0.231885934261786    | share of inputs from another sector for each subsector in sector 2 and region 1 from sector 2                                            |
| phiQI_2_1_3_p                                                                                                          | 0.623421097486084    | share of inputs from another sector for each subsector in sector 2 and region 1 from sector 3                                            |
| phiQI_2_1_4_p                                                                                                          | 0.144640256141321    | share of inputs from another sector for each subsector in sector 2 and region 1 from sector 4                                            |
| phiQI_3_1_1_p                                                                                                          | 4.99750124937531e-05 | share of inputs from another sector for each subsector in sector 3 and region 1 from sector 1                                            |
| phiQI_3_1_2_p                                                                                                          | 0.423338330834583    | share of inputs from another sector for each subsector in sector 3 and region 1 from sector 2                                            |
| phiQI_3_1_3_p                                                                                                          | 0.455647176411794    | share of inputs from another sector for each subsector in sector 3 and region 1 from sector 3                                            |
| phiQI_3_1_4_p                                                                                                          | 0.120964517741129    | share of inputs from another sector for each subsector in sector 3 and region 1 from sector 4                                            |
| phiQI_4_1_1_p                                                                                                          | 0.122952801593323    | share of inputs from another sector for each subsector in sector 4 and region 1 from sector 1                                            |
| phiQI_4_1_2_p                                                                                                          | 0.0430974122294702   | share of inputs from another sector for each subsector in sector 4 and region 1 from sector 2                                            |
| phiQI_4_1_3_p                                                                                                          | 0.694896141346769    | share of inputs from another sector for each subsector in sector 4 and region 1 from sector 3                                            |
| phiQI_4_1_4_p                                                                                                          | 0.139053644830438    | share of inputs from another sector for each subsector in sector 4 and region 1 from sector 4                                            |
| phiQI_5_1_1_p                                                                                                          | 0.0283669584146953   | share of inputs from another sector for each subsector in sector 5 and region 1 from sector 1                                            |
| phiQI_5_1_2_p                                                                                                          | 0.0297152908851502   | share of inputs from another sector for each subsector in sector 5 and region 1 from sector 2                                            |
| phiQI_5_1_3_p                                                                                                          | 0.513588296922581    | share of inputs from another sector for each subsector in sector 5 and region 1 from sector 3                                            |
| phiQI_5_1_4_p                                                                                                          | 0.428329453777573    | share of inputs from another sector for each subsector in sector 5 and region 1 from sector 4                                            |
| Parameter values for share of emissions on total emissions for each sector using prdoucts from another sector as input |                      |                                                                                                                                          |
| sEI_1_1_1_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 1 and region 1 from sector 1 |
| sEI_1_1_2_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 1 and region 1 from sector 2 |
| sEI_1_1_3_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 1 and region 1 from sector 3 |
| sEI_1_1_4_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 1 and region 1 from sector 4 |
| sEI_2_1_1_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 2 and region 1 from sector 1 |
| sEI_2_1_2_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 2 and region 1 from sector 2 |
| sEI_2_1_3_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 2 and region 1 from sector 3 |
| sEI_2_1_4_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 2 and region 1 from sector 4 |
| sEI_3_1_1_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 3 and region 1 from sector 1 |
| sEI_3_1_2_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 3 and region 1 from sector 2 |
| sEI_3_1_3_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 3 and region 1 from sector 3 |
| sEI_3_1_4_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 3 and region 1 from sector 4 |
| sEI_4_1_1_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 4 and region 1 from sector 1 |
| sEI_4_1_2_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 4 and region 1 from sector 2 |
| sEI_4_1_3_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 4 and region 1 from sector 3 |
| sEI_4_1_4_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 4 and region 1 from sector 4 |
| sEI_5_1_1_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 5 and region 1 from sector 1 |
| sEI_5_1_2_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 5 and region 1 from sector 2 |
| sEI_5_1_3_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 5 and region 1 from sector 3 |
| sEI_5_1_4_p                                                                                                            | 0                    | share of emissions on total emissions for each sector using prdoucts from another sector as input in sector 5 and region 1 from sector 4 |
| Parameter values for share of production used in one region from another region in the subsector                       |                      |                                                                                                                                          |
| phiQ_D_1_1_1_p                                                                                                         | 1                    | share of production used in one region from another region in the subsector in sector 1 and region 1 from region 1                       |
| phiQ_D_2_1_1_p                                                                                                         | 1                    | share of production used in one region from another region in the subsector in sector 2 and region 1 from region 1                       |
| phiQ_D_3_1_1_p                                                                                                         | 1                    | share of production used in one region from another region in the subsector in sector 3 and region 1 from region 1                       |
| phiQ_D_4_1_1_p                                                                                                         | 1                    | share of production used in one region from another region in the subsector in sector 4 and region 1 from region 1                       |
| phiQ_D_5_1_1_p                                                                                                         | 1                    | share of production used in one region from another region in the subsector in sector 5 and region 1 from region 1                       |
| Capital Adjustment Cost                                                                                                |                      |                                                                                                                                          |
| phiK_1_1_p                                                                                                             | 20                   | share of production used in one region from another region in the subsector in sector 1 and region 1 from region 1                       |
| phiK_2_1_p                                                                                                             | 40                   | share of production used in one region from another region in the subsector in sector 2 and region 1 from region 1                       |
| phiK_3_1_p                                                                                                             | 20                   | share of production used in one region from another region in the subsector in sector 3 and region 1 from region 1                       |
| phiK_4_1_p                                                                                                             | 20                   | share of production used in one region from another region in the subsector in sector 4 and region 1 from region 1                       |
| phiK_5_1_p                                                                                                             | 20                   | share of production used in one region from another region in the subsector in sector 5 and region 1 from region 1                       |
| Depreciation  Rate                                                                                                     |                      |                                                                                                                                          |
| delta_1_1_p                                                                                                            | 0.05                 | depreciation rate  in sector 1 and region 1                                                                                              |
| delta_2_1_p                                                                                                            | 0.05                 | depreciation rate  in sector 2 and region 1                                                                                              |
| delta_3_1_p                                                                                                            | 0.05                 | depreciation rate  in sector 3 and region 1                                                                                              |
| delta_4_1_p                                                                                                            | 0.05                 | depreciation rate  in sector 4 and region 1                                                                                              |
| delta_5_1_p                                                                                                            | 0.05                 | depreciation rate  in sector 5 and region 1                                                                                              |

