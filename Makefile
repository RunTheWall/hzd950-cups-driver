CC      ?= cc
CFLAGS  ?= -O2 -Wall
LIBS    := -lcupsimage -lcups -lm

all: src/rastertohzd

src/rastertohzd: src/rastertohzd.c
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f src/rastertohzd

.PHONY: all clean
