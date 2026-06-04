%
% Status : main Dynare file
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

clearvars -global
clear_persistent_variables(fileparts(which('dynare')), false)
tic0 = tic;
% Define global variables.
global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info
options_ = [];
M_.fname = 'rbc';
M_.dynare_version = '7.0';
oo_.dynare_version = '7.0';
options_.dynare_version = '7.0';
%
% Some global variables initialization
%
global_initialization;
M_.exo_names = cell(1,1);
M_.exo_names_tex = cell(1,1);
M_.exo_names_long = cell(1,1);
M_.exo_names(1) = {'e_z'};
M_.exo_names_tex(1) = {'e\_z'};
M_.exo_names_long(1) = {'e_z'};
M_.endo_names = cell(5,1);
M_.endo_names_tex = cell(5,1);
M_.endo_names_long = cell(5,1);
M_.endo_names(1) = {'c'};
M_.endo_names_tex(1) = {'c'};
M_.endo_names_long(1) = {'c'};
M_.endo_names(2) = {'k'};
M_.endo_names_tex(2) = {'k'};
M_.endo_names_long(2) = {'k'};
M_.endo_names(3) = {'l'};
M_.endo_names_tex(3) = {'l'};
M_.endo_names_long(3) = {'l'};
M_.endo_names(4) = {'y'};
M_.endo_names_tex(4) = {'y'};
M_.endo_names_long(4) = {'y'};
M_.endo_names(5) = {'z'};
M_.endo_names_tex(5) = {'z'};
M_.endo_names_long(5) = {'z'};
M_.endo_partitions = struct();
M_.param_names = cell(5,1);
M_.param_names_tex = cell(5,1);
M_.param_names_long = cell(5,1);
M_.param_names(1) = {'beta'};
M_.param_names_tex(1) = {'beta'};
M_.param_names_long(1) = {'beta'};
M_.param_names(2) = {'rho'};
M_.param_names_tex(2) = {'rho'};
M_.param_names_long(2) = {'rho'};
M_.param_names(3) = {'alpha'};
M_.param_names_tex(3) = {'alpha'};
M_.param_names_long(3) = {'alpha'};
M_.param_names(4) = {'delta'};
M_.param_names_tex(4) = {'delta'};
M_.param_names_long(4) = {'delta'};
M_.param_names(5) = {'sigma'};
M_.param_names_tex(5) = {'sigma'};
M_.param_names_long(5) = {'sigma'};
M_.param_partitions = struct();
M_.exo_det_nbr = 0;
M_.exo_nbr = 1;
M_.endo_nbr = 5;
M_.param_nbr = 5;
M_.orig_endo_nbr = 5;
M_.aux_vars = [];
M_.heterogeneity_aggregates = {
};
M_.database = {};
M_.Sigma_e = zeros(1, 1);
M_.Correlation_matrix = eye(1, 1);
M_.Skew_e = zeros(0, 4);
M_.H = 0;
M_.Correlation_matrix_ME = 1;
M_.sigma_e_is_diagonal = true;
M_.det_shocks = struct([]);
M_.surprise_shocks = struct([]);
M_.learnt_shocks = struct([]);
M_.learnt_endval = struct([]);
M_.shock_paths = struct([]);
M_.heteroskedastic_shocks.Qvalue_orig = struct([]);
M_.heteroskedastic_shocks.Qscale_orig = struct([]);
M_.matched_irfs = {};
M_.matched_irfs_weights = {};
M_.perfect_foresight_controlled_paths = struct([]);
options_.linear = false;
options_.block = false;
options_.bytecode = false;
options_.use_dll = false;
options_.ramsey_policy = false;
options_.discretionary_policy = false;
M_.eq_nbr = 5;
M_.ramsey_orig_eq_nbr = 0;
M_.ramsey_orig_endo_nbr = 0;
M_.set_auxiliary_variables = exist(['./+' M_.fname '/set_auxiliary_variables.m'], 'file') == 2;
M_.epilogue_names = {};
M_.epilogue_var_list_ = {};
M_.orig_maximum_endo_lag = 1;
M_.orig_maximum_endo_lead = 1;
M_.orig_maximum_exo_lag = 0;
M_.orig_maximum_exo_lead = 0;
M_.orig_maximum_exo_det_lag = 0;
M_.orig_maximum_exo_det_lead = 0;
M_.orig_maximum_lag = 1;
M_.orig_maximum_lead = 1;
M_.orig_maximum_lag_with_diffs_expanded = 1;
M_.lead_lag_incidence = [
 0 3 8;
 1 4 9;
 0 5 10;
 0 6 0;
 2 7 11;]';
