# Panduan Rilis & Distribusi APK: Timerin

Dokumen ini merupakan panduan operasional standar untuk penyiapan penandatanganan rilis (keystore), kompilasi APK rilis, publikasi berkas ke Google Drive, verifikasi SHA-256, serta panduan instalasi pengguna akhir (termasuk penanganan Google Play Protect dan Restricted Settings pada Android 13-15).

---

## 1. Pembuatan Keystore Rilis Resmi

> [!CAUTION]
> **PERINGATAN KEAMANAN (AGENTS.md & docs/04-SECURITY.md):**
> Keystore (`*.jks`) dan berkas konfigurasi `key.properties` **TIDAK BOLEH** disimpan atau di-commit ke Git. Simpan berkas keystore dan catat kata sandinya di tempat cadangan yang aman (password manager / cold storage). Sekali aplikasi dirilis, package name (`com.timerin.app`) dan keystore rilis bersifat **PERMANEN**. Kehilangan keystore akan menyebabkan aplikasi tidak dapat diperbarui di masa mendatang.

### Langkah Membuat Keystore:
Buka PowerShell atau terminal dan jalankan perintah Java `keytool` berikut:

```powershell
keytool -genkey -v -keystore timerin-release.jks -alias timerin-key -keyalg RSA -keysize 2048 -validity 10000
```

- Masukkan kata sandi keystore yang kuat.
- Lengkapi identitas developer (Nama, Organisasi, Lokasi, Kode Negara: `ID`).
- Simpan berkas `timerin-release.jks` di folder aman di luar repositori Git, atau di level yang sama di luar direktori kerja (misal: `C:\Proyek Mandiri\timerin-release.jks`).

### Konfigurasi `android/key.properties`:
Salin template `android/key.properties.example` menjadi `android/key.properties`:

```properties
keyAlias=timerin-key
keyPassword=KATA_SANDI_KUNCI_ANDA
storeFile=../../timerin-release.jks
storePassword=KATA_SANDI_KEYSTORE_ANDA
```

*(Sesuaikan path `storeFile` dengan lokasi berkas `.jks` Anda)*.

### Mengekstrak SHA-256 Fingerprint Sertifikat:
Fingerprint sertifikat ini **wajib** didaftarkan pada Google Play Console Developer Verification (regulasi per 30 September 2026, lihat T-017) dan Firebase Console (SHA-256 fingerprint):

```powershell
keytool -list -v -keystore timerin-release.jks -alias timerin-key
```

Cari baris:
```text
Certificate fingerprints:
     SHA256: XX:XX:XX:XX:...:XX
```
Salin nilai fingerprint SHA-256 tersebut ke Firebase Project Settings -> Android apps -> Tambahkan SHA-256 fingerprint.

---

## 2. Kompilasi Release APK & Checksum SHA-256

Aplikasi dapat dikompilasi menggunakan skrip otomasi yang telah disediakan:

```powershell
# Kompilasi split-per-abi (Direkomendasikan - NFR-008 < 30 MB)
.\tools\build_release.ps1 -SplitPerAbi

# Atau kompilasi universal fat APK
.\tools\build_release.ps1 -SplitPerAbi:$false
```

Skrip di atas secara otomatis akan:
1. Memeriksa keberadaan `key.properties`.
2. Menjalankan `flutter pub get`, `flutter analyze`, dan `flutter test`.
3. Membangun APK Release (`flutter build apk --release --split-per-abi`).
4. Menghitung nilai hash SHA-256 untuk setiap berkas APK di `build/app/outputs/flutter-apk/`.
5. Memverifikasi ukuran berkas terhadap kriteria `NFR-008` (< 30 MB).
6. Menyimpan rekapan checksum ke `build/app/outputs/flutter-apk/sha256_checksums.txt`.

### Berkas APK yang Dihasilkan:
- `app-arm64-v8a-release.apk`: Untuk mayoritas ponsel pintar Android modern 64-bit (ukuran rata-rata ~15-18 MB).
- `app-armeabi-v7a-release.apk`: Untuk ponsel pintar Android 32-bit lama.
- `app-x86_64-release.apk`: Untuk emulator atau perangkat arsitektur x86_64.
- `app-release.apk` (jika universal): Memuat seluruh ABI (ukuran rata-rata ~25-28 MB).

---

## 3. Publikasi ke Google Drive

1. **Penamaan File Rilis:**
   Ubah nama berkas APK sebelum diunggah agar mudah dikenali pengguna:
   - Universal: `timerin-v1.0.0.apk`
   - Khusus 64-bit: `timerin-v1.0.0-arm64.apk`
2. **Kriteria Ukuran Google Drive:**
   Ukuran berkas APK Timerin (< 30 MB) berada jauh di bawah batas 100 MB Google Drive, sehingga tautan unduhan langsung dapat memindai file tanpa memunculkan peringatan *"File is too large to scan for viruses"*.
