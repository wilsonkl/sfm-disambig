clc, clear all
addpath(genpath('./util'));
rng('shuffle'); % set up the random number generator

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% demo_sfmDisambiguation
%
% Script to run the structure from motion disambiguation method from
% the ICCV2013 paper. See the paper for a discussion of parameters.
%
% This script demonstrates two ways to run the code: from a given
% tracks.txt file, or by extracting tracks out of a bundle file. The
% second way may take a while to read in input for large datasets
% since the I/O functions involved are not optimized.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% PARAMS %%%
k              = 10;
EPSILON        = 0.02;
ALPHA          = 0.3;
N              = 15;
MIN_COMMON     = 200;
NUM_COMPONENTS = 6;

%%% OPTIONS %%%
opt_useParallel = false; % should we use a local pool if available?
opt_tracksSource = 'tracksfile'; % normal option: pre-sfm tracks
% opt_tracksSource = 'bundlefile'; % read in tracks from a bundle file
% opt_tracksSource = 'nvmfile'; % read in tracks from an NVM file

%%% DATA PATHS %%%
dataset = '../datasets/Seville';
tracksfile = [dataset '/tracks.txt'];
fovfile    = [dataset '/fov.txt'   ];
bundlefile = [dataset '/bundle.out'];
nvmfile    = [dataset '/model.nvm' ];
outdir = '../output';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(outdir,'dir')
    mkdir(outdir)
end

% read input data
fprintf('Reading in data\n');
if strcmp(opt_tracksSource, 'tracksfile')
    biadjmat = readTracksFile(tracksfile);
elseif strcmp(opt_tracksSource, 'bundlefile')
    bundledata = readBundleFile(bundlefile);
    biadjmat = bundledata2biadjmat(bundledata);
elseif strcmp(opt_tracksSource, 'nvmfile')
    convertNvmFileToTracksAndFov(nvmfile, tracksfile, fovfile);
    biadjmat = readTracksFile(tracksfile);
else
    error('Unknown tracks source');
end
fov = readFovFile(fovfile);

% is the parallel computing toolbox available?
% do we need to start it up?
if opt_useParallel && license('test','distrib_computing_toolbox')
    gcp
end

fprintf('disambiguating\n');
sfmDisambiguation(biadjmat,fov,outdir, ...
    k,EPSILON,ALPHA,NUM_COMPONENTS,N,MIN_COMMON)
