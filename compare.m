clear all
close all
clc

% Settings
var_y = 0.01;   % Variance
ps = 4;     % Sparsity percent
dy = 6;      % System dimension
r = 1;       % Range of input data H
rt = 2;      % Range of theta
T = 300;
n = round(0.3*T);
Ns = 2000;
Nb = 1000;
Tb = 150;

R = 1;


time_mcmc = zeros(R);
time_orls = zeros(R);
orls_run = zeros(R);
mcmc_run = zeros(R);


tic
for run = 1:R

    %Create data
    [y, H, theta] = generate_data(T, dy, r, rt,  ps, var_y);
    idx_h = find(theta ~= 0)';

    % Pad original true indices for comparison
    idx_h_padded = [idx_h zeros(1, dy - length(idx_h))];


    % RJ MCMC ___________________________________________________
    % Data partition and Number of sweeps
    tic
    [idx_mcmc, theta_RJ, models_mcmc, count_mcmc, Nm] = rj_mcmc(y, H, n, Ns, Nb);
    time_mcmc(run) = toc;


    % Check through all models
    idx_corr_mcmc = 0;
    for m = 1:length(models_mcmc(:,1))
        if (sum(models_mcmc(m,:) == idx_h_padded ) == dy)
            idx_corr_mcmc = m;
        end
    end


    % PJ ORLS___________________________________________________
    tic
    init = dy + 1;
    [theta_k, Hk, k_store, k_mode, models_orls, count_orls, idx_orls, J] = pj_orls(y, H, dy, var_y, init, Tb);
    time_orls(run) = toc;



    % Check through all models
    idx_corr_orls = 0;
    for m = 1:length(models_orls(:,1))
        if (sum(models_orls(m,:) == idx_h_padded ) == dy)
            idx_corr_orls = m;
        end
    end


    % LASSO
    [B, STATS] = lasso(H, y, 'CV', 10);
    theta_lasso = B(:, STATS.IndexMinMSE);
    idx_lasso = find(theta_lasso ~= 0);

    idx_corr_lasso = 0;
    if (sum(idx_lasso == idx_h_padded ) == dy)
        idx_corr_lasso = 1;
    end


    orls_run(run) = idx_corr_orls;
    mcmc_run(run) = idx_corr_mcmc;
    lasso_run(run) = idx_corr_lasso;
end
toc

% Anything below 5
orls_run(orls_run > 4) = 5;
mcmc_run(mcmc_run > 4) = 5;


% Average run time ratio
avg_time = mean(time_mcmc./time_orls);


R = length(orls_run);

str_dy = num2str(dy);
str_k = num2str(dy - ps);
str_T = num2str(T);
str_v = num2str(var_y);
str_R = num2str(R);

% filename = join(['Results/T', str_T, '_K', str_dy, '_k', str_k, '_v', str_v, ...
%     '_R', str_R, '.mat']);
% 
% save(filename)

% figure;
% plot(J, 'Color', 'k', 'Linewidth', 3)
% 
% 
% 
% 
% 
% % Bar plot
% figure;
% subplot(1,2, 1)
% b_orls = bar(count_orls/(T - Tb), 'FaceColor', 'flat');
% %ylim([0, 0.4])
% ylabel('Number of Visits')
% title('ORLS Models visited ','FontSize',20)
% set(gca, 'FontSize', 20);
% grid on
% if (idx_corr_orls==0)
%     text(1,0.1, 'True Model NOT visited', 'FontSize', 15)
% else
%     b_orls.CData(idx_corr_orls,:) = [0.5, 0, 0];
% end
% 
% 
% % Bar plot
% subplot(1,2, 2)
% b_mcmc = bar(count_mcmc/(Ns - Nb), 'FaceColor', 'flat');
% %ylim([0, 0.4])
% ylabel('Number of Visits')
% title('RJMCMC Models visited','FontSize',20)
% set(gca, 'FontSize', 20);
% grid on
% b_mcmc.CData(idx_corr_mcmc,:) = [0, 0, 0];
% 

