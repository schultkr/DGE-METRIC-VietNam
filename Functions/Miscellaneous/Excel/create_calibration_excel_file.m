% create_calibration_excel_file  Reproduce the current 5-sector/1-region
% calibration workbook as ModelCalibration5Sectorsand1Regions_replication.xlsx.
%
% The unsuffixed workbook is the reference output. This script deliberately
% does not read or copy that file: all workbook content is defined below (or
% by the existing Data-sheet helpers), so the replication is a real rebuild.

%% Configuration
clearvars;

sThisFolder = fileparts(mfilename('fullpath'));
sRepoRoot = char(java.io.File(fullfile(sThisFolder, '..', '..', '..')).getCanonicalPath());
sFunctionsFolder = fullfile(sRepoRoot, 'Functions');
sExcelFolder = fullfile(sRepoRoot, 'ExcelFiles');
addpath(genpath(sFunctionsFolder));

casSectors = {'Primary'; 'Energy'; 'Secondary'; 'Tertiary'};
casSubSectors = {'Primary'; 'Fossil'; 'Renewables'; 'Secondary'; 'Tertiary'};
casRegions = {'VNM'};
casClimateVarsRegionalName = {'surface temperature (Celsius)'};
casClimateVarsRegional = {'tas'};
casClimateVarsNationalName = {'Sea level'};
casClimateVarsNational = {'SL'};

inbsectors_p = numel(casSectors);
inbsubsectors_p = numel(casSubSectors);
inbregions_p = numel(casRegions);

sWorkBookName = sprintf('ModelCalibration%dSectorsand%dRegions_replication.xlsx', ...
    inbsubsectors_p, inbregions_p);
sExcelFileName = fullfile(sExcelFolder, sWorkBookName);

%% Build the sheet definitions
% Keep using the established helper for Data: it already reproduces the
% reference Data sheet and its 100 named cells exactly.
run(fullfile(sThisFolder, 'define_sheets_calibration.m'));
[~, iData] = ismember('Data', {strSheet.Name});
strData = strSheet(iData);

strIOData.Name = 'IO_Data';
strIOData.Description = 'a sheet containing input-output data and sectoral accounts';
strIOData.Categories = reference_io_data();

strStart.Name = 'Start';
strStart.Description = 'a sheet to assign values for the initial conditions';
strStart.Categories = reference_start_parameters();

strStructural.Name = 'Structural Parameters';
strStructural.Description = 'a sheet to assign values for structural parameters';
strStructural.Categories = reference_structural_parameters( ...
    inbregions_p, inbsubsectors_p, inbsectors_p);

strContent.Name = 'Content';
strContent.Description = '';
strContent.Categories = {
    'Sheets', '', '';
    'IO_Data', strIOData.Description, '';
    'Data', strData.Description, '';
    'Start', strStart.Description, '';
    'Structural Parameters', strStructural.Description, '';
    'Regions', '', '';
    1, 'VNM', '';
    'Subsectors', '', '';
    1, 'Primary', '';
    2, 'Fossil', '';
    3, 'Renewables', '';
    4, 'Secondary', '';
    5, 'Tertiary', ''
    };

% Content is intentionally last here because the established write logic
% rotates the final definition into the first workbook position.
strSheet = [strIOData, strData, strStart, strStructural, strContent];
strSheet = [strSheet(end), strSheet(1:end-1)];

%% Create and populate the workbook
if exist(sExcelFileName, 'file')
    delete(sExcelFileName);
end
writecell({' '}, sExcelFileName);

exl = [];
exlFile = [];
try
    exl = actxserver('excel.application');
    exl.Visible = false;
    exl.DisplayAlerts = false;
    exl.AskToUpdateLinks = false;
    exlFile = exl.Workbooks.Open(sExcelFileName);

    while exlFile.Sheets.Count < numel(strSheet)
        exlFile.Sheets.Add;
    end

    for iSheet = 1:numel(strSheet)
        exlFile.Sheets.Item(iSheet).Name = strSheet(iSheet).Name;
        exlSheet = exlFile.Sheets.Item(iSheet);
        exlSheet.Activate;

        if isstruct(strSheet(iSheet).Categories)
            write_data_sheet(exlSheet, strSheet(iSheet).Categories);
        else
            write_parameter_sheet(exlSheet, strSheet(iSheet).Categories, ...
                strSheet(iSheet).Name);
        end
        exlSheet.Cells.EntireColumn.AutoFit;
        format_reference_sheet(exlSheet, strSheet(iSheet).Name);
    end

    % phiQPV0_p is a workbook input. phiPV_p is intentionally not defined
    % here because the steady-state calibration determines it separately.
    iPhiQPV0Row = find(strcmp(strStart.Categories(:, 1), 'phiQPV0_p'), 1);
    exlFile.Names.Add('phiQPV0_p', ...
        ['=Start!$B$' num2str(iPhiQPV0Row)]);

    exlFile.Save;
    exlFile.Close(false);
    exl.Quit;
