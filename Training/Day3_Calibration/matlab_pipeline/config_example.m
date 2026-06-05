function cfg = config_example()
%CONFIG_EXAMPLE Copy to config_local.m and edit paths if needed.

pipelineRoot = fileparts(mfilename("fullpath"));
cfg = default_pipeline_config(pipelineRoot);

% Optional workbook replacement:
% cfg.dge_workbook = "C:\path\to\ModelSimulationandCalibration5Sectorsand1Regions.xlsx";
% cfg.dge_sheet = "IO_Data";
end

