import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
    indices: Uint32Array;
    positions: Float32Array;
    normals: Float32Array;
    center: vec4;

    constructor(center: vec3) {
        super(); // Call the constructor of the super class. This is required.
        this.center = vec4.fromValues(center[0], center[1], center[2], 1);
    }

    create() {
        this.indices = new Uint32Array([0, 1, 2, //front left triangle
                                        0, 2, 3, //front right triangle
                                        4, 5, 6, //top left triangle
                                        4, 6, 7, //top right triangle
                                        8, 9, 10, // right front triangle
                                        8, 10, 11, // right back triangle
                                        12, 13, 14, // bottom right triangle
                                        12, 14, 15, // bottom left triangle
                                        16, 17, 18, // left back triangle
                                        16, 18, 19, // left front triangle
                                        20, 21, 22, // back top triangle
                                        20, 22, 23]); // back bottom triangle

        this.normals = new Float32Array([0, 0, 1, 0, //front face normal
                                         0, 0, 1, 0, //front face normal
                                         0, 0, 1, 0, //front face normal
                                         0, 0, 1, 0, //front face normal
                                         0, 1, 0, 0, //top face normal
                                         0, 1, 0, 0, //top face normal
                                         0, 1, 0, 0, //top face normal
                                         0, 1, 0, 0, //top face normal
                                         1, 0, 0, 0, //right face normal
                                         1, 0, 0, 0, //right face normal
                                         1, 0, 0, 0, //right face normal
                                         1, 0, 0, 0, //right face normal
                                         0, -1, 0, 0, //bottom face normal
                                         0, -1, 0, 0, //bottom face normal
                                         0, -1, 0, 0, //bottom face normal
                                         0, -1, 0, 0, //bottom face normal
                                         -1, 0, 0, 0, //left face normal
                                         -1, 0, 0, 0, //left face normal
                                         -1, 0, 0, 0, //left face normal
                                         0, 0, -1, 0, //back face normal
                                         0, 0, -1, 0, //back face normal
                                         0, 0, -1, 0, //back face normal
                                         0, 0, -1, 0, //back face normal
                                        ]);

        this.positions = new Float32Array([-1, -1, 1, 1, //front bottom left
                                           -1, 1, 1, 1, //front top left
                                           1, 1, 1, 1, //front top right
                                           1, -1, 1, 1, //front bottom right
                                           -1, 1, 1, 1, //top front left
                                           -1, 1, -1, 1, //top back left
                                           1, 1, -1, 1, //top back right
                                           1, 1, 1, 1, //top front right
                                           1, -1, 1, 1, //right front bottom
                                           1, 1, 1, 1, //right front top
                                           1, 1, -1, 1, //right back top
                                           1, -1, -1, 1, //right back bottom
                                           -1, -1, 1, 1, //bottom front left
                                           -1, -1, -1, 1, //bottom back left
                                           1, -1, -1, 1, //bottom back right
                                           1, -1, 1, 1, //bottom front right
                                           -1, -1, 1, 1, //left front bottom
                                           -1, -1, -1, 1, //left back bottom
                                           -1, 1, -1, 1, //left back top
                                           -1, 1, 1, 1, //left front top
                                           -1, -1, -1, 1, //back bottom left
                                           -1, 1, -1, 1, //back top left
                                           1, 1, -1, 1, //back top right
                                           1, -1, -1, 1, //back bottom right
                                        ]);
        
        this.generateIdx();
        this.generatePos();
        this.generateNor();

        this.count = this.indices.length;
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
        gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
        gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

        console.log(`Created cube`);
    }
}

export default Cube;
