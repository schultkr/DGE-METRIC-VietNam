function config = get_pdp8_target_investment_config(repoRoot, calibrationVersion)
% GET_PDP8_TARGET_INVESTMENT_CONFIG  Shared inputs for PDP8 target-I/Y paths.
%
% config = get_pdp8_target_investment_config(repoRoot, calibrationVersion)
%
% `calibrationVersion` is the filename suffix used by the active model
% variant, for example "_replication". Keeping the GDP anchor, default
% method, and legacy IndexProxy scaling here prevents the maintenance
% scripts from silently drifting apart.

if nargin < 1 || isempty(repoRoot)
    error('get_pdp8_target_investment_config:MissingRepoRoot', ...
        'repoRoot is required.');
end
if nargin < 2
    calibrationVersion = "";
end

config.projectedGDPBaseYear = 2025;
config.projectedGDPBaseValueMioUSD = 514700;
config.projectedGDPSource = ...
    'World Bank NY.GDP.MKTP.CD, Vietnam, accessed 2026-07-27';
config.defaultMethod = 'CapitalStock';

% Legacy IndexProxy base-year capital/GDP assumptions. These are retained
% only for reproducibility when DGE_TARGET_IY_METHOD=IndexProxy.
config.indexProxyBaseCapitalShareFossil = 0.025;
config.indexProxyBaseCapitalShareRenewable = 0.005;

config.calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', ...
    "ModelCalibration5Sectorsand1Regions" + string(calibrationVersion) + ".xlsx");
end
