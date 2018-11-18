
/*
Designed for velostat mat, for standing on.
 
 BEHAVIOR
 Init to
 * "black" image, no sound
 When stand-on:
 * trigger sound
 * wait for 1 seconds, show "white" image
 Whend stand-off:
 * stop sound
 * show "black" image
 
 Warning: We do not "clear" the canvas when switching images: we assume both images are the same size.
 
 WIRING/CALIBRATE/SETUP
 * Wire the velostat as a voltage divider. We put a 1K variable resistor (potentiometer) as R2.
 so, pressure drops the analogRead value,
 attach mid-point to A0
 * Install your mat, with rugs, etc., then:
 * Run "calibrate" sketch to calibrate: we want > 400 when no-stand, and < 200 when stand.
 * Attach the arduino to a usb port: 
 run this sketch and look at the port list,
 count from 0 till you find the arduino (on mac it looks like "????", on linux "/dev/ttyACM0").
 update the ArduinoPortIndex variable.
 * do not change physical ports, or you have to redo this.
 * Update the size(x,y) to match your screen
 * Update ImageScale to make images fit
 * Sound files should be 16-bit, AIFF (stereo). 8-bit doesn't work. AIFF-C may not work.
 
 INSTALL
 install the sound library for processing.
 installed Firmata library for processing.
 in Arduino IDE upload StandardFirmata from Examples/Firmata
 */

//sound stuff
import processing.sound.*;   
import processing.serial.*;
SoundFile soundfile;
final String SoundName = "sound2.aif";

// image stuff
PImage img_black;
PImage img_white;
final int ImageScale = 1; // Scale the image down to fit, could calculate based on screen size

// Arduino (velostat)
import cc.arduino.*;
Arduino arduino;
final int ArduinoPortIndex = 4; // cf. Arduino.list()
int sensorPin = 0; // A0 i.e. analog 0
float sensorValue = 0;

final int ImageDelay = 1000; // wait to show "white" image

// state/book-keeping
int last_change_at;
int last_state;
boolean standing_on;
boolean did_image;
boolean did_sound; // seem to need to play only once

void setup() {
  size(500, 500); // Adjust to actual screen size, is there magic constants for this?
  //size(8000, 3667); // Adjust to actual screen size, is there magic constants for this?
  background(255);
  setup_sound();
  setup_image();
  setup_velodetect();

  last_change_at = 0;
  last_state = 0; // no change
  standing_on = false;
  did_image = false;

  println("Ready");
}

void draw() {

  // Only deal with changes:
  int change = stood_upon();

  if (change == 1) {
    println("On/(black)");
    standing_on = true;
    if (!did_sound) { 
      soundfile.loop();
    }
    did_sound = true;
  } else if (change == 2) {
    println("Off/Black");
    standing_on = false;
    did_image = false; // reset
    soundfile.stop();
    did_sound = false;
    image(img_black, 0, 0, img_black.width/ImageScale, img_black.height/ImageScale);
  } else {
    // Nothing has changed (0), but we need to monitor the imagedelay
    if (standing_on && !did_image && ( millis() - last_change_at > ImageDelay ) ) {
      println("(on)/white");
      image(img_white, 0, 0, img_white.width/ImageScale, img_white.height/ImageScale);
      did_image = true; // just once
    }
  }
}

int stood_upon() {
  // Return 1 when someone _starts_ to stand upon
  // Return 2 when they _finish_ standing upon
  // Return 0 when nothing has changed

  if (millis() - last_change_at < 200) { // debounce/shifting: be tolerant of weight shifts
    return 0;
  }

  int current_velo = arduino.analogRead(sensorPin);

  // classify value, 0 is indeterminate (in-between)
  int new_state = 0;
  if (current_velo < 100) {
    new_state = 2;
  } else if (current_velo > 400) {
    new_state = 1;
  }

  // change?
  if (new_state != last_state) {

    // turn on
    if (new_state == 1) {
      last_state = 1; // is standing-on
      last_change_at = millis();
      println("Stand");
      return 1;
    }

    // turn off 
    else if (new_state == 2) {
      last_state = 2; // is standing-off
      last_change_at = millis();
      println("Leave");
      return 2;
    }
  }
  // no change
  else {
    return 0;
  }
  return 0; // dead code
}

void setup_sound() {   
  // Load a soundfile from the /data folder of the sketch and play it back
  soundfile = new SoundFile(this, SoundName);
  println("Sound setup");
}

void setup_image() {

  // The image file must be in the data folder of the current sketch 
  // to load successfully
  img_black = loadImage("map_black.jpg");  // Load the image into the program  
  img_white = loadImage("map_white.jpg");  //first time you draw the image, its slow
  // preload, so the "real" 1st time is fast
  image(img_white, 0, 0, img_white.width/ImageScale, img_white.height/ImageScale);
  image(img_black, 0, 0, img_black.width/ImageScale, img_black.height/ImageScale);
  println("Images ready");
}

void setup_velodetect()
{
  println("USB Ports:");
  println(Arduino.list()); // cf ArduinoPortIndex, count from 0

  arduino = new Arduino(this, Arduino.list()[ArduinoPortIndex], 57600); //your offset may vary
  arduino.pinMode(sensorPin, 0);
  println("Arduino/Velow setup");
}