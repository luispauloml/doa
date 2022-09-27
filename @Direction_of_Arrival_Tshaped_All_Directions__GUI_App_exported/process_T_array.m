function [] = process_T_array(app, event, data)
%% Process data from a T-array of sensors.  `data` should have 4
%% columns.

% Create GUIDE-style callback args - Added by Migration Tool
[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

% hObject    handle to Hit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NO_IMPACT_MSG = 'No impact detected';
filt_data = app.filter_signal(event, data);

% data extraction
threshold=5*max(filt_data(1:ceil(0.02*size(data,1)),1));
thres_over_point = app.point_over_threshold(filt_data(:,1), threshold);

if isempty(thres_over_point)
    app.log(NO_IMPACT_MSG);
    return
end

ext_data=filt_data(thres_over_point-2000:thres_over_point+8000,:);

thres_lev=str2num(get(handles.Threshold,'string'));
min_point=6;

%% sensor 1 cluster signal processing for angle detection
sensor1_data=ext_data(:,1:3);

% get first wave arrival point
% active threshold setup
threshold_over_point = app.point_over_threshold(sensor1_data(:,1), thres_lev);

if isempty(threshold_over_point)
    app.log(NO_IMPACT_MSG);
    return
end

% find sensor 1 signal peak point
peak_point = [];
range = threshold_over_point : size(sensor1_data, 1);
peak_point(1) = app.find_peak(sensor1_data(range, 1)) + range(1) - 1;

% find sensor 2 signal peak point
range = peak_point(1) : size(sensor1_data, 1);
for j=2:3
    peak_point(j) = app.find_peak(sensor1_data(range, j)) + range(1) - 1;
    if peak_point(j)-peak_point(1) < min_point
        range = peak_point(j) + 1 : size(sensor1_data, 1);
        peak_point(j) = app.find_peak(sensor1_data(range, j)) + range(1) - 1;
    end
end

left=peak_point(3);%%%%%%%%%%% compare with right


hold off;
grid; set(gca,'Xlim',[peak_point(1)-100 max(peak_point(2:3))+100])

dt21=peak_point(2)-peak_point(1);
dt31=peak_point(3)-peak_point(1);
dist21=1;
dist31=1;
angle1=atan((dist21*dt21)/(dist31*dt31));

%% sensor 2 cluster signal processing for angle detection
sensor2_data=ext_data(:,[1 2 4]);

axes(handles.cluster2_raw); plot(ext_data(:,[3 1 4])); grid;

% get first wave arrival point
% active threshold setup
threshold_over_point = app.point_over_threshold(sensor2_data(:,1), thres_lev);

% find sensor 1 signal peak point
peak_point = [];
range = threshold_over_point : size(sensor2_data, 1);
peak_point(1) = app.find_peak(sensor2_data(range, 1)) + range(1) - 1;

% find sensor 2 signal peak point
range = peak_point(1) : size(sensor2_data, 1);
for j=2:3
    peak_point(j) = app.find_peak(sensor2_data(range, j)) + range(1) - 1;
    if peak_point(j)-peak_point(1) < min_point
        range = peak_point(j) + 1 : size(sensor2_data, 1);
        peak_point(j) = app.find_peak(sensor2_data(range, j)); + range(1) - 1;
    end
end

axes(handles.cluster2_catch);
plot(ext_data(:,1:4)); hold all;
plot(peak_point(1),sensor2_data(peak_point(1),1),'o','Color',[0 0 0]);
plot(peak_point(2),sensor2_data(peak_point(2),2),'o','Color',[0 0 0]);
plot(peak_point(3),sensor2_data(peak_point(3),3),'o','Color',[0 0 0]);
plot(left,sensor1_data(left,3),'o','Color',[0 0 0]);


right=peak_point(3);%%%%%%%%%%% compare with left

threshold_over_point_L = app.point_over_threshold(ext_data(:,3), thres_lev);
threshold_over_point_R = app.point_over_threshold(ext_data(:,4), thres_lev);

hold off;
grid; set(gca,'Xlim',[peak_point(1)-100 max(peak_point(2:3))+100])

dt21=peak_point(2)-peak_point(1);
dt31=peak_point(3)-peak_point(1);
dist21=1;
dist31=1;
angle2=pi-atan((dist21*dt21)/(dist31*dt31));
% now we have angle1 and angle2!

%% impact localization
m1=tan(angle1);
m2=-tan(angle2);

%% result visualization
sensor1_pos=[0 0];
sensor2_pos=[0 -50];
sensor3_pos=[-50 0];
sensor4_pos=[50 0];

app.log('Ploting...');

line_width=3;
axes(handles.Position);
plot(sensor1_pos(1),sensor1_pos(2),'o','LineWidth',line_width,'Color',[0 0 1]);hold all;
plot(sensor2_pos(1),sensor2_pos(2),'o','LineWidth',line_width,'Color',[0 0 1]);
plot(sensor3_pos(1),sensor3_pos(2),'o','LineWidth',line_width,'Color',[0 0 1]);
plot(sensor4_pos(1),sensor4_pos(2),'o','LineWidth',line_width,'Color',[0 0 1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   For All DOA
if threshold_over_point_R<threshold_over_point_L
    app.angles(end + 1) = angle1;
    plot([0 10000],[0 m1*10000],'LineWidth',line_width,'Color',[1 0 0],'LineStyle','--');
end
if threshold_over_point_R>threshold_over_point_L
    app.angles(end + 1) = angle2;
    plot([0 -10000],[0 m2*10000],'LineWidth',line_width,'Color',[1 0 0],'LineStyle','--');
end



hold off; set(gca,'Xlim',[-400 400],'Ylim',[-100 600],'FontSize',20,'FontWeight','bold'); grid;


app.log('Done ploting.');
app.log(sprintf('angle=%0.f°', app.angles(end)/pi*180));
