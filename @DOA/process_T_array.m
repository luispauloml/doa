function angle = process_T_array(self, data, varargin)
%% Process data from a T-array of sensors.
%%
%% angle = process_T_array(data, [plot_figure])
%%
%% Calculate the angle of arrival of the wave from the signal in
%% `data`. If no angle is found, returns an empty matrix.
%% 
%% Parameters:
%% data : matrix
%%     A 4-column matrix with the signal read from a T-array of
%%     sensors.
%% plot_figure : matlab.ui.Figure
%%     A figure in which to plot results. If given, the filtered
%%     signal and the peaks will be plotted. By default, nothing
%%     is plotted.

plot_flag = false;
switch length(varargin)
    case 0
        %% do nothing
    case 1
        try
            plot_figure = varargin{1};
            figure(plot_figure);
            plot_flag = true;
        catch
            error(sprintf("A 'matlab.ui.Figure' was expected as optional argument"));
        end
    otherwise
        error("Only one optional argument is accepted: 'plot_figure'");
end

angle = [];
NO_IMPACT_MSG = 'No peak found.';
filt_data = data;

% data extraction
threshold = 5 * max(filt_data(1 : ceil(0.02 * size(data, 1)), 1));
thres_over_point = self.point_over_threshold(filt_data(:, 1), threshold);

if isempty(thres_over_point)
    self.log(NO_IMPACT_MSG);
    return
end

ext_data = filt_data(thres_over_point - 2000 : thres_over_point + 8000, :);

thres_lev = self.threshold;
min_point = 6;

%% sensor 1 cluster signal processing for angle detection
sensor1_data = ext_data(:, 1 : 3);

% get first wave arrival point
% active threshold setup
threshold_over_point = self.point_over_threshold(sensor1_data(:, 1), thres_lev);

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
sensor2_data = ext_data(:, [1 2 4]);

% get first wave arrival point
% active threshold setup
threshold_over_point = self.point_over_threshold(sensor2_data(:, 1), thres_lev);

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
        peak_point(j) = self.find_peak(sensor2_data(range, j)); + range(1) - 1;
    end
end

peaks_idx([1, 2, 4]) = peak_point;
peaks_vals = [];
for i = 1 : 4
    peaks_vals(i) = ext_data(peaks_idx(i), i);
end

if plot_flag
    self.log('Plotting...');
    figure(plot_figure);
    clf();
    plot(ext_data(2000:end, :));
    hold on;
    plot(peaks_idx - 2000 + 1, peaks_vals, 'ko');
    grid on;
    xlim([1, 5*max(peaks_idx - 2000)]);
    legend('Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4', 'Peaks');
    xlabel('Sample')
    ylabel('Amplitude')
end

threshold_over_point_L = self.point_over_threshold(ext_data(:, 3), thres_lev);
threshold_over_point_R = self.point_over_threshold(ext_data(:, 4), thres_lev);

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
