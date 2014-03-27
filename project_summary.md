# Portal

## Authors
- Mostafa Elshamy, https://github.com/melhosseiny
  
## Description

Why do we explore space? What are we trying to find? What if what we’re looking for starts looking back at us?

Visitors are invited to gaze at a blank display with an attached eye tracker. It is like a portal to other worlds. Using a small control knob, they can adjust the portal to receive gaze from different points in spacetime.

It is blocked so that no one can enter but if two beings looking from both ends make eye contact, they can feel the presence of one another. They can hear faint static and see light that grows in intensity and beauty as they keep looking.

## Link to Prototype
NOTE: Use your mouse as fallback for the eye tracker.

[Prototype](http://portal-pt.appspot.com/ "Prototype")-->

## Example Code
NOTE: This is pseudocode, see below or look at the source for the Dart implementation.
```
THRESHOLD_MG_DURATION = 3

viewport_diagonal_length = sqrt(pow(viewport_width, 2) + pow(viewport_height, 2)) 
distance = human_gaze_position.distance_to(ET_gaze_position)
mutual_gaze = 1 - distance

if mutual_gaze > 0.9 // mutual gaze if within 10% of the viewport
  if (!timer_started)
    orientation_synth.play(delta)
    start_delta = delta
    timer_started = !timer_started
  duration = delta - start_delta / 1000 // delta in milliseconds
else
  // reset timer
  orientation_synth.mute(delta)
  duration = 0
  timer_started = !timer_started

// if there's mutual gaze for more than t seconds
if duration > THRESHOLD_MG_DURATION
  start_sequence()
```

![Mutual gaze detection algorithm](../project_images/interaction.gif?raw=true "Mutual gaze detection algorithm")

## Links to External Libraries

 - [three.dart](http://threedart.github.io/three.dart/ "Dart port of three.js")
 - [AngularDart](https://angulardart.org/ "Dart port of AngularJS")
 - [scikit-learn](http://scikit-learn.org/stable/ "Machine Learning in Python")
 - [webgl-noise](https://github.com/ashima/webgl-noise "Procedural Noise Shader Routines compatible with WebGL")

## Images & Videos

https://www.youtube.com/watch?v=4RAbX9EUzQ0

![Looking right then up](../project_images/gazegen-lookrightup.gif?raw=true "Looking right then up")