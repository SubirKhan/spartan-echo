# Spartan Echo: Ultrasonic Radar

Tech 60 (Intro to Electronics, SJSU) final project by Subir Khan and Dhiryen Moorthi.

An HC-SR04 ultrasonic sensor rides on an SG90 servo that sweeps 0° → 180° → 0°.
At every degree the Arduino measures the distance, lights a red LED and buzzer if something is
closer than 30 cm (green LED otherwise), and sends `angle,distance.` to a laptop.
A Processing sketch on the laptop draws a live radar screen (100 cm range).

```
radar_arduino/radar_arduino.ino   Arduino sketch (sensor, servo, LEDs, buzzer)
radar_display/radar_display.pde   Processing sketch (radar screen)
```

## Wiring

| Part | Arduino pin | Notes |
|---|---|---|
| HC-SR04 Trig | D10 | VCC → 5V, GND → GND |
| HC-SR04 Echo | D11 | |
| SG90 servo signal (orange) | D12 | Red → 5V, brown → GND |
| Green LED + 220 Ω | D5 | Area clear |
| Red LED + 220 Ω | D6 | Object under 30 cm |
| Active buzzer | D9 | On/off only |
| 470 µF capacitor (optional) | 5V / GND rails | Smooths servo current spikes. Stripe (−) to GND |

LED long leg (+) goes to the pin through the 220 Ω resistor; short leg to GND.
The board is powered from the laptop's USB cable.

## 1. Upload the Arduino sketch

1. Install the [Arduino IDE](https://www.arduino.cc/en/software).
2. Plug in the board. The ELEGOO Uno clone may need the **CH340 driver** if no port shows up.
3. Open `radar_arduino/radar_arduino.ino`.
4. **Tools → Board → Arduino Uno**, then **Tools → Port** → pick the board's port.
5. Click **Upload**.
6. Optional check: open **Tools → Serial Monitor** at **9600 baud**. You should see
   `0,0.1,0.2,45.` and so on scrolling by. **Close the Serial Monitor before step 2.**

## 2. Run the radar display

1. Install [Processing](https://processing.org/download).
2. Open `radar_display/radar_display.pde` and click **Run**.
3. The console at the bottom prints the available ports, for example:
   ```
   [0] "COM1"
   [1] "COM4"
   ```
4. If the radar doesn't move, stop the sketch, change `PORT_INDEX` near the top of the file to
   the number of your Arduino's port (the same one you picked in the Arduino IDE), and run again.

**Only one program can use the serial port at a time.** If Processing shows "Port busy",
close the Arduino IDE Serial Monitor (or any other program using the port) and try again.

## Testing without the parts

The Arduino sketch can be built and simulated in [Tinkercad Circuits](https://www.tinkercad.com/circuits),
which has the Uno, HC-SR04, micro servo, LEDs and buzzer. The Processing display needs the real board.

## How the distance is calculated

The sensor sends out an ultrasonic pulse and the Echo pin stays HIGH until the echo returns.
Sound travels about 0.034 cm per microsecond, and the pulse goes there and back, so:

```
distance_cm = echo_time_us * 0.034 / 2
```

If no echo returns within 30 ms, the Arduino sends a distance of 0 (nothing detected).
