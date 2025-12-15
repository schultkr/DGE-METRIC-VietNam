function [y, T, residual, g1] = static_83(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=((1+y(13))/(1+max(0,y(41)*y(28))+max(0,y(92)*y(79))+max(0,y(136)*y(123))+max(0,y(187)*y(174))+max(0,y(238)*y(225))))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/(1+max(0,y(41)*y(28))+max(0,y(92)*y(79))+max(0,y(136)*y(123))+max(0,y(187)*y(174))+max(0,y(238)*y(225)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
