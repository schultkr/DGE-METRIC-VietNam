function [y, T, residual, g1] = static_77(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  T(767)=1+y(300)*y(44)/(y(25)*y(21))*y(65)+y(300)*y(95)/(y(25)*y(21))*y(116)+y(300)*y(139)/(y(25)*y(21))*y(160)+y(300)*y(190)/(y(25)*y(21))*y(211)+y(300)*y(241)/(y(25)*y(21))*y(262);
  residual(1)=((1+y(15))/T(767))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/T(767);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
