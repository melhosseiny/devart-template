Here are two GIFs of synthetic yet realistic gaze behavior

![Looking down](../project_images/gazegen-lookdown.gif?raw=true "Looking down")

*Downward saccade*

![Looking right then up](../project_images/gazegen-lookrightup.gif?raw=true "Looking right then up")

*A saccade to the right followed by an upward saccade*

Using [scikit-learn](http://scikit-learn.org/stable/), I trained a Gaussian HMM with 9 states (corresponding to 9 points on the screen) on gaze data collected using a Tobii eye tracker. The eye gaze data includes **gaze direction**, **3D eye position** and **pupil diameter**. The HMM model is then sampled to generate artificial eye movements. 

Here's a sample data instance

```
{
    "timestamp" : 1395021750640245,
    "right" : {
        "validity" : 0,
        "gaze_point_3d" : [ 
            2.259748868374572, 
            181.4579186550704, 
            60.00621904831905
        ],
        "gaze_point_2d" : [ 
            0.5043981099033772, 
            0.4595537080197118
        ],
        "pupil" : 2.608810424804688,
        "eye_pos_r" : [ 
            0.3794451155595198, 
            0.4479527997232253, 
            0.49029541015625
        ],
        "eye_pos" : [ 
            40.89783361336958, 
            7.696183277495948, 
            597.0886491385249
        ]
    },
    "left" : {
        "validity" : 0,
        "gaze_point_3d" : [ 
            8.804402651745704, 
            184.3009247375505, 
            61.15886915113038
        ],
        "gaze_point_2d" : [ 
            0.5171358556863197, 
            0.4489731122530429
        ],
        "pupil" : 2.663970947265625,
        "eye_pos_r" : [ 
            0.6076854583395743, 
            0.4560840504705084, 
            0.4794256591794692
        ],
        "eye_pos" : [ 
            -24.60967448821611, 
            5.520645866677796, 
            593.8276883330673
        ]
    }
}
```

and here's the scikit-learn code to train a Gaussian HMM

```
vec = DictVectorizer()
X = vec.fit_transform(gaze_data_from_csv).toarray()
print(X)
model = GaussianHMM(9, 'full')
model.fit([X])
```

You can then generate samples using `model.sample(1000)`

Dart's `dart:io` library natively supports Web Sockets. I emit the data from python to the dart server which then sends it to the dart client in the browser.

```
// python to dart server
ws = create_connection("ws://localhost:8080/ws")
ws.send(json.dumps(sample.tolist()).encode('utf-8'))
```

```
// dart server to dart client
void handleWebSocket(WebSocket socket){
  print('Client connected!');
  sockets.add(socket);
  socket.listen((String s) {
    print('Client sent: $s');
    sockets.forEach((_) => _.add('$s'));
  },
  onDone: () {
    print('Client disconnected');  
  });
}

void main() {
  runZoned(() {
    HttpServer.bind('127.0.0.1', 8080).then((server) {
      server.listen((HttpRequest req) {
        if (req.uri.path == '/ws') {
          WebSocketTransformer.upgrade(req).then(handleWebSocket);
        }
      });
    });
  },
  onError: (e) => print("An error occurred."));
}
```

```
// dart client
var ws = new WebSocket("ws://127.0.0.1:8080/ws");

ws.onMessage.listen((MessageEvent e) {
  var data = JSON.decode(e.data);
}
```