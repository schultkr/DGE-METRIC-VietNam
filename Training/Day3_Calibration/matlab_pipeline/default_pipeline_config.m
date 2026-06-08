function cfg = default_pipeline_config(pipelineRoot)
%DEFAULT_PIPELINE_CONFIG Default paths for the MATLAB IO pipeline.

if nargin < 1 || strlength(string(pipelineRoot)) == 0
    pipelineRoot = fileparts(mfilename("fullpath"));
end

cfg = struct();
cfg.pipeline_root = char(pipelineRoot);

cfg.io_xlsx_path = fullfile(cfg.pipeline_root, "data", "raw", "IO-2019.xlsx");
cfg.tech_summary_csv = fullfile(cfg.pipeline_root, "data", "input", "tech_group_summary.csv");

cfg.split_output_xlsx = fullfile(cfg.pipeline_root, "data", "output", "IO-2019_utilities_split.xlsx");
cfg.split_output_csv = fullfile(cfg.pipeline_root, "data", "output", "IO-2019_utilities_split.csv");
cfg.split_summary_csv = fullfile(cfg.pipeline_root, "data", "output", "IO_2019_utilities_split_summary.csv");

cfg.oecd_xlsx = fullfile(cfg.pipeline_root, "data", "raw", "IO-2019.xlsx");

% Optional: set this to an existing DGE model workbook to update a copy.
cfg.dge_workbook = "";
cfg.dge_sheet = "IO_Data";

cfg.dge_output_xlsx = fullfile(cfg.pipeline_root, "data", "output", "IO_2019_5sec_for_DGE_IO_Data.xlsx");
cfg.dge_output_csv = fullfile(cfg.pipeline_root, "data", "output", "IO_2019_5sec_for_DGE_IO_Data.csv");
cfg.dge_validation_csv = fullfile(cfg.pipeline_root, "data", "output", "IO_2019_5sec_for_DGE_validation.csv");
cfg.dge_audit_csv = fullfile(cfg.pipeline_root, "data", "output", "IO_2019_5sec_for_DGE_audit.csv");
cfg.dge_output_workbook_copy = fullfile(cfg.pipeline_root, "data", "output", "ModelCalibration5Sectorsand1Regions_IO_Data_Replaced.xlsx");
end

