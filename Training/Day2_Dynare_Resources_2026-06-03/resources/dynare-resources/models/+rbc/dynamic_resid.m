function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(6, 1);
end
[T_order, T] = rbc.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(5, 1);
    residual(1) = (1/y(6)) - (T(1)*T(4));
    residual(2) = ((1-params(3))*y(9)/y(6)) - (1/y(8));
    residual(3) = (y(9)) - (T(5)*T(6));
    residual(4) = (y(7)) - (y(9)+(1-params(4))*y(2)-y(6));
    residual(5) = (y(10)) - (params(2)*y(5)+params(5)*x(1));
end
