# LabGuard — Web dan Android

Satu folder `lib` digunakan untuk kedua-dua platform. Setiap page kekal dalam fail berasingan. Login, bacaan sensor, kawalan, history dan alerts menggunakan Firebase yang sama. Telefon menggunakan menu bawah; browser yang lebar menggunakan menu di sebelah kiri.

Pakej ini ialah kod sumber dan workflow, bukan APK siap atau laman yang telah dipublish. Tiada compile, build, deployment atau ujian pada hardware sebenar dilakukan untuk kemas kini ini. GitHub hanya melakukan build apabila kau tekan **Run workflow**.

## 1. Gunakan projek Firebase yang sama

Gunakan projek **labguard-419c6**. Tak perlu buat database atau akaun operator kedua untuk versi web. Operator yang sama boleh login pada Android dan web. Akaun ESP32 tetap berasingan.

Database perlu mempunyai UID operator dalam `members/lab01` dan UID ESP32 dalam `deviceUsers`. Pemetaan akaun sebenar dan langkah untuk database yang dipulihkan ada dalam `ACCOUNT_SETUP_BM.md`. Jika masih kosong, ikut bahagian database dalam `START_HERE_BM.md` dahulu. Web tidak menghasilkan bacaan sensor sendiri.

## 2. Daftarkan app Web

App Web kau sudah didaftarkan dan konfigurasi yang kau berikan telah dimasukkan ke pakej ini. Tak perlu daftar app Web sekali lagi. Langkah di bawah ialah rujukan untuk pendaftaran; konfigurasi sedia ada boleh dilihat semula melalui Project settings.

1. Buka Firebase Console, kemudian projek **LabGuard**.
2. Buka **Project settings → General → Your apps → Add app**. Pilih ikon Web **`</>`**. Ikon ini juga boleh muncul pada Project Overview.
3. Isi nickname **LabGuard Web**.
4. Tak perlu aktifkan Firebase Hosting kerana kita menggunakan GitHub Pages.
5. Tekan **Register app**.
6. Firebase memaparkan objek `firebaseConfig`. Salin nilainya mengikut jadual di bawah. Tidak perlu paste kod JavaScript itu ke `index.html` dan tidak perlu install npm untuk pakej ini.

Untuk melihat semula konfigurasi, buka **Project settings → General → Your apps**, pilih **LabGuard Web**, kemudian bahagian **SDK setup and configuration → Config**.

## 3. Isi satu fail konfigurasi

Buka `lib/config/app_config.dart`.

| Field dalam fail Dart | Ambil nilai dari |
|---|---|
| `apiKey` | Android `google-services.json`: `client[].api_key[].current_key` |
| `androidAppId` | Android `google-services.json`: `client[].client_info.mobilesdk_app_id` |
| `webApiKey` | Objek Web `firebaseConfig`: `apiKey` |
| `webAppId` | Objek Web `firebaseConfig`: `appId` |
| `messagingSenderId` | Objek Web `messagingSenderId`, sama dengan Android `project_info.project_number` |
| `projectId` | `labguard-419c6` |
| `databaseUrl` | URL HTTPS Realtime Database yang kau sudah buat |
| `authDomain` | Objek Web `firebaseConfig`: `authDomain` |
| `labId` | Kekalkan `lab01` |

Konfigurasi Web telah diisi berdasarkan objek `firebaseConfig` yang kau berikan: `webApiKey`, `webAppId`, `messagingSenderId`, `authDomain`, Project ID dan URL database. Konfigurasi Android telah diisi daripada `google-services.json` yang kau berikan untuk package `com.amiraziz.labguard`; API key Android sepadan dengan nilai terdahulu.

Tiada placeholder konfigurasi Firebase yang tinggal dalam `app_config.dart`. Android App ID ialah `1:997404851226:android:120512201e45d898a8a5a3`. Semakan field tempatan Android dan Web lulus; sambungan Firebase sebenar belum diuji dan app belum dibuild. Semua nilai ialah string, jadi kekalkan tanda petik dalam fail Dart.

App ID Android mengandungi `:android:`. App ID Web mengandungi `:web:`. Kedua-duanya bukan package name dan bukan UID pengguna. Jika kau sudah isi `appId` dalam versi lama, pindahkan nilai itu ke `androidAppId`.

App Android perlu didaftarkan dengan package **`com.amiraziz.labguard`**. Jika `google-services.json` mempunyai beberapa client, pilih yang mempunyai package name itu. Pakej ini initialise Firebase menggunakan `FirebaseOptions`, jadi tidak perlu tambah Google Services Gradle plugin atau paste Firebase JavaScript ke HTML.

Isi App ID Web untuk build web, dan App ID Android untuk build Android. Satu platform boleh dibuild dahulu walaupun App ID platform satu lagi belum diisi.

