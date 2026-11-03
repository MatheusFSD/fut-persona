shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float sea_time = 0.0;
varying vec2 sea;
void vertex() {
	sea = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz;
	VERTEX.y += sin(sea.x*0.20+sea_time*0.55)*0.025 + cos(sea.y*0.17-sea_time*0.4)*0.02;
}
void fragment() {
	float band = sin(sea.x*0.8+sea.y*0.17+sin(sea.y*0.11)*1.1+sea_time*0.8);
	float breakup = sin(sea.y*0.72-sea.x*0.22+sea_time*0.35);
	float glitter = smoothstep(0.94,0.99,band)*smoothstep(0.45,0.80,breakup)*0.12;
	vec3 color = mix(vec3(0.13,0.43,0.51),vec3(0.24,0.62,0.65),COLOR.r);
	ALBEDO = color + glitter;
}
