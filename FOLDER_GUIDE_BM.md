# Susunan fail Flutter

Setiap page berada dalam fail berasingan. Semua kod dan teks app dalam English, tanpa komen kod.

## Fail permulaan

| Fail | Fungsi |
|---|---|
| `lib/main.dart` | Initialise Firebase dan mulakan app |
| `lib/app.dart` | Tema app, status login dan pengurusan sesi pengguna |
| `lib/config/app_config.dart` | Konfigurasi Firebase bersama, Android App ID dan Web App ID |

## Page berasingan

| Fail | Page / fungsi |
|---|---|
| `lib/pages/login_page.dart` | Login dan reset password |
| `lib/pages/home_page.dart` | Menu bawah pada telefon, menu sisi pada browser lebar dan pertukaran page |
| `lib/pages/dashboard_page.dart` | Ringkasan sensor, keselamatan dan actuator |
| `lib/pages/sensors_page.dart` | Bacaan langsung dan maklumat ESP32 |
| `lib/pages/control_page.dart` | Test alarm, Stop Test dan edit threshold |
| `lib/pages/history_page.dart` | Jadual bacaan terdahulu, pilihan masa dan pagination |
| `lib/pages/alerts_page.dart` | Rekod amaran dan recovery |
| `lib/pages/setup_page.dart` | Paparan jika konfigurasi Firebase belum lengkap |

Enam skrin utama untuk demonstrasi ialah Login, Dashboard, Sensors, Control, History dan Alerts. Home ialah container navigasi, manakala Setup ialah paparan konfigurasi.

## Fail sokongan

| Fail | Fungsi |
|---|---|
| `lib/models/lab_models.dart` | Struktur bacaan sensor, threshold dan rekod amaran |
| `lib/services/lab_repository.dart` | Bacaan/tulisan Firebase dan pengesahan arahan ESP32 |
| `lib/widgets/common_widgets.dart` | Card status, card sensor dan widget yang digunakan semula |
| `lib/utils/formatters.dart` | Format tarikh, masa, suhu dan kelembapan |
| `web/index.html` | Halaman permulaan Flutter Web dan base path deployment |
| `web/favicon.svg` | Ikon tab browser |
| `tool/check_config.py` | Semak field Firebase untuk platform yang dipilih sebelum build |
| `tool/prepare_android.py` | Sediakan fail Android daripada template Flutter tanpa build APK |
| `.github/workflows/android.yml` | Workflow manual untuk APK demo dan source projek penuh |
| `.github/workflows/web.yml` | Workflow manual untuk build web dan publish GitHub Pages |
| `WEB_AND_ANDROID_BM.md` | Panduan dua platform dan GitHub |

## Cara copy-paste

1. Buka projek Flutter `labguard` kau.
2. Backup nilai Firebase yang kau sudah isi. Jika masih guna versi satu fail, nilainya ada dalam `class AppConfig` pada `lib/main.dart` lama.
3. Salin folder `lib` daripada ZIP ini ke root projek Flutter kau dan gantikan fail LabGuard yang sama nama. Hasilnya mesti `labguard/lib/main.dart`, bukan `labguard/lib/lib/main.dart`.
4. Jika mahu paste secara manual, cipta folder `config`, `models`, `services`, `pages`, `widgets` dan `utils` di dalam `lib`. Cipta setiap fail mengikut jadual, kemudian paste kod ke fail masing-masing. Kekalkan nama fail supaya import betul.
5. Konfigurasi Web yang kau berikan sudah diisi dalam `lib/config/app_config.dart`. Isi `androidAppId` untuk Android; nilai `appId` Android daripada versi lama boleh dipindahkan ke field itu. Semak `apiKey` Android menggunakan `google-services.json`.
6. Jika belum pernah setup dependencies, salin `pubspec.yaml` yang diberikan dan jalankan `flutter pub get`.
7. Untuk pakej baharu dua platform, salin juga `web`, `tool`, `.github` dan `analysis_options.yaml`. Ikut `WEB_AND_ANDROID_BM.md` untuk build pada GitHub, atau `START_HERE_BM.md` untuk hardware/database.

Untuk mengubah rupa satu page, buka fail page tersebut. Untuk menambah menu bawah, buka `home_page.dart`. Untuk mengubah konfigurasi Firebase, buka `app_config.dart`.

Versi ini disediakan sebagai kod sumber. Tiada compile, build APK atau deployment web dilakukan. Folder Android dijana oleh workflow atau `tool/prepare_android.py`.
