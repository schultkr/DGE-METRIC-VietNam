function [Fval_vec, strys, strexo] = ss_compute_capital(x, strys, strexo, strpar)
%SS_COMPUTE_CAPITAL Wrapper around compute_capital with clearer naming.
%
% This function exists to support the refactored steady-state interface in
% DGE_Model_steadystate.m without breaking existing code that calls
% the original compute_capital function in its old location.
%
% Inputs and outputs are identical to compute_capital.
%
% See also: compute_capital

[Fval_vec, strys, strexo] = compute_capital(x, strys, strexo, strpar);

