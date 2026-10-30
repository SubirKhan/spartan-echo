/*
  Spartan Echo - Ultrasonic Radar (Arduino side)
  Tech 60, SJSU - Subir Khan & Dhiryen Moorthi

  A servo sweeps an HC-SR04 ultrasonic sensor from 0 to 180 degrees and back.
  At each degree we:
    1. Measure the distance to the nearest object
    2. Turn on the red LED + buzzer if it is closer than WARN_CM, otherwise the green LED
    3. Send "angle,distance." to the laptop over USB (read by the Processing sketch)
*/

#include <Servo.h>

// ----- Pin connections -----
const int TRIG_PIN      = 10;  // HC-SR04 Trig
const int ECHO_PIN      = 11;  // HC-SR04 Echo
const int SERVO_PIN     = 12;  // SG90 signal (orange wire)
const int GREEN_LED_PIN = 5;   // Green LED: area clear
const int RED_LED_PIN   = 6;   // Red LED: object too close
const int BUZZER_PIN    = 9;   // Active buzzer (on/off only)

// ----- Settings -----
const int WARN_CM = 30;                    // Closer than this = warning
const int MAX_CM  = 100;                   // Radar screen range (used by the display)
const int STEP_DELAY_MS = 25;              // Time for the servo to reach each new angle
const unsigned long ECHO_TIMEOUT_US = 30000;  // Stop waiting for an echo after 30 ms

Servo radarServo;

// Helper functions (written below loop)
void scanAt(int angle);
int measureDistanceCm();
void updateAlerts(int distance);

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  radarServo.attach(SERVO_PIN);
  Serial.begin(9600);  // Must match the baud rate in the Processing sketch
}

void loop() {
  // Sweep left to right: 0 -> 180 degrees
  for (int angle = 0; angle <= 180; angle++) {
    scanAt(angle);
  }
  // Sweep back right to left: 180 -> 0 degrees
  for (int angle = 180; angle >= 0; angle--) {
    scanAt(angle);
  }
}

// Move the servo to one angle, measure, update alerts and report to the laptop.
void scanAt(int angle) {
  radarServo.write(angle);
  delay(STEP_DELAY_MS);

  int distance = measureDistanceCm();
  updateAlerts(distance);

  // Message format: angle,distance.   (the period marks the end of a message)
  Serial.print(angle);
  Serial.print(",");
  Serial.print(distance);
  Serial.print(".");
}

// Returns the distance in cm, or 0 if no echo came back (nothing detected).
int measureDistanceCm() {
  // Send a 10 microsecond pulse on Trig to fire the ultrasonic burst
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Echo stays HIGH for as long as the sound took to go out and come back
  unsigned long echoTimeUs = pulseIn(ECHO_PIN, HIGH, ECHO_TIMEOUT_US);
  if (echoTimeUs == 0) {
    return 0;  // Timed out: no object in range
  }

  // Sound travels 0.034 cm per microsecond. Divide by 2 because it goes there AND back.
  return echoTimeUs * 0.034 / 2;
}

// Red LED + buzzer when an object is close, green LED otherwise.
void updateAlerts(int distance) {
  bool tooClose = (distance > 0 && distance < WARN_CM);

  digitalWrite(RED_LED_PIN, tooClose ? HIGH : LOW);
  digitalWrite(BUZZER_PIN,  tooClose ? HIGH : LOW);
  digitalWrite(GREEN_LED_PIN, tooClose ? LOW : HIGH);
}
