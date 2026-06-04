function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(5, 1);
end
[T_order, T] = rbc.static_resid_tt(y, x, params, T_order, T);
residual = NaN(5, 1);
    residual(1) = (1/y(1)) - (T(1)*T(4));
    residual(2) = ((1-params(3))*y(4)/y(1)) - (1/y(3));
    residual(3) = (y(4)) - (T(3)*T(5));
    residual(4) = (y(2)) - (y(4)+y(2)*(1-params(4))-y(1));
    residual(5) = (y(5)) - (y(5)*params(2)+params(5)*x(1));
end
