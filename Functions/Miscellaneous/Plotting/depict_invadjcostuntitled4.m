% ==== Tabulate effective installed investment increase (explicit functional form) ====
% Provided wedge:
%   P_K(x) = 1 - ( exp(sqrt(phiK/2)*x) + exp(-sqrt(phiK/2)*x) - 2 )
% where x is the investment growth rate (e.g. x=0.10 for 10%).
%
% Effective installed investment increase relative to previous investment:
%   I_eff / I_{-1} - 1  = (1+x)*P_K(x) - 1

% --- choose grids ---
xGrid    = [-0.1 0.01 0.02 0.05 0.10 0.20];   % growth rates
phiKGrid = [1 10 15 20 40 80];              % phiK values

nX = numel(xGrid);
nP = numel(phiKGrid);

Pk   = nan(nX,nP);   % wedge P_K(x)
effG = nan(nX,nP);   % effective installed growth (fraction)

for j = 1:nP
    phiK = phiKGrid(j);
    a = sqrt(phiK/2);
    for i = 1:nX
        x = xGrid(i);

        % --- explicit functional form exactly as you wrote it ---
        Pk(i,j) = 1 - ( exp(a*x) + exp(-a*x) - 2 );

        % effective installed investment increase vs previous level
        effG(i,j) = (1 + x) * Pk(i,j) - 1;
    end
end

% --- pretty tables ---
rowNames = compose('x=%.0f%%', 100*xGrid);
colNames = compose('phiK=%g', phiKGrid);

T_eff = array2table(100*effG, 'VariableNames', colNames, 'RowNames', rowNames);
T_Pk  = array2table(Pk,       'VariableNames', colNames, 'RowNames', rowNames);

disp('Effective installed investment growth (%):');
disp(T_eff);

disp('Wedge P_K(x) (unitless):');
disp(T_Pk);

% --- optional visualization: heatmap ---
figure('Color','w');
imagesc(phiKGrid, 100*xGrid, 100*effG);
set(gca,'YDir','normal');
colorbar;
xlabel('\phi_K');
ylabel('Investment growth rate (%)');
title('Effective installed investment growth (%)');
