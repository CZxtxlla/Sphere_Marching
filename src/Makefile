CC = gcc

SDL3 = $(shell brew --prefix sdl3)

CFLAGS = -I$(SDL3)/include
LDFLAGS = -L$(SDL3)/lib -Wl,-rpath,$(SDL3)/lib
LDLIBS = -lSDL3

TARGET = main
SRC = main.c

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) $(LDFLAGS) $(LDLIBS) -o $(TARGET)

clean:
	rm -f $(TARGET)