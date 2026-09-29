function setup_paths()
% setup_paths  Add project MATLAB source folders and Dynare to the path.
%
% Run from anywhere inside the repository:
%   setup_paths
%
% Dynare is located in this order:
%   1. the DGE_DYNARE_PATH environment variable (folder containing dynare.m,
%      e.g. C:\dynare\7.0\matlab), if set;
%   2. a dynare.m already on the MATLAB path;
%   3. the default install roots (C:\dynare\<version>\matlab on Windows,
%      /Applications/Dynare/<version>/matlab on macOS, /usr/lib/dynare/matlab
%      on Linux), trying the tested versions 7.0 and 6.1 first and then any
%      other installed version, newest first.

repoRoot = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(repoRoot, 'Functions')));
addpath(genpath(fullfile(repoRoot, 'ModFiles')));
addpath(repoRoot);

envDynarePath = strtrim(getenv('DGE_DYNARE_PATH'));
if ~isempty(envDynarePath)
    if isfile(fullfile(envDynarePath, 'dynare.m'))
        addpath(envDynarePath);
        return
    end
    warning('setup_paths:DynarePathInvalid', ...
        'DGE_DYNARE_PATH is set to "%s", but that folder does not contain dynare.m.', ...
        envDynarePath);
end

if ~isempty(which('dynare'))
    return
end

dynarePaths = find_default_dynare_paths();
for iPath = 1:numel(dynarePaths)
    if isfile(fullfile(dynarePaths{iPath}, 'dynare.m'))
        addpath(dynarePaths{iPath});
        return
    end
end

warning('setup_paths:DynareNotFound', ...
    ['Dynare was not found. Either set the environment variable DGE_DYNARE_PATH ' ...
     'to the folder containing dynare.m (e.g. C:\\dynare\\7.0\\matlab), or addpath ' ...
     'that folder manually before running simulations.']);
end

function dynarePaths = find_default_dynare_paths()
% Candidate Dynare matlab/ folders. The versions the published results were
% produced and tested with come first, so that installing a newer Dynare does
% not silently change the solver used; other installed versions follow,
% newest first.
testedVersions = {'7.0', '6.1'};
if ispc
    installRoots = {'C:\dynare'};
elseif ismac
    installRoots = {'/Applications/Dynare'};
else
    installRoots = {};
end

dynarePaths = {};
for iRoot = 1:numel(installRoots)
    versionDirs = dir(installRoots{iRoot});
    versionDirs = versionDirs([versionDirs.isdir] & ~startsWith({versionDirs.name}, '.'));
    versionNames = {versionDirs.name};
    for iTested = 1:numel(testedVersions)
        dynarePaths{end+1} = fullfile(installRoots{iRoot}, testedVersions{iTested}, 'matlab'); %#ok<AGROW>
    end
    versionNames = setdiff(versionNames, testedVersions, 'stable');
    [~, order] = sort(version_sort_keys(versionNames), 'descend');
    for iVersion = order
        dynarePaths{end+1} = fullfile(installRoots{iRoot}, versionNames{iVersion}, 'matlab'); %#ok<AGROW>
    end
end

if isunix && ~ismac
    dynarePaths{end+1} = '/usr/lib/dynare/matlab';
end
end

function keys = version_sort_keys(versionNames)
% Numeric sort key for folder names such as '6.1', '7.0' or '5.5-beta'.
keys = zeros(1, numel(versionNames));
for iName = 1:numel(versionNames)
    parts = regexp(versionNames{iName}, '\d+', 'match');
    parts = str2double(parts(1:min(3, numel(parts))));
    parts(end+1:3) = 0;
    keys(iName) = parts(1) * 1e6 + parts(2) * 1e3 + parts(3);
end
end
