function Hit_Callback(app, event)
% Create GUIDE-style callback args - Added by Migration Tool
[hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

% hObject    handle to Hit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% start to measure
data = app.read_data(event);
app.process_T_array(event, data(:, 1:4));
if str2num(get(handles.ChannelNumber,'string')) == 8
    app.process_T_array(event, data(:, 5:8));
    app.get_source_position('plot');
end

app.log('Done!!!');

axes(handles.LOGO);
imshow('ASDL.gif');
