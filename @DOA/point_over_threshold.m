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
