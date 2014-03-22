Here's a storyboard of how the visitor will interact with the portal

![How the visitor will interact with the portal](../project_images/storyboard.png?raw=true "How the visitor will interact with the portal")

The previous posts focused on  creating the audiovisual sequence and generating realistic gaze behavior so that the visitor feels someone is looking back. 

This post will focus on the detection of mutual gaze which in turn triggers the audiovisual sequence (the upper two panels).

## Mutual Gaze Detection

Here's a GIF of the mutual gaze detection algorithm,

![Mutual gaze detection algorithm](../project_images/interaction.gif?raw=true "Mutual gaze detection algorithm")

The algorithm is really simple, here is the Dart implementation (and I will put pseudocode up in the project summary since this is the core interaction):

```
var mousePos = new Point(mouse.x, mouse.y);
mousePos.render(dir.context2D, 'rgba(0,200,0,0.85)');
distance = mousePos.distanceTo(gaze.averageGazePoint2DInCanvas(dir.context2D));
distance = distance / Math.sqrt(Math.pow(window.innerWidth, 2) + Math.pow(window.innerHeight, 2));

// mutual gaze if within 10% of the viewport
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
```

1. Calculate the distance between the human's gaze direction and the ET's gaze direction
2. Normalize the distance relative to the viewport
3. There's mutual gaze if the human's gaze is within 10% of the viewport size from the ET's gaze direction
4. Compute mutual gaze duration in seconds 
5. Start AV sequence when duration reaches a threshold value (3 here)