catch ME
    if ~isempty(exlFile)
        try exlFile.Close(false); catch, end %#ok<CTCH>
    end
    if ~isempty(exl)
        try exl.Quit; catch, end %#ok<CTCH>
    end
    rethrow(ME);
end

fprintf('Created %s\n', sExcelFileName);

%% Local helpers
function write_data_sheet(exlSheet, strSubSheets)
    iStartCol = 1;
    for iSubSheet = 1:numel(strSubSheets)
        inbrow = size(strSubSheets(iSubSheet).Data, 1);
        inbcol = size(strSubSheets(iSubSheet).Data, 2);
        sRange = [get_excel_column(iStartCol) '1:' ...
            get_excel_column(iStartCol + inbcol - 1) num2str(inbrow)];
        rngObj = exlSheet.Range(sRange);
        rngObj.NumberFormat = '0.00';
        rngObj.Value = strSubSheets(iSubSheet).Data;

        for iRow = 1:inbrow
            for iCol = 1:inbcol
                sName = strSubSheets(iSubSheet).CellNames{iRow, iCol};
                if ~isempty(sName)
                    rngName = exlSheet.Range([get_excel_column(iStartCol + iCol - 1) ...
                        num2str(iRow)]);
                    rngName.Name = sName;
                end
            end
        end
        iStartCol = iStartCol + inbcol + 1;
    end
end

function write_parameter_sheet(exlSheet, casCategories, sSheetName)
    inbrow = size(casCategories, 1);
    inbcol = size(casCategories, 2);
    [~, iValueCol] = ismember('Value', casCategories(1, :));

    for iCol = 1:inbcol
        if iCol == iValueCol
            exlSheet.Range([get_excel_column(iCol) '1']).Value = ...
                casCategories(1, iCol);
            for iRow = 2:inbrow
                rngValue = exlSheet.Range([get_excel_column(iCol) num2str(iRow)]);
                xValue = casCategories{iRow, iCol};
                if ischar(xValue) && startsWith(xValue, '=')
                    try
                        rngValue.Formula = {xValue};
                    catch ME
                        % Some localized Excel installations reject decimal
                        % points through Formula but accept the equivalent
                        % local formula. Excel stores it canonically either way.
                        try
                            rngValue.FormulaLocal = {strrep(xValue, '.', ',')};
                        catch
                            error('create_calibration_excel_file:FormulaWrite', ...
                                'Could not write formula "%s" to %s!%s: %s', ...
                                xValue, sSheetName, rngValue.Address, ME.message);
                        end
                    end
                else
                    rngValue.Value = xValue;
                end
            end
        else
            sRange = [get_excel_column(iCol) '1:' ...
                get_excel_column(iCol) num2str(inbrow)];
            exlSheet.Range(sRange).Value = casCategories(:, iCol);
        end
    end

    if strcmp(sSheetName, 'Content')
        for iRow = [1, 6, 8]
            rngObj = exlSheet.Range(['A' num2str(iRow) ':C' num2str(iRow)]);
            rngObj.MergeCells = true;
            exlSheet.Range(['A' num2str(iRow)]).Font.Bold = true;
        end
    elseif strcmp(sSheetName, 'IO_Data')
        % Detailed formatting is applied after AutoFit.
    else
        for iRow = 1:inbrow
            rngObj = exlSheet.Range(['A' num2str(iRow) ':' ...
                get_excel_column(inbcol) num2str(iRow)]);
            if sum(cellfun(@isempty, casCategories(iRow, :))) == inbcol - 1
                rngObj.MergeCells = true;
                exlSheet.Range(['A' num2str(iRow)]).Interior.ColorIndex = 48;
            end
            if iRow == 1
                rngObj.Interior.ColorIndex = 48;
            end
        end
    end
