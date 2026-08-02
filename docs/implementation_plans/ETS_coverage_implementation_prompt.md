# ETS Coverage Rate Implementation — Complete Change Specification

> **Status: proposed, not implemented.** Confirmed via `grep` of `ModFiles/`
> (2026-07-14): no `xi_*`, `xi0_p`, or `exo_xi*` variables are declared
> anywhere in the compiled model. The ETS currently has full (100%) implicit
> coverage with no time-varying coverage-rate mechanism. This document is a
> change specification for future work, not a description of shipped code.

## Overview

This document specifies all changes required to add **time-varying sectoral ETS coverage rates** to the DGE-CRED model. The design introduces two separate coverage rate variables:

- **`xi_{subsec}_{reg}(t)`** — direct emission coverage (scales `E_{subsec}_{reg}`)
- **`xi_I_{subsec}_{reg}_{secm}(t)`** — intermediate emission coverage (scales `E_I_{subsec}_{reg}_{secm}`)

A second structural change, needed for model consistency, is the **removal of the fossil ratio `sF_`** from all intermediate emission (`E_I`) equations and its MATLAB counterparts. The parameter `kappaEI` absorbs the fossil ratio through recalibration.

### Design Principles

| Principle | Details |
|---|---|
| Coverage parameterisation | Level-additive: `xi_t = xi0_p + exo_xi_t` (no log transform) |
| Default values | `xi0_p = 1.0`, `xi0_I_p = 1.0`, `exo_xi = 0`, `exo_xi_I = 0` → recovers current model exactly |
| Tracked aggregates | Both `E_{reg}` (total) and `E_ETS_{reg}` (ETS-covered) are tracked as separate endogenous variables |
| Revenue recycling | Government budget and transfers use `E_ETS_{reg}` |
| Cap constraint | Binds on `E_ETS_{reg}` with benchmark `E_ETS0_{reg}_p * exp(exo_EBase + exo_E)` |
| `E_ETS0_{reg}_p` | Set to `0.0` placeholder in Parameters.mod; overwritten at steady-state solve time in `compute_emissions_and_aggregate_output.m` |
| Fossil ratio | `sF_` **removed** from all `E_I` and intermediate price equations; `kappaEI` absorbs it via recalibration in `compute_pf_parameters.m` |

---

## File 1: `ModFiles/DGE_Model_Declaration.mod`

### Change 1a — New `var` entries: `E_ETS_{subsec}_{reg}` (inside subsec loop)

**Location:** Inside the `@# for subsec` loop, after line 87 (`E_@{subsec}_@{reg}`).

**Insert after:**
```
            E_@{subsec}_@{reg} ${E_{s,r}}$ (long_name = 'regional emissions associated with output used in sector k')
```
**New line to insert:**
```
            E_ETS_@{subsec}_@{reg} ${E^{ETS}_{s,r}}$ (long_name = 'ETS-covered direct emissions in subsector s region r')
```

### Change 1b — New `var` entries: `E_I_ETS_{subsec}_{reg}_{secm}` (inside secm loop)

**Location:** Inside the `@# for secm` loop (after line 92), after `E_I_@{subsec}_@{reg}_@{secm}`.

**Insert after:**
```
                E_I_@{subsec}_@{reg}_@{secm} ${E^I_{s,r,k}}$ (long_name = 'regional emissions associated with inputs used form sector k')
```
**New line to insert:**
```
                E_I_ETS_@{subsec}_@{reg}_@{secm} ${E^{I,ETS}_{s,r,k}}$ (long_name = 'ETS-covered intermediate emissions in subsector s region r from sector k')
```

### Change 1c — New `var` entry: `E_ETS_{reg}` (regional level)

**Location:** After line 134 (`E_@{reg}`).

**Insert after:**
```
    E_@{reg} ${E_r}$ (long_name = 'regional emissions')
```
**New line to insert:**
```
    E_ETS_@{reg} ${E^{ETS}_r}$ (long_name = 'total ETS-covered regional emissions')
```

### Change 1d — New `varexo` entries: `exo_xi_{subsec}_{reg}` (inside subsec loop)

**Location:** Inside the `@# for subsec` loop, after line 201 (`exo_E_@{subsec}_@{reg}`).

**Insert after:**
```
            exo_E_@{subsec}_@{reg} ${\eta^{E,s,r}}$ (long_name = 'exogenous emission of the respective sector and region')
```
**New line to insert:**
```
            exo_xi_@{subsec}_@{reg} ${\eta^{\xi,s,r}}$ (long_name = 'exogenous additive change in ETS coverage rate for subsector s region r')
```

### Change 1e — New `varexo` entries: `exo_xi_I_{subsec}_{reg}_{secm}` (inside secm loop)

**Location:** Inside the `@# for secm` loop (after line 223), after `exo_AI_@{subsec}_@{reg}_@{secm}`.

