
/*
Designed for velostat mat, for standing on.

Wire the velostat as a voltage divider. We put a 1K variable resistor (potentiometer) as R2.
Run "calibrate" sketch to calibrate: we want > 400 when no-stand, and < 200 when stand.

INSTALL
  install the sound library for processing.
  installed Firmata library for processing.
  in Arduino IDE upload StandardFirmata from Examples/Firmata
*/

//sound stuff
import processing.sound.*;   
import processing.serial.*;
SoundFile file;
PImage img_black;
PImage img_white;

import cc.arduino.*;
Arduino arduino;
int sensorPin = 0;
float sensorValue = 0;

int last_change;

void setup() {
  size(8000, 3667);
  background(255);
  setup_sound();
  setup_image();
  setup_velodetect();

  preload_images();

  last_change = 0;
}

void draw() {
  int change = stood_upon();

  if (stood_upon()) {
    show image white
      play
  } else {
    show image black
      stop playing
  }
  //draw_image();
  //draw_velodetect();
  //draw_sound();
}


int stood_upon() {
  // Return 1 when someone _starts_ to stand upon
  // Return 2 when they finish standing upon
  // Return 0 when nothing has changed

  int current_velo = arduino.analogRead(sensor_pin);

  Boolean new_state;
  if (current_velo < 100) {
    new_state = false;
  } else if (current_velo > 400) {
    new_state = true;
  }

  if (millis() - last_change < 200) { // debounce/shifting
    return 0;
  }
}

void setup_sound() {   
  // Load a soundfile from the /data folder of the sketch and play it back
  file = new SoundFile(this, "sound2.aif");
}
void draw_sound() {
  file.play();
}
//-------



void setup_image() {

  // The image file must be in the data folder of the current sketch 
  // to load successfully
  img_black = loadImage("map_black.jpg");  // Load the image into the program  
  img_white = loadImage("map_white.jpg");  //first time you draw the image, its slow
}


void draw_image() {
  // Displays the image at its actual size at point (0,0)
  //image(img, 0, 0);
  // Displays the image at point (0, height/2) at half of its size
  print("black...");
  image(img_black, 0, height/15, img_black.width/15, img_black.height/15);
  print("white...");
  image(img_white, 0, height/15, img_white.width/15, img_white.height/15);
}

void setup_velodetect()
{
  println(Arduino.list());

  arduino = new Arduino(this, Arduino.list()[3], 57600); //your offset may vary
  arduino.pinMode(sensorPin, 0);
}

void draw_velodetect()
{
  sensorValue = arduino.analogRead(0);
  println(sensorValue);
}  