end

function format_reference_sheet(exlSheet, sSheetName)
    switch sSheetName
        case 'Content'
            exlSheet.Columns.Item(1).ColumnWidth = 19.71;
            exlSheet.Columns.Item(2).ColumnWidth = 44.57;
            exlSheet.Columns.Item(3).ColumnWidth = 8.43;

        case 'Start'
            exlSheet.Columns.Item(1).ColumnWidth = 13.43;
            exlSheet.Columns.Item(2).ColumnWidth = 14;
            exlSheet.Columns.Item(3).ColumnWidth = 59.71;

        case 'Structural Parameters'
            exlSheet.Columns.Item(1).ColumnWidth = 15.29;
            exlSheet.Columns.Item(2).ColumnWidth = 15;
            exlSheet.Columns.Item(3).ColumnWidth = 121.86;
            exlSheet.Range('B4:B5').NumberFormatLocal = '0,00E+00';
            exlSheet.Range('B10').Interior.ColorIndex = 36;
            exlSheet.Range('B10').Font.Name = 'Aptos Narrow';

        case 'IO_Data'
            caWidths = {80.43, 11.29, 15, 14, 15, 15, 15, 14, 24.29, 15, 16.43, 21.57};
            for iCol = 1:numel(caWidths)
                exlSheet.Columns.Item(iCol).ColumnWidth = caWidths{iCol};
            end
            exlSheet.Rows.Item(1).RowHeight = 22;
            exlSheet.Rows.Item(2).RowHeight = 44;
            exlSheet.Rows.Item(3).RowHeight = 16;
            exlSheet.Rows.Item(9).RowHeight = 5;
            exlSheet.Rows.Item(10).RowHeight = 16;

            % Title and column headings.
            exlSheet.Range('A1').Font.Bold = true;
            exlSheet.Range('A1').HorizontalAlignment = -4131; % xlLeft
            exlSheet.Range('A1').VerticalAlignment = -4108;   % xlCenter
            exlSheet.Range('A1:L1').Borders.Item(9).LineStyle = 1;

            rngHeader = exlSheet.Range('A2:L2');
            rngHeader.Interior.ColorIndex = 49;
            rngHeader.Font.Bold = true;
            rngHeader.Font.Size = 10;
            rngHeader.HorizontalAlignment = -4108;
            rngHeader.VerticalAlignment = -4108;
            rngHeader.WrapText = true;
            rngHeader.Borders.LineStyle = 1;

            % Matrix subheading.
            exlSheet.Range('A3:L3').Borders.Item(8).LineStyle = 1;
            exlSheet.Range('A3:L3').Borders.Item(9).LineStyle = 1;
            exlSheet.Range('A3').Font.Size = 9;
            exlSheet.Range('A3').HorizontalAlignment = -4131;
            exlSheet.Range('A3').VerticalAlignment = -4108;
            exlSheet.Range('H3:L3').Font.Size = 9;
            exlSheet.Range('H3:L3').HorizontalAlignment = -4108;
            exlSheet.Range('H3:L3').VerticalAlignment = -4108;

            % Five sector rows.
            exlSheet.Range('A4:L8').Borders.LineStyle = 1;
            exlSheet.Range('A4:B8').HorizontalAlignment = -4131;
            exlSheet.Range('C4:L8').HorizontalAlignment = -4108;
            exlSheet.Range('A4:L8').VerticalAlignment = -4108;
            for iRow = [4, 6, 8]
                exlSheet.Range(['A' num2str(iRow) ':G' num2str(iRow)]).Interior.ColorIndex = 24;
            end
            for iRow = [5, 7]
                exlSheet.Range(['A' num2str(iRow) ':G' num2str(iRow)]).Interior.ColorIndex = 2;
            end
            exlSheet.Range('H4:H8').Interior.ColorIndex = 19;
            exlSheet.Range('I4:K8').Interior.ColorIndex = 35;
            exlSheet.Range('L4:L8').Interior.ColorIndex = 19;
            exlSheet.Range('C6').NumberFormatLocal = '0,00E+00';
            exlSheet.Range('E6').NumberFormatLocal = '0,00E+00';
            exlSheet.Range('H6').NumberFormatLocal = '0,00E+00';

            % Spacer/footnote rows retain the reference table styling.
            exlSheet.Range('A9:K9').Interior.ColorIndex = 24;
            exlSheet.Range('L9').Interior.ColorIndex = 2;
            exlSheet.Range('A9:L9').Borders.Item(8).LineStyle = 1;
            exlSheet.Range('C9:K9').Borders.Item(9).LineStyle = 1;
            exlSheet.Range('L9').Borders.LineStyle = 1;
            exlSheet.Range('C9:L9').NumberFormat = '0';

            exlSheet.Range('A10').Font.Size = 9;
            exlSheet.Range('A10').HorizontalAlignment = -4131;
            exlSheet.Range('A10').VerticalAlignment = -4108;
            exlSheet.Range('B10').Borders.Item(10).LineStyle = 1;
            exlSheet.Range('C10:G10').Interior.ColorIndex = 19;
            exlSheet.Range('C10:G10').HorizontalAlignment = -4108;
            exlSheet.Range('C10:G10').VerticalAlignment = -4108;
            exlSheet.Range('C10:G10').Borders.LineStyle = 1;
            exlSheet.Range('H10:L10').Interior.ColorIndex = 2;
            exlSheet.Range('H10:L10').Borders.LineStyle = 1;
            exlSheet.Range('H10:L10').NumberFormat = '0';
            exlSheet.Range('E10').NumberFormatLocal = '0,00E+00';
    end
