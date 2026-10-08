#ifndef RENDER_H
#define RENDER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void init_renderer(int width, int height);

void render_frame(uint32_t* h_pixels, int width, int height, float time, float cx, float cy, float cz, float pitch, float yaw);

void cleanup_renderer();

#ifdef __cplusplus
}
#endif


#endif