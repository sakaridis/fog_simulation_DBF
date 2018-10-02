function [output, mask_undefined] =...
    dual_range_color_cross_bilateral_filter_with_bilateral_grids(input_image,...
    labels, color_ref, label_min, label_max, intensity_min,...
    intensity_max, sigma_spatial, sampling_spatial, sigma_intensity,...
    sampling_intensity, kernel_radius_in_std, lambda)
%DUAL_RANGE_COLOR_CROSS_BILATERAL_FILTER_WITH_BILATERAL_GRIDS  Cross-bilateral
%filter using two range domains in disjunction, namely the (semantic) labels of
%the input image plus a second image of color intensities, as references for
%defining filtering weights. Implementation is based on the **bilateral grid**
%approach for performing approximate bilateral filtering, adjusted from the code
%provided by Jiawen Chen:
%http://people.csail.mit.edu/jiawen/software/bilateralFilter.m
%
%   INPUTS:
%
%   -|input_image|: |input_height|-by-|input_width| matrix with elements of type
%    double. May contain |nan| elements, which correspond to pixels with missing
%    value. It is a required argument of the function.
%
%   -|labels|: matrix of the same size and type as |input_image|. Must only
%    contain values that are equal to an integer, so that they are interpretable
%    as labels. It is a required argument of the function.
%
%   -|color_ref|: 3D matrix with the same number of rows and columns and the
%    same type as |input_image|. Must not contain |nan| values. It is a required
%    argument of the function.
%
%   -|label_min|: lower end of range of |labels| values. Defaults to minimum
%    value in |labels|.
%
%   -|label_max|: upper end of range of |labels| values. Defaults to maximum
%    value in |labels|.
%
%   -|intensity_min|: lower ends of range of values of |color_ref| channels.
%    Defaults to 1-by-3 array with minimum values in channels of |color_ref|.
%    Reflects prior knowledge about the domain of |color_ref|.
%
%   -|intensity_max|: upper ends of range of values of |color_ref| channels.
%    Defaults to 1-by-3 array with maximum values in channels of |color_ref|.
%    Reflects prior knowledge about the domain of |color_ref|.
% 
%   -|sigma_spatial|: standard deviation of the space Gaussian. Defaults to
%    |min(input_width, input_height) / 16|.
%
%   -|sampling_spatial|: amount of downsampling used for the approximation in
%    the spatial domain. Defaults to |sigma_spatial|.
%
%   -|sigma_intensity|: standard deviation of the range Gaussian. Defaults to
%    |(intensity_max - intensity_min) / 10|.
%
%   -|sampling_intensity|: amount of downsampling used for the approximation in
%    the intensity range domain. Defaults to |sigma_intensity|.
%
%   -|kernel_radius_in_std|: "radius", i.e. half width, of the Gaussian kernel
%    tensor that is used in the bilateral grid approach, measured in units of
%    the respective standard deviation for each dimension.
%
%   -|lambda|: positive scalar that controls the relative weight of the
%    intensity range domain compared to the label range domain in the dual-range
%    filter.
%
%   OUTPUTS:
%
%   -|output|: filtered image as a matrix of the same size and type as
%    |input_image|.
%
%   -|mask_undefined|: |input_height|-by-|input_width| matrix of logical values.
%    True where and only where |output| is well-defined.

if ndims(input_image) > 2
    error('Input to filter must be a grayscale image with size [height, width]');
end

if ~isa(input_image, 'double')
    error('Input to filter must be of type "double"');
end

if ~exist('labels', 'var')
    error('Label image is required for semantic cross-bilateral filter.');
end

if ndims(labels) > 2
    error('Label image must be a grayscale image with size [ height, width ]');
end

if ~isa(labels, 'double')
    error('Label image must be of type "double"');
end

if ~exist('color_ref', 'var')
    error('Color reference image is required for dual-range color cross-bilateral filter.');
end

if ndims(color_ref) ~= 3
    error(strcat('Color reference image must be a color image',...
        ' with size [height, width]'));
end

if ~isa(color_ref, 'double')
    error('Color reference image must be of type "double"');
end

if any(any(isnan(color_ref)))
    error('Color reference image must not contain any NaN element');
end

if ~exist('label_min', 'var')
    label_min = min(labels(:));
    warning('Minimum label value not set! Defaulting to: %f\n', label_min);
end

if ~exist('label_max', 'var')
    label_max = max(labels(:));
    warning('Maximum label value not set! Defaulting to: %f\n', label_max);
end

label_range = label_max - label_min;

if ~exist('intensity_min', 'var')
    intensity_min = shiftdim(min(min(color_ref, [], 1), [], 2)).';
    warning('intensity_min not set!  Defaulting to: %f\n', intensity_min);