**Insert after:**
```
                exo_AI_@{subsec}_@{reg}_@{secm} ${\eta^{A^{I},s,k,r}}$ (long_name = 'exogenous productivity for intermediate products in subsector s from sector k')
```
**New line to insert:**
```
                exo_xi_I_@{subsec}_@{reg}_@{secm} ${\eta^{\xi^{I},s,k,r}}$ (long_name = 'exogenous additive change in ETS coverage rate for intermediate emissions subsector s from sector k region r')
```

### Change 1f — New `parameters` entry: `xi0_{subsec}_{reg}_p` (inside subsec loop)

**Location:** After line 333 (`sE_@{subsec}_@{reg}_p`).

**Insert after:**
```
            sE_@{subsec}_@{reg}_p ${\frac{E_{s,r}}{E_0}}$ (long_name = 'share of emissions associated with using the input factor in the subsector and region')
```
**New line to insert:**
```
            xi0_@{subsec}_@{reg}_p ${\xi_{s,r,0}}$ (long_name = 'initial ETS coverage rate for subsector s region r')
```

### Change 1g — New `parameters` entry: `xi0_I_{subsec}_{reg}_{secm}_p` (inside secm loop)

**Location:** After line 362 (`sEI_@{subsec}_@{reg}_@{secm}_p`).

**Insert after:**
```
                sEI_@{subsec}_@{reg}_@{secm}_p ${\frac{E^{I}_{s,r,k}}{E_0}}$ (long_name = 'share of emissions associated with using the input factor in the subsector and region')
```
**New line to insert:**
```
                xi0_I_@{subsec}_@{reg}_@{secm}_p ${\xi^{I}_{s,r,k,0}}$ (long_name = 'initial ETS coverage rate for intermediate emissions subsector s from sector k region r')
```

### Change 1h — New `parameters` entry: `E_ETS0_{reg}_p` (regional level)

**Location:** After line 413 (`E0_@{reg}_p`).

**Insert after:**
```
    E0_@{reg}_p ${E_{r,0}}$ (long_name = 'initial emissions')
```
**New line to insert:**
```
    E_ETS0_@{reg}_p ${E^{ETS}_{r,0}}$ (long_name = 'initial total ETS-covered emissions in region r')
```

---

## File 2: `ModFiles/DGE_Model_Parameters.mod`

### Change 2a — Initialize `xi0_{subsec}_{reg}_p`

**Location:** After line 183 (`sE_@{subsec}_@{reg}_p = ...`).

**Old text:**
```
            sE_@{subsec}_@{reg}_p = 1/(subend_@{Sectors}_p*inbregions_p+inbsectors_p*inbregions_p*subend_@{Sectors}_p);

            @# for secm in 1:Sectors
```
**New text:**
```
            sE_@{subsec}_@{reg}_p = 1/(subend_@{Sectors}_p*inbregions_p+inbsectors_p*inbregions_p*subend_@{Sectors}_p);
            xi0_@{subsec}_@{reg}_p = 1.0;

            @# for secm in 1:Sectors
```

### Change 2b — Initialize `xi0_I_{subsec}_{reg}_{secm}_p`

**Location:** Inside `@# for secm` loop, after line 189 (`sEI_@{subsec}_@{reg}_@{secm}_p = 0;`).

**Old text:**
```
                kappaEI_@{subsec}_@{reg}_@{secm}_p = 0;
                sEI_@{subsec}_@{reg}_@{secm}_p = 0;
            @# endfor
```
**New text:**
```
                kappaEI_@{subsec}_@{reg}_@{secm}_p = 0;
                sEI_@{subsec}_@{reg}_@{secm}_p = 0;
                xi0_I_@{subsec}_@{reg}_@{secm}_p = 1.0;
            @# endfor
```

### Change 2c — Initialize `E_ETS0_{reg}_p`

**Location:** After the `E0_@{reg}_p` regional parameter initialization. Find the line:

```
    E0_@{reg}_p = 1;
```

**Old text (find the pattern):**
```
    E0_@{reg}_p = 1;
```
**New text:**
```
    E0_@{reg}_p = 1;
    E_ETS0_@{reg}_p = 0.0;
```

---

## File 3: `ModFiles/Equations/firms.mod`

This file currently has the following key baseline lines (referenced by content):

- **Line 16**: `#rhsSupplySubsec_1_...` — value added FOC, emission cost `kappaE * PE * lEndoQ`
- **Line 20**: `#rhsSupplySubsec_2_...` — intermediate demand FOC, same emission cost
- **Line 24**: `#lhsSupplySubsecSec_1_...` — intermediate FOC, contains fossil ratio `(Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg})`
- **Line 29**: `#rhsSupplySubsecSec_2_...` — E_I equation, contains fossil ratio

### Change 3a — Add `xi` auxiliary before secm loop (inside subsec loop)

**Location:** Before the `@# for secm in 1:Sectors` line (before line 23).

