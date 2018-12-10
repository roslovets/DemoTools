classdef DemoToolsStorage < handle
    %Store data locally in installed toolbox folder
    
    properties
        E % Toolbox Extender
        fname % File name
        data % storage data
    end
    
    methods
        function obj = DemoToolsStorage(fname)
            % Constructor
            obj.E = DemoToolsExtender;
            if nargin < 1
                fname = matlab.lang.makeValidName(obj.E.name) + "_data";
            end
            obj.fname = fname;
        end
        
        function set.fname(obj, fname)
            % Set file name
            obj.fname = fname;
            obj.load();
        end
        
        function [fpath, fname] = genpath(obj)
            %Generate data file name
            fname = obj.fname + ".mat";
            fpath = fullfile(obj.E.root, fname);
        end
        
        function data = load(obj)
            %Load data from file
            fpath = obj.genpath();
            if isfile(fpath)
                data = load(fpath);
                data = data.data;
            else
                data = [];
            end
            obj.data = data;
        end
        
        function save(obj, data)
            %Save data to file
            if nargin < 2
                data = obj.data;
            else
                obj.data = data;
            end
            save(obj.genpath(), 'data');
        end
        
        function [val, isf] = get(obj, varname, type)
            %Get variable from data
            if isstruct(obj.data) && isfield(obj.data, varname)
                val = obj.data.(varname);
                isf = true;
            else
                val = [];
                isf = false;
            end
            if nargin > 2
                val = cast(val, type);
            end
        end
        
        function set(obj, varname, val, type)
            %Set variable in data
            if nargin > 3
                val = cast(val, type);
            end
            obj.data.(varname) = val;
        end
        
    end
end