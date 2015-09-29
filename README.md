# Risset Rhythm

## Generating a Risset rhythm with timbral morphing

Risset rhythms are looping rhythms that seem to accelerate indefinitely. They are like a rhythmic version of the [Shepherd tone](https://en.wikipedia.org/wiki/Shepard_tone) illusion. The shephard tone works by building the individual tones out of several octave-related components, and scaling the volume of each component so that they fade to 0 in the low and high ranges. The Risset rhythm works by playing the same clip simultaneously at octave-related tempos, scaling the volume of each so that the fastest and slowest components are the quietest.

Dan Stowell has [posted code](http://swiki.hfbk-hamburg.de/MusicTechnology/826) to turn any sound clip into a Risset rhythm in about a dozen lines in SuperCollider. What do I want to add to this?

My interest is in making a Risset rhythm in which the instrumentation shifts along with the tempo. Suppose the basic sound loop involves a bass drum, snare drum, and hihat, with the following pattern:
```
bass:   |---
snare:  |-|-
hihat:  ||||
```
When the clip has sped up to twice the tempo, the bass will still be playing twice as often. However, if the rhythms are hierarchically related anyway (as they are in this case), what if the bass drum morphed into the sound of a snare drum while it was accelerating, until it sounded exactly like one? Ditto for the snare into the hihat.

## To do

The code currently generates this effect in Matlab using a very, very basic sound generation model. I'd like to improve on it to do more arbitrary morphing (for example, between any points in a 3D timbre space). And maybe rewrite the code to work in Python or something else.
