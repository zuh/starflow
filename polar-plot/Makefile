ASTROMETRY := /usr/local/astrometry

CFLAGS = -Wall -Wextra -I$(ASTROMETRY)/include
LDFLAGS = -L$(ASTROMETRY)/lib
LDLIBS = -lanbase -lanutils -lqfits -lpthread -lm -lgsl -lgslcblas -lwcs

polar-plot: polar-plot.o
