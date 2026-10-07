//-----------------------------------------------------------------------------
// name: FFruiT_NINJA.ck
// desc: Fruit ninja, but your frequency spectrum is your blade
// 
// author: Tao-Tao He
// date: Oct. 5, 2026
//-----------------------------------------------------------------------------

// window size
2048 => int WINDOW_SIZE;
// y position of waveform, outside sight to start with
3.8 => float WAVEFORM_Y;
// width of waveform and spectrum display
10 => float DISPLAY_WIDTH;
// Maximum and minimum frequency
22100 => float MAX;
120 => float MIN;
// Number of points in spectrum
2048 => int POINTS;
// Sampling Rate
44100 => int SR;
// Scale of the spectrum
20 => int SPEC_SCALE;
// Scale of the apple
0.01 => float APPLE_SCALE;
// Initial HP
90 => float INIT_HP;
// Apple path
me.dir() + "/apple/appleuvw.obj" => string APPLE_PATH;
// More params to tune in lines 101, 225

// Initialize HP and Score values
90 => float hp;
0 => int SCORE;

// From line 38 to 79, code mostly copy pasted from sndpeek.ck
// window title
GWindow.title( "FFruiT Ninja" );
// uncomment to fullscreen
GWindow.fullscreen();
// position camera
GG.scene().camera().posZ(8.0);

// waveform renderer
GLines waveform --> GG.scene(); waveform.width(.01);
// translate up
waveform.posY(WAVEFORM_Y);
// color0
waveform.color( @(1.0, .2, .2) );

// spectrum renderer
GLines spectrum --> GG.scene(); spectrum.width(.01);
// spectrum.sca(10);
// translate down
spectrum.posY(-WAVEFORM_Y);
// spectrum.posX(0);
// color0
spectrum.color( @(.3, .5, .7) );

// accumulate samples from mic
adc => Flip accum => blackhole;
// take the FFT
adc => PoleZero dcbloke => FFT fft => blackhole;
// set DC blocker
.5 => dcbloke.blockZero;
// set size of flip
WINDOW_SIZE => accum.size;
// set window type and size
Windowing.hann(WINDOW_SIZE) => fft.window;
// set FFT size (will automatically zero pad)
WINDOW_SIZE*2 => fft.size;
// get a reference for our window for visual tapering of the waveform
Windowing.hann(WINDOW_SIZE) @=> float window[];

// sample array
float samples[0];
// FFT response
complex response[0];

// We separate the waveform array and the spectrum array, since they are needed for different functions
// Determines how many points are visualized in the spectrum
vec2 waveformPositions[POINTS];
vec2 spectrumPositions[POINTS];

// map FFT output to 3D positions
fun void map2spectrum( complex in[], vec2 out[] )
{
    DISPLAY_WIDTH => float width;
    // mapping to xyz coordinate
    for (int i; i < out.size(); i++)
    {
        // space in X into logarithmic bins, so that each octave is spaced evenly
        // This calculates 20*log
        -width/2 + width * i / POINTS => out[i].x;
        // Find bin j that corresponds to frequnecy i
        // Math.min(... MAX) prevents array out-of-bounds error
        // (MIN * Math.pow(MAX / MIN, i $ float / POINTS) gets log scale between MIN and MAX
        Math.min((MIN * Math.pow(MAX / MIN, i $ float / POINTS) * fft.size() / SR), MAX) $ int  => int j;
        // This is a weighted representation of the true spectrum towards the ends
        // Second term rewards frequency towards both ends
        (2 + Std.fabs(i-out.size()/2) / out.size() * 2) => float SCALE_SIDES;
        // map weighted frequency bin magnitide in Y
        SCALE_SIDES * SPEC_SCALE * Math.sqrt( (in[j-1]$polar).mag ) => out[i].y;
    }
}

// map audio buffer to *tuned* 3D positions (line 113, 115)
fun void map2waveform( float in[], vec2 out[], float hp )
{   
    // mapping to xyz coordinate
    0.2 => float width;
    for (int i; i < in.size(); i++)
    {
        // space evenly in Y
        -width/2 + width/WINDOW_SIZE*i - 0.8 => out[i].y;
        // map y, using window function to taper the ends; also tuned to right location
        in[i] * 2 * window[i] - 4.3 + 1.4 * hp / 100 => out[i].x;
    }
}

// do audio stuff (copy-pasted)
fun void doAudio()
{
    while( true )
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output( samples );
        // upchuck to take FFT, get magnitude response
        fft.upchuck() ;
        // get spectrum (as complex values)
        fft.spectrum( response );
        // jump by samples
        WINDOW_SIZE::samp/2 => now;
    }
}

