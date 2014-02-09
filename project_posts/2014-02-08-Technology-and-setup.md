Some early thoughts on how I'm going to build this.

## Setup

![Setup](../project_images/setup.jpg?raw=true "Setup")

## Tobii X2-30

I can probably use the relatively inexpensive Tobii X2-30 eye trackers since I don't need perfect accuracy. It is not clear at this point if the extraterrestrials will be simulated or if they will be other visitors, but to get development going on an early prototype I will assume a single display with an attached Tobii X2-30 eye tracker and a simulated extraterrestrial inhabiting that setup. The eye tracker software will run on a computer connected to the eye tracker. 

![Tobii X2](../project_images/x2.jpg?raw=true "Tobii X2")

Source: [Screenshot from Tobii Research & Analysis Youtube Channel](http://www.youtube.com/user/TobiiEyeTracking?feature=watch)

## Bare-bones generative model of gaze behavior

Using existing eye tracking data, I will employ machine learning techniques to generate a generative model of realistic eye movements. I would like to use [scitkit-learn](http://scikit-learn.org) for this. I did machine learning with [Weka](http://www.cs.waikato.ac.nz/ml/weka/) previously but since the eye tracking software is written in Python, it seems like a good idea to use Python for the generative model.

## Node.js/Python Communication (Websockets)

[Code in Python, communicate in Node.js and Socket.IO, present in HTML](http://stackoverflow.com/a/13870294/371309)

## Front-end

I'm considering [Dart](https://www.dartlang.org/) and [AngularDart](https://angulardart.org/) for the OO/libaries features. I enjoy [AngularJS](http://angularjs.org/) very much and was grateful that there was a Dart port. I haven't used Dart before so I'm not sure how it will be integrated with Node.js and if this means that Node.js will have to be replaced by server-side Dart.

## Audio/Visual

Web Audio will be used to create and mix the melodic static and [three.js](http://threejs.org/) will be used to render the nebula-like visuals.