/*
based on specs here
 http://ayab-knitting.com/development/
 */

/*

 This example takes knitting lines from a shifting images 
 so I can use processing drawing capabilities instead of dealing with arrays
 */

/*
to do 
 
 
 */

import processing.sound.*;
import processing.serial.*; 
import processing.event.KeyEvent;


color colorA = color(255,255,255);//color(49, 96, 152);//color(255, 18, 18);//color(255, 255, 255);
color colorB = color(0 ,164,250);//color(206, 203, 198); //color(0, 0, 0);//

color drawColor;

int portNumber = 3;

Serial myPort;    // The serial port
String inString;  // Input string from serial port
int lf = 10;      // ASCII linefeed 

//these have to be divisible by 2
int IMAGE_WIDTH = 40;//64;
int TOT_NEEDLES = 200;

//scarf
ArrayList<int[]> history;
//the current line that will be added to the scarf
int[] lineData = new int[IMAGE_WIDTH];

//glitch buttons
Button startKnitting;
//Button changePattern;

//25
int startNeedle = IMAGE_WIDTH;//TOT_NEEDLES/2+IMAGE_WIDTH/2; //this is good
int stopNeedle = 198;//TOT_NEEDLES/2-IMAGE_WIDTH/2;  //this is not
//(Range: 0..198)

//if (i<(TOT_NEEDLES/2 - IMAGE_WIDTH/2) || i>=(TOT_NEEDLES/2 + IMAGE_WIDTH/2) ) {
    

int currentLine = 0;

boolean connected = false;
boolean ready = false;
boolean handshake = false;
boolean resetMessage = false;


color avatarColor = color(200, 200, 200);

color drawingColor = colorB;

//GUI 
int BUTTON_W = 250;
int BUTTON_H = 50;
int MARGIN = 20;

//pixelated canvas
PGraphics canvas;
PGraphics overlay;
int canvasScale;
PFont pixelFont;
PFont bigFont;

//how many lines of the square canvas are reserved to history (non drawable?)
int HISTORY_LINES = 6;


//is the scrolling visualized going down (toilet paper) or up (typewriter)
boolean SCROLL_DOWN = true;

int cMouseX, cMouseY, previousMouseX, previousMouseY;
int CANVAS_X, CANVAS_Y;

boolean nextLine = false;
boolean clearCanvas= false;

//canvas height, not related to machine setup but mere visualization of history and future knits
int IMAGE_HEIGHT;
int IMAGE_BOTTOM; //minus history lines

//game stuff
ArrayList<Sprite> sprites;
Avatar avatar;

//particles always render on canvas
ArrayList<Particle> particles;


int PATTERN_REPEAT = 5; //probably better if divisible

boolean[] KEYS; 
boolean beginning;
int beginningLines;

int avatarDir = 0;
int directionDelay = 0;
int DIR_DELAY = 2;

boolean moved = true;
boolean firstAction = false;
boolean actionJustPress = false;
boolean colorPicked = false;
int actionDuration = 0;

//String[] modes = {"artifacts", "shiftline", "stretcher", "negaline", "smearer", "ants", "debug", "abomb"}; 

ModeMeta[] modes = new ModeMeta[] {
  new ModeMeta("artifacts", "ART.FACTS"), 
  new ModeMeta("shiftline", "LNSHFT<<<"), 
  new ModeMeta("stretcher", "STRRRRCHR"), 
  new ModeMeta("negaline", "N3GAB1T"), 
  new ModeMeta("smearer", "^SMEARUP^"), 
  new ModeMeta("ants", "BUG1234"), 
  new ModeMeta("debug", "DEBUG"), 
  new ModeMeta("abomb", "THE-NOTHING")
};

ModeMeta[] drawModes = new ModeMeta[] {
  new ModeMeta("pencil", "PIXEL"), 
  new ModeMeta("symmetry", "SYMMETRY"), 
  new ModeMeta("pattern4x4", "4x4"), 
  new ModeMeta("pattern8x8", "8x8"), 
  new ModeMeta("pattern4x8", "4x8"), 
  new ModeMeta("pattern8x8s", "8x8 OFF"), 
  new ModeMeta("clearAll", "CLEAR ALL"), 
  new ModeMeta("fillAll", "FILL ALL")
};


