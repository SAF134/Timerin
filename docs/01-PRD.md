# PRD: Timerin

## 1. Tujuan & Non-Goals
**Tujuan:** Pemain MLBB bisa mencatat cooldown spell musuh dengan 1 ketukan pada overlay, tanpa meninggalkan game. Pendapatan lewat langganan Rp10.000/bulan.
**Non-Goals:** iOS, pembayaran otomatis, deteksi otomatis spell, membaca layar/konten game, panel admin, sinkronisasi antar perangkat.

## 2. Persona
**Raka (17–25 th), pemain ranked:** ingin tahu kapan Flicker/Retribution/dll. musuh siap lagi; tidak mau mencatat manual; HP menengah; sensitif terhadap lag.

## 3. Status Akses
| Status | Kondisi | Timer |
|---|---|---|
| BARU | `trialStartedAt` kosong, tidak berlangganan | Siap mulai trial; saat tombol Aktifkan ditekan, catat `trialStartedAt` ke server terlebih dahulu, lalu luncurkan overlay |
| TRIAL | sekarang < `trialStartedAt` + 24 jam | Boleh |
| BERLANGGANAN | sekarang < `subscriptionEndsAt` | Boleh |
| HABIS | selain di atas | **Terkunci**, app tetap bisa dibuka |

"Sekarang" = waktu server (lihat `03-TECH.md`), bukan jam perangkat.

## 4. Functional Requirements
| ID | Deskripsi | Prioritas |
|---|---|---|
| FR-001 | Splash lalu arahkan otomatis: sudah login → Beranda; belum → Onboarding (kali pertama) atau Masuk | Must |
| FR-002 | Onboarding 3 layar: fungsi aplikasi, penjelasan izin overlay, info trial & harga; tombol Lewati | Must |
| FR-003 | Masuk dengan Google; buat dokumen pengguna pada login pertama | Must |
| FR-004 | Beranda: banner status akses, tombol Aktifkan/Matikan overlay, panel pengaturan overlay | Must |
| FR-005 | Jumlah timer 1–5 | Must |
| FR-006 | Format tampilan: detik total (120, 119, 118…) atau mm:ss (02:00, 01:59…) | Must |
| FR-007 | Durasi per timer: preset 30 dtk, 1, 2, 3 menit + custom (5–600 dtk, asumsi) | Must |
| FR-008 | Ukuran overlay dapat diatur (skala 50–150%) | Must |
| FR-009 | Orientasi susunan timer: vertikal atau horizontal | Must |
| FR-010 | Overlay tampil di atas game; ketuk timer → hitung mundur; selesai → indikator visual; ketuk lagi → mulai ulang | Must |
| FR-011 | Overlay dapat digeser posisinya | Should |
| FR-012 | Alur izin overlay: cek, jelaskan, arahkan ke setelan, tangani penolakan; sertakan panduan bypass "Restricted Settings" (menu 3 titik di Info Aplikasi) untuk perangkat Android 13+ hasil sideload | Must |
| FR-013 | Trial 24 jam (waktu berjalan) dimulai saat tombol Aktifkan Overlay pertama kali ditekan; wajib berhasil menulis `trialStartedAt` ke Firestore (waktu server) sebelum overlay tampil, sekali per akun | Must |
| FR-014 | Setelah akses HABIS: overlay berhenti, tombol overlay nonaktif, banner ajakan berlangganan | Must |
| FR-015 | Halaman Berlangganan: harga, QRIS statis, langkah bayar, tombol "Kirim bukti" (buka email dengan UID & email terisi) | Must |
| FR-016 | Developer mengaktifkan langganan 30 hari di Firebase; app membaca status terbaru saat dibuka & tarik-segarkan | Must |
| FR-017 | Halaman Pengaturan: akun, status & tanggal berakhir langganan, status izin overlay, bantuan (tips baterai), kebijakan privasi, versi, keluar, minta hapus akun | Must |
| FR-018 | Pengaturan timer tersimpan lokal dan dipulihkan | Must |
| FR-019 | Notifikasi persisten saat overlay aktif, dengan tombol Matikan | Must |
| FR-020 | Cek versi baru: jika versi di `config/app` lebih tinggi dari versi terpasang, tampilkan ajakan memperbarui (buka tautan unduhan di browser; app tidak mengunduh/menginstal APK sendiri) | Should |

## 5. Non-Functional Requirements
| ID | Target | Verifikasi |
|---|---|---|
| NFR-001 | Ketuk → timer mulai < 100 ms; selisih hitung mundur ≤ 1 dtk per 10 menit (pakai jam monotonik) | Tes manual + unit test |
| NFR-002 | Overlay ringan: CPU rata-rata < 3%, RAM < 100 MB (asumsi) | Android Studio Profiler |
| NFR-003 | Cold start < 2 dtk di HP menengah | Profiling |
| NFR-004 | Overlay tetap jalan offline selama masa akses valid | Tes mode pesawat |
| NFR-005 | Izin hanya yang terdaftar di `04-SECURITY.md`; Firestore rules lolos tes emulator | Review manifest + emulator test |
| NFR-006 | Android 8.0 (API 26) ke atas, termasuk Android 14/15 | Uji perangkat/emulator |
| NFR-007 | Kontras ≥ 4,5:1; target sentuh di app ≥ 48 dp | Review desain |
| NFR-008 | Ukuran APK < 30 MB | Build report |
| NFR-009 | Crash-free sessions ≥ 99% | Crashlytics |
| NFR-010 | Tetap dalam kuota gratis Firebase Spark | Monitoring konsol |

## 6. Acceptance Criteria Kunci
- **FR-010:** Given overlay aktif, When timer 1 diketuk, Then hitung mundur mulai dari durasi timer 1; Then timer lain tidak terpengaruh; Given hitung mundur 0, Then tampil indikator selesai dan kembali siap.
- **FR-013:** Given akun baru tanpa trial, When overlay diaktifkan pertama kali, Then `trialStartedAt` diisi waktu server dan tidak bisa diubah lagi.
- **FR-014:** Given trial lewat 24 jam dan tidak berlangganan, When pengguna membuka Beranda, Then overlay berhenti, tombol nonaktif, banner berlangganan tampil; app tetap bisa dibuka.
- **FR-016:** Given developer mengisi `subscriptionEndsAt` di masa depan, When pengguna tarik-segarkan, Then status menjadi BERLANGGANAN dan tombol overlay aktif.
- **Edge:** izin overlay ditolak, offline saat pertama kali login, jam perangkat diubah, app dimatikan sistem saat overlay aktif.

## 7. Aturan Bisnis
- Satu akun = satu trial; trial tidak bisa diulang.
- Langganan 30 hari; jika masih aktif saat diperpanjang, ditumpuk dari tanggal berakhir (keputusan final).
- Pengaturan timer disimpan lokal (tidak disinkronkan).

## 8. Asumsi & Pertanyaan Terbuka
Semua pertanyaan terbuka sudah dijawab (lihat `00-BRIEF.md`).
