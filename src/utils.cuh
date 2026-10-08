#ifndef UTILS_H
#define UTILS_H

#include <cuda_runtime.h>

struct ShapeData {
    float d;
    float3 colour;
};

// vector operations 2D
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

// vector operations 3D
__device__ inline float3 operator+(float3 a, float3 b) { 
    return make_float3(a.x + b.x, a.y + b.y, a.z + b.z); 
}
__device__ inline float3 operator-(float3 a, float3 b) { 
    return make_float3(a.x - b.x, a.y - b.y, a.z - b.z); 
}
__device__ inline float3 operator*(float3 a, float s) {
    return make_float3(a.x * s, a.y * s, a.z * s);
}
__device__ inline float dot(float3 a, float3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}
__device__ inline float length(float3 v) {
    return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
}
__device__ inline float3 abs(float3 v) {
    return make_float3(fabsf(v.x), fabsf(v.y), fabsf(v.z));
}
__device__ inline float3 max(float3 v, float m) {
    return make_float3(fmaxf(v.x, m), fmaxf(v.y, m), fmaxf(v.z, m));
}
__device__ inline float3 min(float3 v, float m) {
    return make_float3(fminf(v.x, m), fminf(v.y, m), fminf(v.z, m));
}
__device__ inline float3 normalize(float3 v) {
    float l = length(v);
    return make_float3(v.x / l, v.y / l, v.z / l);
}



// extra functions
__device__ inline float3 mix(float3 a, float3 b, float t) {
    return make_float3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);
}

// cubic polynomial
__device__ inline float smin(float a, float b, float k) {
    k *= 6.0f;
    float h = fmaxf(k - abs(a - b), 0.0f) / k;
    return fminf(a, b) - h*h*h*k*(1.0f / 6.0f);
}

__device__ inline ShapeData smin_shape(ShapeData a, ShapeData b, float k) {
    float h = 1.0f - fminf(fabsf(a.d - b.d) / (6.0f * k), 1.0);
    float w = h*h*h;
    float m = w*0.5f;
    float s = w*k;

    float mix_d = (a.d < b.d) ? a.d - s : b.d - s;
    float mix_factor = (a.d < b.d) ? m : (1.0f - m);

    float3 mix_colour = mix(a.colour, b.colour, mix_factor);

    ShapeData result = {mix_d, mix_colour};
    return result;
}

__device__ inline ShapeData smax_shape(ShapeData a, ShapeData b, float k) {
    float h = 1.0f - fminf(fabsf(a.d - b.d) / (6.0f * k), 1.0);
    float w = h*h*h;
    float m = w*0.5f;
    float s = w*k;

    float mix_d = (a.d < b.d) ? b.d - s : a.d - s;
    float mix_factor = (b.d < a.d) ? m : (1.0f - m);

    float3 mix_colour = mix(a.colour, b.colour, mix_factor);

    ShapeData result = {mix_d, mix_colour};
    return result;
}

__device__ inline ShapeData min_shape(ShapeData a, ShapeData b) {
    if (a.d < b.d) {
        return a;
    } else {
        return b;
    }
}

__device__ inline ShapeData max_shape(ShapeData a, ShapeData b) {
    if (a.d > b.d) {
        return a;
    } else {
        return b;
    }
}

__device__ inline ShapeData subtract_shape(ShapeData base, ShapeData sub, float k) {
    float a = base.d;
    float b = -sub.d;

    k *= 6.0f;
    float h = fmaxf(k - abs(a - b), 0.0f) / k;
    float result_d = fmaxf(a, b) + h*h*h*k*(1.0f / 6.0f);

    ShapeData result = {result_d, base.colour};
    return result;
}

__device__ inline float modulo(float x, float y) {
    return x - (y * floorf(x / y));
}

__device__ inline float2 rot2D(float2 p, float a) {
    float s = sinf(a);
    float c = cosf(a);
    return make_float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

#endif