
%% Main Code
clear all
close all
clc

% Settings
var_y = 0.1;   % Variance
ps = 3;     % Sparsity percent
dy = 5;      % System dimension
r =  1;       % Range of input data H
rt = 0.5;      % Range of theta
T = 800;

% OLASSO params
epsilon = 1e-7;
t0 = 20;

% JPLS params
Tb = 5;
init = t0;

% rjMCMC params
% n = round(0.2*T);
% Ns = 2000;
% Nb = 1000;

% Parallel runs
R = 16;

% Initialize arrays
% time_mcmc = zeros(R);
% mcmc_run = zeros(R);

time_jpls = zeros(R);
jpls_run = zeros(R);
time_olin = zeros(R);
olin_run = zeros(R);


parfor run = 1:R

    %Create data
    [y, H, theta] = generate_data(T, dy, r, rt,  ps, var_y);
    idx_h = find(theta ~= 0)';


    % Pad original true indices for comparison
    idx_h_padded = [idx_h zeros(1, dy - length(idx_h))];


    % PJ ORLS___________________________________________________
    tic
    [theta_jpls, H_jpls,  models_jpls, count_jpls, idx_jpls, e, J_pred, jpls_correct, jpls_wrong, jpls_missing] = jpls(y, H, dy, var_y, init, Tb, idx_h);
    toc
    time_jpls(run) = toc;
    Jpred_jpls(run,:)=J_pred;
    e_jpls(run,:) = e;

    % Check through all models
%     idx_corr_jpls = 0;
%     for m = 1:length(models_jpls(:,1))
%         if (sum(models_jpls(m,:) == idx_h_padded ) == dy)
%             idx_corr_jpls = m;
%         end
%     end
%     best_jpls = models_jpls(1,:);



    % Olin LASSO___________________________________________________
    tic
    [theta_olin, idx_olin, models_olin, count_olin, e, J_pred, olin_correct, olin_wrong, olin_missing] = olasso(y, H, t0, epsilon, var_y, idx_h);
    toc
    time_olin(run) = toc;
    Jpred_olin(run,:) = J_pred;
    e_olin(run,:) = e;

    % Check through all models
%     idx_corr_olin() = 0;
%     for m = 1:length(models_olin(:,1))
%         if (sum(models_olin(m,:) == idx_h_padded ) == dy)
%             idx_corr_olin = m;
%         end
%     end
%     best_olin = models_olin(1,:);


        % RJ MCMC ___________________________________________________
    % Data partition and Number of sweeps
%     tic
%     [idx_mcmc, theta_RJ, models_mcmc, count_mcmc, Nm] = rj_mcmc(y, H, n, Ns, Nb);
%     time_mcmc(run) = toc;
% 
% 
%     % Check through all models
%     idx_corr_mcmc = 0;
%     for m = 1:length(models_mcmc(:,1))
%         if (sum(models_mcmc(m,:) == idx_h_padded ) == dy)
%             idx_corr_mcmc = m;
%         end
%     end


    % Store model ranks
