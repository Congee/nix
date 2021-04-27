CC=cc
CFLAGS=
CXXFLAGS=
LD=
LDFLAGS=

target = main

all:
	$(CC) $(CFLAGS) %.c -o $(target)

.PHONY: clean

clean:
	rm -f *.o $(target)