end

function casData = reference_io_data()
    casData = {
        'Intermediate Input Shares and Sectoral Accounts (phiQI, phiX, phiM_I, phiM_F, phiW, phiY0, phiN0)', '', '', '', '', '', '', '', '', '', '', '';
        'Aggregate Sector', 'Subsector', 'Primary', 'Fossil', 'Renewables', 'Secondary', 'Tertiary', 'Exports (phiX)', 'Imports Intermediate (phiM_I)', 'Labour (phiW)', 'Value Added (phiY0)', 'Employment Share (phiN0)';
        'Intermediate input matrix phiQI [row=using, col=supplying]', '', '', '', '', '', '', '', '', '', '', '';
        'Primary', 'Primary', 0.0144222269304676, 0.00373203422197252, 0.000366163017465422, 0.0270460723021061, 0.00497520146338073, 0.00696061357776502, 0.0213453989397538, 0.03952593401003, 0.0438490218797826, 0.184219369117872;
        'Energy', 'Fossil', 0.00064131046250133, 0.0119814350752675, 0.000262936200857761, 0.00342080646961404, 0.00266445741596313, 0.00461393299633571, 0.019046009569366, 0.00622250548616622, 0.0186175196511867, 0.0290013648938226;
        'Energy', 'Renewables', 0.00001280984048025, 0.00165367250847013, 0.0000672760934804738, 0.000553826819472627, 0.000390253282396369, 0.0000594584490109265, 0.000353631006751602, 0.000722040212268816, 0.0033232510115608, 0.00336522831688537;
        'Secondary', 'Secondary', 0.0682890607273026, 0.0209100803164061, 0.00317746981052693, 0.332304892389546, 0.0525343162839348, 0.262089452443859, 0.181111309312077, 0.0763289422675271, 0.112422074941918, 0.35574793972965;
        'Tertiary', 'Tertiary', 0.005897909318092, 0.0128747869078953, 0.00150301451541214, 0.0371544012217515, 0.0506785278794848, 0.0336508607041189, 0.0255262414624216, 0.0917596344321297, 0.152319844922846, 0.427666097941771;
        '', '', '', '', '', '', '', '', '', '', '', '';
        'Final Imports (phiM_F)', '', 0.00355410089734362, 0.00163033360104539, 0.0000124347763588485, 0.0382628872177005, 0.00318515838400662, '', '', '', '', ''
        };
end

