%% Run all Online Training comparison scripts (Day 1 scenario set)

close all;

fprintf('\n[Online Training] Running PDP8 variants vs Baseline...\n');
run(fullfile(fileparts(mfilename('fullpath')), 'compare_online_training_pdp8_vs_baseline.m'));

fprintf('\n[Online Training] Running NZ variants vs NZ...\n');
run(fullfile(fileparts(mfilename('fullpath')), 'compare_online_training_nz_variants_vs_nz.m'));

fprintf('\n[Online Training] Running NZ variants vs Baseline...\n');
run(fullfile(fileparts(mfilename('fullpath')), 'compare_online_training_nz_variants_vs_baseline.m'));

fprintf('\n[Online Training] All comparison scripts completed.\n');