PatternMeta[] patterns = new PatternMeta[] {
  //geometric
  new PatternMeta("p21.png", 4, 8), 
  new PatternMeta("p18.png", 8, 10), 
  new PatternMeta("p16.png", 8, 10), 
  new PatternMeta("p11.png", 4, 8), 
  new PatternMeta("p22.png", 6, 12), 
  new PatternMeta("p18.png", 4, 8), 
  new PatternMeta("p33.png", 8, 16), 

  //winter
  new PatternMeta("p23.png", 2, 4), 
  new PatternMeta("p10.png", 1, 2), 
  new PatternMeta("p24.png", 4, 8), 
  new PatternMeta("p25.png", 1, 2), 
  new PatternMeta("p14.png", 1, 2), 
  new PatternMeta("p15.png", 1, 2), 
  new PatternMeta("p15.png", 1, 2), 

  //modern
  new PatternMeta("p7.png", 2, 6), 
  new PatternMeta("p4.png", 2, 6), 
  new PatternMeta("p9.png", 2, 6), 
  new PatternMeta("p13.png", 6, 12), 
  new PatternMeta("p31.png", 2, 4), 
  //new PatternMeta("p32.png", 3, 6),
  new PatternMeta("p34.png", 4, 8), 

  //folk
  new PatternMeta("p27.png", 1, 2), 
  new PatternMeta("p28.png", 1, 2), 
  new PatternMeta("p29.png", 1, 2), 
  //new PatternMeta("p30.png", 3, 6),
  new PatternMeta("p35.png", 1, 2), 
  new PatternMeta("p36.png", 1, 2), 


};

SoundFile explosion;
SoundFile changeMode;
SoundFile endLine;

boolean simulation = false;
float ENDLINE_VOLUME = 0.5;

boolean drawMode = false;

//"paint", "abomb"
int modeInd = 0;
String mode = modes[modeInd].id;

PImage patternImage;
int patternLine;
int patternRepetitions;
int patternTotal;

//ArrayList<PatternMeta> patterns;

int PATTERNS = 25+1;

color BLACK = color(0, 0, 0);
color WHITE = color(255, 255, 255);

int lines = 0;
SoundFile currentSound;

void settings() {
  fullScreen();
  size(1280, 800, P2D);
}

void setup() { 
  noSmooth();

  frameRate(30);
  canvas = createGraphics(IMAGE_WIDTH, IMAGE_WIDTH, P2D);
  canvas.noSmooth();
  ((PGraphicsOpenGL)canvas).textureSampling(POINT);

  overlay = createGraphics(IMAGE_WIDTH, IMAGE_WIDTH, P2D);
  overlay.noSmooth();
  ((PGraphicsOpenGL)overlay).textureSampling(POINT);

  // List all the available serial ports: 
  printArray(Serial.list()); 
  // I know that the first port in the serial list on my mac 
  // is always my  Keyspan adaptor, so I open Serial.list()[0]. 
  // Open whatever port is the one you're using. 
  if (Serial.list().length>portNumber) {
    myPort = new Serial(this, Serial.list()[portNumber], 115200); 
    myPort.bufferUntil('\n'); 
    connected = true;
  } else
  {
    println("Error there's no port "+portNumber);
  }

  if (IMAGE_WIDTH%2!=0)
    println("MAKE THE IMAGE WITH DIVISIBLE BY 2");

  //history is an array list of array integers (variable) that contains all the previously knitted lines
  history = new ArrayList<int[]>();
  sprites = new ArrayList<Sprite>();
  particles = new ArrayList<Particle>();
  beginning = true;
  beginningLines = 0;
  //reset line data
  for (int i = 0; i<IMAGE_WIDTH; i++)
  {
    lineData[i] = 0;
  }


  //buttons

  startKnitting =  new Button(width/2-BUTTON_W/2, height/2-BUTTON_H/2, BUTTON_W, BUTTON_H, color(190), color(255));
  startKnitting.setText("START KNITTING");

  //find the canvas scale
  if (width > height) {
    canvasScale = int(height/IMAGE_WIDTH);
  } else
    canvasScale = int(width/IMAGE_WIDTH);

  print("canvas scale is "+canvasScale);

  background(0); 

  CANVAS_X = width/2-IMAGE_WIDTH*canvasScale/2; //non zero positions are not working yet
  CANVAS_Y = 0;
  //let's make it square to start
  IMAGE_HEIGHT = IMAGE_WIDTH;
  IMAGE_BOTTOM = IMAGE_HEIGHT-HISTORY_LINES;

  pixelFont = loadFont("Small-5x3-8.vlw");
  bigFont = loadFont("Small-5x3-32.vlw");

  //load icons
  for (int i=0; i<modes.length; i++) {
    modes[i].icon = loadImage(modes[i].id+".png");
    modes[i].sound = new SoundFile(this, modes[i].id+".aif");
  }

  for (int i=0; i<patterns.length; i++) {
    patterns[i].file = loadImage(patterns[i].fileName);
  }

  /*
  canvas.beginDraw();
   canvas.background(colorA);
   canvas.fill(colorB);
   canvas.textFont(pixelFont, 8);
   canvas.textLeading(6);
   //canvas.text("LOREM IPSUM ipsum dolor sit amet, consectetur ante", 0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
   
   canvas.endDraw();
   */

  /////////
  //sprites
  avatar = new Avatar();
  avatar.w = 1;
  avatar.h = 1;
  avatar.x = (int)IMAGE_WIDTH/2;
  avatar.y = (int)IMAGE_HEIGHT/2;
  avatar.col = avatarColor;

  sprites.add(avatar);

  clearCanvas = true;

  KEYS = new boolean[255];

  explosion = new SoundFile(this, "explosion.aif");
  changeMode = new SoundFile(this, "bip.aif");
  endLine = new SoundFile(this, "endLine.aif");

  drawMode = false;

  changePattern();

  pixelFont = loadFont("Small-5x3-8.vlw");
} 