function casStart = reference_start_parameters()
    casStart = {
        'Parameter', 'Value', 'Description';
        'Y0_p', 5, 'initial GDP';
        'Parameter values for initial sum of hours worked relative to potential hours worked', '', '';
        'N0_1_p', 0.25, 'initial sum of hours worked relative to potential hours worked in region 1';
        'Initial public debt', '', '';
        'BG0_1_p', 0.3, 'initial public debt to GDP ratio';
        'sGY0_1_p', 0.095291, 'actual government-consumption share of GDP (calibration target for G_1/tauC_1_p; GSO 2019 IO table, GSO_REDUCED sheet, GC/TOTAL)';
        'Parameter values for initial emissions', '', '';
        'E0_NOETS_1_p', 0.22, 'initial emissions in region 1 not covered by ETS';
        'E0_1_p', 0.78, 'initial emissions in region 1 covered by ETS';
        'Initial emissions price', '', '';
        'PE0_1_p', 0, 'initial emissions price in region 1';
        'Parameter values for investments in residential building relative to GDP', '', '';
        'sH_1_p', '=83/1000', 'investments in residential building relative to GDP in region 1';
        'Parameter values for initial population', '', '';
        'PoP0_1_p', 1, 'initial population in region 1';
        'Parameter values for initial labour force', '', '';
        'LF0_1_p', '=0.68*B15', 'initial labour force in region 1';
        'Parameter values for initial housing', '', '';
        'H0_1_p', '=25', 'initial housing in region 1';
        'Parameter values for initial value for tas', '', '';
        'tas0_1_p', '=0', 'initial value for tas in region 1';
        'tas0_p', '=0', 'initial national surface temperature';
        'Parameter values for initial share of value added', '', '';
        'phiY0_1_1_p', 0.0438490218797826, 'initial share of value added in sector 1 and region 1';
        'phiY0_2_1_p', 0.0186175196511867, 'initial share of value added in sector 2 and region 1';
        'phiY0_3_1_p', 0.0033232510115608, 'initial share of value added in sector 3 and region 1';
        'phiY0_4_1_p', 0.112422074941918, 'initial share of value added in sector 4 and region 1';
        'phiY0_5_1_p', 0.164273191041304, 'initial share of value added in sector 5 and region 1';
        'Parameter values for initial share of employment', '', '';
        'phiN0_1_1_p', 0.184219369117872, 'initial share of employment in sector 1 and region 1';
        'phiN0_2_1_p', 0.0290013648938226, 'initial share of employment in sector 2 and region 1';
        'phiN0_3_1_p', 0.00336522831688537, 'initial share of employment in sector 3 and region 1';
        'phiN0_4_1_p', 0.35574793972965, 'initial share of employment in sector 4 and region 1';
        'phiN0_5_1_p', 0.427666097941771, 'initial share of employment in sector 5 and region 1';
        'Initial shares of government-owned capital', '', '';
        'phiG_1_1_p', 0.48, 'initial share of government-owned capital in subsector 1 and region 1';
        'phiG_2_1_p', 0.5, 'initial share of government-owned capital in subsector 2 and region 1';
        'phiG_3_1_p', 0.01, 'initial share of government-owned capital in subsector 3 and region 1';
        'phiG_4_1_p', 0.08, 'initial share of government-owned capital in subsector 4 and region 1';
        'phiG_5_1_p', 0.3, 'initial share of government-owned capital in subsector 5 and region 1';
        'Rooftop solar PV parameters', '', '';
        'phiQPV0_p', '=0.018*2', 'initial share of rooftop solar PV in final energy demand';
        'phiKPV0_p', 0.013, 'initial rooftop solar PV capital-to-GDP ratio';
        'deltaPV_p', 0.1, 'depreciation rate of rooftop solar PV capital';
        'Baseline foreign-owned capital shares', '', '';
        'sFDI0_1_1_p', 0.2, 'baseline share of foreign-owned capital in total capital for subsector 1 and region 1';
        'sFDI0_2_1_p', 0.14, 'baseline share of foreign-owned capital in total capital for subsector 2 and region 1';
        'sFDI0_3_1_p', 0.2, 'baseline share of foreign-owned capital in total capital for subsector 3 and region 1';
        'sFDI0_4_1_p', 0.7, 'baseline share of foreign-owned capital in total capital for subsector 4 and region 1';
        'sFDI0_5_1_p', 0.2, 'baseline share of foreign-owned capital in total capital for subsector 5 and region 1'
        };
end

