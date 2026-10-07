#include "render.h"
#include "utils.cuh"

#define MAX_STEPS 300
#define MAX_DIST 1000.0f
#define SURF_DIST 0.01f

// output
uint32_t* d_pixels = NULL;

// KERNELS

// helper for repeated domain
__device__ float3 repeatXZ(float3 p, float2 s) {
    float3 q = p;
    q.x = modulo(p.x + 0.5f * s.x, s.x) - 0.5f * s.x;
    q.z = modulo(p.z + 0.5f * s.y, s.y) - 0.5f * s.y;
    return q;
}

__device__ float sdSphere(float3 point, float radius) {
    return length(point) - radius;
}

__device__ float sdBox(float3 point, float3 b) {
    float3 d = abs(point) - b;
    return length(max(d, 0.0f)) + fminf(fmaxf(d.x, fmaxf(d.y, d.z)), 0.0f);
}

__device__ float sdFloor(float3 point) {
    float floor_height = -0.5f * sinf(point.x) * sinf(point.z) - 2.0f;
    float d = point.y - floor_height;

    return d * 0.7f;
}


// relates all the sds for the scene
__device__ ShapeData sdAll(float3 point, float time) {
    float2 spacing = make_float2(2.5f, 2.5f);
    float3 p_repeat = repeatXZ(point, spacing);

    // Sphere
    float3 sphere_center = make_float3(0.0f,  sinf(time)* 0.3f - 0.1f, 0.0f);
    float d_sphere = sdSphere(p_repeat - sphere_center, 0.25f);
    float3 colour_sphere = make_float3(0.9f, 0.1f, 0.2f);
    ShapeData sphere = {d_sphere, colour_sphere};

    // Box
    float3 box_center = make_float3(0.0f, -0.5f, 0.0f);
    float3 p_box = p_repeat - box_center;

    // inverse rotation
    float2 rotated_xz = rot2D(make_float2(p_box.x, p_box.z), -time);
    p_box.x = rotated_xz.x;
    p_box.z = rotated_xz.y;

    float d_box = sdBox(p_box, make_float3(0.5f, 0.2f, 0.5));
    float3 colour_box = make_float3(0.1f, 0.4f, 0.9f);
    ShapeData box = {d_box, colour_box};

    ShapeData box_sphere = smin_shape(box, sphere, 0.04f);
    ShapeData floor = {sdFloor(point), make_float3(0.5f, 0.5f, 0.5f)};

    return min_shape(box_sphere, floor);
}


// helpers for raymarching

__device__ ShapeData rayMarch(float3 ro, float3 rd, float time) {
    float d_0 = 0.0f;
    ShapeData d_s;

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 p = ro + rd * d_0;
        d_s = sdAll(p, time);
        d_0 += d_s.d * 0.75f;

        if (d_0 >= MAX_DIST || d_s.d < SURF_DIST) {
            break;
        }
    }
    if (d_s.d >= SURF_DIST) {
        d_0 = MAX_DIST;
    }
    d_s.d = d_0;
    return d_s;
}

// use finite differences to compute normal
__device__ float3 getNormal(float3 p, float time) {
    float eps = 0.0001f;

    float dx = sdAll(make_float3(p.x + eps, p.y, p.z), time).d - sdAll(make_float3(p.x - eps, p.y, p.z), time).d;
    float dy = sdAll(make_float3(p.x, p.y + eps, p.z), time).d - sdAll(make_float3(p.x, p.y - eps, p.z), time).d;
    float dz = sdAll(make_float3(p.x, p.y, p.z + eps), time).d - sdAll(make_float3(p.x, p.y, p.z - eps), time).d;

    float3 normal = make_float3(dx, dy, dz);
    return normalize(normal);
}

__device__ float soft_shadow(float3 ro, float3 rd, float mint, float maxt, float time, float k) {
    // raymarch to sun
    float res = 1.0f;
    float t = mint;
    for (int i = 0; i < 256 && t < maxt; i++) {
        float h = sdAll(ro + rd * t, time).d;
        if (h < 0.001) {
            return 0.0;
        }
        res = fminf(res, k * h / t);
        t += h * 0.75f;
    }
    return fmaxf(res, 0.0f);
}


// main rendering kernel
__global__ void render_kernel(uint32_t* pixels, int width, int height, float time, float cx, float cy, float cz) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float u = (2.0f * x - width) / height;
        float v = (2.0f * (height - y) - height) / height;
        
        float3 ro = make_float3(cx, cy, cz); // camera position (ray origin)

        float3 rd = make_float3(u, v, -1.0f); // initial direction of ray
        rd = normalize(rd);

        ShapeData result = rayMarch(ro, rd, time);

        int index = y*width + x;
        uint32_t colour = 0;

        if (result.d < MAX_DIST) {
            float3 hit_point = ro + rd * result.d;
            float3 normal = getNormal(hit_point, time);

            // light
            float3 light_dir = make_float3(1.5f, 0.8f, 0.3f); // direction
            light_dir = normalize(light_dir);

            float n_dot_l = dot(normal, light_dir);
            float diff = fmaxf(n_dot_l, 0.0f);

            float3 shadow_ro = hit_point + normal * 0.02f;

            float s = soft_shadow(shadow_ro, light_dir, 0.0f, 20.0f, time, 20.0f);
            
            float ambient_light = 0.10f;
            float intensity = ambient_light + (diff * s * 0.90f);

            uint8_t r = (uint8_t)(fminf(result.colour.x * intensity, 1.0f) * 255.0f);
            uint8_t g = (uint8_t)(fminf(result.colour.y * intensity, 1.0f) * 255.0f);
            uint8_t b = (uint8_t)(fminf(result.colour.z * intensity, 1.0f) * 255.0f);

            colour = (r << 24) | (g << 16) | (b << 8) | 255;
        } /* else {
            uint8_t r = (uint8_t)(135.0f);
            uint8_t g = (uint8_t)(206.0f);
            uint8_t b = (uint8_t)(235.0f);

            colour = (r << 24) | (g << 16) | (b << 8) | 255;
        }
        */

        pixels[index] = colour;
    }
}

// HOST FUNCTIONS
void init_renderer(int width, int height) {
    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMalloc(&d_pixels, memory_size);
}

void render_frame(uint32_t* h_pixels, int width, int height, float time, float cx, float cy, float cz) {
    if (!d_pixels) {
        return;
    }

    dim3 dimBlock(16, 16);
    dim3 dimGrid((width + dimBlock.x - 1) / dimBlock.x, (height + dimBlock.y - 1) / dimBlock.y);

    render_kernel<<<dimGrid, dimBlock>>>(d_pixels, width, height, time, cx, cy, cz);

    size_t memory_size = width * height * sizeof(uint32_t);
    cudaMemcpy(h_pixels, d_pixels, memory_size, cudaMemcpyDeviceToHost);
}

void cleanup_renderer() {
    if (d_pixels) {
        cudaFree(d_pixels);
        d_pixels = NULL;// 3D shapes
    }
}