void draw() { 

  background(0);
  moved = false;

  //game logic
  //free movements
  if (KEYS[LEFT])
  {
    if (avatarDir!=2)
      directionDelay=0;

    if (directionDelay==0) {
      avatar.x -= 1;
      moved = true;
      directionDelay = DIR_DELAY;
    } else 
    directionDelay--;

    avatarDir = 2;
  } else if (KEYS[RIGHT])
  {
    if (avatarDir!=0)
      directionDelay=0;

    if (directionDelay==0) {
      avatar.x += 1;
      moved = true;
      directionDelay = DIR_DELAY;
    } else 
    directionDelay--;

    avatarDir = 0;
  } else if (KEYS[UP])
  {
    if (avatarDir!=3)
      directionDelay=0;

    if (directionDelay==0) {
      avatar.y -= 1;
      moved = true;
      directionDelay = DIR_DELAY;
    } else 
    directionDelay--;

    avatarDir = 3;
  } else if (KEYS[DOWN])
  {

    if (avatarDir!=1)
      directionDelay=0;

    if (directionDelay==0) {
      avatar.y += 1;
      moved = true;
      directionDelay = DIR_DELAY;
    } else 
    directionDelay--;

    avatarDir = 1;
  }

  //debugging
  if (KEYS[76]) {
    ready = resetMessage = true;
    simulation = true;
    onLineRequest(currentLine);
  }

  //wrap around the screen horizontally
  if (avatar.x >= IMAGE_WIDTH) {
    avatar.x = 0;
  }

  if (avatar.x < 0) {
    avatar.x = IMAGE_WIDTH-1;
  }

  //stop vertically
  if (avatar.y < 0) {
    avatar.y = 0;
  }
  if (avatar.y > IMAGE_BOTTOM-1) {
    avatar.y = IMAGE_BOTTOM-1;
  }

  //what happens in the canvas goes in the knitting
  ////////////////////////////////////////////////////
  canvas.beginDraw();

  //canvas operations can only be done in the draw thread for some openGL reason so I use the flag

  if (clearCanvas) {
    clearCanvas = false;
    canvas.background(colorA);
  }

  if (nextLine || beginning)
  {
    nextLine = false;
    moved = true;
    boolean allA = true;
    boolean allB = true;

    //create an array with the next canvas line to go in history  
    for (int c=0; c<IMAGE_WIDTH; c++) {
      color col = canvas.get(c, IMAGE_BOTTOM-1);

      if (col == colorB) {
        lineData[c] = 1;
        allB = false;
      } else //if (col == colorA) 
      {
        lineData[c] = 0;
        allA = false;
      }
    }

    //fix full lines
    if (allA) {
      lineData[0] = 1;
      lineData[IMAGE_WIDTH-1] = 1;
      ///println("ALL A");
    }

    if (allB) {
      lineData[0] = 0;
      lineData[IMAGE_WIDTH-1] = 0;
      //println("ALL B");
    }

    if (!beginning)
      sendLine(currentLine, lineData);
    else
    {
      beginningLines++;
      if (beginningLines>=IMAGE_HEIGHT)
        beginning = false;
    }
    /*
    //store line in history
     //make a copy first, otherwise it would be passed as reference
     int[] lineCopy = new int[lineData.length];
     arrayCopy(lineData, lineCopy);
     //disabled for now, no use
     //history.add(lineCopy);
     */

    //move one line down
    canvas.pushStyle();
    canvas.stroke(colorA);
    //canvas.line(0, 0, canvas.width, 0);
    canvas.popStyle();

    canvas.copy(0, 0, canvas.width, canvas.height-1, 0, 1, canvas.width, canvas.height-1);

    //particles act if stuck on canvas
    for (int i=0; i<particles.size(); i++) {
      Particle p = particles.get(i);
      p.y++;
    }


    //pull the next line from the pattern
    for (int c=0; c<IMAGE_WIDTH; c++) {
      color col = patternImage.get(c%patternImage.width, patternLine);
      color pixColor = colorA;
      if (col == BLACK)
        pixColor = colorB;

      canvas.set(c, 0, pixColor); //god knows openGL pixel approximation
    }

    patternLine--;
    if (patternLine<0)
    {
      patternRepetitions++;
      if (patternRepetitions>=patternTotal)
        changePattern();
      patternLine = patternImage.height-1;
    }
  }//end next line


  //render all the particles
  for (int i=0; i<particles.size(); i++) {
    Particle p = particles.get(i);

    //kill
    if (p.life > p.MAX_LIFE || p.x <0 || p.x > IMAGE_WIDTH || p.y<0 || p.y >= IMAGE_BOTTOM-1) {
      particles.remove(p);
      p = null;
    } else
    {
      p.render();
      p.update();
    }
  }

  //http://keycode.info/ 

  //autofire
  if (KEYS[90] && firstAction) {
    actionDuration++;

    if (mode == "abomb") {
      if (actionDuration<=1)
      {
        //explosion.stop();
        explosion.play();
        explosion.amp(0.5);

        Particle p = createParticle(avatar.x, avatar.y, "bomb");
        p.life=0;
        p.MAX_LIFE = 5;
        p.direction = -1;
      } else if (actionDuration/2+2<IMAGE_BOTTOM-avatar.y)
      {

        modes[modeInd].playSound(0.5, 2, 4, false);

        /*
        currentSound.stop();
         currentSound.play();
         currentSound.rate(random(0.5, 2));
         */
        Particle p = createParticle(avatar.x, avatar.y, "bomb");
        p.life=actionDuration;
        p.MAX_LIFE = actionDuration+5;
        p.direction = -1;
      }
    }

    if (mode=="erode")
    {
      for (int i=0; i<3; i++) {
        float a = radians(random(0, 360));
        float d = random(1, 4);
        Particle p = createParticle(int(avatar.x+cos(a)*d), int(avatar.y+sin(a)*d), "spark");
        p.effectColor = WHITE;
        p.MAX_LIFE = 6;
        p.direction = -1;
      }
    }

    if (mode == "smearer") {

      if (frameCount%4==0) {
        //currentSound.stop();
        modes[modeInd].playSound(0.4, 4, 4, false);
      }

      int d = int(random(2, IMAGE_WIDTH/3));
      canvas.copy(avatar.x-d/2, avatar.y-1, d, 8, avatar.x-d/2, avatar.y-2, d, 8);
    }

    if (mode=="ants" && frameCount%2==0) {
      Particle p = createParticle(avatar.x, avatar.y, "wanderer");
      p.MAX_LIFE = 30;
      p.inverter = true;
      p.direction = (int)random(0, 4);


      modes[modeInd].playSound(0.8, 1.2, 4, false, 0.1);



      //println(">"+currentSound.isPlaying());
      //if (currentSound.isPlaying()==1)
      //  currentSound.stop();
      //else {

      //}
      //}
    }

    if (mode=="stretcher") {
      //currentSound.stop();
      //currentSound.play();
      modes[modeInd].playSound(0.5, 5, 4, false, 0.5);


      canvas.copy(0, avatar.y, IMAGE_WIDTH, IMAGE_BOTTOM-avatar.y-1, 0, avatar.y+1, IMAGE_WIDTH, IMAGE_BOTTOM-avatar.y-1);
    }


    if (mode == "shiftline") {

      //actionDuration

      modes[modeInd].playSound(0.5, 2, 4, false, 0.5);



      if (avatarDir==2) {
        canvas.copy(1, avatar.y-1, IMAGE_WIDTH, 1, 0, avatar.y-1, IMAGE_WIDTH, 1);
        canvas.copy(2, avatar.y, IMAGE_WIDTH, 1, 0, avatar.y, IMAGE_WIDTH, 1);
        canvas.copy(1, avatar.y+1, IMAGE_WIDTH, 1, 0, avatar.y+1, IMAGE_WIDTH, 1);
      } else {

        canvas.copy(0, avatar.y-1, IMAGE_WIDTH, 1, 1, avatar.y-1, IMAGE_WIDTH, 1);
        canvas.copy(0, avatar.y, IMAGE_WIDTH, 1, 2, avatar.y, IMAGE_WIDTH, 1);
        canvas.copy(0, avatar.y+1, IMAGE_WIDTH, 1, 1, avatar.y+1, IMAGE_WIDTH, 1);
      }
    }

    if (mode=="artifacts")
    {

      modes[modeInd].playSound(0.8, 2.5, 1, true, 0.1);

      for (int i=0; i<3; i++) {
        canvas.noStroke();

        if (int(random(0, 2))==0)
          canvas.fill(colorA);
        else
          canvas.fill(colorB);

        float ox = random(-10, 10);
        float oy = random(-5, 5);
        float rw = random(3, 10);
        float rh = random(1, 3);
        canvas.rectMode(CENTER);
        canvas.rect(avatar.x+ox, avatar.y+oy, rw, rh);
      }
    }
  }///end autofire

  //each press
  if (KEYS[90] && actionJustPress) { 

    if (mode=="paint")
    {
      Particle p = createParticle(avatar.x, avatar.y, "flame");
      p.direction = avatarDir;
    }




    if (mode == "debug") {

      //currentSound.stop();
      modes[modeInd].playSound(0.5, 2, 4, false);


      canvas.textFont(pixelFont, 8);
      canvas.textLeading(6);

      int ty = (avatar.y-avatar.y%6+lines%6);
      int rndColor = int(random(0, 2));
      int rnd = int(random(0, 6));
      String s = "ERROR";

      if (rnd ==0) s = "LINES:"+lines;
      if (rnd ==1) s = "POS:"+avatar.x+","+avatar.y;
      if (rnd ==2) s = "PTRN:"+patternLine+"/"+patternTotal;
      if (rnd ==3) s = "FPS:"+int(frameRate);
      if (rnd ==4) s = "DEBUG MODE";
      if (rnd ==5) s = "KNITS:"+lines*IMAGE_WIDTH;


      float w = s.length()*4;
      int tx = (avatar.x)-int(w/2);

      canvas.noStroke();
      canvas.rectMode(CORNER);
      canvas.fill(rndColor==0 ? colorA : colorB);
      canvas.rect(tx-tx%6, ty-6, w, 7);
      canvas.fill(rndColor==0 ? colorB : colorA);
      canvas.text(s, tx-tx%6+1, ty);
    }
  }

  //limited to new step
  if (KEYS[90] && (moved || actionJustPress)) { 
    actionJustPress = false;

    if (mode == "negaline") {

      modes[modeInd].playSound(0.5, 4, 4, false);

      Particle p = createParticle(avatar.x+1, avatar.y, "normal");
      p.MAX_LIFE = int(random(4, 20));
      p.direction = 0;//(int)random(0, 4);
      p.visible = true;
      p.inverter = true;

      p = createParticle(avatar.x, avatar.y, "normal");
      p.MAX_LIFE = int(random(4, 20));
      p.visible = true;
      p.inverter = true;
      p.direction = 2;//(int)random(0, 4);
    }
  }

  //repeated ACTIONS every step
  if (KEYS[90] && (moved || firstAction)) {

    if (!colorPicked)
    {
      color col = canvas.get(avatar.x, avatar.y);
      drawColor =  (col==colorB)? colorA : colorB;
      colorPicked = true;
    }

    if (mode == "pencil") {
      canvas.set(avatar.x, avatar.y, drawColor);
    }

    if (mode == "symmetry") {
      canvas.set(avatar.x, avatar.y, drawColor);
      //i know theres math for that
      if (avatar.x < IMAGE_WIDTH/2)
        canvas.set(IMAGE_WIDTH/2+(IMAGE_WIDTH/2-avatar.x), avatar.y, drawColor);
      else
        canvas.set(IMAGE_WIDTH/2-(avatar.x-IMAGE_WIDTH/2), avatar.y, drawColor);
    }

    if (mode == "clearAll") {
      canvas.fill(colorA);
      canvas.noStroke();
      canvas.rectMode(CORNER);
      canvas.rect(0, 0, IMAGE_WIDTH, IMAGE_BOTTOM);
    }

    if (mode == "fillAll") {
      canvas.fill(colorB);
      canvas.noStroke();
      canvas.rectMode(CORNER);
      canvas.rect(0, 0, IMAGE_WIDTH, IMAGE_BOTTOM);
    }



    if (mode=="pattern4x4" || mode=="pattern8x8" || mode=="pattern4x8" || mode=="pattern8x8s") {

      int PATTERN_REPEAT_X, PATTERN_REPEAT_Y, PATTERN_OFFSET_Y;
      PATTERN_REPEAT_X = PATTERN_REPEAT_Y = 4;
      PATTERN_OFFSET_Y = 0;

      if (mode=="pattern4x4") {
        PATTERN_REPEAT_X = PATTERN_REPEAT_Y = 4;
      }

      if (mode=="pattern8x8") {
        PATTERN_REPEAT_X = PATTERN_REPEAT_Y = 8;
      }

      if (mode=="pattern4x8") {
        PATTERN_REPEAT_X = 4;
        PATTERN_REPEAT_Y = 8;
      }

      if (mode=="pattern8x8s") {
        PATTERN_REPEAT_X = 4;
        PATTERN_REPEAT_Y = 8;
        PATTERN_OFFSET_Y = 4;
      }


      for (int r=0; r<IMAGE_HEIGHT/PATTERN_REPEAT_Y; r++) {
        for (int c=0; c<IMAGE_WIDTH/PATTERN_REPEAT_X; c++) {
          firstAction = false;
          int px = int(avatar.x%(PATTERN_REPEAT_X)) + PATTERN_REPEAT_X*c;
          int py = int(avatar.y%(PATTERN_REPEAT_Y)) + PATTERN_REPEAT_Y*r;

          if (px%(PATTERN_REPEAT_X*2)==0)
            py += PATTERN_OFFSET_Y;

          if (py < IMAGE_BOTTOM && py <= avatar.y) {
            canvas.set(px, py, drawColor);
          }
        }
      }
    }
  }//actions


  canvas.endDraw();

  image(canvas, CANVAS_X, CANVAS_Y, IMAGE_WIDTH*canvasScale, IMAGE_HEIGHT*canvasScale); // draw canvas streched to sketch dimensions

  /////////////////////////////////////////////////////
  //what happens in the overlay after this doesn't affect the knits

  overlay.beginDraw();

  overlay.background(255, 255, 255, 0);



  //render all the sprites
  for (int i=0; i<sprites.size(); i++) {
    Sprite s = sprites.get(i);
    s.update();
    s.render(overlay);
  }

  //draw a rect to visualize history
  overlay.noStroke();
  overlay.fill(0, 0, 0, 50);
  overlay.rect(0, IMAGE_BOTTOM, IMAGE_WIDTH, HISTORY_LINES);

  overlay.endDraw();

  image(overlay, CANVAS_X, CANVAS_Y, IMAGE_WIDTH*canvasScale, IMAGE_HEIGHT*canvasScale); // draw canvas streched to sketch dimensions

  //////////////////////////////////////////////////////
  //everything below here is printed in the normal canvas

  //glitch mode
  if (!drawMode) {
    noStroke();
    textFont(bigFont, 32);
    //float tw = textWidth(modes[modeInd].name);
    textAlign(CENTER, BOTTOM);
    text(modes[modeInd].name, CANVAS_X/2, height/2);

    image(modes[modeInd].icon, CANVAS_X/2-64/2, height/2-88);
  } else {
    noStroke();
    textFont(bigFont, 32);
    //float tw = textWidth(modes[modeInd].name);
    textAlign(CENTER, BOTTOM);
    text(drawModes[modeInd].name, width-(CANVAS_X+IMAGE_WIDTH)/2, height/2);

    //image(modes[modeInd].icon, CANVAS_X/2-64/2, height/2-88);
  }

  //show start button
  if (!ready)
    startKnitting.display();
} 