// Detects if the spectrum has sliced the apple
fun int slice(vec2 spectrum[], GModel apple)
{
    DISPLAY_WIDTH => float width;
    apple.scaWorld() => vec3 appleScale;
    // Find range of target x bins
    ((apple.posX() - appleScale.x / 2.0 + width / 2.0) * POINTS / width) $ int => int xMin;
    ((apple.posX() + appleScale.x / 2.0 + width / 2.0) * POINTS / width) $ int => int xMax;
    // To slice apple, spectrum must reach this within range of x bins
    apple.posY() - appleScale.y / 2.0 => float appleMin; 

    // Where to start searching for range of x bins
    Math.max(xMin, 0) $ int => int startI;

    // Within target range, see if spectrum exceeds appleMin
    for(startI => int i; i <= xMax && i < spectrum.size(); i++)
    {
        if(spectrum[i].y > appleMin)
        {
            return 10; // meaningless
        }
    }
    return 0;
}

0 => int sliced;
0 => float t;

// Makes a new apple, and plans for its demise
fun void makeApple(vec2 spectrum[])
{   
    // Determine apple's next position
    Math.random2f(-4.0, 4.0) => float x;
    Math.random2f(-0.5, 1.5) => float y;

    // Spawn new apple
    GModel apple(APPLE_PATH) --> GG.scene();
    apple.sca(APPLE_SCALE);
    apple.pos(@(x,y,0));

    0 => sliced;
    while(sliced==0)
    {
        100::ms => now;
        if(slice(spectrum, apple) == 10) // if sliced == true
        {
            apple --< GG.scene(); // remove apple
            updateHP(hp, spectrum, 8, SCORE) => hp; // boost HP

            // Set up sound effect (copy-pasted from wind.ck)
            Noise n => BiQuad f => dac;
            // set biquad pole radius
            .99 => f.prad;
            // set biquad gain
            .2 => f.gain;
            // set equal zeros 
            1 => f.eqzs;
            // our float
            0.0 => t;

            while(t < 0.2)
            {
                // sweep the filter resonant frequency
                100.0 + Std.fabs(Math.sin(t)) * 15000.0 => f.pfreq;
                t + .01 => t;
                // advance time
                5::ms => now;
            }

            10 => sliced; // break loop
            n =< dac; // end sound effect
        }
    }
    SCORE + 1 => SCORE; // update score
    makeApple(spectrum); // make new apple
}

// HP diminishes according to spectrum magnitude, and boosts with each apple slice
fun float updateHP(float hp_temp, vec2 spectrum[], int sliced, int SCORE)
{
    0 => float curAmp;
    for(vec2 s : spectrum) // Calculate total spectrum energy
    {
        curAmp + s.y => curAmp;
    }
    // Controls rate of deduction for HP
    hp_temp - Math.sqrt(curAmp) * 0.01 * Math.sqrt(Math.sqrt(SCORE+1)) => hp_temp;
    return Math.min(hp_temp + sliced, INIT_HP); // No infinite HP
}

// Title text but also HP and score and HP bar
fun void title()
{
    while(true)
    {
        GText title --> GG.scene();
        title.text("FFruiT Ninja");
        @(0.4, 0.2, 0.2) => title.color;

        GCube HPBar --> GG.scene();
        HPBar.scaX(2.8);
        HPBar.scaY(0.2);
        HPBar.scaZ(0.01);
        HPBar.pos(@(-3.4, 3.37, -1));
        HPBar.color(@(0.5, 0, 0));

        GText HP --> GG.scene();
        HP.text("HP");
        @(0.4, 0.4, 0.4) => HP.color;
        HP.sca(0.2);
        HP.pos(@(-4.5, 3.0, 0.0));

        GText score --> GG.scene();
        score.text("Score: " + SCORE);
        @(0.4, 0.4, 0.4) => score.color;
        score.sca(0.2);
        score.pos(@(-4.28, 2.7, 0.0));

        100::ms => now;

        score --< GG.scene(); // so that score numbers don't overlay
    }
}

fun void growl() // suzanne growls; copied from piano.ck
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

fun void fireSuzanne()
{   
    spork ~growl(); // suz growls as game ends
}

spork ~makeApple(spectrumPositions);
spork ~title();
spork ~doAudio();

// graphics render loop
while( true )
{
    updateHP(hp, spectrumPositions, 0, SCORE) => hp;

    if(hp > 0)
    {
        // next graphics frame
        GG.nextFrame() => now;
        // map to interleaved format
        map2waveform( samples, waveformPositions, hp );
        // set the mesh position
        waveform.positions( waveformPositions );
        // map to spectrum display
        map2spectrum( response, spectrumPositions );
        // set the mesh position
        spectrum.positions( spectrumPositions ); // chugl
    }
    else // GAME OVER
    {
        fireSuzanne();
        1::second => now;
        me.exit();
    }
}