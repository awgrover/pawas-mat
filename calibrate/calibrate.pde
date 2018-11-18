
/*
Calibrate the velostat mat, for standing on.

Wire the velostat as a voltage divider. We put a 1K variable resistor (potentiometer) as R2.
Run this to calibrate: we want > 400 when no-stand, and < 200 when stand.
Adjust the variable resistor.

INSTALL
  installed Firmata library for processing.
  in Arduino IDE upload StandardFirmata from Examples/Firmata
*/

import cc.arduino.*;
Arduino arduino;
int sensorPin = 0;
float sensorValue = 0;

void setup() {
  size(10,10); // don't care
  setup_velodetect();
}

void draw() {
  velo_calibrate();
}


int velo_calibrate() {
  int current_velo = arduino.analogRead(sensor_pin);

  println(current_velo);
}
