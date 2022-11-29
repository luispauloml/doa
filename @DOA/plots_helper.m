function ax = plots_helper(varargin)
%% Plot signals, direction or location graphs.
%%
%% ax = plots_helper([axes], ...)
%% ax = plots_helper(..., 'signals', data, [peaks_idx, [threshold]])
%% ax = plots_helper(..., 'direction', angle)
%% ax = plots_helper(..., 'location', angle, distance, position)
%%
%% Returns the axes in which the plot was created.
%%
%% Parameters:
%% axes : axes handle, optional
%%     The handle of the axes where the plot should be created. If not
%%     given, a new figure will be created.
%% 'signals'
%%     Create a plot with the signals read from on array of sensors.
%% 'direction'
%%     Create a plot showing the direction of arrival of the wave.
%% 'location'
%%     Create a plot showing the position of the source of the waves.
%% data : Nx4 matrix
%%     Required for 'signals' plot. A matrix with the signal from
%%     the sensor array. Each column is corresponds to a channel.
%% peaks_idx : 1x4 matrix
%%     Required for 'signals' plot. Indeces of the peaks in
%%     `data`. Each element (1, i) is an index corresponding to a
%%     value in column i of `data`. If not given, peaks won't be
%%     marked in the plot.
%% threshold : scalar, optional
%%     Optional for 'signals' plot. Threshold over which peaks were
%%     detected. If not given, no threshold line will be plotted.
%% angle : scalar or 1x2 matrix
%%     Required for 'direction' and 'location' plots. Angle of arrival
%%     of the wave at the sensor arrays. If 'direction' plot, should
%%     be an scalar; if 'location' plot, should be a 1x2 matrix with
%%     the angles of arrival for both sensor arrays.
%% distance : scalar
%%     Required for 'location' plot. The distance between two sensor
%%     arrays.
%% position : 1x2 matrix
%%     Required for 'location' plot. A matrix of the form [X, Y] with
%%     the X and Y positions of the source.

try
    axes(varargin{1});
catch
    figure();
    %% Append to the left of varargin to adjust its size.  This is
    %% necessary because of the indexes used further down.
    varargin = [0, varargin];
end
ax = gca();

switch varargin{2}
case 'signals'
    data = varargin{3};
    peaks_idx = [];
    threshold = [];
    for i = 1 : length(varargin) - 3
        switch i
            case 1
                peaks_idx = varargin{4};
            case 2
                threshold = varargin{5};
            otherwise
                error(sprintf('%s %s: %s', ...
                              'For `signals` type of plot', ...
                              'there are only two optional parameters', ...
                              '`threshold` and `peaks_idx`'));
        end
    end

    legends = {'Sensor 1', 'Sensor 2', 'Sensor 3', 'Sensor 4'};
    plot(data(:, 1:4));
    hold on;
    if ~isempty(threshold)
        plot([1, size(data, 1)], ...
             [threshold, threshold], ...
             'g--');
        legends{end+1} = 'Threshold';
    end
    if ~isempty(peaks_idx)
        peaks_vals = zeros([1 4]);
        for i = 1 : 4
            peaks_vals(i) = data(peaks_idx(i), i);
        end
        plot(peaks_idx, peaks_vals, 'ko');
        legends{end+1} = 'Peaks';
    end
    grid on;
    legend(legends{:});
    xlabel('Sample');
    ylabel('Amplitude');
    hold off;

case 'direction'
    angle = varargin{3};
    [a, c] = deal(angle(1), atan(2));
    m = tan(a);
    d = 20;
    if a <= c
        plot([0, d/2], [0, m*d/2], 'k--');
    elseif a <= pi - c
        plot([0, d/m], [0, d], 'k--');
    else
        plot([0, -d/2], [0, -m*d/2], 'k--');
    end
    hold on;
    plot(0, 0, 'r*');
    x_lims = [-d/2, +d/2];
    y_lims = [0, d];
    legend('Direction', 'Sensor array');
    title(sprintf('Angle of arrival (deg): a=%0.1f', a/pi*180));
    axis equal;
    set(gca(), 'XTickLabel', {});
    set(gca(), 'YTickLabel', {});
    xlim(x_lims);
    ylim(y_lims);
    xlabel('x');
    ylabel('y');
    grid on;

case 'location'
    angle = varargin{3};
    d = varargin{4};
    position = varargin{5};
    [a, b] = deal(angle(1), angle(2));
    [x, y] = deal(position(1), position(2));
    %% Pin-pointing the source
    plot([0, x, 0], [0, y, d], 'k--');
    hold on;
    plot([0, 0], [0, d], 'bo');
    plot(x, y, 'r*');
    y_lims = [min(0, y), max(d, y)];
    x_lims = max([d, diff(y_lims), abs(2*x)]);
    x_lims = [-x_lims/2, +x_lims/2];
    title(sprintf('%s: x=%0.1f, y=%0.1f\n%s: a=%0.1f, b=%0.1f',...
                  'Position (unit)', x, y,...
                  'Angles of arrival (deg)', a/pi*180, b/pi*180));
    %% Region of impact
    plot([d/2, d/2, -d/2, -d/2, d/2],...
         [0, d, d, 0, 0],...
         'k-.','LineWidth', 2);
    if x > 0 && y > d/2
        %% First quadrant
        line = plot([0, d/2, d/2, 0, 0],...
                    [d/2, d/2, d, d, d/2]);
    elseif x <= 0 && y > d/2
        %% Second quadrant
        line = plot([0, 0, -d/2, -d/2, 0],...
                    [d/2, d, d, d/2, d/2]);
    elseif x <= 0 && y <= d/2
        %% Third quadrant
        line = plot([0, -d/2, -d/2, 0, 0],...
                    [d/2, d/2, 0, 0, d/2]);
    else
        %% Fourth quadrant
        line = plot([0, 0, d/2, d/2, 0],...
                    [d/2, 0, 0, d/2, d/2]);
    end
    set(line, 'LineStyle', '-.',...
        'Color', [0, 0, 1],...
        'LineWidth', 2);
    legend('Direction', 'Sensor arrays', 'Source',...
           'Plate boundary', 'Region of impact',...
           'Location','northeastoutside');
    axis equal;
    xlim(x_lims);
    ylim(y_lims);
    xlabel('x');
    ylabel('y');
    grid on;

otherwise
    error(sprintf('%s: %s; got "%s"', ...
                  'The parameter for plot should be one of', ...
                  '"signals", "direction" or "location"', ...
                  varargin{2}));
end
