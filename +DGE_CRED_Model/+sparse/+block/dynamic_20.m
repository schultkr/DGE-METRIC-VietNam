function [y, T, residual, g1] = dynamic_20(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=((1+y(403))/(1+(1-params(147))*y(85)+y(402)))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=(-(1+y(403)))/((1+(1-params(147))*y(85)+y(402))*(1+(1-params(147))*y(85)+y(402)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
