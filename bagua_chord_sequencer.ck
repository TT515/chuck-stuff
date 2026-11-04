//-----------------------------------------------------------------------------
// name: BAGUA.ck
// desc: Control harmonic cycle with colors
// 
// author: Tao-Tao He
// date: Oct. 20, 2026
//-----------------------------------------------------------------------------

@import "chodash";

GG.camera().orthographic(); // 2d scene, set camera to orthographic
GG.bloom(true);

// Main color
vec3 MAIN_COLOR;
@(0.6, 1.0, 1.0) @=> MAIN_COLOR;

// Sampling Rate
44100 => int SR;
// Default speed
60 => global float BPM;
60 => global float initBPM;
// Default scale
1.0 => float SCALE;

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

// Copy-pasted from light.ck
// a custom GGen:
// lightbulb class that renders pointlight with a colored sphere to visualize its position
class LightBulb extends GGen
{
    // GGen network. a light + sphere at the same position
    GPointLight light --> genie g --> this;

    // set up sphere to be a flat color
    FlatMaterial mat( Color.WHITE );
    // set the material
    g.mat(mat);

    // set light radius (how far the light reaches)
    light.radius(2);
    // light color
    vec3 m_color;
    // randomize pulse rate for fading in/out
    Math.random2f(0.5, 1.5) => float pulseRate;

    // method for setting color
    fun void color(float r, float g, float b) {
        @(r, g, b) => m_color;  // save the set color
        mat.color(@(r, g, b));   // set material color
        light.color(@(r, g, b));  // set light diffuse color
    }

    // this is called automatically every frame by ChuGL...
    // IF the GGen or one of its parents is connected to GG.scene()
    fun void update(float dt) {
        // fluctuate intensity
        0.5 + 0.5 * Math.sin((now/second) * pulseRate) => light.intensity; // range [0, 1]
        // fluctuate material color
        light.intensity() * m_color => mat.color;
    }
}

// The center taichi; spins and controls overall sound
public class taichi extends Button
{
    Circle circles[3]; // store circles
    HalfCircle halfcircles[2]; // store circles
    
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
        bigCir @=> circles[0];

        // The half circles
        HalfCircle halfCirOne(128, 1) --> this;
        halfCirOne.color(@(0.6, 1.0, 1.0));
        halfCirOne.sca(scale/2);
        halfCirOne.width(width*1.4);
        // halfCirOne.width(10);
        @( scale/2,0,0 ) => halfCirOne.pos;
        halfCirOne @=> halfcircles[0];

        // The half circles
        HalfCircle halfCirTwo(128, 1) --> this;
        halfCirTwo.color(@(0.6, 1.0, 1.0));
        halfCirTwo.sca(scale/2);
        halfCirTwo.width(width*1.4);
        @( -scale/2,0,0 ) => halfCirTwo.pos;
        halfCirTwo.rotateZ(pi);
        halfCirTwo @=> halfcircles[1];

        // The small circles
        Circle smallCirOne(128, 1) --> this;
        smallCirOne.color(@(0.6, 1.0, 1.0));
        smallCirOne.sca(scale/20);
        smallCirOne.width(width*8);
        @( scale/2+width*1.5, -width, 0 ) => smallCirOne.pos;
        smallCirOne @=> circles[1];

        // The small circles
        Circle smallCirTwo(1024, 1) --> this;
        smallCirTwo.color(@(0.6, 1.0, 1.0));
        smallCirTwo.sca(scale/20);
        smallCirTwo.width(width*8);
        @( -scale/2-width*1.5, width, 0 ) => smallCirTwo.pos;
        smallCirTwo @=> circles[2];
    }

    // Control color of entire genie
    fun void color(vec3 col)
    {
        for(Circle c : circles)
        {
            c.color(col);
        }
        for(HalfCircle hc : halfcircles)
        {
            hc.color(col);
        }
    }
}

