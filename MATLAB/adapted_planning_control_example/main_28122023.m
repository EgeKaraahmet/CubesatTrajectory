clear 
close all 
clc


%% Initial conditions 
% Input 
A=125e-4;               %m^2        % spacecraft cross - sectional area

% constant 
m = 6;                  %kg         % spacecraft mass  m = 3 for ISS
Cd=2.2;                             % drag coefficient
BC = m / Cd / A; 



%constants
mi=398600.44;           %km^3/s^2   % Earth G*M
Re=6371.0088;           %km         % Earth mean radius
g0=9.80665;             %m/s^2      % Gravitational acceleration (sea level)
%spacecraft parameters
E=0;                                % aerodynamic efficiency
CL=Cd*E;                            % lift coefficient
rcurv=0.1;              %m          % TPS nose curvature radius

%space environment      
date=[2023,01,01,12,00,00];         % intial time of simulation [y,m,d,h,m,s]
jdate=juliandate(date);
F107_avg=90.85;         %SFU        % F10.7 average of 3x27 days before the date under consideration
F107_day=86.0;          %SFU        % F10.7 average of day before the date under consideration


Kp=1;                                 % Kp three-hourly planetary geomagneticindex

alt_0 = 200;              %km         % initial altitude    %% 400 km
r_a=alt_0+Re;             %km         % radius at apoapsis
r_p=alt_0+Re;             %km         % radius at periapsis
a=(r_a+r_p)/2;            %km         % semimajor axis
e=(r_a-r_p)/(r_a+r_p);                % eccentricity


%re-entry path initial values (at t=0 s)
x0=0;                             % m          % travelled distance
gamma0=0;                         % rad        % flight path angle
theta0=0;                         % rad        % true anomaly 
r0=a*(1-e^2)/(1+e*cos(theta0));   % km         % position vector length
h0=r0-Re;                         % km         % height 
V0=sqrt(mi*(2/r0-1/a));           % km/s       % orbital speed (ellipse)
V0 = 7.788; 

%de-orbiting retrograde burn
dV=0;                             % km/s       % impulsive delta V obtained
V0=V0-dV;                         % km/s       % effective inital speed 

%integration method
solv_kep='ode4';                  % solver method for orbital phase. ode4 is runge kutta
step_kep='30';  %s                % keplerian intergartor fixed step size   % 30 
stop_h=150;     %km               % thres alt for switch from Kep. to Atm. phase 

solv_atm = 'ode4';                % solver method for re-entry phase. ode4 is runge kutta
step_atm='0.1'; %s                % atmospheric integrator fixed step size     % 0.1

%conversions to I.S.
Re=Re*1000;                     %m
V0=V0*1000;                     %m/s
h0=h0*1000;                     %m
stop_h=stop_h*1000;             %m

%% Simulation 
%a 3 DOF simulator has been implemented in Simulink model SatSim_ARES
%Kepleran phase of the simulation, slow variations in states due to low
%density, thus low drag perturbation.
%Integration step: 30 s
%First run stops when altitude reachesG stop_h threshold

kepOut = sim('reference_signal_generator','Solver',solv_kep,'FixedStep',step_kep);

%   updating initial conditions, 2nd run using ouput from 1st

%space environment
ndays1=kepOut.time(end)/60/60/24;  %days since intial time of simulation
jdate=jdate+ndays1;                %new julian date at beginning of 2nd run
F107_avg=90.85;         %SFU: updating
F107_day=86.0;          %SFU: updating
Kp=1;

%re-entry path initial values (at t=0 s)
h0=kepOut.h(end);            %m        %height
x0=kepOut.x(end);            %m        %travelled distance
V0=kepOut.V(end);            %m/s      %orbital speed
theta0=kepOut.theta(end);    %rad      %true anomaly
gamma0=kepOut.gamma(end);    %rad      %flight path angle


X0 = x0; 
%Re-entry simulation, atmospheric phase, more accuracy is needed.
%Smaller integration step required (e.g. 0.1 s)
%Simulation stops when altitude reaches 0 km (default)
%%%%%%%%%%%%%%%%%%
stop_h=0;   %m          %final desired altitude
%%%%%%%%%%%%%%%%%%

atmOut = sim('reference_signal_generator','Solver',solv_atm,'FixedStep',step_atm,'StartTime','kepOut.time(end)');

