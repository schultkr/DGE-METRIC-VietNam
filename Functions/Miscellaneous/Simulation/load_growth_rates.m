function [iTargetGrowthRatesY, iTargetGrowthRatesN] = load_growth_rates(sWorkbookBaseline, M_, sSheet)
    % [iTargetGrowthRatesY, iTargetGrowthRatesN] = load_growth_rates(sWorkbookBaseline, M_, sSheet)
    % Reads growth rate targets from the ModelBaseline workbook.
    % Inputs:
    %   - sWorkbookBaseline  [character] path to ModelBaseline*.xlsx
    %   - M_                 [structure] see dynare manual
    %   - sSheet             [character] sheet name to read (default 'Baseline')
    %
    % Output:
    %   - iTargetGrowthRatesY  [matrix] GDP growth rates (subsectors x time)
    %   - iTargetGrowthRatesN  [matrix] employment growth rates (subsectors x time)

    if nargin < 3, sSheet = 'Baseline'; end
    [danum, catext] = xlsread(sWorkbookBaseline, sSheet);
    % find positions of exogenous variables
    inbregions_p = M_.params(ismember(M_.param_names, 'inbregions_p'));
    inbsectors_p = M_.params(ismember(M_.param_names, 'inbsectors_p'));
    inbsubsectors_p = M_.params(ismember(M_.param_names, ['subend_' num2str(inbsectors_p) '_p']));
    temp = arrayfun(@(y) arrayfun(@(x) ['gY_' num2str(y) '_'  num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
    casgrowthratesY = [temp{:}];
    temp = arrayfun(@(y) arrayfun(@(x) ['gN_' num2str(y) '_'  num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
    casgrowthratesN = [temp{:}];
    
    
    [~, ipostext] = ismember(casgrowthratesY, catext);
    % update values of exogenous variables
    iTargetGrowthRatesY = danum(:, ipostext(ipostext>0))';
    % update values of exogenous variables
    [~, ipostext] = ismember(casgrowthratesN, catext);
    iTargetGrowthRatesN = danum(:, ipostext(ipostext>0))';
    
end