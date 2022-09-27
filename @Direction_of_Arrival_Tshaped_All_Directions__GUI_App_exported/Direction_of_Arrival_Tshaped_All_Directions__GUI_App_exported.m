classdef Direction_of_Arrival_Tshaped_All_Directions__GUI_App_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1         matlab.ui.Figure
        LOGO            matlab.ui.control.UIAxes
        uipanel3        matlab.ui.container.Panel
        ChannelNumber   matlab.ui.control.EditField
        SampleRate      matlab.ui.control.EditField
        Duration        matlab.ui.control.EditField
        Filename        matlab.ui.control.EditField
        text2           matlab.ui.control.Label
        text3           matlab.ui.control.Label
        text4           matlab.ui.control.Label
        text5           matlab.ui.control.Label
        uipanel4        matlab.ui.container.Panel
        text6           matlab.ui.control.Label
        Nyquist         matlab.ui.control.EditField
        text7           matlab.ui.control.Label
        Order           matlab.ui.control.EditField
        text9           matlab.ui.control.Label
        High            matlab.ui.control.EditField
        text10          matlab.ui.control.Label
        edit8           matlab.ui.control.EditField
        Low             matlab.ui.control.EditField
        text12          matlab.ui.control.Label
        text8           matlab.ui.control.Label
        uipanel5        matlab.ui.container.Panel
        Status          matlab.ui.control.ListBox
        Hit             matlab.ui.control.Button
        uipanel6        matlab.ui.container.Panel
        Position        matlab.ui.control.UIAxes
        uipanel7        matlab.ui.container.Panel
        DataNumber      matlab.ui.control.EditField
        Load            matlab.ui.control.Button
        text17          matlab.ui.control.Label
        text11          matlab.ui.control.Label
        Threshold       matlab.ui.control.EditField
        Save            matlab.ui.control.Button
        uipanel2        matlab.ui.container.Panel
        cluster2_raw    matlab.ui.control.UIAxes
        cluster2_catch  matlab.ui.control.UIAxes
        text15          matlab.ui.control.Label
        text16          matlab.ui.control.Label
        daq_session     daq.ni.Session
        angles          double
        distance        double
        last_position   double
        nchannels       double
        position_figure matlab.ui.Figure
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function Direction_of_Arrival_Tshaped_All_Directions__GUI_OpeningFcn(app, distance, varargin)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
            % This function has no output args, see OutputFcn.
            % hObject    handle to figure
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            % varargin   command line arguments to Direction_of_Arrival_Tshaped_All_Directions__GUI (see VARARGIN)
            app.angles = [];
            app.distance = distance;
            app.last_position = [];
            app.nchannels = 0;
        end

        function [] = log(app, msg)
            % Add log message to status status window.
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>

            msgs = {msg, app.Status.Items{:}};
            app.Status.Items = msgs;
            set(handles.Status, 'string', msgs);
            guidata(hObject, handles);
            drawnow
        end

        function [] = setup_device(app)
            % Setup a NI device for the task.
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>

            nchannels = str2num(get(handles.ChannelNumber,'string'));
            if app.nchannels == nchannels;
                %% Device is already set
                return
            else
                app.nchannels = nchannels;
            end
            app.log('Setting up device.');
            daq.reset();
            daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
            ap = daq.createSession('ni'); % ap as ADD Project
            
            %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Define measurment parameters
            handles.rate = str2num(get(handles.SampleRate,'string'));                          % sampling rate  must be less than 2E6
            handles.duration = str2num(get(handles.Duration,'string'));                        % measuring time
            handles.filename = get(handles.Filename,'string');            % filename to save
            data_points = handles.rate*duration;         % Number of data point to measure
            measuring_range = 10;                  % Channel info range
            Trigger_level=0.001;
            % trigger level in Volt. If the signal is higher than 0.001volt than it will start to measure
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% making analog input channel, choose device1 and channel
            %voltage,frequency, etc..
            for i=1:app.nchannels
                chan_name=sprintf('%s%d','ai',i-1);
                ap.addAnalogInputChannel('Dev2',chan_name, 'Voltage');
            end
            
            d=daq.getDevices();
            
            %% Setting code as Defined parameteres
            ap.Rate = handles.rate;
            ap.DurationInSeconds = handles.duration;
            ap.IsNotifyWhenDataAvailableExceedsAuto=true;
            ap.NotifyWhenDataAvailableExceeds = handles.rate/10;
            
            for i=1:app.nchannels
                ap.Channels(i).Range=[-measuring_range,measuring_range];
            end

            app.daq_session = ap;
            %----------------------------------------------
            % set(handles.Status,'string',ap);
            
            announce=sprintf('%s%d%s','Single recording is set for ',handles.duration,' s');
            app.log('Device set up.');
            app.log(announce);
            %%
            beep
            % Choose default command line output for Direction_of_Arrival_Tshaped_All_Directions__GUI
            handles.output = hObject;
            
            % Update handles structure
            guidata(hObject, handles);
        end

        % Button pushed function: Hit
        output = Hit_Callback(app, event)
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create figure1 and hide until all components are created
            app.figure1 = uifigure('Visible', 'off');
            app.figure1.Color = [1 1 1];
            app.figure1.Colormap = [1 1 1;0 0.32156862745098 0.580392156862745;0.870588235294118 0.83921568627451 0.870588235294118;0 0.258823529411765 0.549019607843137;0 0.227450980392157 0.482352941176471];
            app.figure1.Position = [0 0 1525 739];
            app.figure1.Name = 'Direction_of_Arrival_Tshaped_All_Directions__GUI';
            app.figure1.Resize = 'off';
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create LOGO
            app.LOGO = uiaxes(app.figure1);
            app.LOGO.DataAspectRatio = [1 1 1];
            app.LOGO.FontSize = 11;
            app.LOGO.XLim = [0.5 243.5];
            app.LOGO.YLim = [0.5 132.5];
            app.LOGO.YDir = 'reverse';
            app.LOGO.TickDir = 'out';
            app.LOGO.Layer = 'top';
            app.LOGO.Box = 'on';
            app.LOGO.NextPlot = 'replace';
            app.LOGO.Visible = 'off';
            app.LOGO.BackgroundColor = [1 1 1];
            app.LOGO.Tag = 'LOGO';
            app.LOGO.Position = [56 -11 330 129];

            % Create uipanel3
            app.uipanel3 = uipanel(app.figure1);
            app.uipanel3.Title = 'DAQ Parameter';
            app.uipanel3.BackgroundColor = [1 1 1];
            app.uipanel3.Tag = 'uipanel3';
            app.uipanel3.FontAngle = 'italic';
            app.uipanel3.FontWeight = 'bold';
            app.uipanel3.FontSize = 13;
            app.uipanel3.Position = [40 470 364 206];

            % Create ChannelNumber
            app.ChannelNumber = uieditfield(app.uipanel3, 'text');
            app.ChannelNumber.Tag = 'ChannelNumber';
            app.ChannelNumber.HorizontalAlignment = 'center';
            app.ChannelNumber.FontSize = 13;
            app.ChannelNumber.Position = [167 153 169 24];
            app.ChannelNumber.Value = '4';

            % Create SampleRate
            app.SampleRate = uieditfield(app.uipanel3, 'text');
            app.SampleRate.Tag = 'SampleRate';
            app.SampleRate.HorizontalAlignment = 'center';
            app.SampleRate.FontSize = 13;
            app.SampleRate.Position = [167 109 169 24];
            app.SampleRate.Value = '1000000';

            % Create Duration
            app.Duration = uieditfield(app.uipanel3, 'text');
            app.Duration.Tag = 'Duration';
            app.Duration.HorizontalAlignment = 'center';
            app.Duration.FontSize = 13;
            app.Duration.Position = [167 64 169 24];
            app.Duration.Value = '3';

            % Create Filename
            app.Filename = uieditfield(app.uipanel3, 'text');
            app.Filename.Tag = 'Filename';
            app.Filename.HorizontalAlignment = 'center';
            app.Filename.FontSize = 13;
            app.Filename.Position = [167 20 169 24];
            app.Filename.Value = 'Impact_Data';

            % Create text2
            app.text2 = uilabel(app.uipanel3);
            app.text2.Tag = 'text2';
            app.text2.BackgroundColor = [1 1 1];
            app.text2.HorizontalAlignment = 'center';
            app.text2.VerticalAlignment = 'top';
            app.text2.FontSize = 13;
            app.text2.Position = [21 152 113 20];
            app.text2.Text = 'Channel Number';

            % Create text3
            app.text3 = uilabel(app.uipanel3);
            app.text3.Tag = 'text3';
            app.text3.BackgroundColor = [1 1 1];
            app.text3.HorizontalAlignment = 'center';
            app.text3.VerticalAlignment = 'top';
            app.text3.FontSize = 13;
            app.text3.Position = [21 110 113 20];
            app.text3.Text = 'Sample Rate';

            % Create text4
            app.text4 = uilabel(app.uipanel3);
            app.text4.Tag = 'text4';
            app.text4.BackgroundColor = [1 1 1];
            app.text4.HorizontalAlignment = 'center';
            app.text4.VerticalAlignment = 'top';
            app.text4.FontSize = 13;
            app.text4.Position = [21 68 113 20];
            app.text4.Text = 'Testing Duration';

            % Create text5
            app.text5 = uilabel(app.uipanel3);
            app.text5.Tag = 'text5';
            app.text5.BackgroundColor = [1 1 1];
            app.text5.HorizontalAlignment = 'center';
            app.text5.VerticalAlignment = 'top';
            app.text5.FontSize = 13;
            app.text5.Position = [21 25 113 20];
            app.text5.Text = 'Filename';

            % Create uipanel4
            app.uipanel4 = uipanel(app.figure1);
            app.uipanel4.Title = 'Filter Parameter';
            app.uipanel4.BackgroundColor = [1 1 1];
            app.uipanel4.Tag = 'uipanel4';
            app.uipanel4.FontAngle = 'italic';
            app.uipanel4.FontWeight = 'bold';
            app.uipanel4.FontSize = 13;
            app.uipanel4.Position = [40 259 364 212];

            % Create text6
            app.text6 = uilabel(app.uipanel4);
            app.text6.Tag = 'text6';
            app.text6.BackgroundColor = [1 1 1];
            app.text6.HorizontalAlignment = 'center';
            app.text6.VerticalAlignment = 'top';
            app.text6.FontSize = 13;
            app.text6.Position = [27 111 113 19];
            app.text6.Text = 'Nyquist Rate';

            % Create Nyquist
            app.Nyquist = uieditfield(app.uipanel4, 'text');
            app.Nyquist.Tag = 'Nyquist';
            app.Nyquist.HorizontalAlignment = 'center';
            app.Nyquist.FontSize = 13;
            app.Nyquist.Position = [167 109 169 24];
            app.Nyquist.Value = 'N/A';

            % Create text7
            app.text7 = uilabel(app.uipanel4);
            app.text7.Tag = 'text7';
            app.text7.BackgroundColor = [1 1 1];
            app.text7.HorizontalAlignment = 'center';
            app.text7.VerticalAlignment = 'top';
            app.text7.FontSize = 13;
            app.text7.Position = [27 71 113 19];
            app.text7.Text = 'Filter Order';

            % Create Order
            app.Order = uieditfield(app.uipanel4, 'text');
            app.Order.Tag = 'Order';
            app.Order.HorizontalAlignment = 'center';
            app.Order.FontSize = 13;
            app.Order.Position = [167 65 169 24];
            app.Order.Value = '5';

            % Create text9
            app.text9 = uilabel(app.uipanel4);
            app.text9.Tag = 'text9';
            app.text9.BackgroundColor = [1 1 1];
            app.text9.HorizontalAlignment = 'center';
            app.text9.VerticalAlignment = 'top';
            app.text9.FontSize = 13;
            app.text9.Position = [12 30 143 19];
            app.text9.Text = 'Bandpass Range';

            % Create High
            app.High = uieditfield(app.uipanel4, 'text');
            app.High.Tag = 'High';
            app.High.HorizontalAlignment = 'center';
            app.High.FontSize = 13;
            app.High.Position = [255 24 81 24];
            app.High.Value = '15000';

            % Create text10
            app.text10 = uilabel(app.uipanel4);
            app.text10.Tag = 'text10';
            app.text10.BackgroundColor = [1 1 1];
            app.text10.HorizontalAlignment = 'center';
            app.text10.VerticalAlignment = 'top';
            app.text10.FontSize = 13;
            app.text10.Position = [27 152 113 19];
            app.text10.Text = 'Filter';

            % Create edit8
            app.edit8 = uieditfield(app.uipanel4, 'text');
            app.edit8.Tag = 'edit8';
            app.edit8.HorizontalAlignment = 'center';
            app.edit8.FontSize = 13;
            app.edit8.Position = [167 153 169 24];
            app.edit8.Value = 'Bandpass';

            % Create Low
            app.Low = uieditfield(app.uipanel4, 'text');
            app.Low.Tag = 'Low';
            app.Low.HorizontalAlignment = 'center';
            app.Low.FontSize = 13;
            app.Low.Position = [167 24 76 24];
            app.Low.Value = '5000';

            % Create text12
            app.text12 = uilabel(app.uipanel4);
            app.text12.Tag = 'text12';
            app.text12.BackgroundColor = [1 1 1];
            app.text12.HorizontalAlignment = 'center';
            app.text12.VerticalAlignment = 'top';
            app.text12.FontSize = 11;
            app.text12.Position = [244 28 10 15];
            app.text12.Text = '~';

            % Create text8
            app.text8 = uilabel(app.figure1);
            app.text8.Tag = 'text8';
            app.text8.BackgroundColor = [1 1 1];
            app.text8.HorizontalAlignment = 'center';
            app.text8.VerticalAlignment = 'top';
            app.text8.FontSize = 40;
            app.text8.FontWeight = 'bold';
            app.text8.FontAngle = 'italic';
            app.text8.Position = [150 675 1290 58];
            app.text8.Text = 'Direction of Arrival_ T-shaped Sensor Array_All Directions';

            % Create uipanel5
            app.uipanel5 = uipanel(app.figure1);
            app.uipanel5.Title = 'Operating Interface';
            app.uipanel5.BackgroundColor = [1 1 1];
            app.uipanel5.Tag = 'uipanel5';
            app.uipanel5.FontWeight = 'bold';
            app.uipanel5.FontSize = 13;
            app.uipanel5.Position = [1066 7 464 264];

            % Create Status
            app.Status = uilistbox(app.uipanel5);
            app.Status.Items = {'Press "Hit" to start.'};
            app.Status.Tag = 'Status';
            app.Status.FontSize = 13;
            app.Status.Position = [21 64 410 170];
            app.Status.Value = 'Press "Hit" to start.';

            % Create Hit
            app.Hit = uibutton(app.uipanel5, 'push');
            app.Hit.ButtonPushedFcn = createCallbackFcn(app, @Hit_Callback, true);
            app.Hit.Tag = 'Hit';
            app.Hit.FontSize = 16;
            app.Hit.Position = [22 17 410 36];
            app.Hit.Text = 'Hit';

            % Create uipanel6
            app.uipanel6 = uipanel(app.figure1);
            app.uipanel6.Title = 'Direction of Impact';
            app.uipanel6.BackgroundColor = [1 1 1];
            app.uipanel6.Tag = 'uipanel6';
            app.uipanel6.FontWeight = 'bold';
            app.uipanel6.FontSize = 13;
            app.uipanel6.Position = [1066 277 460 400];

            % Create Position
            app.Position = uiaxes(app.uipanel6);
            app.Position.FontSize = 13;
            app.Position.XColor = [1 1 1];
            app.Position.XTick = [];
            app.Position.YColor = [1 1 1];
            app.Position.YTick = [];
            app.Position.Color = [0.941176470588235 0.941176470588235 0.941176470588235];
            app.Position.NextPlot = 'replace';
            app.Position.BackgroundColor = [1 1 1];
            app.Position.Tag = 'Position';
            app.Position.Position = [64 61 346 271];

            % Create uipanel7
            app.uipanel7 = uipanel(app.figure1);
            app.uipanel7.Title = 'Data Analysis';
            app.uipanel7.BackgroundColor = [1 1 1];
            app.uipanel7.Tag = 'uipanel7';
            app.uipanel7.FontWeight = 'bold';
            app.uipanel7.FontSize = 13;
            app.uipanel7.Position = [40 126 365 117];

            % Create DataNumber
            app.DataNumber = uieditfield(app.uipanel7, 'text');
            app.DataNumber.Tag = 'DataNumber';
            app.DataNumber.HorizontalAlignment = 'center';
            app.DataNumber.FontSize = 19;
            app.DataNumber.Position = [170 52 25 30];
            app.DataNumber.Value = '1';

            % Create Load
            app.Load = uibutton(app.uipanel7, 'push');
            app.Load.Tag = 'Load';
            app.Load.FontSize = 16;
            app.Load.Position = [224 54 49 37];
            app.Load.Text = 'Load';

            % Create text17
            app.text17 = uilabel(app.uipanel7);
            app.text17.Tag = 'text17';
            app.text17.BackgroundColor = [1 1 1];
            app.text17.HorizontalAlignment = 'center';
            app.text17.VerticalAlignment = 'top';
            app.text17.FontSize = 16;
            app.text17.Position = [24 57 144 20];
            app.text17.Text = 'Impact Data -';

            % Create text11
            app.text11 = uilabel(app.uipanel7);
            app.text11.Tag = 'text11';
            app.text11.BackgroundColor = [1 1 1];
            app.text11.HorizontalAlignment = 'center';
            app.text11.VerticalAlignment = 'top';
            app.text11.FontSize = 13;
            app.text11.Position = [31 17 113 19];
            app.text11.Text = 'Threshold';

            % Create Threshold
            app.Threshold = uieditfield(app.uipanel7, 'text');
            app.Threshold.Tag = 'Threshold';
            app.Threshold.HorizontalAlignment = 'center';
            app.Threshold.FontSize = 13;
            app.Threshold.Position = [169 14 169 24];
            app.Threshold.Value = '0.018';

            % Create Save
            app.Save = uibutton(app.uipanel7, 'push');
            app.Save.Tag = 'Save';
            app.Save.FontSize = 16;
            app.Save.Position = [287 54 49 36];
            app.Save.Text = 'Save';

            % Create uipanel2
            app.uipanel2 = uipanel(app.figure1);
            app.uipanel2.Title = 'Signal';
            app.uipanel2.BackgroundColor = [1 1 1];
            app.uipanel2.Tag = 'uipanel2';
            app.uipanel2.FontAngle = 'italic';
            app.uipanel2.FontWeight = 'bold';
            app.uipanel2.FontSize = 13;
            app.uipanel2.Position = [431 6 618 669];

            % Create cluster2_raw
            app.cluster2_raw = uiaxes(app.uipanel2);
            app.cluster2_raw.FontSize = 13;
            app.cluster2_raw.XColor = [1 1 1];
            app.cluster2_raw.XTick = [];
            app.cluster2_raw.YColor = [1 1 1];
            app.cluster2_raw.YTick = [];
            app.cluster2_raw.Color = [0.941176470588235 0.941176470588235 0.941176470588235];
            app.cluster2_raw.NextPlot = 'replace';
            app.cluster2_raw.BackgroundColor = [1 1 1];
            app.cluster2_raw.Tag = 'cluster2_raw';
            app.cluster2_raw.Position = [53 371 505 256];

            % Create cluster2_catch
            app.cluster2_catch = uiaxes(app.uipanel2);
            app.cluster2_catch.FontSize = 13;
            app.cluster2_catch.XColor = [1 1 1];
            app.cluster2_catch.XTick = [];
            app.cluster2_catch.YColor = [1 1 1];
            app.cluster2_catch.YTick = [];
            app.cluster2_catch.Color = [0.941176470588235 0.941176470588235 0.941176470588235];
            app.cluster2_catch.NextPlot = 'replace';
            app.cluster2_catch.BackgroundColor = [1 1 1];
            app.cluster2_catch.Tag = 'cluster2_catch';
            app.cluster2_catch.Position = [55 31 505 272];

            % Create text15
            app.text15 = uilabel(app.uipanel2);
            app.text15.Tag = 'text15';
            app.text15.BackgroundColor = [1 1 1];
            app.text15.HorizontalAlignment = 'center';
            app.text15.VerticalAlignment = 'top';
            app.text15.FontSize = 13;
            app.text15.FontWeight = 'bold';
            app.text15.Position = [209 629 186 21];
            app.text15.Text = 'Cluster Signal';

            % Create text16
            app.text16 = uilabel(app.uipanel2);
            app.text16.Tag = 'text16';
            app.text16.BackgroundColor = [1 1 1];
            app.text16.HorizontalAlignment = 'center';
            app.text16.VerticalAlignment = 'top';
            app.text16.FontSize = 13;
            app.text16.FontWeight = 'bold';
            app.text16.Position = [223 305 186 21];
            app.text16.Text = 'Catched Points';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % Assorted methods
    methods (Access = public)
        function filt_data = filter_signal(app, event, data)
            %% Apply bandpass filter on acquired data.
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event);
            SF = handles.rate;
            low = str2num(get(handles.Low, 'string'));
            high = str2num(get(handles.High, 'string'));
            Wn = [low, high]; % high or low Hz % first set
            Fn = SF/2; %nyquist sampling frequency
            set(handles.Nyquist, 'string', num2str(Fn));
            n = str2num(get(handles.Order, 'string'));
            [b, c] = butter(n, Wn/Fn, 'bandpass');
            filt_data = filter(b, c, data); % filtered row signal
        end

        function data = read_data(app, event)
            %% Read data from DAQ
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event);
            beep
            app.log('Start recording...');
            data = app.daq_session.startForeground();

            %% self calibration
            for i = 1 : app.nchannels
                data(:,i) = data(:,i) - data(1,i);
            end

            handles.Data = data;
            guidata(hObject, handles);
            app.log('Done recording');
        end

        output = process_T_array(app, event, data)

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
                if isempty(app.position_figure)
                    app.position_figure = figure();
                end
                fig = figure(app.position_figure);
                clf();
                set(fig, 'Name', 'Source localization');
                plot([0, x, 0], [0, y, app.distance], 'k--');
                hold on;
                plot([0, 0], [0, app.distance], 'bo');
                plot(x, y, 'r*');
                axis equal;
                y_lims = [min(0, y), max(app.distance, y)];
                x_lim = max([app.distance, diff(y_lims), 2*x]);
                xlim([-x_lim/2, +x_lim/2]);
                ylim(y_lims);
                grid on;
                legend('Direction', 'Sensors', 'Source');
                xlabel('x');
                ylabel('y');
                title(sprintf('Position: x=%0.1f, y=%0.1f\nAngles: a=%0.f°, b=%0.f°',...
                              x, y, app.angles(1)/pi*180, app.angles(2)/pi*180));
            end
        end
    end

    % Assorted static methods
    methods (Access = public, Static)
        function thres_over_point = point_over_threshold(data, threshold)
            %% Find the index of an element in 'data' the is greater than 'threshold'.
            %% Returns an empty matrix in case no value is above threshold.
            thres_over_point = [];
            for i = 1 : length(data)
                if data(i) > threshold
                    thres_over_point = i;
                    break
                end
            end
        end

        function i = find_peak(data)
            %% Find the first maximum point in a 1D matrix using
            %% change of signal of the gradient. Returns an empty
            %% matrix in case no maximum is found.
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

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Direction_of_Arrival_Tshaped_All_Directions__GUI_App_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.figure1)

            % Execute the startup function
            runStartupFcn(app, @(app)Direction_of_Arrival_Tshaped_All_Directions__GUI_OpeningFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.figure1)
        end
    end
end
