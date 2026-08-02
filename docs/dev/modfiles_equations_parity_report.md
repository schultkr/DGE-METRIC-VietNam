# ModFiles Parity Report (Equations vs Equations_display)

Date: 2026-06-03

## Scope

- Compared all shared .mod files under [ModFiles/Equations](ModFiles/Equations) and [ModFiles/Equations_display](ModFiles/Equations_display).
- Checked file presence, equation label coverage (`[name = '...']`), and exogenous switch token coverage (`exo_l...`).

## High-Level Result

- Shared files compared: 15
- Files only in Equations: 1
	- [ModFiles/Equations/investment_adjustment.mod](ModFiles/Equations/investment_adjustment.mod)
- Files only in Equations_display: 0

## Remaining Mismatches

1. [ModFiles/Equations/firms.mod](ModFiles/Equations/firms.mod) vs [ModFiles/Equations_display/firms.mod](ModFiles/Equations_display/firms.mod)
- Missing in display:
	- Firms FOC capital
	- Firms FOC labour @{subsec} @{reg}
- Extra in display:
	- SRI emission-intensity-based capital rental wedge

2. [ModFiles/Equations/households.mod](ModFiles/Equations/households.mod) vs [ModFiles/Equations_display/households.mod](ModFiles/Equations_display/households.mod)
- Missing in display:
	- HH FOC labour @{subsec} @{reg}
	- SRI emission-intensity-based capital rental wedge

3. [ModFiles/Equations/government.mod](ModFiles/Equations/government.mod) vs [ModFiles/Equations_display/government.mod](ModFiles/Equations_display/government.mod)
- Extra in display:
	- baseline sector specific public capital share

4. [ModFiles/Equations/private_investment.mod](ModFiles/Equations/private_investment.mod) vs [ModFiles/Equations_display/private_investment.mod](ModFiles/Equations_display/private_investment.mod)
- Missing in display:
	- Exogenous private capital s=@{subsec} r=@{reg}

## Notes

- Climate/emissions and investment_wedge parity items fixed earlier in this session are now aligned.

## Machine-Readable Output

- Full CSV output: [modfiles_equations_parity_report.csv](modfiles_equations_parity_report.csv)