h_end=atmOut.h(end);         %m        %altitude
x_end=atmOut.x(end);         %m        %travelled distance
V_end=atmOut.V(end);            %m/s      %orbital speed
theta_end=atmOut.theta(end);    %rad      %true anomaly
gamma_end=atmOut.gamma(end);    %rad      %flight path angle


%% Results analysis and plotting
%   union of 1st and 2nd run results

h_reference_signal=[kepOut.h;atmOut.h];
x_reference_signal=[kepOut.x;atmOut.x];
time_reference_signal=[kepOut.time;atmOut.time];
V_reference_signal=[kepOut.V;atmOut.V];
Vx_reference_signal=[kepOut.Vx;atmOut.Vx];
Vz_reference_signal=[kepOut.Vz;atmOut.Vz];
gamma_reference_signal=[kepOut.gamma;atmOut.gamma];
theta_reference_signal=[kepOut.theta;atmOut.theta];
rho_reference_signal=[kepOut.rho;atmOut.rho];
dotV_reference_signal=[kepOut.dotV;atmOut.dotV];

%% Trajectory Planning
% The robot initially rests at |[-10,-10]| with an orientation angle of
% |pi/2| radians (facing north). The flying maneuver for this example is to
% move and park the robot at the final location |[0,0]| with an angle of
% |0| radians (facing east) in |12| seconds. The goal is to find the
% optimal path such that the total amount of fuel consumed by the thrusters
% during the maneuver is minimized.
%
% Nonlinear MPC is an ideal tool for trajectory planning problems because
% it solves an open-loop constrained nonlinear optimization problem given
% the current plant states. With the availability of a nonlinear dynamic
% model, MPC can make more accurate decisions.
%
% In this example, the target prediction time is |12| seconds. Therefore,
% specify a sample time of |0.4| seconds and prediction horizon of |30|
% steps. Create a multistage nonlinear MPC object with |5| states and |1|
% inputs. By default, all the inputs are manipulated variables (MVs).
Ts = 500;
p = 20;
nx = 5;
nu = 1;
nlobj = nlmpcMultistage(p,nx,nu);
nlobj.Ts = Ts;



%%

% x: (1) h: altitude 
%    (2) X: distance travelled
%    (3) V: velocity 
%    (4) theta: true anomaly
%    (5) gamma: flight path angle

% For a path planning problem, it is typical to allow MPC to have free
% moves at each prediction step, which provides the maximum number of
% decision variables for the optimization problem. Since planning usually
% runs at a much slower sampling rate than a feedback controller, the extra
% computation load introduced by a larger optimization problem can be
% accepted.

%%
% Specify the prediction model state function using the function name
nlobj.Model.StateFcn = "CubeSatStateFcn_25122023";


%%
% A trajectory planning problem usually involves a nonlinear cost function,
% which can be used to find the shortest distance, the maximal profit, or
% as in this case, the minimal fuel consumption. Because the thrust value
% is a direct indicator of fuel consumption, compute the fuel cost as the
% sum of the thrust values at each prediction step from stage 1 to stage p.
% Specify this cost function using a named function. 

for ct = 1:p
    nlobj.Stages(ct).CostFcn = 'CubeSatCostFcn_OptimalPath';
    
end

%% 
% nlobj.Model.TerminalState = zeros(5,1); 

x_op_t = [0;x_end;V_end;theta_end;gamma_end];
nlobj.Model.TerminalState = x_op_t;


%% constraints 
% bounded fin areas 

nlobj.MV.Min = 100 * 10^(-4);
nlobj.MV.Max = 150 * 10^(-4);


%% Initial conditions 
% Specify the initial conditions for the robot.
x_op_0 = [h0;X0;V0;theta0;gamma0];   % initial dynamics values 
% x_op_0 = [200*10^3;0;7788;0;0];        % initial dynamics values
u0 = 100 * 10^(-4);                        % minimum fin areas 



%%
% It is best practice to validate the user-provided model, cost, and
% constraint functions and their Jacobians. To do so, use the
% |validateFcns| command.
validateFcns(nlobj,x_op_0,u0);

%%
% The optimal state and MV trajectories can be found by calling the
% |nlmpcmove| command once, given the current state |x0| and last MV |u0|.
% The optimal cost and trajectories are returned as part of the |info|
% output argument.

