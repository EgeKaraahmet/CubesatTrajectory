function [Gx, Gmv, Gdmv] = RocketLanderCostGradientFcn(stage,x,u,dmv,p)
% Rocket lander cost gradient function.

% Copyright 2020 The MathWorks, Inc.

Gmv = zeros(2,1);
if stage == 1
    Gx = zeros(6,1);
    Gdmv = 2*[0.1 0;0 0.1]*dmv;
elseif stage == 11
    Gx = 2*(x-p);
    Gdmv = zeros(2,1);
else
    Gx = 2*(x-p);
    Gdmv = 2*[stage*0.1 0;0 stage*0.1]*dmv;
end