**Old text:**
```
            #lhsSupplySubsec_2_@{subsec}_@{reg} = P_I_@{subsec}_@{reg};
            #rhsSupplySubsec_2_@{subsec}_@{reg} =  A_I_@{subsec}_@{reg}^((etaI_@{subsec}_p-1)/etaI_@{subsec}_p) * omegaQI_@{subsec}_@{reg}_p^(1/etaI_@{subsec}_p) * ((Q_I_@{subsec}_@{reg})/Q_@{subsec}_@{reg})^(-1/etaI_@{subsec}_p) * (P_Q_@{subsec}_@{reg}-kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p);
            [name = 'regional sector demand for intermediates']
            (lhsSupplySubsec_2_@{subsec}_@{reg}+1) / (rhsSupplySubsec_2_@{subsec}_@{reg}+1) = 1;
            @# for secm in 1:Sectors
```
**New text:**
```
            #lhsSupplySubsec_2_@{subsec}_@{reg} = P_I_@{subsec}_@{reg};
            #rhsSupplySubsec_2_@{subsec}_@{reg} =  A_I_@{subsec}_@{reg}^((etaI_@{subsec}_p-1)/etaI_@{subsec}_p) * omegaQI_@{subsec}_@{reg}_p^(1/etaI_@{subsec}_p) * ((Q_I_@{subsec}_@{reg})/Q_@{subsec}_@{reg})^(-1/etaI_@{subsec}_p) * (P_Q_@{subsec}_@{reg}-kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p * xi_@{subsec}_@{reg});
            [name = 'regional sector demand for intermediates']
            (lhsSupplySubsec_2_@{subsec}_@{reg}+1) / (rhsSupplySubsec_2_@{subsec}_@{reg}+1) = 1;
            #xi_@{subsec}_@{reg} = xi0_@{subsec}_@{reg}_p + exo_xi_@{subsec}_@{reg};
            @# for secm in 1:Sectors
```

### Change 3b — Scale emission cost in value added FOC (line 16)

**Old text:**
```
            #rhsSupplySubsec_1_@{subsec}_@{reg} = (1 - omegaQI_@{subsec}_@{reg}_p)^(1/etaI_@{subsec}_p) * ((Y_@{subsec}_@{reg})/Q_@{subsec}_@{reg})^(-1/etaI_@{subsec}_p) * (P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p);
```
**New text:**
```
            #rhsSupplySubsec_1_@{subsec}_@{reg} = (1 - omegaQI_@{subsec}_@{reg}_p)^(1/etaI_@{subsec}_p) * ((Y_@{subsec}_@{reg})/Q_@{subsec}_@{reg})^(-1/etaI_@{subsec}_p) * (P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p * xi_@{subsec}_@{reg});
```

### Change 3c — Add `xi_I` auxiliary and remove fossil ratio from intermediate FOC (line 24)

**Old text:**
```
                #lhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm} = P_A_@{secm}_@{reg} + kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p;
```
**New text:**
```
                #xi_I_@{subsec}_@{reg}_@{secm} = xi0_I_@{subsec}_@{reg}_@{secm}_p + exo_xi_I_@{subsec}_@{reg}_@{secm};
                #lhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm} = P_A_@{secm}_@{reg} + kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p * xi_I_@{subsec}_@{reg}_@{secm};
```

### Change 3d — Remove fossil ratio from E_I equation (line 29)

**Old text:**
```
                #rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm} = kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * Q_I_@{subsec}_@{reg}_@{secm};
```
**New text:**
```
                #rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm} = kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * Q_I_@{subsec}_@{reg}_@{secm};
```

### Change 3e — Add `E_I_ETS` equation (inside secm loop, after E_I equation)

**Location:** After the `[name = 'regional emissions caused by using intermediates from aggregate sector']` block (after line 31), before the `A_I_Eff_` line.

**Old text:**
```
                [name = 'regional emissions caused by using intermediates from aggregate sector']
                (lhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm}+1) / (rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm}+1) = 1;
                # A_I_Eff_@{subsec}_@{reg}_@{secm}=exo_AI_@{subsec}_@{reg}_@{secm}+K_A_@{subsec}_@{reg} * exo_etaKA_@{subsec}_@{reg};
```
**New text:**
```
                [name = 'regional emissions caused by using intermediates from aggregate sector']
                (lhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm}+1) / (rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm}+1) = 1;
                #lhsEIETS_@{subsec}_@{reg}_@{secm} = E_I_ETS_@{subsec}_@{reg}_@{secm};
                #rhsEIETS_@{subsec}_@{reg}_@{secm} = xi_I_@{subsec}_@{reg}_@{secm} * E_I_@{subsec}_@{reg}_@{secm};
                [name = 'ETS-covered intermediate emissions subsector s from sector k']
                (lhsEIETS_@{subsec}_@{reg}_@{secm}+1) / (rhsEIETS_@{subsec}_@{reg}_@{secm}+1) = 1;
                # A_I_Eff_@{subsec}_@{reg}_@{secm}=exo_AI_@{subsec}_@{reg}_@{secm}+K_A_@{subsec}_@{reg} * exo_etaKA_@{subsec}_@{reg};
```

### Change 3f — Add `E_ETS` equation (end of subsec loop, after emission intensity equation)

**Location:** After the emission intensity equation (line 106), before `@# endfor` closing the subsec loop (line 108).