Jangan masukkan password akaun operator, password ESP32 atau password Wi-Fi dalam fail Flutter. Pengguna menaip email/password operator pada skrin Login.

## 4. Masukkan fail ke GitHub

1. Cipta repository, contohnya **labguard**.
2. Extract ZIP ini. Upload **kandungan folder `LabGuard_Copy_Paste`**, bukan fail ZIP sahaja atau satu folder tambahan yang membungkus semuanya.
3. Pada halaman utama repository, kau mesti nampak terus **`pubspec.yaml`, `lib`, `web`, `tool`** dan fail panduan.
4. Pastikan `.github/workflows/android.yml` dan `.github/workflows/web.yml` turut ada. Dalam file manager Linux, tekan **Ctrl+H** untuk melihat folder `.github`.
5. Jika uploader browser tidak memasukkan folder itu, gunakan **Add file → Create new file** di GitHub. Isi nama penuh `.github/workflows/android.yml`, paste kandungan fail Android dari ZIP, lalu commit. Ulang untuk `.github/workflows/web.yml`.
6. Commit fail pada default branch repository, lazimnya **main**.

GitHub Pages pada akaun percuma biasanya memerlukan repository public. Repo private memerlukan pelan/akses Pages yang sesuai. Laman yang dipublish melalui Pages biasanya boleh diakses umum; data makmal masih memerlukan login dan rules Firebase.

Fail `.ino` dalam ZIP masih menggunakan placeholder. Jika kau upload salinan firmware yang sudah diubah sendiri, keluarkan password sebenar dahulu. Bagi proses build Flutter, `.ino` tidak diperlukan; ia dimuat naik ke ESP32 melalui Arduino IDE.

## 5. Publish versi Web

1. Dalam repository, buka **Settings → Pages**.
2. Di **Build and deployment**, pilih **Source: GitHub Actions**.
3. Buka tab **Actions → Publish Flutter Web**.
4. Tekan **Run workflow**, pilih default branch, kemudian **Run workflow**.
5. Tunggu kedua-dua job `build` dan `deploy` menjadi hijau.
6. Buka link deployment yang dipaparkan pada workflow atau **Settings → Pages → Visit site**.

Link biasanya berbentuk `https://USERNAME.github.io/labguard/`. Gunakan URL sebenar yang GitHub berikan. Workflow mendapatkan base path repository secara automatik, jadi nama repository boleh berbeza.

Jika konfigurasi Firebase belum lengkap, workflow berhenti pada **Check Firebase Web configuration** dan menyenaraikan field yang perlu diisi. Betulkan `app_config.dart`, commit, kemudian jalankan workflow sekali lagi.

Web perlu dibuild sebelum diterbitkan. Upload fail `.dart` sahaja ke Pages tidak terus menghasilkan dashboard. Workflow ini membina Flutter Web dan menghantar folder `build/web` kepada Pages.

## 6. Build dan install Android

1. Dalam tab **Actions**, pilih **Build Android APK**.
2. Tekan **Run workflow** pada default branch.
3. Workflow menjana folder Android menggunakan Flutter jika belum ada. Ia menetapkan minimum Android SDK 24, package name dan permission Internet.
4. Selepas berjaya, buka run tersebut. Di bahagian **Artifacts**, download **LabGuard-Android-Demo**.
5. Extract fail yang dimuat turun. Di dalamnya ada **`app-debug.apk`**.
6. Pindahkan APK ke telefon Android, buka fail dan benarkan pemasangan daripada aplikasi pengurus fail apabila diminta.
7. Buka LabGuard dan login menggunakan akaun operator yang sama dengan versi web.

APK ini ialah **debug APK untuk ujian/demonstrasi pada telefon**, bukan pakej untuk diterbitkan ke Play Store. Kunci debug pada runner GitHub boleh berubah antara build. Jika Android menolak pemasangan sebagai update kerana tandatangan berbeza, uninstall salinan demo lama, kemudian install APK baharu dan login semula. Bacaan yang tersimpan dalam Firebase kekal.

Artifact kedua, **LabGuard-Flutter-Source**, mengandungi projek Flutter bersama folder Android yang telah dijana dan `pubspec.lock`. Download ini jika kau perlukan folder projek penuh untuk submission atau untuk dibuka dalam Android Studio. Fail firmware `.ino` perlu disertakan secara berasingan untuk submission.

Artifact disimpan selama 14 hari dalam workflow ini. Download APK dan source yang kau perlukan selepas build berjaya.

## 7. Jika mahu jalankan pada laptop

Bahagian ini pilihan. Kau tidak perlu menjalankannya jika menggunakan GitHub Actions.

