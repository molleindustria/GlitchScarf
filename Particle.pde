class Particle {

  //PImage img;
  int x, y, px, py;
  float w = 10;
  float h = 10;
  float vx = 0;
  float vy = 0;
  boolean visible;
  color colA = color(random(255), random(255), random(255));
  color colB = color(random(255), random(255), random(255));
  color effectColor;
  color pColor;
  boolean dead = false;
  PGraphics canvas;
  int MAX_LIFE = 10;
  int life = 0;
  String type = "";
  int direction = 0;
  boolean inverter = false;
  
  
  Particle(String _t) {
    //img = loadImage(fname);
    visible = true;
    type = _t;
  }

  void render() {


    
      canvas.pushStyle();
      canvas.pushMatrix();
      canvas.translate(x, y);
      display();
      canvas.popMatrix();
      canvas.popStyle();
    
  }

  //appearance
  void display() {
    
    
    canvas.noStroke();

    color currentColor = canvas.get(x, y);

    if (currentColor == colB && inverter)
      canvas.fill(colA);
    else
      canvas.fill(colB);
    
    if(type == "spark")
      {
      color cooling = lerpColor(effectColor, colorA, map(life,0,MAX_LIFE,0,1));
      canvas.fill(cooling);
      }
    
    if(type == "shifter")
      {
      canvas.set(x, y, pColor);
      }
    
    if (visible)
      canvas.rect(0, 0, w, h);
    
    //goes in whatever direction linearly
    if (type=="bullet") {
      
      if (currentColor == colB) 
        {
        canvas.set(x, y, colA);
        canvas.set(px, py, colA);
        
        life = MAX_LIFE+1;
        
        }
      //x += vx;
      //y += vy;
    }

  }

  void update() {

    px = x;
    py = y;
    
    
    pColor = canvas.get(x, y);
    
    if (type == "bomb") {
      canvas.noStroke();
      canvas.fill(colA);
      canvas.ellipse(x, y, life, life);
      vx = 0;
      vy = 0;
    }

    if (type == "flame") {
      canvas.noStroke();
      canvas.fill(colB);
      canvas.ellipse(x, y, life, life);
    }

    if (type == "dasher") {
      if ((life-1)%3==0)
        visible = !visible;
    }

    if (type == "wanderer") {
      //change direction
      if (int(random(life))>MAX_LIFE/10) {

        int o = ((int)random(0, 2) == 0)? -1 : 1;
        direction += o;
        if (direction>3)
          direction=0;
        if (direction<0)
          direction=3;
      }
    }

    if (direction==0) {
      vx = 1;
      vy = 0;
    }
    if (direction==1) {
      vx = 0;
      vy = 1;
    }
    if (direction==2) {
      vx = -1;
      vy = 0;
    }
    if (direction==3) {
      vx = 0;
      vy = -1;
    }

    /*
     if (direction== -1) {
     vx = 0;
     vy = 0;
     }*/


    x += vx;
    y += vy;


    life++;

  }

  //reset color
  void kill() {
    
  }
}
