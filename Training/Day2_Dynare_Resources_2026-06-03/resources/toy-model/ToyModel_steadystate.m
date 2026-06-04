
function [ys, params, check] = ToyModel_steadystate(ys, exo, M_, options_)
% Computes the steady state for the Toy Model in Dynare format
% Now solves for all endogenous variables in a single fsolve call
% Inputs:
%   ys: initial guess for steady state (vector)
%   exo: exogenous variables (vector)
%   M_: Dynare model structure
%   options_: Dynare options structure
% Outputs:
%   ys: steady state vector (ordered as in the .mod file)
%   params: parameter vector
%   check: 0 if successful, 1 if failed

sp.Init = [];
for ii = 1:M_.param_nbr
	paramname = M_.param_names{ii};
	sp.(paramname) = M_.params(ii);
end

se.Init = [];
for ii = 1:M_.exo_nbr
	exoname = M_.exo_names{ii};
	se.(exoname) = exo(ii);
end

params = M_.params;
check = 0;

L = sp.Lbar;
E_D = sp.ED_bar + se.e_d_shock;
E_C = sp.EC_bar + se.e_c_shock;
E   = E_D + E_C;

% 1. Compute steady state rental rate from Euler equation
r_ss = 1/sp.beta + sp.delta - 1;

% 2. Solve for all endogenous variables in one system

%(K^(sp.rho-1)) * (sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho - 1);

%(r_ss / (sp.A * sp.alpha_K))^()
%MPK = sp.A * sp.alpha_K * (K^(sp.rho-1)) * (sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho - 1);


% Variables: [K, Y, C, I, w, p_E]
guess_vec = [10; 10; 5; 1; 1; 1]; % [K, Y, C, I, w, p_E] initial guesses
%options_fsolve = optimset('Display','off');

%r   = A * sp.alpha_K * (K^(rho-1)) * (alpha_K*K^rho + alpha_L*Lbar^rho + alpha_E*E^rho)^((1 - rho)/rho);
%(r/(A * sp.alpha_K))^(rho/(1 - rho)) - alpha_K = alpha_L*(Lbar/K)^rho + alpha_E*(E/K)^rho

numerator = (r_ss/(sp.A * sp.alpha_K))^(sp.rho/(1 - sp.rho)) - sp.alpha_K;
denominator = sp.alpha_L*(L)^sp.rho + sp.alpha_E*(E)^sp.rho;

K = (numerator/denominator)^(-1/sp.rho);

I = sp.delta*K;

Y = sp.A*(sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho);
C = Y-I;
% Wage (marginal product of labor)
w = sp.A * sp.alpha_L * (L^(sp.rho-1)) * (sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho - 1);

% Energy price (marginal product of energy)
pE = sp.A * sp.alpha_E * (E^(sp.rho-1)) * (sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho - 1);



% 3. Assemble steady state vector in order of var in .mod file
ys = [Y; C; I; K; E; E_D; E_C; r_ss; w; pE];

% Optionally, save to .mat file for inspection
save('ToyModel_steadystate.mat', 'ys', 'params');

end

% function F = steady_state_system(x, sy, sp, L, E, r_ss)
% 	% x = [K, Y, C, I, w, p_E]
% 	K   = x(1);
% 	Y   = x(2);
% 	C   = x(3);
% 	I   = x(4);
% 	w   = x(5);
% 	p_E = x(6);
% 
% 	% Production function
% 	Y_calc = sp.A*(sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho);
% 
% 	% Capital FOC (Euler): marginal product = r_ss
% 	MPK = sp.A * sp.alpha_K * (K^(sp.rho-1)) * (sp.alpha_K*K^sp.rho + sp.alpha_L*L^sp.rho + sp.alpha_E*E^sp.rho)^(1/sp.rho - 1);
% 
% 
% 	% Resource constraint
% 
% 	F = [F1; F2; F3; F4; F5; F6];
% end
