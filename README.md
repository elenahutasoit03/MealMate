# MealMate

**Aplikasi perencanaan menu makanan mingguan berdasarkan budget, jumlah orang, dan bahan yang tersedia.**

MealMate membantu pengguna menyusun menu selama tujuh hari, melihat detail resep, memperkirakan biaya, dan menyiapkan daftar belanja berdasarkan bahan yang sudah tersedia di rumah.

> Repository ini disiapkan sebagai dokumentasi dan source code proyek akademik. Publikasi ke Google Play Store bukan target distribusi proyek saat ini.

## Fitur utama

- Mengatur budget makanan mingguan.
- Mengatur jumlah orang yang akan makan.
- Mencatat bahan makanan yang tersedia di rumah (pantry).
- Memilih target menu: **Hemat**, **Seimbang**, atau **Tinggi Protein**.
- Menghasilkan rencana menu tujuh hari dari katalog resep aktif di Supabase.
- Melihat detail resep, bahan, takaran, langkah memasak, dan waktu memasak.
- Melihat informasi nutrisi per porsi ketika data nutrisi tersedia di katalog.
- Mengganti resep untuk hari tertentu.
- Membuat daftar belanja dari menu aktif, menggabungkan bahan yang setara, dan mempertahankan bahan manual pengguna.
- Menghitung estimasi biaya menu dan estimasi belanja.
- Menyimpan riwayat rencana menu.
- Menyimpan state secara lokal dan menyinkronkannya ke Supabase.

## Teknologi

| Bagian | Teknologi |
|---|---|
| Mobile app | Flutter dan Dart |
| Database dan Data API | Supabase PostgreSQL |
| Autentikasi | Supabase Anonymous Auth |
| Penyimpanan lokal | SharedPreferences |
| Penyimpanan gambar resep | Supabase Storage (bucket `meal-recipe-images`) dan URL gambar pada data resep |
| Pengujian | Flutter Test |

Dependensi utama dapat dilihat di `pubspec.yaml`. `pubspec.lock` disertakan agar versi paket aplikasi tetap terkunci saat project dipasang.

## Struktur project

```text
lib/
├── config/       # Konfigurasi Supabase untuk aplikasi client
├── data/         # State aplikasi, pemuatan katalog, dan layanan Supabase
├── models/       # Model resep dan riwayat meal plan
├── screens/      # Halaman dan alur antarmuka MealMate
├── theme/        # Tema aplikasi
├── utils/        # Utilitas kuantitas bahan
└── widgets/      # Widget UI yang digunakan bersama

assets/images/    # Asset gambar lokal
supabase/         # SQL bootstrap, migration, dan panduan database
test/             # Unit dan regression tests
docs/             # Dokumentasi arsitektur, database, dan keamanan
.github/          # Workflow pemeriksaan otomatis GitHub Actions
```

## Persyaratan lokal

- Flutter SDK stable (versi yang digunakan saat validasi project: **3.41.7**).
- Dart SDK yang kompatibel dengan batas versi di `pubspec.yaml`.
- Visual Studio Code atau IDE Flutter lain.
- Emulator Android atau perangkat Android untuk pengujian mobile.
- Akses ke project Supabase MealMate.

## Menjalankan project

Clone repository, buka terminal pada folder yang berisi `pubspec.yaml`, lalu jalankan:

```bash
flutter pub get
flutter test
flutter analyze
```

Untuk menjalankan aplikasi melalui VS Code, pilih device Android atau Chrome lalu gunakan **Run and Debug (F5)**. Perintah `flutter devices` dapat digunakan untuk melihat device yang terdeteksi.

## Konfigurasi Supabase

Konfigurasi client berada di:

```text
lib/config/supabase_config.dart
```

Aplikasi menggunakan Supabase URL dan **publishable key** (`sb_publishable_...`). Publishable key memang dirancang untuk digunakan pada aplikasi client. Keamanan tetap bergantung pada Row Level Security (RLS), policy, dan privilege database.

**Jangan pernah memasukkan `service_role` key, `sb_secret_...`, password database, access token, atau kredensial pribadi ke source code atau repository.** Jangan mengunggah file `.env`, `android/local.properties`, `android/key.properties`, atau file signing ke GitHub.

Untuk project Supabase baru, baca [`docs/SUPABASE.md`](docs/SUPABASE.md) sebelum menjalankan SQL. `supabase/schema.sql` adalah bootstrap untuk database baru, bukan dump penuh dari project Supabase aktif. Jangan menjalankan ulang bootstrap tersebut pada database aktif tanpa meninjau dampaknya terlebih dahulu.

## Pengujian

Test suite saat snapshot repository ini terdiri dari **33 test**:

| File | Jumlah test |
|---|---:|
| `test/meal_mate_data_test.dart` | 20 |
| `test/recipe_test.dart` | 5 |
| `test/ingredient_quantity_test.dart` | 4 |
| `test/shopping_list_deduplication_test.dart` | 4 |
| **Total** | **33** |

Perintah validasi:

```bash
flutter test
flutter analyze
```

Workflow GitHub Actions pada `.github/workflows/flutter-ci.yml` menjalankan kedua pemeriksaan tersebut pada setiap push dan pull request.

## Catatan data dan batasan saat ini

- Katalog resep aplikasi dimuat dari tabel `public.recipes` di Supabase. Cache lokal hanya menyimpan katalog yang sebelumnya berhasil diterima dari Supabase; tidak ada katalog resep contoh yang otomatis digunakan sebagai pengganti saat koneksi pertama gagal.
- State pengguna disimpan di SharedPreferences dan disinkronkan ke `public.user_meal_mate_state` menggunakan Supabase Anonymous Auth.
- Akun anonim tidak sama dengan akun permanen. Jika pengguna sign out, menghapus data aplikasi/browser, atau pindah perangkat, identitas anonim yang sama tidak otomatis dapat dipulihkan. Pengaitan email/nomor telepon belum menjadi alur autentikasi pada source saat ini.
- Harga resep merupakan estimasi dari katalog, bukan harga pasar real-time.
- Kolom nutrisi (kalori, protein, karbohidrat, dan lemak per porsi) sudah didukung model dan database, tetapi nilainya dapat kosong (`NULL`) sampai data yang dapat dipertanggungjawabkan dimasukkan.
- Target Tinggi Protein tidak boleh dianggap sebagai pengukuran gram protein ketika data nutrisi belum tersedia secara lengkap.
- Pada audit project Supabase yang terhubung tanggal **19 November 2026**, tabel `recipes` memiliki 41 baris, 34 di antaranya aktif. `schema.sql` dalam repository hanya memuat tujuh resep starter untuk instalasi baru; katalog terkurasi pada project aktif tidak seluruhnya diekspor ke repository ini.
- Fitur transaksi, pembayaran, atau pemesanan bahan makanan tidak termasuk ruang lingkup aplikasi.

## Lisensi

Repository ini belum menyertakan file `LICENSE`. Tentukan lisensi dan izin penggunaan ulang sebelum mendistribusikan source code sebagai proyek open-source.
