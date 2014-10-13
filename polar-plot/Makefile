ASTROMETRY := /usr/local/astrometry

CFLAGS = -Wall -Wextra -I$(ASTROMETRY)/include
LDFLAGS = -L$(ASTROMETRY)/lib
LDLIBS = -lastrometry -lanbase -lanutils -lpthread -lm -lgsl -lgslcblas -lwcs

polar-plot: polar-plot.o

clean:
	rm -rf polar-plot polar-plot.o
