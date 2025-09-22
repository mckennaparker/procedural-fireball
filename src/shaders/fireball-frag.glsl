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

uniform vec4 u_BaseColor; // The color with which to render this instance of geometry.
uniform vec4 u_SecondaryColor;
uniform vec4 u_TertiaryColor;
uniform float u_Time;
uniform float u_Amplitude;
uniform float u_Persistence;
uniform float u_Frequency;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// TOOLBOX FUNCTIONS
float bias(float b, float t)
{
    return pow(t, log(b) / log(0.5));
}

float gain(float g, float t)
{
    if (t < 0.5) {
        return bias(1.0 - g, 2.0 * t) / 2.0;
    } else {
        return 1.0 - bias(1.0 - g, 2.0 - 2.0 * t) / 2.0;
    }
}

// Sinc Impulse as shown on IQ's functions article
float impulse(float x, float k)
{
    float a = 3.1415926 * (k * x - 1.0);
    return sin(a) / a;
}

float triangleWave(float x, float freq, float amplitude)
{
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

float easeInQuad(float x)
{
    return x * x;
}

float easeInOutQuad(float x)
{
    if (x < 0.5) {
        return easeInQuad(x * 2.0) / 2.0;
    } else {
        return (1.0 - easeInQuad((1.0 - x) * 2.0) / 2.0);
    }
}

// NOISE FUNCTIONS
float hash(float p)
{
    p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p);
}

// 3D Noise Function from morgan3d on Shadertoy: https://www.shadertoy.com/view/4dS3Wd
float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);

    // For performance, compute the base input to a 1D hash from the integer part of the argument and the
    // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// FBM Function from morgan3d on Shadertoy: https://www.shadertoy.com/view/4dS3Wd
float fbm(vec3 x) {
    float value = 0.0;

    float amp = u_Amplitude;
    float pers = u_Persistence;
    float freq = u_Frequency;
    int octaves = 6;

    for (int i = 0; i < octaves; i++) {
        value += amp * noise(x * freq);
        amp *= pers;
        freq *= 0.5;
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

void main()
{
    // Fireball Frag Shader
    vec4 diffuseColor = u_BaseColor;
    vec3 pos = fs_Pos.xyz;
    vec3 nor = fs_Nor.xyz;

    vec3 modifiedPos = fs_Pos.xyz;
    modifiedPos.x *= u_Time * 0.0456;
    modifiedPos.y *= u_Time * -0.2380;
    modifiedPos.z *= u_Time / 0.24239184;

    float noise = easeInOutQuad(fbm(fs_Pos.xyz * u_Time)); // Toolbox Function

    if (fs_Pos.y < -0.3 * noise) {
        diffuseColor = u_BaseColor * noise / worley(fs_Pos.xyz, 5.0) + u_SecondaryColor;
    } else if (fs_Pos.y < 0.9 * noise) {
        diffuseColor = u_SecondaryColor * noise / worley(fs_Pos.xyz, 5.0) + u_BaseColor;
    } else if (fs_Pos.y < 1.5 * noise) {
        diffuseColor = u_TertiaryColor * noise / worley(fs_Pos.xyz, 5.0) + u_SecondaryColor;
    } else {
        discard;
    }


    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

    float ambientTerm = 0.99;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
