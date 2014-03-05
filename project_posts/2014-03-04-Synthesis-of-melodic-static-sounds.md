# Synthesis of melodic static sounds

To get started with the Web Audio API, I decided to play a simple melody: an E D B A progression with the notes E F# G B F# G A C played over it in 4/4 time. If you're familiar with music theory, you'll notice that all notes are from the E major scale. Each note is a single sine wave oscillator with an attack-delay envelope.

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971436%3Fsecret_token%3Ds-95aqF&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

I then replaced the notes with randomly generated notes from the E major scale with each note played at a random time.

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971447%3Fsecret_token%3Ds-LtV29&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

I felt that there was a lot going on though, and decided that three notes sounded more appropriate. I also varied the octave of each note to make the sound a bit more interesting.

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971449%3Fsecret_token%3Ds-RjFu9&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

Inspired by the [Deep Note](http://en.wikipedia.org/wiki/Deep_Note), I added more oscillators. As I went from 30 to 150 oscillators, the sound became more eerie and staticy.

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971469%3Fsecret_token%3Ds-oqZGp&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

*30 Oscillators*

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971472%3Fsecret_token%3Ds-22nIo&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

*60 Oscillators*

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971486%3Fsecret_token%3Ds-Qefp8&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

*100 Oscillators*

<iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/137971499%3Fsecret_token%3Ds-NQ9Ff&amp;color=ff5500&amp;auto_play=false&amp;hide_related=false&amp;show_artwork=true"></iframe>

*150 Oscillators*

## Demo

http://www.youtube.com/watch?v=BnJYewFo-Uo

## What's next?

Besides refining the audio/visual effects, I'll be trying to generate seemingly realistic eye movements on the screen.