# LabGuard — setup Firebase dan hardware

Pakej ini ialah kod sumber untuk projek DFI20443 Smart Laboratory Safety Monitoring System. Semua kod dan teks app dalam English, tanpa komen kod. Android dan Web kini menggunakan page dan database yang sama. Baca **WEB_AND_ANDROID_BM.md** dahulu untuk build APK melalui GitHub dan publish web. Tiada APK dibuild atau laman dipublish dalam kemas kini ini.

## Jika kau sudah guna versi sebelum ini

1. Backup dahulu nilai Firebase yang kau sudah isi. Dalam versi satu fail, nilainya ada dalam `class AppConfig` pada `lib/main.dart` lama.
2. Salin keseluruhan folder `lib` daripada ZIP ini ke projek Flutter kau dan gantikan fail LabGuard yang sama nama.
3. Field `appId` Android lama kini bernama `androidAppId`. Konfigurasi Android daripada `google-services.json` dan konfigurasi Web yang kau berikan sudah dimasukkan dalam `lib/config/app_config.dart`.
4. Tiada database atau akaun operator baharu diperlukan untuk versi web. Kedua-duanya menggunakan `lab01`.

Setiap page kini mempunyai fail sendiri di dalam `lib/pages`. `lib/main.dart` hanya initialise Firebase dan memulakan app. Rujuk `FOLDER_GUIDE_BM.md` untuk nama dan fungsi setiap fail.

Interface menggunakan tema biru-putih, `AppBar`, `Card`, `ListTile` dan butang biasa. Telefon menggunakan `BottomNavigationBar`, browser lebar menggunakan `NavigationRail`. Enam skrin ialah Login, Dashboard, Sensors, Control, History dan Alerts. History menggunakan jadual bertarikh dengan butang Previous/Next dan scrollbar mendatar; historical table dibenarkan dalam soalan.

## Fail yang kau perlukan

| Fail | Kegunaan |
|---|---|
| `lib/` | Semua fail Flutter, dengan setiap page dalam fail berasingan |
| `FOLDER_GUIDE_BM.md` | Susunan folder dan tempat paste setiap fail |
| `WEB_AND_ANDROID_BM.md` | Setup dua platform dan langkah GitHub Actions |
| `pubspec.yaml` | Senarai dependencies Flutter |
| `LabGuard_ESP32.ino` | Semua kod Arduino, konfigurasi dan sijil HTTPS dalam satu sketch |
| `database.seed.json` | Struktur permulaan database tanpa bacaan palsu |
| `ACCOUNT_SETUP_BM.md` | Akaun sebenar, UID dan langkah tambah akses pada database yang dipulihkan |
| `database.rules.json` | Rules keselamatan database |
| `HARDWARE_REFERENCE.md` | Sambungan, voltage divider, library Arduino dan threshold |
| `DEMO_AND_RUBRIC.md` | Susunan demonstrasi dan padanan kepada rubrik |

## 1. Buat Firebase dahulu

1. Buka https://console.firebase.google.com/ dan gunakan projek **labguard-419c6** yang kau sudah buat.
2. App Android untuk package **com.amiraziz.labguard** sudah didaftarkan berdasarkan `google-services.json` yang kau berikan.
3. Nilai daripada `google-services.json` sudah disalin ke `lib/config/app_config.dart`; kod ini menggunakan `FirebaseOptions` secara terus.
4. Buka **Authentication**, kemudian aktifkan provider **Email/Password**.
5. Gunakan akaun sedia ada: `amir.sm480@gmail.com` untuk login Android/Web dan `tboom743@gmail.com` untuk ESP32. Password setiap akaun ialah password yang kau tetapkan dalam Firebase Authentication.
6. UID kedua-dua akaun sudah dimasukkan dalam `database.seed.json`. Semak padanan dalam `ACCOUNT_SETUP_BM.md` dengan senarai pengguna Firebase projek lama.
7. Buka **Realtime Database** yang kau sudah buat. Kod ini menggunakan Realtime Database, bukan Cloud Firestore.
8. Salin URL HTTPS database yang sebenar daripada halaman database.

## 2. Masukkan struktur database dan rules

Pemetaan akaun berikut sudah disediakan dalam `database.seed.json`:

| Akaun | UID |
|---|---|
| Operator: `amir.sm480@gmail.com` | `YjVfVSbJ8BQiYtH4X0JO1dptY223` |
| ESP32: `tboom743@gmail.com` | `VBYNfKL6ezOyQfDei1uvxcGf2Kk2` |

