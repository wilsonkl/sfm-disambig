function sfmDisambiguation_iccv(biadjmat,fov,outDir, ...
                   k,EPSILON,ALPHA,NUM_COMPONENTS,N,MIN_COMMON)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION sfmDisambiguation
%
% Run the network-based disambiguation from the ICCV paper on a sfm
% dataset.
%
% INPUTS:
%   biadjmat: the visibility graph. That is, a sparse  matrix
%       indexing tracks by rows and images by columns. (i,j)=1
%       indicates that track i includes image j.
%       Furthermore, the value of biadjmat(i,j) encodes which index
%       feature (1-based) in image j track i corresponds to.
%   fov: an estimate of the field of view of each image (size
%       n_images x 1). Images with unknown fov should be assigned 0.
%   outDir: where to put the resulting files
%   k,EPSILON,ALPHA,NUM_COMPONENTS,N,MIN_COMMON: algorithm parameters,
%      as described in the paper
%
% OUTPUTS:
% The following files are written to outDir, where ranges from 1 to
% the number of components produced by the disambiguation.
%   summary.txt: records the inputs, the output filenames, and other
%       diagnostic numbers
%   tracks_X.txt: files describing the new disambiguated tracks.
%   skeletal_X.txt: files listing the images in the covering subgraph
%       for each component
%
% NOTES:
%   File formats for track_X.txt and skeletal_X.txt are documented in
%   their respective writing functions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%
%%% INPUT %%%
%%%%%%%%%%%%%

tic_start = tic;
start_time = now;

if ~exist(outDir,'dir')
    disp(outDir)
    error('[sfmDisambiguation] outDir does not exist!');
end

% write input info to a log file
summaryFile = [outDir '/summary.txt'];
fid = fopen(summaryFile,'w');
fprintf(fid,'sfmDisambiguation log\n');
fprintf(fid,'outDir: %s\n\n',outDir);

fprintf(fid,'Input Params:\n');
fprintf(fid,'k:\t\t%d\n',k);
fprintf(fid,'EPSILON:\t%3.2f\n',EPSILON);
fprintf(fid,'ALPHA:\t\t%3.2f\n',ALPHA);
fprintf(fid,'NUM_COMPONENTS:\t%d\n',NUM_COMPONENTS);
fprintf(fid,'N:\t\t%d\n',N);
fprintf(fid,'MIN_COMMON:\t%d\n',MIN_COMMON);

%%%%%%%%%%%%%%%
%%% COMPUTE %%%
%%%%%%%%%%%%%%%

% compute a (1-epsilon) approximate k-cover
% ie, a subset of the images that covers almost all the tracks k times
tic_cover = tic;
kCover = kCoverBipartite(biadjmat,k,fov,ALPHA,EPSILON,N);
time_cover = toc(tic_cover);

% form the visibility graph restricted to the k-cover
subBiadjmat = sparse(size(biadjmat,1),size(biadjmat,2));
subBiadjmat(:,kCover) = biadjmat(:,kCover);

% compute the bipartite local clustering coeff on the images in the
% k-cover subgraph
% Empirically, the blcc performs poorly on tracks of degree < 10 as
% this is too small to have clear bipartite clustering behavior.
tic_scoring = tic;
long_tracks = find(sum(logical(biadjmat),2)>=10);
scores = zeros(size(biadjmat,1),1);
[scores(long_tracks), ~] = blcc(subBiadjmat,long_tracks,[],0.05);
time_scoring = toc(tic_scoring);

% choose a threshold adaptively: use bisection to pick a threshold
% that returns enough components. This is rather hacky.
tic_CCs = tic;
num_found_CCs = 1;
while(true)
    threshold_sure  = 1.0;
    threshold_guess = 0.5;
    for i=1:12
        % fprintf('threshold_guess: %f\t\t',threshold_guess);

        % discard all bad tracks, form new vizibility graph
        badTracks = (scores > 0) & (scores < threshold_guess);
        newBiadjmat = biadjmat;
        newBiadjmat(badTracks,:) = 0;

        % break this graph into connected components
        CCs = connectedComponents(newBiadjmat,MIN_COMMON);
        % fprintf('nCCs: %d\n',length(CCs));

        if length(CCs) >= NUM_COMPONENTS
            threshold_sure = threshold_guess;
            threshold_guess = threshold_guess - 2^(-i-1);
        else
            threshold_guess = threshold_guess + 2^(-i-1);
        end
    end

    % compute CCs again with the best threshold
    badTracks = (scores > 0) & (scores < threshold_sure);
    newBiadjmat = biadjmat;
    newBiadjmat(badTracks,:) = 0;
    CCs = connectedComponents(newBiadjmat,MIN_COMMON);
    % fprintf('chosen threshold: %f\t\tnCCs: %d\n',threshold_sure, length(CCs));

    if length(CCs) < NUM_COMPONENTS
        % fprintf('---mandatory decrease in NUM_COMPONENTS---\n');
        NUM_COMPONENTS = NUM_COMPONENTS-1;
    else
        break;
    end
end
time_CCs = toc(tic_CCs);

%%%%%%%%%%%%%%%%%%%%
%%% WRITE OUTPUT %%%
%%%%%%%%%%%%%%%%%%%%

% write tracks files and skeletal files
tic_write = tic;
for i=1:length(CCs)
    % don't write insignficantly small components
    nnz_images = nnz(sum(logical(CCs{i}),1));
    if nnz_images > 10
        tracksOut   = sprintf('%s/outTracks_%d.txt',outDir,i);
        skeletalOut = sprintf('%s/outSkeletal_%d.txt',outDir,i);

        writeTracksFile(CCs{i},tracksOut);
        writeSkeletalFile(CCs{i},kCover,skeletalOut);
    end
end
time_write = toc(tic_write);

% write a summary file
if license('test','distrib_computing_toolbox') &&  ...
        matlabpool('size')>0
    fprintf(fid,'\nScoring in parallel on %d cores\n', ...
        matlabpool('size'));
end
fprintf(fid,'\nTiming Data: (tic/toc seconds)\n');
fprintf(fid,'Compute k-Cover:     %7.2f\n',time_cover);
fprintf(fid,'Compute blcc scores: %7.2f\n',time_scoring);
fprintf(fid,'Compute CCs:         %7.2f\n',time_CCs);
fprintf(fid,'Write output:        %7.2f\n',time_write);
fprintf(fid,'Total Time:          %7.2f\n',toc(tic_start));
fprintf(fid,'Start time: %s\n',datestr(start_time,'HH:MM:SS, dd mmm yyyy'));
fprintf(fid,'Stop time:  %s\n',datestr(now,'HH:MM:SS, dd mmm yyyy'));

fprintf('\nkCover size:\t%d\n',length(kCover));

fprintf(fid,'\nComponent Information:\n');
fprintf(fid,'Component:\tnum images\tnum tracks\n');

for i=1:length(CCs)
    % don't write insignficantly small components
    nnz_images = nnz(sum(logical(CCs{i}),1));
    nnz_tracks = nnz(sum(logical(CCs{i}),2));
    fprintf(fid,'%d\t\t%d\t\t%8d\n',i,nnz_images,nnz_tracks);
end
nnz_images = nnz(sum(logical(biadjmat),1));
nnz_tracks = nnz(sum(logical(biadjmat),2));
fprintf(fid,'original\t%d\t\t%8d\n',nnz_images,nnz_tracks);
fclose(fid);