void changePattern() {
  PatternMeta p = patterns[int(floor(random(0, patterns.length)))];
  patternImage = p.file;
  patternRepetitions = 0;
  patternTotal = int(floor(random(p.min, p.max)));
}

Particle createParticle(int x, int y, String type) {

  //sprites
  Particle p = new Particle(type);
  p.x = x;
  p.y = y;
  p.w = 1;
  p.h = 1;

  p.colB = colorB;
  p.colA = colorA;


  p.canvas = canvas;
  particles.add(p);
  return p;
}


//received whenever the operator completes a new line
//this is where the next line is assembled or passed
void onLineRequest(int lineNumber) {
  //println("reqLine received: requesting line "+lineNumber);
  /*
  //create an array with the next canvas line to go in history
   for (int c=0; c<IMAGE_WIDTH; c++) {
   color col = colorA;//canvas.get(c, IMAGE_BOTTOM-1);
   
   if (col == colorB)
   lineData[c] = 1;
   else //if (col == colorA)
   lineData[c] = 0;
   }
   
   sendLine(lineNumber, lineData);
   
   //store line in history
   //make a copy first, otherwise it would be passed as reference
   int[] lineCopy = new int[lineData.length];
   arrayCopy(lineData, lineCopy);
   history.add(lineCopy);
   */
  currentLine = lineNumber;
  nextLine = true;
  lines++;

  if (!simulation) {
    endLine.amp(ENDLINE_VOLUME);
    endLine.play();
  }
}


