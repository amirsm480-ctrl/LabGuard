# LabGuard

Aplikasi Flutter untuk Smart Laboratory Safety Monitoring System, dengan satu set page untuk Android dan Web.

## Mula di sini

1. Baca [WEB_AND_ANDROID_BM.md](WEB_AND_ANDROID_BM.md) untuk konfigurasi Firebase, build Android dan publish GitHub Pages.
2. Konfigurasi Android dan Web yang kau berikan sudah diisi dalam `lib/config/app_config.dart`. Android menggunakan package `com.amiraziz.labguard` dan App ID daripada `google-services.json` projek lama.
3. Gunakan workflow **Build Android APK** atau **Publish Flutter Web** dari tab Actions. Kedua-duanya hanya berjalan apabila kau tekan Run workflow.

## Fungsi

- Login Firebase Email/Password.
- Dashboard, Sensors, Control, History dan Alerts dalam fail page berasingan.
- Bacaan suhu, kelembapan, gas mentah dan flame detection.
- Arahan alarm dengan pengesahan ESP32.
- Jadual history dan rekod amaran daripada database sebenar.
- Menu bawah pada telefon dan menu sisi pada browser lebar.

## Panduan tambahan

- [FOLDER_GUIDE_BM.md](FOLDER_GUIDE_BM.md): susunan fail Flutter.
- [START_HERE_BM.md](START_HERE_BM.md): database, akaun pengguna, firmware dan sambungan.
- [HARDWARE_REFERENCE.md](HARDWARE_REFERENCE.md): pin, bekalan dan voltage divider.
- [DEMO_AND_RUBRIC.md](DEMO_AND_RUBRIC.md): demonstrasi dan submission.

Pakej ini mengandungi source dan workflow, bukan APK yang sudah dibuild atau laman yang sudah dipublish. Folder Android dijana oleh workflow; untuk kerja pada laptop, jalankan `python3 tool/prepare_android.py`. ESP32 perlu menjalankan firmware dan menghantar bacaan ke Firebase.
