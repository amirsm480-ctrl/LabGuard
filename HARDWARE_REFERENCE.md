# Hardware and ESP32 upload

Target board: classic ESP32 Dev Module / ESP32-WROOM. Pin assignments are for this board family, not ESP32-S2, S3 or C3.

## Signal connections

Disconnect power before changing the wiring.

| Component signal | ESP32 GPIO |
|---|---:|
| DHT11 DATA | 18 |
| MQ-5 analog signal after the divider | 34 |
| IR flame sensor DO | 33 |
| Relay channel 1 IN1 | 16 |

Keep the existing tested buzzer/light wiring on the same relay channel. Both switch together. Channel 2 and the LCD are not used.

GPIO15 belongs to ADC2 on the classic ESP32. ADC2 is unavailable during Wi-Fi operation, so the MQ-5 analog input is moved to ADC1 GPIO34. If GPIO34 is already occupied on this physical board, use another free ADC1 input and update `GAS_PIN` before uploading.

## Protect the analog input

ESP32 signal inputs are not 5 V tolerant. MQ modules powered from 5 V can present an analog output above the ESP32 input limit. Do not directly connect an unverified 5 V AO signal.

For a module whose AO is bounded by 5.0 V, a divider can use:

| Connection | Part |
|---|---|
| MQ-5 AO to the GPIO34 junction | 10 kΩ resistor |
| GPIO34 junction to GND | 15 kΩ resistor |
| MQ-5 GND to ESP32 GND | Common ground |

The nominal ratio is 15 / (10 + 15) = 0.6, so 5.0 V becomes 3.0 V. Verify the actual voltage with a multimeter, including resistor tolerance and supply variation, before connecting the ADC. The divider changes the raw readings, so set thresholds after wiring it.

Keep the tested power supplies for the relay and sensors, and check that DHT and flame digital signals presented to the ESP32 are no higher than 3.3 V. A bare LED still requires a suitable current-limiting resistor. The buzzer must be an active DC buzzer if the relay simply supplies power to it.

## Arduino IDE setup

1. Install `esp32 by Espressif Systems` using Boards Manager. Use a current stable Arduino-ESP32 3.x release.
2. Install `DHT sensor library` by Adafruit.
3. Install `Adafruit Unified Sensor` when prompted by the DHT library.
4. Install `ArduinoJson` by Benoit Blanchon, version 7.x.
5. Open `LabGuard_ESP32.ino`. All required configuration and helper code is included in the single sketch.
6. Select ESP32 Dev Module and the connected serial port.
7. Fill in the configuration block near the top of `LabGuard_ESP32.ino`, upload, and set Serial Monitor to 115200 baud.

If the relay or flame module uses the opposite logic, change only `RELAY_ACTIVE_LOW` or `FLAME_ACTIVE_LOW` in the configuration block near the top of `LabGuard_ESP32.ino` after checking the relevant module's output. The defaults are active LOW.

## Thresholds and warm-up

| Setting | Default |
|---|---:|
| Temperature alarm ON | 40 °C |
| Temperature alarm clears | 38 °C |
| Gas alarm ON | 2200 raw |
| Gas alarm clears | 2000 raw |
| Demonstration gas warm-up delay | 60 seconds |
| Manual test maximum duration | 10 seconds |

The gap between ON and clear thresholds prevents repeated switching when a reading fluctuates close to a limit. Thresholds can be changed in Control after the board is online. Confirm that the screen says `Confirmed by ESP32`.

The MQ-5 manufacturer specifies at least 48 hours of preheating under its standard test conditions. The 60-second firmware delay is only a classroom startup delay for an already conditioned sensor. It does not establish calibration, ppm accuracy or readiness for life-safety use. Follow the module manufacturer's conditioning procedure and allow readings to stabilise before selecting a demonstration threshold.

An unplugged analog input can float and still produce a reading. This code cannot reliably prove an MQ-5 or flame module is physically connected solely from its signal pin. Check these connections physically. DHT read failures are detected and shown in the app.

## Suggested first checks

1. Confirm normal readings and correct relay OFF state at startup.
2. Run a 10-second manual test from the app and observe both outputs.
3. End the manual test and confirm both outputs return OFF when no hazard is detected.
4. Verify flame sensor operation using a supervised, lecturer-approved demonstration method.
5. To demonstrate threshold logic without releasing combustible gas, temporarily set the gas threshold just below the stable ambient raw reading, with the clear value lower, and restore it afterwards.
6. Disconnect internet while the ESP32 remains powered. Confirm local alarm detection still operates and the app marks the device offline.

This is an educational prototype. It is not a replacement for certified laboratory fire/gas protection.

## Official references

- ESP32 GPIO/ADC restrictions: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html
- ESP32 Wi-Fi API: https://docs.espressif.com/projects/arduino-esp32/en/latest/api/wifi.html
- MQ-5 manufacturer information: https://www.winsen-sensor.com/product/mq-5.html
