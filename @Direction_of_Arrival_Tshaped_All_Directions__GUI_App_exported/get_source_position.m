function [x, y] = get_source_position(app, varargin)
%% Get impact position based on the angles obtained from
%% T-arrays.

if ~isempty(varargin)
    plot_flag = varargin{1} == 'plot';
end

m1 = tan(app.angles(1));
m2 = tan(app.angles(2) + pi);
x = app.distance / (m1 - m2);
y = m1 * x;
app.last_position = [x, y];
app.log(sprintf('position=(%0.1f, %0.1f)', x, y));

if plot_flag
    fig = figure();
    set(fig, 'Name', 'Source localization');
    plot([0, x, 0], [0, y, app.distance], 'k--');
    hold on;
    plot([0, 0], [0, app.distance], 'bo');
    plot(x, y, 'r*');
    axis equal;
    y_lims = [min(0, y), max(app.distance, y)]
    x_lim = max([app.distance, diff(y_lims), 2*x]);
    xlim([-x_lim/2, +x_lim/2])
    ylim(y_lims)
    grid on;
    legend('Direction', 'Sensors', 'Source');
    xlabel('x');
    ylabel('y');
    title(sprintf('Position: x=%0.1f, y=%0.1f', x, y));
end
