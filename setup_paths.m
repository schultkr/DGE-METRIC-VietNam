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

for iPath = 1:numel(dynarePaths)
    if isfolder(dynarePaths{iPath})
        addpath(dynarePaths{iPath});
        break
    end
end
end
