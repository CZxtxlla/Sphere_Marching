CC = gcc
NVCC = nvcc

# Flags
SDL_CFLAGS = $(shell pkg-config --cflags sdl3)
SDL_LDFLAGS = $(shell pkg-config --libs sdl3 | sed 's/-Wl,/-Xlinker /g')

CFLAGS = -Wall -O3 $(SDL_CFLAGS)
NVCCFLAGS = -O3 -use_fast_math

TARGET = main

C_SOURCES = main.c
CU_SOURCES = render.cu

C_OBJECTS = $(C_SOURCES:.c=.o)
CU_OBJECTS = $(CU_SOURCES:.cu=.o)

all: $(TARGET)

$(TARGET): $(C_OBJECTS) $(CU_OBJECTS)
	$(NVCC) $(C_OBJECTS) $(CU_OBJECTS) -o $(TARGET) $(SDL_LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cu
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

clean:
	rm -f *.o
	rm -f $(TARGET)