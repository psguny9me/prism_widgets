#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;

// Output color
out vec4 fragColor;

// Pseudo-random number generator
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Noise function (can use simplex noise for better results if available)
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f * f * (3.0 - 2.0 * f); // Smoothstep curve

    return mix(mix(random(i + vec2(0.0, 0.0)), random(i + vec2(1.0, 0.0)), u.x),
               mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Smooth pulsing function (0 -> 1 -> 0)
float pulse(float time, float frequency, float offset) {
    float val = sin((time + offset) * 3.14159 * frequency) * 0.5 + 0.5;
    return val * val; // Square to make the peak sharper and fade faster
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 originalUV = uv;

    // --- Sparkle Grid & Jitter ---
    // Define a grid cell size (smaller value = more potential sparkles)
    float gridCellSize = 0.03; // Adjust for density
    vec2 gridUV = uv / gridCellSize;
    vec2 gridID = floor(gridUV);
    vec2 gridFract = fract(gridUV);

    // Generate a unique random offset for each grid cell
    float cellRand = random(gridID);

    // Only create a sparkle in some grid cells
    // Adjust threshold (e.g., 0.85) to control density
    if (cellRand < 0.85) {
        fragColor = vec4(0.0); // No sparkle in this cell
        return;
    }

    // Add jitter to the sparkle position within the cell
    vec2 jitterOffset = vec2(random(gridID + 0.1) - 0.5, random(gridID + 0.2) - 0.5) * 0.8;
    vec2 sparkleCenterUV = (gridID + 0.5 + jitterOffset) * gridCellSize;

    // --- Sparkle Appearance ---
    float dist = distance(uv, sparkleCenterUV);

    // Base sparkle size (smaller radius = smaller sparkles)
    float sparkleRadius = gridCellSize * (0.1 + random(gridID + 0.3) * 0.2); // Vary size

    // Calculate intensity based on distance (falloff)
    float intensity = smoothstep(sparkleRadius, sparkleRadius * 0.3, dist);

    // --- Twinkling Animation ---
    // Give each sparkle a unique time offset and frequency for twinkling
    float timeOffset = random(gridID + 0.4) * 10.0;
    float twinkleFrequency = 0.5 + random(gridID + 0.5) * 1.5; // Vary speed

    // Apply pulsing brightness
    float brightness = pulse(uTime, twinkleFrequency, timeOffset);
    brightness = smoothstep(0.1, 0.6, brightness); // Make the pulse more distinct

    intensity *= brightness;

    // --- Final Color ---
    // Base color (mostly white with slight yellow tint)
    vec3 sparkleColor = vec3(1.0, 1.0, 0.85);

    // Optional: Add subtle color shift based on position or time
    // sparkleColor.g *= (0.8 + 0.2 * sin(uTime + gridID.x * 0.5));

    // Calculate final color with alpha
    fragColor = vec4(sparkleColor * intensity, intensity);
} 