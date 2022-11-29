classdef DOA < handle
    properties (Access = public)
        aoa = [];               % angles of arrival (rad)
        beep_flag = false;      % beep flag
        daq_session;            % DAQ session for NI device
        data = [];              % post-processed data read from DAQ session
        dir_or_loc = "";        % type of experiment being run
        distance = 50;          % distance between two T-array of sensors (unit)
        filter = struct();      % Butterworth filter for signal processing
        overwrite_plots = true; % flag to overwrite plot results
        peaks_idx = [];         % indeces of peaks
        plots_flag = false      % flag to plot results
        quiet = false;          % quiet flag
        raw_data = [];          % raw data read from DAQ session
        sampl_rate = 1e6;       % sampling rate (samples/s)
        source_position = [];   % position of the source (unit)
        threshold = [];         % lower threshold for peak detection (volts)
    end

    properties (Access = private)
        plot_figures = struct([]); % `Figure` for debugging
    end

    methods (Access = public)
        function self = DOA(direction_or_location, device_name, varargin)
            %% Realize direction of arrival experiments.
            %%
            %% obj = DOA(direction_or_location, device_name, [...])
            %% obj = DOA(..., [Name, Value])
            %% obj = DOA(..., ['quiet'])
            %% obj = DOA(..., ['beep'])
            %% obj = DOA(..., ['plots'])
            %%
            %% Parameters:
            %% direction_or_location : {'direction', 'location'}
            %%     Select the type of experiment.
            %% device_name : char
            %%     The name of the NI device to be used for reading
            %%     data as presented in NI MAX, e.g. 'Dev1'.
            %% 'quiet'
            %%     Suppress log messages.
            %% 'beep'
            %%     Issue a beep sound when it start reading data.
            %% 'plots'
            %%     Plot results.
            %%
            %% Name, Value pairs:
            %% 'distance' : scalar (unit)
            %%     The distance between two T-arrays, default: 50.
            %% 'sampl_rate' : scalar (samples/s)
            %%     The sampling rate, default: 1e6.
            %% 'ftype' : char
            %%     The type of filter, default: 'bandpass'.
            %%     (cf. 'butter' for more information)
            %% 'Wn' : matrix (Hz)
            %%     Filter's cutoff frequency, default: [5e3, 15e3].
            %%     (cf. 'butter' for more information)
            %% 'threshold' : scalar (V)
            %%     The lower threshold for detecting a peak. If not
            %%     given, threshold will be computed
            %%     automaticallity with `calibrate_threshold`.
            %% 'overwite_plots' : logical
            %%     If 'plots' is provided, this value tells whether to
            %%     create new figures for every run, or to overwrite
            %%     the last figures. If true, do not create new figure
            %%     and overwrite the last ones; if false, create new
            %%     figures. Default is true.

            if ~(strcmp(direction_or_location, 'direction') || ...
                 strcmp(direction_or_location, 'location'))
                err_msg = ...
                   sprintf( "DOA: 'direction_or_location' should be either '%s' or '%s', got '%s'.",...
                            'direction', 'location', direction_or_location);
                error(err_msg);
            end
            self.dir_or_loc = direction_or_location;

            %% Filter parameters
            Wn = [5e3, 15e3];
            ftype = 'bandpass';

            next_arg_is_value = false;
            for i = 1 : length(varargin)
                arg = varargin{i};
                if ~next_arg_is_value
                    switch arg
                        case 'quiet'
                            self.quiet = true;
                            next_arg_is_value = false;
                        case 'sampl_rate'
                            self.sampl_rate = varargin{i + 1};
                            next_arg_is_value = true;
                        case 'Wn'
                            Wn = varargin{i + 1};
                            next_arg_is_value = true;
                        case 'ftype'
                            ftype = varargin{i + 1};
                            next_arg_is_value = true;
                        case 'threshold'
                            self.threshold = varargin{i + 1};
                            next_arg_is_value = true;
                        case 'beep'
                            self.beep_flag = true;
                            next_arg_is_value = false;
                        case 'distance'
                            self.distance = varargin{i + 1};
                            next_arg_is_value = true;
                        case 'plots'
                            self.plots_flag = true;
                            next_arg_is_value = false;
                        case 'overwrite_plots'
                            self.overwrite_plots = varargin{i + 1};
                            next_arg_is_value = true;
                        otherwise
                            error(sprintf('invalid argument: %s', arg));
                    end
                else
                    next_arg_is_value = false;
                end
            end

            self.setup_filter(5, Wn, ftype);
            self.setup_device(device_name, direction_or_location);
            if isempty(self.threshold)
                self.calibrate_threshold();
            end
        end

        function setup_filter(self, n, Wn, ftype)
            %% Setup a Butterworth filter for signal processing.
            %%
            %% [] = setup_filter(n, Wn, ftype)
            %%
            %% Cf. `doc butter` for information on the parameters.

            Fn = self.sampl_rate/2;
            [b, c] = butter(n, Wn/Fn, ftype);
            self.filter.b = b;
            self.filter.c = c;
        end

        function setup_device(self, device_name, direction_or_location)
            %% Setup NI device session.
            %%
            %% [] = setup_device(device_name, direction_or_location)
            %%
            %% Paramenters:
            %% device_name : char
            %%     The name of the NI device according to NI MAX, e.g. 'Dev2'.
            %% direction_or_location : {'direction', 'location'}
            %%     The type of experiment to be conducted. For
            %%     'direction' 4 analog input channels are needed, and
            %%     for 'location', 8 channels are need.

            self.log('Setting up device...');
            daq.reset();
            daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization', true);
            ap = daq.createSession('ni');
            duration = 3;
            data_points = duration * self.sampl_rate;
            measuring_range = 10;
            Trigger_level = 0.001;

            switch direction_or_location
                case 'direction'
                    nchannels = 4;
                case 'location'
                    nchannels = 8;
                otherwise
                    error(sprintf('setup_device: invalid value for `direction_or_location`: %s',...
                                  direction_or_duration));
            end
            self.dir_or_loc = direction_or_location;

            for i = 1 : nchannels
                chan_name = sprintf('%s%d','ai',i-1);
                ap.addAnalogInputChannel(device_name, chan_name, 'Voltage');
            end

            %% Setting code as Defined parameteres
            ap.Rate = self.sampl_rate;
            ap.DurationInSeconds = duration;
            ap.IsNotifyWhenDataAvailableExceedsAuto = true;
            ap.NotifyWhenDataAvailableExceeds = self.sampl_rate / 10;

            for i = 1 : nchannels
                ap.Channels(i).Range = [-measuring_range, +measuring_range];
            end

            self.daq_session = ap;
        end

        function data = read_data(self)
            %% Read signal from DAQ session.
            %%
            %% data = read_data()
            %%
            %% Returns `data` as matrix with the signal read from the
            %% DAQ session of current object. The data read is stored
            %% in the object's `raw_data` property.

            self.beep();
            self.log('Reading signal...');
            data = self.daq_session.startForeground();
            self.raw_data = data;
        end

        function data = postprocess(self, varargin)
            %% Post process data read from DAQ session.
            %%
            %% data = postprocess([raw_data])
            %%
            %% Returns `data` with data post-processed as follows:
            %% - self calibration
            %% - filter according to the object's parameters
            %% - trimming
            %%
            %% Parameters:
            %% raw_data : double
            %%     A matrix whose columns are signals from a single
            %%     channel. If not provided, read data from object's
            %%     `raw_data` property.
            %%
            %% Note: If trimming fails, returns an empty matrix.

            switch length(varargin)
                case 0
                    data = self.raw_data;
                case 1
                    data = varargin{1};
                otherwise
                    error("Only one optional argument expected: 'raw_data'");
            end

            if isempty(data)
                error("Input data is empty.");
            end

            self.log('Post processing data...');

            %% Self calibration
            for i = 1 : size(data, 2)
                data(:,i) = data(:,i) - data(1,i);
            end

            data = filter(self.filter.b, self.filter.c, data);

            %% Trimming
            threshold = 5 * max(data(1 : ceil(0.02 * size(data, 1)), 1));
            idx = zeros([1, size(data, 2)]);
            for i = 1 : size(data, 2)
                idx(i) = self.point_over_threshold(data(:, i), threshold);
            end
            idx = idx(find(idx)); % Select only non-zero values
            if isempty(idx)
                data = [];
            else
                idx = min(idx);
                data = data(idx : idx + 10000, :);
            end

            self.data = data;
        end

        function varargout = run(self)
            %% Execute the experiment.
            %%
            %% [a] = run()
            %% [a, b, x, y] = run()
            %%
            %% Read signals from device, postprocess it and compute
            %% the direction or location of the source.
            %%
            %% If the experiment is set to detect direction of
            %% arrival, returns `a` as the angle of arrival. If set to
            %% locate the source, returns:
            %%  - `a` : the angle w.r.t to the first T-array (rad),
            %%  - `b` : the angle w.r.t to the second T-array (rad),
            %%  - `x` : the the x-position of the source (unit),
            %%  - `y` : the y-position of the source (unit).
            %%
            %% If an angle cannot be computed, it will be an empty
            %% matrix and so will `x` and `y`. If post-processing
            %% fails, returns an empty matrix.
            %%
            %% It also plot results, which can be controlled by
            %% setting the `overwrite_plots` property.

            self.read_data();
            self.postprocess();

            if isempty(self.data);
                varargout = {[]};
                return
            end

            switch self.dir_or_loc
                case 'direction'
                    a = self.compute_dirloc();
                    varargout = {a};
                case 'location'
                    [a, b, x, y] = self.compute_dirloc();
                    varargout = {a, b, x, y};
            end

            if self.plots_flag
                self.log('Plotting...');
                self.plot_results(self.overwrite_plots);
            end
        end

        function varargout = compute_dirloc(self)
            %% Compute direction or location of the source.
            %%
            %% [a] = compute_dirloc()
            %% [a, b, x, y] = compute_dirloc()
            %%
            %% If the experiment is set to detect direction of
            %% arrival, returns `a` as the angle of arrival. If set to
            %% locate the source, returns:
            %%  - `a` : the angle w.r.t to the first T-array (rad),
            %%  - `b` : the angle w.r.t to the second T-array (rad),
            %%  - `x` : the the x-position of the source (unit),
            %%  - `y` : the y-position of the source (unit).
            %%
            %% If an angle cannot be computed, it will be an empty
            %% matrix and so will `x` and `y`. If post-processing
            %% fails, returns an empty matrix.

            [a, peaks_idx] = self.process_T_array(self.data(:, 1:4), ...
                                                  self.threshold);
            if strcmp(self.dir_or_loc, 'location')
                [b, tmp] = self.process_T_array(self.data(:, 5:8), ...
                                                self.threshold);
                peaks_idx = [peaks_idx, tmp]; % Concat to deal with empty values
                if ~isempty(a) && ~isempty(b)
                    [x, y] = self.get_source_position(a, b, self.distance);
                else
                    x = [];
                    y = [];
                end
                self.aoa = [a, b];
                self.source_position = [x, y];
                varargout = {a, b, x, y};
            else
                self.aoa = a;
                self.source_position = [];
                varargout = {a};
            end
            self.peaks_idx = peaks_idx;

            if isempty(peaks_idx)
                self.log('No peak found.');
            end
        end

        function [] = plot_results(self, varargin)
            %% Generate plots with results
            %%
            %% [] = plot_results([overwrite])
            %%
            %% Parameters:
            %% overwrite : logical, optional
            %%     If true, overwrite previously used figures. If
            %%     false, create new ones instead. If not given, use
            %%     `overwrite_plot` property's value instead.

            switch length(varargin)
                case 0
                    overwrite = self.overwrite_plots;
                case 1
                    overwrite = varargin{1};
                otherwise
                    error("Only one optional value was expected: 'overwrite'");
            end

            if overwrite && ~isempty(self.plot_figures)
                %% Check for closed figures
                fields = fieldnames(self.plot_figures);
                for i = 1 : length(fields)
                    fig = self.plot_figures.(fields{i});
                    if ~isvalid(fig)
                        self.plot_figures.(fields{i}) = figure();
                    end
                end
            else
                self.plot_figures = ...
                    struct('signals_figure', figure(),...
                           'position_figure', figure());
            end

            peaks_vals = [];
            for i = 1 : length(self.peaks_idx)
                peaks_vals(i) = self.data(self.peaks_idx(i), i);
            end

            legends = {'Sensor 1', 'Sensor 2', 'Sensor 3',...
                       'Sensor 4', 'Peaks', 'Threshold'};
            labels = @(x, y, t) [xlabel(x), ylabel(y), title(t)];
            switch self.dir_or_loc
                case 'direction'
                    N = 1;
                case 'location'
                    N = 2;
            end
            
            fig = self.plot_figures.signals_figure;
            figure(fig);
            clf();
            set(fig, 'Name', 'Signals');
            for i = 1 : N
                idx = [1 : 4] + 4*(i - 1);
                h = subplot(N, 1, i);
                self.plots_helper(h, 'signals', self.data(:, idx), ...
                                  self.peaks_idx(idx), self.threshold);
                title(sprintf('Sensor Array %i', i));
                xlim([1, 2*max(self.peaks_idx)]);
            end

            fig = self.plot_figures.position_figure;
            figure(fig);
            clf();
            d = self.distance;
            switch self.dir_or_loc
                case 'direction'
                    set(fig, 'Name', 'Direction of arrival');
                    self.plots_helper(gca(), 'direction', self.aoa);
                case 'location'
                    set(fig, 'Name', 'Position of source');
                    self.plots_helper(gca(), 'location', self.aoa, ...
                                      self.distance, self.source_position);
            end
        end

        function [threshold] = calibrate_threshold(self, varargin)
            %% Calibrate lower threshold for peak detection.
            %%
            %% [threshold] = calibrate_threshold(self, [factor])
            %%
            %% Sets and returns the threshold for peak detection to
            %% `factor` times the maximum RMS value among all channels
            %% when there is no impact and after filtering their
            %% signals.
            %%
            %% Parameters:
            %% factor : double, optional
            %%     The factor to which the maximum RMS value among the
            %%     channels will be multiplied to define the
            %%     threshold. If not given, default is 5.

            self.log('Calibrating threshold...');

            switch length(varargin)
                case 0
                    factor = 5;
                case 1
                    factor = varargin{1};
                otherwise
                    error("Only one optional parameter is allowed: 'factor'");
            end

            %% Silence everything
            old_beep = beep();
            beep('off');
            old_quiet = self.quiet;
            self.quiet = true;

            self.read_data();
            data = filter(self.filter.b, self.filter.c, self.raw_data);
            threshold = factor * max(rms(data));
            self.threshold = threshold;

            %% Restore values
            beep(old_beep);
            self.quiet = old_quiet;
            self.raw_data = [];
        end
    end

    methods (Access = private)
        function beep(self, varargin)
            %% Emit a beep sound.
            %%
            %% [] = beep([force])
            %%
            %% In Windows, it issues and "asterisk" sound.
            %% It is controlled by the `beep` flag of the object.
            %%
            %% Parameters:
            %% force : logical, optional
            %%     If present, force beeping even if it is disabled
            %%     and if the the beep flag is false.

            force = false;
            if ~isempty(varargin)
                if length(varargin) > 1
                    error('Invalid arguments.');
                else
                    force = varargin{1};
                end
            end

            if force
                status = beep();
                flag = self.beep_flag;
                beep('on');
                self.beep_flag = true;
            end

            if self.beep_flag
                beep();
            end

            if force
                beep(status);
                self.beep_flag = flag;
            end
        end

        function log(self, msg, varargin)
            %% Print log message to console.
            %%
            %% [] = log(msg, [force])
            %%
            %% Parameters:
            %% msg : char
            %%     The message to be printed.
            %% force : logical, optional
            %%     Force the printing of the message inspite of a
            %%     `quiet` flag being present.

            force = false;
            if ~isempty(varargin)
                if length(varargin) > 1
                    error('Invalid arguments.');
                else
                    force = varargin{1};
                end
            end

            if force || (~self.quiet && ~force)
                disp(msg);
            end
        end
    end

    methods (Access = public, Static)
        [x, y] = get_source_position(a, b, distance)
        ax = plots_helper(varargin)
        thres_over_point = point_over_threshold(data, threshold)
        [angle, peaks_idx] = process_T_array(data, threshold)
    end
end
