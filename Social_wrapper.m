%% Clear workspace
clear all
SIM = 0;
FIT = 1;
rng(23);
%% Construct the appropriate path depending on the system this is run on
% If running on the analysis cluster, some parameters will be supplied by 
% the job submission script -- read those accordingly.

dbstop if error

if ispc
    root = 'L:/';
    experiment = 'prolific'; % indicate local or prolific
    room = 'Like';
    model = 'UCB';
    results_dir = sprintf([root 'rsmith/lab-members/cgoldman/Wellbeing/social_media/output/%s/%s/'], experiment, model);
    id = '659ab1b4640b25ce093058a2'; % 666878a27888fdd27f529c64 60caf58c38ce3e0f5a51f62b 668d6d380fb72b01a09dee54 659ab1b4640b25ce093058a2
    MDP.field = {'sigma_d', 'baseline_noise', 'side_bias', 'sigma_r', 'DE_RE_horizon', 'baseline_info_bonus', 'reward_sensitivity'};
elseif ismac
    root = '/Volumes/labs/';
elseif isunix 
    root = '/media/labs/'
    results_dir = getenv('RESULTS')   % run = 1,2,3
    room = getenv('ROOM') %Like and/or Dislike
    experiment = getenv('EXPERIMENT')
    id = getenv('ID')
    MDP.field = strsplit(getenv('FIELD'), ',')

end

addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);

%% Set parameters or run loop over all-----
% study = 'prolific'; %prolific or local

% indicate if you want the same parameter to control directed exploration
% (increased likelihood of choosing high info option in H5) and random
% exploration (increased choice randomness on H5 trials)
if any(strcmp('DE_RE_horizon', MDP.field))
    MDP.combined_DE_RE_horizon = 1; % setting to combine DE and RE
    MDP.params.DE_RE_horizon = 2.5; % prior on this value
else
    MDP.combined_DE_RE_horizon = 0; % setting to NOT combine DE and RE
%     MDP.params.DE_RE_horizon = 0; % prior that doesn't get fit

    if any(strcmp('info_bonus', MDP.field))
        MDP.params.info_bonus = 5; 
    else
        MDP.params.info_bonus = 0; 
    end
    if any(strcmp('random_exp', MDP.field))
        MDP.params.random_exp = 2.5;
    else
        MDP.params.random_exp = 0;
    end
end

MDP.params.sigma_d = .25;
MDP.params.side_bias = 0; 
MDP.params.initial_sigma = 1000;
MDP.params.sigma_r = 4;
MDP.params.baseline_info_bonus = 0; 
MDP.params.initial_mu = 50;
MDP.params.baseline_noise = 1;
MDP.params.reward_sensitivity = 1;


if SIM
    % choose generative mean difference of 2, 4, 8, 12, 24
    gen_mean_difference = 8; %
    % choose horizon of 1 or 5
    horizon = 5;
    % if truncate_h5 is true, use the H5 bandit schedule but truncate so that
    %all games are H1
    truncate_h5 = 0;
    simulate_social_media(MDP.params, gen_mean_difference, horizon, truncate_h5);
end
if FIT
    fits_table = get_fits(root, experiment, room, results_dir,MDP, id);
end


% Effect of DE - people more likely to pick high info in H6 vs H1
% Effect of RE - people behave more randomly in H5 vs H1. Easier to see when set info_bonus to 0 and gen_mean>4. 
% Increasing confidence within game - can see in some games e.g., game 8
% (gen_mean=4), game 2 (gen_mean=8)