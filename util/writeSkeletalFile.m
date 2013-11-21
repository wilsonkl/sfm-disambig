function writeSkeletalFile(G,skeletalSubset,fileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION writeSkeletalFile(G,skeletalSubset,fileName)
%
% Write a skeletal file. This is just a list of image indices. This
% is the skeletal component- the subgraph to be reconstructed first.
%
% The file consists of the number of skeletal images, followed by
% their 0-based indices, all on a single line separated by spaces.
%
% To facilitate use with connected components, intersect the given
% subset with the images used in a particular given graph.
%
% Inputs:
%    G:               a visibility graph
%    skeletalSubset:  an array of 1-indexed image indices, of which a
%                     subset will be written
%    fileName:        output file name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

allImages = find(any(G,1));
imagesToWrite = intersect(skeletalSubset,allImages);

fid = fopen(fileName,'w');
fprintf(fid,'%d ',[length(imagesToWrite) imagesToWrite-1]);
fclose(fid);