//button events
void mouseClicked() {

  if (!resetMessage)
    if (startKnitting.mouseOver()) {
      startup();
    }
}

public void keyReleased() {
  if (keyCode < 255) {
    KEYS[keyCode] = false;
  }
  directionDelay = 0;

  //
  if (mode=="artifacts") {

    //currentSound.stop();
  }
}

//keyboard events
public void keyPressed()
{

  firstAction = true;
  //println(keyCode+" < WHAT IS THIS");

  if (keyCode < 255) {
    KEYS[keyCode] = true;
  }

  //switch draw mode
  if (KEYS[67]) {
    drawMode = !drawMode;
    modeInd = 0;
    if (drawMode) {
      clearCanvas = true;
      mode = drawModes[modeInd].id;
    } else
      mode = modes[modeInd].id;
  }

  //X select mode
  if (KEYS[88]) {

    changeMode.play();
    modeInd++;

    if (drawMode) {
      if (modeInd>=drawModes.length)
        modeInd = 0;

      mode = drawModes[modeInd].id;
    } else {

      if (modeInd>=drawModes.length)
        modeInd = 0;

      mode = modes[modeInd].id;
    }

    //print(mode+ " ssss");
  }

  if (keyCode == 90) {
    colorPicked = false;
    //println("COLOR PICKES");
  }

  //Z action
  if (KEYS[90]) {
    actionJustPress = true;
    actionDuration = 0;

    /*
    if (mode == "negaline") {
     Particle p = createParticle(avatar.x, avatar.y, "normal");
     p.MAX_LIFE = 40;
     p.direction = 0;//(int)random(0, 4);
     p.visible = true;
     p.inverter = true;
     
     p = createParticle(avatar.x, avatar.y, "normal");
     p.MAX_LIFE = 40;
     p.visible = true;
     p.inverter = true;
     p.direction = 2;//(int)random(0, 4);
     }*/

    if (mode == "bullet") {
      //trailing
      Particle p = createParticle(avatar.x, avatar.y, "bullet");
      p.MAX_LIFE = 30;
      p.direction = avatarDir;//(int)random(0, 4);=        p.visible = true;
    }
  }


  //V
  if (KEYS[86]) {
    Particle p = createParticle(avatar.x, avatar.y, "bomb");
    p.MAX_LIFE = avatar.y-IMAGE_BOTTOM;
    p.direction = -1;
  }

  /*
  //N
   if (KEYS[78]) {
   Particle p = createParticle(avatar.x, avatar.y, "flame");
   p.direction = avatarDir;
   }*/

  //A
  if (KEYS[65]) {

    clearCanvas = true;
    /*
    if (drawingColor == colorA)
     drawingColor = colorB;
     else
     drawingColor = colorA;
     */
  }

  //quantized movements
  /*
  if (keyCode == LEFT)
   {
   avatar.x -= 1;
   } else if (keyCode == RIGHT)
   {
   avatar.x += 1;
   }
   
   if (keyCode == UP)
   {
   avatar.y -= 1;
   } else if (keyCode == DOWN)
   {
   avatar.y += 1;
   }
   */


  //used to simulate a new line request (prev line completed)
  if (key == 'l')
  {
    //onLineRequest(currentLine);
    //ready = resetMessage = true;
  }

  if (key == 'q') {
    startup();
  }

  if (key == 'w') {
    println("HISTORY");
    //output history from beginning
    for (int r = 0; r<history.size(); r++) {
      println();
      for (int c = 0; c<IMAGE_WIDTH; c++)
      {
        print(history.get(r)[c]);
      }
    }
  }
}



