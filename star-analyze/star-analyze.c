/*
 * Star-Analyze, a star quality analyzing tool
 *
 * Copyright (c) 2014, Kalle Vahlman
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdint.h>
#include <assert.h>

#include <astrometry/anqfits.h>
#include <astrometry/sip_qfits.h>

#define SAMPLE_SIZE 32

/* All sampled data */
static double sdata[SAMPLE_SIZE*SAMPLE_SIZE];
/* Single row/column of sampled data */
static double ldata[SAMPLE_SIZE];

/* Find maximum intensity, return also column where it was */
double calculate_max(double *data, int len, int *column)
{
    int i;
    double max = 0;
    for (i = 0; i<len; i++) {
        if (max < data[i]) {
            max = data[i];
            if (column != NULL)
                *column = i;
        }
    }
    return max;
}

/* Calculate Full Width Half Maximum for given row of data */
double calculate_fwhm(double *data, int len)
{
    int i, es, ee;
    double maxpos, hmax, hmax1pos, hmax2pos;
    double max = 0;

    assert(data != NULL);

    /* Find maximum intensity */
    for (i = 0; i<len; i++) {
        if (max < data[i]) {
            maxpos = i;
            max = data[i];
        }
    }
    hmax = max*0.5;

    /* Find the half intensity index boundary and calculate
       the fractional position of "left" side */
    i = maxpos;
    while (hmax < data[i]) i--;
    es = i;
    while (hmax >= data[i]) i++;
    ee = i;
    hmax1pos = es + (hmax-data[es])/(data[ee]-data[es]);

    /* Find the half intensity index boundary and calculate
       the fractional position of "right" side */
    i = maxpos;
    while (hmax < data[i]) i++;
    ee = i;
    while (hmax >= data[i]) i--;
    es = i;
    hmax2pos = es + (hmax-data[es])/(data[ee]-data[es]);

    /* Full Width Half Maximum is the distance between half maximums */
    return hmax2pos - hmax1pos;
}

int main(int argc, char **argv)
{
    anqfits_t* infits;
    qfits_header* header;
    double *data;
    double max, hfwhm, vfwhm;
    int w, h, i, x, y, maxrow, maxcolumn;

    if (argc < 4) {
        printf("Star-Analyze v1.0\n");
        printf("Usage: %s: image X Y\n\n", argv[0]);
        printf("\timage\tFITS image to inspect\n");
        printf("\tX,Y\tCenter (pixel) coordinates of sampling area\n");
        printf("\t\tSampled area is %dx%d\n", SAMPLE_SIZE, SAMPLE_SIZE);
        return 1;
    }

    infits = anqfits_open(argv[1]);
    if (infits == NULL) {
        printf("Unable to open '%s'\n", argv[1]);
        return 1;
    }

    header = anqfits_get_header(infits, 0);
    if (header == NULL) {
        printf("Unable to read FITS header from '%s'\n", argv[1]);
        return 1;
    }

    /* Fetch image size and adjust for boundary check */
    sip_get_image_size(header, &w, &h);
    qfits_header_destroy(header);
    w -= SAMPLE_SIZE/2;
    h -= SAMPLE_SIZE/2;

    /* Boundary checks */
    x = atoi(argv[2]);
    if (x < SAMPLE_SIZE/2) {
        printf("Warning: X coordinate out of range, adjusting %d => %d\n", x, SAMPLE_SIZE/2);
        x = SAMPLE_SIZE/2;
    }
    if (x > w) {
        printf("Warning: X coordinate out of range, adjusting %d => %d\n", x, w);
        x = w;
    }
    y = atoi(argv[3]);
    if (y < SAMPLE_SIZE/2) {
        printf("Warning: Y coordinate out of range, adjusting %d => %d\n", y, SAMPLE_SIZE/2);
        y = SAMPLE_SIZE/2;
    }
    if (y > h) {
        printf("Warning: Y coordinate out of range, adjusting %d => %d\n", y, h);
        y = h;
    }

    /* Grab sampled the data set */
    data = anqfits_readpix(infits, 0,
                           x-SAMPLE_SIZE/2, x+SAMPLE_SIZE/2,
                           y-SAMPLE_SIZE/2, y+SAMPLE_SIZE/2,
                           0, PTYPE_DOUBLE,
                           sdata, &w, &h);
    anqfits_close(infits);

    /* Find row and column of data with the maximum intensity */
    for (i = 0; i < h; i++) {
        int c = 0;
        double m = calculate_max(data+w*i, w, &c);
        if (max < m) {
            max = m;
            maxrow = i;
            maxcolumn = c;
        }
    }

    /* Horizontal FWHM */
    for (i = 0; i < w; i++)
        ldata[i] = sdata[w*maxrow+i];
    hfwhm = calculate_fwhm(ldata, w);

    /* Vertical FWHM */
    for (i = 0; i < w; i++)
        ldata[i] = sdata[i*w+maxcolumn];
    vfwhm = calculate_fwhm(ldata, w);

    printf("Vertical FWHM   : %.2f\n", vfwhm);
    printf("Horizontal FWHM : %.2f\n", hfwhm);

    return 0;
}
