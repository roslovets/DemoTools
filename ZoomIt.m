function ZoomIt
if ispc
    p = fileparts(mfilename('fullpath'));
    system(fullfile(p, 'bin', 'ZoomIt.exe &'));
else
    error('Your system is not supported by ZoomIt (Windows-only)')
end