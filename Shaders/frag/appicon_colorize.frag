#version 450
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 targetColor;
    float colorizeMode; // 0.0 = dock mode (grayscale), 1.0 = tray mode (intensity), 2.0 = distro mode (luminance with better contrast), 3.0 = duotone
    vec4 lowColor; // duotone only: color for the darkest pixels, targetColor is used for the brightest
} ubuf;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);

    if (ubuf.colorizeMode > 2.5) {
        // Duotone: grayscale, then map luminance onto lowColor -> targetColor
        // so the icon keeps its shading but only uses theme colors.
        // The source is premultiplied, so unpremultiply before measuring.
        vec3 rgb = tex.a > 0.0 ? tex.rgb / tex.a : vec3(0.0);
        float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
        float t = smoothstep(0.05, 0.95, lum);
        vec3 color = mix(ubuf.lowColor.rgb, ubuf.targetColor.rgb, t);
        fragColor = vec4(color * tex.a, tex.a) * ubuf.qt_Opacity;
        return;
    }

    float intensity;

    if (ubuf.colorizeMode < 0.5) {
        // Dock mode: Convert to grayscale using proper luminance weights
        intensity = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    } else if (ubuf.colorizeMode < 1.5) {
        // Tray mode: Use the maximum RGB channel value as intensity.
        // The source is premultiplied, so unpremultiply before measuring.
        vec3 rgb = tex.a > 0.0 ? tex.rgb / tex.a : vec3(0.0);
        intensity = max(max(rgb.r, rgb.g), rgb.b);

        // Normalize intensity to make all icons more uniform, with a floor so
        // dark parts of an icon keep some of the target color instead of going black.
        // Scale by alpha last so transparent pixels stay fully transparent.
        intensity = mix(0.45, 1.0, smoothstep(0.1, 0.9, intensity)) * tex.a;
    } else {
        // Distro mode: Brightness boost with proper alpha handling
        float maxChannel = max(max(tex.r, tex.g), tex.b);

        intensity = maxChannel * 1.5;
        intensity = min(intensity, 1.0);
        intensity = intensity * 0.7 + 0.3;

        intensity = intensity * tex.a;
    }

    fragColor = vec4(ubuf.targetColor.rgb * intensity, tex.a) * ubuf.qt_Opacity;
}
