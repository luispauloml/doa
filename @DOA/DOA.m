classdef DOA < handle
    properties (Access = public)
        beep_flag = false;      % beep flag
        daq_session;            % DAQ session for NI device
        data = [];              % post-processed data read from DAQ session
        dir_or_loc = "";        % type of experiment being run
        distance = 50;          % distance between two T-array of sensors (unit)
        filter = struct();      % Butterworth filter for signal processing
        overwrite_plots = true; % flag to overwrite plot results
        plots_flag = false      % flag to plot results
        quiet = false;          % quiet flag
        raw_data = [];          % raw data read from DAQ session
        sampl_rate = 1e6;       % sampling rate (samples/s)
        threshold = 0.018;      % lower threshold for peak detection (volts)
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
            %%     The lower threshold for detecting a peak, default:
            %%     0.018.
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

            self.log('Setting up device.');
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
            self.log('Device set up.');
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

            self.log('Post processing data...');

            %% Self calibration
            for i = 1 : size(data, 2)
                data(:,i) = data(:,i) - data(1,i);
            end

            data = filter(self.filter.b, self.filter.c, data);

            %% Trimming
            threshold = 5 * max(data(1 : ceil(0.02 * size(data, 1)), 1));
            idx = self.point_over_threshold(data(:, 1), threshold);
            if isempty(idx)
                data = [];
            else
                data = data(idx : idx + 10000, :);
            end

            self.data = data;
        end

        [angle, peaks_idx] = process_T_array(self, data, varargin)

        function varargout = run(self)
            %% Execute the experiment.
            %%
            %% [a] = run()
            %% [a, b, x, y] = run()
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
            %% matrix and so will `x` and `y`.

            if self.plots_flag
                if self.overwrite_plots && ~isempty(self.plot_figures)
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
                        struct('sensor_array_1', figure());
                    if strcmp(self.dir_or_loc, 'location')
                        self.plot_figures.sensor_array_2 = figure();
                    end
                end
            end

            self.read_data();

            fig_cell = {};
            if self.plots_flag
                fig = self.plot_figures.sensor_array_1;
                set(fig, 'Name', 'Sensor Array 1');
                fig_cell = {fig};
            end
            a = self.process_T_array(self.data(:, 1:4), fig_cell{:});

            if strcmp(self.dir_or_loc, 'location')
                if self.plots_flag
                    fig = self.plot_figures.sensor_array_2;
                    set(fig, 'Name', 'Sensor Array 2');
                    fig_cell = {fig};
                end
                b = self.process_T_array(self.data(:, 5:8), fig_cell{:});
            else
                varargout = {a};
                return
            end

            if ~isempty(a) && ~isempty(b)
                [x, y] = self.get_source_position(a, b);
            else
                x = [];
                y = [];
            end

            varargout = {a, b, x, y};
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

            if self.quiet
                return
            end
            disp(msg);
        end

        function [x, y] = get_source_position(self, a, b)
            %% Calucate (x, y) position of the source.
            %%
            %% [x, y] = get_source_position(a, b)
            %%
            %% Parameters:
            %% a : scalar
            %%     The angle w.r.t the first T-array.
            %% b : scalar
            %%     The angle w.r.t the second T-array.

            m1 = tan(a);
            m2 = tan(b + pi);
            x = self.distance / (m1 - m2);
            y = m1 * x;
        end
    end

    methods (Access = private, Static)
        function thres_over_point = point_over_threshold(data, threshold)
            %% Find the index of an element in 'data' the is greater than 'threshold'.
            %%
            %% thres_over_point = point_over_threshold(data, threshold)
            %%
            %% Returns an empty matrix in case no value is above threshold.
            %%
            %% Parameters:
            %% data : matrix
            %%     The matrix with the data.
            %% threshold : scalar
            %%     The threshold.

            thres_over_point = [];
            for i = 1 : length(data)
                if data(i) > threshold
                    thres_over_point = i;
                    break
                end
            end
        end

        function i = find_peak(data)
            %% Find the first maximum point in a 1D matrix.
            %%
            %% i = find_peak(data)
            %%
            %% Find the first maximum using the change of signal of
            %% the gradient. Returns an empty matrix in case no
            %% maximum is found.
            %%
            %% Parameters:
            %% data : matrix
            %%     The matrix with the data.

            found = false;
            for i = 2 : length(data) - 1
                fac1 = data(i) - data(i-1);
                fac2 = data(i + 1) - data(i);
                if fac1 * fac2 < 0
                    if fac1 > 0
                        found = true;
                        break
                    end
                end
            end
            if ~found
                i = []
            end
        end
    end
end