**Old text:**
```
            [name = 'regional subsector emission intensity']
            (lEndogenousY_p == 1) * kappaE_@{subsec}_@{reg} + (lEndogenousY_p == 0) * E_@{subsec}_@{reg} = (lEndogenousY_p ==1) *(kappaE_@{subsec}_@{reg}_p + exo_kappaE_@{subsec}_@{reg}) + (lEndogenousY_p == 0) *exp(exo_E_@{subsec}_@{reg}) * E0_@{reg}_p * sE_@{subsec}_@{reg}_p;

        @# endfor
```
**New text:**
```
            [name = 'regional subsector emission intensity']
            (lEndogenousY_p == 1) * kappaE_@{subsec}_@{reg} + (lEndogenousY_p == 0) * E_@{subsec}_@{reg} = (lEndogenousY_p ==1) *(kappaE_@{subsec}_@{reg}_p + exo_kappaE_@{subsec}_@{reg}) + (lEndogenousY_p == 0) *exp(exo_E_@{subsec}_@{reg}) * E0_@{reg}_p * sE_@{subsec}_@{reg}_p;
            #lhsEETS_@{subsec}_@{reg} = E_ETS_@{subsec}_@{reg};
            #rhsEETS_@{subsec}_@{reg} = xi_@{subsec}_@{reg} * E_@{subsec}_@{reg};
            [name = 'ETS-covered direct emissions in subsector s region r']
            (lhsEETS_@{subsec}_@{reg}+1) / (rhsEETS_@{subsec}_@{reg}+1) = 1;

        @# endfor
```

---

## File 4: `ModFiles/Equations/climate_emissions.mod`

### Change 4a — Add `E_ETS_{reg}` regional aggregation

**Location:** After the `E_{reg}` aggregation block (after line 23), before the subsidy block.

**Old text:**
```
    [name = 'regional emissions']
    (lhsAggReg_@{reg}_25+1)/(rhsAggReg_@{reg}_25+1) = 1;

    #lhsSubsidies_@{reg} = tauS_@{reg} * 
```
**New text:**
```
    [name = 'regional emissions']
    (lhsAggReg_@{reg}_25+1)/(rhsAggReg_@{reg}_25+1) = 1;

    #lhsAggReg_@{reg}_ETS = E_ETS_@{reg};
    #rhsAggReg_@{reg}_ETS = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_ETS_@{subsec}_@{reg}
                @# for secm in 1:Sectors
                    + E_I_ETS_@{subsec}_@{reg}_@{secm}
                @# endfor
            @# endfor
        @# endfor
    ;
    [name = 'regional ETS-covered emissions']
    (lhsAggReg_@{reg}_ETS+1)/(rhsAggReg_@{reg}_ETS+1) = 1;

    #lhsSubsidies_@{reg} = tauS_@{reg} * 
```

### Change 4b — Use `E_ETS_{reg}` in subsidy benchmark

**Old text:**
```
    #rhsSubsidies_@{reg} = exo_tauS_@{reg} * PE_@{reg} * E_@{reg};
```
**New text:**
```
    #rhsSubsidies_@{reg} = exo_tauS_@{reg} * PE_@{reg} * E_ETS_@{reg};
```

### Change 4c — Use `E_ETS_{reg}` in cap constraint (CapandTrade == 1 branch)

**Old text:**
```
        #lhsEmissionPrice_@{reg} = E_@{reg} + (exo_PE_@{reg} + exo_PE+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = E0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});   
```
**New text:**
```
        #lhsEmissionPrice_@{reg} = E_ETS_@{reg} + (exo_PE_@{reg} + exo_PE+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = E_ETS0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});   
```

---

## File 5: `ModFiles/Equations/government.mod`

### Change 5a — Government budget constraint: `E_{reg}` → `E_ETS_{reg}`

**Old text:**
```
    #rhsAggReg_@{reg}_27 = tauC_@{reg} * P_@{reg} * C_@{reg} + IH_@{reg} * PH_@{reg} * tauH_@{reg} + PE_@{reg} * E_@{reg}
```
**New text:**
```
    #rhsAggReg_@{reg}_27 = tauC_@{reg} * P_@{reg} * C_@{reg} + IH_@{reg} * PH_@{reg} * tauH_@{reg} + PE_@{reg} * E_ETS_@{reg}
```

### Change 5b — Transfers: `E_{reg}` → `E_ETS_{reg}`

**Old text:**
```
    #rhsAggReg_@{reg}_28 = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_@{reg};
```
**New text:**
```
    #rhsAggReg_@{reg}_28 = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_ETS_@{reg};
```

---

## File 6: `ModFiles/Equations_display/firms.mod`

Apply the **same changes as File 3** but using `lhs = rhs;` syntax instead of `(lhs+1)/(rhs+1) = 1;`.

The `mcp` tags on FOC capital (line 76) and FOC labour (line 82) must be preserved:
```
[name = 'Firms FOC capital',mcp = 'K_@{subsec}_@{reg} > 0']
[name = 'Firms FOC labour @{subsec} @{reg}',mcp = 'N_@{subsec}_@{reg} > 0']
```