////////////////////////////////////////////////// MACHINE COMMUNICATION STUFF

//takes an array of int, turns into bits splits into 25 bytes and sends it as command
public void sendLine(int lineNumber, int imageLine[]) {

  imageLine = reverse(imageLine);

  //line is the whole bed
  int[] line = new int[TOT_NEEDLES];

  //put the line in the center of the bed
  //int imgIndex = 0;
  int imgIndex = 0;

  for (int i=0; i<TOT_NEEDLES; i++) {
    //outside image
    //if (i<(TOT_NEEDLES/2 - IMAGE_WIDTH/2) || i>=(TOT_NEEDLES/2 + IMAGE_WIDTH/2) ) {
      if (i<0 || i>=IMAGE_WIDTH ) {
    
      line[i] = 0;
    } else {
      //inside image
      line[i] = imageLine[imgIndex];
      imgIndex++;
    }
  }

  //println("Centered line");
  //printArray(line);

  byte lineBytes[] = new byte[25];

  //pack it into an array of bytes
  for (int by = 0; by<25; by++) {
    int newByte = 0;

    for (int b = 0; b<8; b++) {
      int newBit = line[(by*8)+b] << b;
      //println("Bit shifted "+binary(newBit));
      newByte = newByte | newBit;
    }
    lineBytes[by] = byte(newByte);
  }//end line bytearray


  //init the byte array to send out
  byte out[] = new byte[29];

  for (int i=0; i<29; i++) {
    out[i] = 0;
  }

  //merge the array with command and flags with the line data
  out[0] = byte(0x42);
  out[1] = byte(lineNumber); //line number
  for (int i=0; i<25; i++) {
    out[2+i] = lineBytes[i];
    //println("what I actually send " +binary(out[2+i]));
  }

  out[27] = byte(0x00); //last line: 1 = job done
  out[28] = byte(0x00); //checksum (possibly not implemented

  if (connected)
    myPort.write(out);
}

