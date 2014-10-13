/*
 * Adapted from bits and pieces in https://code.google.com/p/eq-polar-alignment/
 * Could not find copyright statement from there, but license seems to be GPLv3...
 *
 * Copyright 2014, Kalle Vahlman, zuh@iki.fi
 * Licensed under the GNU GPL v3
 *
 */

#include <stdio.h>
#include <time.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_multiroots.h>
#include <astrometry/anwcs.h>
#include <astrometry/sip.h>
#include <astrometry/sip_qfits.h>

struct coord
{
    double ra;
    double dec;
    double x;
    double y;
};

struct state
{
    anwcs_t* h_wcs;
    anwcs_t* v_wcs;
    double pixel_scale;
    struct coord ncp;
    struct coord polaris;
    struct coord lambda;
    struct coord axis;

};

double julian_date()
{
    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    int day = t->tm_mday;
    int month = t->tm_mon+1;
    int year = 1900 + t->tm_year;

    return 367*year-7*(year+(month+9)/12)/4-3*((year+(month-9)/7)/100+1)/4+275*month/9+day+1721029;
}

int calculate_ncp (double julian, struct coord *c)
{
    double t, zeta, theta;
    if (c == NULL)
        return 0;

    t = (julian-2451545)/36525;
    zeta = (2306.2181*t+0.30188*t*t+0.017998*t*t*t)/3600;
    theta = (2004.3109*t-0.42665*t*t-0.041833*t*t*t)/3600;
    c->dec = 90 - theta;
    c->ra = -zeta;

    return 1;
}

int solve_field(struct state *ps, const char *dir, const char *in, const char *out)
{
    char run[512];
    // TODO: Run the solving with code rather than system()
#define SOLVE "solve-field -B none -M none -S none -R none -U none -N none " \
              "--no-plots --temp-dir %s --dir %s --out %s " \
              "--downsample 2 --ra %.4f --dec %.4f --radius 10 %s"
    sprintf(run, SOLVE, dir, dir, out, ps->ncp.ra, ps->ncp.dec, in);
    printf("%s\n", run);
    return system(run);
}

int fvec(const gsl_vector *x, void *params, gsl_vector *f)
{
    struct state *s = (struct state *)params;
    double ra, dec, xp, yp;
    double xi = gsl_vector_get(x, 0);
    double yi = gsl_vector_get(x, 1);

    anwcs_pixelxy2radec(s->h_wcs, xi, yi, &ra, &dec);
    anwcs_radec2pixelxy(s->v_wcs, ra, dec, &xp, &yp);
    xp = xp - xi;
    yp = yp - yi;
    gsl_vector_set(f, 0, xp);
    gsl_vector_set(f, 1, yp);

    return GSL_SUCCESS;
}

int solve_axis(struct state *ps)
{
    int s;
    size_t iter=0;
    const size_t n=2;
    gsl_multiroot_fsolver *solver;
    gsl_multiroot_function f = { &fvec, n, ps};
    gsl_vector *x = gsl_vector_alloc(n);

    gsl_vector_set(x, 0, ps->polaris.x);
    gsl_vector_set(x, 1, ps->polaris.y);
    solver = gsl_multiroot_fsolver_alloc(gsl_multiroot_fsolver_hybrids, 2);
    gsl_multiroot_fsolver_set(solver, &f, x);
    do {
        iter++;
        s = gsl_multiroot_fsolver_iterate(solver);
        if (s) break;
        s = gsl_multiroot_test_residual(solver->f,1e-7);
    } while (s == GSL_CONTINUE && iter < 1000);
    ps->axis.x = gsl_vector_get(solver->x, 0);
    ps->axis.y = gsl_vector_get(solver->x, 1);

    gsl_multiroot_fsolver_free(solver);
    gsl_vector_free(x);
    return s;
}

#define MAX(a, b) a < b ? b : a

