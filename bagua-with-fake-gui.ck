//-----------------------------------------------------------------------------
// name: Harmony_Clock.ck
// desc: Control harmonic cycle with colors
// 
// author: Tao-Tao He
// date: Oct. 20, 2026
//-----------------------------------------------------------------------------

@import "chodash";

GG.camera().orthographic(); // 2d scene, set camera to orthographic

// Main color
vec3 MAIN_COLOR;
@(0.6, 1.0, 1.0) @=> MAIN_COLOR;

// Sampling Rate
44100 => int SR;
// Default speed
120 => global float BPM;
// Default scale
1.0 => float SCALE;

// Major 7th chord blue
// Minor 7th chord yellow
// Dominant chord green
// Minor-major chord red
// Half-Diminished chord purple
// Diminished chord orange

// Copy-pasted from circles.ck
// creating a custom GGen class for a 2D circle
public class Circle extends GGen
{
    // for drawing our circle 
    GLines circle --> this;
    // randomize rate
    Math.random2f(2,3) => float rate;
    // default color
    color( @(.8, .8, 1) );
    // default line width
    circle.width(.1);

    // initialize a circle
    fun void Circle( int resolution, float radius )
    {
        // incremental angle from 0 to 2pi in N-2 step, plus to steps to close the line loop
        2*pi / (resolution-2) => float theta;    
        // positions of our circle
        vec2 pos[resolution];
        // previous, init to 1 zero
        @(radius) => vec2 prev;
        // loop over vertices
        for( int i; i < pos.size(); i++ )
        {
            // rotate our vector to plot a circle
            // https://en.wikipedia.org/wiki/Rotation_matrix
            Math.cos(theta)*prev.x - Math.sin(theta)*prev.y => pos[i].x;
            Math.sin(theta)*prev.x + Math.cos(theta)*prev.y => pos[i].y;
            // remember v as the new previous
            pos[i] => prev;
        }
        
        // set positions
        circle.positions( pos );
    }
    
    fun void color( vec3 c )
    {
        circle.color( c );
    }

    fun void width( float w )
    {
        circle.width( w );
    }
}

// Copy-pasted from circles.ck
// creating a custom GGen class for a 2D circle
public class HalfCircle extends GGen
{
    // for drawing our circle 
    GLines circle --> this;
    // randomize rate
    Math.random2f(2,3) => float rate;
    // default color
    color( @(.8, .8, 1) );

    // initialize a circle
    fun void HalfCircle( int resolution, float radius )
    {
        // incremental angle from 0 to 2pi in N-2 step, plus to steps to close the line loop
        2*pi / (resolution-2) => float theta;    
        // positions of our circle
        vec2 pos[resolution/2];
        // previous, init to 1 zero
        @(radius) => vec2 prev;

        // loop over vertices
        for( int i; i < pos.size(); i++ )
        {
            // rotate our vector to plot a circle
            // https://en.wikipedia.org/wiki/Rotation_matrix
            Math.cos(theta)*prev.x - Math.sin(theta)*prev.y => pos[i].x;
            Math.sin(theta)*prev.x + Math.cos(theta)*prev.y => pos[i].y;
            // remember v as the new previous
            pos[i] => prev;
        }

        // @(0,0) => pos[pos.size()-1];
        
        // set positions
        circle.positions( pos );
    }
    
    fun void color( vec3 c )
    {
        circle.color( c );
    }

    fun void width( float w )
    {
        circle.width( w );
    }
}

