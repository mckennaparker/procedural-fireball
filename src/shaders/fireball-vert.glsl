#version 300 es

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;       // Time variable used to non-uniformly change vertex position
uniform float u_Amplitude;
uniform float u_Persistence;
uniform float u_Frequency;
uniform int u_Octaves;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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
    int octaves = u_Octaves;

    for (int i = 0; i < octaves; i++) {
        value += amp * noise(x * freq);
        amp *= pers;
        freq *= 2.0;
    }

    return value;
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;

    // Deformation of icosphere to flame
    float dX = impulse(fbm(vs_Pos.xyz), u_Time); // Toolbox Function
    float dY = fs_Pos.y * triangleWave(fbm(vs_Pos.xyz), 3.1415926, 1.0); // Toolbox Function
    float dZ = impulse(10.0 * fbm(vs_Pos.xyz), 2.0);

    vec3 newPos = vs_Pos.xyz + vec3(dX, dY, dZ);
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition = u_Model * vec4(newPos, 1.0);   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