Specific equation syntax for new equations in display file:

**E_I_ETS equation (Change 3e equivalent):**
```
                [name = 'ETS-covered intermediate emissions subsector s from sector k']
                E_I_ETS_@{subsec}_@{reg}_@{secm} = xi_I_@{subsec}_@{reg}_@{secm} * E_I_@{subsec}_@{reg}_@{secm};
```

**E_ETS equation (Change 3f equivalent):**
```
            [name = 'ETS-covered direct emissions in subsector s region r']
            E_ETS_@{subsec}_@{reg} = xi_@{subsec}_@{reg} * E_@{subsec}_@{reg};
```

All other changes (3a–3d) mirror Files 3 exactly (the `#` auxiliary definitions are identical; only the final equation lines change syntax).

---

## File 7: `ModFiles/Equations_display/climate_emissions.mod`

Apply the **same changes as File 4** but using `lhs = rhs;` syntax.

**Change 4a equivalent** — E_ETS aggregation equation:
```
    [name = 'regional ETS-covered emissions']
    E_ETS_@{reg} = rhsAggReg_@{reg}_ETS;
```

**Change 4b equivalent:**
```
    #rhsSubsidies_@{reg} = exo_tauS_@{reg} * PE_@{reg} * E_ETS_@{reg};
```
(The `#` auxiliary definition is identical; the equation below it uses `lhs = rhs` form.)

**Change 4c equivalent:**
```
        #lhsEmissionPrice_@{reg} = E_ETS_@{reg} + (exo_PE_@{reg} + exo_PE+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = E_ETS0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});   
```

---

## File 8: `ModFiles/Equations_display/government.mod`

Apply the **same changes as File 5** — the syntax is already `lhs = rhs` style in government.mod equations but verify the exact form in the display file.

**Change 5a equivalent:**
```
    #rhsAggReg_@{reg}_27 = tauC_@{reg} * P_@{reg} * C_@{reg} + IH_@{reg} * PH_@{reg} * tauH_@{reg} + PE_@{reg} * E_ETS_@{reg}
```

**Change 5b equivalent:**
```
    #rhsAggReg_@{reg}_28 = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_ETS_@{reg};
```

---

## File 9: `Functions/SteadyState/setupInitialState/compute_emissions_and_aggregate_output.m`

### Change 9a — Initialize `E_ETS_{reg}` counter

**Old text:**
```
        strys.(['E_' sreg]) = 0;
```
**New text:**
```
        strys.(['E_' sreg]) = 0;
        strys.(['E_ETS_' sreg]) = 0;
```

### Change 9b — Compute `E_ETS_{subsec}_{reg}` and accumulate into `E_ETS_{reg}`

**Old text:**
```
                % Add direct emissions
                strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_' ssubsec '_' sreg]);

                % Add emissions from intermediate input use
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]);
                end
```
**New text:**
```
                % Add direct emissions
                strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_' ssubsec '_' sreg]);

                % Compute ETS-covered direct emissions
                xi_ss = strpar.(['xi0_' ssubsec '_' sreg '_p']);
                strys.(['E_ETS_' ssubsec '_' sreg]) = xi_ss * strys.(['E_' ssubsec '_' sreg]);
                strys.(['E_ETS_' sreg]) = strys.(['E_ETS_' sreg]) + strys.(['E_ETS_' ssubsec '_' sreg]);

                % Add emissions from intermediate input use
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]);

                    % Compute ETS-covered intermediate emissions
                    xi_I_ss = strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecm '_p']);
                    strys.(['E_I_ETS_' ssubsec '_' sreg '_' ssecm]) = xi_I_ss * strys.(['E_I_' ssubsec '_' sreg '_' ssecm]);
                    strys.(['E_ETS_' sreg]) = strys.(['E_ETS_' sreg]) + strys.(['E_I_ETS_' ssubsec '_' sreg '_' ssecm]);
                end
```

### Change 9c — Write `E_ETS0_{reg}_p` back to `M_.params` after region loop

**Location:** After the first region loop (after line 59, `strys.E = strys.E + strys.(['E_' sreg]);`), before the second region loop (`for icoreg = 1:strpar.inbregions_p` starting line 61).

**Old text:**
```
        % Add regional emissions to national total
        strys.E = strys.E + strys.(['E_' sreg]);
    end

    for icoreg = 1:strpar.inbregions_p
```
**New text:**
```
        % Add regional emissions to national total
        strys.E = strys.E + strys.(['E_' sreg]);

        % Write back E_ETS0 parameter
        if isfield(strpar, 'M_')
            ipos = strcmp(strpar.M_.param_names, ['E_ETS0_' sreg '_p']);
            if any(ipos)
                strpar.M_.params(ipos) = strys.(['E_ETS_' sreg]);
            end
        end
    end

    for icoreg = 1:strpar.inbregions_p
```

### Change 9d — Remove `sF_` from `Q_A_I` computation (second region loop)

