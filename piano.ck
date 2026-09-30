GG.camera().orthographic(); // 2d scene, set camera to orthographic

// Copy-pasted from cheatsheet and modified
// returns true if mouse is hovering over the plane
// this is for keyboard as "thing"
fun int isHovered(GGen thing, vec3 mouse_pos) {
    thing.scaWorld() => vec3 worldScale;  // get dimensions
    0.9 => float halfWidth; // width of keyboard
    0.5 => float halfHeight; // height of keyboard
    thing.posWorld() => vec3 worldPos;   // get position

    if (
    mouse_pos.x > worldPos.x - halfWidth 
    && 
    mouse_pos.x < worldPos.x + halfWidth 
    && 
    mouse_pos.y > worldPos.y - halfHeight 
    && 
    mouse_pos.y < worldPos.y + halfHeight
    ) {
    return true;
    }
    return false;
}

public class key extends GCube // defining each key
{
    // Define member variables
    int pitch; // midi pitch
    int keyColor; // color==0 means white, ==1 means black

    // same detecting mouse location function, but inside the class
    fun int isHovered(vec3 mouse_pos) {
        this.scaWorld() => vec3 worldScale;  // get dimensions
        worldScale.x / 2.0 => float halfWidth;
        worldScale.y / 2.0 => float halfHeight;
        this.posWorld() => vec3 worldPos;   // get position

        if (
        mouse_pos.x > worldPos.x - halfWidth 
        && 
        mouse_pos.x < worldPos.x + halfWidth 
        && 
        mouse_pos.y > worldPos.y - halfHeight 
        && 
        mouse_pos.y < worldPos.y + halfHeight
        ) {
        return true;
        }
        return false;
    }

    // Chuck input values onto member variables to initialize key's pitch, color, and position
    fun key(int arg1, float arg2, float arg3, int arg4)
    {
        arg1 => this.pitch;
        arg2 => this.posX;
        arg3 => this.posY;
        arg4 => this.keyColor;

        if( keyColor != 0 ) { // if the key is black
            this.scaY(0.6); // make the key shorter on y axis
            this.scaX(0.1); // make the key shorter on x axis
            Color.BLACK => this.color; // make the color black
            0.2 + this.posY() => this.posY; // shift the key on Y axis
            0.1 => this.posZ; // lift the key on Z axis
        }
        else // if key is white
        {
            this.scaY(1.0);
            this.scaX(0.16);
            Color.WHITE => this.color;
            0 => this.posZ;
        }
    }

    fun int sound(vec3 mouse_pos) // Detects if the mouse is on the key; if so, play the note
    {
        Rhodey piano => dac;
        Std.mtof(this.pitch) => piano.freq; // maps input midi pitch to matching frequency
        0.5 => piano.gain;

        if(isHovered(mouse_pos))
        {
            0.5 => piano.noteOn;
            1::second => now;
            0.5 => piano.noteOff;
            return 1; // Returns 1 inidicating the note has been played (0 if not)
        }
        else
        {
            return 0;
        }
    }
}

public class keyboard extends GGen
{
    key keys[13]; // an array to store the keys
    
    fun keyboard(float arg1, float arg2)
    {   
        // Make the keys; put black keys in the front of the array since black key areas also have white keys
        key C4(60, -0.7+arg1, arg2, 0) @=> keys[5];
        key Cs4(61, -0.6+arg1, arg2, 1) @=> keys[0];
        key D4(62, -0.5+arg1, arg2, 0) @=> keys[6];
        key Ds4(63, -0.4+arg1, arg2, 1) @=> keys[1];
        key E4(64, -0.3+arg1, arg2, 0) @=> keys[7];
        key F4(65, -0.1+arg1, arg2, 0) @=> keys[8];
        key Fs4(66, 0.0+arg1, arg2, 1) @=> keys[2];
        key G4(67, 0.1+arg1, arg2, 0) @=> keys[9];
        key Af4(68, 0.2+arg1, arg2, 1) @=> keys[3];
        key A4(69, 0.3+arg1, arg2, 0) @=> keys[10];
        key Bf4(70, 0.4+arg1, arg2, 1) @=> keys[4];
        key B4(71, 0.5+arg1, arg2, 0) @=> keys[11];
        key C5(72, 0.7+arg1, arg2, 0) @=> keys[12];

        for(key k : keys)
        {
            k --> this; // Connect each key to the keyboard object
        }
    }
    