% [~,~,info] = nlmpcmove(nlobj,x_op_0,u0);
%%
%% Initialize data structure
% The state and stage functions require state and stage parameters. 
% Use getSimulationData to initialize data structure. 
simdata = getSimulationData(nlobj);
% simdata.StateFcnParameter = pvstate;
% simdata.StageParameter = repmat(pvcost, p+1, 1);

%% Setting the Optimization Solver: conjugate gradient method
nlobj.Optimization.Solver = "cgmres";
% Adjust the Stabilization Parameter 
% based on the prediction model sample time.
nlobj.Optimization.SolverOptions.StabilizationParameter = 1/nlobj.Ts; % 1/mosbj.Ts

% Set the solver parameters.
nlobj.Optimization.SolverOptions.MaxIterations = 10;
nlobj.Optimization.SolverOptions.Restart = 3;
nlobj.Optimization.SolverOptions.BarrierParameter = 1e-3;
nlobj.Optimization.SolverOptions.TerminationTolerance = 1e-6;


%% Simulation duration in seconds.
Duration = Ts * p;

x0 = x_op_0; 
u0 = 100 * 10^(-4); 


% Store states and control for plotting purposes.
xHistory1 = x0.';
uHistory1 = u0.';

% Initialize control.
uk = uHistory1(1,:);

% Initialize the accumulated elapsed time 
% for computing the optimal control action calculation.
timerVal1 = 0;

% Simulation loop
for k = 1:(Duration/Ts)
    % Compute optimal control action using nlmpcmove.
    xk = xHistory1(k,:).';
    
    % Call the nlmpcmove function.
    tic
    [uk, simdata] = nlmpcmove(nlobj, xk, uk, simdata);
    
    % Accumulate the elapsed time.
    timerVal1 = timerVal1 + toc;

    % Simulate CubeSat trajectory for the next control interval.
    ODEFUN = @(t,xk) CubeSatStateFcn_25122023(xk,uk);
    [TOUT, XOUT] = ode45(ODEFUN, [0 Ts], xHistory1(k,:));

    % Log states and control.
    xHistory1(k+1,:) = XOUT(end,:);
    uHistory1(k+1,:) = uk;
   

    % Check for clicked Cancel button.
    %if getappdata(hbar,"canceling")
    %    delete(hbar)
    %    break
    % end
end


%%


% Assuming h_plot is xHistory1(:,1)
h_plot = xHistory1(:,1);
X_plot = xHistory1(:,2);
T_plot = TOUT;
u_plot = uHistory1; 

% Create a logical index to exclude negative values
positive_indices = h_plot >= 0;

% Filter the vectors using the logical index
h_plot = h_plot(positive_indices);
X_plot = X_plot(positive_indices);
T_plot = T_plot(positive_indices);
u_plot = u_plot(positive_indices);

figure
plot(X_plot,h_plot,'r')
figure
plot(x_reference_signal,h_reference_signal,'b')
% CubeSatPlotPlanning_29122023(info,Ts);


X_plot_end = X_plot(end);

(x_end - floor(x_end/(2*pi*Re))*(2*pi*Re))/(2*pi*Re)


(X_plot_end - floor(X_plot_end/(2*pi*Re))*(2*pi*Re))/(2*pi*Re)

%%
% The first plot shows the optimal trajectory of the six robot states
% during the maneuver. The second plot shows the corresponding optimal MV
% profiles for the four thrusts. The third plot shows the X-Y position
% trajectory of the robot, moving from |[-10 -10 pi/2]| to |[0 0 0]|.

%% Feedback Control for Path Following
% After the optimal trajectory is found, a feedback controller is required
% to move the robot along the path. In theory, you can apply the optimal MV
% profile directly to the thrusters to implement feed-forward control.
% However, in practice, a feedback controller is needed to reject
% disturbances and compensate for modeling errors.
%
% You can use different feedback control techniques for tracking. In this
% example, you use a generic nonlinear MPC controller to move the robot to
% the final location. In this path tracking problem, you track references
% for all 5 states (the number of outputs equals the number of states).
ny = 5;
nlobj_tracking = nlmpc(nx,ny,nu);

%% 
% Use the same state function.
nlobj_tracking.Model.StateFcn = nlobj.Model.StateFcn;
% nlobj_tracking.Jacobian.StateFcn = nlobj.Model.StateJacFcn;