Untuk database lama yang sudah dipulihkan, ikut `ACCOUNT_SETUP_BM.md` dan tambah hanya dua entri akses yang dinyatakan. Kekalkan data sensor, sejarah dan konfigurasi sedia ada.

`database.seed.json` hanya untuk database yang benar-benar kosong. Import pada root boleh menggantikan data pada lokasi itu; jangan import keseluruhan seed ke root database yang sudah berisi.

Kemudian buka tab **Rules**, padam kandungan asal, paste keseluruhan `database.rules.json`, dan publish. Jangan jadikan rules public untuk mengatasi permission error; semak UID yang dimasukkan.

## 3. Sediakan projek Flutter

Jika guna GitHub Actions, ikut **WEB_AND_ANDROID_BM.md**. Workflow menyediakan Flutter dan fail Android pada runner, jadi laptop kau tidak perlu compile.

Jika guna laptop, extract ZIP dan buka folder yang mengandungi `pubspec.yaml`. Gunakan Flutter stable dengan Dart 3.12 atau lebih baharu. Jalankan:

```bash
python3 tool/prepare_android.py
flutter pub get
```

Script menyediakan folder Android jika belum ada, permission Internet, label LabGuard dan minimum SDK 24. Folder Web sudah disediakan. Untuk projek lama, backup konfigurasi dahulu dan salin `lib`, `web`, `tool`, `pubspec.yaml` serta `analysis_options.yaml` daripada pakej. Jika masih ada `test/widget_test.dart` contoh counter asal Flutter, keluarkan fail contoh itu kerana ia tidak menguji LabGuard.

## 4. Isi konfigurasi Flutter

Buka `lib/config/app_config.dart`. Konfigurasi Android dan Web sudah diisi berdasarkan nilai yang kau berikan untuk projek `labguard-419c6`. Jadual ini menjadi rujukan jika konfigurasi projek berubah kemudian.

| Field | Nilai yang perlu disalin |
|---|---|
| `apiKey` | `client[0].api_key[0].current_key` dalam `google-services.json` |
| `androidAppId` | `client[0].client_info.mobilesdk_app_id` |
| `webAppId` | `appId` dalam konfigurasi app Web Firebase |
| `webApiKey` | `apiKey` dalam konfigurasi app Web Firebase |
| `authDomain` | `authDomain` dalam konfigurasi app Web Firebase |
| `messagingSenderId` | `project_info.project_number`, kekalkan dalam tanda petik |
| `projectId` | `project_info.project_id` |
| `databaseUrl` | URL HTTPS sebenar daripada Realtime Database |
| `labId` | Kekalkan `lab01` |

Jika JSON mengandungi beberapa client, pilih client untuk package `com.amiraziz.labguard`.

Jangan letak password operator atau ESP32 dalam kod Flutter. Login app menggunakan email dan password yang ditaip oleh pengguna. Konfigurasi Firebase di atas tidak memberikan akses admin; akses dikawal oleh Authentication dan rules.

Jalankan:

```bash
flutter pub get
```

## 5. Sambungan hardware

Matikan bekalan sebelum ubah sambungan.

| Signal | GPIO |
|---|---:|
| DHT11 DATA | 18 |
| MQ-5 AO selepas voltage divider | 34 |
| IR flame DO | 33 |
| Relay IN1 | 16 |

MQ-5 berpindah daripada GPIO15 kepada GPIO34 kerana GPIO15 menggunakan ADC2 yang tidak boleh digunakan bersama Wi-Fi pada ESP32 biasa.

**Pastikan signal AO yang masuk ke GPIO34 tidak melebihi 3.3 V.** Untuk AO maksimum 5.0 V, rujukan divider ialah 10 kΩ dari AO ke junction GPIO34, dan 15 kΩ dari junction itu ke GND. Nisbah nominal 0.6 menghasilkan 3.0 V daripada 5.0 V. Ukur voltan sebenar dan pastikan common ground sebelum sambung ke ESP32. Maklumat lanjut ada dalam `HARDWARE_REFERENCE.md`.

Buzzer dan lampu kekal pada relay channel 1, jadi kedua-duanya ON/OFF serentak. LCD dan channel 2 tidak digunakan.

## 6. Paste kod Arduino

1. Dalam Arduino IDE, install board package **esp32 by Espressif Systems**, stable 3.x.
2. Dalam Library Manager, install **DHT sensor library by Adafruit**, **Adafruit Unified Sensor**, dan **ArduinoJson by Benoit Blanchon, versi 7.x**.
3. Buat sketch baharu dan save dengan nama **LabGuard_ESP32**.
4. Padam kod contoh dan paste keseluruhan `LabGuard_ESP32.ino`. Semua helper dan sijil sudah disatukan; tiada fail `.h` berasingan diperlukan.
5. Cari nilai konfigurasi dekat atas sketch dan isi:

