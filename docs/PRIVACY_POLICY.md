# Kebijakan Privasi Timerin

**Terakhir Diperbarui:** 8 Oktober 2026  
**Berlaku Efektif:** 8 Oktober 2026  
**Entitas Pengembang:** Tim Pengembang Timerin ("kami", "aplikasi", atau "Timerin")  
**Kontak Perlindungan Data:** timerindev@gmail.com

---

## 1. Pendahuluan

Selamat datang di **Timerin**. Kami menghargai dan berkomitmen penuh untuk melindungi privasi serta data pribadi pengguna kami ("Anda"). Kebijakan Privasi ini disusun sebagai bentuk transparansi dan kepatuhan terhadap ketentuan hukum yang berlaku di Republik Indonesia, khususnya **Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP)**.

Dengan mengunduh, memasang, mendaftar, atau menggunakan aplikasi Timerin, Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui seluruh ketentuan dalam Kebijakan Privasi ini serta menyetujui pemrosesan data pribadi Anda sebagaimana diuraikan di bawah ini.

---

## 2. Definisi

- **Data Pribadi:** Data tentang orang perseorangan yang teridentifikasi atau dapat diidentifikasi secara tersendiri atau dikombinasi dengan informasi lainnya baik secara langsung maupun tidak langsung.
- **Subjek Data Pribadi:** Orang perseorangan yang pada dirinya melekat Data Pribadi (Pengguna Timerin).
- **Pengendali Data Pribadi:** Pihak yang menentukan tujuan dan melakukan kendali pemrosesan Data Pribadi (Pengembang Timerin).
- **Overlay Window:** Antarmuka utilitas mengambang sistem Android (`SYSTEM_ALERT_WINDOW`) yang menampilkan timer cooldown spell.

---

## 3. Data Pribadi yang Kami Kumpulkan

Kami menganut prinsip pembatasan tujuan dan minimalisasi data (hanya mengumpulkan data yang benar-benar esensial untuk pengoperasian aplikasi):

### A. Data Akun & Otentikasi (Disediakan Pengguna)

Saat Anda masuk menggunakan Layanan Masuk Google (Google Sign-In), kami menerima data dari penyedia identitas:

- **Alamat Email:** Digunakan sebagai identifikasi akun unik dan tujuan verifikasi bukti langganan.
- **Nama Tampilan Profil (Display Name):** Ditampilkan pada menu profil pengguna di aplikasi.
- **ID Pengguna Firebase (UID):** Pengenal acak unik alfanumerik yang dihasilkan oleh Firebase Authentication untuk mengaitkan status langganan Anda.

### B. Data Status Layanan & Akses

Data yang disimpan pada basis data aman cloud kami (Google Cloud Firestore):

- **Waktu Mulai Trial (`trialStartedAt`):** Timestamp server saat Anda pertama kali mengaktifkan masa percobaan 24 jam.
- **Waktu Berakhir Langganan (`subscriptionEndsAt`):** Timestamp server masa aktif langganan bulanan berbayar Anda.
- **Waktu Aktivitas Terakhir (`lastSeenAt`):** Timestamp server terakhir kali aplikasi disinkronkan untuk verifikasi integritas waktu (mencegah manipulasi jam perangkat).
- **Waktu Pendaftaran (`createdAt`):** Timestamp pembuatan akun.
- **Status Permintaan Hapus Akun (`deleteRequestedAt`):** Timestamp jika Anda mengajukan permohonan penghapusan akun.

### C. Data Teknis & Diagnostik Otomatis

- **Laporan Kerusakan (Crash Reports):** Melalui Firebase Crashlytics, kami menerima rekaman jejak tumpukan kesalahan (stack trace), model perangkat keras, versi sistem operasi Android, dan status memori bebas saat terjadi kerusakan aplikasi untuk perbaikan stabilitas. Laporan ini bersifat teknis dan **tidak pernah mencatat informasi identitas pribadi (email/UID/token)**.

---

## 4. Data yang TIDAK Pernah Kami Kumpulkan atau Akses

Untuk menjaga integritas dan keamanan Anda:

1. **TIDAK Membaca Konten Layar atau Game:** Timerin **tidak** menggunakan Android `AccessibilityService`, `MediaProjection` (rekaman/tangkapan layar), atau API inspeksi UI. Timerin tidak membaca piksel, chat, nama pemain, atau peristiwa di dalam game Mobile Legends.
2. **TIDAK Mengakses Memori Game:** Timerin tidak melakukan injeksi kode, modifikasi file instalasi game, reverse engineering, atau hooking memori game.
3. **TIDAK Mengakses Data Pribadi Sensitif di Perangkat:** Timerin **tidak** meminta atau mengakses kontak telepon, SMS, media/galeri, kamera, mikrofon, atau lokasi geografis (GPS).
4. **TIDAK Menjalankan Dynamic Code Loading:** Timerin tidak mengunduh atau mengeksekusi kode biner/APK dari server asing secara tersembunyi.

---

