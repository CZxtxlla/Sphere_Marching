#ifndef UTILS_H
#define UTILS_H

#include <cuda_runtime.h>

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
    return make_float2(abs(v.x), abs(v.y));
}
__device__ inline float2 max(float2 v, float m) {
    return make_float2(max(v.x, m), max(v.y, m));
}
// cubic polynomial
__device__ inline float smin(float a, float b, float k) {
    k *= 6.0f;
    float h = max(k - abs(a - b), 0.0f) / k;
    return min(a, b) - h*h*h*k*(1.0f / 6.0f);
} 


#endif