end

if ~exist('intensity_max', 'var')
    intensity_max = shiftdim(max(max(color_ref, [], 1), [], 2)).';
    warning('intensity_max not set!  Defaulting to: %f\n', intensity_max);
end

intensity_range = intensity_max - intensity_min;

input_height = size(input_image, 1);
input_width = size(input_image, 2);

if ~exist('sigma_spatial', 'var')
    sigma_spatial = min(input_width, input_height) / 64;
    fprintf('Using default sigma_spatial of: %f\n', sigma_spatial);
end

if ~exist('sigma_intensity', 'var')
    sigma_intensity = 0.1 * max(intensity_range);
    fprintf('Using default sigma_intensity of: %f\n', sigma_intensity);
end

if ~exist('sampling_spatial', 'var') || isempty(sampling_spatial)
    sampling_spatial = sigma_spatial;
end

if ~exist('sampling_intensity', 'var') || isempty(sampling_intensity)
    sampling_intensity = sigma_intensity;
end

if ~exist('kernel_radius_in_std', 'var')
    kernel_radius_in_std = 1;
end

if any(size(input_image) ~= size(labels)) ||...
        any(size(input_image) ~= [size(color_ref, 1), size(color_ref, 2)])
    error('Input, labels and color reference must be of the same size');
end

if any(labels(:) - round(labels(:)))
    error('Label image must take integer values that are interpretable as labels');
end

% ------------------------------------------------------------------------------

% Parameters.
derived_sigma_spatial = sigma_spatial / sampling_spatial;
derived_sigma_intensity = sigma_intensity / sampling_intensity;

padding_XY = floor(2 * derived_sigma_spatial) + 1;
padding_intensity = floor(2 * derived_sigma_intensity) + 1;

% ------------------------------------------------------------------------------

% 1) Downsampling.

% Split the three channels of the color reference image.
color_1 = color_ref(:, :, 1);
color_2 = color_ref(:, :, 2);
color_3 = color_ref(:, :, 3);

% Compute size of downsampled dimensions of bilateral grids.
downsampled_width =...
    floor((input_width - 1) / sampling_spatial) + 1 + 2 * padding_XY;
downsampled_height =...
    floor((input_height - 1) / sampling_spatial) + 1 + 2 * padding_XY;
downsampled_intensity_range =...
    floor(intensity_range / sampling_intensity) + 1 +...
    2 * repmat(padding_intensity, 1, 3);

% Compute indices for bilateral grids.
[jj, ii] = meshgrid(0:input_width - 1, 0:input_height - 1);
di = round(ii / sampling_spatial) + padding_XY + 1;
dj = round(jj / sampling_spatial) + padding_XY + 1;
dl = labels - label_min + 1;

dc1 = round((color_1 - intensity_min(1)) / sampling_intensity) +...
    padding_intensity + 1;
dc2 = round((color_2 - intensity_min(2)) / sampling_intensity) +...
    padding_intensity + 1;
dc3 = round((color_3 - intensity_min(3)) / sampling_intensity) +...
    padding_intensity + 1;

% Calculate auxiliary matrices that are used to populate the bilateral grid by
% handling NaN values as zeros, i.e. ignoring their contribution.
input_nan_mask = isnan(input_image);
input_image_nans_as_zeros = input_image;
input_image_nans_as_zeros(input_nan_mask) = 0;
% Abusive variable name. After the following assignment, |input_nan_mask| is
% rather a mask of non-NaN values.
input_nan_mask = double(~input_nan_mask);

% Compute the two bilateral grids, one for the labels and the other for the
% intensity, with one shot using |accumarray|, which accumulates all the values
% that correspond to a single subscript tuple by default.
label_grid_image =...
    accumarray([di(:), dj(:), dl(:)], input_image_nans_as_zeros(:),...
    [downsampled_height, downsampled_width, label_range + 1]);
label_grid_weights =...
    accumarray([di(:), dj(:), dl(:)], input_nan_mask(:),...
    [downsampled_height, downsampled_width, label_range + 1]);

intensity_grid_image =...
    accumarray([di(:), dj(:), dc1(:), dc2(:), dc3(:)],...
    input_image_nans_as_zeros(:), [downsampled_height, downsampled_width,...
    downsampled_intensity_range]);
intensity_grid_weights =...
    accumarray([di(:), dj(:), dc1(:), dc2(:), dc3(:)], input_nan_mask(:),...
    [downsampled_height, downsampled_width, downsampled_intensity_range]);

% Build the two 3D kernels corresponding to the grids.

