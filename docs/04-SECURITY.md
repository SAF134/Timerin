# SECURITY: Timerin

## 1. Aset & Ancaman Utama
| ID | Ancaman | Mitigasi |
|---|---|---|
| THREAT-001 | Pengguna mengubah `subscriptionEndsAt` / `trialStartedAt` sendiri | Firestore rules (lihat `03-TECH.md` §6), tes emulator |
| THREAT-002 | Mengubah jam perangkat untuk memperpanjang akses | Waktu server (`lastSeenAt`) + jam monotonik |
| THREAT-003 | Trial berulang lewat hapus dokumen / banyak akun | `delete: false`; banyak akun diterima di MVP (App Check bila perlu) |
| THREAT-004 | APK dimodifikasi/di-crack lalu disebarkan ulang | Tanda tangan keystore sendiri + registrasi package name; akses tetap ditentukan data server; publikasikan SHA-256 resmi |
| THREAT-005 | Pembocoran data pengguna | Rules ketat, tanpa data sensitif di log |
| THREAT-006 | Bukti bayar palsu | Developer verifikasi manual nominal & waktu mutasi sebelum aktivasi |

## 2. Izin Android (daftar putih)
| Izin | Alasan |
|---|---|
| `INTERNET` | Firebase Auth, Firestore, Crashlytics |
| `SYSTEM_ALERT_WINDOW` | Overlay timer di atas aplikasi lain |
| `FOREGROUND_SERVICE` | Menjaga service overlay tetap hidup di latar belakang |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Tipe foreground service Android 14 (API 34+) untuk floating utility/timer overlay |
| `POST_NOTIFICATIONS` | Notifikasi persisten service overlay (Android 13+) |

**Konfigurasi Manifest Tambahan:**
- Android 11+ (API 30+): Deklarasikan `<queries>` untuk intent `https` (browser) dan `mailto:` (email).
- Android 14+ (API 34+): Deklarasikan `android:foregroundServiceType="specialUse"` pada service `flutter_overlay_window` dan sertakan `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="Overlay timer for game cooldown" />`.

**Dilarang:** `AccessibilityService`, `READ_SMS`, `READ_CONTACTS`, `REQUEST_INSTALL_PACKAGES`, `MANAGE_EXTERNAL_STORAGE`, perekaman layar, dan izin lain di luar daftar. Setiap penambahan izin harus lewat persetujuan developer.

## 3. Checklist Aman Play Protect & Sistem Android
**Perilaku aplikasi**
- [ ] Tidak membaca layar, konten game, atau aplikasi lain; overlay hanya menampilkan timer sendiri
- [ ] Tidak ada dynamic code loading, tidak mengunduh/menjalankan kode atau APK dari luar
- [ ] Tidak menyembunyikan ikon / tidak berjalan tersembunyi; selalu ada notifikasi saat overlay aktif
- [ ] Overlay tidak menutupi dialog izin/sistem dan bisa dimatikan dari notifikasi
- [ ] Penjelasan izin overlay tampil **sebelum** meminta izin (onboarding + layar izin)

**Konfigurasi build**
- [ ] `android:allowBackup="false"`; semua komponen punya `android:exported` yang benar
- [ ] Tanpa cleartext traffic (HTTPS saja)
- [ ] R8/minify standar boleh; **jangan** pakai packer/obfuscator agresif atau pustaka native yang tidak perlu
- [ ] Rilis ditandatangani keystore sendiri; keystore & password **tidak** masuk repo (backup di tempat aman)
- [ ] `targetSdk` mengikuti level API stabil terbaru (Android menolak/memperingatkan aplikasi dengan target SDK lama)
- [ ] Dependensi minimal; periksa `flutter pub outdated` sebelum rilis

**Distribusi (APK langsung via Google Drive)**
- [ ] **Verifikasi developer Android:** menurut dokumentasi Google, sejak 30 Sep 2026 aplikasi harus terdaftar pada developer terverifikasi agar dipasang/diperbarui normal di perangkat Android bersertifikasi di Indonesia. Aplikasi tak terdaftar hanya bisa lewat ADB atau "advanced flow" (mode developer, restart, tunggu 24 jam, autentikasi) yang tidak realistis untuk pengguna umum. **Jalur Timerin:** beta lewat akun *limited distribution* (gratis, tanpa ID, maks. 20 perangkat; kemungkinan tiap perangkat perlu diotorisasi, cek mekanismenya di Console); rilis publik wajib akun penuh (US$25 + verifikasi identitas). Daftarkan package name + SHA-256 keystore rilis. Baca `developer.android.com/developer-verification` sebelum rilis, karena rincian penegakan bisa berubah.
- [ ] Package name & keystore rilis **permanen**; update harus ditandatangani kunci yang sama
- [ ] Drive: tautan publik, file kecil (< 100 MB agar tidak terkena peringatan "tidak bisa dipindai"), nama file memuat versi, SHA-256 dicantumkan di halaman info
- [ ] Panduan instal untuk pengguna (dengan screenshot): izinkan "Pasang aplikasi tidak dikenal" untuk browser/Drive, jelaskan dialog pemindaian Play Protect dan cara melanjutkannya. Khusus Android 13-15: sertakan panduan bypass "Restricted Settings" (buka Info Aplikasi -> menu 3 titik -> "Izinkan setelan terbatas") agar izin overlay bisa diaktifkan.
- [ ] Uji pemasangan dari Drive di ≥ 3 HP (Android 13-15), Play Protect aktif; pastikan alur aktivasi izin overlay berhasil dilewati setelah bypass setelan terbatas.
- [ ] Update: app tidak mengunduh/menginstal APK sendiri (dilarang `REQUEST_INSTALL_PACKAGES`); hanya menampilkan ajakan dan membuka tautan di browser (FR-020)
- [ ] Catatan jujur: aplikasi di luar Play tidak bisa dijamin 100% bebas peringatan; checklist ini meminimalkan risiko
- Kebijakan Google Play Billing tidak berlaku karena tidak lewat Play

## 4. Keamanan Firebase
- Rules sesuai `03-TECH.md`, diuji di emulator dan **wajib lulus** sebelum rilis
- Tidak ada kunci admin / service account di app maupun repo
- App Check ditunda di MVP (perlu evaluasi untuk APK di luar Play)
- Akses Firebase Console developer: aktifkan 2FA

## 5. Privasi
- Data yang dikumpulkan: email, nama, UID, timestamp trial/langganan, laporan crash
- Kebijakan Privasi wajib (halaman web publik) dan ditautkan di app; selaraskan dengan UU PDP
- Permintaan hapus akun lewat Pengaturan (`deleteRequestedAt`), diproses manual; dokumen dihapus atau dianonimkan sesuai kebijakan
- Log: dilarang mencatat email, token, atau UID

## 6. Aturan Khusus Agent AI
Dilarang menambah izin Android, mengubah `firestore.rules`, atau menambah dependensi tanpa persetujuan. Wajib review manusia untuk: rules, manifest, penandatanganan rilis, dan logika akses/trial.

## 7. Catatan Kepatuhan Game
Overlay tidak membaca/mengubah game. Tetap cantumkan di deskripsi aplikasi bahwa Timerin tidak berafiliasi dengan Moonton/Mobile Legends, dan periksa kebijakan penerbit game terkini (bukan nasihat hukum).
