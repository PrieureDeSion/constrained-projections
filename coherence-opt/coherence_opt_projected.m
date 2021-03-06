%% Designing Constrained Projections for Compressed Sensing
% Constrained optimization of the sensing matrix be minimizing the
% (average) coherence of \Phi\Psi. Entries of \Phi constrained to be
% non-negative and in the range of [0, 1] --  optical constraints.
%  Written by Dhruv Ilesh Shah (dhruv.ilesh@gmail.com)

%% init
clear all; close all;
addpath('../misc');

patch_dim = 16;
measurements = [32, 48, 64, 96, 128];
N = patch_dim ^ 2;
max_iter = 2000;
% step_size = 1e-6;
rng(40); % 40
mu_av = zeros(max_iter, size(measurements, 2));
mu_mx = zeros(max_iter, size(measurements, 2));
gd_err = zeros(max_iter, size(measurements, 2));

% set desired representation matrix
psi = kron(dctmtx(patch_dim)', dctmtx(patch_dim )'); % 2D-DCT Representation Matrix
% psi = kron(haarmtx(patch_dim)', haarmtx(patch_dim)'); % 2D-Haar Representation Matrix

for m = 1 : size(measurements, 2)
    M = measurements(m)
    phi_org = rand(M, N); % Uniform(0, 1) init
    D_org = phi_org * psi; % Overall sensing matrix
    D = D_org;
    phi = phi_org;
    step_size = 1e-4;
    
    for i = 1:max_iter
        [mu_av(i, m), mu_mx(i, m)] = compute_coherence(D);
        gd_err(i, m) = trace(((D' * D) - eye(size(D, 2))) * ((D' * D) - eye(size(D, 2)))');
        del_D = D * (D' * D - eye(size(D, 2)));
        upd_D = D - step_size * del_D;

        upd_phi = upd_D * psi';
        % Taking projection
        proj_phi = get_projection(upd_phi);
        [mu_av_proj, mu_mx_proj] = compute_coherence(proj_phi * psi);
        if (mu_av_proj > mu_av(i, m))
            % Reduce step_size and DO NOT update phi
            sprintf('Decreasing step size to %f', step_size/2)
            step_size = step_size / 2; % Adaptive step size
        else
            phi = proj_phi;
            D = phi * psi;
        end
    end
    phi_con = phi;
    D_con = D;
    save(strcat('../designed-matrices/coherence-opt/2ddct/projected/opt-mat-sanei-16-M', num2str(M), '.mat'), 'phi_org', 'phi_con', 'D_org', 'D_con');
end

% Visualizing trends
% figure;
% for i = 1:size(measurements, 2)
% plot(mu_av(:, i));
% hold on
% end
% xlabel('Iterations');
% ylabel('\mu_{av}');
% legend(strtrim(cellstr(num2str((measurements/N)'))'));
% title('Optimizing sensing matrix by minimizing \mu_{av} [Abolghasemi et al 2010]');