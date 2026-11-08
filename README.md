# RT 08 — Starter Project Android (Flutter + Firebase)

Proyek awal aplikasi administrasi RT 08 untuk pengurus dan warga. Data bersama disimpan di Firebase.

## Fitur yang sudah disiapkan pada source
- Login dan pendaftaran akun email/password.
- Peran `warga` dan `pengurus` (role disimpan di Firestore).
- Dashboard RT 08.
- Form laporan lingkungan dengan kategori, lokasi, uraian, dan foto.
- Daftar laporan realtime dan pembaruan status oleh pengurus.
- Pengumuman realtime.
- Struktur menu data warga, kas RT, dan surat (menu awal/placeholder untuk tahap berikutnya).

> Ini adalah source proyek awal, bukan APK yang sudah ditandatangani. APK final harus dibangun setelah konfigurasi Firebase milik RT 08 dipasang.

## Persiapan
1. Pasang Flutter SDK dan Android Studio di komputer.
2. Buat project Flutter:
   ```bash
   flutter create rt08
   ```
3. Salin folder `lib/` dari paket ini ke project `rt08/` (timpa `lib/main.dart`).
4. Ganti isi `pubspec.yaml` dengan dependensi di bawah, lalu jalankan:
   ```bash
   flutter pub get
   ```
5. Buat project di https://console.firebase.google.com
   - Tambahkan aplikasi Android dengan package ID `com.rt08.app`.
   - Aktifkan Authentication > Email/Password.
   - Buat Firestore Database.
   - Aktifkan Firebase Storage.
6. Pasang FlutterFire CLI dan konfigurasi:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Pilih project Firebase dan aplikasi Android `com.rt08.app`. Perintah ini membuat `lib/firebase_options.dart`.
7. Di `lib/main.dart`, aktifkan import dan inisialisasi `firebase_options.dart` seperti petunjuk komentar pada file.
8. Terapkan rules dari folder `firebase/` ke Firestore Rules dan Storage Rules di Firebase Console.
9. Jalankan:
   ```bash
   flutter run
   ```

## Dependensi pubspec.yaml
```yaml
name: rt08
description: Aplikasi administrasi RT 08
publish_to: "none"
version: 1.0.0+1
environment:
  sdk: ">=3.3.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  firebase_storage: ^12.3.6
  image_picker: ^1.1.2
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
flutter:
  uses-material-design: true
```

## Menjadikan akun pertama sebagai pengurus
- Daftarkan akun pertama lewat aplikasi.
- Di Firebase Console > Firestore, buka koleksi `users`, cari dokumen dengan ID UID akun tersebut.
- Ubah field `role` menjadi `pengurus`.
- Akun warga berikutnya otomatis mendapat role `warga`.
- Jangan pernah memberi akses pengurus kepada akun yang tidak dipercaya.

## Membuat APK
Dari folder project:
```bash
flutter build apk --release
```
File hasil build:
`build/app/outputs/flutter-apk/app-release.apk`

Untuk APK yang bisa dibagikan luas, atur signing key Android release sendiri. Jangan membagikan file konfigurasi rahasia Firebase Admin atau service account.

## Catatan keamanan dan privasi
- Jangan masukkan NIK/nomor KK ke laporan umum. Batasi data sensitif warga hanya untuk pengurus yang berwenang.
- Atur persetujuan warga dan kebijakan retensi foto/laporan.
- Rules ini adalah baseline awal; uji dengan akun warga dan pengurus sebelum dipakai sungguhan.
