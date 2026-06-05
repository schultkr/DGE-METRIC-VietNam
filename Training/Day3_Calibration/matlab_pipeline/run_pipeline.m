function result = run_pipeline(configInput)
%RUN_PIPELINE Run the MATLAB recreation of the IO pipeline.

scriptDir = fileparts(mfilename("fullpath"));
addpath(scriptDir);

if nargin < 1 || isempty(configInput)
    cfg = default_pipeline_config(scriptDir);
elseif isstruct(configInput)
    cfg = configInput;
else
    cfg = load_pipeline_config(configInput);
end

fprintf("Running utilities split...\n");
splitResult = split_utilities_sector( ...
    cfg.io_xlsx_path, ...
    cfg.tech_summary_csv, ...
    cfg.split_output_xlsx, ...
    cfg.split_output_csv, ...
    cfg.split_summary_csv);

fprintf("Running 5-sector aggregation for DGE IO_Data...\n");
dgeResult = aggregate_for_dge( ...
    cfg.split_output_csv, ...
    cfg.oecd_xlsx, ...
    cfg.dge_workbook, ...
    cfg.dge_sheet, ...
    cfg.dge_output_xlsx, ...
    cfg.dge_output_csv, ...
    cfg.dge_validation_csv, ...
    cfg.dge_audit_csv, ...
    cfg.dge_output_workbook_copy);

fprintf("Pipeline complete.\n");
fprintf("Main output: %s\n", cfg.dge_output_csv);

result = struct("split", splitResult, "dge", dgeResult);
end

function cfg = load_pipeline_config(configInput)
configInput = char(configInput);
[configDir, configName, configExt] = fileparts(configInput);

if isempty(configName)
    error("Config path is empty.");
end

if isempty(configExt) && isempty(configDir)
    cfg = feval(configName);
    return;
end

if isempty(configDir)
    configDir = pwd;
end

oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(configDir);

cfg = feval(configName);
end

