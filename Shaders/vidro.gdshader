shader_type spatial;
// CORREÇÃO: Mudado de 'shadow_disabled' para 'shadows_disabled'
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled;

// ============================================
// PARÂMETROS EXPORTADOS
// ============================================
uniform vec4 cor_vidro : source_color = vec4(0.75, 0.85, 1.0, 0.25);
uniform float roughness : hint_range(0, 1) = 0.05;
uniform float metallic : hint_range(0, 1) = 0.9;
uniform float intensidade_reflexo : hint_range(0, 2) = 1.0;

// CORREÇÃO OBRIGATÓRIA DA GODOT 4: Declaração da textura da tela com sampler de hint dedicado
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// ============================================
// VERTEX - NORMAL PARA REFLEXÃO
// ============================================
void vertex() {
	// Gera normais suaves para o vidro
	NORMAL = normalize(NORMAL);
}

// ============================================
// FRAGMENT
// ============================================
void fragment() {
	// Cor base do vidro
	vec3 cor = cor_vidro.rgb;
	float alpha = cor_vidro.a;

	// Efeito Fresnel (bordas mais opacas)
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	cor += fresnel * 0.3;
	alpha += fresnel * 0.4;

	// Reflexos do ambiente (utilizando a SCREEN_TEXTURE corrigida acima)
	vec3 reflexo = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	cor += reflexo * 0.15 * intensidade_reflexo;

	// Brilho nas bordas
	float brilho_borda = pow(fresnel, 2.0) * 0.5;
	cor += brilho_borda * 0.3;

	// Saída
	ALBEDO = cor;
	ALPHA = clamp(alpha, 0.0, 0.6);
	ROUGHNESS = roughness;
	METALLIC = metallic;

	// Reflexos especulares
	SPECULAR = 1.0;

	// Transmissão (luz passando pelo vidro - atualizado para Godot 4)
	BACKLIGHT = vec3(0.3) * cor_vidro.rgb;

}
