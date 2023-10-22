function [models_sorted, count_sorted, theta_sorted, idx_orls] = model_sorting(M, Nb, dy, theta)

% Apply models
M_burn = M;
M_burn(1:Nb) = [];
theta(1:Nb) = [];

% Find unique models
models = unique(cell2mat(M_burn'), 'rows');
Nm = length(models(:,1));
count = zeros(1,Nm);
theta_sorted = zeros(Nm, dy);

% For each unique model
for m = 1:Nm

    % Current model to check for
    Mk = models(m,:);

    % Check all sweeps
    for s = 1: length(M) - Nb
        if (sum(Mk == M_burn{s}) == dy)
            count(m) = count(m) + 1;
            theta_sorted(m, nonzeros(M_burn{s})) = theta{s};
        end     
    end

end

% Sort count and find max
[count_sorted, idx_sorted] = sort(count, 'descend');
models_sorted = models(idx_sorted,:);
theta_sorted = theta_sorted(idx_sorted,:);
idx_orls = nonzeros(models_sorted(1,:))';


end