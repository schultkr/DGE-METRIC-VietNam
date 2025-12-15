function [y, T, residual, g1] = static_78(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  T(768)=1+y(65)*y(44)/y(302)+y(116)*y(95)/y(302)+y(160)*y(139)/y(302)+y(211)*y(190)/y(302)+y(262)*y(241)/y(302);
  residual(1)=((1+y(277))/T(768))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/T(768);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
