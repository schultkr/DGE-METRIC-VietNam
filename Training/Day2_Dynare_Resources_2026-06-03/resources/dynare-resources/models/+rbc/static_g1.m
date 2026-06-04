function [g1, T_order, T] = static_g1(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 8
    T_order = -1;
    T = NaN(6, 1);
end
[T_order, T] = rbc.static_g1_tt(y, x, params, T_order, T);
g1_v = NaN(15, 1);
g1_v(1)=(-1)/(y(1)*y(1))-T(4)*(-params(1))/(y(1)*y(1));
g1_v(2)=(-((1-params(3))*y(4)))/(y(1)*y(1));
g1_v(3)=1;
g1_v(4)=(-(T(1)*T(3)*params(3)*exp(y(5))*getPowerDeriv(y(2),params(3)-1,1)));
g1_v(5)=(-(T(3)*exp(y(5))*getPowerDeriv(y(2),params(3),1)));
g1_v(6)=1-(1-params(4));
g1_v(7)=(-(T(1)*T(2)*T(6)));
g1_v(8)=(-((-1)/(y(3)*y(3))));
g1_v(9)=(-(T(5)*T(6)));
g1_v(10)=(1-params(3))/y(1);
g1_v(11)=1;
g1_v(12)=(-1);
g1_v(13)=(-(T(1)*T(2)*T(3)));
g1_v(14)=(-(T(3)*T(5)));
g1_v(15)=1-params(2);
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