// The chord that is embodied by the GUA
class Chord
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
        if(paused == 0)    
        {
            SinOsc tosc => ADSR tenv => NRev trev => dac;
            SinOsc sosc => ADSR senv => NRev srev => dac;
            gain*0.8 => tosc.gain;
            gain*0.2 => sosc.gain;
            Std.mtof(midiNote) => tosc.freq; // Converts MIDI note to frequency
            Std.mtof(midiNote) => sosc.freq;
            tenv.set(length*0.01, length*0.01, .9, length*0.08);
            senv.set(length*0.05, length*0.01, .8, length*0.03);
            0.4 => trev.gain;
            0.4 => srev.gain;
            tenv.keyOn();
            senv.keyOn();
            length*0.2-tenv.releaseTime() => now;
            tenv.keyOff();
            tenv.releaseTime()-senv.releaseTime() => now;
            senv.keyOff();
            senv.releaseTime() => now;
            length*0.8 => now;
        }
        else
        {
            length => now;
            return;
        }
    }

    // Function for getting the chord to make sound
    fun void playChord()
    {
        1::minute / BPM / 4 => dur quarterBeat; // define duration of each arpeggio note
        
        // Play bass notes
        spork ~playNote(this.bassNotes[0], this.gainBass, this.modBass, quarterBeat*8);
        spork ~playNote(this.bassNotes[1], this.gainBass, this.modBass, quarterBeat*8);

        0 => int q;

        for(int note : this.arpeggio)
        {
            spork ~playNote(note, this.gainArp * (0.76 + (note - this.arpeggio[0]) * 0.02) - 0.2 * (q % 2) - 0.04 * (q % 4), this.modArp, quarterBeat);
            quarterBeat => now; // play one note at a time; advances time
            q++;
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

// The three rectangles (each GUA)
class GUA extends Button
{
    // Initialize the 3 rectangles
    GCube top --> this;
    GCube mid --> this;
    GCube bottom --> this;
    // color( @(.6, 1, 1) );
    vec3 thisColor;
    @(.6, 1, 1) @=> thisColor;
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
        c @=> thisColor;
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

    // Returns the current chord
    fun Chord getChord()
    {
        return this.myChord;
    }

    // Effect when chord is updated (it jumps)
    fun void updateEffect(vec3 targetColor)
    {
        // getChordColor(chord) @=> vec3 targetColor;
        thisColor @=> vec3 curColor;
        this.sca(1.1);
        color(targetColor);
        150::ms => now;
        this.sca(1.0);
        150::ms => now;
        this.sca(1.1);
        150::ms => now;
        this.sca(1.0);
        color(curColor);
        150::ms => now;
    }
}

// Rotating genie
public class genie extends GMesh
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

    // Control color of entire genie
    fun void color(vec3 col)
    {
        for(Circle c : circles)
        {
            c.color(col);
        }
    }
}

// Click these buttons, changes visualizing mode
public class modeButton extends Button
{
    GCube button --> this;
    GText mode --> this;
    string mode1;
    string mode2;
    int curMode;

    mode.color(@(1,1,1));
    mode.sca(0.2);
    mode.font("./OCRB.ttf");
    button.color(@(0,0,0));
    button.scaY(0.2);
    button.scaX(2.5);
    button.posZ(-1.1);

    fun void modeButton(string mode1, string mode2)
    {
        mode1 => this.mode1;
        mode2 => this.mode2;
        1 => this.curMode;
        mode.text(mode1);
    }

    // Changes mode depending on current mode
    fun int changeMode()
    {
        if(curMode == 1)
        {
            2 => this.curMode;
            mode.text(mode2);
        }
        else
        {
            1 => this.curMode;
            mode.text(mode1);
        }
        return curMode;
    }
}

// Click these buttons, select action to act upon a GUA
public class menuButton extends Button
{
    GCube button --> this;
    GText whatIsThis --> this;
    // GIcon icon --> this;
    float action;
    string targetVar;

    whatIsThis.color(@(1,1,1));
    whatIsThis.sca(0.15);
    whatIsThis.font("./OCRB.ttf");
    button.color(@(0,0,0));
    button.scaY(0.2);
    button.scaX(2.1);
    button.posZ(-1.1);

    fun void menuButton(string is, string targetVar, float action, vec3 textColor)
    {
        whatIsThis.text(is);
        targetVar => this.targetVar;
        action => this.action;
        whatIsThis.color(textColor);
    }

    fun float getAction()
    {
        return this.action;
    }

    fun string getTargetVar()
    {
        return this.targetVar;
    }
}

// Subtitle in menu
public class subtitle extends GGen
{
    GText category --> this;
    category.color(@(1,1,1));
    category.sca(0.15);
    category.font("./OCRB.ttf");
    
    fun void subtitle(string is)
    {
        category.text(is);
    }
}

public class chordGUI extends GGen
{
    // Initialize interface
    GCube outBox --> this;
    GCube inBox --> this;
    GText title --> this;

    // Design interface: outter boxes
    outBox.pos(@(0,0,-0.1));
    inBox.pos(@(0,0,-0.09));
    outBox.scaY(4.2);
    outBox.scaX(2.3);
    outBox.scaZ(0.001);
    inBox.scaY(4.1);
    inBox.scaX(2.2);
    inBox.scaZ(0.001);
    outBox.color(@(0.2,0.2,0.2));
    inBox.color(@(0.01,0.01,0.01));
    // Title text
    title.text("Chord Menu");
    title.pos(@(0, 1.85, 0));
    title.sca(0.2);
    title.font("./OCRB.ttf");
}

// Makes entire GUI disappear
fun void noGUI(GGen things[])
{
    for(GGen thing : things)
    {
        thing --< GG.scene();
    }
}

// Makes entire GUI reappear
fun void yesGUI(GGen things[])
{
    for(GGen thing : things)
    {
        thing --> GG.scene();
    }
}

// Function for chord updating; passes in old chord and selected button
fun Chord changeChord(menuButton selected, Chord oldChord)
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

    // Get selected action
    selected.getTargetVar() => string targetVar; // Which variable to update?
    selected.getAction() => float action; // Target variable changes by how much?

    // Update chord
    if(targetVar == "chordType")
    {
        if(action == 1.0) { "maj7" => type; }
        else if(action == 2.0) { "dom7" => type; }
        else if(action == 3.0) { "min7" => type; }
        else if(action == 4.0) { "hdim7" => type; }
        else if(action == 5.0) { "dim7" => type; }
        else { "mmaj7" => type; }
    } else if(targetVar == "root")
    {
        root + action$int => root;
    } else if(targetVar == "inversion")
    {
        action$int => inversion;
    } else if(targetVar == "gainArp")
    {
        gainArp + action => gainArp;
    } else if(targetVar == "depth")
    {
        depth + action$int => depth;
    } else if(targetVar == "gainBass")
    {
        gainBass + action => gainBass;
    }

    Chord newChord(type, root, inversion, modArp, gainArp, modBass, gainBass, depth) @=> Chord updatedChord; // updated chord
    return updatedChord;
}

