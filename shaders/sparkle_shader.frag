#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uLightDirection; // Assuming light direction is provided

// Output color
out vec4 fragColor;

// --- Noise Functions ---
// Simple pseudo-random number generator
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Value Noise (simple version)
float valueNoise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f * f * (3.0 - 2.0 * f); // Smoothstep

    return mix(mix(random(i + vec2(0.0, 0.0)), random(i + vec2(1.0, 0.0)), u.x),
               mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Fractal Brownian Motion (FBM) - combines multiple noise layers
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    int octaves = 4; // Number of noise layers

    for (int i = 0; i < octaves; i++) {
        value += amplitude * valueNoise(st);
        st *= 2.0; // Increase frequency
        amplitude *= 0.5; // Decrease amplitude
    }
    return value;
}

// --- Surface Normal Simulation (Simplified) ---
vec3 calculatePerturbedNormal(vec2 uv) {
    float noiseScale = 20.0; // Increase scale slightly for finer wrinkles
    float noiseStrength = 0.5; // Adjust strength of perturbation

    // Calculate a single noise value, animated slightly
    float noise = fbm(uv * noiseScale + uTime * 0.1);

    // Perturb the normal based on the noise value
    // This creates bumps/dents rather than using derivatives
    // We use noise directly and also offset slightly to get variation
    float noiseOffset = fbm(uv * noiseScale + vec2(10.0, 10.0) + uTime * 0.1);
    vec3 perturbedNormal = normalize(vec3(
        (noise - 0.5) * noiseStrength,          // Perturb x based on noise
        (noiseOffset - 0.5) * noiseStrength,    // Perturb y based on offset noise
        1.0                                     // Z remains primarily facing outwards
    ));

    return perturbedNormal;
}

// --- Main ---
void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec3 lightDir = normalize(uLightDirection);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);

    // Use the perturbed normal calculation again
    vec3 normal = calculatePerturbedNormal(uv); // <-- Re-enabled

    // --- Lighting Calculation ---
    vec3 reflectDir = reflect(-lightDir, normal);
    float specularPower = 48.0; // Increase shininess for sharper highlights
    float specularIntensity = pow(max(dot(viewDir, reflectDir), 0.0), specularPower);
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);
    fresnel = mix(0.1, 1.0, fresnel);
    // Adjust intensity mix for more prominent specular
    float finalIntensity = specularIntensity * 1.8 + fresnel * 0.2; // More specular weight
    finalIntensity = smoothstep(0.1, 0.7, finalIntensity); // Adjust smoothing range

    // --- Color (Optional Iridescence) ---
    float hue = atan(reflectDir.y, reflectDir.x) / (2.0 * 3.14159) + 0.5;
    vec3 iridescentColor = vec3(
        sin(hue * 6.283 + 0.0) * 0.5 + 0.5,
        sin(hue * 6.283 + 2.0) * 0.5 + 0.5,
        sin(hue * 6.283 + 4.0) * 0.5 + 0.5
    );
    vec3 finalColor = mix(vec3(1.0), iridescentColor, 0.35); // Slightly more iridescence

    // --- Final Output ---
    float finalAlpha = finalIntensity * 0.75; // Slightly increase overall alpha
    fragColor = vec4(finalColor * finalAlpha, finalAlpha);
} 