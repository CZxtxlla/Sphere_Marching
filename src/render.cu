#include "render.h"
#include "utils.cuh"

uint32_t* d_pixels = NULL;

// KERNELS
__device__ float sdCircle(float2 point, float radius) {
    return length(point) - radius;
}


__global__ void render_kernel(uint32_t* pixels, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float u = (2.0f * x - width) / height;
        float v = (2.0f * (height - y) - height) / height;
        float2 point = make_float2(u, v);

        float d = sdCircle(point, 0.5f);

        int index = y*width + x;
        uint32_t colour = 0;

        uint8_t r = (uint8_t)((x / (float)width) * 255);
        uint8_t g = (uint8_t)((y / (float)height) * 255);

        if (d < 0) {
            colour = (r << 24) | (g << 16) | (150 << 8) | 255;
        }

        pixels[index] = colour;
    }
}



// HOST FUNCTIONS


void init_renderer(int width, int height) {
    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMalloc(&d_pixels, memory_size);
}

void render_frame(uint32_t* h_pixels, int width, int height) {
    if (!d_pixels) {
        return;
    }

    dim3 dimBlock(16, 16);
    dim3 dimGrid((width + dimBlock.x - 1) / dimBlock.x, (height + dimBlock.y - 1) / dimBlock.y);

    render_kernel<<<dimGrid, dimBlock>>>(d_pixels, width, height);

    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMemcpy(h_pixels, d_pixels, memory_size, cudaMemcpyDeviceToHost);
}

void cleanup_renderer() {
    if (d_pixels) {
        cudaFree(d_pixels);
        d_pixels = NULL;
    }
}