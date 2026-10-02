shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 crack_color : source_color = vec3(0.2, 0.05, 0.05);
uniform float noise_scale : hint_range(1.0, 50.0) = 10.0;
uniform float crack_threshold : hint_range(0.0, 1.0) = 0.5; // Quanto maior, mais finas as rachaduras

// Função de ruído simples para Godot 4
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
    vec4 base_color = texture(albedo_texture, UV);
    
    // Gera o padrão de ruído baseado na UV
    float n = noise(UV * noise_scale);
    
    // Cria um efeito de "veias" ou rachaduras usando o ruído
    // Se o ruído for maior que o threshold, consideramos como rachadura
    float crack_mask = smoothstep(crack_threshold, crack_threshold + 0.1, n);
    
    // Inverte para que as linhas sejam escuras (opcional)
    crack_mask = 1.0 - crack_mask;
    
    vec3 final_color = mix(base_color.rgb, crack_color, crack_mask);
    
    ALBEDO = final_color;
    
    // Dá uma leve rugosidade extra nas rachaduras
    ROUGHNESS = mix(0.8, 0.5, crack_mask);
}