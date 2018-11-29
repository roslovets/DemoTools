classdef FontSizerUpdater < handle
    % Let you control version of installed toolbox and update it from
    % GitHub remote
    
    properties
        name % project name
        pname % name of project file
        ptype % type of project
        remote % GitHub link
        pv % project version
        cv % current installed version
        iv % latest version form internet
        root % root dir
        updaterv % updaterv version
    end
    
    methods
        function obj = FontSizerUpdater(root)
            % Tools Constructor
            if nargin < 1
                obj.root = fileparts(mfilename('fullpath'));
            else
                obj.root = root;
            end
            if ~obj.readconfig()
                obj.getpname();
                obj.getptype();
                obj.getname();
                obj.getremote();
            end
            if ~isempty(obj.pname)
                obj.pv = obj.gpv();
            end
            obj.gcv();
        end
        
        function name = getname(obj)
            % Get project name from project file
            name = '';
            ppath = fullfile(obj.root, obj.pname);
            if isfile(ppath)
                txt = obj.readtxt(ppath);
                name = char(extractBetween(txt, '<param.appname>', '</param.appname>'));
            end
            obj.name = name;
        end
        
        function name = getvalidname(obj)
            % Get valid variable name
            name = char(obj.name);
            name = name(isstrprop(name, 'alpha'));
        end
        
        function pname = getpname(obj)
            % Get project name
            fs = dir(fullfile(obj.root, '*.prj'));
            if ~isempty(fs)
                pname = fs(1).name;
                obj.pname = pname;
            else
                error('Project file was not found in a current folder');
            end
        end
        
        function bpath = getbinpath(obj)
            % Get generated binary file path            
            [~, name] = fileparts(obj.pname);
            if obj.ptype == "toolbox"
                ext = ".mltbx";
            else
                ext = ".mlappinstall";
            end
            bpath = fullfile(obj.root, name + ext);
        end
        
        function ptype = getptype(obj)
            % Get project type (Toolbox/App)
            ppath = fullfile(obj.root, obj.pname);
            txt = obj.readtxt(ppath);
            if contains(txt, 'plugin.toolbox')
                ptype = 'toolbox';
            elseif contains(txt, 'plugin.apptool')
                ptype = 'app';
            else
                ptype = '';
            end
            obj.ptype = ptype;
        end
        
        function remote = getremote(obj)
            % Get remote (GitHub) address
            [~, cmdout] = system('git remote -v');
            remote = extractBetween(cmdout, 'https://', '.git', 'Boundaries', 'inclusive');
            if ~isempty(remote)
                remote = remote(end);
            end
            remote = char(remote);
            obj.remote = remote;
        end
        
        function [uname, upath] = clone(obj)
            % Clone FontSizerUpdater class to current Project folder
            TU = FontSizerUpdater(pwd);
            uname = TU.getvalidname + "Updater";
            upath = uname + ".m";
            oname = mfilename('class');
            opath = fullfile(obj.root, oname + ".m");
            copyfile(opath, upath);
            obj.txtrep(upath, oname, uname);
        end
        
        function nfname = copyscript(obj, sname, newclass)
            % Copy script to Project folder
            spath = fullfile(obj.root, 'scripts', sname + ".m");
            nfname = sname + ".m";
            copyfile(spath, nfname);
            if nargin > 2
                obj.txtrep(nfname, mfilename('class'), newclass);
            end
        end
        
        function pv = gpv(obj)
            % Get project version
            ppath = fullfile(obj.root, obj.pname);
            if isfile(ppath)
                if obj.ptype == "toolbox"
                    pv = matlab.addons.toolbox.toolboxVersion(ppath);
                else
                    txt = obj.readtxt(ppath);
                    pv = char(regexp(txt, '(?<=(<param.version>))(.*?)(?=(</param.version>))', 'match'));
                end
            else
                pv = '';
            end
            obj.pv = pv;
        end
        
        function cv = gcv(obj)
            % Get current installed version
            if obj.ptype == "toolbox"
                tbx = matlab.addons.toolbox.installedToolboxes;
                tbx = struct2table(tbx, 'AsArray', true);
                idx = strcmp(tbx.Name, obj.name);
                cv = tbx.Version(idx);
                if isscalar(cv)
                    cv = char(cv);
                elseif isempty(cv)
                    cv = '';
                end
            else
                tbx = matlab.apputil.getInstalledAppInfo;
                cv = '';
            end
            obj.cv = cv;
        end
        
        function [iv, r] = giv(obj)
            % Get internet version from GitHub
            iname = string(extractAfter(obj.remote, 'https://github.com/'));
            url = "https://api.github.com/repos/" + iname + "/releases/latest";
            try
                r = webread(url);
                iv = r.tag_name;
                iv = erase(iv, 'v');
            catch e
                iv = '';
                r = '';
            end
            obj.iv = iv;
        end
        
        function [cv, iv, r] = ver(obj, echo)
            % Get local version
            if nargin < 2
                echo = true;
            end
            cv = obj.gcv();
            if echo
                if isempty(cv)
                    fprintf('%s is not installed\n', obj.name);
                else
                    fprintf('Installed version: %s\n', cv);
                end
            end
            % Get latest version
            [iv, r] = obj.giv();
            if echo
                fprintf('Latest version: %s\n', iv);
                if isequal(cv, iv)
                    fprintf('You use the latest version\n');
                else
                    fprintf('* Update is available: %s->%s *\n', cv, iv);
                    fprintf('To update run update command\n');
                end
            end
        end
        
        function yes = isonline(~)
            % Check connection to internet is available
            try
                java.net.InetAddress.getByName('google.com');
                yes = true;
            catch e
                yes = false;
            end
        end
        
        function install(obj, r)
            % Download and install latest version from web
            if nargin < 2
                [~, ~, r] = obj.ver(0);
            end
            fprintf('* Installation of %s is started *\n', obj.name);
            fprintf('Installing the latest version: v%s...\n', obj.iv);
            dpath = tempname;
            mkdir(dpath);
            fpath = fullfile(dpath, r.assets.name);
            websave(fpath, r.assets.browser_download_url);
            if obj.ptype == "toolbox"
                res = matlab.addons.install(fpath);
            else
                res = matlab.apputil.install(fpath);
            end
            fprintf('%s v%s has been installed\n', res.Name{1}, res.Version{1});
            delete(fpath);
        end
        
        function update(obj)
            % Update installed version to latest
            [~, ~, r] = obj.ver();
            if obj.isupdate()
                obj.install(r);
            end
        end
        
        function yes = isupdate(obj)
            % Check that update is available
            obj.ver(0);
            yes = ~isempty(obj.iv) & ~isequal(obj.cv, obj.iv);
        end
        
        function doc(obj)
            % Open getting started manual
            docpath = fullfile(obj.root, 'doc', 'GettingStarted.html');
            web(docpath);
        end
        
        function examples(obj)
            % cd to Examples dir
            expath = fullfile(obj.root, 'examples');
            cd(expath);
        end
        
        function txt = readtxt(~, fpath)
            % Read text from file
            f = fopen(fpath, 'r', 'n', 'windows-1251');
            txt = fread(f, '*char')';
            fclose(f);
        end
        
        function writetxt(~, txt, fpath)
            % Wtite text to file
            fid = fopen(fpath, 'w', 'n', 'windows-1251');
            fwrite(fid, unicode2native(txt, 'windows-1251'));
            fclose(fid);
        end
        
        function txt = txtrep(obj, fpath, old, new)
            % Replace in txt file
            txt = obj.readtxt(fpath);
            txt = replace(txt, old, new);
            obj.writetxt(txt, fpath);
        end
        
        function ok = readconfig(obj)
            % Read config from xml file
            confname = 'ToolboxConfig.xml';
            confpath = fullfile(obj.root, confname);
            ok = isfile(confpath);
            if ok
                xml = xmlread(confpath);
                conf = obj.getxmlitem(xml, 'config', 0);
                obj.name = obj.getxmlitem(conf, 'name');
                obj.pname = obj.getxmlitem(conf, 'pname');
                obj.ptype = obj.getxmlitem(conf, 'ptype');
                obj.remote = erase(obj.getxmlitem(conf, 'remote'), '.git');
                obj.updaterv = obj.getxmlitem(conf, 'updaterv');
            end
        end
        
        function [confname, confpath] = writeconfig(obj)
            % Write config to xml file
            docNode = com.mathworks.xml.XMLUtils.createDocument('config');
            docNode.appendChild(docNode.createComment('FontSizerUpdater configuration file'));
            obj.addxmlitem(docNode, 'name', obj.name);
            obj.addxmlitem(docNode, 'pname', obj.pname);
            obj.addxmlitem(docNode, 'ptype', obj.ptype);
            obj.addxmlitem(docNode, 'remote', obj.remote);
            obj.addxmlitem(docNode, 'updaterv', obj.updaterv);
            confname = 'ToolboxConfig.xml';
            confpath = fullfile(obj.root, confname);
            xmlwrite(confpath, docNode);
        end
        
        function i = getxmlitem(~, xml, name, getData)
            % Get item from XML
            if nargin < 4
                getData = true;
            end
            i = xml.getElementsByTagName(name);
            i = i.item(0);
            if getData
                i = i.getFirstChild;
                if ~isempty(i)
                    i = i.getData;
                end
                i = char(i);
            end
        end
        
        function addxmlitem(~, node, name, value)
            % Add item to XML
            doc = node.getDocumentElement;
            el = node.createElement(name);
            el.appendChild(node.createTextNode(value));
            doc.appendChild(el);
        end
        
        function build(obj, pv)
            % Build toolbox for specified version
            ppath = fullfile(obj.root, obj.pname);
            obj.gendoc();
            if nargin > 1
                if obj.ptype == "toolbox"
                    matlab.addons.toolbox.toolboxVersion(ppath, pv);
                else
                    txt = obj.readtxt(ppath);
                    txt = regexprep(txt, '(?<=(<param.version>))(.*?)(?=(</param.version>))', pv);
                    txt = strrep(txt, '<param.version />', '');
                    obj.writetxt(txt, ppath);
                end
                obj.pv = pv;
            end
            bname = strrep(obj.name, ' ', '-');
            bpath = fullfile(obj.root, bname);
            if obj.ptype == "toolbox"
                obj.seticons();
                matlab.addons.toolbox.packageToolbox(ppath, bname);
            else
                matlab.apputil.package(ppath);
                movefile(fullfile(obj.root, obj.name + ".mlappinstall"), bpath + ".mlappinstall",'f');
            end
            obj.echo('has been built');
        end
        
        function push(obj)
            % Commit and push project to GitHub
            commitcmd = sprintf('git commit -m v%s', obj.pv);
            system('git add .');
            system(commitcmd);
            system('git push');
            obj.echo('has been pushed');
        end
        
        function tag(obj)
            % Tag git project and push tag
            tagcmd = sprintf('git tag -a v%s -m v%s', obj.pv, obj.pv);
            system(tagcmd);
            system('git push --tags');
            obj.echo('has been tagged');
        end
        
        function untag(obj, v)
            % Delete tag from local and remote
            untagcmd1 = sprintf('git push --delete origin v%s', v);
            untagcmd2 = sprintf('git tag -d v%s', v);
            system(untagcmd1);
            system(untagcmd2);
            system('git push --tags');
            obj.echo('has been untagged');
        end
        
        function deploy(obj, pv)
            % Build toolbox, push and tag version
            if nargin > 1
                obj.build(pv);
            else
                obj.build();
            end
            obj.push();
            obj.tag();
            obj.echo('has been deployed');
            clipboard('copy', ['"' char(obj.getbinpath) '"'])
            disp("Binary path was copied to clipboard")
            disp("* Now create release on GitHub page with binary attached *")
            pause(1)
            web(obj.remote + "/releases/edit/v" + obj.pv, '-browser')
        end
        
        function echo(obj, msg)
            % Display service message
            fprintf('%s v%s %s\n', obj.name, obj.pv, msg);
        end
        
        function gendoc(obj)
            % Generate html from mlx doc
            docdir = fullfile(obj.root, 'doc');
            fs = struct2table(dir(fullfile(docdir, '*.mlx')), 'AsArray', true);
            fs = convertvars(fs, 1:3, 'string');
            for i = 1 : height(fs)
                [~, fname] = fileparts(fs.name(i));
                fprintf('Converting %s...\n', fname);
                fpath = fullfile(fs.folder(i), fs.name{i});
                htmlpath = fullfile(fs.folder(i), fname + ".html");
                matlab.internal.liveeditor.openAndConvert(char(fpath), char(htmlpath));
                disp('Doc has been generated');
            end
        end
        
        function seticons(obj)
            % Set icons to app
            xmlfile = 'DesktopToolset.xml';
            oldtxt = '<icon filename="matlab_app_generic_icon_' + string([16; 24]) + '"/>';
            newtxt = '<icon path="./" filename="icon_' + string([16; 24]) + '.png"/>';
            if isfile(xmlfile) && isfolder('resources')
                if all(isfile("resources/icon_" + [16 24] + ".png"))
                    txt = obj.readtxt(xmlfile);
                    if contains(txt, oldtxt)
                        txt = replace(txt, oldtxt, newtxt);
                        obj.writetxt(txt, xmlfile);
                    end
                end
            end
        end
        
    end
end
