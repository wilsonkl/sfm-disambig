#include <mex.h>
#include <stdio.h>

/* mex function to write track files quickly                        */
/* Called in Matlab as so:                                          */
/*      writeTracksFile_mex(outFname,tracks,images,features)        */

void mexFunction(int nlhs, mxArray *plhs[ ],
                 int nrhs, const mxArray *prhs[ ])
{
    FILE *file;

    const double *tracks, *images, *features;
    const char* fname;
    int n;
    int unique_tracks;

    int i, j, prev_track, curr_track, track_start;

    /* check for right number of inputs and outputs */
    if (nrhs != 4)
    {
        mexPrintf("[writeTrackFile_mex] Error: 4 inputs expected!\n");
        return;
    }
    if (nlhs != 0)
    {
        mexPrintf("[writeTrackFile_mex] Error: this function should have no outputs\n");
        return;
    }

    n = mxGetM(prhs[0]);
    if ( (mxGetM(prhs[1]) != n ) || (mxGetM(prhs[2]) != n ) )
    {
        mexPrintf("[writeTrackFile_mex] Error: input vectors must be the same size!\n");
        return;
    }
    if (   (mxGetN(prhs[0]) != 1 ) ||
           (mxGetN(prhs[1]) != 1 ) ||
           (mxGetN(prhs[2]) != 1 )   )
    {
        mexPrintf("[writeTrackFile_mex] Error: input vectors must be column vectors!\n");
        return;
    }

    images   = mxGetPr(prhs[1]);
    tracks   = mxGetPr(prhs[0]);
    features = mxGetPr(prhs[2]);
    fname    = mxArrayToString(prhs[3]);

    /* open an output file */
    file = fopen(fname,"w");
    if (file == NULL)
    {
    mexPrintf("[writeTrackFile_mex] Error: Output file could not be opened!");
        return;
    }

    /* first we have to write the number of tracks */
    unique_tracks = 0;
    prev_track = -1;
    for(i=0;i<n;i++)
    {
        curr_track = (int) tracks[i];
        if (prev_track != curr_track)
        {
            unique_tracks++;
            prev_track = curr_track;
        }
    }
    fprintf(file,"%d\n",unique_tracks);

    /* loop through the records
    *  we can assume that 'tracks' is in ascending order.
    */
    track_start = 0;
    prev_track = -1; /* 1-indexed (yes, it's ugly) */
    for(i=0;i<n;i++)
    {
        curr_track = (int) tracks[i];


        if ( (prev_track != curr_track) && (i > track_start) )
        {
            /* write the line */
            fprintf(file,"%d",i-track_start);
            for (j=track_start;j<i;j++)
            {
                fprintf(file," %d %d",(int)images[j] -1,(int)features[j] -1);
            }

            fprintf(file,"\n");
            track_start = i;
            prev_track = curr_track;
        }

    }
    fclose(file);
}
