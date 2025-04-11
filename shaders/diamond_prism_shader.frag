#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uLightDirection;

// Output color
out vec4 fragColor;

// Simple rainbow color generation
vec3 rainbow(float value) {
    float hue = fract(value);
    float saturation = 0.9;
    float lightness = 0.65;
    float c = (1.0 - abs(2.0 * lightness - 1.0)) * saturation;
    float x = c * (1.0 - abs(mod(hue * 6.0, 2.0) - 1.0));
    float m = lightness - c / 2.0;
    vec3 rgb;
    if (hue < 1.0/6.0) rgb = vec3(c, x, 0.0);
    else if (hue < 2.0/6.0) rgb = vec3(x, c, 0.0);
    else if (hue < 3.0/6.0) rgb = vec3(0.0, c, x);
    else if (hue < 4.0/6.0) rgb = vec3(0.0, x, c);
    else if (hue < 5.0/6.0) rgb = vec3(x, 0.0, c);
    else rgb = vec3(c, 0.0, x);
    return rgb + m;
}

// Function to create thin lines - REMOVED as hairlines are removed
// float line(float value, float thickness) {
//     return smoothstep(thickness, thickness * 0.5, abs(value)); 
// }

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // --- Diamond Pattern Generation ---
    float scale = 15.0;
    vec2 scaledUV = (uv - 0.5) * scale;
    vec2 gridUV = fract(scaledUV) * 2.0 - 1.0;
    float diamondShape = abs(gridUV.x) + abs(gridUV.y);
    float diamondMask = 1.0 - smoothstep(0.85, 0.95, diamondShape);

    // --- Hairline Generation --- REMOVED
    // float lineThickness = 0.08;
    // float hLine = line(gridUV.y, lineThickness);
    // float vLine = line(gridUV.x, lineThickness);
    // float inset = 0.3;
    // float line1 = line(abs(gridUV.x) + abs(gridUV.y) - inset, lineThickness);
    // float hairlineFactor = max(hLine, vLine);
    // hairlineFactor = max(hairlineFactor, line1);
    // hairlineFactor *= diamondMask;
    
    // --- Prism Effect Calculation ---
    vec3 normal = normalize(vec3(uv.x - 0.5, uv.y - 0.5, 0.8)); 
    vec3 lightDir = normalize(uLightDirection);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float prismValue = atan(reflectDir.y, reflectDir.x) / (2.0 * 3.14159);
    vec2 gridID = floor(scaledUV);
    prismValue += uTime * 0.08 + fract(sin(dot(gridID.xy, vec2(12.9898, 78.233))) * 10.0) * 0.1;
    vec3 prismColor = rainbow(prismValue);

    // --- Final Color for MATERIAL --- 
    vec3 baseMaterialColor = vec3(0.3);
    vec3 diamondColor = prismColor * 0.8 + 0.2; 
    // vec3 hairlineColor = vec3(0.1); // REMOVED

    // Combine: Start with base material, overlay diamond color based on mask
    vec3 finalColor = mix(baseMaterialColor, diamondColor, diamondMask);
    // finalColor = mix(finalColor, hairlineColor, hairlineFactor); // REMOVED Hairline mixing

    // Clamp color
    finalColor = clamp(finalColor, 0.0, 1.0);

    // Output opaque material color
    fragColor = vec4(finalColor, 1.0);
} 