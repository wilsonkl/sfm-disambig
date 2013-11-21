function biadjmat = readTracksFile(fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION readTracksFile
%
% read in a tracks file into a (sparse) biadjacency matrix.
%
% FORMATS:
%   tracks file:
%       The first line is a single integer: <nTracks>
%       Each following line is of the following format:
%       n <img1> <feat1> ... <img_n> <feat_n>
%       where images and features are 0-indexed.
%       images is indexed into a list file by line number, and
%       features are indexed into SIFT key files
%
%   biadjmat: the visibility graph. That is, a sparse (1-indexed)
%       matrix indexing tracks by rows and images by columns. (i,j)=1
%       indicates that track i includes image j.
%       Furthermore, the value of biadjmat(i,j) encodes which index
%       feature (1-based) in image j track i corresponds to.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the file with the track data
fin = fopen(fname,'r');

% take care of the one line header
numTracks = str2double(fgetl(fin));

% read in the lines
allocatedRows = min(numTracks*100,100000); % It seems that preallocating 1.5M entries crashes Matlab...
sp_rows = zeros(allocatedRows,1);
sp_cols = zeros(allocatedRows,1);
sp_values = zeros(allocatedRows,1);
count = 0;

% The files are small enough to fit into memory. Read the whole thing
% in. This is an optimized way to read in: since line length is
% encoded within the file format, we can ignore line breaks, read all
% numbers into a vector, and traverse the vector with a pointer.
data = fscanf(fin,'%d');
pointer = 1;
for j=1:numTracks
    % read in the line
    % the first  field is the number of views
    numViews = data(pointer)    ;
    views    = data(pointer+1:2:pointer+2*numViews);
    features = data(pointer+2:2:pointer+2*numViews);
    pointer = pointer + 2*numViews + 1;

    % allocate more space if necessary
    if count + numViews > allocatedRows
        sp_rows   = [sp_rows;   zeros(allocatedRows,1)]; %#ok<AGROW>
        sp_cols   = [sp_cols;   zeros(allocatedRows,1)]; %#ok<AGROW>
        sp_values = [sp_values; zeros(allocatedRows,1)]; %#ok<AGROW>
        allocatedRows = allocatedRows * 2;
    end

    % stuff the "line" we just read
    sp_rows(  count+1:count+numViews) = repmat(j,numViews,1);
    sp_cols(  count+1:count+numViews) = views;
    sp_values(count+1:count+numViews) = features;
    count = count + numViews;
end

% trim the preallocated space to length
sp_rows   = sp_rows(1:count);
sp_cols   = sp_cols(1:count);
sp_values = sp_values(1:count);

% switch to 1-indexing and stuff into a sparse structure
sp_cols   = sp_cols+1; % biadjmat is 1-indexed
sp_values = sp_values+1; % biadjmat is 1-indexed
biadjmat = sparse(sp_rows,sp_cols,sp_values);

fclose(fin);
