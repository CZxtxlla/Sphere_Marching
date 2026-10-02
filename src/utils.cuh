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


#endif