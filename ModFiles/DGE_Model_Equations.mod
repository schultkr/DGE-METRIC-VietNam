% =============================
% === Declare Model Equations =
% =============================

predetermined_variables
@# for reg in 1:Regions
    B_@{reg}
    @# if Regions > 1
        @# for regm in 1:Regions
            B_@{reg}_@{regm}
        @# endfor
    @# endif
@# endfor
;

model;

// =======================
// Block 1: Expectations =
// =======================
@#include "ModFiles/Equations/expectations.mod"

// =====================
// Block 2: Identities =
// =====================
@#include "ModFiles/Equations/identities.mod"

// ==========================================
// Block 3 & 4: Regional Identities & Demographics
// ==========================================
@#include "ModFiles/Equations/regional_identities_demographics.mod"

// ==========================================
// Block 5: Rest of the World
// ==========================================
@#include "ModFiles/Equations/rest_of_world.mod"

// ==========================================
// Block 6: Households
// ==========================================
@#include "ModFiles/Equations/households.mod"

// ==========================================
// Block 7: Government
// ==========================================
@#include "ModFiles/Equations/government.mod"

// ==========================================
// Block 8: Productivity and damages
// ==========================================
@#include "ModFiles/Equations/productivity_damages.mod"

// ==========================================
// Block 9: Retailers
// ==========================================
@#include "ModFiles/Equations/retailers.mod"

// ==========================================
// Block 10: Wholesalers
// ==========================================
@#include "ModFiles/Equations/wholesalers.mod"

// ==========================================
// Block 11: Firms
// ==========================================
@#include "ModFiles/Equations/firms.mod"

// ==========================================
// Block 12: Climate Variables and Emissions
// ==========================================
@#include "ModFiles/Equations/climate_emissions.mod"

// ==========================================
// Block 13: Resource Constraints
// ==========================================
@#include "ModFiles/Equations/resource_constraints.mod"

// ==========================================
// Block 14: Investment-to-GDP wedge
// ==========================================
@#include "ModFiles/Equations/investment_wedge.mod"

end;

