function biadjmat = bundledata2biadjmat(bundledata)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION bundledata2biadjmat
%
% Extract the visibility graph from bundle data.
%
% Returns:
%   biadjmat: the visibility graph. That is, a sparse  matrix
%       indexing tracks by rows and images by columns. (i,j)=1
%       indicates that track i includes image j.
%
%       Furthermore, the value of biadjmat(i,j) encodes which index
%       feature (1-based) in image j track i corresponds to.
%
% Input: a bundledata structure of the format defined in (for example)
%   readBundleFile.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arrayGrowLength = 10000;
currArrayLength = 0;

r = zeros(arrayGrowLength,1);
c = zeros(arrayGrowLength,1);
v = zeros(arrayGrowLength,1);

for i=1:bundledata.nPts
    views = bundledata.views{i}(:,1);
    keys  = bundledata.views{i}(:,2);
    n = length(views);

    while currArrayLength + n > length(r)
        r = [r; zeros(arrayGrowLength,1)]; %#ok<*AGROW>
        c = [c; zeros(arrayGrowLength,1)];
        v = [v; zeros(arrayGrowLength,1)];
    end

    r(currArrayLength+1:currArrayLength+n) = repmat(i,n,1);
    c(currArrayLength+1:currArrayLength+n) = views+1;
    v(currArrayLength+1:currArrayLength+n) = keys+1;
    currArrayLength = currArrayLength + n;
end

r = r(1:currArrayLength);
c = c(1:currArrayLength);
v = v(1:currArrayLength);

biadjmat = sparse(r,c,v,bundledata.nPts,bundledata.nCams);
