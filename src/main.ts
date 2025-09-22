import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  Tesselations: 5,
  BaseColor: [255, 0, 0],
  SecondaryColor: [190, 76, 0],
  TertiaryColor: [255, 225, 0],
  Persistence: 0.5,
  Amplitude: 0.5,
  Frequency: 2.0,
  Octaves: 6,
  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let prevTesselations: number = 5;
let time: number = 0.0;
let toDraw: Array<Icosphere> = [];

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.Tesselations);
  icosphere.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Tesselations', 0, 8).step(1);
  gui.addColor(controls, 'BaseColor');
  gui.addColor(controls, 'SecondaryColor');
  gui.addColor(controls, 'TertiaryColor');
  gui.add(controls, 'Persistence', 0.0, 1.0);
  gui.add(controls, 'Amplitude', 0.25, 1.0);
  gui.add(controls, 'Frequency', 0.0, 10.0);
  gui.add(controls, 'Octaves', 1, 10).step(1);
  gui.add(controls, 'Load Scene');

  // Get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const shader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    // Tick time
    time += 0.01;

    // Start necessary systems for rendering
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    // Draw the icosphere
    icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.Tesselations);
    icosphere.create();
    toDraw = [icosphere];

    // Check if tesselation level changed
    if(controls.Tesselations != prevTesselations)
    {
      prevTesselations = controls.Tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    // Make colors into vec4s for shader
    let baseColor = vec4.fromValues(controls.BaseColor[0] / 255, controls.BaseColor[1] / 255, controls.BaseColor[2] / 255, 1);
    let secondaryColor = vec4.fromValues(controls.SecondaryColor[0] / 255, controls.SecondaryColor[1] / 255, controls.SecondaryColor[2] / 255, 1);
    let tertiaryColor = vec4.fromValues(controls.TertiaryColor[0] / 255, controls.TertiaryColor[1] / 255, controls.TertiaryColor[2] / 255, 1);

    // Set shader uniforms
    shader.setBaseColor(baseColor);
    shader.setSecondaryColor(secondaryColor);
    shader.setTertiaryColor(tertiaryColor);
    shader.setTime(time);
    shader.setPersistence(controls.Persistence);
    shader.setAmplitude(controls.Amplitude);
    shader.setFrequency(controls.Frequency);
    shader.setOctaves(controls.Octaves);

    // Draw
    renderer.render(camera, shader, baseColor, toDraw);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
