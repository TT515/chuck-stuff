//-----------------------------------------------------------------------------
// name: chuckmas.ck
// desc: Two users take turn chatting on a device
// 
// author: Tao-Tao He
// date: Nov. 17, 2026
//-----------------------------------------------------------------------------

@import "chodash";

GG.camera().orthographic(); // 2d scene, set camera to orthographic

// just get my image into the background...
// With help from Alex
me.dir() + "assets/chuckmas.png" => string BG_PATH;
TextureLoadDesc load_desc;
true => load_desc.flip_y;
true => load_desc.gen_mips;
Texture.load(
    BG_PATH, load_desc
) @=> Texture tree;

FlatMaterial sprite_material;
sprite_material.colorMap(tree); // texture
GMesh sprite(new PlaneGeometry, sprite_material) --> GG.scene();
sprite.sca(6.6);
sprite.posZ(-20);

// Function for playing a note (copied from my bagua_chord_sequencer.ck)
fun void playNote(int midiNote, float gain, float mod, dur length)
{
    if(false)    
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

global Event e; // triggered by person opening a loaded gift
global Event c; // triggered by person closing gift

// Instructions
GText instruct --> GG.scene();
instruct.posY(3.0);
// instruct.posX(0.4);
instruct.text("Fill a gift, or open yours!");
instruct.sca(0.4);
instruct.color(@(0,0,0));
instruct.font("./assets/bakery.ttf");

// giftContent class: what each gift contains
class giftContent
{
    string message;
    // int[] recording; WILL DO

    fun giftContent() {return;}
    fun giftContent(string msg) {msg => this.message;}

    fun updateMessage(string msg) {msg => this.message;}

    fun string getMessage() {return this.message;}
}

// Gift class: each gift has a state: empty, in-progress, filled
class gift extends Button
{
    string state; // empty, in-progress, or filled
    string sender; // who sent the gift?
    giftContent content; // What the gift contains
    GPlane bubble --> this; // contains text
    GText status --> this;
    bubble.scaY(0.3);
    bubble.color(@(0.1,0.1,0.1));
    bubble.alpha(0.7);
    status.sca(0.25);
    status.font("./assets/Venite.ttf");
    status.color(@(0.6,1,1));

    fun gift()
    {
        "Empty" => this.state;
        status.text(this.state);
        this.sca(0.8);
        this.posZ(1.1);
    }

    fun updateContent(giftContent content) {content @=> this.content;}

    fun giftContent getContent() {return this.content;}

    fun updateStatus(string state) {state @=> this.state; this.status.text(state);}

    fun string getStatus() {return this.status.text();}

    fun updateSender(string sender) {sender @=> this.sender;}

    fun string getSender() {return this.sender;}
}

// GUI for wrapping a gift
GGen giftGUI;
// TextFields for the sender to enter
TextField senderText(5.0) --> giftGUI;
senderText.placeholder("Who is sending the gift?").showBox(true).pos(-2.5,0,0);
senderText.posY(1.5);
senderText.font("./assets/Venite.ttf");
senderText.color(@(0,1,0)).boxColor(@(0.3,0,0));
TextField giftText(5.0) --> giftGUI;
giftText.placeholder("What do you want to say?").showBox(true).pos(-2.5,0,0);
giftText.posY(0.5);
giftText.font("./assets/Venite.ttf");
giftText.color(@(0,1,0)).boxColor(@(0.3,0,0));
TextField reciptentText(5.0) --> giftGUI;
reciptentText.placeholder("Who is receiving the gift?").showBox(true).pos(-2.5,0,0);
reciptentText.posY(-0.5);
reciptentText.font("./assets/Venite.ttf");
reciptentText.color(@(0,1,0)).boxColor(@(0.3,0,0));
// Box, with additive synthesis, but i don't think these actually do anything
GCube box --> giftGUI;
box.color(@(0,0.1,0));
box.sca(25).scaZ(0.012).posZ(-0.01);
// GCube boxForBlendRight --> giftGUI;
// boxForBlendRight.color(@(0.9,0.4,0.9));
// boxForBlendRight.sca(10).scaZ(0.012).pos(@(5,-5,-0.02));
// GCube boxForBlendLeft --> giftGUI;
// boxForBlendLeft.color(@(0.9,0.4,0.9));
// boxForBlendLeft.sca(10).scaZ(0.012).pos(@(-5,-5,-0.02));
// Buttons to wrap / abandon gift
Button abandon --> giftGUI;
Button wrap --> giftGUI;
GCube cancelBox --> abandon;
GCube okBox --> wrap;
GText okay --> giftGUI;
GText canc --> giftGUI;
wrap.pos(@(1.4,-1.5,1.0011));
wrap.scaX(2.33);
wrap.scaY(0.36);
wrap.scaZ(0.1);
abandon.pos(@(-1.4,-1.5,1.0011));
abandon.scaX(2.33);
abandon.scaY(0.36);
abandon.scaZ(0.1);
okBox.color(@(0.6,0,0));
cancelBox.color(@(0.6,0,0));
okay.pos(@(1.4,-1.51,1.11));
okay.sca(0.24);
canc.pos(@(-1.4,-1.5,1.11));
canc.sca(0.24);
okay.color(@(0.2,0.5,0));
canc.color(@(1,0.2,1));
okay.text("Wrap Gift");
canc.text("ABANDON");
okay.font("./assets/Venite.ttf");
canc.font("./assets/World Conflict .ttf");
// Don't add to GG.scene until prompted
// giftGUI --> GG.scene();
giftGUI.sca(1.5).posZ(1.2);

// Add gift tags to scene
gift gift1() --> GG.scene();
gift gift2() --> GG.scene();
gift gift3() --> GG.scene();
gift gift4() --> GG.scene();
gift gift5() --> GG.scene();
gift1.pos(@(-1.5,-3.1,1.1));
gift2.pos(@(-0.9,-2.4,1.1));
gift3.pos(@(0.3,-2.05,1.1));
gift4.pos(@(0.57,-2.9,1.1));
gift5.pos(@(1.1,-3.1,1.1));

// GUI for opening a gift
fun string giftMessage(gift curGift)
{
    curGift.getSender() => string sender;
    curGift.getStatus() => string reciptent;
    curGift.getContent().getMessage() => string message;

    "Dear " + reciptent + ", \n\n" + message + "\n\n" + "Yours,\n" + sender => string gm;
    return gm;
}

// Function for editing gift while not crashing program
fun void editGift(gift targetGift)
{
    giftGUI --> GG.scene();
    <<<targetGift.getStatus()>>>;
    10::ms => now;
    c => now; // Wait for either Wrap or Abandon to be clicked

    if (submit == 1) // Then update gift to new status
    {
        giftContent content(giftText.text());
        targetGift.updateSender(senderText.text());
        targetGift.updateStatus(reciptentText.text());
        targetGift.updateContent(content);
    }
    giftGUI --< GG.scene();
}

// Function for opening gift while not crashing program
fun void openGift(gift targetGift)
{
    GText gm;
    gm.font("./assets/bakery.ttf");
    gm.sca(0.6);
    gm.text(giftMessage(targetGift));
    gm --> GG.scene();
    gm.posZ(2);
    gm.color(@(1,1,1));
    GPlane black;
    black.sca(100).posZ(1.5);
    black.color(@(0,0,0));
    black --> GG.scene();
    
    // Last 10 seconds
    10::second => now;

    gm --< GG.scene();
    black --< GG.scene();
    return;
}

gift targetGift; // tracks which gift was selected
0 => global int submit;

// CHODASH: when a gift is selected...
class openGiftBox extends Chommand
{
    gift @ targetGift; // the selected gift
    string status;
    string sender;
    giftContent content;

    fun @construct(gift target) { 
        target @=> targetGift;
        targetGift.getSender() => this.sender;
        targetGift.getStatus() => this.status;
        targetGift.getContent() @=> this.content;
    }

    fun run()
    {
        if (targetGift.getStatus() == "Empty") // Then let user fill in gift
        {
            spork ~editGift(targetGift);
        }

        else // Unwrap gift
        {
            spork ~openGift(targetGift);
        }
    }
}

// The command for the "abandon" and "wrap" buttons
class triggerC extends Chommand
{
    int which; // change submit to 0 or 1?

    fun @construct(int which) {which => this.which;}

    fun void run()
    {
        which => submit;
        <<<submit>>>;
        c.broadcast();
    }
}

// Bind commands to buttons
gift1.onClick(new openGiftBox(gift1));
gift2.onClick(new openGiftBox(gift2));
gift3.onClick(new openGiftBox(gift3));
gift4.onClick(new openGiftBox(gift4));
gift5.onClick(new openGiftBox(gift5));
abandon.onClick(new triggerC(0));
wrap.onClick(new triggerC(1));

// if getStatus == "Empty": selected gift @=> targetGift
// Box pops up with two textfields
// if abandon is hit, go back
// if wrap gift is hit, update content & status
// else:
// enter new scene; black background; words show up
// after finished, fade, update content & status to null & "Empty"

while(true)
{
    GG.nextFrame() => now;
    Button.update();
    Keyboard.update();
    Mouse.update();
    Text.update();
}

// // These GCubes hide the text
// global GCube cover1 --> GG.scene();
// global GCube cover2 --> GG.scene();
// cover1.scaX(5);
// cover2.scaX(0); // hide cover 2 to start with
// Color.RED => cover1.color;
// Color.BLUE => cover2.color;
// // These are the text on the covers
// GText text11 --> cover1;
// text11.text("Player 1");
// text11.posZ(1.1);
// text11.scaX(0.2);
// GText text21 --> cover2;
// text21.text("Player 2");
// text21.posZ(1.1);
// text21.scaX(0.2);

// // The text for the user to enter
// TextField userText(3.0) --> GG.scene();
// userText.placeholder("Text").showBox(true).pos(-1.5,0,0);

// // Function that reacts to [Enter]
// fun void update(Event e)
// {
//     while(true)
//     {
//         e => now;
        
//         if (stage==0) // Cover user text up
//         {
//             if (turn==1) {cover1.scaX(5);}
//             else {cover2.scaX(5);}
//         }
//         else if (stage==1) // Uncover user text
//         {
//             if (turn==1) {cover1.scaX(0);}
//             else {cover2.scaX(0);}
//         }
//         else
//         {
//             userText.text("");
//         }
//         1::ms => now; // GG.nextFrame() => now crashed
//     }
// }

// e.broadcast();

// // CHODASH!!!
// // Copy-pasted from Chodash/text/commands.ck
// // Focus the next field (e.g. after pressing Enter)
// public class NextCommand extends Chommand {
//     // Functions for updating turn and stage
//     fun void updateTurn()
//     {
//         if (turn==1) {2 => turn;}
//         else {1 => turn;}
//     }
//     fun void updateStage()
//     {
//         if (stage!=2) {stage++;}
//         else 
//         {
//             0 => stage;
//             updateTurn();
//         }
//     }

//     fun void run() 
//     { 
//         updateStage();
//         <<<stage>>>;
//         e.broadcast();
//     }
// }

// // Pressing enter on both the text field and not triggers the update in stage
// NextCommand nextCommand();
// Keyboard.bind(nextCommand, GWindow.KEY_ENTER);
// userText.onSubmit(nextCommand);

// spork ~update(e);