## 5. Tujuan dan Dasar Hukum Pemrosesan Data Pribadi

Sesuai dengan Pasal 20 UU PDP, kami memproses data Anda berdasarkan **Persetujuan yang Sah (Consent)** dan **Pelaksanaan Perjanjian Layanan**:

- **Menyediakan Layanan Utama:** Mengotentikasi akun Anda dan memvalidasi apakah masa trial (24 jam) atau langganan aktif Anda masih berlaku.
- **Pencegahan Penyalahgunaan:** Memastikan sistem trial 24 jam hanya dapat digunakan satu kali per akun dan waktu akses terlindungi dari manipulasi jam lokal perangkat.
- **Verifikasi Pembayaran Manual:** Memverifikasi transfer pembayaran langganan melalui QRIS yang dikirimkan bukti mutasinya melalui email resmi.
- **Pemberitahuan Pembaruan:** Menyediakan informasi ketersediaan versi aplikasi terbaru demi keamanan pengguna.
- **Peningkatan Kualitas:** Menganalisis laporan kegagalan aplikasi secara anonim untuk memperbaiki bug.

---

## 6. Penyimpanan, Retensi, dan Keamanan Data

- **Lokasi Penyimpanan:** Data akun disimpan pada infrastruktur cloud Google Firebase yang memiliki sertifikasi kepatuhan ISO/IEC 27001, SOC 1/2/3, dan enkripsi data saat transit (TLS/HTTPS) serta saat istirahat (AES-256).
- **Masa Retensi:** Data akun Anda disimpan selama akun Anda aktif. Jika Anda mengajukan penghapusan akun atau akun tidak aktif selama lebih dari 24 bulan setelah masa langganan berakhir, data Anda akan dihapus atau dianonimkan secara permanen.
- **Keamanan Keystore & Kode:** Aplikasi dibangun dengan pengamanan ketat, minimasi izin sistem, dan dipublikasikan dengan tanda tangan kriptografis resmi.

---

## 7. Hak-Hak Anda sebagai Subjek Data Pribadi (UU PDP)

Berdasarkan Bab VI UU PDP, Anda memiliki hak-hak berikut:

1. **Hak Mendapatkan Informasi:** Mengetahui identitas pengendali, tujuan pemrosesan, dan dasar hukum pemrosesan data (sebagaimana tertuang dalam dokumen ini).
2. **Hak Mengakses Data:** Melihat informasi akun dan status langganan Anda secara langsung melalui halaman Pengaturan di aplikasi.
3. **Hak Memperbarui / Memperbaiki Data:** Memperbarui informasi profil melalui pengaturan Akun Google Anda.
4. **Hak Menarik Persetujuan & Mengakhiri Pemrosesan:** Anda berhak berhenti menggunakan aplikasi dan keluar (Sign Out) kapan saja.
5. **Hak Menghapus Data (Right to Erasure):**
   - Anda dapat mengajukan penghapusan akun langsung melalui menu:  
     `Pengaturan` -> `Minta Hapus Akun`.
   - Tindakan ini akan mencatat permohonan penghapusan Anda (`deleteRequestedAt`) pada sistem kami.
   - Tim pengembang akan memproses penghapusan dokumen pengguna secara permanen dari basis data dalam waktu maksimal 14 (empat belas) hari kerja. Anda juga dapat mengirimkan konfirmasi penghapusan ke email `timerindev@gmail.com`.

---

## 8. Layanan Pihak Ketiga

Aplikasi Timerin menggunakan layanan pihak ketiga yang tunduk pada kebijakan privasi masing-masing:

- **Google Play Services / Google Sign-In:** [Kebijakan Privasi Google](https://policies.google.com/privacy)
- **Google Firebase (Authentication, Firestore, Crashlytics):** [Kebijakan Privasi Firebase](https://firebase.google.com/support/privacy)

Kami tidak pernah menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pihak ketiga mana pun untuk tujuan pemasaran.

---

## 9. Penafian Independensi Game (Game Disclaimer)

Timerin adalah aplikasi utilitas stopwatch independen yang dikembangkan oleh pihak ketiga. Timerin **TIDAK berafiliasi, didukung, disponsori, atau secara khusus disetujui oleh Moonton Games atau penerbit Mobile Legends: Bang Bang**. Hak cipta dan merek dagang game sepenuhnya merupakan milik dari pemiliknya masing-masing.

---

## 10. Perubahan Kebijakan Privasi

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu untuk menyesuaikan dengan regulasi terbaru atau pengembangan fitur. Setiap perubahan akan diberitahukan melalui pembaruan tanggal "Terakhir Diperbarui" pada dokumen ini atau melalui pengumuman di aplikasi.

---

## 11. Hubungi Kami

Jika Anda memiliki pertanyaan, keluhan, atau ingin melaksanakan hak pelindungan data pribadi Anda, silakan hubungi kami melalui:

- **Email:** timerindev@gmail.com
- **Subjek:** Permohonan Perlindungan Data Pribadi - Timerin