% The kernel for the label grid is separable into a spatial Gaussian kernel and
% a range impulse kernel (the range dimension is discrete). Therefore, we can
% use the spatial part of the kernel on its own and abandon the range part.
kernel_width = 2 * ceil(kernel_radius_in_std * derived_sigma_spatial) + 1;
kernel_height = kernel_width;

kernel_half_width = floor(kernel_width / 2);
kernel_half_height = floor(kernel_height / 2);

[grid_X, grid_Y] = meshgrid(0:kernel_width - 1, 0:kernel_height - 1);
grid_X = grid_X - kernel_half_width;
grid_Y = grid_Y - kernel_half_height;
grid_R_squared = (grid_X .* grid_X + grid_Y .* grid_Y) /...
    (derived_sigma_spatial ^ 2);
label_kernel = exp(-0.5 * grid_R_squared);
label_kernel = label_kernel ./ sum(label_kernel(:));

% Kernel for intensity grid.
intensity_kernel_depth =...
    2 * ceil(kernel_radius_in_std * derived_sigma_intensity) + 1;
intensity_kernel_half_depth = floor(intensity_kernel_depth / 2);

[grid_X, grid_Y, grid_C1, grid_C2, grid_C3] = ndgrid(0:kernel_width - 1,...
    0:kernel_height - 1, 0:intensity_kernel_depth - 1,...
    0:intensity_kernel_depth - 1, 0:intensity_kernel_depth - 1);
grid_X = grid_X - kernel_half_width;
grid_Y = grid_Y - kernel_half_height;
grid_C1 = grid_C1 - intensity_kernel_half_depth;
grid_C2 = grid_C2 - intensity_kernel_half_depth;
grid_C3 = grid_C3 - intensity_kernel_half_depth;
grid_R_squared =...
    (grid_X .* grid_X + grid_Y .* grid_Y) / (derived_sigma_spatial ^ 2) +...
    (grid_C1 .* grid_C1 + grid_C2 .* grid_C2 + grid_C3 .* grid_C3) /...
    (derived_sigma_intensity ^ 2);
intensity_kernel = exp(-0.5 * grid_R_squared);
intensity_kernel = intensity_kernel ./ sum(intensity_kernel(:));

% ------------------------------------------------------------------------------

% 2) Convolution.

% Even though |label_kernel| has two dimensions, MATLAB's |convn| is able to
% apply it on the 3D |label_grid_image| as if it had a third, singleton
% dimension, and generate the corresponding 3D result.
blurred_label_grid_image = convn(label_grid_image, label_kernel, 'same');
blurred_label_grid_weights = convn(label_grid_weights, label_kernel, 'same');

blurred_intensity_grid_image =...
    convn(intensity_grid_image, intensity_kernel, 'same');
blurred_intensity_grid_weights =...
    convn(intensity_grid_weights, intensity_kernel, 'same');

% ------------------------------------------------------------------------------

% 3) Upsampling and slicing.

% Indices for upsampling: no rounding.
di = (ii / sampling_spatial) + padding_XY + 1;
dj = (jj / sampling_spatial) + padding_XY + 1;
dc1 = (color_1 - intensity_min(1)) / sampling_intensity +...
    padding_intensity + 1;
dc2 = (color_2 - intensity_min(2)) / sampling_intensity +...
    padding_intensity + 1;
dc3 = (color_3 - intensity_min(3)) / sampling_intensity +...
    padding_intensity + 1;

% Use |interpn| to retrieve the filtering output using interpolation from the
% samples of the bilateral grid. Interpolation is linear in all cases.
unnormalized_label_filtered = interpn(blurred_label_grid_image, di, dj, dl);
label_weights = interpn(blurred_label_grid_weights, di, dj, dl);

unnormalized_intensity_filtered =...
    interpn(blurred_intensity_grid_image, di, dj, dc1, dc2, dc3);
intensity_weights = interpn(blurred_intensity_grid_weights, di, dj, dc1, dc2,...
    dc3);

% ------------------------------------------------------------------------------

% 4) Weighted average - division nonlinearity.

% Form denominator of the weighted average.
denominator = label_weights + lambda * intensity_weights;

% Identify pixels where the output is not defined, i.e. the denominator is equal
% to zero, and set them to a non-zero value; corresponding elements of output
% are anyway irrelevant.
mask_undefined = denominator == 0;
denominator(mask_undefined) = -eps;

% Weighted average of the two ranges: the label range and the intensity range.
output = (unnormalized_label_filtered +...
    lambda * unnormalized_intensity_filtered) ./ denominator;

% Put zeros by convention where output is undefined.
% Implicit assumption: |input_image| contains positive values.
output(mask_undefined) = 0;

end