int plot(struct state *ps, char *in, char *out)
{
    char convert[2048];
    double arcmin = 60/ps->pixel_scale;
    double cropwidth = MAX(400, 120 * arcmin);
    double cropheight = MAX(400, 120 * arcmin);
    double cropx = ps->ncp.x - cropwidth/2;
    double cropy = ps->ncp.y - cropheight/2;
    int fontsize = ps->pixel_scale < 24 ? 16 : 8;

#define CONVERT "convert -fill none " \
    "-pointsize %d " \
    "-font Courier -stroke cyan " \
    "-draw 'point %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-stroke red " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-draw 'circle %.0f,%.0f %.0f,%.0f' " \
    "-stroke white " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-font Symbol -fill white " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-fill none " \
    "-stroke orange " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-draw 'line %.0f,%.0f %.0f,%.0f' " \
    "-font Symbol -fill orange " \
    "-draw \"text %.0f,%.0f '%s'\" " \
    "-fill none " \
    "-font Courier -stroke white -fill white " \
    "-draw \"text %.0f,%.0f 'Current pixel offset from NCP: %.0f, %.0f'\" " \
    "-draw \"text %.0f,%.0f '%s %s %s %s'\" " \
    "-crop '%.0fx%.0f+%.0f+%.0f' " \
    "%s %s"

    sprintf(convert, CONVERT, fontsize,
        // Target circles
        ps->ncp.x, ps->ncp.y,
        ps->ncp.x, ps->ncp.y, ps->ncp.x+2*arcmin, ps->ncp.y,
        ps->ncp.x, ps->ncp.y, ps->ncp.x+5*arcmin, ps->ncp.y,
        ps->ncp.x, ps->ncp.y, ps->ncp.x+10*arcmin, ps->ncp.y,
        ps->ncp.x, ps->ncp.y, ps->ncp.x+20*arcmin, ps->ncp.y,
        ps->ncp.x, ps->ncp.y, ps->ncp.x+40*arcmin, ps->ncp.y,
        ps->ncp.x-2*arcmin+2, ps->ncp.y, ps->pixel_scale < 24 ? "2\\'" : "",
        ps->ncp.x-5*arcmin+2, ps->ncp.y, ps->pixel_scale < 24 ? "5\\'" : "",
        ps->ncp.x-10*arcmin+2, ps->ncp.y, ps->pixel_scale < 24 ? "10\\'" : "",
        ps->ncp.x-20*arcmin+2, ps->ncp.y, "20\\'",
        ps->ncp.x-40*arcmin+2, ps->ncp.y, "40\\'",
        // Current axis
        ps->axis.x-5*arcmin, ps->axis.y-5*arcmin, ps->axis.x+5*arcmin, ps->axis.y+5*arcmin,
        ps->axis.x-5*arcmin, ps->axis.y+5*arcmin, ps->axis.x+5*arcmin, ps->axis.y-5*arcmin,
        ps->axis.x, ps->axis.y, ps->axis.x+2*arcmin, ps->axis.y,
        ps->axis.x, ps->axis.y, ps->axis.x+5*arcmin, ps->axis.y,
        // Polaris
        ps->polaris.x, ps->polaris.y-1*arcmin,
            ps->polaris.x, ps->polaris.y+1*arcmin,
        ps->polaris.x-1*arcmin, ps->polaris.y,
            ps->polaris.x+1*arcmin, ps->polaris.y,
        ps->polaris.x+1*arcmin, ps->polaris.y-1*arcmin, "a",
        // λ UMi
        ps->lambda.x, ps->lambda.y-1*arcmin,
            ps->lambda.x, ps->lambda.y+1*arcmin,
        ps->lambda.x-1*arcmin, ps->lambda.y,
            ps->lambda.x+1*arcmin, ps->lambda.y,
        ps->lambda.x+1*arcmin, ps->lambda.y-1*arcmin, "l",
        // Offset report
        cropx + 16, cropy + 32, ps->ncp.x-ps->axis.x, ps->ncp.y-ps->axis.y,
        cropx + 16, cropy + 64,
            (ps->ncp.x == ps->axis.x && ps->ncp.y == ps->axis.y)
                ? "Well done, perfect alignment!"
                : "Adjust mount alignment to",
            (ps->ncp.x == ps->axis.x && ps->ncp.y == ps->axis.y)
                ? ""
                : ps->ncp.x < ps->axis.x ? "left" : "right",
            (ps->ncp.x == ps->axis.x && ps->ncp.y == ps->axis.y) ? "" : "and",
            (ps->ncp.x == ps->axis.x && ps->ncp.y == ps->axis.y)
                ? ""
                : ps->ncp.y < ps->axis.y ? "up" : "down",
        // Crop
        cropwidth, cropheight, cropx, cropy,
        in, out);

    printf("%s\n", convert);
    return system(convert);
}

