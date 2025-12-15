function oo_ = LoadExogenous(sWorkbookNameInput, sScenario, oo_, M_)
    % oo_ = LoadExogenous(sWorkbookNameInput, sScenario, oo_, M_)
    % loads path for exogeonous variables
    % Inputs: 
    %   - sWorkbookNameInput [character] name of workbook with paths
    %   - sScenario          [character] name of scneario and sheet in workbook
    %   - oo_                [structure] see dynare manual
    %   - M_                 [structure] see dynare manual
    %
    % Output: 
    %   - oo_                [structure] see dynare manual
    
    % read excel file
    if contains(sScenario, '.csv')
        data = fopen(['ExcelFiles/Input/' sScenario]);
        A = textscan(data,'%s','Delimiter','\n');
        B = A{1,1};
        catext = reshape(split(B', ','),size(split(B', ','),2),size(split(B', ','),3)) ;
        danum = cellfun(@(x) str2num(x),catext(2:end, 1:end));
        %[danum, catext] = csvread(['ExcelFiles/Input/' sScenario],);
    else
        [danum, catext] = xlsread(sWorkbookNameInput, sScenario);
    end
    
    % find positions of exogenous variables
    % [lUpdateExo, ipostext] = ismember(M_.exo_names, catext(1,:));
    [~, iposexo] = ismember(catext, M_.exo_names);
    % update values of exogenous variables
    oo_.exo_simul(danum(:,1), iposexo(iposexo>0)) = danum(:, iposexo>0);
    oo_.exo_simul((danum(end,1)+1):end, iposexo(iposexo>0)) = repmat(oo_.exo_simul(danum(end,1), iposexo(iposexo>0)), size(oo_.exo_simul,1)-danum(end,1), 1);
end