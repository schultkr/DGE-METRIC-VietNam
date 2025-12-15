function [y, T, residual, g1] = dynamic_78(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  T(819)=1+y(383)*y(362)/y(620)+y(434)*y(413)/y(620)+y(478)*y(457)/y(620)+y(529)*y(508)/y(620)+y(580)*y(559)/y(620);
  residual(1)=((1+y(595))/T(819))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/T(819);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