//converts a canvas x coordinate to world space
int unscaleX(int x) {
  return int(x*canvasScale + CANVAS_X*canvasScale);
}

int unscaleY(int y) {
  return int(y*canvasScale + CANVAS_Y*canvasScale);
}


//function converting 010101010101010 to {0,1...} etc
public int[] stringToInt(String str) {
  int[] arr = new int[IMAGE_WIDTH]; 

  for (int i=0; i<IMAGE_WIDTH; i++) {
    if (str.charAt(i)=='0')
      arr[i] = 0;
    else
      arr[i] = 1;
  }

  return arr;
}

void onHandShake() {
  println("cnfInfo received: handshake successful");
  handshake = true;
  //automatically send a request
  reqStart();
}


void onInit(boolean isReady) {
  if (isReady) {
    currentLine = 0;
    ready = true;

    println("cnfStart/indInit positive: ready to start");
  } else if (!resetMessage) {
    println("cnfStart/indInit received: Reset the carriage");
    resetMessage = true;
    //TODO startKnitting change text
  }
}

//called when the carriage is at in the starting position
void onReset(boolean isReset) {
  if (isReset)
    reqStart();
}

public void startup() {
  println("Sending reqInfo");

  if (connected)
    myPort.write(0x03);

  ready = false;
  handshake = false;
  resetMessage = false;
}

