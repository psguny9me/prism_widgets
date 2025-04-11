#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uLightDirection;
// uniform sampler2D uImageSampler; // REMOVED - No longer samples base image

// Output color
out vec4 fragColor;

// Simple pseudo-random number generator
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Simple rainbow color generation
vec3 rainbow(float value) {
    float hue = fract(value);
    float saturation = 0.8;
    float lightness = 0.6;
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

// Simulate a surface normal
vec3 calculateSurfaceNormal(vec2 uv) {
    float wave = sin(uv.x * 20.0 + uTime * 0.5) * 0.01 + cos(uv.y * 15.0 + uTime * 0.3) * 0.01;
    return normalize(vec3(cos(wave * 3.14), sin(wave * 3.14), 1.0));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 normal = calculateSurfaceNormal(uv);
    vec3 lightDir = normalize(uLightDirection);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);

    // --- Prism Effect Calculation ---
    vec3 reflectDir = reflect(-lightDir, normal);
    float prismValue = atan(reflectDir.y, reflectDir.x) / (2.0 * 3.14159) + length(uv - 0.5) * 0.5;
    prismValue += uTime * 0.1;
    vec3 prismColor = rainbow(prismValue);

    // Calculate prism intensity based on reflection angle
    float prismIntensity = pow(max(dot(viewDir, reflectDir), 0.0), 16.0);
    prismIntensity = mix(0.0, 0.8, prismIntensity); // Start from 0 intensity
    prismIntensity *= (smoothstep(0.0, 0.5, length(uv * 2.0 - 1.0))); // Fade near edges

    // --- Specular Highlight (Optional, can add subtle glint) ---
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float specAngle = max(dot(normal, halfwayDir), 0.0);
    float shininess = 128.0;
    float specularIntensity = pow(specAngle, shininess) * 0.5; // Reduce intensity

    // --- Final Color for Coating ---
    // The color is the prism color, potentially boosted by specular
    vec3 finalColor = prismColor + vec3(1.0) * specularIntensity;
    
    // The alpha is determined by the prism intensity
    // This makes the coating transparent where the prism effect is weak
    float finalAlpha = prismIntensity;

    // Apply premultiplied alpha
    fragColor = vec4(finalColor * finalAlpha, finalAlpha);
} 