// Maps each chord type to a color
// Major 7th chord blue
// Minor 7th chord yellow
// Dominant chord green
// Minor-major chord other
// Half-Diminished chord purple
// Diminished chord red
fun vec3 getChordColor(Chord chord)
{
    chord.gettype() => string type;
    vec3 col;

    if(type == "maj7")
        {
            @(0.6,0.6,1) @=> col; // Major 7th chord blue
        }
        else if(type == "min7")
        {
            @(0.9,0.9,0.6) @=> col; // Minor 7th chord yellow
        }
        else if(type == "dom7")
        {
            @(0.6,1,0.6) @=> col; // Dominant chord green
        }
        else if(type == "hdim7")
        {
            @(0.9,0.6,0.9) @=> col; // Half-Diminished chord purple
        }
        else if(type == "dim7")
        {
            @(1,0.6,0.6) @=> col; // Diminished chord red
        }
        else // minor major 7th
        {
            @(0.6,0.9,0.9) @=> col; // Minor-major we'll see
        }

    return col;
}

// In Visualize Mode: On, the color of the entire thing shifts with targetColor
@(0.6,0.9,0.9) @=> vec3 targetColor;
@(0.6,1,0.6) @=> vec3 prevColor;
@(0.6,0.9,0.9) @=> vec3 nextColor;

