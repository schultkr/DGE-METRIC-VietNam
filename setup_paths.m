function setup_paths()
% setup_paths  Add project MATLAB source folders to the path.
%
% Run from anywhere inside the repository:
%   setup_paths

repoRoot = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(repoRoot, 'Functions')));
addpath(genpath(fullfile(repoRoot, 'ModFiles')));
addpath(repoRoot);

dynarePaths = { ...
    'C:\dynare\7.0\matlab', ...
    'C:\dynare\6.1\matlab' ...
};

dynareFound = false;
for iPath = 1:numel(dynarePaths)
    if isfolder(dynarePaths{iPath})
        addpath(dynarePaths{iPath});
        dynareFound = true;
        break
    end
end

if ~dynareFound
    warning('setup_paths:DynareNotFound', ...
        ['Dynare was not found at either of the expected locations:\n' ...
         '  %s\n  %s\n' ...
         'If Dynare is installed elsewhere, addpath the folder containing ' ...
         'dynare.m manually before running simulations.'], ...
        dynarePaths{1}, dynarePaths{2});
end
end