// The center taichi; spins and controls overall sound
public class taichi extends GGen 
{
    fun taichi(float scale)
    {
        // Width
        scale / 48 => float width;
        
        // The main circle
        Circle bigCir(128, 1) --> this;
        bigCir.color(@(0.6, 1.0, 1.0));
        bigCir.sca(scale);
        bigCir.width(width);
        @( 0,0,0 ) => bigCir.pos;

        // The half circles
        HalfCircle halfCirOne(128, 1) --> this;
        halfCirOne.color(@(0.6, 1.0, 1.0));
        halfCirOne.sca(scale/2);
        halfCirOne.width(width*1.4);
        // halfCirOne.width(10);
        @( scale/2,0,0 ) => halfCirOne.pos;

        // The half circles
        HalfCircle halfCirTwo(128, 1) --> this;
        halfCirTwo.color(@(0.6, 1.0, 1.0));
        halfCirTwo.sca(scale/2);
        halfCirTwo.width(width*1.4);
        @( -scale/2,0,0 ) => halfCirTwo.pos;
        halfCirTwo.rotateZ(pi);

        // The small circles
        Circle smallCirOne(128, 1) --> this;
        smallCirOne.color(@(0.6, 1.0, 1.0));
        smallCirOne.sca(scale/20);
        smallCirOne.width(width*8);
        @( scale/2+width*1.5, -width, 0 ) => smallCirOne.pos;

        // The small circles
        Circle smallCirTwo(1024, 1) --> this;
        smallCirTwo.color(@(0.6, 1.0, 1.0));
        smallCirTwo.sca(scale/20);
        smallCirTwo.width(0.5);
        @( -scale/2-width*1.5, width, 0 ) => smallCirTwo.pos;
    }
}

// The chord that is embodied by the GUA
public class Chord
{
    // Gives the arpeggio notes according to chord type, root note, and inversion
    fun int[] getArp(string type, int r, int inv)
    {
        int temp[8];
        int arp[8];
        inv => int i;
        
        // Prepare two octaves worth of arpeggio notes according to chord type
        if(type == "maj7")
        {
            [0,4,7,11,12,16,19,23] @=> temp;
        }
        else if(type == "min7")
        {
            [0,3,7,10,12,15,19,22] @=> temp;
        }
        else if(type == "dom7")
        {
            [0,4,7,10,12,16,19,22] @=> temp;
        }
        else if(type == "hdim7")
        {
            [0,3,6,10,12,15,18,22] @=> temp;
        }
        else if(type == "dim7")
        {
            [0,3,6,9,12,15,18,21] @=> temp;
        }
        else // minor major 7th
        {
            [0,3,7,11,12,15,19,23] @=> temp;
        }

        // According to root and inversion, identify actual notes
        temp[i] + r => arp[0];
        temp[i+1] + r => arp[1];
        temp[i+2] + r => arp[2];
        temp[i+3] + r => arp[3];
        temp[i+4] + r => arp[4];
        temp[i+3] + r => arp[5];
        temp[i+2] + r => arp[6];
        temp[i+1] + r => arp[7];

        return arp;
    }

    // Gives the bass notes based on the root note
    fun int[] getBass(int r, int depth)
    {
        return [r-12*depth,r-12*(depth+1)];
    }
    
    string type; // What type of 7th chord? e.g. Major 7th
    int root; // What's the root note?
    int inversion; // What inversion is the chord?
    float modArp; // What's the modulation value of the chord?
    float gainArp; // What's the amplitude of the chord?
    float modBass; // What's the modulation value of the bass?
    float gainBass; // What's the amplitude of the bass?
    int depth; // how deep is the bass?
    int arpeggio[8]; // What notes are in the arpeggio?
    int bassNotes[2]; // What notes are in the bass?

    // Initializes chord
    fun void Chord(string type, int r, int inv, float ma, float ga, float mb, float gb, int d)
    {
        type => this.type;
        r => this.root;
        inv => this.inversion;
        ma => this.modArp;
        ga => this.gainArp;
        mb => this.modBass;
        gb => this.gainBass;
        d => this.depth;

        getArp(type, r, inv) @=> arpeggio;
        getBass(r, d) @=> bassNotes;
    }

    // Function for playing a note
    fun void playNote(int midiNote, float gain, float mod, dur length)
    {
        Wurley osc => NRev rev => dac;
        gain => osc.gain;
        Std.mtof(midiNote) => osc.freq; // Converts MIDI note to frequency
        0.8 => rev.gain;
        0.5 => osc.noteOn;
        length => now;
        0.5 => osc.noteOff;
    }

    // Function for getting the chord to make sound
    fun void playChord()
    {
        1::minute / BPM / 4 => dur quarterBeat; // define duration of each arpeggio note
        
        // Play bass notes
        spork ~playNote(this.bassNotes[0], this.gainBass, this.modBass, quarterBeat*8);
        spork ~playNote(this.bassNotes[1], this.gainBass, this.modBass, quarterBeat*8);

        for(int note : this.arpeggio)
        {
            playNote(note, this.gainArp, this.modArp, quarterBeat);
            quarterBeat => now; // play one note at a time; advances time
        }
    }

