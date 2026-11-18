# Demonstration and rubric mapping

The interface uses standard Flutter widgets and a blue-and-white theme. This mapping describes implemented source-code features. It does not claim marks have been awarded or that physical tests have already been completed.

| Requirement | Where to demonstrate |
|---|---|
| At least three sensor readings | Temperature, humidity, MQ-5 raw level and flame status |
| Two actuators | Physical warning buzzer and warning light on relay channel 1 |
| At least five meaningful screens | Login, Dashboard, Sensors, Control, History and Alerts |
| At least three data/system screens | Dashboard, Sensors, Control, History and Alerts |
| Automatic response | ESP32 turns both warning devices on for flame, high gas or high temperature |
| Dashboard overview | Dashboard shows readings, overall condition, two device states and connection status |
| Real-time visualization | Numeric cards, gas progress indicator and status indicators |
| Actuator control | Control provides a timed manual alarm test and end-test command |
| Abnormal indication | Status card, flame status, alarm state and alert records |
| Historical visualization | History displays genuine saved readings in a paginated table with date, time and a time-range filter |
| Security feature | Firebase login plus role-based database rules |
| Database integration | Firebase Realtime Database |
| Navigation | Five destinations after login, with a bottom bar on phones and a side rail on wide browsers |
| Android deployment | Run the Android workflow, install its demo APK and demonstrate it on a physical Android phone |
| Additional web version | Run the Web workflow and demonstrate the same laboratory from the GitHub Pages URL |
| Coding practice | Separate page files, models, Firebase service, configuration and shared widgets; dedicated firmware safety logic |

The existing hardware contains two physical output devices with one shared control channel. Demonstrate that both operate. The supplied rubric does not clearly require independent control, so this project preserves the user's shared-channel decision; it does not claim two independent switches.

## Recording sequence

1. Introduce the project, the three sensor modules and two warning devices.
2. Show an unsuccessful login with invalid input, then sign in with the authorised operator account. Keep passwords out of the recording.
3. Show Dashboard and explain the connection and safety status.
4. Open Sensors and point to temperature, humidity, raw gas and flame detection.
5. Open Control, request the alarm test and film both physical outputs. Show ESP32 acknowledgement and the automatic stop after 10 seconds.
6. Demonstrate a lecturer-approved sensor trigger. Show the automatic response and abnormal indication. Explain that ending a manual test cannot suppress an actual hazard alarm.
7. Clear the condition and show the recovery event.
8. Open History after several recorded samples exist. Change the time range and use Previous / Next to view the recorded-data table.
9. Open Alerts and filter the recorded events.
10. Disconnect the network briefly while keeping the board powered. Show the offline indicator and disabled cloud controls. Demonstrate that local protection still operates.
11. Reconnect, verify fresh readings, and sign out.

## Submission

- Flutter project folder as ZIP or the instructor's repository link.
- YouTube demonstration link.
- Single ESP32 `.ino` file.
- Deployed GitHub Pages link as the additional web version. Keep the Android APK demonstration for the Android/iOS deployment criterion.

The Android workflow also saves a complete Flutter source artifact containing the generated Android platform files. Include the separate firmware sketch with the submission. The downloadable source package itself has not been compiled or deployed; the workflows run only when manually started.

Remove real device and Wi-Fi passwords from the submission copy. Include the configuration example and instructions so the assessor can understand the structure.

## Explaining the project

The phone authenticates the laboratory operator and displays data stored in Firebase. The ESP32 reads the sensors and performs automatic protection locally. It reports telemetry and events to the database using a separate authenticated device account. Commands from the phone are time limited and the interface waits for the ESP32 to acknowledge them.

The gas threshold is a raw sensor threshold, not a measured ppm value. The buzzer and warning light share one relay, so they operate together. The reported actuator state represents the ESP32 relay output; physical operation is verified during the demonstration.
