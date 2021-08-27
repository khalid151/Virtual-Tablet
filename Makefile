export CC=gcc
export CFLAGS=-g -Wall
export GFX=main.c
export SERVER=virtual_tablet

all: server
all: client

.PHONY: client server

client:
	$(MAKE) -C client

server:
	$(MAKE) -C server

clean:
	$(MAKE) -C client clean
	$(MAKE) -C server clean

memcheck:
	$(MAKE) -C server memcheck
