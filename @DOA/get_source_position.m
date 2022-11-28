function [x, y] = get_source_position(a, b, distance)
%% Calucate (x, y) position of the source.
%%
%% [x, y] = get_source_position(a, b)
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
x = distance / (m1 - m2);
y = m1 * x;
