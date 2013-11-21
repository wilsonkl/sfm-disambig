function bundledata = readBundleFile(fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION readBundleFile
%
% Read in a bundle version 0.3 format bundle file. Return a structure
% with the following fields:
%
% bundledata.f   : camera focal length
% bundledata.k1  : camera distortion model coeff
% bundledata.k2  : camera distortion model coeff
% bundledata.R   : camera rotation matrix
% bundledata.t   : camera translation vector
% bundledata.cop : camera Center of Projection (3D location)
%
% bundledata.points : 3D coords of each point
% bundledata.colors : scene color of each point
% bundledata.views  : where this point is seen
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fin = fopen(fname);

% header
fgetl(fin);
data = str2num(fgetl(fin));
nCams = data(1); nPts = data(2);

% initialize the output structure
bundledata = struct();
bundledata.nCams = nCams;
bundledata.nPts  = nPts;
bundledata.f    = zeros(nCams,1);
bundledata.k1   = zeros(nCams,1);
bundledata.k2   = zeros(nCams,1);
bundledata.R    = zeros(nCams,9);
bundledata.t    = zeros(nCams,3);
bundledata.cop  = zeros(nCams,3);
bundledata.points  = zeros(nPts,3);
bundledata.colors  = zeros(nPts,3);
bundledata.views   = cell(nPts,1);

% read each camera
for i=1:nCams
    % intrinsics: k, f1, f2
    data = str2num(fgetl(fin));
    bundledata.f(i)  = data(1);
    bundledata.k1(i) = data(2);
    bundledata.k2(i) = data(3);

    % rotation matrix
    for j=1:3
        data = str2num(fgetl(fin));
        R(j,:) = data;
    end
    bundledata.R(i,:) = reshape(R,1,9);

    % translation
    data = str2num(fgetl(fin));
    bundledata.t(i,:) = data(:);
    bundledata.cop(i,:) = (-R'*bundledata.t(i,:)')';
end

% read each point
for i=1:nPts
    % location
    data = str2num(fgetl(fin));
    bundledata.points(i,:) = data;

    % color
    data = str2num(fgetl(fin));
    bundledata.colors(i,:) = data;

    % views
    data = str2num(fgetl(fin));
    data = reshape(data(2:end),4,[])';
    bundledata.views{i} = data;
end