    fun string gettype() { return type; }
    fun int getroot() { return root; }
    fun int getinversion() { return inversion; }
    fun float getmodArp() { return modArp; }
    fun float getgainArp() { return gainArp; }
    fun float getmodBass() { return modBass; }
    fun float getgainBass() { return gainBass; }
    fun int getdepth() { return depth; }
}

// Visualizer: 八卦阵
public class GUA extends GGen
{
    // Initialize the 3 rectangles
    GCube top --> this;
    GCube mid --> this;
    GCube bottom --> this;
    color( @(.6, 1, 1) );
    // Initialize chord
    Chord myChord;
    
    // fun void GUA(float[] pos, int[] splits, chord initChord)
    fun void GUA(int angle, float scale)
    {
        // Set the amount to rotate
        pi/4*(angle-0.5) => float rad;
        
        // Set the position of the Gua according to the angle
        top.pos(@(0, scale * 1.5, 0));
        mid.pos(@(0, scale * 1.38, 0));
        bottom.pos(@(0, scale * 1.26, 0));
        // Set the shape of the rectangles
        top.scaX(scale * 0.9);
        mid.scaX(scale * 0.75);
        bottom.scaX(scale * 0.6);
        top.scaY(scale / 60);
        mid.scaY(scale / 60);
        bottom.scaY(scale / 60);
        // Rotate the Gua
        this.rotateZ(rad);
    }

    fun void color( vec3 c )
    {
        top.color( c );
        mid.color( c );
        bottom.color( c );
    }

    // Updates the chord associated with the GUA
    fun void updateChord(string type, int r, int inv, float ma, float ga, float mb, float gb, int d)
    {
        Chord newChord(type, r, inv, ma, ga, mb, gb, d) @=> this.myChord;
    }

    // If the function directly inputs a new chord
    fun void updateChord(Chord newChord)
    {
        newChord @=> this.myChord;
    }

    // Plays the chord associated with the GUA
    fun void playChord()
    {
        this.myChord.playChord();
    }
}
// initChord => chord this.mychord;
// if(clicks) {updateChord => this.mychord}
// fun playChord()

// Rotating genie
public class genie extends GGen
{
    // an array of our custom circles
    Circle circles[3000];
    
    fun void genie(float scale)
    {
        // Kinda copy-pasted from circles.ck
        0 => int i;
        // iterate over circles array
        while( i < 3000 )
        {
            // initialize each 
            // connect it
            Circle circ(128, 0.001) @=> circles[i];
            i++;
            // randomize location in XYZ, but make it curvy
            Math.random2f(-0.5,0.001)*Math.random2f(0,5)*Math.random2f(0,1)+Math.sin(pi/3000*i)*0.05 => float x;
            Math.random2f(-0.02,0.02) + scale * 0.1 + Math.cos(pi/3000*i)*0.05 + Math.cos(x/2.0/scale)*2.0*scale => float y;

            @( x,y,0 ) => circ.pos;
            // make circle thin
            circ.width(0.01);
        }

        for(Circle c : circles)
        {
            c --> this; // Connect each circle to the genie object
        }
    }

    // Re-define rotateZ here, to add movement in the particles
    fun void rotaZ(float speed)
    {
        for(Circle c : circles)
        {
            // randomize tiny movement
            Math.random2f(-0.002,0.002) => float xmov;
            Math.random2f(-0.002,0.002) => float ymov;

            xmov + c.posX() => c.posX;
            ymov + c.posY() => c.posY;
        }
        this.rotateZ(speed);
    }
}

public class chordGUI extends GGen
{
    // Initialize interface
    GCube outBox --> this;
    GCube inBox --> this;
    GCube cancelBox --> this;
    GCube okBox --> this;
    GCube plusBox --> this;
    GCube minusBox --> this;
    GText rootBox --> this;
    GText plus --> this;
    GText minus --> this;
    GCircle inv0 --> this;
    GCircle inv1 --> this;
    GCircle inv2 --> this;
    GCircle inv3 --> this;
    GText maj7 --> this;
    GText min7 --> this;
    GText dom7 --> this;
    GText dim7 --> this;
    GText hdim7 --> this;
    GText mmaj7 --> this;
    GText title --> this;
    GText chordType --> this;
    GText invType --> this;
    GText rtPs --> this;
    GText fInv --> this;
    GText sInv --> this;
    GText tInv --> this;
    GText rNote --> this;
    GText okay --> this;
    GText canc --> this;

