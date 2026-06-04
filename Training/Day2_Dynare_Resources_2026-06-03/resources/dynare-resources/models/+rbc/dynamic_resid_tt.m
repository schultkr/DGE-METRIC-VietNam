function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 6
    T = [T; NaN(6 - size(T, 1), 1)];
end
T(1) = params(1)/y(11);
T(2) = params(3)*exp(y(15))*y(12)^(params(3)-1);
T(3) = y(13)^(1-params(3));
T(4) = 1+T(2)*T(3)-params(4);
T(5) = exp(y(10))*y(7)^params(3);
T(6) = y(8)^(1-params(3));
end