| Field | Isi |
|---|---|
| `WIFI_SSID` | Nama Wi-Fi/hotspot |
| `WIFI_PASSWORD` | Password Wi-Fi/hotspot |
| `FIREBASE_API_KEY` | Sudah diisi daripada konfigurasi projek Firebase lama |
| `FIREBASE_DATABASE_URL` | Sudah diisi untuk Realtime Database projek `labguard-419c6` |
| `DEVICE_EMAIL` | Sudah diisi: `tboom743@gmail.com` |
| `DEVICE_PASSWORD` | Isi sendiri password Firebase Authentication untuk `tboom743@gmail.com` |

6. Pilih board **ESP32 Dev Module** dan port yang betul, kemudian upload.
7. Buka Serial Monitor pada **115200 baud**. Semak bacaan sensor dan mesej `Device signed in.`.

Relay dan flame sensor menggunakan active LOW secara lalai. Jika modul yang kau uji berfungsi terbalik, ubah `RELAY_ACTIVE_LOW` atau `FLAME_ACTIVE_LOW` selepas mengesahkan logic modul.

## 7. Jalankan app pada Android

1. Hidupkan Developer Options dan USB debugging pada telefon Android.
2. Sambungkan telefon ke laptop menggunakan kabel data dan benarkan USB debugging.
3. Pastikan telefon dan ESP32 mempunyai internet. ESP32 biasa memerlukan rangkaian Wi-Fi/hotspot 2.4 GHz.
4. Dalam terminal projek:

```bash
flutter devices
flutter run
```

Pilih telefon Android jika diminta. Login menggunakan akaun operator. Tiada Bluetooth pairing diperlukan kerana sistem ini menggunakan Firebase melalui internet.

## 8. Periksa fungsi

- Tunggu status ESP32: Online dan pastikan perubahan sensor fizikal muncul dalam app.
- Tekan **Test Alarm (10 seconds)**. Buzzer dan lampu patut hidup bersama, dan app menunggu pengesahan ESP32.
- **Stop Test** hanya menamatkan ujian. Ia tidak mematikan alarm jika bahaya masih dikesan.
- Bacaan history disimpan kira-kira setiap 30 saat semasa online. Rekod pertama akan muncul dalam jadual History selepas ia disimpan. Gunakan Previous dan Next untuk melihat rekod lain.
- History menggunakan 2,880 slot berputar, kira-kira 24 jam. Alerts menyimpan 100 rekod terkini.
- Jika internet terputus, app menandakan data offline selepas 20 saat dan kawalan remote dinyahaktifkan. Pengesanan automatik pada ESP32 terus berjalan.
- Gas dipaparkan sebagai nilai **raw**, bukan ppm. Tetapkan threshold selepas sensor stabil dan divider dipasang.

Delay warm-up 60 saat dalam kod ialah delay demonstrasi, bukan pengganti conditioning MQ-5. Rujuk panduan hardware untuk preheat pengeluar. Projek ini ialah prototaip pembelajaran, bukan sistem perlindungan makmal yang diperakui.

## Jika ada error

| Masalah | Semak |
|---|---|
| `DHT.h: No such file` | Install DHT sensor library by Adafruit |
| `ArduinoJson.h: No such file` | Install ArduinoJson versi 7.x |
| Flutter menyebut SDK version | Semak `flutter --version`; dependencies memerlukan Dart 3.12+ |
| Paparan Connect your laboratory | Masih ada placeholder `REPLACE_` dalam `lib/config/app_config.dart` |
| Login gagal | Provider Email/Password, akaun operator dan internet |
| Database access failed | UID operator pada `members/lab01`, boolean `true`, dan rules |
| HTTP 401/403 pada ESP32 | Akaun device, UID pada `deviceUsers`, API key, URL dan rules |
| MQ-5 pelik semasa Wi-Fi hidup | Pastikan signal menggunakan ADC1 GPIO34, voltan betul dan common ground |
| Alarm terbalik | Semak logic `RELAY_ACTIVE_LOW` dengan ujian modul |

Kemas kini Web/Android ini belum dibuild atau diuji pada browser/peranti sebenar. Ia memerlukan konfigurasi Firebase, workflow dan ujian fizikal di atas sebelum demonstrasi.

## Rujukan rasmi

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/database/flutter/read-and-write
- https://firebase.google.com/docs/database/rest/auth
- https://firebase.google.com/docs/reference/security/database
- https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html
- https://www.winsen-sensor.com/product/mq-5.html
