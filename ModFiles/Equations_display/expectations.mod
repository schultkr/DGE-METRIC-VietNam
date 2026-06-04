// =======================
// Block 1: Expectations =
// =======================

@#define reg_exp_vars    = ["tauC","P","NX","B","Y","C","H","PoP","lambda","omegaH"]
@#define bilat_exp_vars  = ["NX","B"]
@#define subsec_exp_vars = ["p", "P", "P_K","rlog_H","r_H","omegaI","I_H", "K_H", "tauKH"]
# rfEXP = omegaP_p*rf(+1) + (1-omegaP_p)*rf;

@#for reg in 1:Regions
    @#for v in reg_exp_vars
        # @{v}_@{reg}EXP = omegaP_p*(@{v}_@{reg}(+1)) + (1-omegaP_p)*(@{v}_@{reg});
    @#endfor

    # B_@{reg}EXPEXP = omegaP_p*(B_@{reg}(+2)) + (1-omegaP_p)*(B_@{reg}(+1));

    @#if Regions > 1
        @#for regm in 1:Regions
            @#for v in bilat_exp_vars
                # @{v}_@{reg}_@{regm}EXP = omegaP_p*(@{v}_@{reg}_@{regm}(+1)) + (1-omegaP_p)*(@{v}_@{reg}_@{regm});
            @#endfor

            # B_@{reg}_@{regm}EXPEXP = omegaP_p*(B_@{reg}_@{regm}(+2)) + (1-omegaP_p)*(B_@{reg}_@{regm}(+1));
        @#endfor
    @#endif
@#endfor

@#for sec in 1:Sectors
    @#for reg in 1:Regions
        @#for subsec in Subsecstart[sec]:Subsecend[sec]
            @#for v in subsec_exp_vars
                # @{v}_@{subsec}_@{reg}EXP = omegaP_p*(@{v}_@{subsec}_@{reg}(+1)) + (1-omegaP_p)*(@{v}_@{subsec}_@{reg});
            @#endfor
        @#endfor
    @#endfor
@#endfor