**Old text:**
```
                strys.(['Q_A_I_' ssec '_' sreg]) = strys.(['Q_A_I_' ssec '_' sreg]) + strys.(['Q_I_' ssubsec '_' sreg '_' ssec]) * (strys.(['P_A_' ssec '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p'])*strys.(['sF_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p'])* strys.(['PE_' sreg])) / strys.(['P_A_' ssec '_' sreg]);
```
**New text:**
```
                strys.(['Q_A_I_' ssec '_' sreg]) = strys.(['Q_A_I_' ssec '_' sreg]) + strys.(['Q_I_' ssubsec '_' sreg '_' ssec]) * (strys.(['P_A_' ssec '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssec '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p'])* strys.(['PE_' sreg])) / strys.(['P_A_' ssec '_' sreg]);
```

---

## File 10: `Functions/SteadyState/setupInitialState/compute_pf_parameters.m`

### Change 10a — Remove `sF_` from `kappaEI` calibration (line ~261)

**Old text:**
```
                    strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) = (strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.E0_p) / (strys.(['sF_' sreg])*(strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm])-strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]))/strys.(['P_A_' ssecm '_' sreg]));
```
**New text:**
```
                    strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) = (strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.E0_p) / ((strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm])-strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]))/strys.(['P_A_' ssecm '_' sreg]));
```

### Change 10b — Replace `sF_` with `xi0_I_p` in first `PAgrosstemp` (line ~262)

**Old text:**
```
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
                    tempdenom = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecm]))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm']);        
```
**New text:**
```
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['PE_' sreg]);
                    tempdenom = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecm]))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm']);        
```

### Change 10c — Replace `sF_` in inner `secn` loop `PAgrosstemp` (line ~267)

**Old text:**
```
                        PAgrosstemp = strys.(['P_A_' ssecn '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecn '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
```
**New text:**
```
                        PAgrosstemp = strys.(['P_A_' ssecn '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecn '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecn '_p']) * strys.(['PE_' sreg]);
```

### Change 10d — Replace `sF_` in final `PAgrosstemp` for `P_I` computation (line ~275)

**Old text:**
```
                    PAgrosstemp = (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]))/strys.(['A_I_' ssubsec '_' sreg '_' ssecm']);
```
**New text:**
```
                    PAgrosstemp = (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['PE_' sreg]))/strys.(['A_I_' ssubsec '_' sreg '_' ssecm']);
```

### Change 10e — Replace `sF_` in second calibration path Q_I (line ~561)

**Old text:**
```
                    strys.(['Q_I_' stemp '_' ssecm]) = strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']) * ...
                        strys.(['QIEXP_' ssubsec '_' sreg]) / ...
                        (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' stemp '_' ssecm '_p']) * strys.(['sF_' sreg]) * ...
                         strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]));
```
**New text:**
```
                    strys.(['Q_I_' stemp '_' ssecm]) = strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']) * ...
                        strys.(['QIEXP_' ssubsec '_' sreg]) / ...
                        (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' stemp '_' ssecm '_p']) * strpar.(['xi0_I_' stemp '_' ssecm '_p']) * ...
                         strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]));
```

### Change 10f — Remove `sF_` from `E_I` computation (line ~564)

**Old text:**
```
                    strys.(['E_I_' stemp '_' ssecm]) = strys.(['Q_I_' stemp '_' ssecm]) * ...
                        strpar.(['kappaEI_' stemp '_' ssecm '_p']) * strys.(['sF_' sreg]);
```
**New text:**
```
                    strys.(['E_I_' stemp '_' ssecm]) = strys.(['Q_I_' stemp '_' ssecm]) * ...
                        strpar.(['kappaEI_' stemp '_' ssecm '_p']);
```

---

## File 11: `Functions/SteadyState/compute_production_factors_and_output.m`

### Change 11a — Remove `sF_` from `PAgrosstemp` (line ~224)

**Old text:**
```
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg]) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
```
**New text:**
```
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecm '_p']) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
```

### Change 11b — Remove `sF_` from `E_I` computation (line ~226)

**Old text:**
```
                    strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) = strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg])  * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strys.(['Q_I_' ssubsec '_' sreg '_' ssecm]);
```
**New text:**
```
                    strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) = strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strys.(['Q_I_' ssubsec '_' sreg '_' ssecm]);
```

---

## File 12: `Functions/SteadyState/computeCapital/compute_regional_price_indexes.m`

### Change 12a — Remove `sF_` from `PEtemp` (line ~122)

**Old text:**
```
                    PEtemp = + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg]) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
```
**New text:**
```
                    PEtemp = + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['xi0_I_' ssubsec '_' sreg '_' ssecm '_p']) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
```

---

## File 13: `Functions/SteadyState/computeCapital/initialize_sectoral_aggregation.m`

### Change 13a — Remove `sF_` from `PAgrosstemp` (lines ~33–38)

