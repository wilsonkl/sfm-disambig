function [blccU, blccV] = blcc(G,u,v,sigma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION [blccU, blccV] = blcc(G,u,v,sigma)
%
% Efficiently compute the bipartite local clustering coefficient
% (blcc) on a bipartite graph using random sampling.
%
% Representation:
%   A bipartite graph G=(U,V,E) with |U|=m, |V|=n, is represented by
%   its biadjacency matrix: G(i,j) = 1 iff (u_i,v_j) is in E, else 0.
%   G is a m-by-n matrix.
%
% Inputs:
%   G: sparse biadjacency for the input bipartite graph
%   u: indices into partition U at which to compute the blcc
%   v: indices into partition V at which to compute the blcc
%   sigma: abs. acceptable sampling error (at 95% confidence level)
%
% Returns:
%   blccU: array of same size as u containing the computed blccs
%   blccV: array of same size as v containing the computed blccs
%
% Notes:
% (1)   For a survey on local clustering coefficients over bipartite
%       graphs, see "Triadic closure in two-mode networks: Redefining
%       the global and local clustering coefficients"
%       http://toreopsahl.com/tnet/two-mode-networks/clustering/
%
% (2)   the blcc is not defined for nodes of degree 1. In this case,
%       this function will return 0.
%
% (3)   This function will take advantage of an open matlabpool
%       from the matlab parallel computing toolbox, if present.
%
% (4)   In some applications it is convenient to encode additional
%       information in the biadjacency matrix. In this case G is no
%       longer a logical matrix. To accomodate this, this function
%       uses only the non-zero structure of G.
%
% (5)   This implementation uses random sampling. In most applications
%       it is desirable to have set up rng shuffling, by calling:
%           rng('shuffle');
%
% Example:
%   Compute the blcc of the first 4 nodes in the second partition of
%   G. Take enough samples to get within 0.05 of the actual value (at
%   a 95% confidence level):
%
%       [~, blccV] = blcc(G,[],1:4,0.05)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% is the parallel computing toolbox avaiable? Are there nodes running?
if license('test','distrib_computing_toolbox') && ...
        matlabpool('size') > 1
    optParallel = true;
else
    optParallel = false;
end

% Cast to logical. Due to column/row major access times, it is
% efficient to precompute the transpose
G = logical(G);
G_t = G';

% Compute the scores on the first partition
if ~isempty(u)
    blccU = zeros(length(u),1);
    if optParallel == true
        parfor i=1:length(blccU)
            blccU(i) = scalarBlcc(G,G_t,u(i),sigma);
        end
    else
        for i=1:length(blccU)
            blccU(i) = scalarBlcc(G,G_t,u(i),sigma);
        end
    end
else
    blccU = [];
end

% Compute the scores on the second partition
if ~isempty(v)
    blccV = zeros(length(v),1);
    if optParallel == true
        parfor i=1:length(blccV)
            blccV(i) = scalarBlcc(G_t,G,v(i),sigma);
        end
    else
        for i=1:length(blccV)
            blccV(i) = scalarBlcc(G_t,G,v(i),sigma);
        end
    end
else
    blccV = [];
end


%%%
% SUBFUNCTION
% C = scalarBlcc(G,G_t,u)
%
% Compute the bipartite local clustering coefficient for a single
% vertex u of graph G.
%
% For efficiency, also require G' as input. Transposing very large
% matrices can be surprisingly expensive, as Matlab uses compressed
% column storage.
%
% This function uses random sampling.
%%%
function C = scalarBlcc(G,G_t,u,sigma)

% explicit enumeration of all 2-paths from root track

% with this representation it is easy to enumerate all two-paths
% starting at from root node u
neighbors = find(G_t(:,u));
[sample_u,sample_v] = find(G(:,neighbors));

% return gracefully if this nodes isn't connected enough to compute
if length(neighbors) <= 1, C = 0; return; end

% generate the random sampling of pairs of these 2-paths.
% sample with replacement because that's fast, and then reject
% invalid pairs of 2-paths.
% since we're very nearly just sampling from a binomial distribution,
% its easy to know how many samples to take.
normInv = 1.960; % norminv(0.975,0,1)
NUM_SAMPLES = ceil( (normInv/sigma/2)^2 );
rand_ind = randi(length(sample_u),NUM_SAMPLES,2);
vA  = sample_v(rand_ind(:,1));
vB  = sample_v(rand_ind(:,2));
uA = sample_u(rand_ind(:,1));
uB = sample_u(rand_ind(:,2));

% check which of these pairs are invalid: (ie, not vertex-disjoint
% non-degenerate two-paths)
bad_ind = (vA == vB) | (uA == uB) | (uA == u) | (uB == u);

% now check each random pair of 2-paths
count_closed = 0;
for i=1:NUM_SAMPLES
    % is this a valid 4-path?
    if bad_ind(i)
        continue;
    end
    % this is a valid 4-path. is it closed?
    if any( G_t(:,uA(i)) & G_t(:,uB(i)) )
        count_closed = count_closed + 1;
    end
end
C = count_closed / double((NUM_SAMPLES - nnz(bad_ind)));

