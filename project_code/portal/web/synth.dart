import 'dart:math' as Math;
import 'dart:web_audio';

var context;
var lead;
var rhythm;

void main() {
  context = new AudioContext();
  
  lead = new Synth();
  rhythm = new Synth();
  
  // Solo E F# G B - F# G A C B
  // Rhythm E D B A
  // We'll start playing the rhythm 100 milliseconds from "now"
  var startTime = context.currentTime + 0.100;
  var tempo = 40; // BPM (beats per minute)
  var eighthNoteTime = (60 / tempo) / 2;
  
  for (var bar = 0; bar < 20; bar++) {
    var time = startTime + bar * 8 * eighthNoteTime;
    var rhythmNotes = new Scale('E').getFourRandomNotes();    
    print(rhythmNotes);
    
    rhythm.playNote(new Note(rhythmNotes[0] + '4'), time);
    rhythm.playNote(new Note(rhythmNotes[1] + '4'), time + 4 * eighthNoteTime);
    //rhythm.playNote(new Note(rhythmNotes[2] + '4'), time + 6 * eighthNoteTime);

    /*rhythm.playNote(new Note('E4'), time);
    rhythm.playNote(new Note('D4'), time + 4 * eighthNoteTime);
    rhythm.playNote(new Note('B3'), time + 6 * eighthNoteTime);    
    rhythm.playNote(new Note('A3'), time + 8 * eighthNoteTime);
    
    lead.playNote(new Note('E4'), time);
    lead.playNote(new Note('F#4'), time + 1 * eighthNoteTime);
    lead.playNote(new Note('G4'), time + 3 * eighthNoteTime);
    lead.playNote(new Note('B4'), time + 4 * eighthNoteTime);
    lead.playNote(new Note('F#4'), time + 5* eighthNoteTime);
    lead.playNote(new Note('G4'), time + 6 * eighthNoteTime);
    lead.playNote(new Note('A4'), time + 7 * eighthNoteTime);
    lead.playNote(new Note('C4'), time + 8 * eighthNoteTime);*/
    
    if (bar.isEven) {
      for (var note in new Scale('E').getRandomAscNotes(3)) {
        lead.playNote(new Note(note+getRandomInt(2,6).toString()), time + getRandomInt(0,8) * eighthNoteTime);
      }
    } else {
      for (var note in new Scale('E').getRandomAscNotes(3)) {
        lead.playNote(new Note(note+getRandomInt(2,6).toString()), time + getRandomInt(0,8) * eighthNoteTime);
      }
    }
    print(lead.oscillators.length);
  }
}
class Scale {
  static final MAJOR = {'C': ['C','D','E','F','G','A','B'],
                        'A': ['A','B','C#','D','E','F#','G#'],
                        'G': ['G','A','B','C','D','E','F#'],
                        'E': ['E','F#','G#','A','B','C#','D#'],
                        'D': ['D','E','F#','G','A','B','C#'],
                        'B': ['B','C#','D#','E','F#','G#','A#'],
                        'F': ['F','G','A','A#','C','D','E'],
                        'D#': ['D#','F','G','G#','A#','C','D']};
  var name;
  
  Scale(this.name);
  
  getNotes() {
    return MAJOR[name];
  }
  
  getRandomAscNotes(howmany) {
    var noteIndexes = [];
    for (var i = 0; i < howmany; i++) {
      noteIndexes.add(getRandomInt(0,6));
    }
    //print(noteIndexes);
    noteIndexes.sort();
    //print('a'+noteIndexes.toString());
    return noteIndexes.map((index) => MAJOR[name][index]);
  }
  
  getRandomDscNotes(howmany) {
    var noteIndexes = [];
    for (var i = 0; i < howmany; i++) {
      noteIndexes.add(getRandomInt(0,6));
    }
    //print(noteIndexes);
    noteIndexes.sort((a,b) => b.compareTo(a));
    //print('d'+noteIndexes.toString());
    return noteIndexes.map((index) => MAJOR[name][index]);
  } 
  
