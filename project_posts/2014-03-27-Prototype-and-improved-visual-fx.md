I've put everything together in a [GAE prototype](http://portal-pt.appspot.com/).

1. Make sure you're using the latest Chrome
2. Use your mouse as a fallback for the eye tracker
3. Turn on your speakers/put on your headphones
4. Due to web audio issues, the static sound might not be very staticy
5. The red dot indicating the ET's gaze will not be visible in the final version
6. And also the red mutual gaze indicator

## Changes to the visual effects

### Gaze contingent visual

The visual sequence is now displayed at the human's gaze position. The position slightly changes with changes in the human's gaze direction as they keep looking.

This was accomplished by converting the mouse position from screen coordinates to world coordinates,

```
onDocumentMouseMove(event) {
  mouse.x = (event.client.x).toDouble();
  mouse.y = (event.client.y).toDouble();
  
  // Screen to world: http://stackoverflow.com/questions/13055214
  var vector = new Vector3(( mouse.x / window.innerWidth ) * 2 - 1, - ( mouse.y / window.innerHeight ) * 2 + 1, 0.5);
  var projector = new Projector();
  projector.unprojectVector(vector, camera);
  
  var dir = vector.sub( camera.position ).normalize();
  var distance = - camera.position.z / dir.z;
  if (pos != null)
    pos += (camera.position.clone().add(dir*distance) - pos) * 0.125;
  else
    pos = camera.position.clone().add(dir*distance);
  translating.targetPosition.x = 0.01*pos.x;
  translating.targetPosition.y = 0.01*pos.y;
}
```

### Color shift

The colors are also slightly shifted as the human keeps looking

```
vec4 color = vec4(vColor, 1.0);
vec4 shift = vec4(vShift, 1.0);
vec4 mixed = mix(color, shift, 0.9);
vec4 amixed = vec4(mixed.xyz, vAlpha);
gl_FragColor = amixed;
```

## Demo

View in HD for best quality

https://www.youtube.com/watch?v=4RAbX9EUzQ0