Buka terminal dalam folder yang mengandungi `pubspec.yaml`. Gunakan Flutter stable dengan Dart 3.12 atau lebih baharu dan Python 3 untuk penyediaan Android.

Untuk web:

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Buka `http://127.0.0.1:8080` dalam Chromium atau Chrome. Terminal mesti kekal berjalan. URL ini untuk laptop itu sahaja; telefon menggunakan link GitHub Pages selepas deployment.

Untuk telefon Android melalui USB:

```bash
python3 tool/prepare_android.py
flutter pub get
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

Gantikan `YOUR_ANDROID_DEVICE_ID` dengan ID telefon daripada `flutter devices`. Aktifkan USB debugging dan benarkan komputer pada telefon. Pada Windows, gunakan `py` jika arahan `python3` tidak tersedia.

Script `prepare_android.py` hanya menyediakan fail projek Android; script itu sendiri tidak build APK. Jika folder `android` sudah ada, ia mengekalkan folder tersebut dan melaraskan minimum SDK, label serta permission yang diperlukan. Backup projek lama sebelum menggabungkan fail.

## 8. Uji kedua-dua platform

1. Upload firmware ESP32 dan semak Serial Monitor pada **115200 baud** dahulu.
2. Semak suhu, kelembapan dan gas keluar. Sambungan kod ini: DHT11 GPIO18, MQ5 AO melalui voltage divider ke GPIO34, flame GPIO33, relay GPIO16.
3. Pastikan firmware menunjukkan `Device signed in.` dan tiada permission error database.
4. Login pada telefon Android dan dashboard web. Kedua-duanya sepatutnya membaca `labs/lab01` yang sama.
5. Semak status ESP32 Online, kemudian uji setiap page.
6. Hantar satu arahan Test Alarm dari satu platform pada satu masa. Tunggu pengesahan ESP32 sebelum hantar arahan lain. Kedua-dua platform berkongsi satu lokasi command, jadi jangan tekan arahan serentak semasa demo.
7. Sahkan buzzer dan lampu fizikal bertindak bersama. Status app menunjukkan arahan relay; ia bukan sensor maklum balas untuk setiap actuator.

Jika DHT11/MQ5 tiada bacaan dalam Serial Monitor, perubahan Android/Web tidak membaiki sambungan sensor. Selesaikan pin, bekalan dan bacaan fizikal terlebih dahulu.

## 9. Masalah biasa

| Masalah | Perkara yang perlu disemak |
|---|---|
| Workflow tidak kelihatan | Fail `.github/workflows/*.yml` berada pada default branch dan `pubspec.yaml` pada root |
| `Fill in lib/config/app_config.dart` | Isi field yang disebut dalam log, commit dan run semula |
| Web App ID gagal semakan | Gunakan nilai `appId` Web yang mengandungi `:web:`, bukan Android App ID |
| Pages belum aktif / gagal configure | Settings → Pages → Source mesti GitHub Actions; semak akses Pages untuk repository |
| Workflow menunggu approval environment | Buka job deployment dan ikuti tetapan environment repository kau |
| Website 404 | Tunggu job deploy siap dan gunakan URL sebenar daripada Settings → Pages |
| Paparan setup selepas ubah config | Commit perubahan dan build/deploy sekali lagi; refresh browser |
| Login gagal pada dua platform | Semak Email/Password provider, akaun operator dan projek Firebase yang sama |
| Database access failed | UID operator mesti berada di `members/lab01`, dengan boolean `true`, dan rules dipublish |
| ESP32 Offline | Pastikan Wi-Fi, akaun device, `deviceUsers`, rules dan bacaan terbaru daripada ESP32 |
| Bacaan hanya `N/A` / Warm-up | Semak DHT11 pada Serial Monitor; kod menyembunyikan nilai gas semasa warm-up awal |
| Android update tidak boleh install | Kunci debug build berbeza; uninstall versi demo lama dahulu |
| Android package tidak sepadan | Gunakan package `com.amiraziz.labguard` pada projek Android dan Firebase |

## 10. Rubrik dan rujukan

Gunakan APK yang dipasang pada telefon untuk menunjukkan deployment Android. Sertakan link Web sebagai versi tambahan. Kedua-duanya menggunakan enam skrin utama yang sama. Buzzer dan warning light kekal berkongsi satu relay; bukan dua kawalan bebas.

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/web/setup
- https://docs.flutter.dev/deployment/web
- https://docs.flutter.dev/deployment/android
- https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
- https://docs.github.com/en/actions/tutorials/store-and-share-data
- https://github.com/subosito/flutter-action

Semakan kod sumber dan struktur fail sahaja dibuat untuk pakej ini. Kejayaan build, login dan kawalan hardware perlu disahkan apabila kau menjalankan workflow dan menggunakan peranti sebenar.
