# TASKS: Timerin

1 task = 1 sesi agent. Baca dokumen di kolom "Baca" sebelum mulai. Semua task wajib lolos `flutter analyze` dan `flutter test`.

## Roadmap
| Milestone | Tujuan | Exit criteria |
|---|---|---|
| M0 Fondasi | Proyek, Firebase, tema siap | App kosong jalan, login Google berhasil |
| M1 Walking Skeleton | Alur layar + 1 overlay minimal | Overlay tampil di atas aplikasi lain dan menghitung mundur |
| M2 MVP | Semua fitur PRD (Must) | FR-001 s.d. FR-019 terpenuhi |
| M3 Hardening | Keamanan, tes, uji perangkat | Rules lulus emulator, checklist `04-SECURITY.md` hijau |
| M4 Rilis | Aset & distribusi | APK terunggah di Drive, package name terdaftar, uji pemasangan lulus |

## Detail T-001 (contoh format; task lain mengikuti)
### T-001: Inisialisasi proyek
- **Baca:** `AGENTS.md`, `03-TECH.md` §1 & §3
- **Ruang lingkup:** `flutter create` (Android saja), struktur folder, Riverpod, lint ketat, `.gitignore` (keystore, `google-services.json` tidak dikecualikan, `*.jks`/`key.properties` dikecualikan). **Tidak:** fitur apa pun.
- **AC:** `flutter analyze` bersih, app menampilkan halaman kosong, minSdk 26
- **Verifikasi:** `flutter analyze && flutter test && flutter run`
- **Estimasi:** ≤ 2 jam

## Daftar Task
| ID | Task | FR/NFR | Baca | AC ringkas |
|---|---|---|---|---|
| T-001 | Inisialisasi proyek | n/a | TECH | lihat di atas |
| T-002 | Firebase (dev/prod) + login Google + Crashlytics + buat dokumen `users` | FR-003, NFR-009 | TECH §4,6; SECURITY §4 | login berhasil, crashlytics aktif, dokumen dibuat sesuai rules |
| T-003 | Tema & design tokens | n/a | DESIGN §3 | token jadi `ThemeData`, tanpa nilai hardcode |
| T-004 | Splash, onboarding, navigasi awal | FR-001, 002 | DESIGN SCR-001..003 | alur sesuai status login |
| T-005 | Overlay minimal: 1 timer, ketuk → hitung mundur (Selesai) | FR-010 | TECH §2; SECURITY §2 | overlay tampil di atas app lain, hitung mundur monotonik & toggle beranda |
| T-006 | Izin overlay + foreground service (Android 14 specialUse) + notifikasi + panduan restricted settings (Selesai) | FR-012, 019 | SECURITY §2,3 | izin ditolak/restricted ditangani; notifikasi & service aktif |
| T-007 | Pengaturan timer (jumlah, format, durasi, ukuran, susunan) + simpan lokal (Selesai) | FR-005..009, 018 | PRD, DESIGN SCR-004 | overlay mengikuti pengaturan, pulih setelah restart |
| T-008 | Beranda lengkap + pratinjau (terintegrasi AccessService) (Selesai) | FR-004 | DESIGN SCR-004 | semua state banner tampil benar & sinkron status akses |
| T-009 | AccessService: waktu server, status akses, mulai trial atomik, cache monotonik + boot count, stop overlay saat habis (Selesai) | FR-013, 014, NFR-001, 004 | TECH §5; PRD §3 | unit test semua status & ubah-jam; trial aman dari manipulasi |
| T-010 | Halaman Berlangganan (QRIS, email bukti, segarkan) | FR-015, 016 | DESIGN SCR-005 | status berubah setelah developer mengisi tanggal |
| T-011 | Halaman Pengaturan | FR-017 | DESIGN SCR-006 | semua item berfungsi |
| T-012 | Geser posisi overlay | FR-011 | DESIGN SCR-007 | posisi tersimpan |
| T-013 | Tes Firestore rules (emulator) + unit test | NFR-005 | TECH §6,9 | rules tolak ubah langganan, tolak trial ganda, read config publik |
| T-014 | Uji perangkat (≥ 3 merek), tips baterai, optimasi CPU/RAM | NFR-002, 003 | PRD §5 | target NFR tercapai |
| T-015 | Review keamanan & checklist Play Protect | NFR-005 | SECURITY | semua checklist tercentang |
| T-016 | Kebijakan Privasi, aset rilis, signing, build APK, unggah ke Drive + SHA-256 | n/a | SECURITY §3,5 | APK terpasang dari Drive & lolos uji pemasangan |
| T-017 | **Mulai sekarang:** daftar akun *limited distribution* (gratis), daftarkan package name + SHA-256 keystore rilis; upgrade ke akun penuh sebelum melebihi 20 perangkat | NFR-005 | SECURITY §3 | regulasi 30 Sep 2026 aktif; package name terdaftar; perangkat beta ≤ 20 |
| T-018 | Cek versi baru (`config/app`) | FR-020 | TECH §4,6 | ajakan update muncul bila versi terpasang lebih lama (bisa dicek sebelum login) |

Dependensi: T-001 → T-002/T-003 → T-004 → T-006 → T-005 → T-007 → T-009 → T-008; T-010 setelah T-009; T-011 setelah T-009; T-012 setelah T-005; T-013 setelah T-009; T-018 sebelum T-016; T-017 dikerjakan paralel oleh developer; T-014/015/016 terakhir. T-002 dan T-003 bisa paralel.
