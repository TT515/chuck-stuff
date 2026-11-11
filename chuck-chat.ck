//-----------------------------------------------------------------------------
// name: chuckchat0.ck
// desc: Two users take turn chatting on a device
// 
// author: Tao-Tao He
// date: Nov. 10, 2026
//-----------------------------------------------------------------------------

@import "chodash";

GG.camera().orthographic(); // 2d scene, set camera to orthographic

global Event e; // triggered by [Enter]

1 => global int turn; // tracks whose turn it is to enter text
0 => global int stage; // tracks what stage the user is at

// Instructions
GText instruct --> GG.scene();
instruct.posY(-2.7);
instruct.text("Click [return] to continue");
instruct.sca(0.2);
instruct.color(@(0.1,0.1,0.1));

// These GCubes hide the text
global GCube cover1 --> GG.scene();
global GCube cover2 --> GG.scene();
cover1.scaX(5);
cover2.scaX(0); // hide cover 2 to start with
Color.RED => cover1.color;
Color.BLUE => cover2.color;
// These are the text on the covers
GText text11 --> cover1;
text11.text("Player 1");
text11.posZ(1.1);
text11.scaX(0.2);
GText text21 --> cover2;
text21.text("Player 2");
text21.posZ(1.1);
text21.scaX(0.2);

// The text for the user to enter
TextField userText(3.0) --> GG.scene();
userText.placeholder("Text").showBox(true).pos(-1.5,0,0);

// Function that reacts to [Enter]
fun void update(Event e)
{
    while(true)
    {
        e => now;
        
        if (stage==0) // Cover user text up
        {
            if (turn==1) {cover1.scaX(5);}
            else {cover2.scaX(5);}
        }
        else if (stage==1) // Uncover user text
        {
            if (turn==1) {cover1.scaX(0);}
            else {cover2.scaX(0);}
        }
        else
        {
            userText.text("");
        }
        1::ms => now; // GG.nextFrame() => now crashed
    }
}

e.broadcast();

// CHODASH!!!
// Copy-pasted from Chodash/text/commands.ck
// Focus the next field (e.g. after pressing Enter)
public class NextCommand extends Chommand {
    // Functions for updating turn and stage
    fun void updateTurn()
    {
        if (turn==1) {2 => turn;}
        else {1 => turn;}
    }
    fun void updateStage()
    {
        if (stage!=2) {stage++;}
        else 
        {
            0 => stage;
            updateTurn();
        }
    }

    fun void run() 
    { 
        updateStage();
        <<<stage>>>;
        e.broadcast();
    }
}

// Pressing enter on both the text field and not triggers the update in stage
NextCommand nextCommand();
Keyboard.bind(nextCommand, GWindow.KEY_ENTER);
userText.onSubmit(nextCommand);

spork ~update(e);

while(true)
{
    GG.nextFrame() => now;
    // Button.update();
    Keyboard.update();
    // Mouse.update();
    Text.update();
}
