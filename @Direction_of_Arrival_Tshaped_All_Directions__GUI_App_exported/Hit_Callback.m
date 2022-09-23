function Hit_Callback(app, event)
% Create GUIDE-style callback args - Added by Migration Tool
[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

% hObject    handle to Hit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% start to measure
NO_IMPACT_MSG = 'No impact detected';
beep
app.log('Start recording...');
data = app.daq_session.startForeground();

% self calibration
for i=1:handles.numb_channel
    data(:,i)=data(:,i)-data(1,i);
end

%% check and save the data
app.log('Done recording');


handles.Data=data;
filt_data = app.filter_signal(event, data);

% data extraction
threshold=5*max(filt_data(1:ceil(0.02*size(data,1)),1));
for i=1:size(data,1)
    if filt_data(i,1) > threshold
        thres_over_point=i;
        break
    end
end

if isempty(whos('thres_over_point'))
    app.log(NO_IMPACT_MSG);
    return
end

ext_data=filt_data(thres_over_point-2000:thres_over_point+8000,:);
signal=ext_data;

gtlv=str2num(get(handles.Threshold,'string'));
min_point=6;

for on=1:1
%% sensor 1 cluster signal processing for angle detection
sensor1_data=ext_data(:,1:3);

% get first wave arrival point
% active threshold setup
thres_lev=1.5*max(abs(sensor1_data(1:1000,1)));
thres_lev=gtlv;
for i=1:size(sensor1_data,1)
    if thres_lev < sensor1_data(i,1);
        threshold_over_point=i;
        break
    end
end

if isempty(whos('threshold_over_point'))
    app.log(NO_IMPACT_MSG);
    return
end

% find sensor 1 signal peak point
for i=threshold_over_point:size(sensor1_data,1)
    fac1=sensor1_data(i,1)-sensor1_data(i-1,1);
    fac2=sensor1_data(i+1,1)-sensor1_data(i,1);

    if fac1*fac2 <0
        if fac1 > 0
            peak_point(1)=i;
            break
        end
    end
end
% find sensor 2 signal peak point
for j=2:3
    for i=peak_point(1):size(sensor1_data,1)
        fac1=sensor1_data(i,j)-sensor1_data(i-1,j);
        fac2=sensor1_data(i+1,j)-sensor1_data(i,j);
        if fac1*fac2 <0
            if fac1 > 0
                peak_point(j)=i;
                break
            end
        end
    end
    if peak_point(j)-peak_point(1) < min_point
        for i=peak_point(j)+1:size(sensor1_data,1)
            fac1=sensor1_data(i,j)-sensor1_data(i-1,j);
            fac2=sensor1_data(i+1,j)-sensor1_data(i,j);
            if fac1*fac2 <0
                if fac1 > 0
                    peak_point(j)=i;
                    break
                end
            end
        end
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
thres_lev=1.5*max(abs(sensor2_data(1:1000,1)));
thres_lev=gtlv;
for i=1:size(sensor2_data,1)
    if thres_lev < sensor2_data(i,1);
        threshold_over_point=i;
        break
    end
end
% find sensor 1 signal peak point
for i=threshold_over_point:size(sensor2_data,1)
    fac1=sensor2_data(i,1)-sensor2_data(i-1,1);
    fac2=sensor2_data(i+1,1)-sensor2_data(i,1);
    if fac1*fac2 <0
        if fac1 > 0
            peak_point(1)=i;
            break
        end
    end
end
% find sensor 2 signal peak point
for j=2:3
    for i=peak_point(1):size(sensor2_data,1)
        fac1=sensor2_data(i,j)-sensor2_data(i-1,j);
        fac2=sensor2_data(i+1,j)-sensor2_data(i,j);
        if fac1*fac2 <0
            if fac1 > 0
                peak_point(j)=i;
                break
            end
        end
    end
    if peak_point(j)-peak_point(1) < min_point
        for i=peak_point(j)+1:size(sensor2_data,1)
            fac1=sensor2_data(i,j)-sensor2_data(i-1,j);
            fac2=sensor2_data(i+1,j)-sensor2_data(i,j);
            if fac1*fac2 <0
                if fac1 > 0
                    peak_point(j)=i;
                    break
                end
            end
        end
    end
end

axes(handles.cluster2_catch);
plot(ext_data(:,1:4)); hold all;
plot(peak_point(1),sensor2_data(peak_point(1),1),'o','Color',[0 0 0]);
plot(peak_point(2),sensor2_data(peak_point(2),2),'o','Color',[0 0 0]);
plot(peak_point(3),sensor2_data(peak_point(3),3),'o','Color',[0 0 0]);
plot(left,sensor1_data(left,3),'o','Color',[0 0 0]);


right=peak_point(3);%%%%%%%%%%% compare with left

for i=1:size(ext_data,1)
    if thres_lev < ext_data(i,3);
        threshold_over_point_L=i;
        break
    end
end

for i=1:size(ext_data,1)
    if thres_lev < ext_data(i,4);
        threshold_over_point_R=i;
        break
    end
end

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
A=[m2 -1;m1 -1];
B=[700; 0];
end

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
    plot([0 10000],[0 m1*10000],'LineWidth',line_width,'Color',[1 0 0],'LineStyle','--');
end
if threshold_over_point_R>threshold_over_point_L
    plot([0 -10000],[0 m2*10000],'LineWidth',line_width,'Color',[1 0 0],'LineStyle','--');
end



hold off; set(gca,'Xlim',[-400 400],'Ylim',[-100 600],'FontSize',20,'FontWeight','bold'); grid;

app.log('Done!!!');

axes(handles.LOGO);
imshow('ASDL.gif');
