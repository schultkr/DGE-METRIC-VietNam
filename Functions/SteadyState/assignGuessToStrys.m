function strys = assignGuessToStrys(strys, xvec, strpar)
%ASSIGNGUESSTOSTRYS Assigns values from vector to strys fields based on fieldList.
%
% Inputs:
%   - strys     : structure to be updated
%   - xvec      : vector of guess values (e.g., from buildInitialGuess)
%   - fieldList : cell array of strings matching structure field names
%
% Output:
%   - strys     : updated structure with values assigned to listed fields
    fn = fieldnames(strpar.InitGuess);
    if length(xvec) ~= length(fn)
        error('Length of guess vector and field list must be the same.');
    end
    
    for i = 1:length(xvec)
        field = fn{i};
        strys.(field) = xvec(i);
    end
end