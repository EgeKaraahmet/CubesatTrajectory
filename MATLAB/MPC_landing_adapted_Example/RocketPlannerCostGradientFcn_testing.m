function [Gx, Gmv] = RocketPlannerCostGradientFcn(stage,x,u)
% Rocket planner cost gradient function.

% Copyright 2020 The MathWorks, Inc.

Gx = zeros(5,1);
Gmv = ones(1,1);
