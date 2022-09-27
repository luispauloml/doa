classdef DOA
    methods (Access = public)
        function self = DOA(direction_or_location, device_name, varargin)
        end
    end

    methods (Access = private)
        function log(self, msg)
            %% Print log message to console.
            %%
            %% [] = log(msg)
            %%
            %% Parameters:
            %% msg : char
            %%     The message to be printed.

            disp(msg);
        end
    end
end
