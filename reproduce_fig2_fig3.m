clear all
close all
clc

% Paths to access functions from other folders
function_paths = [genpath('tpls/'), genpath('util/'), ...
    genpath('predictive_error/'), genpath('baselines/')];

% Add the paths
addpath(function_paths)
clear function_paths

%% Main Script

% FIGURE 2 settings =================================
% K = 15;
% p = 4;

% a) observation noise
%var_y = 0.01;

% b) 
% var_y = 1;


% FIGURE 3 settings =================================
var_y = 1;
K = 20;

% a) true model dimension
% p =  4;

% b)
p = 14;


% Settings
var_features =  1;       % Range of input data H
var_theta = 0.5;         % Variance of theta
T = 100;                % Number of data points
ps = K - p;              % Number of 0s in theta

% OLASSO params 
epsilon = 1e-7;

% Initial batch of datad
t0 = K+1;

% Parallel runs
R = 4;

parfor run = 1:R
    tic

    %Create data
    [y, H, theta] = generate_data(T, K, var_features, var_theta,  ps, var_y);
    idx_h = find(theta ~= 0)';

   
    % TPLS =================================================================
    [theta_tpls, idx_tpls, J, plot_stats] = tpls(y, H, K, var_y, t0, idx_h);

    % Results for plotting
    [tpls_correct, tpls_incorrect] = plot_stats{:};
    J_tpls(run,:) = J;



    % Olin LASSO =================================================================
    [theta_olin, idx_olin, J, plot_stats] = olasso(y, H, t0, epsilon, var_y, idx_h);
    
    % Results for plotting
    [olin_correct, olin_incorrect] = plot_stats{:};
    J_olin(run,:) = J;



    % OCCD ===============================================================
    [theta_occd, idx_occd, J, plot_stats] = occd(y, H, t0, var_y, idx_h);
    
    % Results for plotting
    [occd_correct, occd_incorrect] = plot_stats{:};
    J_occd(run,:) = J;
    


    % GENIE =============================================================
    [J_true(run,:), ~] = true_PE(y, H, t0, T, idx_h, var_y);


    % BARS (for statistical performance)
    tpls_f(run, :, :) = [tpls_correct;  tpls_incorrect]; 
    olin_f(run, :, :) = [olin_correct;  olin_incorrect]; 
    occd_f(run, :, :) = [occd_correct;  occd_incorrect]; 
    toc
end


% Average over R runs - feature plots
tpls_features = squeeze(mean(tpls_f,1));
olin_features = squeeze(mean(olin_f,1));
occd_features = squeeze(mean(occd_f,1));

% Average over R runs - predictive error plots
J_tpls = mean(J_tpls, 1);
J_olin = mean(J_olin, 1);
J_occd = mean(J_occd, 1);
J_true = mean(J_true,1);


%% FIGURE 3 or 4: Statistical performance

% Colors, FontSizes, Linewidths
load plot_settings.mat
fsz = 16;
fszl = 12;


% Time range to plot
time_plot = t0+1:T;



% BAR PLOTS SPECIFIC RUN =========================================
figure('Renderer', 'painters', 'Position', [200 300 1500 400])

% TPLS
subplot(1,4,1)
formats = {fsz, fszl, fsz_title, lwdt, c_tpls, c_inc, c_true, 'TPLS', 'Time'};
bar_plots(tpls_features, t0+1, T, p, K, formats)

% OLinLASSO
subplot(1,4,2)
formats = {fsz, fszl, fsz_title, lwdt, c_olin, c_inc, c_true, 'OLinLASSO', 'Time'};
bar_plots(olin_features, t0+1, T, p, K, formats)

% OCCD
subplot(1,4,3)
formats = {fsz, fszl, fsz_title, lwdt, c_occd, c_inc, c_true, 'OCCD-TWL', 'Time'};
bar_plots(occd_features, t0+1, T, p, K, formats)

% Predictive Error plots
subplot(1,4,4)
hold on
plot(time_plot, J_occd - J_true, 'Color', c_occd, 'LineWidth', lwd)
plot(time_plot, J_olin - J_true, 'Color', c_olin, 'LineWidth', lwd)
plot(time_plot, J_tpls - J_true, 'Color', c_tpls, 'LineWidth', lwd)
yline(0, 'Color',c_true, 'linewidth', lwdt)
hold off
xlim([t0+1, T])
ax = gca;
box(ax,'on')    
ax.BoxStyle ='full';
ax.FontSize = 15;
title('Relative', 'FontSize', 20)
legend('\Delta J_{OCCD}', '\Delta J_{OLin}', '\Delta J_{TPLS}', 'FontSize', fszl)
xlabel('Time', 'FontSize', fsz)
ylabel('Predictive Error Difference', 'FontSize', fsz)
grid on





%save('results/fig3b.mat')
