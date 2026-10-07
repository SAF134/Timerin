# AGENTS.md: Timerin

Aplikasi Android (Flutter + Firebase): overlay timer spell Mobile Legends. Trial 24 jam, lalu Rp10.000/bulan (pembayaran QRIS manual).
Status: lihat milestone di `docs/05-TASKS.md`.

## Dokumen
| File | Baca kapan |
|---|---|
| `docs/01-PRD.md` | Sebelum fitur apa pun (FR/NFR, status akses) |
| `docs/02-DESIGN.md` | Saat membuat UI (tokens & layar) |
| `docs/03-TECH.md` | Arsitektur, data, logika akses, rules |
| `docs/04-SECURITY.md` | Izin, manifest, rules, build rilis |
| `docs/05-TASKS.md` | Memilih & mengerjakan task |

## Perintah
```bash
flutter pub get
flutter run
dart format .
flutter analyze
flutter test
firebase emulators:start --only firestore,auth
flutter build appbundle --release
```

## Struktur
`lib/core` (tema, util) · `lib/features/{auth,onboarding,home,overlay,subscription,settings}` · `lib/data` · `lib/overlay_main.dart` · `firestore.rules`. Fitur tidak saling impor langsung.

## WAJIB
- Baca dokumen relevan dulu; kerjakan **1 task per sesi**
- Pakai design tokens `02-DESIGN.md`, tanpa warna/ukuran hardcode
- Waktu akses selalu dari **waktu server + jam monotonik**, jangan percaya `DateTime.now()`
- Tulis tes bersama kode; jalankan `dart format`, `flutter analyze`, `flutter test` sebelum menyatakan selesai
- Perbarui dokumen jika kontrak/perilaku berubah
- Commit: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`)
- Jangan pernah mengganti package name atau keystore rilis (terikat registrasi developer)

## DILARANG
- Menambah izin Android atau `AccessibilityService`, atau membaca layar/konten game
- Mengubah `firestore.rules` atau model data tanpa izin; mengizinkan klien menulis `subscriptionEndsAt`
- Menambah dependensi tanpa izin
- Commit secret: keystore, `key.properties`, kunci admin/service account
- Mencatat email/UID/token di log
- Menghapus atau melemahkan tes; menonaktifkan lint
- Menambah `REQUEST_INSTALL_PACKAGES` atau mengunduh/menginstal APK dari dalam app
- Refactor besar di luar task; mengarang requirement

## Berhenti & Tanya Jika
Requirement ambigu, perlu izin/dependensi baru, menyentuh rules, manifest, signing, atau logika trial/langganan.

## Laporan Akhir
(a) yang diubah, (b) file terdampak, (c) hasil analyze/test, (d) risiko/catatan, (e) langkah berikutnya.

## Gotchas (isi seiring waktu)
- _kosong_