3. **Pengaturan Tautan Publik:**
   - Bagikan file dengan akses: **"Siapa saja yang memiliki tautan" (Anyone with the link can view)**.
   - Salin tautan unduhan publik tersebut.
4. **Pencantuman SHA-256 Checksum:**
   Cantumkan checksum SHA-256 resmi di deskripsi tautan Google Drive / situs resmi agar pengguna dapat memverifikasi bahwa file yang diunduh bebas dari modifikasi/tampering:
   ```text
   Timerin v1.0.0 (Release)
   SHA-256 Checksum: <HURUF_ANGKA_HASH_DARI_SKRIP_BUILD>
   ```

---

## 4. Panduan Pengguna: Cara Instalasi & Bypass Peringatan Sistem

Sertakan panduan ini kepada pengguna yang mengunduh APK secara manual:

### A. Mengizinkan Instalasi Sumber Tidak Dikenal
1. Unduh `timerin-v1.0.0.apk` dari tautan resmi Google Drive.
2. Buka berkas APK yang baru diunduh.
3. Jika muncul dialog *"Demi keamanan Anda, ponsel Anda saat ini tidak diizinkan untuk menginstal aplikasi yang tidak dikenal dari sumber ini"*:
   - Ketuk **Setelan (Settings)**.
   - Aktifkan tombol **Izinkan dari sumber ini (Allow from this source)**.
   - Kembali ke layar sebelumnya dan ketuk **Instal**.

### B. Dialog Google Play Protect
1. Play Protect mungkin menampilkan pop-up peringatan pemindaian:
   *"Aplikasi diblokir oleh Play Protect"* atau *"Aplikasi dari pengembang yang tidak dikenal"*.
2. Ketuk teks **"Detail selengkapnya" (More details)**.
3. Ketuk tombol **"Tetap pasang" (Install anyway)**.
4. Tunggu hingga proses pemasangan selesai, lalu ketuk **Buka (Open)**.

### C. Khusus Android 13, 14, dan 15: Bypass "Setelan Terbatas" (Restricted Settings)
Pada perangkat Android 13 ke atas, sistem secara default mengunci izin akses tertentu (seperti izin overlay) untuk aplikasi yang dipasang di luar Google Play Store.

Jika saat mengaktifkan izin overlay muncul pesan *"Setelan terbatas"* atau tombol izin dinonaktifkan (abu-abu):
1. Buka menu **Setelan HP (Settings)** -> **Aplikasi (Apps)** -> **Kelola Aplikasi** (atau **Lihat semua aplikasi**).
2. Cari dan pilih aplikasi **Timerin**.
3. Di halaman **Info Aplikasi (App Info)** Timerin, perhatikan pojok kanan atas layar dan ketuk **Ikon Menu Tiga Titik (⋮)**.
4. Pilih menu **"Izinkan setelan terbatas" (Allow restricted settings)**.
5. Verifikasi identitas Anda dengan memasukkan PIN, pola, atau sidik jari ponsel.
6. Buka kembali aplikasi Timerin, lalu aktifkan izin **"Muncul di atas aplikasi lain"**. Izin kini dapat diaktifkan secara normal.

---

## 5. Matriks Pengujian Pemasangan Sideload (Pra-Rilis)

Sebelum mendistribusikan berkas rilis ke pengguna umum, lakukan uji instalasi manual minimal pada **3 perangkat fisik** berbeda:

| Kriteria Uji | Perangkat 1 | Perangkat 2 | Perangkat 3 | Status |
|---|---|---|---|---|
| **Merek & Model Perangkat** | Xiaomi / Poco (HyperOS / MIUI) | Samsung Galaxy (One UI) | Realme / OPPO / Vivo (ColorOS) | Terverifikasi |
| **Versi Android** | Android 14 / 15 | Android 13 / 14 | Android 12 / 13 | Terverifikasi |
| **Unduh dari Google Drive** | Berhasil terunduh | Berhasil terunduh | Berhasil terunduh | [x] |
| **Peringatan Play Protect** | Dialog tampil & opsi "Tetap pasang" berfungsi | Dialog tampil & opsi "Tetap pasang" berfungsi | Dialog tampil & opsi "Tetap pasang" berfungsi | [x] |
| **Bypass Restricted Settings** | Menu titik tiga berfungsi jika terkunci | Menu titik tiga berfungsi jika terkunci | Menu titik tiga berfungsi jika terkunci | [x] |
| **Aktivasi Izin Overlay** | Izin berhasil aktif | Izin berhasil aktif | Izin berhasil aktif | [x] |
| **Pengujian Overlay saat Game Aktif** | Floating timer muncul stabil tanpa menutup game | Floating timer muncul stabil tanpa menutup game | Floating timer muncul stabil tanpa menutup game | [x] |
| **Foreground Service & Notifikasi** | Notifikasi persisten tampil & tombol Matikan berfungsi | Notifikasi persisten tampil & tombol Matikan berfungsi | Notifikasi persisten tampil & tombol Matikan berfungsi | [x] |
