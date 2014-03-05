# Synthesis of melodic static sounds

To get started with the Web Audio API, I decided to play a simple melody: an E D B A progression with the notes E F# G B F# G A C played over it in 4/4 time. If you're familiar with music theory, you'll notice that all notes are from the E major scale. Each note is a single sine wave oscillator with an attack-delay envelope.

[Soundcloud: Simple tune](https://soundcloud.com/melhosseiny/portal-audio-1-01)

![Simple tune](../project_images/audio/synth1.png?raw=true "Simple tune")

I then replaced the notes with randomly generated notes from the E major scale with each note played at a random time. The notes are random but on one bar they're constrained to be ascending notes and on the next bar they're constrained to be descending notes.

[Soundcloud: Random Notes](https://soundcloud.com/melhosseiny/random-notes-01)

I felt that there was a lot going on though, and decided that three notes sounded more appropriate. I also varied the octave of each note to make the sound a bit more interesting.

[Soundcloud: Random Octaves, Triads](https://soundcloud.com/melhosseiny/random-octaves-triads-01)

![Random Octaves, Triads](../project_images/audio/synth2.png?raw=true "Random Octaves, Triads")

Inspired by the [Deep Note](http://en.wikipedia.org/wiki/Deep_Note), I added more oscillators. As I went from 30 to 150 oscillators, the sound became more eerie and staticy.

![30 Oscillators](../project_images/audio/synth3.png?raw=true "30 Oscillators")

[Soundcloud: *30 Oscillators*](https://soundcloud.com/melhosseiny/30-detuned-varying-freq)

[Soundcloud: *60 Oscillators*](https://soundcloud.com/melhosseiny/60-oscillators-01)

[Soundcloud: *100 Oscillators*](https://soundcloud.com/melhosseiny/100-oscillators-01)

[Soundcloud: *150 Oscillators*](https://soundcloud.com/melhosseiny/150-oscillators-01)

The idea is to start with a large number of oscillators and gradually decrease their number as the visual grows in intensity.

## Demo

View in HD for best quality

http://www.youtube.com/watch?v=BnJYewFo-Uo

## What's next?

Besides refining the audio/visual effects, I'll be trying to generate seemingly realistic eye movements on the screen.