// play the chords; update target colors
fun playLoop()
{
    while(true)
    {
        getChordColor(guaeig.getChord()) => prevColor;
        getChordColor(guaone.getChord()) => targetColor;
        getChordColor(guatwo.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guaone.playChord();
        targetColor => prevColor;
        getChordColor(guatwo.getChord()) => targetColor;
        getChordColor(guathr.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guatwo.playChord();
        targetColor => prevColor;
        getChordColor(guathr.getChord()) => targetColor;
        getChordColor(guafou.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guathr.playChord();
        targetColor => prevColor;
        getChordColor(guafou.getChord()) => targetColor;
        getChordColor(guafiv.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guafou.playChord();
        targetColor => prevColor;
        getChordColor(guafiv.getChord()) => targetColor;
        getChordColor(guasix.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guafiv.playChord();
        targetColor => prevColor;
        getChordColor(guasix.getChord()) => targetColor;
        getChordColor(guasev.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guasix.playChord();
        targetColor => prevColor;
        getChordColor(guasev.getChord()) => targetColor;
        getChordColor(guaeig.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
        guasev.playChord();
        targetColor => prevColor;
        getChordColor(guaeig.getChord()) => targetColor;
        getChordColor(guaone.getChord()) => nextColor;
        if(paused == 0) {changeColor();}
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
// Shift Guas down
guaone.posY(-0.5);
guatwo.posY(-0.5);
guathr.posY(-0.5);
guafou.posY(-0.5);
guafiv.posY(-0.5);
guasix.posY(-0.5);
guasev.posY(-0.5);
guaeig.posY(-0.5);
cir.posY(-0.5);
// Add rotating genie to scene
LightBulb light --> genie g(SCALE) --> GG.scene();
g.posY(-0.5);
light.color(1,0,1);
light.light.radius(1);
light.light.falloff(3);

// Put all of these objects in an array
GUA core[8];
guaone @=> core[0];
guatwo @=> core[1];
guathr @=> core[2];
guafou @=> core[3];
guafiv @=> core[4];
guasix @=> core[5];
guasev @=> core[6];
guaeig @=> core[7];

// Initialize GUA chords
// updateChord(string type, int r, int inv, float ma, float ga, float mb, float gb, int d)
// maj7, min7, dom7, dim7, hdim7, else
guaone.updateChord("mm7", 60, 0, 1, 1, 0.7, 0.8, 2);
guatwo.updateChord("mmm7", 60, 0, 1, 1, 0.7, 0.8, 2);
guathr.updateChord("hdim7", 60, 0, 1, 1, 0.7, 0.8, 1);
guafou.updateChord("maj7", 60, 0, 1, 1, 0.7, 0.85, 1);
guafiv.updateChord("min7", 60, 0, 1, 1, 0.7, 0.9, 1);
guasix.updateChord("dim7", 60, 0, 1, 1, 0.7, 0.9, 2);
guasev.updateChord("mmm7", 60, 0, 1, 1, 0.7, 0.95, 2);
guaeig.updateChord("dom7", 60, 0, 1, 1, 0.7, 0.95, 2);

// Track if visualize mode is on, and if the sequencer is paused
1 => int visMode;
0 => int paused;

// Change color live according to latest target color
fun changeColor()
{
    for(GUA gua : core)
    {
        if(visMode == 1) {gua.color(targetColor);} // Visualize mode is off, visualizer is same color
        else {gua.color(getChordColor(gua.getChord()));} // Visualize mode is on, visualizer color depends on chord
    }
    cir.color(targetColor);
    GG.scene().backgroundColor(targetColor * 0.1);
    if(paused == 0) {g.color(targetColor);}
    else {g.color(GG.scene().backgroundColor());}
}

// Array that keeps track of everything to show as chord menu
GGen things[29];

// Put both GUI boxes in place
chordGUI left --> GG.scene();
chordGUI right --> GG.scene();
left.posX(-3.75);
right.posX(3.75);

// Attach menu buttons to GUI
// Chord Type
// {
//             @(0.6,0.6,1) @=> col; // Major 7th chord blue
//         }
//         else if(type == "min7")
//         {
//             @(0.9,0.9,0.6) @=> col; // Minor 7th chord yellow
//         }
//         else if(type == "dom7")
//         {
//             @(0.6,1,0.6) @=> col; // Dominant chord green
//         }
//         else if(type == "hdim7")
//         {
//             @(0.9,0.6,0.9) @=> col; // Half-Diminished chord purple
//         }
//         else if(type == "dim7")
//         {
//             @(1,0.6,0.6) @=> col; // Diminished chord red
//         }
//         else // minor major 7th
//         {
//             @(0.6,0.9,0.9) @=> col; // Minor-major we'll see
//         }
subtitle chordType("Chord Type") --> GG.scene();
menuButton maj7("Major 7th              ", "chordType", 1.0, @(0.6,0.6,1)) --> GG.scene();
menuButton dom7("Dominant 7th           ", "chordType", 2.0, @(0.6,1,0.6)) --> GG.scene();
menuButton min7("Minor 7th              ", "chordType", 3.0, @(0.9,0.9,0.6)) --> GG.scene();
menuButton hdim("Half-Diminished 7th    ", "chordType", 4.0, @(0.9,0.6,0.9)) --> GG.scene();
menuButton dim7("Diminished 7th         ", "chordType", 5.0, @(1,0.6,0.6)) --> GG.scene();
menuButton mmaj("Minor-Major 7th        ", "chordType", 6.0, @(0.6,0.9,0.9)) --> GG.scene();
chordType.pos(@(-3.75, 1.53, 1.1));
maj7.pos(@(-3.75, 1.27, 1.1));
dom7.pos(@(-3.75, 1.03, 1.1));
min7.pos(@(-3.75, 0.79, 1.1));
hdim.pos(@(-3.75, 0.55, 1.1));
dim7.pos(@(-3.75, 0.31, 1.1));
mmaj.pos(@(-3.75, 0.07, 1.1));
// Inversion Type
subtitle invType("Inversion Type") --> GG.scene();
menuButton rtps("Root Position          ", "inversion", 0, @(1,1,1)) --> GG.scene();
menuButton finv("1st Inversion          ", "inversion", 1, @(1,1,1)) --> GG.scene();
menuButton sinv("2nd Inversion          ", "inversion", 2, @(1,1,1)) --> GG.scene();
menuButton tinv("3rd Inversion          ", "inversion", 3, @(1,1,1)) --> GG.scene();
invType.pos(@(-3.75, -0.28, 1.1));
rtps.pos(@(-3.75, -0.54, 1.1));
finv.pos(@(-3.75, -0.78, 1.1));
sinv.pos(@(-3.75, -1.02, 1.1));
tinv.pos(@(-3.75, -1.26, 1.1));
// Tempo Title
subtitle tempoTitle("Tempo") --> GG.scene();
tempoTitle.pos(@(-3.75, -1.60, 1.1));
// Tempo slider is...down there
// Root Note
subtitle root("Root Note") --> GG.scene();
menuButton raise("Raise pitch            ", "root", 1, @(0.5,1,0.5)) --> GG.scene();
menuButton lower("Lower pitch            ", "root", -1, @(1,0.5,0.5)) --> GG.scene();
root.pos(@(3.75, 1.53, 1.1));
raise.pos(@(3.75, 1.24, 1.1));
lower.pos(@(3.75, 1.00, 1.1));
// Bass Volume
subtitle bvol("Bass Volume") --> GG.scene();
menuButton blouder("Louder                 ", "gainBass", 0.1, @(0.5,1,0.5)) --> GG.scene();
menuButton bsofter("Softer                 ", "gainBass", -0.1, @(1,0.5,0.5)) --> GG.scene();
bvol.pos(@(3.75, 0.64, 1.1));
blouder.pos(@(3.75, 0.35, 1.1));
bsofter.pos(@(3.75, 0.11, 1.1));
// Bass Depth
subtitle bdepth("Bass Depth") --> GG.scene();
menuButton higher("Higher                 ", "depth", -1, @(1,1,1)) --> GG.scene();
menuButton deeper("Deeper                 ", "depth", 1, @(0.5,0.5,0.5)) --> GG.scene();
bdepth.pos(@(3.75, -0.25, 1.1));
higher.pos(@(3.75, -0.54, 1.1));
deeper.pos(@(3.75, -0.78, 1.1));
// Overall Volume
subtitle vol("Arpeggio Volume") --> GG.scene();
menuButton louder("Louder                 ", "gainArp", 0.1, @(0.5,1,0.5)) --> GG.scene();
menuButton softer("Softer                 ", "gainArp", -0.1, @(1,0.5,0.5)) --> GG.scene();
vol.pos(@(3.75, -1.14, 1.1));
louder.pos(@(3.75, -1.43, 1.1));
softer.pos(@(3.75, -1.67, 1.1));

// Tempo slider
// Code generously given by Marko
GPlane button --> GG.scene();
button.sca(@(0.1,0.2,1));
button.pos(@(-3.75,-1.9,2));
button.color(@(0.5,0.5,0.5));
GPlane slider --> GG.scene();
slider.sca(@(2,0.06,1));
slider.pos(@(-3.75,-1.9,1.1));

class SliderCommand extends MouseCommand {
    0.0 => float grabOffset;

    fun void dragStart(MouseDrag drag) {
        // remember where on the button you grabbed it, so it doesn't jump to center on the cursor
        drag.sourcePos.x - drag.worldOrigin.x => grabOffset;
    }

    fun void drag(MouseDrag drag) {
        // keep the whole button inside the slider, not just its center
        slider.posX() - slider.scaX() * 0.5 + button.scaX() * 0.5 => float minX;
        slider.posX() + slider.scaX() * 0.5 - button.scaX() * 0.5 => float maxX;

        drag.world.x + grabOffset => float x;
        if (x < minX) minX => x;
        if (x > maxX) maxX => x;
        drag.source.ggen.posX(x);

        // Update BPM (ranged between 0.5x and 2x initBPM, with exponential scale)
        Math.pow(2.0, x - minX) * initBPM / 2 => BPM;
    }
}

// Attach things to things array
// Chord GUIs
left @=> things[0];
right @=> things[1];
// Subtitles
chordType @=> things[2];
invType @=> things[3];
root @=> things[4];
bvol @=> things[5];
bdepth @=> things[6];
vol @=> things[7];
// Menu Buttons
maj7 @=> things[8];
dom7 @=> things[9];
min7 @=> things[10];
hdim @=> things[11];
dim7 @=> things[12];
mmaj @=> things[13];
rtps @=> things[14];
finv @=> things[15];
sinv @=> things[16];
tinv @=> things[17];
// pause @=> things[18];
tempoTitle @=> things[18];
raise @=> things[19];
lower @=> things[20];
blouder @=> things[21];
bsofter @=> things[22];
higher @=> things[23];
deeper @=> things[24];
louder @=> things[25];
softer @=> things[26];
// Slider
button @=> things[27];
slider @=> things[28];

// Put mode buttons on top
modeButton visualize("Chord Visualizer: Off", "Chord Visualizer: On") --> GG.scene();
modeButton menu("Hide Chord Menu", "Show Chord Menu") --> GG.scene();
visualize.posY(2.9);
menu.posY(2.5);

// CHODASH!
menuButton selected; // If a button is clicked, they become the selected button
fun void deselect() // If mouse clicks non-object, deselect any selected object
{
    if(selected != null) {selected.sca(1.0);}
    null @=> selected;
}

// Scale an object (e.g. grow on hover and shrink on leave)
// Copy pasted from commands.ck in Chodash button example
class ScaleCommand extends Chommand {
    GGen @ target;
    float scale; 
    fun @construct(GGen target, float scale) { target @=> this.target; scale => this.scale; }
    fun void run() 
    { 
        if(selected != target) { target.sca(scale); } // If target is selected, we don't mess with its size
    }
}
// Chommand for when top button is clicked
class changeVisMode extends Chommand
{
    fun void run()
    {
        // visualize.changeMode() => int newMode;
        visualize.changeMode() => visMode;
        changeColor();
        deselect();
    }
}
visualize.onClick(new changeVisMode());
visualize.onHover(new ScaleCommand(visualize, 1.2));
visualize.onLeave(new ScaleCommand(visualize, 1.0));
// Chommand for when second-to-top button is clicked
class changeMenuMode extends Chommand
{
    fun void run()
    {
        menu.changeMode() => int newMode;
        if(newMode == 1)
        {
            yesGUI(things);
        }
        else
        {
            noGUI(things);
        }
        deselect();
    }
}
menu.onClick(new changeMenuMode());
menu.onHover(new ScaleCommand(menu, 1.2));
menu.onLeave(new ScaleCommand(menu, 1.0));

// Chommand for selecting a menu button
class selectButton extends Chommand
{
    menuButton @ target;
    fun @construct(menuButton target) { target @=> this.target; }
    
    fun void run()
    {
        deselect();
        target @=> selected;
        target.sca(1.5);
    }
}

// Function for updating chords
fun Chord getNewChord(GUA target, menuButton selected)
{
    target.getChord() @=> Chord oldChord;
    changeChord(selected, oldChord) @=> Chord newChord;
    return newChord;
}

// Chommand for taking the selected action on the selected chord
class updateChord extends Chommand
{
    GUA @ target;
    fun @construct(GUA target) { target @=> this.target; }

    fun void run()
    {
        if(selected != null)
        {
            getNewChord(target, selected) @=> Chord newChord;
            target.updateChord(newChord);
            spork ~target.updateEffect(getChordColor(newChord));
        }
    }
}

// Chommand for updating every chord
class updateAll extends Chommand
{
    Chord newChord;
    
    fun void run()
    {
        if(selected != null)
        {
            getNewChord(guaone, selected) @=> newChord;
            guaone.updateChord(newChord);
            spork ~guaone.updateEffect(getChordColor(newChord));
            getNewChord(guatwo, selected) @=> newChord;
            guatwo.updateChord(newChord);
            spork ~guatwo.updateEffect(getChordColor(newChord));
            getNewChord(guathr, selected) @=> newChord;
            guathr.updateChord(newChord);
            spork ~guathr.updateEffect(getChordColor(newChord));
            getNewChord(guafou, selected) @=> newChord;
            guafou.updateChord(newChord);
            spork ~guafou.updateEffect(getChordColor(newChord));
            getNewChord(guafiv, selected) @=> newChord;
            guafiv.updateChord(newChord);
            spork ~guafiv.updateEffect(getChordColor(newChord));
            getNewChord(guasix, selected) @=> newChord;
            guasix.updateChord(newChord);
            spork ~guasix.updateEffect(getChordColor(newChord));
            getNewChord(guasev, selected) @=> newChord;
            guasev.updateChord(newChord);
            spork ~guasev.updateEffect(getChordColor(newChord));
            getNewChord(guaeig, selected) @=> newChord;
            guaeig.updateChord(newChord);
            spork ~guaeig.updateEffect(getChordColor(newChord));
        }
    }
}

// Pause and resume the sequencer
class pauseThing extends Chommand
{
    fun void run()
    {
        if(paused == 0)
        {
            1 => paused;
            changeColor();
            light.color(0,0,0);
        }
        else
        {
            0 => paused;
            changeColor();
            light.color(0,0,0);
        }
    }
}

// Let all of the GUAs, when pressed corresponding key, update the chord according to selected action
Keyboard.bind(new updateChord(guaone), GWindow.KEY_1);
Keyboard.bind(new updateChord(guatwo), GWindow.KEY_2);
Keyboard.bind(new updateChord(guathr), GWindow.KEY_3);
Keyboard.bind(new updateChord(guafou), GWindow.KEY_4);
Keyboard.bind(new updateChord(guafiv), GWindow.KEY_5);
Keyboard.bind(new updateChord(guasix), GWindow.KEY_6);
Keyboard.bind(new updateChord(guasev), GWindow.KEY_7);
Keyboard.bind(new updateChord(guaeig), GWindow.KEY_8);
Keyboard.bind(new updateAll(), GWindow.KEY_0);

// Let all of the menu buttons adhere to Chommands
// There must be a better way to do this...
maj7.onClick(new selectButton(maj7));
maj7.onHover(new ScaleCommand(maj7, 1.2));
maj7.onLeave(new ScaleCommand(maj7, 1.0));
dom7.onClick(new selectButton(dom7));
dom7.onHover(new ScaleCommand(dom7, 1.2));
dom7.onLeave(new ScaleCommand(dom7, 1.0));
min7.onClick(new selectButton(min7));
min7.onHover(new ScaleCommand(min7, 1.2));
min7.onLeave(new ScaleCommand(min7, 1.0));
hdim.onClick(new selectButton(hdim));
hdim.onHover(new ScaleCommand(hdim, 1.2));
hdim.onLeave(new ScaleCommand(hdim, 1.0));
dim7.onClick(new selectButton(dim7));
dim7.onHover(new ScaleCommand(dim7, 1.2));
dim7.onLeave(new ScaleCommand(dim7, 1.0));
mmaj.onClick(new selectButton(mmaj));
mmaj.onHover(new ScaleCommand(mmaj, 1.2));
mmaj.onLeave(new ScaleCommand(mmaj, 1.0));
rtps.onClick(new selectButton(rtps));
rtps.onHover(new ScaleCommand(rtps, 1.2));
rtps.onLeave(new ScaleCommand(rtps, 1.0));
finv.onClick(new selectButton(finv));
finv.onHover(new ScaleCommand(finv, 1.2));
finv.onLeave(new ScaleCommand(finv, 1.0));
sinv.onClick(new selectButton(sinv));
sinv.onHover(new ScaleCommand(sinv, 1.2));
sinv.onLeave(new ScaleCommand(sinv, 1.0));
tinv.onClick(new selectButton(tinv));
tinv.onHover(new ScaleCommand(tinv, 1.2));
tinv.onLeave(new ScaleCommand(tinv, 1.0));
raise.onClick(new selectButton(raise));
raise.onHover(new ScaleCommand(raise, 1.2));
raise.onLeave(new ScaleCommand(raise, 1.0));
lower.onClick(new selectButton(lower));
lower.onHover(new ScaleCommand(lower, 1.2));
lower.onLeave(new ScaleCommand(lower, 1.0));
blouder.onClick(new selectButton(blouder));
blouder.onHover(new ScaleCommand(blouder, 1.2));
blouder.onLeave(new ScaleCommand(blouder, 1.0));
bsofter.onClick(new selectButton(bsofter));
bsofter.onHover(new ScaleCommand(bsofter, 1.2));
bsofter.onLeave(new ScaleCommand(bsofter, 1.0));
louder.onClick(new selectButton(louder));
louder.onHover(new ScaleCommand(louder, 1.2));
louder.onLeave(new ScaleCommand(louder, 1.0));
softer.onClick(new selectButton(softer));
softer.onHover(new ScaleCommand(softer, 1.2));
softer.onLeave(new ScaleCommand(softer, 1.0));
higher.onClick(new selectButton(higher));
higher.onHover(new ScaleCommand(higher, 1.2));
higher.onLeave(new ScaleCommand(higher, 1.0));
deeper.onClick(new selectButton(deeper));
deeper.onHover(new ScaleCommand(deeper, 1.2));
deeper.onLeave(new ScaleCommand(deeper, 1.0));
// Pause the sequencer if taichi clicked
cir.onClick(new pauseThing());
cir.onHover(new ScaleCommand(cir, 1.04));
cir.onLeave(new ScaleCommand(cir, 1.0));

MouseTarget buttonTarget(button);
SliderCommand sliderCommand;
Mouse.bindDrag(sliderCommand, Mouse.LEFT, buttonTarget);

spork ~playLoop();

while(true)
{
    g.rotaZ(pi/8*BPM/60 * GG.dt());
    if(paused==0) {cir.rotateZ(pi/BPM/7);}
    GG.nextFrame() => now;
    Button.update();
    Keyboard.update();
    Mouse.update();
}
