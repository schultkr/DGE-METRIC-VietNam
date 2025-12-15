function [y, T, residual, g1] = dynamic_83(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=((1+y(331))/(1+max(0,y(359)*y(346))+max(0,y(410)*y(397))+max(0,y(454)*y(441))+max(0,y(505)*y(492))+max(0,y(556)*y(543))))-(1);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1/(1+max(0,y(359)*y(346))+max(0,y(410)*y(397))+max(0,y(454)*y(441))+max(0,y(505)*y(492))+max(0,y(556)*y(543)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