M_.nstatic = 1;
M_.nfwrd   = 2;
M_.npred   = 0;
M_.nboth   = 2;
M_.nsfwrd   = 4;
M_.nspred   = 2;
M_.ndynamic   = 4;
M_.dynamic_tmp_nbr = [6; 0; 0; 0; ];
M_.equations_tags = {
  1 , 'name' , '1' ;
  2 , 'name' , '2' ;
  3 , 'name' , 'y' ;
  4 , 'name' , 'k' ;
  5 , 'name' , 'z' ;
};
M_.mapping.c.eqidx = [1 2 4 ];
M_.mapping.k.eqidx = [1 3 4 ];
M_.mapping.l.eqidx = [1 2 3 ];
M_.mapping.y.eqidx = [2 3 4 ];
M_.mapping.z.eqidx = [1 3 5 ];
M_.mapping.e_z.eqidx = [5 ];
M_.static_and_dynamic_models_differ = false;
M_.has_external_function = false;
M_.block_structure.time_recursive = false;
M_.block_structure.block(1).Simulation_Type = 1;
M_.block_structure.block(1).endo_nbr = 1;
M_.block_structure.block(1).mfs = 1;
M_.block_structure.block(1).equation = [ 5];
M_.block_structure.block(1).variable = [ 5];
M_.block_structure.block(1).is_linear = true;
M_.block_structure.block(1).bytecode_jacob_cols_to_sparse = [1 2 ];
M_.block_structure.block(2).Simulation_Type = 8;
M_.block_structure.block(2).endo_nbr = 4;
M_.block_structure.block(2).mfs = 3;
M_.block_structure.block(2).equation = [ 3 4 2 1];
M_.block_structure.block(2).variable = [ 4 2 3 1];
M_.block_structure.block(2).is_linear = false;
M_.block_structure.block(2).bytecode_jacob_cols_to_sparse = [1 0 4 5 6 7 8 9 ];
M_.block_structure.block(1).g1_sparse_rowval = int32([]);
M_.block_structure.block(1).g1_sparse_colval = int32([]);
M_.block_structure.block(1).g1_sparse_colptr = int32([]);
M_.block_structure.block(2).g1_sparse_rowval = int32([1 1 2 1 2 1 2 3 3 3 3 ]);
M_.block_structure.block(2).g1_sparse_colval = int32([1 4 4 5 5 6 6 6 7 8 9 ]);
M_.block_structure.block(2).g1_sparse_colptr = int32([1 2 2 2 4 6 9 10 11 12 ]);
M_.block_structure.variable_reordered = [ 5 4 2 3 1];
M_.block_structure.equation_reordered = [ 5 3 4 2 1];
M_.block_structure.incidence(1).lead_lag = -1;
M_.block_structure.incidence(1).sparse_IM = [
 4 2;
 5 5;
];
M_.block_structure.incidence(2).lead_lag = 0;
M_.block_structure.incidence(2).sparse_IM = [
 1 1;
 2 1;
 2 3;
 2 4;
 3 2;
 3 3;
 3 4;
 3 5;
 4 1;
 4 2;
 4 4;
 5 5;
];
M_.block_structure.incidence(3).lead_lag = 1;
M_.block_structure.incidence(3).sparse_IM = [
 1 1;
 1 2;
 1 3;
 1 5;
];
M_.block_structure.dyn_tmp_nbr = 8;
M_.maximum_lag = 1;
M_.maximum_lead = 1;
M_.maximum_endo_lag = 1;
M_.maximum_endo_lead = 1;
[~, ~, M_.state_var] = set_state_space(struct(), M_);
oo_.steady_state = zeros(5, 1);
M_.maximum_exo_lag = 0;
M_.maximum_exo_lead = 0;
oo_.exo_steady_state = zeros(1, 1);
M_.params = NaN(5, 1);
M_.endo_trends = struct('deflator', cell(5, 1), 'log_deflator', cell(5, 1), 'growth_factor', cell(5, 1), 'log_growth_factor', cell(5, 1));
M_.dynamic_g1_sparse_rowval = int32([4 5 1 2 4 3 4 2 3 2 3 4 3 5 1 1 1 1 5 ]);
M_.dynamic_g1_sparse_colval = int32([2 5 6 6 6 7 7 8 8 9 9 9 10 10 11 12 13 15 16 ]);
M_.dynamic_g1_sparse_colptr = int32([1 1 2 2 2 3 6 8 10 13 15 16 17 18 18 19 20 ]);
M_.lhs = {
'1/c'; 
'(1-alpha)*y/c'; 
'y'; 
'k'; 
'z'; 
};
M_.dynamic_mcp_equations_reordering = [1; 2; 3; 4; 5; ];
M_.static_tmp_nbr = [5; 1; 0; 0; ];
M_.block_structure_stat.block(1).Simulation_Type = 3;
M_.block_structure_stat.block(1).endo_nbr = 1;
M_.block_structure_stat.block(1).mfs = 1;
M_.block_structure_stat.block(1).equation = [ 5];
M_.block_structure_stat.block(1).variable = [ 5];
M_.block_structure_stat.block(2).Simulation_Type = 6;
M_.block_structure_stat.block(2).endo_nbr = 4;
M_.block_structure_stat.block(2).mfs = 4;
M_.block_structure_stat.block(2).equation = [ 2 3 4 1];
M_.block_structure_stat.block(2).variable = [ 4 2 1 3];
M_.block_structure_stat.variable_reordered = [ 5 4 2 1 3];
M_.block_structure_stat.equation_reordered = [ 5 2 3 4 1];
M_.block_structure_stat.incidence.sparse_IM = [
 1 1;
 1 2;
 1 3;
 1 5;
 2 1;
 2 3;
 2 4;
 3 2;
 3 3;
 3 4;
 3 5;
 4 1;
 4 2;
 4 4;
 5 5;
];
M_.block_structure_stat.tmp_nbr = 6;
M_.block_structure_stat.block(1).g1_sparse_rowval = int32([1 ]);
M_.block_structure_stat.block(1).g1_sparse_colval = int32([1 ]);
M_.block_structure_stat.block(1).g1_sparse_colptr = int32([1 2 ]);
M_.block_structure_stat.block(2).g1_sparse_rowval = int32([1 2 3 2 3 4 1 3 4 1 2 4 ]);
M_.block_structure_stat.block(2).g1_sparse_colval = int32([1 1 1 2 2 2 3 3 3 4 4 4 ]);
M_.block_structure_stat.block(2).g1_sparse_colptr = int32([1 4 7 10 13 ]);
M_.static_g1_sparse_rowval = int32([1 2 4 1 3 4 1 2 3 2 3 4 1 3 5 ]);
M_.static_g1_sparse_colval = int32([1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 ]);
M_.static_g1_sparse_colptr = int32([1 4 7 10 13 16 ]);
M_.static_mcp_equations_reordering = [1; 2; 3; 4; 5; ];
M_.params(1) = 0.99;
beta = M_.params(1);
M_.params(2) = 0.95;
rho = M_.params(2);
M_.params(3) = 0.36;
alpha = M_.params(3);
M_.params(4) = 0.025;
delta = M_.params(4);
M_.params(5) = 0.02;
sigma = M_.params(5);
%
% INITVAL instructions
%
options_.initval_file = false;
oo_.steady_state(1) = 1;
oo_.steady_state(2) = 10;
oo_.steady_state(3) = 0.3;
oo_.steady_state(4) = 1;
oo_.steady_state(5) = 0;
%
% SHOCKS instructions
%
M_.Sigma_e(1, 1) = (1)^2;
options_.irf = 20;
options_.order = 1;
var_list_ = {};
[info, oo_, options_, M_] = stoch_simul(M_, options_, oo_, var_list_);


oo_.time = toc(tic0);
disp(['Total computing time : ' dynsec2hms(oo_.time) ]);
if ~exist([M_.dname filesep 'Output'],'dir')
    mkdir(M_.dname,'Output');
end
save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'oo_', 'M_', 'options_');
if exist('estim_params_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'estim_params_', '-append');
end
if exist('bayestopt_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'bayestopt_', '-append');
end
if exist('dataset_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'dataset_', '-append');
end
if exist('estimation_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'estimation_info', '-append');
end
if exist('dataset_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'dataset_info', '-append');
end
if exist('oo_recursive_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'oo_recursive_', '-append');
end
if exist('options_mom_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'rbc_results.mat'], 'options_mom_', '-append');
end
if ~isempty(lastwarn)
  disp('Note: warning(s) encountered in MATLAB/Octave code')
end
