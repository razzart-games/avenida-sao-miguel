shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Parâmetros que você pode ajustar direto no Inspetor
uniform vec4 cor_base : source_color = vec4(0.0, 0.65, 0.85, 1.0); // O azul do SU7
uniform float metalico : hint_range(0.0, 1.0) = 0.8;             // Nível de metal
uniform float rugosidade : hint_range(0.0, 1.0) = 0.25;          // Brilho da tinta base
uniform float verniz : hint_range(0.0, 1.0) = 1.0;                // Efeito de verniz (clearcoat)
uniform float rugosidade_verniz : hint_range(0.0, 1.0) = 0.05;   // Brilho do verniz

void fragment() {
    ALBEDO = cor_base.rgb;
    METALLIC = metalico;
    ROUGHNESS = rugosidade;
    
    // O segredo do carro novo:
    CLEARCOAT = verniz;
    CLEARCOAT_ROUGHNESS = rugosidade_verniz;
}