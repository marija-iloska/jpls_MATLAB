
%% Main Code
clear all
close all
clc

% Settings
var_y = 0.5;            % Observation noise Variance
ps = 6;                 % Number of 0s in theta
K = 12;                 % Number of available features
var_features =  1;      % Range of input data H
var_theta = 0.5;        % Variance of theta
T = 180;                % Number of data points
p = K - ps;             % True model dimension

% OLASSO params 
epsilon = 1e-7;

% Initial batch of datad
t0 = K+1;

% rjMCMC params
n = round(0.2*T);
Ns = 1400;
Nb = 500;

% Parallel runs
R = 1;

tic
for run = 1:R

    %Create data
    [y, H, theta] = generate_data(T, K, var_features, var_theta,  ps, var_y);
    idx_h = find(theta ~= 0)';

    % Pad original true indices for comparison
    idx_h_padded = [idx_h zeros(1, K - length(idx_h))];


    % JPLS =================================================================
    [theta_jpls, idx_jpls, J, plot_stats] = jpls(y, H, K, var_y, init, idx_h);

    % Results for plotting
    [jpls_correct, jpls_incorrect] = plot_stats{:};
    J_jpls(run,:) = J;



    % Olin LASSO =================================================================
    [theta_olin, idx_olin, J, plot_stats] = olasso(y, H, t0, epsilon, var_y, idx_h);
    
    % Results for plotting
    [olin_correct, olin_incorrect] = plot_stats{:};
    J_olin(run,:) = J;



    % RJ MCMC =================================================================
    % Data partition and Number of sweeps
    [idx_mcmc, theta_RJ, plot_stats, J] = rj_mcmc(y, H, n, Ns, Nb, idx_h, var_y);

    % Results for plotting
    [mcmc_correct, mcmc_incorrect] = plot_stats{:};
    J_mcmc(run,:) = J;
    

    % GENIE 
    [J_true(run,:), ~] = true_PE(y, H, t0, T, idx_h, var_y);

    % SUPER GENIE
    e_super = y(t0+1:end) - H(t0+1:end,:)*theta;
    J_super(run,:) = cumsum(e_super.^2);


    % SINGLE EXPECTATIONS
    [E_add, E_rmv] = expectations(y, H, t0, T, idx_h, var_y, theta);


    % BARS (for statistical performance)
    jpls_f(run, :, :) = [jpls_correct;  jpls_incorrect]; 
    olin_f(run, :, :) = [olin_correct;  olin_incorrect]; 
    mcmc_f(run, :, :) = [mcmc_correct;  mcmc_incorrect]; 



end
toc 

% Average over R runs - feature plots
jpls_features = squeeze(mean(jpls_f,1));
olin_features = squeeze(mean(olin_f,1));
mcmc_features = squeeze(mean(mcmc_f,1));

% Average over R runs - predictive error plots
J_jpls = mean(Jpred_jpls, 1);
J_olin = mean(Jpred_olin, 1);
J_true = mean(J_true,1);
J_super = mean(J_super,1);



%% EXPERIMENT I  - FEATURE BAR PLOTS - DISCRETE

% Colors 
c_olin = [0, 0.8, 0];           % olinlasso green
c_jpls = [0.8, 0, 0];           % jpls red
c_mcmc = [43, 115, 224]/256;    % mcmc blue
c_true = [0,0,0];               % ground truth black
c_inc = [0.4, 0.4, 0.4];        % incorrect features grey

% Time range to plot
time_plot = t0+1:T;

% Format plots - font sz and linewidth
fsz = 15;
fszl = 15;
lwd = 2;
lwdt = 4;


% BAR PLOTS SPECIFIC RUN
figure;

% JPLS
subplot(3,2,1)
formats = {fsz, fszl, lwdt, c_jpls, c_inc, c_true, 'JPLS'};
bar_plots(jpls_features, t0, T, p, K, formats)

% OLinLASSO
subplot(3,2,3)
formats = {fsz, fszl, lwdt, c_olin, c_inc, c_true, 'OLinLASSO'};
bar_plots(olin_features, t0, T, p, K, formats)

% RJMCMC
subplot(3,1,3)
formats = {fsz, fszl, lwdt, c_mcmc, c_inc, c_true, 'RJMCMC'};
bar_plots(mcmc_features, 1, Ns, p, K, formats)


% PREDICTIVE ERROR Plots

% Difference
subplot(3,2,4)
plot(time_plot, J_olin - J_true, 'Color', c_olin, 'LineWidth', lwd)
hold on
plot(time_plot, J_mcmc - J_true, 'Color', c_mcmc, 'LineWidth', lwd)
hold on
plot(time_plot, J_jpls - J_true,  'Color', c_jpls, 'LineWidth', lwd)
hold on
yline(0, 'Color',c_true, 'linewidth', lwdt)
xlim([t0+1, T])
set(gca, 'FontSize', 15)
title('Relative', 'FontSize', 15)
legend('\Delta J_{OLin}', '\Delta J_{RJMCMC}', '\Delta J_{JPLS}', 'FontSize', fszl)
xlabel('Time', 'FontSize', fsz)
ylabel('Predictive Error Difference', 'FontSize', fsz)
grid on

% Raw
subplot(3,2,2)
plot(time_plot, J_olin, 'Color', c_olin, 'LineWidth', lwd)
hold on
plot(time_plot, J_mcmc, 'Color', c_mcmc, 'LineWidth', lwd)
hold on
plot(time_plot,J_jpls, 'Color', c_jpls, 'LineWidth', lwd)
hold on
plot(time_plot, J_true, 'Color', c_true, 'LineWidth', lwd)
hold on
plot(time_plot,J_super, 'Color', [0, 0, 0], 'LineWidth', lwd, 'LineStyle','--')
hold on
xlim([time_plot(1), time_plot(end)])
set(gca, 'FontSize', 15)
legend('J_{OLinLASSO}', 'J_{RJMCMC}', 'J_{JPLS}',  'J_{GENIE}', 'J_{TRUTH}',  'FontSize', fszl)
title('Predictive Error', 'FontSize', 15)
ylabel('Predictive Error ', 'FontSize', fsz)
xlabel('Time', 'FontSize', fsz)
grid on



%% EXPERIMENT IV:  PLOT EXPECTATIONS

% import colors
load colors.mat
time_plot = t0+1:T;

title_str = 'INSTANT';
y_str = '\Delta_n';
lwd = 2;
fsz = 15;


% ADD A FEATURE =======================================================
figure;

subplot(2,1,1)
formats = {fsz, lwd, col, 'INSTANT', '\Delta_n'};
expectation_plots(E_add(time_plot,:), time_plot, K-p,  formats)

subplot(2,1,2)
formats = {fsz, lwd, col, 'BATCH', '\Sigma \Delta_n'};
expectation_plots(cumsum(E_add(time_plot,:)), time_plot, K-p,  formats)

sgtitle('EXTRA FEATURE:  \Delta_n = E_{+j,n} - E_{p,n}', 'fontsize', fsz)


% REMOVING A FEATURE ==================================================
figure;

col{7} = [0,0,0];
subplot(2,1,1)
formats = {fsz, lwd, col, 'INSTANT', '\Delta_n'};
expectation_plots(E_rmv(time_plot,:), time_plot, p,  formats)

subplot(2,1,2)
formats = {fsz, lwd, col, 'BATCH', '\Sigma \Delta_n'};
expectation_plots(cumsum(E_rmv(time_plot,:)), time_plot, p,  formats)

sgtitle('REMOVED FEATURE: \Delta_n =  E_{-j,n} - E_{p,n}', 'fontsize', 15)




