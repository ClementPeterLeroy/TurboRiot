shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 deep_color : source_color = vec4(0.035,0.30,0.46,1.0);
uniform vec4 crest_color : source_color = vec4(0.12,0.53,0.64,1.0);
uniform float wave_speed = 0.35;
void fragment() {
    vec2 p = UV * 700.0;
    float wave = sin(p.y * 1.5 + sin(p.x * 0.18 + TIME * 0.1) * 0.6 - TIME * wave_speed);
    float ribbon = smoothstep(0.97,1.0,wave) * (0.4 + 0.6 * sin(p.x * 0.23 + TIME * 0.12));
    ALBEDO = mix(deep_color.rgb,crest_color.rgb,max(ribbon,0.0) * 0.32);
}
