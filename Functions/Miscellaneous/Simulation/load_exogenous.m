function oo_ = load_exogenous(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet)
    % oo_ = load_exogenous(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet)
    % Loads exogenous variable paths from the appropriate workbook.
    % Inputs:
    %   - sWorkbookBaseline  [character] path to ModelBaseline*.xlsx
    %   - sWorkbookScenarios [character] path to ModelScenarios*.xlsx
    %   - sScenario          [character] sheet name to read (or 'Baseline' routing key)
    %   - oo_                [structure] see dynare manual
    %   - M_                 [structure] see dynare manual
    %   - sBaselineSheet     [character] sheet to read from ModelBaseline (default 'Baseline')
    %
    % Output:
    %   - oo_                [structure] see dynare manual

    if nargin < 6, sBaselineSheet = 'Baseline'; end

    % read excel file
    if contains(sScenario, '.csv')
        data = fopen(['ExcelFiles/Input/' sScenario]);
        A = textscan(data,'%s','Delimiter','\n');
        B = A{1,1};
        catext = reshape(split(B', ','),size(split(B', ','),2),size(split(B', ','),3)) ;
        danum = cellfun(@(x) str2num(x),catext(2:end, 1:end));
    else
        % Route: Baseline reads from ModelBaseline (with optional sheet override);
        % all other scenarios read from ModelScenarios.
        if strcmp(sScenario, 'Baseline')
            sFile  = sWorkbookBaseline;
            sSheet = sBaselineSheet;
        else
            sFile  = sWorkbookScenarios;
            sSheet = sScenario;
        end
        [danum, catext] = xlsread(sFile, sSheet);
    end
    
    % find positions of exogenous variables
    % [lUpdateExo, ipostext] = ismember(M_.exo_names, catext(1,:));
    [~, iposexo] = ismember(catext, M_.exo_names);
    oldKGHeaders = startsWith(catext, 'exo_I_G_') & iposexo == 0;
    if any(oldKGHeaders(:))
        catextKG = strrep(catext(oldKGHeaders), 'exo_I_G_', 'exo_K_G_');
        [~, iposKG] = ismember(catextKG, M_.exo_names);
        iposexo(oldKGHeaders) = iposKG;
    end
    % update values of exogenous variables
    oo_.exo_simul(danum(:,1), iposexo(iposexo>0)) = danum(:, iposexo>0);
    oo_.exo_simul((danum(end,1)+1):end, iposexo(iposexo>0)) = repmat(oo_.exo_simul(danum(end,1), iposexo(iposexo>0)), size(oo_.exo_simul,1)-danum(end,1), 1);
end