function casStructural = reference_structural_parameters(inbregions, inbsubsectors, inbsectors)
    casParams = [ ...
        {'beta'; 0.97; 'discount factor'; false; false; false; false; false}, ...
        {'deltaB'; 0.05; 'foreign-asset depreciation rate'; false; false; false; false; false}, ...
        {'phiB'; 0.1; 'debt-elastic external finance premium coefficient'; false; false; false; false; false}, ...
        {'phiadjB'; 0.1; 'quadratic foreign-asset adjustment-cost parameter'; false; false; false; false; false}, ...
        {'sigmaL'; 1; 'inverse Frisch elasticity'; false; false; false; false; false}, ...
        {'sigmaC'; 1; 'intertemporal elasticity of substitution for consumption'; false; false; false; false; false}, ...
        {'etaQ'; 0.6; 'elasticity of substitution between sectors'; false; false; false; false; false}, ...
        {'etaF'; 0.6; 'elasticity of substitution between imports and domestic products'; false; false; false; false; false}, ...
        {'etaX'; 0.6; 'export price elasticity'; false; false; false; false; false}, ...
        {'tauC_1'; 0.07; 'consumption tax rate'; false; false; false; false; false}, ...
        {'tauNH_1'; 0; 'tax rate on labour income'; false; false; false; false; false}, ...
        {'tauKH'; 0; 'capital-income tax rate paid by households'; false; true; true; false; false}, ...
        {'etaQA'; 1; 'elasticity of substitution between products from different subsectors in one aggregate sector'; true; false; false; false; false}, ...
        {'etaQ'; 2; 'elasticity of substitution between regions in one subsector'; false; true; false; false; false}, ...
        {'phiQI'; 0; 'cost share of intermediate goods'; false; true; true; false; false}, ...
        {'phiM_F'; 0; 'final use import shares'; false; true; true; false; false}, ...
        {'phiM_I'; 0; 'intermediate import shares'; false; true; true; false; false}, ...
        {'phiX'; 0; 'share of exports on revenues'; false; true; true; false; false}, ...
        {'etaI'; 1; 'elasticity of substitution between value added and intermediate products'; false; true; false; false; false}, ...
        {'etaIA'; 0.05; 'elasticity of substitution between intermediate products supplied by different aggregate sectors'; false; true; false; false; false}, ...
        {'phiW'; 0; 'labour cost share'; false; true; true; false; false}, ...
        {'etaNK'; 1; 'elasticity of substitution between labour and capital'; false; true; true; false; false}, ...
        {'tauKF'; 0; 'capital-income tax rate paid by firms'; false; true; true; false; false}, ...
        {'tauNF'; 0; 'labour-income tax rate paid by firms'; false; true; true; false; false}, ...
        {'sE'; 0; 'share of ETS-covered emissions allocated to each subsector and region'; false; true; true; false; false}, ...
        {'sE_NOETS'; 0; 'share of non-ETS emissions allocated to each subsector and region'; false; true; true; false; false}, ...
        {'phiQI'; 0; 'share of inputs from another sector for each subsector'; false; true; true; true; false}, ...
        {'sEI'; 0; 'share of emissions on total emissions for each sector using products from another sector as input'; false; true; true; true; false}, ...
        {'phiQ_D'; 1; 'share of production used in one region from another region in the subsector'; false; true; true; false; true}, ...
        {'delta'; 0.05; 'depreciation rate'; false; true; true; false; false} ...
        ];

    casStructural = define_sheets_input_file_help1( ...
        casParams, inbregions, inbsubsectors, inbsectors);
    casStructural(:, 3) = cellfun(@(x) strrep(x, 'in  region', 'in region'), ...
        casStructural(:, 3), 'UniformOutput', false);

    % The helper historically called every activity a "sector". Correct
    % descriptions for parameters that are actually indexed by subsector.
    caSubsectorPrefixes = {'etaQ_', 'phiQI_', 'phiM_F_', 'phiM_I_', ...
        'phiX_', 'etaI_', 'etaIA_', 'phiW_', 'etaNK_', 'tauKH_', ...
        'tauKF_', 'tauNF_', 'sE_', 'sE_NOETS_', 'phiQ_D_', 'delta_'};
    for iRow = 2:size(casStructural, 1)
        sParameter = casStructural{iRow, 1};
        if ischar(sParameter) && any(cellfun(@(x) startsWith(sParameter, x), ...
                caSubsectorPrefixes))
            casStructural{iRow, 3} = strrep(casStructural{iRow, 3}, ...
                'in sector ', 'in subsector ');
        end
    end

    caAggregateSectors = {'Primary', 'Energy', 'Secondary', 'Tertiary'};
    for iSector = 1:numel(caAggregateSectors)
        sParameter = ['etaQA_' num2str(iSector) '_p'];
        iRow = find(strcmp(casStructural(:, 1), sParameter), 1);
        casStructural{iRow, 3} = sprintf([ ...
            'elasticity of substitution between products from different ' ...
            'subsectors in aggregate sector %d (%s)'], ...
            iSector, caAggregateSectors{iSector});
    end

    % Apply the calibrated values by parameter name.
    casValues = {
        'etaQA_1_p', 1; 'etaQA_2_p', 5; 'etaQA_3_p', 1; 'etaQA_4_p', 1;
        'phiQI_1_1_p', 0.0505416979353924; 'phiQI_2_1_p', 0.0189709456242038; 'phiQI_3_1_p', 0.00267783854429985; 'phiQI_4_1_p', 0.477215819527717; 'phiQI_5_1_p', 0.108108639842636;
        'phiM_F_1_1_p', 0.00355410089734362; 'phiM_F_2_1_p', 0.00163033360104539; 'phiM_F_3_1_p', 0.001; 'phiM_F_4_1_p', 0.0382628872177005; 'phiM_F_5_1_p', 0.00318515838400662;
        'phiM_I_1_1_p', 0.0213453989397538; 'phiM_I_2_1_p', 0.019046009569366; 'phiM_I_3_1_p', 0.000353631006751602; 'phiM_I_4_1_p', 0.181111309312077; 'phiM_I_5_1_p', 0.0255262414624216;
        'phiX_1_1_p', 0.00696061357776502; 'phiX_2_1_p', 0.004; 'phiX_3_1_p', 0.0001; 'phiX_4_1_p', 0.262089452443859; 'phiX_5_1_p', 0.0336508607041189;
        'etaIA_1_p', 0.05; 'etaIA_2_p', 0.05; 'etaIA_3_p', 0.05; 'etaIA_4_p', 0.05; 'etaIA_5_p', 0.05;
        'phiW_1_1_p', 0.03952593401003; 'phiW_2_1_p', 0.00622250548616622; 'phiW_3_1_p', 0.000722040212268816; 'phiW_4_1_p', 0.0763289422675271; 'phiW_5_1_p', 0.0917596344321297;
        'sE_1_1_p', 0; 'sE_2_1_p', 1; 'sE_3_1_p', 0; 'sE_4_1_p', 0; 'sE_5_1_p', 0;
        'sE_NOETS_1_1_p', 1; 'sE_NOETS_2_1_p', 0; 'sE_NOETS_3_1_p', 0; 'sE_NOETS_4_1_p', 0; 'sE_NOETS_5_1_p', 0;
        'phiQI_1_1_1_p', 0.0144222269304676; 'phiQI_1_1_2_p', 0.00409819723943794; 'phiQI_1_1_3_p', 0.0270460723021061; 'phiQI_1_1_4_p', 0.00497520146338073;
        'phiQI_2_1_1_p', 0.00064131046250133; 'phiQI_2_1_2_p', 0.0122443712761253; 'phiQI_2_1_3_p', 0.00342080646961404; 'phiQI_2_1_4_p', 0.00266445741596313;
        'phiQI_3_1_1_p', 0.0001280984048025; 'phiQI_3_1_2_p', 0.0017209486019506; 'phiQI_3_1_3_p', 0.000553826819472627; 'phiQI_3_1_4_p', 0.000390253282396369;
        'phiQI_4_1_1_p', 0.0682890607273026; 'phiQI_4_1_2_p', 0.024087550126933; 'phiQI_4_1_3_p', 0.332304892389546; 'phiQI_4_1_4_p', 0.0525343162839348;
        'phiQI_5_1_1_p', 0.005897909318092; 'phiQI_5_1_2_p', 0.0143778014233074; 'phiQI_5_1_3_p', 0.0371544012217515; 'phiQI_5_1_4_p', 0.0506785278794848
        };
    for iValue = 1:size(casValues, 1)
        iRow = find(strcmp(casStructural(:, 1), casValues{iValue, 1}), 1);
        casStructural{iRow, 2} = casValues{iValue, 2};
    end

    % Use concise, explicit section labels for the two specialized blocks.
    casStructural{find(strcmp(casStructural(:, 1), 'etaIA_1_p'), 1) - 1, 1} = ...
        'Parameter values for elasticity of substitution between intermediate products supplied by different aggregate sectors';
    casStructural{find(strcmp(casStructural(:, 1), 'delta_1_1_p'), 1) - 1, 1} = ...
        'Sectoral capital depreciation rates';
end
