function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(10)=params(2)*y(5)+params(5)*x(1);
end
