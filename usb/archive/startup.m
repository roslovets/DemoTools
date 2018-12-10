% Setup MATLAB files directory
mlDir = [getenv('USERPROFILE') '\Documents\MATLAB'];
scriptMask = 'add*toPath.m';
% Script body
cd(mlDir);
dirs = dir;
dirs = dirs([dirs.isdir]);
trainDir = dirs(end).name;
startPath = fullfile(mlDir, trainDir);
cd(startPath)
startScript = dir(scriptMask);
if ~isempty(startScript)
    run(startScript(1).name);
end
clear
clc