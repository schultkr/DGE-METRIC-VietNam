function omega = ces_compute_weight(tempdenom, tempnums, extra_terms)
%CES_COMPUTE_WEIGHT Compute CES distribution weight.
%   omega = CES_COMPUTE_WEIGHT(tempdenom, tempnums, extra_terms)
%   returns 1 / sum(tempnums ./ tempdenom) plus optional extra_terms.
%
%   Inputs:
%     tempdenom   [scalar]  CES denominator term
%     tempnums    [vector]  numerator terms to sum
%     extra_terms [vector]  optional extra numerator terms
%
%   Output:
%     omega       [scalar]  CES distribution weight

    if nargin < 3
        extra_terms = [];
    end

    if isempty(tempnums)
        temp = 0;
    else
        temp = sum(tempnums ./ tempdenom);
    end

    if ~isempty(extra_terms)
        temp = temp + sum(extra_terms ./ tempdenom);
    end

    omega = 1 / temp;
end