    // Design interface: outter boxes
    outBox.pos(@(3.55,0,-0.1));
    inBox.pos(@(3.55,0,-0.09));
    outBox.scaY(5);
    outBox.scaX(2.7);
    outBox.scaZ(0.001);
    inBox.scaY(4.9);
    inBox.scaX(2.6);
    inBox.scaZ(0.001);
    outBox.color(@(0.2,0.2,0.2));
    inBox.color(@(0.01,0.01,0.01));
    // Title text
    title.text("Chord GUI");
    title.pos(@(3.55, 2.15, 0));
    title.sca(0.2);
    // Chord boxes
    chordType.text("Chord Type");
    maj7.text("Major 7th");
    min7.text("Minor 7th");
    dom7.text("Dominant 7th");
    dim7.text("Diminished 7th");
    hdim7.text("Half-Diminished 7th");
    mmaj7.text("Minor-Major 7th");
    maj7.sca(0.1);
    min7.sca(0.1);
    dom7.sca(0.1);
    dim7.sca(0.1);
    hdim7.sca(0.1);
    mmaj7.sca(0.1);
    chordType.sca(0.13);
    chordType.pos(@(3.0,1.9,0));
    maj7.pos(@(3.0,1.75,0));
    min7.pos(@(3.0,1.65,0));
    dom7.pos(@(3.0,1.54,0));
    dim7.pos(@(3.0,1.43,0));
    hdim7.pos(@(3.0,1.31,0));
    mmaj7.pos(@(3.0,1.19,0));
    // Inversion boxes
    invType.pos(@(3.0,1.0,0));
    invType.text("Inversion Type");
    invType.sca(0.13);
    rtPs.text("Root Position");
    fInv.text("1st Inversion");
    sInv.text("2nd Inversion");
    tInv.text("3rd Inversion");
    rtPs.pos(@(2.9, 0.85, 0));
    fInv.pos(@(2.9, 0.75, 0));
    sInv.pos(@(2.9, 0.65, 0));
    tInv.pos(@(2.9, 0.55, 0));
    rtPs.sca(0.1);
    fInv.sca(0.1);
    sInv.sca(0.1);
    tInv.sca(0.1);
    inv0.sca(0.09);
    inv1.sca(0.09);
    inv2.sca(0.09);
    inv3.sca(0.09);
    inv0.scaY(0.07);
    inv1.scaY(0.07);
    inv2.scaY(0.07);
    inv3.scaY(0.07);
    inv0.pos(@(3.45,0.85,0));
    inv1.pos(@(3.45,0.75,0));
    inv2.pos(@(3.45,0.65,0));
    inv3.pos(@(3.45,0.55,0));
    // Root note
    rNote.text("Root Note");
    rNote.pos(@(4.2, 1.9, 0));
    rNote.sca(0.13);
    plusBox.pos(@(4.5,1.6,-0.0001));
    plusBox.sca(0.15);
    plusBox.scaZ(0.000000001);
    minusBox.pos(@(3.9,1.6,-0.0001));
    minusBox.sca(0.15);
    minusBox.scaZ(0.000000001);
    plusBox.color(@(0.1,0.1,0.1));
    minusBox.color(@(0.1,0.1,0.1));
    rootBox.pos(@(4.2,1.6,0));
    rootBox.sca(0.15);
    rootBox.text("67");
    plus.pos(@(4.5,1.6,0));
    plus.sca(0.15);
    minus.pos(@(3.9,1.6,0));
    minus.sca(0.15);
    plus.color(@(0,1,0));
    minus.color(@(1,0,0));
    plus.text("+");
    minus.text("-");
    // OK and Cancel
    okBox.pos(@(4.19,-2.3,-0.0001));
    okBox.scaX(1.22);
    okBox.scaY(0.2);
    okBox.scaZ(0.000000001);
    cancelBox.pos(@(2.91,-2.3,-0.0001));
    cancelBox.scaX(1.22);
    cancelBox.scaY(0.2);
    cancelBox.scaZ(0.000000001);
    okBox.color(@(0.1,0.1,0.1));
    cancelBox.color(@(0.1,0.1,0.1));
    okay.pos(@(4.19,-2.3,0));
    okay.sca(0.25);
    canc.pos(@(2.91,-2.3,0));
    canc.sca(0.25);
    okay.color(@(0,1,0));
    canc.color(@(1,0,0));
    okay.text("OK");
    canc.text("CANCEL");