%%
% For tracking control applications, reduce the computational effort by
% specifying shorter prediction horizon (no need to look far into the
% future) and control horizon (for example, free moves are allocated at the
% first few prediction steps).
nlobj_tracking.Ts = Ts;
nlobj_tracking.PredictionHorizon = 10;
nlobj_tracking.ControlHorizon = 4;

%% 
% The default cost function in nonlinear MPC is a standard quadratic cost
% function suitable for reference tracking and disturbance rejection. For
% tracking, tracking error has higher priority (larger penalty weights on
% outputs) than control efforts (smaller penalty weights on MV rates).
nlobj_tracking.Weights.ManipulatedVariablesRate = 0.2*ones(1,nu);
nlobj_tracking.Weights.OutputVariables = 5*ones(1,nx);

%% 
% bounded surface area
nlobj.MV.Min = 100 * 10^(-4);
nlobj.MV.Max = 150 * 10^(-4);

%%
% Also, to reduce fuel consumption, it is clear that |u1| and |u2| cannot be
% positive at any time during the operation. Therefore, implement equality
% constraints such that |u(1)*u(2)| must be |0| for all prediction steps.
% Apply similar constraints for |u3| and |u4|.
 nlobj_tracking.Optimization.CustomEqConFcn = @(X,U,data) [U];

%%
% Validate your prediction model and custom functions, and their Jacobians.
validateFcns(nlobj_tracking,x0,u0);

%% Nonlinear State Estimation
% In this example, only the three position states (x, y and angle) are
% measured. The velocity states are unmeasured and must be estimated. Use
% an extended Kalman filter (EKF) from Control System Toolbox(TM) for
% nonlinear state estimation.
%
% Because an EKF requires a discrete-time model, you use the trapezoidal
% rule to transition from x(k) to x(k+1), which requires the solution of
% |nx| nonlinear algebraic equations. For more information, open
% |FlyingRobotStateFcnDiscreteTime.m|.
DStateFcn = @(xk,uk,Ts) CubeSatStateFcnDiscreteTime_25122023(xk,uk,Ts);

%%
% Measurement can help the EKF correct its state estimation. Only the first
% three states are measured.
DMeasFcn = @(xk) xk(1:3);

%%
% Create the EKF, and indicate that the measurements have little noise.
EKF = extendedKalmanFilter(DStateFcn,DMeasFcn,x0);
EKF.MeasurementNoise = 0.01;

%% Closed-Loop Simulation of Tracking Control
% Simulate the system for |32| steps with correct initial conditions.
Tsteps = 32;        
xHistory = x0';
uHistory = [];
lastMV = zeros(nu,1);

%%
% The reference signals are the optimal state trajectories computed at the
% planning stage. When passing these trajectories to the nonlinear MPC
% controller, the current and future trajectory is available for
% previewing.
Xopt = info.Xopt;
Xref = [Xopt(2:p+1,:);repmat(Xopt(end,:),Tsteps-p,1)];



