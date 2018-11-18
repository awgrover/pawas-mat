/* 
  INSTALL
  installed Firmata library for processing.
  in Arduino IDE upload StandardFirmata from Examples/Firmata
  
  
  
  fixme: plain auot isn't float
  fixme: exponentional isn't float
  fixme: we don't take floats
  fixme: template

  If an "analog" sensor is a bit noisy,
  and has a floor, and an "on" level, 
  and the floor, and "on", aren't stable (i.e. hard to predict depending on environment),
  Then this will give you true/false for floor/on level
  and will auto-adjust to the environment.

  However, if the environment pushes the floor up, it will be seen as "on"
  _until_ the signal actually goes "on"-to-"floor", which puts things back in the right state.
  Likewise, if the current state is "on" and the environment changes pushing it lower,
  it will be seen as "floor" till the signal actually goes "floor"-to-"on" which puts things
  back in the right state.

  A good application for this is capacitance-touch sensors using the arduino pins and
  the CapacitiveSensor library (http://playground.arduino.cc/Main/CapSense).
  The readout will have a floor, but it's hard to predict what it is. And, if you
  move things around, the floor moves. And, if you touch your laptop, the floor moves.
  The readout is also a bit noisy. And, "higher" depends on the resistor you use, and
  the capacitance of the touch-wire/touch-plate. And, other things attached to the arduino.
  And, if you change from a laptop to a battery (or wall-power), the floor changes. When
  the "however" above happens, a quick touch is sufficient to "put things back to the right state."

  This works by doing exponential-smoothing (https://en.wikipedia.org/wiki/Exponential_smoothing).
  You can think of it as chasing the raw value. If you chase it, but are slower, then you smooth
  out the zig-zags of the raw value. And, if you chase it at different rates, you'll see a difference
  when the value changes significantly.

  So,
  1. we smooth the raw-value with a fairly small "smoothing-factor". i.e. we respond fairly quickly to changes in the raw-value, but still remove some noise. Call this the "fast" smoother. It's the cleaned-up current value.
  2. we also do an exponential-smoothing with a much large factor. i.e. it responds slower to changes. Call this "slow". This is the reference.
  Thus, short changes are ignored (noise), 
  And, we drift with the environment (auto-adjust).
  3. When there is a persistent change, there will be a difference between the slow & fast values. This is the direction of change.
  4. If the difference is large enough, the change is significant.

For example, in one of our capacitance setups, the floor was about 20 (if you touched the laptop it went to about 80), and a touch was about 600. The values changed a lot if you ran a servo, or used wall-power. We used the debug-graph output to make a guess at the "significant-difference" value (of about 50), and the smoothing-factors. We had 5 for the fast smoothing, but the servo caused a huge spike and we had to increase the fast to about 15 to filter it out. Our slow was about 40, which had about the right timescale for touching.

For this to work, we have to read raw-values pretty often (because we average them, and "chase" them). Using "delay" will get in the way of this. Basically, don't use "delay" (see "wait_for" in here)!

  Use:

  * 1 Sensor, Function Interface
  # use this if you have 1 sensor in your whole setup.

  int fast = 5; // experiment to find this, removes noise. constant: just a named value
  int slow = 40; // experiment to find this, to get a good difference. constant: just a named value
  int significant = 50; // experiment to find this, so false and true can be determined reliably.

  void loop() {
    // don't use "delay" in loop!

    int raw_value = somesensor.read(); // raw/noisy value

    // 
    Boolean touched = auto_bilevel( raw_value, fast, slow, significant);  
    if (touched) { do something...; }
    else { do something when "released"; }

    ...
  }

  ** How to Experiment
  We'll output the interesting values and eyeball them on the Serial Plotter.

  auto_bilevel_graph() takes the same arguments but writes a line of data to the serial output,
  suitable for the Arduino IDE Serial Plotter window (don't forget a Serial.begin in setup()!).
  Use the fastest baud-rate (highest number) that works reliably for you. At least 115200 seems 
  to work everywhere.

  So,
  1. build a new sketch with just your sensor
  3. println the raw values from the sensor (you can use the Serial Plotter)
    3.1 get some idea of the "floor", the value when the sensor is "off".
    3.2 get some idea of the "on" value.
    3.3 get some idea of the noise.
    3.4 play around with the physical setup, moving things around, touching your laptop, etc. To see if it has any effect.
  2. add auto_bilevel_graph to your sketch, and plug in some numbers. If you do this a lot you'll gain experience in guessing the right numbers.
    2.1 the "fast" value depends on the noise and speed of your arduino. 5 is not a bad place to start.
    2.2 the "slow" value depends on how long the "on" period is, and arduino speed. 8 times the fast is a good guess.
    2.3 use your idea from step 3 to guess at the significant" value, about 1/4 the difference you actually see! E.g., we saw about 200 difference from floor to touch with our capacitance setup, so we guessed about 50.
    2.4 comment out your println of the raw-value (auto_bilevel_graph will do it).
  3. Run the sketch, open the Serial Plotter. The lines are (see legend in top right for order):
    3.1 raw-value, should look noisiest
    3.2 fast smoothed value, follows changes fairly quickly
    3.3 slow smoothed value (hidden behind the doubling below)
    3.4 fast-significant: when slow is below this, it means "on"
    3.5 doubling of slow: the doubling shows when "on"

  ** Details
    Boolean auto_bilevel( 
      int raw_value, # the noisy raw-value 
      int fast, # the smoothing factor for the fast smoother.
      int slow, # the smoothing factor for the slow smoother,
      int significant, # the difference to trigger a change
      # raw_value and significant have to be the same type, but can be signed/unsigned, byte/int/long
      )
    Boolean auto_bilevel_graph(...)
      # same as auto_bilevel(), but does serial.println with values for Serial Plotter

    # auto_bilevel_graph() remembers some values from call-to-call, so only use it for one sensor.

*/

import processing.serial.*;
// Firmata setup
import cc.arduino.*;
Arduino arduino;

void setup() {
  println(Arduino.list());
arduino = new Arduino(this, Arduino.list()[0], 57600);
}

void draw() {
  
}

long fast_smooth;
long slow_smooth = 0;


Boolean auto_bilevel(long raw, int fast_factor, int slow_factor, long significant) {
  fast_smooth=raw;

  // We have 2 exponentials: one to "smooth" (fast) and one as the "reference" (slow).
  // Fast moves quickly toward new values, slow takes a while to catch up.
  // So, when fast-slow is positive, we've change "up", and vice-versa,
  // And, it's independant of the absolute values or floor! so, it's "auto"

  // exponential decay, i.e. "Smoothing" but it takes time. aka "chases values slowly"
  fast_smooth = int(raw / fast_factor + fast_smooth - fast_smooth / fast_factor);
  slow_smooth = int(raw / slow_factor + slow_smooth - slow_smooth / slow_factor);

  // the slow lags the fast during changes.
  // if the rate of change is relatively slow, then the lag (the difference) is small
  // and vice-versa.
  // if the change itself is small, then of course the difference is small.

  if ( (fast_smooth - slow_smooth) >= significant ) {
    return true;
  }
  else if ( (fast_smooth - slow_smooth) <= -significant ) {
    return false;
  }
  else { return false; }
}