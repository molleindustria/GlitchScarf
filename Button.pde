
/*****************************************************************************************
 * 
 *   BUTTON CLASS
 * 
 ****************************************************************************************/
class Button
{
  float x, y, w, h;
  color c;
  color cOver;
  String txt = "";
  int txtSize = 32;
  boolean hasText = false;
  
  /****************************************************************************
   
   CONSTRUCTOR
   
   ****************************************************************************/
  Button (float _x, float _y, float _w, float _h, color _c, color _cover)
  {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    c = _c;
    cOver = _cover;
  }

  /****************************************************************************
   
   DISPLAY THE BUTTON
   
   ****************************************************************************/
  void display()
  {
    pushStyle();
    textAlign(CENTER, CENTER);
    if (mouseOver())
      fill(cOver);
    else
      fill(c);
    stroke(cOver);
    strokeWeight(1);
    rect(x, y, w, h);
    fill(0);
    if (txt.equals("")==false) {
      textSize(txtSize);
      text(txt, x+w/2, y+h/2);
    }
    popStyle();
  }


  /****************************************************************************
   
   CHANGE THE TEXT ON THE BUTTON
   
   ****************************************************************************/
  void setText (String _txt)
  {
    txt = _txt;
    display();
  }

  /****************************************************************************
   
   IS THE MOUSE OVER THE BUTTON?
   
   ****************************************************************************/
  boolean mouseOver()
  {
    return (mouseX >= x && mouseX <= (x + w) && mouseY >= y && mouseY <= (y + h));
  }
} // Button
