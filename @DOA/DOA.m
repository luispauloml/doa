classdef DOA
    properties (Access = public)
        quiet               logical % Flag to print log messages
    end
    methods (Access = public)
        function self = DOA(direction_or_location, device_name, varargin)
            self.quiet = false;

            next_arg_is_value = false;
            for i = 1 : length(varargin)
                arg = varargin{i};
                if ~next_arg_is_value
                    switch arg
                        case 'quiet'
                            self.quiet = true;
                            next_arg_is_value = false;
                        otherwise
                            error('invalid argument');
                    end
                end
            end
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

            if self.quiet
                return
            end
            disp(msg);
        end
    end
end
