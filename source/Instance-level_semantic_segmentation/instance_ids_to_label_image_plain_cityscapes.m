function [label_image, L, complete_instance_ids] =...
    instance_ids_to_label_image_plain_cityscapes(instance_ids)
%INSTANCE_IDS_TO_LABEL_IMAGE_PLAIN_CITYSCAPES  Get labeling of a Cityscapes
%image. Assign a layer label between 1 and |L| to each pixel based on the
%instance-level semantic annotation of the image which is provided in
%Cityscapes.
%
%   INPUTS:
%
%   -|instance_ids|: uint16 matrix with instance IDs for a Cityscapes image, in
%    the format specified in the json2instanceImg.py script which is included in
%    the scripts directory that accompanies the Cityscapes dataset.
%
%   OUTPUTS:
%
%   -|label_image|: double matrix of the same dimensions as |instance_ids|,
%    containing values from 1 to |L|, where |L| is the total number of distinct
%    semantic segments that are inferred from the instance-level annotation.
%
%   -|L|: total number of distinct labels in |label_image|, defining the values
%    that a pixel of it can assume (1, 2, ..., |L|).
%
%   -|complete_instance_ids|: matrix with elements of type uint16, containing
%    instance IDs for the Cityscapes image, where certain class IDs are replaced
%    using the nearest neighbor from the complementary set of classes.


% Create mask for pixels whose instance ID in the original annotation will be
% replaced.
current_function_full_name = mfilename('fullpath');
addpath(fullfile(fileparts(current_function_full_name), '..', 'utilities'));
class_names2label_ids = map_cityscapes_classnames_to_labelIds_all;
class_names_to_replace = {'out of roi'};
labels_to_replace =...
    uint16(cell2mat(values(class_names2label_ids, class_names_to_replace)));
mask = ismember(instance_ids, labels_to_replace);

% Replace instance IDs of specified pixels with the ID of their nearest neighbor
% from the set of pixels that are not affected.
complete_instance_ids = nearest_neighbor_inpainting(instance_ids, mask);

%-------------------------------------------------------------------------------

% Identify all instance IDs that occur in the completed annotation and cache the
% ID of all pixels in a vectorized format via |unique|.
[I, ~, indices_I] = unique(complete_instance_ids);
L = size(I, 1);

% Get label image from indices to label vector |I|.
label_image = reshape(indices_I, size(instance_ids));

end

