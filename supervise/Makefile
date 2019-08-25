CFLAGS=-g -O3 -DNDEBUG -std=gnu11
CC=gcc

all : supervise

supervise : supervise.c
	${CC} ${CFLAGS} supervise.c -o supervise
	mkdir -p _target_
	mv -f supervise _target_/

clean:
	rm -rf _target_/

.PHONY : all