**Old text:**
```
                    % Adjusted price including emissions cost
                    PAgrosstemp = strys.(['P_A_' ssec '_' sreg]) + ...
                        strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p']) * ...
                        strys.(['sF_' sreg]) * ...
                        exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssec])) * ...
                        strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                        strys.(['PE_' sreg]);
```
**New text:**
```
                    % Adjusted price including emissions cost
                    PAgrosstemp = strys.(['P_A_' ssec '_' sreg]) + ...
                        strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p']) * ...
                        strpar.(['xi0_I_' ssubsec '_' sreg '_' ssec '_p']) * ...
                        exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssec])) * ...
                        strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                        strys.(['PE_' sreg]);
```

---

## File 14: `Functions/SteadyState/assign_predetermined_variables.m`

### Change 14a — Use `E_ETS0_{reg}_p` in subsidy initial value

**Old text:**
```
            strys.(['SE_' sreg]) = strexo.(['exo_tauS_' sreg]) * strpar.phitauS_p * strpar.(['E0_' sreg '_p']) * strys.(['PE_' sreg]);
```
**New text:**
```
            strys.(['SE_' sreg]) = strexo.(['exo_tauS_' sreg]) * strpar.phitauS_p * strpar.(['E_ETS0_' sreg '_p']) * strys.(['PE_' sreg]);
```

---

## File 15: `Functions/Miscellaneous/ModelSetup/define_auxiliary_expressions_looped.m`

### Change 15a — Add `exo_xi_` and `exo_xi_I_` shock entries

**Location:** After line 98 (`'exo_PE_'` entry).

**Old text:**
```
    'exo_PE_',    [inbregions_p, 0, 0], 'exo',  'casPERegShocks',    'lSelectPERegShocks',    'iposPERegShocks'
    'E_',         [inbregions_p, 0, 0], 'endo', 'casEReg',           'lSelectEReg',           'iposEReg'
```
**New text:**
```
    'exo_PE_',    [inbregions_p, 0, 0], 'exo',  'casPERegShocks',    'lSelectPERegShocks',    'iposPERegShocks'
    'exo_xi_',    [imaxsec_p, inbregions_p, 0], 'exo', 'casXiShocks',    'lSelectXiShocks',    'iposXiShocks'
    'exo_xi_I_',  [imaxsec_p, inbregions_p, inbsectors_p], 'exo', 'casXiIShocks3d', 'lSelectXiIShocks', 'iposXiIShocks'
    'E_',         [inbregions_p, 0, 0], 'endo', 'casEReg',           'lSelectEReg',           'iposEReg'
```

### Change 15b — Add `E_ETS_` regional endogenous entry

**Location:** After line 99 (`'E_'` entry).

**Old text:**
```
    'E_',         [inbregions_p, 0, 0], 'endo', 'casEReg',           'lSelectEReg',           'iposEReg'
    'EE_',        [inbregions_p, 0, 0], 'endo', 'casEEReg',          'lSelectEEReg',          'iposEEReg'
```
**New text:**
```
    'E_',         [inbregions_p, 0, 0], 'endo', 'casEReg',           'lSelectEReg',           'iposEReg'
    'E_ETS_',     [inbregions_p, 0, 0], 'endo', 'casETSEReg',        'lSelectETSEReg',        'iposETSEReg'
    'EE_',        [inbregions_p, 0, 0], 'endo', 'casEEReg',          'lSelectEEReg',          'iposEEReg'
```

---

## File 16: `Functions/simulation_model_refactored.m`

### Change 16a — Add xi stepping blocks after existing PE stepping block

**Location:** After the `iposPERegShocks` stepping block (lines 471–477), before `end` closing the stepping function.

**Old text:**
```
        if lCapandTrade_p == 1
            oo_.exo_simul(:, posIdx.iposERegShocks) = oo_.exo_base(:, posIdx.iposERegShocks).*(1 - stepFrac) + ...
                                                      oo_.exo_simul_start(:, posIdx.iposERegShocks).*stepFrac;
        else
            oo_.exo_simul(:, posIdx.iposPERegShocks) = oo_.exo_base(:, posIdx.iposPERegShocks).*(1 - stepFrac) + ...
                                                       oo_.exo_simul_start(:, posIdx.iposPERegShocks).*stepFrac;
        end
    end
    baseVars = [posIdx.iposPERegShocks,posIdx.iposkapEShock, posIdx.iposEERegShocks,...
```
**New text:**
```
        if lCapandTrade_p == 1
            oo_.exo_simul(:, posIdx.iposERegShocks) = oo_.exo_base(:, posIdx.iposERegShocks).*(1 - stepFrac) + ...
                                                      oo_.exo_simul_start(:, posIdx.iposERegShocks).*stepFrac;
        else
            oo_.exo_simul(:, posIdx.iposPERegShocks) = oo_.exo_base(:, posIdx.iposPERegShocks).*(1 - stepFrac) + ...
                                                       oo_.exo_simul_start(:, posIdx.iposPERegShocks).*stepFrac;
        end
        if ~isempty(posIdx.iposXiShocks)
            oo_.exo_simul(:, posIdx.iposXiShocks) = oo_.exo_base(:, posIdx.iposXiShocks) .* (1 - stepFrac) + ...
                                                     oo_.exo_simul_start(:, posIdx.iposXiShocks) .* stepFrac;
        end
        if ~isempty(posIdx.iposXiIShocks)
            oo_.exo_simul(:, posIdx.iposXiIShocks) = oo_.exo_base(:, posIdx.iposXiIShocks) .* (1 - stepFrac) + ...
                                                      oo_.exo_simul_start(:, posIdx.iposXiIShocks) .* stepFrac;
        end
    end
    baseVars = [posIdx.iposPERegShocks,posIdx.iposkapEShock, posIdx.iposEERegShocks,...
```

