ASTROMETRY := /usr/local/astrometry

TARGET = star-analyze
CFLAGS = -Wall -Wextra -I$(ASTROMETRY)/include
LDFLAGS = -L$(ASTROMETRY)/lib
LDLIBS = -lastrometry -lanbase -lanutils -lpthread -lm -lwcs

$(TARGET): $(TARGET).o

clean:
	rm -rf $(TARGET) $(TARGET).o
