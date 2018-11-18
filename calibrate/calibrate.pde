
/*
Calibrate the velostat mat, for standing on.

Wire the velostat as a voltage divider. We put a 1K variable resistor (potentiometer) as R2.
Run this to calibrate: we want > 400 when no-stand, and < 200 when stand.
Adjust the variable resistor.

INSTALL
  installed Firmata library for processing.
  in Arduino IDE upload StandardFirmata from Examples/Firmata
*/
import processing.serial.*;

import cc.arduino.*;
Arduino arduino;
final int ArduinoPortIndex = 4;  // cf. Arduino.list()
int sensorPin = 0;
float sensorValue = 0;

void setup() {
  size(10,10); // don't care
  setup_velodetect();
}

void draw() {
  velo_calibrate();
}

void setup_velodetect()
{
  println("USB Ports:");
  println(Arduino.list()); // cf ArduinoPortIndex, count from 0

  arduino = new Arduino(this, Arduino.list()[ArduinoPortIndex], 57600); //your offset may vary
  arduino.pinMode(sensorPin, 0);
  println("Arduino/Velow setup");
}

void velo_calibrate() {
  int current_velo = arduino.analogRead(sensorPin);

  println(current_velo);
}