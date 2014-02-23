import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'package:json_object/json_object.dart';

void main() {
  loadStarData();
}

// globals
var starData;
var starSystem;
var scene;
var renderer;
var camera;
var rotating;
var translating;
var universe;

var starUniforms = {
  "color": new Uniform.color(0xffffff),
  "cameraZ": new Uniform.float(0.0),
  "time": new Uniform.float(0.0)
};

var starAttributes = {
  "distance": new Attribute.float(),
  "color": new Attribute.color()
};

// helper functions
bv_to_rgb(bv) {
  var t = 4600 * ((1 / ((0.92 * bv) + 1.7)) +(1 / ((0.92 * bv) + 0.62)) );

  // t to xyY
  var x, y = 0;

  if (t>=1667 && t<=4000) {
    x = ((-0.2661239 * Math.pow(10,9)) / Math.pow(t,3)) + ((-0.2343580 * Math.pow(10,6)) / Math.pow(t,2)) + ((0.8776956 * Math.pow(10,3)) / t) + 0.179910;
  } else if (t > 4000 && t <= 25000) {
    x = ((-3.0258469 * Math.pow(10,9)) / Math.pow(t,3)) + ((2.1070379 * Math.pow(10,6)) / Math.pow(t,2)) + ((0.2226347 * Math.pow(10,3)) / t) + 0.240390;
  }

  if (t >= 1667 && t <= 2222) {
    y = -1.1063814 * Math.pow(x,3) - 1.34811020 * Math.pow(x,2) + 2.18555832 * x - 0.20219683;
  } else if (t > 2222 && t <= 4000) {
    y = -0.9549476 * Math.pow(x,3) - 1.37418593 * Math.pow(x,2) + 2.09137015 * x - 0.16748867;
  } else if (t > 4000 && t <= 25000) {
    y = 3.0817580 * Math.pow(x,3) - 5.87338670 * Math.pow(x,2) + 3.75112997 * x - 0.37001483;
  }

  // xyY to XYZ, Y = 1
  var Y = (y == 0)? 0 : 1;
  var X = (y == 0)? 0 : (x * Y) / y;
  var Z = (y == 0)? 0 : ((1 - x - y) * Y) / y;

  //XYZ to rgb
  var r = 0.41847 * X - 0.15866 * Y - 0.082835 * Z;
  var g = -0.091169 * X + 0.25243 * Y + 0.015708 * Z;
  var b = 0.00092090 * X - 0.0025498 * Y + 0.17860 * Z;
  
  //rgb to RGB
  var R = Math.pow(r, 1 / 2.2);
  var G = Math.pow(g, 1 / 2.2);
  var B = Math.pow(b, 1 / 2.2);
  return [R,G,B];
}

linearTween(t,b,c,d) => c*t/d + b;

lerp(v1,v2,alpha) {
  v1.x += (v2.x - v1.x)*alpha;
  v1.y += (v2.y - v1.y)*alpha;
  v1.z += (v2.z - v1.z)*alpha;
  
  return v1;
}

limit(a, x, b) {
  if(x < a) return a;
  if(x > b) return b;
      return x;
}

// objects
class Camera extends PerspectiveCamera {
  var position = new Vector3.zero();
  var target = new Vector3.zero();
  
  Camera(fov, aspect, near, far, position): super(fov, aspect, near, far) {
    this.position.z = position;
    target.z = position;
  }
  
  update() => position.z += (target.z - position.z) * 0.125;
  
  dramaticEntry(delta) {
    if (target.z > 10000) {
      target.z = linearTween(delta, 500000, -10000, 2000);
    }  
  }
}

class Rotating extends Object3D {
  Rotating() : super() {
    rotation.y = Math.PI * 0.01;
  }
  
  update(delta) {
    rotation.y += 0.0015;
  }
}

class Translating extends Object3D {
  var targetPosition = new Vector3.zero();
  
  update(delta) {
    lerp(position, targetPosition, 0.1);
    if(position.sub(targetPosition).length2 < 0.01)
      position.setFrom(targetPosition);
  }
}

class Universe extends Object3D {
  update(delta) {
    starUniforms['cameraZ'].value = camera.position.z;
    starUniforms['time'].value = delta;
  }
}

class Star extends Vector3 {
  var distance;
  var ra;
  var dec;
  var color;
  
  Star(distance, ra, dec, color) : super.zero() {
    this.distance = distance * 3.26156;
    this.ra = ra;
    this.dec = dec;
    this.color = new Color();

    // http://math.stackexchange.com/questions/52936/plotting-a-stars-position-on-a-2d-map
    var phi = (ra+90) * 15 * Math.PI/180;
    var theta = dec * Math.PI / 180;
    var rho = distance;
    var rvect = rho * Math.cos(theta);
    this.x = rvect * Math.cos(phi);
    this.y = rvect * Math.sin(phi);
    this.z = rho * Math.sin(theta);

    if (color != null) {
      var rgb = bv_to_rgb(color);
      this.color.r = rgb[0]; this.color.g = rgb[1]; this.color.b = rgb[2];
    } 
  }
}

// functions
loadStarData(){
  var url = 'data/hygxyz.json';
  var request = HttpRequest.getString(url).then(onStarDataLoaded);
}

onStarDataLoaded(String responseText) {
  starData = new JsonObject.fromJsonString(responseText);
  init();
  window.animationFrame.then(render);
}

init() {
  scene = new Scene();
  scene.add(new AmbientLight(0x404040));

  universe = new Universe();
  translating = new Translating();
  translating.add(universe);
  rotating = new Rotating();
  rotating.add(translating);
  scene.add(rotating);

  renderer = new WebGLRenderer(antialias:true);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.nodes.add(renderer.domElement);

  camera = new Camera(35.0, window.innerWidth / window.innerHeight, 0.1, 10000000.0, 500000.0);
  scene.add(camera);

  var starGeometry = new Geometry();

  for(var s in starData) {    
    if(s.d >= 10000000) continue;
    var star = new Star(s.d, s.ra, s.dec, s.c);
    starGeometry.vertices.add(star);    
    starGeometry.colors.add(star.color);
  }

  var shaderMaterial = new ShaderMaterial(
    uniforms: starUniforms,
    attributes: starAttributes,
    vertexShader:   document.getElementById('vertexshader').text,
    fragmentShader: document.getElementById('fragmentshader').text,
    blending:     AdditiveBlending,
    depthTest:    false,
    depthWrite:   false,
    transparent:  true
  );
  
  for (var v = 0; v < starGeometry.vertices.length; v++) {
    starAttributes['distance'].value.add(starGeometry.vertices[v].distance);
    starAttributes['color'].value.add(starGeometry.colors[v]);
  }

  starSystem = new ParticleSystem(starGeometry, shaderMaterial);
  universe.add(starSystem);
}

render(num delta) {
  camera.update();
  camera.dramaticEntry(delta);
 
  rotating.update(delta);
  translating.update(delta);
  universe.update(delta);
  
  renderer.render(scene,camera);
  window.animationFrame.then(render);
}