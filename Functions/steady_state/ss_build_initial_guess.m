function [xstart_vec, strys, strpar] = ss_build_initial_guess(strys, strexo, strpar, mode)
%SS_BUILD_INITIAL_GUESS Wrapper around build_initial_guess with clearer naming.
%
% This function exists to support the refactored steady-state interface in
% DGE_Model_steadystate.m without breaking existing code that calls
% the original build_initial_guess function in its old location.
%
% Inputs and outputs are identical to build_initial_guess.
%
% See also: build_initial_guess

[xstart_vec, strys, strpar] = build_initial_guess(strys, strexo, strpar, mode);

