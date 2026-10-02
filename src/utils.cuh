#ifndef UTILS_H
#define UTILS_H

#include <cuda_runtime.h>

struct ShapeData {
    float d;
    float3 colour;
};

// overload operators
__device__ inline float2 operator+(float2 a, float2 b) { 
    return make_float2(a.x + b.x, a.y + b.y); 
}
__device__ inline float2 operator-(float2 a, float2 b) { 
    return make_float2(a.x - b.x, a.y - b.y); 
}
__device__ inline float2 operator*(float2 a, float s) {
    return make_float2(a.x * s, a.y * s);
}
__device__ inline float dot(float2 a, float2 b) {
    return a.x * b.x + a.y * b.y;
}
__device__ inline float length(float2 v) {
    return sqrtf(v.x * v.x + v.y * v.y);
}
__device__ inline float2 abs(float2 v) {
    return make_float2(fabsf(v.x), fabsf(v.y));
}
__device__ inline float2 max(float2 v, float m) {
    return make_float2(fmaxf(v.x, m), fmaxf(v.y, m));
}
__device__ inline float2 min(float2 v, float m) {
    return make_float2(fminf(v.x, m), fminf(v.y, m));
}

// cubic polynomial
__device__ inline float smin(float a, float b, float k) {
    k *= 6.0f;
    float h = fmaxf(k - abs(a - b), 0.0f) / k;
    return fminf(a, b) - h*h*h*k*(1.0f / 6.0f);
}

__device__ inline ShapeData smin_shape(float d1, float d2, float3 col1, float3 col2, float k) {
    float h = 1.0f - fminf(fabsf(d1 - d2) / (6.0f * k), 1.0);
    float w = h*h*h;
    float m = w*0.5f;
    float s = w*k;

    float mix_d = (d1 < d2) ? d1 - s : d2 - s;
    float mix_factor = (d1 < d2) ? m : (1.0f - m);

    float3 mix_colour = make_float3(col1.x + (col2.x - col1.x) * mix_factor, col1.y + (col2.y - col1.y) * mix_factor, col1.z + (col2.z - col1.z) * mix_factor);

    ShapeData result = {mix_d, mix_colour};
    return result;
}

#endif