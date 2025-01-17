function [theta_k, Dk, Hk, idx_H] = ols_downdates(theta_k, Dk, rm_idx, Ht, t, K)


% Code for D change (before update)
% Let be the column removed (or min_k)
k = length(Dk(1,:));
idx = 1:k;
idx = setdiff(idx, rm_idx);


% Hk update
Hk = Ht(1:t, [idx, rm_idx]);

% Update H  - only store indices
idx_H = [idx, k+1:K, rm_idx];
%H = H(:, [idx, K+1:dx, min_k]);

% Get Dk tilde by swapping 
Dk_swap = Dk(idx, idx);
Dk_swap(k, 1:k-1) = Dk(rm_idx, idx);
Dk_swap(:, k) = Dk([idx, rm_idx], rm_idx);

% Now Dk downdate code
DK11 = Dk_swap(1:k-1, 1:k-1);
DK12 = Dk_swap(1:k-1, k);
%DK21 = Dk_swap(K, 1:K-1);
DK22 = Dk_swap(k,k);


% Final DK
Dk = DK11 - DK12*DK12' /( DK22 );


% Ratio
ratio = DK12/DK22;


% Update rest of theta elements
theta_k(idx) = theta_k(idx) - ratio*theta_k(rm_idx);


% theta(k-1) < --- theta(k)
theta_k(rm_idx) = [];





end