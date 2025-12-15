function [y, T, residual, g1] = static_70(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=((1+y(208))/(1+y(207)/y(209)))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/(1+y(207)/y(209));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
