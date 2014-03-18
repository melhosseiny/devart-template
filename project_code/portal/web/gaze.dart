import 'dart:html';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:angular/angular.dart';
import 'package:json_object/json_object.dart';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(targets: const['gaze'], override: '*')
import 'dart:mirrors';

var gaze;

@NgController(
  selector: '[gaze]',
  publishAs: 'ctrl')
class GazeCtrl {
  Gaze gaze;
  CanvasElement dir;
  CanvasElement eyes;
  
  GazeCtrl() {
    var ws = new WebSocket("ws://127.0.0.1:8080/ws");
    
    ws.onMessage.listen((MessageEvent e) {
      var data = JSON.decode(e.data);
      if (gaze != null) {
        gaze = new Gaze(new JsonObject.fromMap({
         "right" : {
           "validity" : 0,
           "gaze_point_2d" : [ 
              gaze.data.right.gaze_point_2d[0] + (data[0] - gaze.data.right.gaze_point_2d[0]) * 0.05, 
              gaze.data.right.gaze_point_2d[1] + (data[1] - gaze.data.right.gaze_point_2d[1]) * 0.05
            ],
          "pupil" : gaze.data.right.pupil + (data[2] - gaze.data.right.pupil) * 0.05,
          "eye_pos_r" : [
               gaze.data.right.eye_pos_r[0] + (data[3] - gaze.data.right.eye_pos_r[0]) * 0.05, 
               gaze.data.right.eye_pos_r[1] + (data[4] - gaze.data.right.eye_pos_r[1]) * 0.05,
               gaze.data.right.eye_pos_r[2] + (data[5] - gaze.data.right.eye_pos_r[2]) * 0.05
             ]
           },
         "left" : {
         "validity" : 0,
         "gaze_point_2d" : [ 
            gaze.data.left.gaze_point_2d[0] + (data[6] - gaze.data.left.gaze_point_2d[0]) * 0.05,
            gaze.data.left.gaze_point_2d[1] + (data[7] - gaze.data.left.gaze_point_2d[1]) * 0.05
          ],
          "pupil" : gaze.data.left.pupil + (data[8] - gaze.data.left.pupil) * 0.05,
          "eye_pos_r" : [
             gaze.data.left.eye_pos_r[0] + (data[9] - gaze.data.left.eye_pos_r[0]) * 0.05, 
             gaze.data.left.eye_pos_r[1] + (data[10] - gaze.data.left.eye_pos_r[1]) * 0.05,
             gaze.data.left.eye_pos_r[2] + (data[11] - gaze.data.left.eye_pos_r[2]) * 0.05
           ]
          }
        })
       ); 
      } else {
        gaze = new Gaze(new JsonObject.fromMap({
          "right" : {
            "validity" : 0,
            "gaze_point_2d" : [ 
               data[0], 
               data[1]
             ],
             "pupil" : data[2],
             "eye_pos_r" : [
                data[3],
                data[4],
                data[5]
              ]
          },
          "left" : {
            "validity" : 0,
            "gaze_point_2d" : [ 
               data[6],
               data[7]
             ],
           "pupil" : data[8],
           "eye_pos_r" : [
              data[9],
              data[10],
              data[11]
            ]
          }
      }));
      }
      dir = querySelector('#a');
      eyes = querySelector('#b');
      //print('Received message: ${JSON.decode(e.data)}');
    });
    
    window.animationFrame.then(render);
  }
  
  render(num delta) {
    if (gaze != null) {
      dir.context2D.fillStyle = 'rgb(0,0,0)';
      dir.context2D.fillRect(0,0,dir.context2D.canvas.width,dir.context2D.canvas.height);
      eyes.context2D.fillStyle = 'rgb(0,0,0)';
      eyes.context2D.fillRect(0,0,eyes.context2D.canvas.width,eyes.context2D.canvas.height);
      gaze.renderDirection(dir.context2D);
      gaze.renderEyes(eyes.context2D);
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

void main() {
  ngBootstrap(module: new MyAppModule());
}