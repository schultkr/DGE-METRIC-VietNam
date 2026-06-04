# RBC Model Replication Materials

This folder contains materials to replicate the RBC (Real Business Cycle) model session in Dynare.

## Files
- `rbc.mod`: Dynare model file for a simple RBC model with a technology shock.
- `run_rbc.m`: MATLAB/Octave script to run the model (optional, see below).

## Instructions
1. Open Dynare (MATLAB/Octave with Dynare installed).
2. Set the working directory to this folder.
3. Run the model by executing in the command window:
   
   ```
   dynare rbc.mod
   ```

## Model Features
- Representative household and firm
- Cobb-Douglas production function
- Log utility
- Capital accumulation
- Stochastic technology shock

## Output
- Impulse response functions (IRFs) for key variables
- Simulated moments

---

For questions, contact your instructor.
