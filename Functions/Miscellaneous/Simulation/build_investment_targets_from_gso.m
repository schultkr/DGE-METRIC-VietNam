function tabtargets = build_investment_targets_from_gso(sCsvPath, M_, sRegion, sIoTableXlsx, sIoTableSheet)
    % tabtargets = build_investment_targets_from_gso(sCsvPath, M_, sRegion, sIoTableXlsx, sIoTableSheet)
    % Builds a reshuffle_initial_period.m tabtargets struct from a GSO
    % investment-by-ownership-and-sector CSV.
    %
    % Inputs:
    %   - sCsvPath [character] path to the GSO CSV. Expected columns:
    %       aggregate_sector, total_investment_bnVND, investment_gdp_ratio,
    %       public_investment_bnVND, public_gdp_ratio,
    %       private_investment_bnVND, private_gdp_ratio,
    %       fdi_proxy_bnVND, fdi_gdp_ratio_proxy,
    %       domestic_private_residual_bnVND, domestic_private_gdp_ratio_residual
    %     aggregate_sector rows expected: Primary, MiningEnergy, Secondary,
    %     Refinery, Utilities, Tertiary.
    %   - M_       [structure] Dynare model structure (see dynare manual);
    %               used to read K0_2_<reg>_p / K0_3_<reg>_p, the existing
    %               calibrated capital stocks that split Utilities
    %               investment between the model's Fossil and Renewables
    %               subsectors.
    %   - sRegion  [character] region index to target (default '1', the
    %               model's single Vietnam region)
    %   - sIoTableXlsx  [character, optional] path to the GSO 2019 IO
    %               workbook (e.g. IO-2019.xlsx). When given, all targets are
    %               uniformly RESCALED so their sum matches that workbook's
    %               non-housing gross capital formation ratio (I/Y, the same
    %               "Actual" total used by
    %               scripts/reporting/generate_gdp_components_start_end_vs_actual.m).
    %               Omit (or pass '') to use the raw, unscaled GSO ownership
    %               ratios (sum to ~34.6% of GDP for 2019) -- see rationale
    %               below.
    %   - sIoTableSheet [character, optional] sheet name to read within
    %               sIoTableXlsx (default 'Calibration for GDP Components').
    %
    % Output:
    %   - tabtargets [structure] fields IH_<subsec>_<reg>, IFDI_<subsec>_<reg>,
    %     IG_<subsec>_<reg> for subsec = 1..5 (nominal investment / nominal
    %     regional GDP), ready to pass into reshuffle_initial_period.m.
    %
    % Mapping (per ExcelFiles/README.md's ISIC convention for phiX/phiY):
    %   subsector 1 Primary    = GSO Primary + MiningEnergy    (A01-A03, B05-B09)
    %   subsector 2 Fossil     = GSO Utilities * fossil share  (D35 fossil-fired)
    %   subsector 3 Renewables = GSO Utilities * renewable share (D35 renewable)
    %   subsector 4 Secondary  = GSO Secondary + Refinery      (C10-C33, F41-F43)
    %   subsector 5 Tertiary   = GSO Tertiary                  (G45-U99)
    %
    %   GSO reports one combined electricity/gas/water investment figure
    %   (Utilities) with no fossil-vs-renewable generation split. That split
    %   is proxied here by the model's existing calibrated capital-stock
    %   shares K0_2_<reg>_p / (K0_2_<reg>_p + K0_3_<reg>_p); pass a
    %   different M_ (e.g. from a rerun with updated K0 parameters) to use a
    %   different split.
    %
    % Rescaling rationale (sIoTableXlsx): the GSO ownership CSV's total
    % (public+private+FDI summed over all sectors, ~34.6% of 2019 GDP) comes
    % from GSO's "Investment_Activity" survey -- realized investment capital
    % by industry, a broader/different statistical concept from SNA gross
    % fixed capital formation. The IO-2019.xlsx workbook's "Calibration for
    % GDP Components" sheet gives the SNA-consistent, IO-table-derived
    % non-housing investment ratio (I/Y, ~23.3% of 2019 GDP) that the
    % Baseline scenario's national accounts (Y = C+I+I_G+G+IH*PH+NX) are
    % benchmarked against. The two totals do not reconcile (see
    % docs/data_sources.md); passing sIoTableXlsx rescales every by-source,
    % by-activity target proportionally so the aggregate investment path the
    % reshuffle produces lands on the IO-table total while preserving the
    % ownership CSV's relative sector/source shares -- the alternative to
    % leaving Simulated total investment permanently ~11pp of GDP above the
    % "Actual" column in generate_gdp_components_start_end_vs_actual.m.

    if nargin < 3 || isempty(sRegion)
        sRegion = '1';
    end
    if nargin < 4
        sIoTableXlsx = '';
    end
    if nargin < 5 || isempty(sIoTableSheet)
        sIoTableSheet = 'Calibration for GDP Components';
    end

    tabGso = readtable(sCsvPath);

    [igPrimary,   ifdiPrimary,   ihPrimary]   = local_row_ratios(tabGso, 'Primary');
    [igMining,    ifdiMining,    ihMining]    = local_row_ratios(tabGso, 'MiningEnergy');
    [igSecondary, ifdiSecondary, ihSecondary] = local_row_ratios(tabGso, 'Secondary');
    [igRefinery,  ifdiRefinery,  ihRefinery]  = local_row_ratios(tabGso, 'Refinery');
    [igUtilities, ifdiUtilities, ihUtilities] = local_row_ratios(tabGso, 'Utilities');
    [igTertiary,  ifdiTertiary,  ihTertiary]  = local_row_ratios(tabGso, 'Tertiary');

    % Fossil/Renewables split of Utilities, from existing calibrated capital shares.
    paramNames = cellstr(M_.param_names);
    getP = @(nm) M_.params(strcmp(paramNames, nm));
    K0Fossil = getP(['K0_2_' sRegion '_p']);
    K0Renew  = getP(['K0_3_' sRegion '_p']);
    if isempty(K0Fossil) || isempty(K0Renew) || ~isfinite(K0Fossil) || ~isfinite(K0Renew) || (K0Fossil + K0Renew) <= 0
        warning('build_investment_targets_from_gso:noSplit', ...
            ['K0_2_%s_p/K0_3_%s_p not found or non-positive - splitting ' ...
             'Utilities investment 50/50 between Fossil and Renewables.'], sRegion, sRegion);
        shareFossil = 0.5;
    else
        shareFossil = K0Fossil / (K0Fossil + K0Renew);
    end
    shareRenew = 1 - shareFossil;

    tabtargets = struct();

    tabtargets.(['IG_1_'   sRegion]) = igPrimary   + igMining;
    tabtargets.(['IFDI_1_' sRegion]) = ifdiPrimary + ifdiMining;
    tabtargets.(['IH_1_'   sRegion]) = ihPrimary   + ihMining;

    tabtargets.(['IG_2_'   sRegion]) = igUtilities   * shareFossil;
    tabtargets.(['IFDI_2_' sRegion]) = ifdiUtilities * shareFossil;
    tabtargets.(['IH_2_'   sRegion]) = ihUtilities   * shareFossil;

    tabtargets.(['IG_3_'   sRegion]) = igUtilities   * shareRenew;
    tabtargets.(['IFDI_3_' sRegion]) = ifdiUtilities * shareRenew;
    tabtargets.(['IH_3_'   sRegion]) = ihUtilities   * shareRenew;

    tabtargets.(['IG_4_'   sRegion]) = igSecondary   + igRefinery;
    tabtargets.(['IFDI_4_' sRegion]) = ifdiSecondary + ifdiRefinery;
    tabtargets.(['IH_4_'   sRegion]) = ihSecondary   + ihRefinery;

    tabtargets.(['IG_5_'   sRegion]) = igTertiary;
    tabtargets.(['IFDI_5_' sRegion]) = ifdiTertiary;
    tabtargets.(['IH_5_'   sRegion]) = ihTertiary;

    % Rescale every target proportionally so the aggregate investment path
    % matches the IO table's non-housing investment ratio, preserving the
    % ownership CSV's relative sector/source shares. See "Rescaling
    % rationale" above.
    if ~isempty(sIoTableXlsx)
        rawTotal = sum(tabGso.investment_gdp_ratio);
        if ~(rawTotal > 0)
            error('build_investment_targets_from_gso:invalidRawTotal', ...
                'Non-positive total investment_gdp_ratio in %s.', sCsvPath);
        end
        targetTotal = local_read_io_investment_ratio(sIoTableXlsx, sIoTableSheet);
        scaleFactor = targetTotal / rawTotal;

        tgtNames = fieldnames(tabtargets);
        for iField = 1:numel(tgtNames)
            tabtargets.(tgtNames{iField}) = tabtargets.(tgtNames{iField}) * scaleFactor;
        end

        fprintf(['[build_investment_targets_from_gso] Rescaled targets by %.4f ' ...
            '(raw ownership total %.4f%% of GDP -> IO-table I/Y target %.4f%% of GDP)\n'], ...
            scaleFactor, rawTotal * 100, targetTotal * 100);
    end
end

function ratio = local_read_io_investment_ratio(file, sheet)
    % Non-housing gross capital formation ratio (I/Y) from the IO workbook's
    % "Calibration for GDP Components" sheet (row 1 = descriptive labels,
    % values on the first row below with a numeric GDP entry). Column
    % lookup mirrors read_gso_actuals/local_find_col in
    % scripts/reporting/generate_gdp_components_start_end_vs_actual.m.
    if ~isfile(file)
        error('build_investment_targets_from_gso:missingIoTableFile', ...
            'IO table workbook not found: %s', file);
    end
    raw = readcell(file, 'Sheet', sheet);
    descRow = lower(string(raw(1, :)));

    colI = find(contains(descRow, "gross capital formation"), 1);
    colY = find(contains(descRow, "gdp"), 1);
    if isempty(colI) || isempty(colY)
        error('build_investment_targets_from_gso:unexpectedIoTableHeader', ...
            'Could not find "gross capital formation" / "GDP" columns in sheet "%s" of %s.', sheet, file);
    end

    rowIdx = [];
    for r = 2:size(raw, 1)
        v = raw{r, colY};
        if isnumeric(v) && ~isempty(v) && ~isnan(v)
            rowIdx = r;
            break
        end
    end
    if isempty(rowIdx)
        error('build_investment_targets_from_gso:ioTableValueRowNotFound', ...
            'Could not locate the GDP components value row in sheet "%s" of %s.', sheet, file);
    end

    ratio = raw{rowIdx, colI} / raw{rowIdx, colY};
end

function [ig, ifdi, ih] = local_row_ratios(tabGso, sSector)
    irow = strcmpi(tabGso.aggregate_sector, sSector);
    if ~any(irow)
        error('build_investment_targets_from_gso:missingSector', ...
            'Sector "%s" not found in the aggregate_sector column.', sSector);
    end
    ig   = tabGso.public_gdp_ratio(irow);
    ifdi = tabGso.fdi_gdp_ratio_proxy(irow);
    ih   = tabGso.domestic_private_gdp_ratio_residual(irow);
end
