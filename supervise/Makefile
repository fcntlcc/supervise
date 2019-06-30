CFLAGS=-g -O3 -std=gnu99 -DNDEBUG
CC=gcc

all : supervise

supervise : supervise.c
	${CC} ${CFLAGS} supervise.c -o supervise -lrt
	mkdir -p _target_
	mv -f supervise _target_/

clean:
	rm -rf _target_/

.PHONY : all