%%
% Use |nlmpcmove| and |nlmpcmoveopt| command for closed-loop simulation.
hbar = waitbar(0,'Simulation Progress');
options = nlmpcmoveopt;
for k = 1:Tsteps
    % Obtain plant output measurements with sensor noise.
    yk = xHistory(k,1:3)' + randn*0.01;
    % Correct state estimation based on the measurements.
    xk = correct(EKF, yk);
    % Compute the control moves with reference previewing.
    [uk,options] = nlmpcmove(nlobj_tracking,xk,lastMV,Xref(k:min(k+9,Tsteps),:),[],options);
    % Predict the state for the next step.
    predict(EKF,uk,Ts);
    % Store the control move and update the last MV for the next step.
    uHistory(k,:) = uk'; %#ok<*SAGROW> 
    lastMV = uk;
    % Update the real plant states for the next step by solving the
    % continuous-time ODEs based on current states xk and input uk.
    ODEFUN = @(t,xk) CubeSatStateFcn_25122023(xk,uk);
    [TOUT,YOUT] = ode45(ODEFUN,[0 Ts], xHistory(k,:)');
    % Store the state values.
    xHistory(k+1,:) = YOUT(end,:);            
    % Update the status bar.
    waitbar(k/Tsteps, hbar);
end
close(hbar)

%% 
% Compare the planned and actual closed-loop trajectories.
CubeSatPlotTracking(Xopt, Ts, p, Tsteps, xHistory, uHistory);


%%
% The nonlinear MPC feedback controller successfully moves the robot (blue
% blocks), following the optimal trajectory (yellow blocks), and parks it
% at the final location (red block) in the last figure.
%
% The actual fuel cost is higher than the planned cost. The main reason for
% this result is that, since we used shorter prediction and control
% horizons in the feedback controller, the control decision at each
% interval is suboptimal compared to the optimization problem used in the
% planning stage.

%% Identify a Neual State Space Model for the Flying Robot System
% In industrial applications, sometimes it is very difficult to manually
% derive a nonlinear state space dynamic model using first principles due
% to our lack of domain knowledge.  One of the popular alternative approach
% is black-box modeling based on experiment data.  In this section, we will
% showcase how to train a neural network to approximate the state function
% and then use it as the prediction model with nonlinear MPC.
%%
% The black-box model we want to identify is called "idNeuralStateSpace", a
% feature from System Identification Toolbox.
if ~mpcchecktoolboxinstalled('ident')
    disp('System Identification Toolbox is required to run this example.')
    return
end
%%
% The traing procedure is implemented in a supporting file
% |trainFlyingRobotNeuralStateSpaceModel|, which can be used a simple
% template and modified to fit your application.  It takes about 10 minutes
% to complete, depending on your computer.  To try it, change
% "ConductTraining = true" below.
IsTraining = false;
if IsTraining
   nss = trainFlyingRobotNeuralStateSpaceModel;
else
   load nssModel.mat %#ok<*UNRCH> 
end

%% Generate M files and Use them for Prediction
% After idNeuralStateSpace system is train, we can automatically generate M
% files for the state function and its analytical Jacobian function by
% using the |generateMATLABFunction| command.
nssStateFcnName = 'nssStateFcn';
generateMATLABFunction(nss,nssStateFcnName);

%% Use the Neural Network Model as the Prediction Model in Nonlinear MPC
% The generated M files are compatible with the interface required by
% nonlinear MPC objecy, and therefore, we can directly use them in the
% nonlinear MPC object
nlobj_tracking.Model.StateFcn = nssStateFcnName;
nlobj_tracking.Jacobian.StateFcn = [nssStateFcnName 'Jacobian'];

%% Run Simulation again with the Neural State Space Prediction Model
% Use |nlmpcmove| and |nlmpcmoveopt| command for closed-loop simulation.
EKF = extendedKalmanFilter(DStateFcn,DMeasFcn,x0);
xHistory = x0';
uHistory = [];
lastMV = zeros(nu,1);
hbar = waitbar(0,'Simulation Progress');
options = nlmpcmoveopt;
for k = 1:Tsteps
    % Obtain plant output measurements with sensor noise.
    yk = xHistory(k,1:3)';
    % Correct state estimation based on the measurements.
    xk = correct(EKF, yk);
    % Compute the control moves with reference previewing.
    [uk,options] = nlmpcmove(nlobj_tracking,xk,lastMV,Xref(k:min(k+9,Tsteps),:),[],options);
    % Predict the state for the next step.
    predict(EKF,uk,Ts);
    % Store the control move and update the last MV for the next step.
    uHistory(k,:) = uk';
    lastMV = uk;
    % Update the real plant states for the next step by solving the
    % continuous-time ODEs based on current states xk and input uk.
    ODEFUN = @(t,xk) FlyingRobotStateFcn(xk,uk);
    [TOUT,YOUT] = ode45(ODEFUN,[0 Ts], xHistory(k,:)');
    % Store the state values.
    xHistory(k+1,:) = YOUT(end,:);            
    % Update the status bar.
    waitbar(k/Tsteps, hbar);
end
close(hbar)
%% 
% Compare the planned and actual closed-loop trajectories.  The response is
% close to what first-principle based prediction model produces.
FlyingRobotPlotTracking(info,Ts,p,Tsteps,xHistory,uHistory);

%% References
% 
% [1] Y. Sakawa. "Trajectory planning of a free-flying robot by using the
% optimal control." _Optimal Control Applications and Methods_, Vol. 20,
% 1999, pp. 235-248.
%



