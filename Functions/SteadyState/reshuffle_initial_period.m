function oo_ = reshuffle_initial_period(oo_, M_, posIdx, inbregions_p, imaxsec_p, tabtargets) %#ok<INUSL>
% RESHUFFLE_INITIAL_PERIOD  Bottom-up reshuffle of the initial-period (col 1
% of oo_.endo_simul) national-accounts flows so investment matches
% user-supplied data targets, and every other flow (consumption,
% government expenditure, net exports, external debt) is re-derived
% consistently from those targets by re-running the same steady-state
% accounting routines used during calibration (setup_initial_state.m,
% steps V-VII).
%
% WHAT IS TARGETED
%   Investment is the only variable set directly by the user, and it is
%   set bottom-up: by economic activity (subsector) AND by source
%   (private household, FDI, public), each expressed as a ratio of
%   nominal investment to nominal regional GDP (Y_<reg> is already a
%   nominal quantity in this model's units):
%
%       tabtargets.IH_<subsec>_<reg>   = I_H_<subsec>_<reg>*P_INV_<subsec>_<reg>   / Y_<reg>
%       tabtargets.IFDI_<subsec>_<reg> = I_FDI_<subsec>_<reg>*P_INV_<subsec>_<reg> / Y_<reg>
%       tabtargets.IG_<subsec>_<reg>   = I_G_<subsec>_<reg>*P_INV_<subsec>_<reg>   / Y_<reg>
%
%   <subsec> is the subsector index (economic activity; e.g. in the
%   current 5-subsector configuration: 1 Primary, 2 Fossil, 3 Renewables,
%   4 Secondary, 5 Tertiary) and <reg> the region index. A field that is
%   absent or NaN leaves that source's investment at its current
%   (pre-reshuffle) model value - generalizing the old
%   targetCY/targetIY/targetGY==0 "keep SS" convention to per-source,
%   per-activity granularity.
%
%   Example:
%       tabtargets.IFDI_3_1 = 0.015;  % FDI into region 1 Renewables = 1.5% of regional GDP
%       tabtargets.IG_1_1   = 0.02;   % Public investment into region 1 Primary = 2% of regional GDP
%       oo_ = reshuffle_initial_period(oo_, M_, posIdx, inbregions_p, imaxsec_p, tabtargets);
%
%   Optionally, investment can ALSO be reconciled against an empirical
%   investment/capital-stock ratio (e.g. from PDP8 data -- see
%   compute_pdp8_capital_investment_ratio.m), holding K_<subsec>_<reg> fixed:
%
%       tabtargets.IK_<subsec>_<reg> = I_<subsec>_<reg> / K_<subsec>_<reg>
%
%   When present and finite, real investment I_<subsec>_<reg> + I_G_<subsec>_<reg>
%   (after the IH/IFDI/IG step above) is rescaled to
%   IK_<subsec>_<reg> * K_<subsec>_<reg> (K itself is NOT touched), holding
%   the ORIGINAL nominal investment level fixed and letting
%   P_INV_<subsec>_<reg> absorb the change in real quantity -- see step 1b
%   below. IK_<subsec>_<reg> is not a simple empirical average: it is found
%   ITERATIVELY (compute_pdp8_capital_investment_ratio.m) by
%   forward-simulating the model's OWN capital-goods supply-price equation
%   (investment_adjustment.mod, lCapPrice==1) period by period -- solving
%   jointly, at each period, the muI wedge and
%   P_INV(t) = PINVbase*(I_pos(t)/IRef(t))^(1/etaKS_p)*exp(exo_I(t)) for the
%   relative investment share q(t)=I_pos(t)/I_pos(1), then accumulating
%   K(t)=(1-delta)*(PoP(t)/PoP(t-1))*K(t-1)+I_pos(t) -- and searching (via
%   fzero) for the I_pos(1)/K(1) that makes the resulting K(T)/K(1) match
%   PDP8's Capacity_MW(T)/Capacity_MW(1) target. Because P_INV is now
%   endogenous to this search (not a separately-assumed PDP8 CAPEX price
%   trend), the resulting P_INV(t)/P_INV(1) path is itself model-consistent
%   by construction. Step 1b below still separately reconciles PERIOD 1's
%   OWN P_INV via nominalOld/Itotal (unchanged from earlier iterations of
%   this design, and independent of this solve) -- what the iterative solve
%   changes is only WHICH IK_<subsec>_<reg>/PINVIndex_<subsec>_<reg> values
%   feed into that step, and into the periods-2+ price tracking below.
%
%   IK_<subsec>_<reg> and PINVIndex_<subsec>_<reg> MUST both come from
%   compute_pdp8_capital_investment_ratio.m, fed with the ACTUAL
%   exo_targetIY_2_1/exo_targetIY_3_1 path (read from oo_.exo_simul, not
%   re-derived), a GDP path built from the Baseline's own gY_<subsec>_<reg>
%   growth targets weighted by initial value-added shares, a population path
%   from exo_LF_1/exo_NLF_1, and the model's own PINVbase/etaKS_p/exo_I
%   inputs (see simulation_model_refactored.m for how all of these are
%   built) -- not a raw dollar-valued or PDP8-CAPEX-price-index-based ratio:
%
%       deltaFossil = M_.params(ismember(M_.param_names, 'delta_2_1_p'));
%       deltaRenew  = M_.params(ismember(M_.param_names, 'delta_3_1_p'));
%       ratios = compute_pdp8_capital_investment_ratio(repoRoot, deltaFossil, deltaRenew, ...
%           sFossilPath, sRenewablePath, yPath, popPath, etaKS_p, fossilParamsIK, renewParamsIK, 2025:2050);
%       tabtargets.IK_2_1 = ratios.Fossil;
%       tabtargets.IK_3_1 = ratios.Renewable;
%       tabtargets.PINVIndex_2_1 = ratios.FossilPriceIndex;
%       tabtargets.PINVIndex_3_1 = ratios.RenewablePriceIndex;
%
%   PINVIndex_<subsec>_<reg> is applied here as a LEVEL SHIFT (new minus old
%   exo_I at period 1) plus a relative-price tracking term for periods 2
%   through numel(PINVIndex) (t=1 reduces to the level shift alone), left
%   untouched beyond that window -- so P_INV tracks the solved path for
%   exactly the years PDP8 covers (2025:2050), and reverts to organic model
%   dynamics (no compounding risk) for the long settling tail beyond it. A
%   flat, unconditional shift over the WHOLE simulation was tried in an
%   earlier iteration and over-corrects: exo_ltargetIY is active for the
%   whole Baseline horizon, so a permanently lower P_INV forces MORE real
%   investment every period (not just t=1) for the same nominal target,
%   compounding through K_t=(1-delta)K_{t-1}+I_t and blowing up renewables'
%   capital stock (whose required shift is far larger than fossil's). A
%   level shift at period 1 ONLY (no PINVIndex) under-corrects the other
%   way. If PINVIndex is omitted, the function falls back to the
%   period-1-only level shift.
%
% WHAT IS DERIVED (bottom-up, by reusing steady-state accounting functions)
%   1. I_<subsec>_<reg> = I_H_<subsec>_<reg> + I_FDI_<subsec>_<reg>          (firms.mod identity)
%   2. Regional/national aggregate investment I_<reg>, I                     compute_aggregates.m
%   3. Regional public investment I_G_<reg> (incl. adaptation G_A)           compute_regional_economic_accounts.m
%   4. Regional/national consumption C_<reg>, C (household budget residual)  compute_regional_economic_accounts.m
%   5. Regional/national government expenditure G_<reg>, G (goods-market     compute_government_expenditure_and_capital.m
%      resource-constraint residual, given C, I, I_G above)
%   6. Regional net exports NX_<reg>, external position B_<reg>/B and        compute_regional_economic_accounts.m
%      exchange-rate index s_<reg> (these respond only through the FDI
%      income/outflow term; goods-market NX itself does not depend on the
%      domestic C/I/G mix in this model)
%   7. Regional public debt BG_<reg> closes the regional government budget
%      constraint (government.mod), using the ORIGINAL (pre-reshuffle)
%      BG_<reg> and s_<reg> as the "lagged" state and the newly reshuffled
%      C_<reg>/G_<reg>/I_G_<reg> plus reused tax income
%      (compute_tax_income.m) on the revenue side.
%
% WHAT IS NOT CHANGED
%   K_<subsec>_<reg> (and its K_H/K_FDI/K_G split), KG_<reg>, H_<reg>,
%   wages, lambda, and productivity: only the flow/accounting side is
%   re-derived. The exceptions are P_INV_<subsec>_<reg> and
%   exo_I_<subsec>_<reg>, which DO move, but only for subsec/reg pairs with
%   an IK_<subsec>_<reg> target (step 1b) -- everywhere else prices are
%   untouched. exo_I_<subsec>_<reg> is adjusted for period 1 always, and for
%   periods 2 through numel(PINVIndex) when tabtargets.PINVIndex_<subsec>_<reg>
%   is supplied (tracking PDP8's own relative price development over its
%   active window, 2025:2050 by default) -- never beyond that window, and
%   never as a flat, unconditional shift over the whole horizon: see step 1b
%   for why that over-corrects and compounds through the active
%   muI-wedge/P_INV equations.

    if nargin < 6 || isempty(tabtargets)
        tabtargets = struct();
    end

    %% Parameters into struct
    paramNames = cellstr(M_.param_names);
    for ii = 1:M_.param_nbr
        strpar.(paramNames{ii}) = M_.params(ii);
    end

    %% Endogenous variables (initial period) into struct
    endoNames = cellstr(M_.endo_names);
    endoIndex = containers.Map(endoNames, num2cell(1:numel(endoNames)));
    ys = oo_.endo_simul(:, 1);
    for ii = 1:M_.endo_nbr
        strys.(endoNames{ii}) = ys(ii);
    end
    strys_pre = strys;  % pre-reshuffle snapshot; used as the "lagged" state for BG below

    %% Exogenous variables (initial period) into struct
    exoNames = cellstr(M_.exo_names);
    exoIndex = containers.Map(exoNames, num2cell(1:numel(exoNames)));
    exo0 = oo_.exo_simul(1, :);
    for ii = 1:M_.exo_nbr
        strexo.(exoNames{ii}) = exo0(ii);
    end

    %% 1. Bottom-up investment targets, by economic activity (subsector) and source
    anyTarget = false;
    namesToWrite = {};
    for icoreg = 1:inbregions_p
        sreg = num2str(icoreg);
        YnomReg = strys.(['Y_' sreg]);

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                stemp = [ssubsec '_' sreg];
                PINV = strys.(['P_INV_' stemp]);

                tH   = local_target(tabtargets, ['IH_'   stemp]);
                tFDI = local_target(tabtargets, ['IFDI_' stemp]);
                tG   = local_target(tabtargets, ['IG_'   stemp]);

                if isfinite(tH)
                    strys.(['I_H_' stemp]) = tH * YnomReg / PINV;
                    anyTarget = true;
                end
                if isfinite(tFDI)
                    strys.(['I_FDI_' stemp]) = tFDI * YnomReg / PINV;
                    anyTarget = true;
                end
                if isfinite(tG)
                    strys.(['I_G_' stemp]) = tG * YnomReg / PINV;
                    anyTarget = true;
                end

                % firms.mod identity: total private + FDI investment flow.
                strys.(['I_' stemp]) = strys.(['I_H_' stemp]) + strys.(['I_FDI_' stemp]);

                namesToWrite = [namesToWrite, {['I_H_' stemp], ['I_FDI_' stemp], ...
                    ['I_G_' stemp], ['I_' stemp]}]; %#ok<AGROW>
            end
        end
    end

    %% 1b. Reconcile real investment against an I/K ratio target solved from
    % the full PDP8 horizon (K held fixed; see
    % compute_pdp8_capital_investment_ratio.m). IK_<subsec>_<reg> need not
    % equal the model's calibrated replacement rate delta_<subsec>_<reg>, so
    % feeding it through the capital-goods supply-price curve's
    % (I_pos/IRef)^(1/etaKS_p) markup (investment_adjustment.mod,
    % lCapPrice==1) can produce implausible P_INV levels. Instead: the
    % ORIGINAL nominal investment level (from step 1, before this rescale)
    % is held FIXED, and P_INV absorbs the change from the old real quantity
    % to the new IK-implied real quantity:
    %
    %   nominalOld = (I_<stemp> + I_G_<stemp>)_old * P_INV_<stemp>_old
    %   P_INV_<stemp>_new = nominalOld / (I_<stemp> + I_G_<stemp>)_new
    %
    % The exo_I_<stemp> shock that reproduces this new P_INV via the model's
    % own steady-state price identity (P_INV = PINV_base*exp(exo_I)) is
    % applied as a LEVEL SHIFT at period 1 (new minus old exo_I), and, if
    % tabtargets.PINVIndex_<stemp> is supplied, additionally tracks PDP8's
    % own relative investment-price development for periods 2 through
    % numel(PINVIndex) -- exactly the PDP8-active window (2025:2050), never
    % beyond it. A flat, unconditional shift across the WHOLE horizon (an
    % earlier version of this function) over-corrects: exo_ltargetIY is
    % active for the whole Baseline horizon, so periods 2+ have the muI wedge
    % and this P_INV equation both binding every period, and a permanently
    % lower P_INV forces more real I every period for the same nominal
    % exo_targetIY target, compounding through K_t=(1-delta)K_{t-1}+I_t
    % across the whole horizon (this blew up renewables' capital stock,
    % whose required shift is far larger than fossil's). Conversely, a
    % level shift at period 1 ONLY (no PINVIndex) under-corrects: IRef(t) =
    % delta*K(t-1)+D_K drifts onto a different trajectory than
    % exo_targetIY_<stemp> was implicitly built for once K starts
    % accumulating from the IK-corrected I(1), so periods 2+ can settle on a
    % solution that misses the target (this under-shot fossil investment).
    % Tracking PDP8's own price trend for exactly its active window, and
    % leaving the long settling tail beyond it untouched, avoids both
    % failure modes. K_<subsec>_<reg> itself is left untouched throughout.
    for icoreg = 1:inbregions_p
        sreg = num2str(icoreg);

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                stemp = [ssubsec '_' sreg];

                tIK = local_target(tabtargets, ['IK_' stemp]);
                if ~isfinite(tIK)
                    continue
                end
                if tIK <= 0
                    warning('reshuffle_initial_period:InvalidIKTarget', ...
                        'IK_%s target must be positive; skipping.', stemp);
                    continue
                end

                K = strys.(['K_' stemp]);
                if ~isfinite(K) || K <= 0
                    warning('reshuffle_initial_period:InvalidIKCapital', ...
                        'K_%s is non-positive; cannot apply IK_%s target.', stemp, stemp);
                    continue
                end

                PINVold = strys.(['P_INV_' stemp]);
                Iold = strys.(['I_' stemp]) + strys.(['I_G_' stemp]);
                Inew = tIK * K;

                if Iold > 0
                    scale = Inew / Iold;
                else
                    scale = 0;
                    warning('reshuffle_initial_period:ZeroBaseInvestment', ...
                        'I_%s is zero pre-reshuffle; IK_%s target cannot rescale the H/FDI/G split.', stemp, stemp);
                end
                nominalOld = Iold * PINVold;

                strys.(['I_H_'   stemp]) = strys.(['I_H_'   stemp]) * scale;
                strys.(['I_FDI_' stemp]) = strys.(['I_FDI_' stemp]) * scale;
                strys.(['I_G_'   stemp]) = strys.(['I_G_'   stemp]) * scale;
                strys.(['I_' stemp]) = strys.(['I_H_' stemp]) + strys.(['I_FDI_' stemp]);

                Itotal = strys.(['I_' stemp]) + strys.(['I_G_' stemp]);
                if Itotal > 0
                    strys.(['P_INV_' stemp]) = nominalOld / Itotal;
                else
                    strys.(['P_INV_' stemp]) = PINVold;
                end

                if strpar.lCapGoodsSecPrice_p == 1
                    PINVbase = strpar.(['P0_' stemp '_p']);
                else
                    PINVbase = strys.(['P_' stemp]);
                end
                exoINew = log(strys.(['P_INV_' stemp]) / PINVbase);
                exoINm = ['exo_I_' stemp];
                exoIOld = strexo.(exoINm);  % pre-reshuffle period-1 value, whatever path this came from
                exoIShift = exoINew - exoIOld;
                strexo.(exoINm) = exoINew;

                % Track PDP8's own relative investment-price development
                % (compute_pdp8_capital_investment_ratio.m's price index)
                % across its ACTIVE window only (t=1 reduces to exoIShift
                % alone), never as a flat unconditional shift over the whole
                % horizon -- see step 1b header for why an unconditional
                % shift over- or under-corrects the target once K starts
                % accumulating from the IK-corrected I(1).
                pinvIndexNm = ['PINVIndex_' stemp];
                nApply = 0;
                if isKey(exoIndex, exoINm)
                    if isfield(tabtargets, pinvIndexNm) && ~isempty(tabtargets.(pinvIndexNm))
                        pRelPath = reshape(tabtargets.(pinvIndexNm), [], 1);
                        pRelPath = pRelPath ./ pRelPath(1);
                        nApply = min(numel(pRelPath), size(oo_.exo_simul, 1));
                        oo_.exo_simul(1:nApply, exoIndex(exoINm)) = ...
                            oo_.exo_simul(1:nApply, exoIndex(exoINm)) + exoIShift + log(pRelPath(1:nApply));

                        oo_.exo_simul((nApply+1):end, exoIndex(exoINm)) = ...
                            oo_.exo_simul((nApply), exoIndex(exoINm));
                    else
                        nApply = 1;
                        oo_.exo_simul(1, exoIndex(exoINm)) = oo_.exo_simul(1, exoIndex(exoINm)) + exoIShift;
                    end
                end

                namesToWrite = [namesToWrite, {['I_H_' stemp], ['I_FDI_' stemp], ...
                    ['I_G_' stemp], ['I_' stemp], ['P_INV_' stemp]}]; %#ok<AGROW>
                anyTarget = true;

                fprintf(['[reshuffle_initial_period] %s: IK target=%.4f  I+I_G %.2f->%.2f  ' ...
                    'P_INV %.4f->%.4f  exo_I shift=%+0.4f (applied to %d period(s))\n'], stemp, tIK, Iold, Itotal, ...
                    PINVold, strys.(['P_INV_' stemp]), exoIShift, nApply);
            end
        end
    end

    if ~anyTarget
        return
    end

    %% 2-6. Bottom-up aggregation, reusing the calibration accounting pipeline
    % (same call order as setup_initial_state.m, steps V-VII)
    [strys, strpar, strexo] = compute_aggregates(strys, strpar, strexo);
    [strys, strpar]         = compute_regional_imports_and_demand(strys, strpar);
    [strys, strpar, strexo] = compute_tax_income(strys, strpar, strexo);
    [strys, strpar, strexo] = compute_regional_economic_accounts(strys, strpar, strexo);
    strys = compute_government_expenditure_and_capital(strys, strpar);

    %% 7. Close each region's government budget constraint for BG
    for icoreg = 1:inbregions_p
        sreg = num2str(icoreg);

        phiBGext = strpar.(['phi_BG_ext_' sreg '_p']) + strexo.(['exo_phi_BG_ext_' sreg]);
        BG_lag   = strys_pre.(['BG_' sreg]);
        s_lag    = strys_pre.(['s_' sreg]);

        revenue = strys.(['tauC_' sreg]) * strys.(['P_' sreg]) * strys.(['C_' sreg]) ...
            + strys.(['IH_' sreg]) * strys.(['PH_' sreg]) * strys.(['tauH_' sreg]) ...
            + strys.(['PE_' sreg]) * strys.(['E_' sreg]) ...
            + strys.(['capitaltax_' sreg]) + strys.(['wagetax_' sreg]) + strys.(['publiccapitalincome_' sreg]) ...
            + (1 + strys.rf) * (phiBGext * s_lag + (1 - phiBGext)) * BG_lag;

        strys.(['BG_' sreg]) = revenue ...
            - strys.(['P_' sreg]) * strys.(['G_' sreg]) ...
            - strys.(['P_' sreg]) * strys.(['I_G_' sreg]) ...
            - strys.(['Tr_' sreg]);

        namesToWrite = [namesToWrite, {['I_' sreg], ['I_G_' sreg], ['C_' sreg], ['G_' sreg], ['BG_' sreg], ...
            ['NX_' sreg], ['B_' sreg], ['s_' sreg], ['Tr_' sreg]}]; %#ok<AGROW>

        fprintf(['[reshuffle_initial_period] reg %s: I/Y=%.4f  C/Y=%.4f  G/Y=%.4f  ' ...
            'NX/Y=%.4f  dBG=%.4f\n'], sreg, ...
            strys.(['I_' sreg]) * strys.(['P_' sreg]) / strys.(['Y_' sreg]), ...
            strys.(['C_' sreg]) * strys.(['P_' sreg]) / strys.(['Y_' sreg]), ...
            strys.(['G_' sreg]) * strys.(['P_' sreg]) / strys.(['Y_' sreg]), ...
            strys.(['NX_' sreg]) / strys.(['Y_' sreg]), ...
            strys.(['BG_' sreg]) - BG_lag);
    end

    namesToWrite = [namesToWrite, {'I', 'C', 'G', 'NX', 'B'}];

    %% Write reshuffled variables back into oo_.endo_simul(:,1)
    for k = 1:numel(namesToWrite)
        nm = namesToWrite{k};
        if isKey(endoIndex, nm) && isfield(strys, nm)
            oo_.endo_simul(endoIndex(nm), 1) = strys.(nm);
        end
    end
end

function v = local_target(tabtargets, name)
    if isfield(tabtargets, name)
        v = tabtargets.(name);
    else
        v = NaN;
    end
end
