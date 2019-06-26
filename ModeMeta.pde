import processing.sound.*;

class ModeMeta {

  PImage icon;
  String id;
  String name;
  SoundFile sound;

  int startTime = 0;
  //sound
  int instances = 0;

  public ModeMeta(String _id, String _name) {//String iconFile
    id = _id;
    name = _name;

    //load icon load file
  }

  
  public void playSound(float minRate, float maxRate, int maxInst, boolean jump) {
    playSound(minRate, maxRate, maxInst, jump, 1);
  }
  
  public void playSound(float minRate, float maxRate, int maxInst, boolean jump, float vol) {

    if (millis() - startTime < sound.duration()*1000)
    {
      //println("SOUND IS PLAYING"+millis()+" "+startTime+" "+sound.duration());
      instances++;
      if (instances>maxInst) {
        sound.stop();
        instances = 0;
      }
    } else {
      startTime = millis();
    }
    
    if(jump)
      sound.jump(random(sound.duration()));
    
    sound.amp(vol);
    sound.rate(random(minRate, maxRate));
    sound.play();
  }
}
