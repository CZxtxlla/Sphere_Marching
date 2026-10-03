#include "render.h"
#include "utils.cuh"

#define MAX_STEPS 100
#define MAX_DIST 1000.0f
#define SURF_DIST 0.01f

uint32_t* d_pixels = NULL;

// KERNELS

// 2D Shapes
__device__ float sdCircle(float2 point, float radius) {
    return length(point) - radius;
}

__device__ float sdBox(float2 point, float2 b) {
    float2 d = abs(point) - b;
    return length(max(d, 0.0f)) + fminf(fmaxf(d.x, d.y), 0.0f);
}

// 3D shapes
__device__ float sdSphere(float3 point, float radius) {
    return length(point) - radius;
}

__device__ float sdBox(float3 point, float3 b) {
    float3 d = abs(point) - b;
    return length(max(d, 0.0f)) + fminf(fmaxf(d.x, fmaxf(d.y, d.z)), 0.0f);
}


// relates all the sds for the scene
__device__ ShapeData sdAll(float2 point, float time) {
    float2 circle_center = make_float2(0.0f, sinf(time)* 0.3f);
    float d_circle = sdCircle(point - circle_center, 0.25f);
    float3 colour_circle = make_float3(0.9f, 0.1f, 0.2f);

    float2 box_center = make_float2(0.0f, -0.6f);
    float d_box = sdBox(point - box_center, make_float2(2.0f, 0.5f));
    float3 colour_box = make_float3(0.1f, 0.4f, 0.9f);

    return smin_shape(d_box, d_circle, colour_box, colour_circle, 0.04f);
}

__device__ ShapeData sdAll(float3 point, float time) {
    float3 sphere_center = make_float3(0.0f,  sinf(time)* 0.3f - 0.1f, -1.0f);
    float d_sphere = sdSphere(point - sphere_center, 0.25f);
    float3 colour_sphere = make_float3(0.9f, 0.1f, 0.2f);

    float3 box_center = make_float3(0.0f, -0.5f, -1.0f);
    float d_box = sdBox(point - box_center, make_float3(0.5f, 0.2f, 0.5));
    float3 colour_box = make_float3(0.1f, 0.4f, 0.9f);

    return smin_shape(d_box, d_sphere, colour_box, colour_sphere, 0.04f);
}


// helpers for raymarching

__device__ ShapeData rayMarch(float3 ro, float3 rd, float time) {
    float d_0 = 0.0f;
    ShapeData d_s;

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 p = ro + rd * d_0;
        d_s = sdAll(p, time);
        d_0 += d_s.d;

        if (d_0 >= MAX_DIST || d_s.d < SURF_DIST) {
            break;
        }
    }
    d_s.d = d_0;
    return d_s;
}


// main rendering kernel
__global__ void render_kernel(uint32_t* pixels, int width, int height, float time) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float u = (2.0f * x - width) / height;
        float v = (2.0f * (height - y) - height) / height;
        
        float3 ro = make_float3(0.0f, 0.0f, 0.0f); // camera position (ray origin)

        float3 rd = make_float3(u, v, -1.0f); // initial direction of ray
        rd = rd * (1 / length(rd)); // normalize

        ShapeData result = rayMarch(ro, rd, time);

        int index = y*width + x;
        uint32_t colour = 0;

        if (result.d < MAX_DIST) {
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