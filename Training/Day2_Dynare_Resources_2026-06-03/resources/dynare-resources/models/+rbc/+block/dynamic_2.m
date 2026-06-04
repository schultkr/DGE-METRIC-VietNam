function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  T(1)=exp(y(10));
  T(2)=T(1)*y(7)^params(3);
  T(3)=y(8)^(1-params(3));
  y(9)=T(2)*T(3);
  residual(1)=(y(7))-(y(9)+(1-params(4))*y(2)-y(6));
  residual(2)=((1-params(3))*y(9)/y(6))-(1/y(8));
  T(4)=params(3)*exp(y(15));
  T(5)=T(4)*y(12)^(params(3)-1);
  T(6)=y(13)^(1-params(3));
  residual(3)=(1/y(6))-(params(1)/y(11)*(1+T(5)*T(6)-params(4)));
  T(7)=T(3)*T(1)*getPowerDeriv(y(7),params(3),1);
  T(8)=T(2)*getPowerDeriv(y(8),1-params(3),1);
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=(-(1-params(4)));
g1_v(2)=1-T(7);
g1_v(3)=(1-params(3))*T(7)/y(6);
g1_v(4)=(-T(8));
g1_v(5)=(1-params(3))*T(8)/y(6)-(-1)/(y(8)*y(8));
g1_v(6)=1;
g1_v(7)=(-((1-params(3))*y(9)))/(y(6)*y(6));
g1_v(8)=(-1)/(y(6)*y(6));
g1_v(9)=(-(params(1)/y(11)*T(6)*T(4)*getPowerDeriv(y(12),params(3)-1,1)));
g1_v(10)=(-(params(1)/y(11)*T(5)*getPowerDeriv(y(13),1-params(3),1)));
g1_v(11)=(-((1+T(5)*T(6)-params(4))*(-params(1))/(y(11)*y(11))));
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 9);
end
end
