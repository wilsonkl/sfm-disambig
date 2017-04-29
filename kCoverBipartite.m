function imgSubset = kCoverBipartite(biadjmat,k,fov,ALPHA,EPSILON,N)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the covering subgraph (see the paper- a subset of the images
% in a sfm problem that more eveny covers the scene)
%
% GIVEN:
%   fov:       an estimate for the angular field of view of each image
%              we've found it most stable to work with the horizantal
%              angle of features seen in the image, rather than
%              something simpler like optical fov.
%   biadjmat:  a (sparse) representation of a visibility graph
%   k:         the degree of cover to be computed
%
% RETURNS:
%   imgSubset: a subset of 1:size(biadjmat,2) which are the images
%              chosen to provide the proscribed cover. the resultant
%              subset is a cover in the following sense: every track
%              long enough has k neighbor images
%
% VIA:
%   greedy algorithm: score images via their imgScore * the number of
%   their non-covered neighbors. Select the highest score. Update the
%   number of non-covered neighbors. Terminate when a cover is
%   achieved or chosing additional images does not cover more tracks.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Clean graph: remove short tracks
biadjmat = double(logical(biadjmat));
biadjmat(:,fov == 0) = 0;
longTracks = (sum(logical(biadjmat),2)>=N);
biadjmat = biadjmat(longTracks,:);

%%% initalize loop vars
% remainingCover:     how many times each track needs to still be covered
% imgSubset:          array of indices of selected indices
% uncoveredNeighbors: persist how many neighbors of each image are still
%                     not k-covered.
% fractionUncovered:  the fraction of coverable tracks that are not yet
%                     k-covered
% loopCounter:        keep track of the current iteration number (debug)
% maxScore:           score of current highest-scoring image to choose
% maxImg:             index of current highest-scoring image to choose
%%%
remainingCover = repmat(k,size(biadjmat,1),1); % indexed by track
uncoveredNeighbors = full(sum(biadjmat,1)'); % indexed by image

fractionUncovered = 1;
loopCounter = 0;
imgSubset = [];

[maxScore,maxImg] = max((uncoveredNeighbors.^ALPHA).*fov);
maxScore = full(maxScore);

while maxScore > 0 && fractionUncovered > EPSILON
    imgSubset(end+1) = maxImg; %#ok<AGROW>

    neighbors = find(biadjmat(:,maxImg));
    %uncoveredNeighbors(maxImg) = uncoveredNeighbors(maxImg) - nnz(remainingCover(neighbors) == 1);
    % update uncoveredNeighbors
    just_covered_nbrs = find(biadjmat(:, maxImg) & (remainingCover == 1));
    for i=1:length(just_covered_nbrs)
        t = just_covered_nbrs(i);
        uncoveredNeighbors(biadjmat(t, :) > 0) = uncoveredNeighbors(biadjmat(t, :) > 0) - 1;
    end

    remainingCover(neighbors) = remainingCover(neighbors) - 1;
    remainingCover(remainingCover < 0) = 0;
    fov(maxImg) = 0;

    [maxScore,maxImg] = max((uncoveredNeighbors.^ALPHA).*fov);
    maxScore = full(maxScore);

    loopCounter = loopCounter + 1;
    fractionUncovered = nnz(remainingCover) / length(remainingCover);
end
