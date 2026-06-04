function [Feval, strpar, strys] = ss_setup_initial_state(x, strys, strexo, strpar)
%SS_SETUP_INITIAL_STATE Wrapper around setup_initial_state with clearer naming.
%
% This function exists to support the refactored steady-state interface in
% DGE_Model_steadystate.m without breaking existing code that calls
% the original setup_initial_state function in its old location.
%
% Inputs and outputs are identical to setup_initial_state.
%
% See also: setup_initial_state

[Feval, strpar, strys] = setup_initial_state(x, strys, strexo, strpar);

