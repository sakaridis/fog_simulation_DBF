clear;

% Define the parameters.

task_id = 1;
images_per_task = 1525;
dataset_split = 'test';
refinement_level = 'full';
variant = 'stereoscopic_inpainting_with_dual_range_cross_bilateral_filtering';
beta = 0.01;

% Can be changed to preferred directory for writing results of simulation.
output_root_directory = fullfile('..', '..', 'output', 'Foggy_Cityscapes-DBF');

% Run the experiment with a single thread. This experiment takes around a day to
% be completed.
% Please refer to the bash scripts that are also included in the directory of
% this MATLAB script for examples of parallel execution on a Linux cluster.

Fog_simulation_Cityscapes(task_id, dataset_split, refinement_level,...
    variant, beta, output_root_directory, images_per_task);