### Change 16b — Add xi shocks to `baseVars`

**Old text:**
```
    baseVars = [posIdx.iposPERegShocks,posIdx.iposkapEShock, posIdx.iposEERegShocks,...
            posIdx.iposUShocks, posIdx.iposPVShocks, posIdx.iposKGShocks, posIdx.iposrGShocks ,...
            posIdx.iposphiKShocks, posIdx.iposTauSShocks, posIdx.iposkapEShock];
```
**New text:**
```
    baseVars = [posIdx.iposPERegShocks,posIdx.iposkapEShock, posIdx.iposEERegShocks,...
            posIdx.iposUShocks, posIdx.iposPVShocks, posIdx.iposKGShocks, posIdx.iposrGShocks ,...
            posIdx.iposphiKShocks, posIdx.iposTauSShocks, posIdx.iposkapEShock, ...
            posIdx.iposXiShocks, posIdx.iposXiIShocks];
```

---

## File 17: `scripts/analysis/check_results.m`

### Change 17a — Use `E_ETS_1` for revenue computation

**Old text:**
```
    plot(ds.Year(1:Tplot),ds.PE_1(1:Tplot).*ds.E_1(1:Tplot)./(ds.Q_1(1:Tplot)-ds.Q_I_1(1:Tplot)).*100, sline); hold on;
```
**New text:**
```
    plot(ds.Year(1:Tplot),ds.PE_1(1:Tplot).*ds.E_ETS_1(1:Tplot)./(ds.Q_1(1:Tplot)-ds.Q_I_1(1:Tplot)).*100, sline); hold on;
```

---

## File 18: `scripts/reporting/simulation_results_financial_instruments.m`

### Change 18a — Use `E_ETS_1` for revenue computation

**Old text:**
```
    revenues = ds.PE_1 .* ds.E_1 ./ (ds.Q_1 - ds.Q_I_1) * 100;
```
**New text:**
```
    revenues = ds.PE_1 .* ds.E_ETS_1 ./ (ds.Q_1 - ds.Q_I_1) * 100;
```

---

## File 19: `Functions/Miscellaneous/Diagnostics/diagnostics_crash.m`

### Change 19a — Use `E_ETS_1` in GDP accounting check

**Old text:**
```
rhsdefgdp = PE_1(time_vec) .* E_1(time_vec) + Y_1(time_vec);
```
**New text:**
```
rhsdefgdp = PE_1(time_vec) .* E_ETS_1(time_vec) + Y_1(time_vec);
```

---

## Implementation Order

Apply changes in this order to avoid Dynare compilation failures:

1. **Declaration.mod** (File 1) — declare all new variables, exogenous, and parameters first
2. **Parameters.mod** (File 2) — initialize new parameters before compile
3. **Equations/firms.mod** (File 3) — main equation changes
4. **Equations/climate_emissions.mod** (File 4)
5. **Equations/government.mod** (File 5)
6. **Equations_display/firms.mod** (File 6)
7. **Equations_display/climate_emissions.mod** (File 7)
8. **Equations_display/government.mod** (File 8)
9. **compute_emissions_and_aggregate_output.m** (File 9)
10. **compute_pf_parameters.m** (File 10)
11. **compute_production_factors_and_output.m** (File 11)
12. **compute_regional_price_indexes.m** (File 12)
13. **initialize_sectoral_aggregation.m** (File 13)
14. **assign_predetermined_variables.m** (File 14)
15. **define_auxiliary_expressions_looped.m** (File 15)
16. **simulation_model_refactored.m** (File 16)
17. **scripts/analysis/check_results.m** (File 17)
18. **scripts/reporting/simulation_results_financial_instruments.m** (File 18)
19. **diagnostics_crash.m** (File 19)

---

## Backward Compatibility Verification

With all changes applied and default values (`xi0_p = 1.0`, `xi0_I_p = 1.0`, all `exo_xi = 0`):

- `xi_@{subsec}_@{reg} = 1.0` → emission cost in FOCs unchanged from baseline
- `E_ETS_@{subsec}_@{reg} = E_@{subsec}_@{reg}` → covered = total at baseline
- `E_I_ETS_@{subsec}_@{reg}_@{secm} = E_I_@{subsec}_@{reg}_@{secm}` → covered = total
- `E_ETS_@{reg} = E_@{reg}` → regional covered = regional total
- `E_ETS0_{reg}_p` is overwritten at steady state to equal `E0_{reg}_p`
- `kappaEI` is recalibrated to absorb the removed `sF_` factor, so `E_I` values are unchanged

The model is **numerically identical** to the pre-change baseline when all coverage rates are at their defaults.
