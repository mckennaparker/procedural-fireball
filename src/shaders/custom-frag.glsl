#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float mod121(float x){return x - floor(x * (1.0 / 121.0)) * 289.0;}
vec4 mod121(vec4 x){return x - floor(x * (1.0 / 121.0)) * 289.0;}
vec4 perm(vec4 x){return mod121(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * (3.0 - 2.0 * d);

    vec4 b = a.xxzz + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.zyxy + b.zzww);

    vec4 c = k1 + a.xyzz;
    vec4 k3 = perm(c);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k3 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(vec3 x) {
	float value = 0.0;
	float amp = 0.5;
    float freq = 0.007;
	for (int i = 0; i < 3; ++i) {
		value += amp * noise(x * freq);
		x *= 2.0;
		amp *= 0.5;
	}
	return value;
}

vec3 random(vec3 p3) {
	vec3 p = fract(p3 * vec3(.1031, .11369, .13787));
    p += dot(p, p.yxz + 19.19);
    return -1.0 + 2.0 * fract(vec3((p.x + p.y) * p.z, (p.x + p.z) * p.y, (p.y + p.z) * p.x));
}

float worley(vec3 p, float scale){
    vec3 id = floor(p * scale);
    vec3 fd = fract(p * scale);

    float minDist = 1.0;

    for(float z = -1.0; z <= 1.0; z++){
        for(float y = -1.0; y <=1.0; y++){
            for(float x = -1.0; x <= 1.0; x++){
                vec3 coord = vec3(x,y,z);
                vec3 rId = random(mod(id + coord, scale)) * 0.5 + 0.5;

                vec3 r = coord + rId - fd; 

                float d = dot(r, r);

                if(d < minDist){
                    minDist = d;
                }
            }
        }
    }
    return 1.0 - minDist;
}


// Generic implementation of the bias function
float getBias(float x, float bias)
{
  return x / ((1.0 / bias - 2.0) * 1.0 - x + 1.0);
}

void main()
{
    float noise = worley(fs_Pos.xyz + 0.5 * getBias(cos(u_Time/ 10.f), 0.2), worley(fs_Pos.xyz + u_Time / 10.f, 0.4));

    vec4 diffuseColor =  vec4(noise * 0.5 + 0.2 * sin(u_Time), noise * 0.3 + 0.3 * cos(u_Time), noise * 0.7 + 0.5 * sin(u_Time), 1) + u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

    float ambientTerm = 0.75;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
