function sversion = report_version_suffix(defaultSuffix)
% report_version_suffix  Filename suffix reporting scripts use for model files.
%
%   sversion = report_version_suffix()
%   sversion = report_version_suffix(defaultSuffix)
%
% Returns the workbook / output-CSV filename suffix (char) that RunSimulations.m
% appends via sSensitivity, e.g. '_replication_fix' -> ExcelFiles/Output/
% Baseline_replication_fix.csv and ExcelFiles/Model*5Sectorsand1Regions
% _replication_fix.xlsx. Mirrors the override logic in RunSimulations.m:
%
%   DGE_WORKBOOK_VERSION unset/empty  -> defaultSuffix ('_replication_fix')
%   DGE_WORKBOOK_VERSION=canonical    -> ''  (plain Baseline.csv etc.)
%   DGE_WORKBOOK_VERSION=<anything>   -> that literal suffix
%
% Keep the default here in sync with sSensitivity in RunSimulations.m so the
% reporting scripts read the same files the last simulation run wrote.

if nargin < 1 || isempty(defaultSuffix)
    defaultSuffix = '_replication_fix';
end

envWorkbookVersion = strtrim(getenv('DGE_WORKBOOK_VERSION'));
if strcmpi(envWorkbookVersion, 'canonical')
    sversion = '';
elseif ~isempty(envWorkbookVersion)
    sversion = envWorkbookVersion;
else
    sversion = defaultSuffix;
end
sversion = char(sversion);
end
