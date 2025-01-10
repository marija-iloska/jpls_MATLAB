function [theta_k, idx_jpls, J_pred, plot_stats, idx_store] = tpls(y, H, K, var_y, t0, idx_h)

% This fn is a compact implementation of TPLS only for the purpose of
% generating statistical experiments comparing to other methods. Users
% should see example_code.m for online implementation of TPLS

% Store
H_true = H;
T = length(y);

% Get estimate using half the total features
k = floor(K/2);
%e = [];
[~, ~, theta_k, Dk, ~,~] = initialize(y, H, t0, k, var_y);

% Initialize variables
J_pred = [];
J = 0;

% Model storage
correct = zeros(1,T-t0);
incorrect = zeros(1,T-t0);
idx_store ={};


% Parameter estimate storage
%theta_store = {};

% Dk matrix storage
Dk_jump = {Dk, Dk, Dk};

% Set of all feature indices
idx_H = 1:K;


% Start time loop
for t = t0+1:T

    %% SETUP

    % Update to J(k,t) from J(k,t-1)
    J = J + (y(t) - H(t, 1:k)*theta_k)^2; 

    % Collect current states theta_(k, t-1) J(k,t), Dk(k, t-1)
    stay = {theta_k, idx_H, J, Dk, k};
    
    
    % Reset PE storage
    J_jump = {J, Inf, Inf};


    %% MOVES 

    % STAY SAME
    [theta_jump{1}, idx_jump{1}, J_jump{1}, Dk_jump{1}, k_jump{1}] = stay{:};

    % JUMP UP +
    if (K > k)
        [theta_jump{2}, idx_jump{2}, J_jump{2}, Dk_jump{2}, k_jump{2}] = jump_up(y, K, k, Dk, theta_k, J, H, t, t0, var_y) ;
    end

    % JUMP DOWN -
    if (k > 1)
        [theta_jump{3}, idx_jump{3}, J_jump{3}, Dk_jump{3}, k_jump{3}] = jump_down(y, k, Dk, theta_k, J, H, t, t0, var_y, K);
    end


    %% CRITERION CHOICE
    % Find Model with lowest PredError
    Js = [J_jump{1}, J_jump{2}, J_jump{3}];
    minJ = find(Js == min(Js));


    % Assign quantities to chosen model: all(t-1)
    H = H(:, idx_jump{minJ});
    k = k_jump{minJ};
    Dk = Dk_jump{minJ};
    theta_k = theta_jump{minJ};
    J = J_jump{minJ};


    %% QUANTITIES UPDATES

    % Update and store terms
    Hk = H(1:t, 1:k);
    %theta_store{end+1} = theta_k;

    % PREDICTIVE ERROR STORAGE
    J_pred(end+1) = J;
    %e(end+1) = y(t) - H(t, 1:k)*theta_k; 

    %% EVALUATION

    % Check which model was selected at time t and store
    [~, idx_jpls] = ismember(Hk(1,:), H_true(1,:));

    % Evaluate features
    correct(t-t0) = sum(ismember(idx_jpls, idx_h));
    incorrect(t-t0) = length(idx_jpls) - correct(t-t0);

    % Store current model (feature indices)
    idx_store{end+1} = idx_jpls;

    %% TIME UPDATE 
    
    % theta(k,t) from theta(k,t-1) and Dk(t) from Dk(t-1)
    [theta_k, Dk] = time_update(y(t), Hk(t,:), theta_k, var_y, Dk);



end

% Concatenate results
plot_stats = {correct, incorrect};


end