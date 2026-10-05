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

    if (!SDL_CreateWindowAndRenderer("RayMarcher", WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        fprintf(stderr, "window and renderer creation failed: %s\n", SDL_GetError());
        return -1;
    }

    SDL_SetRenderVSync(renderer, 0);

    SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
    SDL_ShowWindow(window);

    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT);
    if (!texture) {
        fprintf(stderr, "problem creating texture: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    SDL_SetRenderLogicalPresentation(renderer, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);

    size_t memory_size = WINDOW_WIDTH * WINDOW_WIDTH * sizeof(uint32_t);
    uint32_t* h_pixels = (uint32_t*)malloc(memory_size);
    init_renderer(WINDOW_WIDTH, WINDOW_HEIGHT);
    

    bool is_running = true;
    SDL_Event event;

    // info
    uint64_t last_fps_time = SDL_GetTicks();
    uint64_t last_frame_time = SDL_GetTicks();
    int frame_count = 0;
    char title_buffer[128];

    float cam_x = 0.0f;
    float cam_y = 0.0f;
    float cam_z = 0.0f;

    // main loop
    while (is_running) {
        uint64_t current_time = SDL_GetTicks();
        float delta_time = (current_time - last_frame_time) / 1000.0f;
        last_frame_time = current_time;

        frame_count++;
        uint64_t elapsed_fps_time = current_time - last_fps_time;

        if (elapsed_fps_time > 1000) {
            float fps = frame_count / (elapsed_fps_time / 1000.0f);
            float frame_time_ms = (float) elapsed_fps_time / frame_count;

            snprintf(title_buffer, sizeof(title_buffer), "Sphere Marcher | %.1f FPS | %.2f ms", fps, frame_time_ms); 
            SDL_SetWindowTitle(window, title_buffer);

            last_fps_time = current_time;
            frame_count = 0;
        }

        // input handling
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT || (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE)) {
                is_running = false;
            }
        }

        const bool* keys = SDL_GetKeyboardState(NULL);

        float move_speed = 3.0f * delta_time;
        if (keys[SDL_SCANCODE_W]) cam_z -= move_speed;
        if (keys[SDL_SCANCODE_S]) cam_z += move_speed;
        if (keys[SDL_SCANCODE_A]) cam_x -= move_speed;
        if (keys[SDL_SCANCODE_D]) cam_x += move_speed;
        if (keys[SDL_SCANCODE_SPACE]) cam_y += move_speed;
        if (keys[SDL_SCANCODE_LSHIFT]) cam_y -= move_speed;

        // rendering
        float render_time = current_time / 1000.0f;
        render_frame(h_pixels, WINDOW_WIDTH, WINDOW_HEIGHT, render_time, cam_x, cam_y, cam_z);

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