%     jpls_run(run) = idx_corr_jpls;
%     olin_run(run) = idx_corr_olin;
    %mcmc_run(run) = idx_corr_mcmc;


    [J_true(run,:), e_true(run,:)] = true_PE(y, H, t0, T, idx_h, var_y);
     
    jpls_top = [theta_jpls(1:min(length(models_jpls(:,1)),3),:); theta'];
    olin_top = [theta_olin(1:min(length(models_olin(:,1)),3),:); theta'];
    [jpls_sim] = similarity(jpls_top);
    [olin_sim] = similarity(olin_top);


    % BARS
    jpls_f(run, :, :) = [jpls_correct;  jpls_wrong; jpls_missing]; 
    olin_f(run, :, :) = [olin_correct;  olin_wrong; olin_missing]; 




end

jpls_features = squeeze(mean(jpls_f,1));
olin_features = squeeze(mean(olin_f,1));

e_olin = mean(e_olin, 1);
e_jpls = mean(e_jpls, 1);
e_true = mean(e_true, 1);
J_jpls = mean(Jpred_jpls, 1);
J_olin = mean(Jpred_olin, 1);
J_true = mean(J_true,1);


% Anything below 5
jpls_run(jpls_run > 4) = 5;
olin_run(olin_run > 4) = 5;
%mcmc_run(mcmc_run > 4) = 5;


str_dy = num2str(dy);
str_k = num2str(dy - ps);
str_T = num2str(T);
str_v = num2str(var_y);
str_R = num2str(R);

% filename = join(['Results/T', str_T, '_K', str_dy, '_k', str_k, '_v', str_v, ...
%     '_R', str_R, '.mat']);
% 
% save(filename)


%% PLOTS 


% %% 
% filename = join(['figsPE/K', str_dy, '_k', str_k, '_v', str_v, '_h', num2str(r), '.eps']);
% print(gcf, filename, '-depsc2', '-r300');
% 


%%





% Bar plot
% subplot(1,3, 3)
% b_mcmc = bar(count_mcmc/sum(count_mcmc), 'FaceColor', 'flat');
% %ylim([0, 0.4])
% ylabel('Number of Visits')
% title('RJMCMC Models visited','FontSize',20)
% set(gca, 'FontSize', 20);
% grid on
% b_mcmc.CData(idx_corr_mcmc,:) = [0, 0, 0];


% % Percent Visit
% per_orls = count_jpls/sum(count_jpls);
% per_lasso = count_olin/sum(count_olin);
% y_lim = max(max([per_orls, per_lasso])) + 0.1;
% 
% 
% % Bar plot
% figure;
% subplot(1,2,1)
% b_lasso = bar(per_lasso, 'FaceColor', 'flat');
% ylim([0, y_lim])
% ylabel('Percent Visits')
% title('OLinLASSO','FontSize',20)
% set(gca, 'FontSize', 20); 
% grid on
% if (idx_corr_olin == 0)
%     text(1, 0.5*max(per_lasso), 'True Model NOT visited', 'FontSize', 15)
% else
%     b_lasso.CData(idx_corr_olin,:) = [0, 0.5, 0];
% end
% 
% 
% % Bar plot
% subplot(1,2, 2)
% 
% b_orls = bar(per_orls, 'FaceColor', 'flat');
% ylim([0, y_lim])
% ylabel('Percent Visits')
% title('JPLS ','FontSize',20)
% set(gca, 'FontSize', 20);
% grid on
% if (idx_corr_jpls==0)
%     text(1,0.5*max(per_orls), 'True Model NOT visited', 'FontSize', 15)
% else
%     b_orls.CData(idx_corr_jpls,:) = [0.5, 0, 0];
% end
% 
% sgtitle('Models Visited', 'FontSize', 15)

%% 
% filename = join(['figs/OLinLASSO/T', str_T, '_K', str_dy, '_k', str_k, '_v', str_v, ...
%     '_R', str_R, '.eps']);
% 
% print(gcf, filename, '-depsc2', '-r300');


%% FEATURES
fsz = 20;
lwd = 3;


figure;

% JPLS features BAR plots
subplot(1,3,1)
jb = bar(t0:T, jpls_features', 'stacked', 'FaceColor', 'flat', 'FaceAlpha', 1);
jb(1).CData = [0.7, 0, 0];
jb(2).CData = [0,0,0];
jb(3).CData = [0.6, 0.6, 0.6];
hold on
yline(dy-ps, 'Color', 'b', 'LineWidth', 5)
ylim([0, dy])
set(gca, 'FontSize', 15)
legend('Correct', 'Incorrect', 'Missing', 'True Order', 'FontSize', 15)
title('JPLS', 'FontSize', 15)
ylabel('Number of Features ', 'FontSize', 15)
xlabel('Time', 'FontSize', 15)

% OLinLASSO features BAR plots
subplot(1,3,2)
ob = bar(t0:T, olin_features', 'stacked', 'FaceColor', 'flat', 'FaceAlpha', 1);
hold on
ob(1).CData = [0, 0.7, 0];
ob(2).CData = [0,0,0];
ob(3).CData = [0.6, 0.6, 0.6];
yline(dy-ps, 'Color', 'b', 'LineWidth', 5)
ylim([0, dy])
set(gca, 'FontSize', 15)
legend('Correct', 'Incorrect', 'Missing', 'True Order', 'FontSize', 15)
title('OLinLASSO', 'FontSize', 15)
ylabel('Number of Features ', 'FontSize', 15)
xlabel('Time', 'FontSize', 15)


% PREDICTIVE ERROR Plots
subplot(1,3,3);
plot(J_jpls - J_olin, 'k', 'LineWidth', lwd)
hold on
plot(J_jpls - J_true,  'Color', [0.5, 0, 0], 'LineWidth', lwd)
hold on
plot(J_olin - J_true, 'Color', [0, 0.5, 0], 'LineWidth', lwd)
yline(0, 'b', 'linewidth',1)
set(gca, 'FontSize', 15)
legend('J_{JPLS} - J_{OLin}', 'J_{JPLS} - J_{TRUE}', 'J_{OLin} - J_{TRUE}', 'FontSize', 17)
xlabel('Time', 'FontSize', fsz)
ylabel('Predictive Error Difference', 'FontSize', fsz)
grid on


figure;
plot(J_jpls./J_olin, 'k', 'LineWidth', lwd)
hold on
plot(J_jpls./J_true,  'Color', [0.5, 0, 0], 'LineWidth', lwd)
hold on
plot(J_olin./J_true, 'Color', [0, 0.5, 0], 'LineWidth', lwd)
set(gca, 'FontSize', 15)
legend('J_{JPLS} /J_{OLin}', 'J_{JPLS} / J_{TRUE}', 'J_{OLin} / J_{TRUE}', 'FontSize', 17)
xlabel('Time', 'FontSize', fsz)
ylabel('Predictive Error Ratios', 'FontSize', fsz)
grid on


title_str = join(['\sigma^2 = ', str_v, ...
    '     {\bf h_k } ~ N( {\bf 0}, ', num2str(r), '{\bf I} )  ' , '  {\bf \theta } ~ N( {\bf 0} ', num2str(rt), '{\bf I} ) ']) ; 

sgtitle(title_str, 'FontSize', 20)

