import 'dart:io';
import 'dart:async';
import 'dart:convert';

List<WebSocket> sockets = [];

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

