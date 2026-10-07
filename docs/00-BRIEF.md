# BRIEF: Timerin

- **Deskripsi:** Aplikasi Android berupa overlay timer agar pemain Mobile Legends bisa menghitung cooldown spell musuh dengan satu ketukan, tanpa keluar dari game.
- **Tipe & platform:** Aplikasi mobile, Android saja. Flutter + Firebase (Auth Google, Firestore).
- **Distribusi:** APK langsung via Google Drive. Fase 1 (beta): akun *limited distribution* Android Developer Console (gratis, tanpa ID, maks. 20 perangkat). Fase 2 (rilis publik): akun penuh (US$25 sekali bayar + verifikasi identitas) setelah pendapatan menutup biayanya.
- **Pengguna:** Pemain Mobile Legends (MLBB) di Android.
- **Alur layar:** Splash → Onboarding → Masuk (Google) → Beranda. Plus halaman Berlangganan dan Pengaturan.
- **Monetisasi:** Trial gratis 24 jam (mulai saat fitur overlay pertama kali dipakai), lalu Rp10.000/bulan.
- **Pembayaran (manual):** Pengguna scan QRIS statis developer → kirim bukti ke email developer → developer verifikasi → developer mengaktifkan langganan 30 hari di Firebase.
- **Skala (asumsi):** 6 bulan ≤ 1.000 pengguna, 2 tahun ≤ 10.000.
- **Data pribadi:** Email, nama, UID Google, timestamp trial/langganan. Tidak ada data kartu/rekening.
- **Batasan:** Solo developer, Firebase paket gratis (Spark, tanpa Cloud Functions), aktivasi langganan manual.

## Fitur MVP (urut prioritas)
1. Login Google
2. Overlay timer (1–5 buah) yang diketuk untuk menghitung mundur
3. Pengaturan timer: jumlah, format tampilan, durasi per timer, ukuran, orientasi
4. Trial 24 jam + penguncian fitur setelah habis
5. Halaman Berlangganan (QRIS manual)
6. Halaman Pengaturan

## Di Luar Cakupan
iOS, pembayaran otomatis, panel admin, deteksi spell otomatis / membaca layar game, game lain, push notification, sinkronisasi pengaturan antar perangkat.

## Risiko Awal
| ID | Risiko | Mitigasi |
|---|---|---|
| RISK-001 | Distribusi APK langsung: sejak 30 Sep 2026 di Indonesia, aplikasi tak terdaftar hanya bisa dipasang lewat "advanced flow" (mode developer, restart, tunggu 24 jam), sehingga calon pengguna sulit memasang | Mulai dengan *limited distribution* gratis (≤ 20 perangkat); naik ke akun penuh sebelum rilis publik; jangan ganti package name/keystore |
| RISK-002 | Trial disalahgunakan dengan banyak akun Google | Diterima untuk MVP; App Check + device-binding bila perlu |
| RISK-003 | Izin overlay + foreground service memicu peringatan Play Protect / review Play | Izin minimal, penjelasan jelas, lihat `04-SECURITY.md` |
| RISK-004 | Kebijakan pengembang game terhadap aplikasi pihak ketiga | Overlay hanya menampilkan timer sendiri, tidak menyentuh game; cantumkan disclaimer |
| RISK-005 | Aktivasi manual tidak scalable | Terima di MVP; rencanakan otomatisasi di fase berikutnya |
| RISK-006 | OEM (Xiaomi, Oppo, Vivo, dll.) mematikan service di background | Tips pengaturan baterai di app |

## Keputusan (pertanyaan terbuka sudah terjawab)
- **OQ-1:** Distribusi lewat APK langsung via tautan Google Drive, bukan Play Store.
- **OQ-2:** Trial 24 jam = waktu berjalan sejak dimulai.
- **OQ-3:** Trial dimulai saat tombol Aktifkan Overlay pertama kali ditekan dan overlay tampil.
- **OQ-4:** Perpanjangan saat langganan masih aktif ditumpuk +30 hari dari tanggal berakhir.
