#include "render.h"
#include "utils.cuh"

uint32_t* d_pixels = NULL;

// KERNELS
__device__ float sdCircle(float2 point, float radius) {
    return length(point) - radius;
}

__device__ float sdBox(float2 point, float2 b) {
    float2 d = abs(point) - b;
    return length(max(d, 0.0)) + fminf(fmaxf(d.x, d.y), 0.0f);
}

// relates all the sds for the scene
__device__ ShapeData sdAll(float2 point, float time) {
    float2 circle_center = make_float2(sinf(time)* 0.8f, 0.4f);
    float d_circle = sdCircle(point - circle_center, 0.25f);
    float3 colour_circle = make_float3(0.9f, 0.1f, 0.2f);

    float d_box = sdBox(point, make_float2(0.4f, 0.25f));
    float3 colour_box = make_float3(0.1f, 0.4f, 0.9f);

    return smin_shape(d_box, d_circle, colour_box, colour_circle, 0.04f);
}

__global__ void render_kernel(uint32_t* pixels, int width, int height, float time) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float u = (2.0f * x - width) / height;
        float v = (2.0f * (height - y) - height) / height;
        float2 point = make_float2(u, v);

        ShapeData result = sdAll(point, time);

        int index = y*width + x;
        uint32_t colour = 0;

        if (result.d <= 0.0f) {
            uint8_t r = (uint8_t)(result.colour.x * 255.0f);
            uint8_t g = (uint8_t)(result.colour.y * 255.0f);
            uint8_t b = (uint8_t)(result.colour.z * 255.0f);

            colour = (r << 24) | (g << 16) | (b << 8) | 255;
        }

        pixels[index] = colour;
    }
}

// HOST FUNCTIONS
void init_renderer(int width, int height) {
    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMalloc(&d_pixels, memory_size);
}

void render_frame(uint32_t* h_pixels, int width, int height, float time) {
    if (!d_pixels) {
        return;
    }

    dim3 dimBlock(16, 16);
    dim3 dimGrid((width + dimBlock.x - 1) / dimBlock.x, (height + dimBlock.y - 1) / dimBlock.y);

    render_kernel<<<dimGrid, dimBlock>>>(d_pixels, width, height, time);

    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMemcpy(h_pixels, d_pixels, memory_size, cudaMemcpyDeviceToHost);
}

void cleanup_renderer() {
    if (d_pixels) {
        cudaFree(d_pixels);
        d_pixels = NULL;
    }
}