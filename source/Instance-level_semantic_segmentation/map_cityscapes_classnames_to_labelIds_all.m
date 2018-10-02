function class_names2label_ids = map_cityscapes_classnames_to_labelIds_all()

% class_ids.void = uint8(0);
% class_ids.road = uint8(7);
% class_ids.sidewalk = uint8(8);
% class_ids.building = uint8(11);
% class_ids.wall = uint8(12);
% class_ids.fence = uint8(13);
% class_ids.pole = uint8(17);
% class_ids.traffic_light = uint8(19);
% class_ids.traffic_sign = uint8(20);
% class_ids.vegetation = uint8(21);
% class_ids.terrain = uint8(22);
% class_ids.sky = uint8(23);
% class_ids.person = uint8(24);
% class_ids.rider = uint8(25);
% class_ids.car = uint8(26);
% class_ids.truck = uint8(27);
% class_ids.bus = uint8(28);
% class_ids.train = uint8(31);
% class_ids.motorcycle = uint8(32);
% class_ids.bicycle = uint8(33);

class_names = {'unlabeled', 'ego vehicle', 'rectification border',...
    'out of roi', 'static', 'dynamic', 'ground', 'road', 'sidewalk',...
    'parking', 'rail track', 'building', 'wall', 'fence', 'guard rail',...
    'bridge', 'tunnel', 'pole', 'polegroup', 'traffic light', 'traffic sign',...
    'vegetation', 'terrain', 'sky', 'person', 'rider', 'car', 'truck', 'bus',...
    'caravan', 'trailer', 'train', 'motorcycle', 'bicycle'};
label_ids = uint8([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,...
    22,23,24,25,26,27,28,29,30,31,32,33]);

class_names2label_ids = containers.Map(class_names, label_ids);

end