#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uLightDirection; // Main light source direction
// Optional: Add a second light or environment color if needed
// uniform vec3 uEnvColor;

// Output color
out vec4 fragColor;

// Simple pseudo-random number generator
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Simulate a slightly bumpy surface normal for metallic sheen
// More advanced techniques would use a normal map texture
vec3 getSurfaceNormal(vec2 uv) {
    // Add slight procedural noise/bumpiness to the normal
    float noise = (random(uv * 50.0 + uTime * 0.1) - 0.5) * 0.05;
    // Simple perturbation based on uv coordinates
    vec2 perturbation = vec2(cos(uv.y * 30.0 + uTime * 0.2 + noise), 
                             sin(uv.x * 30.0 - uTime * 0.2 + noise)) * 0.1;
    return normalize(vec3(perturbation.x, perturbation.y, 1.0));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // --- Surface Properties ---
    vec3 surfaceNormal = getSurfaceNormal(uv);
    vec3 viewDirection = vec3(0.0, 0.0, 1.0); // Assuming viewer looks straight down Z
    vec3 lightDir = normalize(uLightDirection);

    // --- Lighting Calculations for Chrome ---

    // Reflection vector (viewer reflects off the surface)
    vec3 reflection = reflect(-viewDirection, surfaceNormal);

    // Fresnel effect: reflections are stronger at grazing angles
    float fresnelFactor = pow(1.0 - max(0.0, dot(surfaceNormal, viewDirection)), 3.0);
    fresnelFactor = mix(0.1, 1.0, fresnelFactor); // Mix between base reflectivity and full reflection

    // Simulate environment reflection using the light direction
    // This is a simplification - real chrome reflects the entire environment
    // We use the reflection vector dotted with the light direction for a highlight
    float envReflection = pow(max(0.0, dot(reflection, lightDir)), 4.0);
    // Add another highlight based directly on light reflection (Blinn-Phong style)
    vec3 halfwayDir = normalize(lightDir + viewDirection);
    float specularHighlight = pow(max(0.0, dot(surfaceNormal, halfwayDir)), 64.0); // Sharp highlight

    // --- Color Calculation ---
    // Base chrome color (dark grey)
    vec3 baseColor = vec3(0.15);

    // Reflection color (bright, slightly bluish tint for cool metal)
    vec3 reflectionColor = vec3(0.9, 0.95, 1.0);

    // Combine using Fresnel
    vec3 finalColor = mix(baseColor, reflectionColor, fresnelFactor);

    // Add the sharp highlights
    finalColor += reflectionColor * envReflection * 0.8; // Environment-like highlight
    finalColor += vec3(1.0) * specularHighlight * 1.2; // Sharp light source highlight

    // Add subtle variations based on UV (optional)
    // finalColor *= (0.95 + 0.05 * sin(uv.x * 10.0 + uTime));

    // Clamp color to avoid excessive brightness, but allow some bloom
    finalColor = clamp(finalColor, 0.0, 1.8);

    // Output final color (fully opaque)
    fragColor = vec4(finalColor, 1.0);
} 