int main (int argc, char **argv)
{
    char dir[20] = "/tmp/polar-XXXXXX";
    char h_dst[30];
    char v_dst[30];
    sip_t *sip;
    struct state ps = { NULL, NULL, 0,
                      { 0, 0, 0, 0 }, // NCP
                      { 37.9529, 89.2642, 0, 0 }, // Polaris
                      { 259.2367, 89.0378, 0, 0 }, // λ UMi
                      { 0, 0, 0, 0 } // axis
                    };

    if (argc < 3) {
        printf("E: Not enough parameters!\n");
        printf("Usage: %s <horizontal image> <vertical image> [output]\n", argv[0]);
        return -1;
    }

    if (mkdtemp(dir) == NULL) {
        printf("E: Could not create working directory!\n");
        return -1;
    }

    // Calculate current ra,dec position of North Celestial Pole
    calculate_ncp(julian_date(), &ps.ncp);

    // Solve horizontal and vertical images of Polaris and Lambda UMi
    sprintf(h_dst, "%s/h.wcs", dir);
    sprintf(v_dst, "%s/v.wcs", dir);
    solve_field(&ps, dir, argv[1], "h.wcs");
    solve_field(&ps, dir, argv[2], "v.wcs");

    // Pick pixel coordinates from horizontal image
    ps.h_wcs = anwcs_open(h_dst, 0);
    anwcs_radec2pixelxy(ps.h_wcs, ps.polaris.ra, ps.polaris.dec, &ps.polaris.x, &ps.polaris.y);
    anwcs_radec2pixelxy(ps.h_wcs, ps.lambda.ra, ps.lambda.dec, &ps.lambda.x, &ps.lambda.y);
    anwcs_radec2pixelxy(ps.h_wcs, ps.ncp.ra, ps.ncp.dec, &ps.ncp.x, &ps.ncp.y);

    // Solve rotational axis in pixel coordinates of the horizontal image
    ps.v_wcs = anwcs_open(v_dst, 0);
    solve_axis(&ps);
    anwcs_pixelxy2radec(ps.h_wcs, ps.axis.x, ps.axis.y, &ps.axis.ra, &ps.axis.dec);
    anwcs_free(ps.v_wcs);

    // Grab pixel scale from horizontal image
    sip = anwcs_get_sip(ps.h_wcs);
    ps.pixel_scale = sip_pixel_scale(sip);
    anwcs_free(ps.h_wcs);

    // Print what we found
    printf("Pixel scale: %.4f\n", ps.pixel_scale);
    printf("Polaris: %+9.4f ra, %+9.4f dec (%4.0f, %4.0f)\n",
        ps.lambda.ra, ps.lambda.dec, ps.lambda.x, ps.lambda.y);
    printf("λ UMi  : %+9.4f ra, %+9.4f dec (%4.0f, %4.0f)\n",
        ps.polaris.ra, ps.polaris.dec, ps.polaris.x, ps.polaris.y);
    printf("NCP    : %+9.4f ra, %+9.4f dec (%4.0f, %4.0f)\n",
        ps.ncp.ra, ps.ncp.dec, ps.ncp.x, ps.ncp.y);
    printf("Axis   : %+9.4f ra, %+9.4f dec (%4.0f, %4.0f)\n",
        ps.axis.ra, ps.axis.dec, ps.axis.x, ps.axis.y);
    printf("Offset : %4.0f x, %4.0f y\n",
        ps.ncp.x-ps.axis.x, ps.ncp.y-ps.axis.y);

    // Plot a chart of the polar alignment, if user asks for it
    if (argc == 4)
        plot(&ps, argv[1], argv[3]);

    return 0;
}
