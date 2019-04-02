PROGRAMS = euron
CC = gcc
CFLAGS = -Wall -O2 -g -no-pie -pthread

all: $(PROGRAMS)

err.o: err.c err.h

euron: euronmain.c euron.o err.o
	gcc -DN=2 $(CFLAGS) -o euron euronmain.c euron.o err.o

%.o: %.asm
	nasm -DN=2 -f elf64 -F dwarf -g $<

.PHONY: all clean

clean:
	rm -rf $(PROGRAMS) *.o