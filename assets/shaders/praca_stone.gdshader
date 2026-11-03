shader_type spatial;
uniform bool promenade = false;
varying vec2 ground;
void vertex() { ground = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz; }
void fragment() {
	vec2 paving = ground * 3.0;
	paving.x += mod(floor(paving.y),2.0)*0.5;
	vec2 cell = floor(paving);
	float variation = fract(sin(dot(cell,vec2(12.9898,78.233))) * 43758.5453);
	vec2 grid = abs(fract(paving)-0.5);
	float seam = smoothstep(0.475,0.495,max(grid.x,grid.y));
	vec3 stone = mix(vec3(0.46,0.47,0.43),vec3(0.55,0.55,0.49),variation*0.40);
	if (promenade) {
		float wave = sin(ground.x*0.9 + sin(ground.y*0.45)*1.6);
		stone = mix(vec3(0.79,0.77,0.65),vec3(0.17,0.22,0.22),smoothstep(0.12,0.3,wave));
	}
	ALBEDO = mix(stone,stone*0.78,seam*0.6);
	ROUGHNESS = 0.95;
}
