shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// CHROMATIC ABERRATION
uniform float chroma_strength : hint_range(0.0, 8.0) = 3.0;
uniform float chroma_pulse_speed : hint_range(0.0, 10.0) = 4.0;

// SCANLINES
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count : hint_range(100.0, 600.0) = 280.0;

// VIGNETTE
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.55;
uniform float vignette_pulse_speed : hint_range(0.0, 5.0) = 1.8;

// SCREEN WARP
uniform float warp_strength : hint_range(0.0, 0.05) = 0.012;

// FLICKER
uniform float flicker_speed : hint_range(0.0, 30.0) = 18.0;
uniform float flicker_intensity : hint_range(0.0, 0.15) = 0.04;

// COLOR GRADE
uniform float cyan_boost : hint_range(0.0, 0.5) = 0.08;
uniform float magenta_boost : hint_range(0.0, 0.5) = 0.05;
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform float saturation : hint_range(0.0, 3.0) = 1.4;

// GLITCH
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float glitch_speed : hint_range(0.0, 20.0) = 7.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 crt_warp(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	uv.x *= 1.0 + uv.y * uv.y * warp_strength;
	uv.y *= 1.0 + uv.x * uv.x * warp_strength;
	return uv * 0.5 + 0.5;
}

vec3 chromatic_sample(sampler2D tex, vec2 uv, float strength) {
	vec2 dir = uv - vec2(0.5);
	float dist = length(dir);
	vec2 offset = normalize(dir) * dist * dist * strength * 0.01;
	
	float r = texture(tex, uv + offset * 1.0).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - offset * 1.0).b;
	return vec3(r, g, b);
}

vec3 apply_saturation(vec3 col, float sat) {
	float grey = dot(col, vec3(0.299, 0.587, 0.114));
	return mix(vec3(grey), col, sat);
}

vec3 apply_contrast(vec3 col, float c) {
	return (col - 0.5) * c + 0.5;
}

void fragment() {
	float t = TIME;
	vec2 uv = SCREEN_UV;
	
	// CRT WARP
	uv = crt_warp(uv);
	
if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    COLOR = vec4(0.0, 0.0, 0.0, 1.0);
} else {
    float glitch_roll = rand(vec2(floor(uv.y * 80.0), floor(t * glitch_speed)));
    float glitch_thresh = 1.0 - glitch_intensity * 0.3;
    if (glitch_roll > glitch_thresh) {
        float glitch_shift = (rand(vec2(t, uv.y)) - 0.5) * glitch_intensity * 0.04;
        uv.x += glitch_shift;
    }
    float band = step(0.997 - glitch_intensity * 0.02, rand(vec2(floor(t * glitch_speed * 0.3), 0.0)));
    float band_y = rand(vec2(floor(t * 2.0), 1.0));
    if (band > 0.0 && abs(uv.y - band_y) < 0.012) {
        uv.x += (rand(vec2(uv.y, t)) - 0.5) * 0.06;
    }

    float chroma_pulse = chroma_strength + sin(t * chroma_pulse_speed) * 1.8 + sin(t * chroma_pulse_speed * 2.3 + 1.0) * 0.9;
    vec3 col = chromatic_sample(screen_texture, uv, chroma_pulse);

    float scan = sin(uv.y * scanline_count * 3.14159);
    scan = scan * scan;
    col *= 1.0 - scan * scanline_intensity;

    float flicker = 1.0 - flicker_intensity * rand(vec2(floor(t * flicker_speed), 0.3));
    col *= flicker;

    col.r += magenta_boost * (1.0 - col.r);
    col.b += magenta_boost * (1.0 - col.b);
    col.g += cyan_boost * (1.0 - col.g);
    col.b += cyan_boost * (1.0 - col.b);

    col = apply_saturation(col, saturation);
    col = apply_contrast(col, contrast);

    float vignette_pulse = vignette_strength + sin(t * vignette_pulse_speed) * 0.12 + sin(t * vignette_pulse_speed * 3.1) * 0.05;
    vec2 vig_uv = uv - 0.5;
    float vignette = 1.0 - dot(vig_uv, vig_uv) * vignette_pulse * 3.2;
    col *= clamp(vignette, 0.0, 1.0);

    COLOR = vec4(col, 1.0);
}

	float glitch_roll = rand(vec2(floor(uv.y * 80.0), floor(t * glitch_speed)));
	float glitch_thresh = 1.0 - glitch_intensity * 0.3;
	if (glitch_roll > glitch_thresh) {
		float glitch_shift = (rand(vec2(t, uv.y)) - 0.5) * glitch_intensity * 0.04;
		uv.x += glitch_shift;
	}
    // BAND TEAR
	float band = step(0.997 - glitch_intensity * 0.02, rand(vec2(floor(t * glitch_speed * 0.3), 0.0)));
	float band_y = rand(vec2(floor(t * 2.0), 1.0));
	if (band > 0.0 && abs(uv.y - band_y) < 0.012) {
		uv.x += (rand(vec2(uv.y, t)) - 0.5) * 0.06;
	}

	// PULSING CHROMATIC ABERRATION
	float chroma_pulse = chroma_strength + sin(t * chroma_pulse_speed) * 1.8 + sin(t * chroma_pulse_speed * 2.3 + 1.0) * 0.9;
	vec3 col = chromatic_sample(screen_texture, uv, chroma_pulse);

	// SCANLINES
	float scan = sin(uv.y * scanline_count * 3.14159);
	scan = scan * scan;
	col *= 1.0 - scan * scanline_intensity;

	// FLICKER
	float flicker = 1.0 - flicker_intensity * rand(vec2(floor(t * flicker_speed), 0.3));
	col *= flicker;

	// COLOR GRADING (cyan/magenta)
	col.r += magenta_boost * (1.0 - col.r);
	col.b += magenta_boost * (1.0 - col.b);
	col.g += cyan_boost * (1.0 - col.g);
	col.b += cyan_boost * (1.0 - col.b);
	
	col = apply_saturation(col, saturation);
	col = apply_contrast(col, contrast);

	// PULSING VIGNETTE
	float vignette_pulse = vignette_strength + sin(t * vignette_pulse_speed) * 0.12 + sin(t * vignette_pulse_speed * 3.1) * 0.05;
	vec2 vig_uv = uv - 0.5;
	float vignette = 1.0 - dot(vig_uv, vig_uv) * vignette_pulse * 3.2;
	col *= clamp(vignette, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
