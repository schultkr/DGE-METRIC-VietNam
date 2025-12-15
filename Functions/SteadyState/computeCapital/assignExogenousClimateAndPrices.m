function strys = assignExogenousClimateAndPrices(strys, strexo, strpar)
%ASSIGNEXOGENOUSCLIMATEANDPRICES Assigns climate and price-related variables to strys.
%
% Inputs:
%   - strys  : structure of endogenous variables (to be updated)
%   - strexo : structure of exogenous shocks
%   - strpar : structure of parameters
%
% Output:
%   - strys  : updated structure with exogenous variables applied

    % === 1. Compute foreign interest rate
    strys.rf = 1 / (strpar.beta_p * exp(strexo.exo_beta)) - 1 + strexo.exo_rf;

    % === 2. Assign regional climate variables
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        for iVar = 1:length(strpar.casClimatevarsRegional)
            climVar = strpar.casClimatevarsRegional{iVar};
            base = [climVar '0_' sreg '_p'];
            shock = ['exo_' climVar '_' sreg];
            strys.([climVar '_' sreg]) = strpar.(base) + strexo.(shock);
        end
    end

    % === 3. Assign national climate variables
    for iVar = 1:length(strpar.casClimatevarsNational)
        climVar = strpar.casClimatevarsNational{iVar};
        base = [climVar '0_p'];
        shock = ['exo_' climVar];
        strys.(climVar) = strpar.(base) + strexo.(shock);
    end

    % === 4. Assign domestic price levels and exchange rates
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);

        % Domestic price level P_D
        strys.(['P_D_' sreg]) = strpar.(['P0_D_' sreg '_p']) * exp(strexo.(['exo_P_D_' sreg]));

        % Exchange rate s_
        strys.(['s_' sreg]) = strpar.(['s0_' sreg '_p']) * exp(strexo.(['exo_s_' sreg]));
    end

end
