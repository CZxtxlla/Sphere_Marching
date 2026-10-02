#include <SDL3/SDL.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include "render.h"
#include <stdlib.h>

#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 720


int main() {

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return -1;
    }

    SDL_Window* window = NULL;
    SDL_Renderer* renderer = NULL;

    if (!SDL_CreateWindowAndRenderer("RayMarcher", WINDOW_WIDTH, WINDOW_HEIGHT, 0, &window, &renderer)) {
        fprintf(stderr, "window and renderer creation failed: %s\n", SDL_GetError());
        return -1;
    }

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT);
    if (!texture) {
        fprintf(stderr, "problem creating texture: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    size_t memory_size = WINDOW_WIDTH * WINDOW_WIDTH * sizeof(uint32_t);
    uint32_t* h_pixels = (uint32_t*)malloc(memory_size);
    init_renderer(WINDOW_WIDTH, WINDOW_HEIGHT);
    

    bool is_running = true;
    SDL_Event event;

    // main loop
    while (is_running) {

        // input handling
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT || (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE)) {
                is_running = false;
            }
        }

        // rendering
        render_frame(h_pixels, WINDOW_WIDTH, WINDOW_HEIGHT);

        SDL_UpdateTexture(texture, NULL, h_pixels, WINDOW_WIDTH * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderTexture(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    cleanup_renderer();
    free(h_pixels);

    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}