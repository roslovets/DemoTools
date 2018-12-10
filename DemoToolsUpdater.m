classdef DemoToolsUpdater < handle
    %Control version of installed toolbox and update it from GitHub
    
    properties
        E % Toolbox Extender
    end
    
    methods
        function obj = DemoToolsUpdater()
            % Init
            obj.E = DemoToolsExtender;
        end
        
        function [cv, iv, r] = ver(obj, echo)
            % Get local version
            if nargin < 2
                echo = true;
            end
            cv = obj.E.gcv();
            if echo
                if isempty(cv)
                    fprintf('%s is not installed\n', obj.E.name);
                else
                    fprintf('Installed version: %s\n', cv);
                end
            end
            % Get latest version
            [iv, r] = obj.E.giv();
            if echo
                if ~isempty(iv)
                    fprintf('Latest version: %s\n', iv);
                    if isequal(cv, iv)
                        fprintf('You use the latest version\n');
                    else
                        fprintf('* Update is available: %s->%s *\n', cv, iv);
                        fprintf("To update call 'update' method\n");
                    end
                else
                    fprintf('No remote version is available\n');
                end
            end
        end
        
        function yes = isonline(~)
            % Check connection to internet is available
            try
                java.net.InetAddress.getByName('google.com');
                yes = true;
            catch
                yes = false;
            end
        end
        
        function res = install(obj)
            % Install toolbox or app
            res = obj.E.install();
        end
        
        function installweb(obj, r)
            % Download and install latest version from web
            if nargin < 2
                [~, ~, r] = obj.ver(0);
            end
            fprintf('* Installation of %s is started *\n', obj.E.name);
            fprintf('Installing the latest version: v%s...\n', obj.E.iv);
            dpath = tempname;
            mkdir(dpath);
            fpath = fullfile(dpath, r.assets.name);
            websave(fpath, r.assets.browser_download_url);
            res = obj.install(fpath);
            fprintf('%s v%s has been installed\n', res.Name{1}, res.Version{1});
            delete(fpath);
        end
        
        function uninstall(obj)
            % Unstall toolbox or app
            obj.E.uninstall();
        end
        
        function yes = isupdate(obj)
            % Check that update is available
            obj.ver(0);
            yes = ~isempty(obj.E.iv) & ~isequal(obj.E.cv, obj.E.iv);
        end
        
        function update(obj)
            % Update installed version to latest
            [~, ~, r] = obj.ver();
            if obj.isupdate()
                obj.installweb(r);
            end
        end
        
    end
end

