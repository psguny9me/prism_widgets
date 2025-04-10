#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms passed from Flutter
uniform vec2 uResolution; // Canvas size (width, height)
uniform float uTime;      // Time for animations
uniform vec3 uLightDirection; // Normalized light direction (x, y, z) - z is towards the viewer if positive
uniform sampler2D uImageSampler; // The base texture of the card

// Output color
out vec4 fragColor;

// Simple pseudo-random number generator
float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Simple rainbow color generation based on a float value (0-1)
vec3 rainbow(float value) {
    // Shift the hue based on the input value
    float hue = fract(value);
    float saturation = 0.8; // Keep saturation high for vibrant colors
    float lightness = 0.6; // Adjust lightness

    float c = (1.0 - abs(2.0 * lightness - 1.0)) * saturation;
    float x = c * (1.0 - abs(mod(hue * 6.0, 2.0) - 1.0));
    float m = lightness - c / 2.0;

    vec3 rgb;
    if (hue < 1.0/6.0) {
        rgb = vec3(c, x, 0.0);
    } else if (hue < 2.0/6.0) {
        rgb = vec3(x, c, 0.0);
    } else if (hue < 3.0/6.0) {
        rgb = vec3(0.0, c, x);
    } else if (hue < 4.0/6.0) {
        rgb = vec3(0.0, x, c);
    } else if (hue < 5.0/6.0) {
        rgb = vec3(x, 0.0, c);
    } else {
        rgb = vec3(c, 0.0, x);
    }
    return rgb + m;
}

// Simulate a normal vector. For real depth, use a normal map texture.
// This version creates a subtle wave pattern.
vec3 calculateSurfaceNormal(vec2 uv) {
    // Simple procedural normal - creates a subtle sheen effect
    float wave = sin(uv.x * 20.0 + uTime * 0.5) * 0.01 + cos(uv.y * 15.0 + uTime * 0.3) * 0.01;
    // Use dFdx/dFdy if available and needed for more complex normals,
    // but for simple effects, manipulating z is often enough.
    // vec3 tangent = normalize(vec3(1.0, 0.0, dFdx(wave)));
    // vec3 bitangent = normalize(vec3(0.0, 1.0, dFdy(wave)));
    // return normalize(cross(tangent, bitangent));
    return normalize(vec3(cos(wave * 3.14), sin(wave * 3.14), 1.0)); // Simple tilt based on wave
}

void main() {
    // Get normalized texture coordinates (0.0 to 1.0)
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Flip UV vertically if needed (Flutter loads images upside down for shaders)
    uv.y = 1.0 - uv.y;

    // Sample the base color from the texture
    vec4 baseColor = texture(uImageSampler, uv);

    // --- Calculate Surface Normal ---
    vec3 normal = calculateSurfaceNormal(uv);
    // For a flat effect, uncomment below:
    // vec3 normal = vec3(0.0, 0.0, 1.0);

    // --- Lighting Calculation ---
    vec3 lightDir = normalize(uLightDirection); // Ensure light direction is normalized
    vec3 viewDir = vec3(0.0, 0.0, 1.0); // Assume viewer is looking directly down the Z-axis

    // Diffuse reflection (how much light reflects evenly) - subtle for metallic look
    float diffuseIntensity = max(dot(normal, lightDir), 0.0) * 0.3;

    // Specular reflection (shiny highlight)
    vec3 halfwayDir = normalize(lightDir + viewDir); // Blinn-Phong optimization
    float specAngle = max(dot(normal, halfwayDir), 0.0);
    // Adjust shininess (higher value = sharper highlight)
    float shininess = 128.0;
    float specularIntensity = pow(specAngle, shininess);

    // --- Prism Effect ---
    // Calculate a value that changes based on the view angle relative to the normal and light
    // We use the reflection vector for a more dynamic effect
    vec3 reflectDir = reflect(-lightDir, normal);

    // Angle based on reflection direction projected onto the view plane
    // Adding uv position makes it vary across the surface
    float prismValue = atan(reflectDir.y, reflectDir.x) / (2.0 * 3.14159) + length(uv - 0.5) * 0.5;
    prismValue += uTime * 0.1; // Animate the prism effect over time

    vec3 prismColor = rainbow(prismValue);

    // Intensity of the prism effect - make it stronger where the specular highlight is
    // and also vary based on the viewing angle relative to the reflection
    float prismIntensity = pow(max(dot(viewDir, reflectDir), 0.0), 16.0); // Stronger near reflection center
    prismIntensity = mix(0.1, 0.8, prismIntensity); // Control min/max intensity
    prismIntensity *= (smoothstep(0.0, 0.5, length(uv * 2.0 - 1.0))); // Fade near edges

    // --- Combine Components ---
    // Start with base color modulated by subtle diffuse light
    vec3 finalColor = baseColor.rgb * (0.7 + diffuseIntensity);

    // Add the specular highlight (white)
    finalColor += vec3(1.0) * specularIntensity * 1.5; // Make specular bright

    // Add the prism color, mixing it based on calculated intensity
    finalColor = mix(finalColor, prismColor * 1.2, prismIntensity); // Mix in the prism effect, make it slightly brighter

    // Clamp the color to prevent extreme blowouts, but allow some brightness > 1 for bloom potential
    finalColor = clamp(finalColor, 0.0, 1.5);

    // Final output color, preserving original alpha
    fragColor = vec4(finalColor, baseColor.a);
} 