This is code accompanying the ICCV paper "Network Principles for SfM: Disambiguating Repeated Structures with Local Context". It is intended to be used as an add-on to a structure from motion pipeline such as bundler-sfm. Prior to reconstruction, this code takes a set of geometric constraints (tracks) and cleans them up, returning a second set which is hopefully free of the sorts of large errors caused by ambiguous scene objects.

Running the Code:
=================

All the code is written in Matlab. It should run out of the box, although see note 1 below. demo_sfmDisambiguation.m is the driver script, and contains variables to set up I/O paths according to your setup. As discussed in the paper, this method accepts one tracks file, and a file of image field of view information, and returns a new tracks file that is hopefully free from errors. The tracks file format is the same as that used in bundler, and is documented in util/readTracksFile.m

All code has been tested on Matlab R2011a- on other versions YMMV.

Code Notes:
===========

(1) The tracks file format doesn't play that well with Matlab, although it is very easy to read and write in C. In my own development I've used a mex'ed file writer which is included. To allow this code to run without toolboxes, I also incldued a pure-Matlab version in this code, but it is orders of magnitude slower- sometimes taking hours! If you have mex'ing abilities, do this:
    cd util
    mex writeTracksFile_mex.c

(2) The code for computing the bipartite local clustering coefficient will use multiple threads if a local matlabpool is open. If you have the parallel computing toolbox, set opt_useParallel=true in demo_sfmDisambiguation.m.

(3) This code is intended to be run as part of a structure from motion pipeline, where it recieves a set of tracks, cleans them, and passes them on to a geometric solver. However, in case it's useful, I've also included a few lines to extract the tracks out of an existing bundle file. This code isn't well optimized, so the file IO might take annoyingly long. To take input from a bundle file, change opt_tracksSource to 'bundlefile' in demo_sfmDisambiguation.m.

(4) This distribution is covered under a FreeBSD license. Please see the included license file for more details.

Contact:
========

Please address comments or questions about the code to:
Kyle Wilson, wilsonkl (at) cs.cornell.edu

Here is the bibTeX reference:
@inproceedings{wilson_iccv2013_disambig,
   Title = {Network Principles for SfM: Disambiguating Repeated Structures with Local Context}
   Author = {Kyle Wilson and Noah Snavely},
   booktitle = {Proceedings of the International Conference on Computer Vision ({ICCV})},
   Year = {2013},
}