  getFourRandomNotes() {
    MAJOR[name].shuffle();
    return MAJOR[name].sublist(0,4);
  }
  
  getChordNotes() {
    return [MAJOR[name][0],MAJOR[name][2],MAJOR[name][4]];
  }
}

getRandomInt(min, max) {
    return (new Math.Random().nextDouble() * (max - min + 1)).floor() + min;
}

addWobble(osc) {
  var currentFrequency = osc.frequency.value,
      total_wobbles = getRandomInt(0, 4),
      stop_wobbling_time = 0;

  osc.frequency.setValueAtTime(currentFrequency, context.currentTime - 5);
}

makeFilter(osc) {
  var lowpass = context.createBiquadFilter();
  lowpass.type = 'lowpass';
  lowpass.frequency.value = 1000;

  if (osc.frequency.value > 300) {
    lowpass.frequency.setValueAtTime(300, context.currentTime);
    lowpass.frequency.linearRampToValueAtTime(500, context.currentTime + (26 / 2));
    lowpass.frequency.linearRampToValueAtTime(20000, context.currentTime + 1.5 *(26 / 3));
  }

  return lowpass;
}

class Synth {
  var num_of_oscillators = 30;
  var oscillators = [];
  var master_gain;
  
  Synth() : super() {
    master_gain = context.createGain();
    master_gain.gain.value = 0;
    
    for (var i = 0; i < num_of_oscillators; i++) {
      var panner = context.createPanner();
      panner.setPosition(getRandomInt(-0.5,0.5),1.0,0.0);
      var oscillator = context.createOscillator();
      var lowpass = makeFilter(oscillator);
      var osc_gain = context.createGain();
  
      addWobble(oscillator);
      oscillator.detune.value = getRandomInt(-20, 20);
      
      osc_gain.gain.value = 0.3;
      
      var type = getRandomInt(0,3);
      oscillator.type = 'triangle';
      /*if (type == 1) oscillator.type = 'square';
      else if (type == 2) oscillator.type = 'sawtooth';
      else if (type == 3) oscillator.type = 'triangle';*/
      oscillator.connectNode(panner);
      panner.connectNode(lowpass);
      lowpass.connectNode(osc_gain);
      osc_gain.connectNode(master_gain);
      oscillator.start(0);
      oscillators.add(oscillator);
    }
    //oscillators.sort();
    master_gain.connectNode(context.destination);
  }
  
  activate(howmany) {
    //print(howmany);
    //print(oscillators.length);
    //print(num_of_oscillators - oscillators.length);
    if (howmany > num_of_oscillators - oscillators.length && howmany < num_of_oscillators - 30) {
      oscillators[oscillators.length - 1].stop(0);
      oscillators.removeLast();
    }
  }
  
  playNote(note, when) {
    for (var o in oscillators) {
      o.frequency.setValueAtTime(getRandomInt(note.frequency-20,note.frequency+20), when);
      
      // ar envelope
      //master_gain.gain.cancelScheduledValues(when);
      master_gain.gain.linearRampToValueAtTime(0, when);
      master_gain.gain.linearRampToValueAtTime(1 / num_of_oscillators, when + 1.0);
      master_gain.gain.linearRampToValueAtTime(0, when + 1.0 + 1.5);
    }
  }
}

class Note {
  var name;
  var frequency;
  var oscillators;
  
  Note(this.name) {
    var notes = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
        key_number,
        octave = (name.length == 3)? int.parse(name[2]): int.parse(name[1]);

    key_number = notes.indexOf(name.substring(0, name.length-1));

    if (key_number < 3) {
        key_number = key_number + 12 + ((octave - 1) * 12) + 1;
    } else {
        key_number = key_number + ((octave - 1) * 12) + 1;
    }

    this.frequency = 440 * Math.pow(2, (key_number - 49) / 12);
    this.oscillators = [];
  }
}