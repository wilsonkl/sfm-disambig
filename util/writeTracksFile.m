function writeTracksFile(biadjmat,fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION writeTrackFile(biadjmat,fname)
%
% Write a biadjmat out as a track file. This is a wrapper around a mex
% function- this is enormously faster than using Matlab native I/O
% since the tracksfile format has variable length lines.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('writeTracksFile_mex') == 3
    % Do a slick bit of gymnastics: the mex file requires that the first
    % argument, representing the tracks of the biadjmat, be sorted ascending.
    % This accomplishes that.
    [c,r,v] = find(biadjmat'); % rows, columns, values
    writeTracksFile_mex(r,c,v,fname);
    return
end

% Here's a slow matlab-only version of track file writing
fprintf(['[writeTracksFile] Compile util/writeTracksFile_mex' ...
        ' to speed file writing up!']);

fid = fopen(fname,'w');

% get indices of all nonzero tracks
tracks = find(sum(logical(biadjmat),2)>0);
n_tracks = length(tracks);

% print the number of tracks to the file
fprintf(fid,'%d\n', n_tracks);

% print a line for each track to the file
for i=1:n_tracks
    images = find(biadjmat(tracks(i),:));
    n_images = length(images);

    fprintf(fid, '%d ', n_images);
    for j=1:n_images
        fprintf(fid, '%d %d ', images(j), full(biadjmat(tracks(i),images(j))));
    end
    fprintf(fid, '\n');
end

fclose(fid);


