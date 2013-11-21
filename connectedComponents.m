function CCs = connectedComponents(biadjmat,MIN_COMMON)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION CCs = connectedComponents(biadjmat,MIN_COMMON)
%
% Two images are considered connected if they have at least MIN_COMMON
% tracks in common. Identify all connected components.
%
% There's a hidden magic number: filter out trivially small components
% (ie, coded as smaller than 50 images).
%
% I also clean up length 1 tracks here, which aren't useful for
% structure from motion.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the connected components using a Matlab graph library from fex.
adjmat = connectivityAdjmat(biadjmat,MIN_COMMON);
[labels sizes] = scomponents(adjmat);

% for each found cc, stuff it to output (unless it's small)
CCs = cell(max(labels),1);
counter = 0;
for i=1:max(labels)
    CC = sparse(size(biadjmat,1),size(biadjmat,2));
    images = (labels == i);
    if nnz(images) > 50
        CC(:,images) = biadjmat(:,images);
        % filter out length 1 tracks
        CC(sum(logical(CC),2)<2,:) = 0;

        counter = counter+1;
        CCs{counter} = CC;
    end
end
CCs = CCs(1:counter);

end % connectedComponents

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION adjmat = connectivityAdjmat(biadjmat,MIN_COMMON)
%
% Make an adjacency matrix for images. Two images are considered
% adjacent if they have at least MIN_COMMON tracks in common.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adjmat = connectivityAdjmat(biadjmat,MIN_COMMON)
    biadjmat = double(logical(biadjmat));
    % transposing a big sparse matrix takes a small hit, but its
    % nothing compared to implementing this with loops.
    adjmat = (biadjmat' * biadjmat) >= MIN_COMMON;
end
