function cfg = config_local_example()
%CONFIG_LOCAL_EXAMPLE Example config that updates an existing DGE workbook copy.

cfg = config_example();
projectRoot = fileparts(cfg.pipeline_root);
candidateWorkbook = fullfile(projectRoot, "data", "output", "ModelSimulationandCalibration5Sectorsand1Regions_IO_Data_Replaced.xlsx");

if isfile(candidateWorkbook)
    cfg.dge_workbook = candidateWorkbook;
else
    cfg.dge_workbook = "";
end
end

