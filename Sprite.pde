class Sprite {

  //PImage img;
  int x, y;
  float w = 1;
  float h = 1;
  float vx = 0;
  float vy = 0;
  boolean visible;
  color col = color(random(255), random(255), random(255));
  boolean dead = false;
  
  Sprite() {
    //img = loadImage(fname);
    visible = true;
  }

  void render(PGraphics canvas) {
    if (visible) { 
      canvas.pushStyle();
      canvas.pushMatrix();
      canvas.translate(x, y);
      display(canvas);
      canvas.popMatrix();
      canvas.popStyle();
    }
  }

  //appearance
  void display(PGraphics canvas) {
    canvas.rectMode(CENTER);
    canvas.fill(col);
    canvas.rect(0, 0, w, h);
  }

  void update() {
    x += vx;
    y += vy;
  }

}


class Avatar extends Sprite
{
  color blinkColorA = color(0,0,0);
  color blinkColorB= color(255,255,255);
  
  @Override
  public void update() { 
    super.update();
    float t = abs(sin(float(frameCount)/5));
    
    col = lerpColor(blinkColorA, blinkColorB, t);
    
  }
}




class Bullet extends Sprite
{
  color targetColorr;
  int direction;

  @Override
  public void update() { 
    
    
    //color currentColor = knitCanvas.get(x, y);

    /*
    if (currentColor == targetColor) {
     // knitCanvas.set(x,y,newColor);
     println("WHA"); 
    }*/
    
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


    x += vx;
    y += vy;
    
  }
}
