function [angle, peaks_idx] = process_T_array(self, data)
%% Process data from a T-array of sensors.
%%
%% [angle, peaks_idx] = process_T_array(data)
%%
%% Calculate the angle of arrival of the wave from the signal in
%% `data`.
%% 
%% Parameters:
%% data : matrix
%%     A 4-column matrix with the signal read from a T-array of
%%     sensors.
%%
%% Returns:
%% angle : double
%%     The angle of arriavle of the wave. If no angle is found,
%%     returns an empty matrix.
%% peaks_idx : 1x4 matrix
%%     The indeces of the peaks in each column of input `data`. If
%%     no angle is found, returns an empty matrix.

angle = [];
NO_IMPACT_MSG = 'No peak found.';
if isempty(data)
    self.log(NO_IMPACT_MSG);
    return
end

min_point = 6;

%% sensor 1 cluster signal processing for angle detection
sensor1_data = data(:, 1 : 3);

% get first wave arrival point
% active threshold setup
threshold_over_point = self.point_over_threshold(sensor1_data(:, 1), self.threshold);

if isempty(threshold_over_point)
    self.log(NO_IMPACT_MSG);
    return
end

% find sensor 1 signal peak point
peak_point = [];
range = threshold_over_point : size(sensor1_data, 1);
peak_point(1) = self.find_peak(sensor1_data(range, 1)) + range(1) - 1;

% find sensor 2 signal peak point
range = peak_point(1) : size(sensor1_data, 1);
for j = 2 : 3
    peak_point(j) = self.find_peak(sensor1_data(range, j)) + range(1) - 1;
    if peak_point(j) - peak_point(1) < min_point
        range = peak_point(j) + 1 : size(sensor1_data, 1);
        peak_point(j) = self.find_peak(sensor1_data(range, j)) + range(1) - 1;
    end
end

peaks_idx(3) = peak_point(3);

dt21 = peak_point(2) - peak_point(1);
dt31 = peak_point(3) - peak_point(1);
dist21 = 1;
dist31 = 1;
angle1 = atan((dist21 * dt21) / (dist31 * dt31));

%% sensor 2 cluster signal processing for angle detection
sensor2_data = data(:, [1 2 4]);

% get first wave arrival point
% active threshold setup
threshold_over_point = self.point_over_threshold(sensor2_data(:, 1), self.threshold);

% find sensor 1 signal peak point
peak_point = [];
range = threshold_over_point : size(sensor2_data, 1);
peak_point(1) = self.find_peak(sensor2_data(range, 1)) + range(1) - 1;

% find sensor 2 signal peak point
range = peak_point(1) : size(sensor2_data, 1);
for j = 2 : 3
    peak_point(j) = self.find_peak(sensor2_data(range, j)) + range(1) - 1;
    if peak_point(j) - peak_point(1) < min_point
        range = peak_point(j) + 1 : size(sensor2_data, 1);
        peak_point(j) = self.find_peak(sensor2_data(range, j)) + range(1) - 1;
    end
end

peaks_idx([1, 2, 4]) = peak_point;

threshold_over_point_L = self.point_over_threshold(data(:, 3), self.threshold);
threshold_over_point_R = self.point_over_threshold(data(:, 4), self.threshold);

dt21 = peak_point(2) - peak_point(1);
dt31 = peak_point(3) - peak_point(1);
dist21 = 1;
dist31 = 1;
angle2 = pi - atan((dist21 * dt21) / (dist31 * dt31));
% now we have angle1 and angle2!

if threshold_over_point_R<threshold_over_point_L
    angle = angle1;
else
    angle = angle2;
end