    fun void play(vec3 mouse_pos) // plays the key that the mouse is on
    {   
        0 => int done; // iterate over all the keys until playing the sound is "done"
        for(0=>int i; i<13; i++)
        {
            if(done==0){
                keys[i].sound(mouse_pos) => done;
            }
            else {
                999 => i; // break loop once done
            }
        }
    }
}

fun void growl() // suzanne growls
{
    SawOsc growl => dac;
    0.0 => growl.gain;
    50 => growl.freq;
    0 => int a;

    while(a<1000)
    {
        if(a<300) // growl rises in gain and freq gradually to start
        {
            a++;
            growl.gain() + 0.002 => growl.gain;
            growl.freq() + 0.2 => growl.freq;
        }
        else if(a<900) // stays level for a while
        {
            a++;
        }
        else // then fades out
        {
            growl.freq() - 1.0 => growl.freq;
            growl.gain() - 0.009 => growl.gain;
            a++;
        }

        1::ms => now;
    }
}

// Summons suzanne!!!
fun void suzzane()
{
    float x, y, z;

    for(0=>int n; n < 50; n++)
    {
        // Determine suz's next position
        Math.random2f(-0.1, 0.1) => x;
        Math.random2f(-0.1, 0.1) => y;
        Math.random2f(-0.1, 0.1) => z;
        // Declare suz
        GSuzanne suz --> GG.scene();
        // Make suzanne big
        suz.scaX(3);
        suz.scaY(3);
        suz.scaZ(3);
        // Make suzanne red
        @(1,0,0) => suz.color;
        // Make suzanne move
        suz.pos(@(x,y,z));
        // suzanne is here for 10 ms...
        10::ms => now;
        // before being gone for 10 ms...
        suz.detach();
        10::ms => now;
        // And repeat 50 times
    }
}

fun void fireSuzanne()
{   
    spork ~growl(); // while graphics go off, suz growls concurrently
    spork ~suzzane();
}

0 => float a;
0 => float b;

keyboard keys(a,b) --> GG.scene(); 

while(true)
{
    GG.nextFrame() => now;
    // mouse position
    GG.camera().screenCoordToWorldPos(GWindow.mousePos(), 1) => vec3 mouse_pos; // get mouse world position

    // mouse buttons
    if(GWindow.mouseLeftDown() && isHovered(keys, mouse_pos)) 
    {
        if(maybe || maybe || maybe || maybe) // 15/16 probability
        {
            spork ~keys.play(mouse_pos); // usually, when the mouse presses the key, it should sound
        }
        else
        {
            Math.random2f(-3.0, 3.0) => a;
            Math.random2f(-2.0, 2.0) => b;
            keys --< GG.scene(); // removes keyboard (not sure if this worked)
            fireSuzanne(); // but occassionally, summon suzzane

            keys.pos(@(a,b,0)); // update the keyboard's location randomly
            keys --> GG.scene(); // add keyboard back to scene
        }
    }
}


//FAIL⬇️⬇️

// fun void makeKey(string name, float posX) {
//     GCube name --> GG.scene(); // adds the key to the scene
//     0 => float posY; // initializes key's position on y axis
//     name.scaX(0.16); // make the key narrow on x axis
//     name.scaZ(0.2); // make the key thin on z axis
//     Color.WHITE => name.color; // make the key white
    
//     if( name.length() != 1 ) { // if the key is black
//         name.scaY(0.6); // make the key shorter on y axis
//         name.scaX(0.1); // make the key shorter on x axis
//         Color.BLACK => name.color; // make the color black
//         0.2 => posY; // shift the key on Y axis
//     }
    
//     name.pos(@(posX, posY, 0)); // places the key according to parameter
//     GG.nextFrame() => now; // keeps time moving, I guess
// }

// // Add the keys to the scene. Cs is C#, Bf is Bb
// makeKey( "c", -0.40); // named c to make room for C, the higher octave. need to keep key-name at length 1
// makeKey( "Cs", -0.32);
// makeKey( "D", -0.24);
// makeKey( "Ds", -0.16);
// makeKey( "E", -0.08);
// makeKey( "Fs", 0 );
// makeKey( "G", 0.08);
// makeKey( "Af", 0.16);
// makeKey( "A", 0.24);
// makeKey( "Bf", 0.32);
// makeKey( "B", 0.40);
// makeKey( "C", 0.48);


    

// while(true)
// {
//     GG.nextFrame() => now;
// }