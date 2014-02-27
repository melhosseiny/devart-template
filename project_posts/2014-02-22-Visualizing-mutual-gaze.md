Using a big dataset seems like a good counterbalance to my limited experience with 3D graphics and WebGL. After reading about [how Michael Chang created](http://www.html5rocks.com/en/tutorials/casestudies/100000stars/) the 100,000 stars project featured on the three.js homepage, I decided to use [astronexus.com](http://astronexus.com/)'s HYG database to render the nebula-like visuals. This is a dataset of 119,617 stars.

The idea is to render every star as a particle and gradually move the camera from an extremely distant position to a closer position. I also perturb the star's position using a noise function and use the star's color index to compute the star's color (by converting from kelvin to rgb).

## Result

![t+1](../project_images/visual/1.png?raw=true "t+1")

![t+2](../project_images/visual/2.png?raw=true "t+2")

![t+3](../project_images/visual/3.png?raw=true "t+3")

![t+4](../project_images/visual/4.png?raw=true "t+4")

![t+5](../project_images/visual/5.png?raw=true "t+5")

![t+6](../project_images/visual/6.png?raw=true "t+6")

## What's next?

I'm going to experiment with additional effects to make the visuals more impressive. I'm also going to look at my options for synthesizing the melodic static using the Web Audio API.