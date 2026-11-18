# Akaun LabGuard

Gunakan projek Firebase lama `labguard-419c6` dan Lab ID `lab01`.

| Kegunaan | Email | Firebase User UID |
|---|---|---|
| Login Android dan Web | `amir.sm480@gmail.com` | `YjVfVSbJ8BQiYtH4X0JO1dptY223` |
| ESP32 | `tboom743@gmail.com` | `VBYNfKL6ezOyQfDei1uvxcGf2Kk2` |

Pemetaan ini disediakan dalam fail projek. Perubahan pada database sebenar masih perlu dibuat melalui Firebase Console.

## 1. Semak akaun yang dipulihkan

Buka Authentication > Users. Pastikan kedua-dua email sepadan dengan UID di atas dan akaun boleh menggunakan Email/Password. Password yang digunakan ialah password akaun tersebut dalam Firebase Authentication. Tiada password sebenar disimpan dalam pakej ini.

## 2. Tambah akses pada database lama

Buka Realtime Database > Data. Tambah atau kemas kini hanya dua nilai berikut:

| Lokasi penuh | Nilai | Jenis |
|---|---|---|
| `members/lab01/YjVfVSbJ8BQiYtH4X0JO1dptY223` | `true` | Boolean |
| `deviceUsers/VBYNfKL6ezOyQfDei1uvxcGf2Kk2` | `lab01` | String |

Setiap `/` menandakan satu aras dalam pokok data. Contohnya, untuk operator, buka `members`, kemudian `lab01`, dan tambah child dengan nama `YjVfVSbJ8BQiYtH4X0JO1dptY223`. Nilainya ialah boolean `true`, tanpa tanda petik.

Untuk ESP32, buka `deviceUsers` dan tambah child bernama `VBYNfKL6ezOyQfDei1uvxcGf2Kk2`. Pilih jenis String dan masukkan nilai `lab01`.

Jika parent belum wujud, gunakan butang tambah untuk bina aras yang diperlukan. Jika paparan berbeza, semak screenshot sebelum mengubah data. Kekalkan cabang `labs` dan sejarah sedia ada. Import keseluruhan `database.seed.json` pada root hanya apabila database benar-benar kosong.

## 3. Semak rules

Rules mesti membaca akses operator daripada `members/$lab/$uid` dan akses ESP32 daripada `deviceUsers/$uid`. Fail `database.rules.json` dalam pakej ini menggunakan struktur tersebut. Jika rules projek lama sudah sama, kekalkan. Jika berbeza, bandingkan dan simpan salinan rules lama sebelum menerbitkan rules pakej ini untuk projek LabGuard.

## 4. Isi konfigurasi ESP32

Dalam `LabGuard_ESP32.ino`, email sudah ditetapkan:

```cpp
constexpr char DEVICE_EMAIL[] = "tboom743@gmail.com";
constexpr char DEVICE_PASSWORD[] = "REPLACE_DEVICE_ACCOUNT_PASSWORD";
constexpr char LAB_ID[] = "lab01";
```

Gantikan `REPLACE_DEVICE_ACCOUNT_PASSWORD` sendiri dengan password Firebase Authentication untuk `tboom743@gmail.com`. Isi juga `WIFI_SSID` dan `WIFI_PASSWORD`. Firebase API key dan URL database projek lama sudah diisi. UID tidak perlu dimasukkan ke dalam sketch kerana login Firebase akan mengenal pasti UID akaun itu.

## 5. Login app

Masukkan `amir.sm480@gmail.com` dan password Firebase Authentication akaun itu pada skrin Login Android atau Web. Kedua-dua platform menggunakan akaun operator yang sama.

Android App ID dan konfigurasi projek sudah diisi dalam `lib/config/app_config.dart` daripada `google-services.json` yang kau berikan. Android menggunakan package `com.amiraziz.labguard`. Konfigurasi Web dalam pakej menggunakan snippet yang diberikan sebelum ini; semak padanannya dengan app Web dalam projek yang dipulihkan sebelum menjalankan app. Sambungan sebenar masih perlu diuji pada peranti.

## Rujukan

- [Urus data melalui Firebase Console](https://firebase.google.com/docs/database/manage-data-console)
- [Urus akaun Firebase Authentication](https://firebase.google.com/docs/auth/flutter/manage-users)
