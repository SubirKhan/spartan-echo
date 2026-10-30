/*
  Spartan Echo - Radar Display (Processing side)
  Tech 60, SJSU - Subir Khan & Dhiryen Moorthi

  Reads "angle,distance." messages from the Arduino over USB
  and draws a live radar screen.

  IMPORTANT: Close the Arduino IDE Serial Monitor before running this.
  Only one program can use the serial port at a time.
*/

import processing.serial.*;

// ----- Serial port -----
// When this sketch starts, the console prints a numbered list of ports.
// Change PORT_INDEX to the number of your Arduino's port.
//   Windows: usually "COM3", "COM4", ...
//   Mac:     usually "/dev/cu.usbserial-..." or "/dev/cu.wchusbserial-..."
final int PORT_INDEX = 0;
final int BAUD_RATE  = 9600;  // Must match Serial.begin() in the Arduino sketch

// ----- Radar settings -----
final int MAX_CM  = 100;  // Outer ring of the radar
final int WARN_CM = 30;   // Closer than this = "OBJECT CLOSE"

Serial port;

int currentAngle = 0;
int currentDistance = 0;
int[] distances = new int[181];  // Last distance seen at each angle (0 = nothing)

// Radar geometry (set in setup)
float centerX, centerY;  // Center of the radar (bottom middle)
float radius;            // Radius in pixels of the MAX_CM ring

void setup() {
  size(1200, 700);
  smooth();

  centerX = width / 2;
  centerY = height - 130;
  radius  = 500;

  // Show every available serial port so you can pick the right one
  println("Available serial ports:");
  printArray(Serial.list());

  port = new Serial(this, Serial.list()[PORT_INDEX], BAUD_RATE);
  port.bufferUntil('.');  // Call serialEvent() each time a full message arrives
}

// Runs automatically whenever a message ending in '.' arrives
void serialEvent(Serial p) {
  String message = p.readStringUntil('.');
  if (message == null) return;

  // "45,23." -> "45,23" -> ["45", "23"]
  message = trim(message.substring(0, message.length() - 1));
  String[] parts = split(message, ',');
  if (parts.length != 2) return;  // Ignore broken messages

  int angle = int(trim(parts[0]));
  int distance = int(trim(parts[1]));
  if (angle < 0 || angle > 180) return;

  currentAngle = angle;
  currentDistance = distance;
  distances[angle] = distance;  // Overwrites what we saw here on the last sweep
}

void draw() {
  background(0, 15, 0);
  drawGrid();
  drawObjects();
  drawSweepLine();
  drawInfoPanel();
}

// Converts a radar position (angle in degrees, distance in cm) to screen x/y.
// 0 degrees points right, 90 points straight up, 180 points left.
float toScreenX(float angle, float cm) {
  return centerX + cos(radians(angle)) * cm * radius / MAX_CM;
}
float toScreenY(float angle, float cm) {
  return centerY - sin(radians(angle)) * cm * radius / MAX_CM;
}

// Range rings at 25/50/75/100 cm and angle lines every 30 degrees
void drawGrid() {
  stroke(0, 140, 0);
  strokeWeight(1.5);
  noFill();
  textSize(14);

  for (int cm = 25; cm <= MAX_CM; cm += 25) {
    float d = 2 * cm * radius / MAX_CM;
    arc(centerX, centerY, d, d, PI, TWO_PI);

    fill(0, 200, 0);
    text(cm + " cm", toScreenX(0, cm) - 40, centerY + 20);
    noFill();
  }

  for (int angle = 0; angle <= 180; angle += 30) {
    line(centerX, centerY, toScreenX(angle, MAX_CM), toScreenY(angle, MAX_CM));

    fill(0, 200, 0);
    textAlign(CENTER, CENTER);
    text(angle + "°", toScreenX(angle, MAX_CM + 6), toScreenY(angle, MAX_CM + 6));
    textAlign(LEFT, BASELINE);
    noFill();
  }
}

// A red mark for every angle where something was detected within range
void drawObjects() {
  stroke(255, 40, 40);
  strokeWeight(8);
  for (int angle = 0; angle <= 180; angle++) {
    int cm = distances[angle];
    if (cm >= 1 && cm <= MAX_CM) {
      point(toScreenX(angle, cm), toScreenY(angle, cm));
    }
  }
}

// Bright line showing where the sensor is pointing right now
void drawSweepLine() {
  stroke(80, 255, 80);
  strokeWeight(3);
  line(centerX, centerY, toScreenX(currentAngle, MAX_CM), toScreenY(currentAngle, MAX_CM));
}

// Text at the bottom: angle, distance and warning
void drawInfoPanel() {
  noStroke();
  fill(0);
  rect(0, height - 80, width, 80);

  textSize(24);
  fill(0, 220, 0);
  text("Angle: " + currentAngle + "°", 60, height - 32);

  if (currentDistance >= 1 && currentDistance <= MAX_CM) {
    text("Distance: " + currentDistance + " cm", 300, height - 32);
  } else {
    text("Distance: out of range", 300, height - 32);
  }

  if (currentDistance >= 1 && currentDistance < WARN_CM) {
    fill(255, 40, 40);
    text("OBJECT CLOSE", 700, height - 32);
  }

  fill(0, 220, 0);
  text("SPARTAN ECHO", width - 240, height - 32);
}
