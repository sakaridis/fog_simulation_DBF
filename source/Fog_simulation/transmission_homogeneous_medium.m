function t = transmission_homogeneous_medium(d, beta, camera_parameters_file)
%TRANSMISSION_HOMOGENEOUS_MEDIUM  Compute transmission map using given depth
%map, based on the Beer-Lambert law. Distinguish between scene depth |d| and
%distance between camera and object depicted at each pixel, |l|.
%   Inputs:
%       -|d|: H-by-W matrix with values of depth for processed image in meters.
%       -|beta|: attenuation coefficient. Constant, since the medium is
%       homogeneous.
%
%   Outputs:
%       -|t|: H-by-W matrix with medium transmission values ranging in [0, 1].

% Add directory with |distance_in_meters_cityscapes| function to path.
current_function_full_name = mfilename('fullpath');
path_str = fileparts(current_function_full_name);
path_split = strsplit(path_str, filesep);
parent_dir_str = strjoin(path_split(1:end - 1), filesep);
addpath(fullfile(parent_dir_str, 'Depth_processing'));

% Compute scene distance from camera for each pixel.
l = distance_in_meters_cityscapes(d, camera_parameters_file);

% Beer-Lambert law for homogeneous medium.
t = exp(-beta * l);

end

