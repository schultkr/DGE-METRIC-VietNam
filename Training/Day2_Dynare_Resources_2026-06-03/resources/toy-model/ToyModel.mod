// RBC-style Dynare model with CES production
// and exogenous dirty/clean energy shocks

var Y C I K E E_D E_C r w p_E;

varexo e_d_shock e_c_shock;

parameters A alpha_K alpha_L alpha_E rho eta beta delta Lbar ED_bar EC_bar;

// -----------------------------
// Parameter values
// -----------------------------
A       = 1;
alpha_K = 0.30;
alpha_L = 0.50;
alpha_E = 0.20;
eta = 2;
rho     = (eta -1)/eta;     % CES parameter rho = (eta_p - 1) / eta_p;
beta    = 0.96;     % discount factor
delta   = 0.08;     % depreciation rate
Lbar    = 10;       % fixed labor supply
ED_bar  = 0.75;        % steady-state dirty energy
EC_bar  = 0.25;        % steady-state clean energy

// -----------------------------
// Model
// -----------------------------

model;
    // Exogenous energy inputs
    E_D = ED_bar + e_d_shock;
    E_C = EC_bar + e_c_shock;
    E   = E_D + E_C;


    // CES production function
    Y = A*(alpha_K*K(-1)^rho + alpha_L*Lbar^rho + alpha_E*E^rho)^(1/rho);

    // Marginal products (rental rate, wage, energy price)
    r   = A * alpha_K * (K(-1)^(rho-1)) * (alpha_K*K(-1)^rho + alpha_L*Lbar^rho + alpha_E*E^rho)^(1/rho - 1);
    w   = A * alpha_L * (Lbar^(rho-1)) * (alpha_K*K(-1)^rho + alpha_L*Lbar^rho + alpha_E*E^rho)^(1/rho - 1);
    p_E = A * alpha_E * (E^(rho-1)) * (alpha_K*K(-1)^rho + alpha_L*Lbar^rho + alpha_E*E^rho)^(1/rho - 1);

    // Resource constraint
    Y = C + I;

    // Capital accumulation
    K = (1-delta)*K(-1) + I;

    // Euler equation (using rental rate)
    1/C = beta*(1/C(+1))*( r(+1) + 1 - delta );

end;

// -----------------------------
// Initial values
// -----------------------------
initval;
    e_d_shock = 0;
    e_c_shock = 0;
end;
steady;


endval;
    e_d_shock = -0.7;
    e_c_shock = 0.7;
end;
steady;

perfect_foresight_setup(periods = 500);
perfect_foresight_solver;