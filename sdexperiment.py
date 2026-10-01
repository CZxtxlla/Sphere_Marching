import numpy as np
import matplotlib.pyplot as plt
import time

height = 720
width = 1280

def mix(x, y, a):
    return x * (1.0 - a) + y * a

def smoothstep(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

def sdCircle(point, radius):
    return np.linalg.norm(point, axis=-1) - radius

def sdSegment(point, a, b, radius):
    a = np.array(a)
    b = np.array(b)
    
    pa = point - a
    ba = b - a

    dot_pa_ba = np.sum(pa * ba, axis=-1)
    dot_ba_ba = np.dot(ba, ba)
    
    h = np.clip(dot_pa_ba / dot_ba_ba, 0.0, 1.0)
    
    return np.linalg.norm(pa - h[..., np.newaxis] * ba, axis=-1) - radius

def getSD(points):
    # Calculate both distance fields
    d_circle = sdCircle(points, 0.5)
    
    # A line segment from bottom-left to top-right, with a thickness (radius) of 0.05
    d_segment = sdSegment(points, [-0.8, -0.6], [0.8, 0.6], 0.05)
    
    return np.minimum(d_circle, d_segment)

def render():
    image = np.zeros((height, width, 3)) #image array
    for i in range(height):
        print('{:.1f}'.format((i/height)*100)) #prints progress
        for j in range(width):
            u = (2.0 * j - width) / height
            v = (2.0 * i - height) / height
            point = np.array([u, v])
            d = sdCircle(point, 0.5)
            pixel_colour = np.array([0.9, 0.6, 0.3]) if (d > 0.0) else np.array([0.65, 0.85, 1])
            pixel_colour *= 1.0 - np.exp(-6.0 * abs(d))
            pixel_colour *= 0.8 + 0.2 * np.cos(150.0 * d)
            pixel_colour = mix(pixel_colour, 1.0, 1.0-smoothstep(0.0, 0.01, abs(d)))

            image[i, j] = pixel_colour
    print('100.0')
    return image

def render_vectorized():
    j = np.arange(width)
    i = np.arange(height)

    u = (2.0 * j - width) / height
    v = (2.0 * i - height) / height

    U, V = np.meshgrid(u, v)

    points = np.stack([U, V], axis = -1)


    d = getSD(points)

    d_ext = d[:, :, np.newaxis]
    
    image = np.zeros((height, width, 3))
    image[d > 0.0] = [0.9, 0.6, 0.3]  
    image[d <= 0.0] = [0.65, 0.85, 1.0] 
    
    image *= 1.0 - np.exp(-6.0 * np.abs(d_ext))
    image *= 0.8 + 0.2 * np.cos(150.0 * d_ext)
    
    outline_weight = 1.0 - smoothstep(0.0, 0.01, np.abs(d_ext))
    image = mix(image, 1.0, outline_weight)

    return np.clip(image, 0.0, 1.0)



time_limit = 100 #time limit for rendering in seconds
start = time.time()

rend = render_vectorized()

print('Time elapsed:', (time.time()-start), 'seconds')
plt.imsave('Final.png', rend) #saves final image