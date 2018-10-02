function t = transmittance_postprocessing_dual_bilateral_filter(t, I, labels,...
    L, transmittance_postprocessing_parameters, varargin)
%TRANSMITTANCE_POSTPROCESSING_DUAL_BILATERAL_FILTER  Postprocess an already
%complete transmittance map with a dual-range cross-bilateral filter using
%semantics and color as references.

% Convert to unit range CIELAB.
I_CIELAB = RGB_to_CIELAB_unit_range(I);
intensity_min = shiftdim(min(min(I_CIELAB, [], 1), [], 2)).';
intensity_max = shiftdim(max(max(I_CIELAB, [], 1), [], 2)).';

% Read parameters for dual-range color cross-bilateral filter.
sigma_spatial = transmittance_postprocessing_parameters.sigma_spatial;
sigma_intensity = transmittance_postprocessing_parameters.sigma_intensity;
kernel_radius_in_std =...
    transmittance_postprocessing_parameters.kernel_radius_in_std;
lambda = transmittance_postprocessing_parameters.lambda;

% Set the rest parameters to their recommended values.
sampling_spatial = sigma_spatial;
sampling_intensity = sigma_intensity;

% Postprocess by filtering.
t = dual_range_color_cross_bilateral_filter_with_bilateral_grids(t, labels,...
    I_CIELAB, 1, L, intensity_min, intensity_max, sigma_spatial,...
    sampling_spatial, sigma_intensity, sampling_intensity,...
    kernel_radius_in_std, lambda);

end

