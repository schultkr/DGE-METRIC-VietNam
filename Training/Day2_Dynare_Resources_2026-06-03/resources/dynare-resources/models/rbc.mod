// Simple RBC Model with Technology Shock
// Author: Training Session

var c k l y z;
varexo e_z;

parameters beta rho alpha delta sigma;

beta = 0.99;      // Discount factor
rho  = 0.95;      // Persistence of technology shock
alpha = 0.36;     // Capital share
delta = 0.025;    // Depreciation rate
sigma = 0.02;     // Std. dev. of technology shock

// Model equations
model;
// 1. Euler equation
1/c = beta * 1/c(+1) * (alpha * exp(z(+1)) * k(+1)^(alpha-1) * l(+1)^(1-alpha) + 1 - delta);
// 2. Labor-leisure (static)
(1 - alpha) * y / c = 1 / l;
// 3. Production function
y = exp(z) * k^alpha * l^(1-alpha);
// 4. Capital accumulation
k = (1 - delta) * k(-1) + y - c;
// 5. Technology process
z = rho * z(-1) + sigma * e_z;
end;

initval;
c = 1;
k = 10;
l = 0.3;
y = 1;
z = 0;
end;

shocks;
var e_z; stderr 1;
end;

stoch_simul(order=1,irf=20);
