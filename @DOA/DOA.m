classdef DOA
    properties (Access = public)
        quiet               logical % Flag to print log messages
        sampl_rate          double  % Sampling rate
    end
    methods (Access = public)
        function self = DOA(direction_or_location, device_name, varargin)
            self.quiet = false;
            self.sampl_rate = 1e6;

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
                        otherwise
                            error(sprintf('invalid argument: %s', arg));
                    end
                else
                    next_arg_is_value = false;
                end
            end
        end
    end

    methods (Access = private)
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
    end
end
