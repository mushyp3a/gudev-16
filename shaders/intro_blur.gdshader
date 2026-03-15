shader_type canvas_item;

uniform vec3 color1 : source_color = vec3(1.0, 0.0, 0.5);
uniform vec3 color2 : source_color = vec3(0.0, 0.5, 1.0);
uniform vec3 color3 : source_color = vec3(0.5, 0.0, 1.0);

uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float blur_amount : hint_range(0.0, 1.0) = 0.8;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

// Improved multi-octave noise for organic Firewatch-like feel
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion for layered organic movement
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for(int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_scale;

    // Create larger, slower moving organic patches (Firewatch style)
    vec2 noise_uv1 = uv * noise_scale * 0.6 + vec2(t * 0.08, t * 0.12);
    vec2 noise_uv2 = uv * noise_scale * 0.8 + vec2(-t * 0.1, t * 0.06);
    vec2 noise_uv3 = uv * noise_scale * 0.5 + vec2(t * 0.04, -t * 0.08);

    // Use FBM for more organic, layered movement
    float n1 = fbm(noise_uv1);
    float n2 = fbm(noise_uv2);
    float n3 = fbm(noise_uv3);

    // Add subtle pulsing to make it feel alive
    float pulse = sin(t * 0.5) * 0.15 + 0.85;

    // More defined splotches with sharper edges
    float blur = blur_amount * 0.8;
    n1 = smoothstep(0.3 - blur, 0.7 + blur, n1) * pulse;
    n2 = smoothstep(0.3 - blur, 0.7 + blur, n2);
    n3 = smoothstep(0.3 - blur, 0.7 + blur, n3) * (1.0 + sin(t * 0.7) * 0.1);

    // Blend colors with medium darkness for noir cyberpunk
    vec3 blend1 = color1 * n1 * 0.55;
    vec3 blend2 = color2 * n2 * 0.5;
    vec3 blend3 = color3 * n3 * 0.5;

    // Dark, moody blending with some overlap
    vec3 final_color = blend1 + blend2 * 0.6 + blend3 * 0.65;

    // Moderate vignette for noir darkness
    vec2 center = uv - 0.5;
    float dist = length(center);
    float vignette = 1.0 - smoothstep(0.4, 1.1, dist);

    // Apply vignette darkening
    final_color *= vignette;

    // Add center emphasis for depth
    float center_glow = 1.0 - smoothstep(0.0, 0.6, dist);
    final_color += final_color * center_glow * 0.15;

    // Moderate darkening for gritty cyberpunk
    final_color *= 0.75;

    // Strong contrast for defined colors
    float luma = dot(final_color, vec3(0.299, 0.587, 0.114));
    final_color = mix(vec3(luma), final_color, 1.5);

    COLOR = vec4(final_color, 1.0);
}