    fun void chordGUI(string type, int root, int inversion)
    {
        <<<"test">>>;
    }
}

// Function for chord updating
fun changeChord(Chord oldChord)
{ 
    // Store old values
    oldChord.gettype() => string type; // What type of 7th chord? e.g. Major 7th
    oldChord.getroot() => int root; // What's the root note?
    oldChord.getinversion() => int inversion; // What inversion is the chord?
    oldChord.getmodArp() => float modArp; // What's the modulation value of the chord?
    oldChord.getgainArp() => float gainArp; // What's the amplitude of the chord?
    oldChord.getmodBass() => float modBass; // What's the modulation value of the bass?
    oldChord.getgainBass() => float gainBass; // What's the amplitude of the bass?
    oldChord.getdepth() => int depth; // how deep is the bass?

    Chord newChord(type, root, inversion, modArp, gainArp, modBass, gainBass, depth);

    while(true)
    {

    }
    // if(clicks +/-)

    // if(clicks cancel or another chord) {return oldChord;}
    // if(clicks ok) {return newChord;}
}

// Chommand for opening interface
// Intialize interface to set parameters to current values
// Chord type: menu; Root note: - note +; inversion: 4 stacked notes with text
// Sliders for the gains; bass depth - depth +
// If cancel, or clicks new target: nothing happens
// If OK:
// => Chord newChord;
// target.updateChord(newChord);

// Each of the 8 are targets

// play the chords
fun playLoop()
{
    while(true)
    {
        guaone.playChord();
        guatwo.playChord();
        guathr.playChord();
        guafou.playChord();
        guafiv.playChord();
        guasix.playChord();
        guasev.playChord();
        guaeig.playChord();
    }
}

// Add taichi symbol to scene
taichi cir(SCALE) --> GG.scene();
// Add 8 Guas to scene
GUA guaone(1, SCALE) --> GG.scene();
GUA guatwo(2, SCALE) --> GG.scene();
GUA guathr(3, SCALE) --> GG.scene();
GUA guafou(4, SCALE) --> GG.scene();
GUA guafiv(5, SCALE) --> GG.scene();
GUA guasix(6, SCALE) --> GG.scene();
GUA guasev(7, SCALE) --> GG.scene();
GUA guaeig(8, SCALE) --> GG.scene();
// Add rotating genie to scene
genie g(SCALE) --> GG.scene();

// Initialize GUA chords
// updateChord(string type, int r, int inv, float ma, float ga, float mb, float gb, int d)
// maj7, min7, dom7, dim7, hdim7, else
guaone.updateChord("mm7", 60, 0, 1, 1, 0.7, 0.8, 2);
guatwo.updateChord("mmm7", 60, 0, 1, 1, 0.7, 0.8, 2);
guathr.updateChord("hdim7", 50, 3, 1, 1, 0.7, 0.8, 1);
guafou.updateChord("maj7", 51, 3, 1, 1, 0.7, 0.85, 1);
guafiv.updateChord("min7", 53, 3, 1, 1, 0.7, 0.9, 1);
guasix.updateChord("dim7", 65, 0, 1, 1, 0.7, 0.9, 2);
guasev.updateChord("mmm7", 60, 2, 1, 1, 0.7, 0.95, 2);
guaeig.updateChord("dom7", 67, 0, 1, 1, 0.7, 0.95, 2);

chordGUI test("0",0,0) --> GG.scene();

spork ~playLoop();

while(true)
{
    cir.rotateZ(pi/420);
    g.rotaZ(pi/8*BPM/60/60);
    GG.nextFrame() => now;
    // Keyboard.update();
    // Tween.update();
}


// Class blurb extends GGen


// fun makeGUA(rot, splits, initChord)

// spork Yinyang rotates

// spork Blurb of points rotate

// spork while(true) for(0 => int i, i > -1, ++i) {EIGHTGUA[i%8].playChord()} 

// spork low pass slider

// spork speed slider

// spork 