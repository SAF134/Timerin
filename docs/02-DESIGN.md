# DESIGN: Timerin

## 1. Prinsip
1. **Cepat & ringan:** overlay harus terbaca sekilas saat game berlangsung.
2. **Gaya visual modern two-tone (DESIGN.jpeg):** header midnight navy (`#111625`) dengan container/sheet terang (`#FFFFFF` / `#F8F9FD`); overlay di atas game tetap gelap (`#111625` 85% opasitas) agar tidak silau dan kontras tinggi.
3. **Jujur soal izin:** selalu jelaskan alasan sebelum meminta izin.

## 2. Navigasi
Splash → (belum pernah) Onboarding → Masuk → Beranda. Dari Beranda: Berlangganan (dari banner) dan Pengaturan (ikon gigi). Tanpa bottom nav.

## 3. Design Tokens (Berdasarkan DESIGN.jpeg)
| Token | Nilai | Keterangan |
|---|---|---|
| primary | `#111625` | Midnight Navy (header, tombol utama, elemen aktif) |
| bg | `#F8F9FD` | Off-white canvas / latar utama aplikasi |
| surface | `#FFFFFF` | Latar kartu / bottom sheet |
| surface-variant | `#F1F4F9` | Latar input, kartu sekunder, item non-aktif |
| border | `#E2E8F0` | Garis tepi kartu dan pemisah |
| text | `#111827` | Slate pekat untuk teks utama pada surface terang |
| text-on-primary | `#FFFFFF` | Teks putih pada tombol primary / header gelap |
| text-muted | `#64748B` | Teks sekunder / keterangan |
| text-muted-header | `#94A3B8` | Keterangan pada header navy |
| accent (timer berjalan) | `#00D1B2` | [ASUMSI] Cyan terang (dipertahankan agar kontras tinggi di atas game) |
| warning (< 5 dtk / trial hampir habis) | `#F59E0B` | [ASUMSI] Amber hangat |
| error | `#EF4444` | [ASUMSI] Merah peringatan |
| Font | Inter (dibundel di aset, tanpa fetch jaringan) | Sans-serif modern |
| Skala teks | 12 / 14 / 16 / 20 / 28 |
| Spacing | 4 · 8 · 12 · 16 · 24 · 32 |
| Radius | 16 (kartu), 14 (tombol), 28 (sheet), 999 (overlay/pill) |

Overlay: lingkaran, latar `primary` (`#111625`) 85% opasitas, angka `text-on-primary`, berubah `accent` (`#00D1B2`) saat berjalan, `warning` (`#F59E0B`) saat ≤ 5 dtk, dan kedip singkat saat selesai. Ukuran dasar 56 dp × skala (50–150%).

## 4. Layar

**SCR-001 Splash:** logo + nama di tengah, maks. 1,5 dtk.

**SCR-002 Onboarding (3 slide):**
```
[ ilustrasi ]
Judul
Deskripsi 2 baris
● ○ ○                [Lewati]  [Lanjut]
```
1. Hitung spell musuh dengan 1 ketukan. 2. Butuh izin "Tampil di atas aplikasi lain" (dan alasan: hanya untuk menampilkan timer, tidak membaca layar). 3. Coba gratis 24 jam, lalu Rp10.000/bulan.

**SCR-003 Masuk:**
```
Logo Timerin
[ G  Masuk dengan Google ]
Dengan masuk, kamu setuju dengan Kebijakan Privasi
```
State: loading, gagal (snackbar + coba lagi), offline.

**SCR-004 Beranda:**
```
Timerin                              [⚙]
┌─ Banner status ─────────────────────┐
│ Trial: sisa 18 jam   / Habis → [Berlangganan]
└─────────────────────────────────────┘
        [  ▶ Aktifkan Overlay  ]
Pengaturan Overlay
 Jumlah timer      [1][2][3][4][5]
 Format            (•) 120,119..  ( ) 02:00,01:59..
 Susunan           (•) Vertikal   ( ) Horizontal
 Ukuran            ──●────  100%
 Durasi tiap timer
   Timer 1  [ 30 dtk ▾ ]
   Timer 2  [ 1 mnt  ▾ ]   (sebanyak jumlah timer)
 [ Pratinjau overlay ]
```
State: BARU (banner "Trial 24 jam mulai saat overlay pertama diaktifkan"), TRIAL, BERLANGGANAN, HABIS (tombol Aktifkan nonaktif, banner berlangganan), izin belum diberikan (tombol memicu SCR izin).

**SCR-005 Berlangganan:**
```
← Berlangganan
Rp10.000 / 30 hari
[ gambar QRIS statis ]
1. Scan QRIS & bayar Rp10.000
2. Kirim bukti bayar ke email developer
3. Tunggu aktivasi (maks. [X] jam)
[ Kirim Bukti via Email ]   (UID & email otomatis terisi)
[ Segarkan Status ]
```

**SCR-006 Pengaturan:**
Akun (nama, email) · Status langganan + tanggal berakhir · Izin overlay (status + tombol buka setelan) · Bantuan (tips pengaturan baterai/autostart per merek) · Kebijakan Privasi · Versi · Keluar · Minta Hapus Akun.

**SCR-007 Overlay (di atas game):** 1–5 lingkaran timer tersusun vertikal/horizontal; ketuk = mulai/mulai ulang; seret = pindah posisi (Should). Tidak menutupi tombol game secara default (posisi awal di tepi kiri-tengah).

## 5. Teks Penting (microcopy)
- Izin: "Timerin butuh izin 'Tampil di atas aplikasi lain' hanya untuk menampilkan timer di atas game. Timerin tidak membaca layar atau data game kamu."
- Trial habis: "Trial 24 jam selesai. Berlangganan Rp10.000/bulan untuk lanjut memakai timer."
- Offline: "Tidak ada koneksi. Status langganan terakhir yang tersimpan dipakai."

## 6. Aksesibilitas
Kontras ≥ 4,5:1, target sentuh ≥ 48 dp di dalam app, label semantik pada kontrol, hormati pengaturan ukuran font sistem pada layar app (overlay memakai skala sendiri).