public void reqStart() {
  //the reqStart has to be sent continuously until the carriage is ready
  //the first line request will initiate the knitting
  println("Sending reqStart");
  byte out[] = new byte[4];
  out[0] = byte(0x01);
  out[1] = byte(0x01); //machine type KH 910
  out[2] = byte(startNeedle); //start needle (Range: 0..198)
  out[3] = byte(stopNeedle); //start needle (Range: 0..198)


  if (connected)
    myPort.write(out);
}


void serialEvent(Serial myPort) {
  inString = "";

  byte[] inBuffer = new byte[8];

  if (connected)
    while (myPort.available () > 0) {
      inBuffer = myPort.readBytes();
      myPort.readBytes(inBuffer);
      //inBufferfinal = inBuffer;

      if (inBuffer != null) {
        for (int i=0; i<inBuffer.length; i++) {
          inString = inString + hex(inBuffer[i])+" , " ;
        }

        //println(hex(inBuffer[1])+" wtf");

        if (hex(inBuffer[0]).equals("C3")) {
          onHandShake();
        }

        if (hex(inBuffer[0]).equals("C1")) {

          if (hex(inBuffer[1]).equals("00")) 
            onInit(false);

          if (hex(inBuffer[1]).equals("01")) 
            onInit(true);
        }

        if (hex(inBuffer[0]).equals("84")) {

          if (hex(inBuffer[1]).equals("00")) 
            onReset(false);

          if (hex(inBuffer[1]).equals("01")) 
            onReset(true);
        }

        if (hex(inBuffer[0]).equals("82")) {
          onLineRequest(inBuffer[1]);
        }
      }
    }
}
