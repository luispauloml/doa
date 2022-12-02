function pos = estimate_source_position(a, b, distance)
%% Estimate (x, y) position of the source.
%%
%% pos = estimate_source_position(a, b, distance)
%%
%% Returns `pos` as a 1x2 matrix with [x, y] position of the source.
%%
%% Parameters:
%% a : scalar
%%     The angle w.r.t the first T-array.
%% b : scalar
%%     The angle w.r.t the second T-array.
%% distance : scalar
%%     The distance between the two T-arrays.

m1 = tan(a);
m2 = tan(b + pi);
pos = zeros([1, 2]);
pos(1) = distance / (m1 - m2);
pos(2) = m1 * pos(1);
