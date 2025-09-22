import {vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifBaseColor: WebGLUniformLocation;
  unifSecondaryColor: WebGLUniformLocation;
  unifTertiaryColor: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifPersistence: WebGLUniformLocation;
  unifAmplitude: WebGLUniformLocation;
  unifFrequency: WebGLUniformLocation;
  unifOctaves: WebGLUniformLocation;


  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifBaseColor  = gl.getUniformLocation(this.prog, "u_BaseColor");
    this.unifSecondaryColor  = gl.getUniformLocation(this.prog, "u_SecondaryColor");
    this.unifTertiaryColor  = gl.getUniformLocation(this.prog, "u_TertiaryColor");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");
    this.unifPersistence = gl.getUniformLocation(this.prog, "u_Persistence");
    this.unifAmplitude = gl.getUniformLocation(this.prog, "u_Amplitude");
    this.unifFrequency = gl.getUniformLocation(this.prog, "u_Frequency");
    this.unifOctaves = gl.getUniformLocation(this.prog, "u_Octaves");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setBaseColor(color: vec4) {
    this.use();
    if (this.unifBaseColor !== -1) {
      gl.uniform4fv(this.unifBaseColor, color);
    }
  }

  setSecondaryColor(color: vec4) {
    this.use();
    if (this.unifSecondaryColor !== -1) {
      gl.uniform4fv(this.unifSecondaryColor, color);
    }
  }

  setTertiaryColor(color: vec4) {
    this.use();
    if (this.unifTertiaryColor !== -1) {
      gl.uniform4fv(this.unifTertiaryColor, color);
    }
  }

  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, time);
    }
  }

  setPersistence(persistence: number) {
    this.use();
    if (this.unifPersistence !== -1) {
      gl.uniform1f(this.unifPersistence, persistence);
    }
  }

  setAmplitude(amplitude: number) {
    this.use();
    if (this.unifAmplitude !== -1) {
      gl.uniform1f(this.unifAmplitude, amplitude);
    }
  }

  setFrequency(frequency: number) {
    this.use();
    if (this.unifFrequency !== -1) {
      gl.uniform1f(this.unifFrequency, frequency);
    }
  }

  setOctaves(octaves: number) {
    this.use();
    if (this.unifOctaves !== -1) {
      gl.uniform1f(this.unifOctaves, octaves);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
