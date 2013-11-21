function fov = readFovFile(fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION readFovFile
%
% Read in a field of view file, which is just a array of doubles, one
% per line.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fin = fopen(fname,'r');
fov = fscanf(fin,'%f\n');
fclose(fin);
