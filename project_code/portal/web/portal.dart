import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'package:json_object/json_object.dart';
import 'dart:web_audio';
import 'package:angular/angular.dart';
import 'dart:async';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(targets: const['gaze'], override: '*')
import 'dart:mirrors';

void main() {
  ngBootstrap(module: new MyAppModule());
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
var context;
var lead;
var rhythm;
var mouse;
var orient;

var starUniforms = {
  //"color": new Uniform.color(0xffffff),
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
  var r = 3.2406 * X - 1.5372 * Y - 0.4986 * Z;
  var g = -0.9689 * X + 1.8758 * Y + 0.0415 * Z;
  var b = 0.0557 * X - 0.2040 * Y + 1.0570 * Z;

  var gma = 0.5;
  
  //linear RGB to sRGB
  var R = (r <= 0.0031308)? 12.92*r : 1.055*Math.pow(r,1/gma)-0.055;
  var G = (g <= 0.0031308)? 12.92*g : 1.055*Math.pow(g,1/gma)-0.055;
  var B = (b <= 0.0031308)? 12.92*b : 1.055*Math.pow(b,1/gma)-0.055;

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
  
  update() => position += (target - position) * 0.125;
  
  dramaticEntry(delta) {
    if (target.z > 10000) {
      // total duration = [(e - b) / c] * d = 98 sec
      target.z = linearTween(delta, 500000, -10000, 2000);
      //target.z = linearTween(delta, 20000, -1000, 2000);
      // c = e / (total duration / d) = e / 49
      
      var vFOV = camera.fov * Math.PI / 180;        // convert vertical fov to radians
      var height = 2 * Math.tan( vFOV / 2 ) * camera.target.z; // visible height

      var aspect = window.innerWidth / window.innerHeight;
      var width = height * aspect;

      var vector = new Vector3(universe.matrixWorld[12], universe.matrixWorld[13], universe.matrixWorld[14]);
      var projector = new Projector();
      projector.projectVector(vector, camera);
      
      if (!vector.x.isNaN) { 
        target.x = linearTween(delta, 0, universe.position.x / 49, 2000);        
      }
      target.y = linearTween(delta, 0, universe.position.y / 49, 2000); 
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
loadStarData() {
  var url = 'data/hygxyz.json';
  var request = HttpRequest.getString(url).then(onStarDataLoaded);
}

onStarDataLoaded(String responseText) {
  starData = new JsonObject.fromJsonString(responseText);
  init();
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
  camera.position.z = 500000.0;
  renderer.render(scene,camera);

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
  
  mouse = new Vector2.zero();
  renderer.domElement.addEventListener( 'mousemove', onDocumentMouseMove, false );
  
  context = new AudioContext();
  
  lead = new Synth();
  rhythm = new Synth();
  orient = new Synth();
}

onDocumentMouseMove(event) {
  event.preventDefault(); 

  mouse.x = (event.clientX).toDouble(); 
  mouse.y = (event.clientY).toDouble(); 
}

var started = false;
var pos;

startSeq() {
  if (started == false) {
    print(mouse);
    
    // Screen to world: http://stackoverflow.com/questions/13055214
    var vector = new Vector3(( mouse.x / window.innerWidth ) * 2 - 1, - ( mouse.y / window.innerHeight ) * 2 + 1, 0.5);
    var projector = new Projector();
    projector.unprojectVector(vector, camera);
  
    var dir = vector.sub( camera.position ).normalize();
    var distance = - camera.position.z / dir.z;  
    pos = camera.position.clone().add(dir*distance);
  
    print(pos);
    window.animationFrame.then(render);
    playStatic();
    started = true;
  }
}


render(num delta) {
  camera.update();
  camera.dramaticEntry(delta);
 
  //rotating.update(delta);
  universe.position.x = pos.x;
  universe.position.y = pos.y;
  //camera.lookAt(universe.position);
  translating.update(delta);
  universe.update(delta);
  
  renderer.render(scene,camera);
  
  lead.activate(((1 - (camera.target.z / 500000)) * 100).toInt());
  rhythm.activate(((1 - (camera.target.z / 500000)) * 100).toInt());
  
  window.animationFrame.then(render);
}

// audio

void playStatic() {  
  var startTime = context.currentTime + 0.100;
  var tempo = 40; // BPM (beats per minute)
  var eighthNoteTime = (60 / tempo) / 2;
  
  for (var bar = 0; bar < 20; bar++) {
    var time = startTime + bar * 8 * eighthNoteTime;
    var rhythmNotes = new Scale('E').getFourRandomNotes(); 
    
    rhythm.playNote(new Note(rhythmNotes[0] + '4'), time);
    rhythm.playNote(new Note(rhythmNotes[1] + '4'), time + 4 * eighthNoteTime);
    
    if (bar.isEven) {
      for (var note in new Scale('E').getRandomAscNotes(3)) {
        lead.playNote(new Note(note+getRandomInt(2,6).toString()), time + getRandomInt(0,8) * eighthNoteTime);
      }
    } else {
      for (var note in new Scale('E').getRandomAscNotes(3)) {
        lead.playNote(new Note(note+getRandomInt(2,6).toString()), time + getRandomInt(0,8) * eighthNoteTime);
      }
    }
  }  
}

void playOrientStatic() {  
  var startTime = context.currentTime + 0.100;
  var tempo = 40; // BPM (beats per minute)
  var eighthNoteTime = (60 / tempo) / 2;
  
  var bar = 0;
  var time = startTime + bar * 8 * eighthNoteTime;
  var rhythmNotes = new Scale('E').getFourRandomNotes(); 
  
  orient.playNote(new Note(rhythmNotes[0] + '4'), time);
  //orient.playNote(new Note(rhythmNotes[1] + '4'), time + 4 * eighthNoteTime);
}

class Scale {
  static final MAJOR = {'C': ['C','D','E','F','G','A','B'],
                        'A': ['A','B','C#','D','E','F#','G#'],
                        'G': ['G','A','B','C','D','E','F#'],
                        'E': ['E','F#','G#','A','B','C#','D#'],
                        'D': ['D','E','F#','G','A','B','C#'],
                        'B': ['B','C#','D#','E','F#','G#','A#'],
                        'F': ['F','G','A','A#','C','D','E'],
                        'D#': ['D#','F','G','G#','A#','C','D']};
  var name;
  
  Scale(this.name);
  
  getNotes() {
    return MAJOR[name];
  }
  
  getRandomAscNotes(howmany) {
    var noteIndexes = [];
    for (var i = 0; i < howmany; i++) {
      noteIndexes.add(getRandomInt(0,6));
    }
    //print(noteIndexes);
    noteIndexes.sort();
    //print('a'+noteIndexes.toString());
    return noteIndexes.map((index) => MAJOR[name][index]);
  }
  
  getRandomDscNotes(howmany) {
    var noteIndexes = [];
    for (var i = 0; i < howmany; i++) {
      noteIndexes.add(getRandomInt(0,6));
    }
    //print(noteIndexes);
    noteIndexes.sort((a,b) => b.compareTo(a));
    //print('d'+noteIndexes.toString());
    return noteIndexes.map((index) => MAJOR[name][index]);
  } 
  
  getFourRandomNotes() {
    MAJOR[name].shuffle();
    return MAJOR[name].sublist(0,4);
  }
  
  getChordNotes() {
    return [MAJOR[name][0],MAJOR[name][2],MAJOR[name][4]];
  }
}

getRandomInt(min, max) {
    return (new Math.Random().nextDouble() * (max - min + 1)).floor() + min;
}

addWobble(osc) {
  var currentFrequency = osc.frequency.value,
      total_wobbles = getRandomInt(0, 4),
      stop_wobbling_time = 0;

  osc.frequency.setValueAtTime(currentFrequency, context.currentTime - 5);
}

makeFilter(osc) {
  var lowpass = context.createBiquadFilter();
  lowpass.type = 'lowpass';
  lowpass.frequency.value = 1000;

  if (osc.frequency.value > 300) {
    lowpass.frequency.setValueAtTime(300, context.currentTime);
    lowpass.frequency.linearRampToValueAtTime(500, context.currentTime + (26 / 2));
    lowpass.frequency.linearRampToValueAtTime(20000, context.currentTime + 1.5 *(26 / 3));
  }

  return lowpass;
}

class Synth {
  var num_of_oscillators = 150;
  var oscillators = [];
  var master_gain;
  var osc_gains = [];
  
  Synth() : super() {
    master_gain = context.createGain();
    master_gain.gain.value = 0;
    
    for (var i = 0; i < num_of_oscillators; i++) {
      var panner = context.createPanner();
      panner.setPosition(getRandomInt(-0.5,0.5),1.0,0.0);
      var oscillator = context.createOscillator();
      var lowpass = makeFilter(oscillator);
      var osc_gain = context.createGain();
  
      addWobble(oscillator);
      oscillator.detune.value = getRandomInt(-20, 20);
      
      osc_gain.gain.value = 0.3;
      
      oscillator.connectNode(panner);
      panner.connectNode(lowpass);
      lowpass.connectNode(osc_gain);
      osc_gain.connectNode(master_gain);
      osc_gains.add(osc_gain);
      oscillator.start(0);
      oscillators.add(oscillator);
    }
    //oscillators.sort();
    master_gain.connectNode(context.destination);
  }
  
  activate(howmany) {
    //print(howmany);
    //print(oscillators.length);
    //print(num_of_oscillators - oscillators.length);
    if (howmany > num_of_oscillators - oscillators.length && howmany < num_of_oscillators - 30) {
      oscillators[oscillators.length - 1].stop(0);
      oscillators.removeLast();
    }
  }
  
  playNote(note, when) {  
    for (var o in osc_gains) {
      o.gain.value = 0.3;
    }
    for (var o in oscillators) {
      o.frequency.setValueAtTime(getRandomInt(note.frequency-20,note.frequency+20), when);
    }
    
    // ar envelope
    //master_gain.gain.cancelScheduledValues(when);
    master_gain.gain.linearRampToValueAtTime(0, when);
    master_gain.gain.linearRampToValueAtTime(1 / num_of_oscillators, when + 1.0);
    master_gain.gain.linearRampToValueAtTime(0, when + 1.0 + 1.5);
  }  
  
  mute(when) {       
    master_gain.gain.cancelScheduledValues(when);
    master_gain.gain.cancelScheduledValues(when + 1.0);
    master_gain.gain.cancelScheduledValues(when + 1.0 + 1.5);
    master_gain.gain.value = 0;

    for (var o in osc_gains) {
      o.gain.value = 0;
    }
  }
  
  log_master_gain_v() {
    print(master_gain.gain.value);
  }
}

class Note {
  var name;
  var frequency;
  var oscillators;
  
  Note(this.name) {
    var notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
        key_number,
        octave = (name.length == 3)? int.parse(name[2]): int.parse(name[1]);

    key_number = notes.indexOf(name.substring(0, name.length-1));

    if (key_number < 3) {
        key_number = key_number + 12 + ((octave - 1) * 12) + 1;
    } else {
        key_number = key_number + ((octave - 1) * 12) + 1;
    }

    this.frequency = 440 * Math.pow(2, (key_number - 49) / 12);
    this.oscillators = [];
  }
}

// gaze
var gaze;

@NgController(
  selector: '[gaze]',
  publishAs: 'ctrl')
class GazeCtrl {
  var gazeData;
  Gaze gaze;
  CanvasElement dir;
  CanvasElement eyes;
  var t = 0;
  var distance;
  var mutualGaze; // from 0 to 1
  var mutualGazeDuration;
  
  GazeCtrl() {
    loadGazeData();
    dir = querySelector('#a');
    dir.setAttribute('width', window.innerWidth.toString() + 'px');
    dir.setAttribute('height', window.innerHeight.toString() + 'px');
  
    window.animationFrame.then(render);
  }   
  
  onGazeDataLoaded(String responseText) {
    gazeData = new JsonObject.fromJsonString(responseText);     
    gazeBehave();
    loadStarData();
    var rectLength = 120.0, rectWidth = 40.0;
  }
  
  loadGazeData() {
    var url = 'data/gaze.json';
    var request = HttpRequest.getString(url).then(onGazeDataLoaded);
  }
  
  gazeBehave() {
    if (!started) {
      for (var g in gazeData) {
        
        new Future.delayed(new Duration(milliseconds:t), () {
          if (!started) {
            //print(g);
            if (gaze != null) {
              gaze = new Gaze(new JsonObject.fromMap({
                "right" : {
                  "validity" : 0,
                  "gaze_point_2d" : [ 
                     gaze.data.right.gaze_point_2d[0] + (g.right.gaze_point_2d[0] - gaze.data.right.gaze_point_2d[0]) * 0.05, 
                     gaze.data.right.gaze_point_2d[1] + (g.right.gaze_point_2d[1] - gaze.data.right.gaze_point_2d[1]) * 0.05
                   ]
                },
                "left" : {
                  "validity" : 0,
                  "gaze_point_2d" : [ 
                     gaze.data.left.gaze_point_2d[0] + (g.left.gaze_point_2d[0] - gaze.data.left.gaze_point_2d[0]) * 0.05,
                     gaze.data.left.gaze_point_2d[1] + (g.left.gaze_point_2d[1] - gaze.data.left.gaze_point_2d[1]) * 0.05
                 ]
                }
              })
              ); 
            } else {
              gaze = new Gaze(g);
            }
          }
        });
        t += 30;
      }
      new Future.delayed(new Duration(milliseconds:t), () {
        t = 0;
        gazeBehave();
      });
    }
  }
  
  var startDelta;
  var counterStarted = false;
  
  render(num delta) {    
    if (gaze != null) {
      dir.context2D.fillStyle = 'rgb(0,0,0)';
      dir.context2D.fillRect(0,0,dir.context2D.canvas.width,dir.context2D.canvas.height);
      gaze.renderDirection(dir.context2D);
      

      if (mouse != null) {
        var mousePos = new Point(mouse.x, mouse.y);
        mousePos.render(dir.context2D, 'rgba(0,200,0,0.85)');
        distance = mousePos.distanceTo(gaze.averageGazePoint2DInCanvas(dir.context2D));
        distance = distance / Math.sqrt(Math.pow(window.innerWidth, 2) + Math.pow(window.innerHeight, 2));
        
        // more mutual gaze if within 100px for more time
        mutualGaze = 1 - distance;
        if (mutualGaze > 0.9) {
          if (!counterStarted) {
            startDelta = delta;
            if (!started) playOrientStatic();
            counterStarted = !counterStarted;
          }
          mutualGazeDuration = (delta - startDelta) / 1000; // in seconds
        } else {
          // reset
          if (!started) orient.mute(delta);
          mutualGazeDuration = 0;
          counterStarted = false;
        }
        
        // if there's mutual gaze for more than t seconds
        if (mutualGazeDuration > 3) {
          startSeq();
        }

        var opacity = mutualGazeDuration / 3;
        var mutualCir = new Circle(mouse.x, mouse.y, 100);
        mutualCir.render(dir.context2D, 'rgba(200,0,0,' + opacity.toString() + ')');
        
        orient.log_master_gain_v();
      }
    }
    window.animationFrame.then(render);
  }
}

class Gaze {
  var data;
  
  Gaze(this.data);
  
  static final MAX_AGE = 100.0;
  
  static relative(a, x, b) {
    return (x - a) / (b - a);
  }
  
  static renderEye(context, eye) {
    var age = 0;
    
    var eye_radius = 0.05 * context.canvas.width;
    var iris_radius = 0.5 * eye_radius;
    var pupil_radius = relative(1,eye.pupil,5) * iris_radius / 2;

    var gaze_point_2d = [(eye.gaze_point_2d[0]*context.canvas.width - context.canvas.width / 2) * 2,(eye.gaze_point_2d[1]*0.99*context.canvas.height - 0.99*context.canvas.height / 2) * 2];
    var eye_pos_r = [eye.eye_pos_r[0]*context.canvas.width,eye.eye_pos_r[1]*0.99*context.canvas.height];
    
    var opacity = 1 - age * 1.0 / MAX_AGE;
    if (eye.validity <= 1) {
      context.fillStyle = 'rgba(255,255,255,'+opacity.toString()+')';
      context.beginPath();
      context.arc(context.canvas.width - eye_pos_r[0], eye_pos_r[1], eye_radius, 0, 2 * Math.PI);
      context.fill();

      context.fillStyle = 'rgba(128,128,128,'+opacity.toString()+')';
      context.beginPath();
      context.arc(context.canvas.width - eye_pos_r[0] + 0.01*gaze_point_2d[0], eye_pos_r[1] + 0.01*gaze_point_2d[1], iris_radius, 0, 2 * Math.PI);
      context.fill();

      context.fillStyle = 'rgba(0,0,0,'+opacity.toString()+')';
      context.beginPath();
      context.arc(context.canvas.width - eye_pos_r[0] + 0.01*gaze_point_2d[0], eye_pos_r[1] + 0.01*gaze_point_2d[1], pupil_radius, 0, 2 * Math.PI);
      context.fill();
    }
  }
  
  averageGazePoint2D() {
    var lx = this.data.left.gaze_point_2d[0];
    var ly = this.data.left.gaze_point_2d[1];
    var rx = this.data.right.gaze_point_2d[0];
    var ry = this.data.right.gaze_point_2d[1];

    return (new Point(lx,ly) + new Point(rx,ry)) * 0.5;
  }
  
  averageGazePoint2DInCanvas(context) {
    var a = averageGazePoint2D();

    return new Point(a.x*context.canvas.width, a.y*context.canvas.height);
  }
  
  renderDirection(context, {fillStyle: 'rgba(200,0,0,0.85)'}) {
    var a = averageGazePoint2D();
    
    new Point(a.x*context.canvas.width, a.y*context.canvas.height).render(context, fillStyle);
  }
  
  renderEyes(context) {
    renderEye(context, this.data.left);
    renderEye(context, this.data.right);
  }
}

class Point extends Math.Point {
  Point(x, y): super(x, y);
  
  render(context, fillStyle) {
    context.fillStyle = fillStyle;
    context.fillRect(this.x, this.y, 0.01*context.canvas.width, 0.01*context.canvas.width);
  }
}

class Circle extends Math.Point {
  var r;
  
  Circle(x, y, this.r): super(x, y);
  
  render(context, fillStyle) {
    context.fillStyle = fillStyle;
    context.beginPath();
    context.arc(this.x, this.y, this.r, 0, 2 * Math.PI);
    context.fill();
  }
}

class MyAppModule extends Module {
  MyAppModule() {
    type(GazeCtrl);
  }
}