# Arsitektur MealMate

## Gambaran umum

MealMate menggunakan Flutter/Dart untuk antarmuka dan logika aplikasi. Supabase menyediakan katalog resep, autentikasi anonim, dan penyimpanan state pengguna di PostgreSQL. SharedPreferences menyimpan state dan cache katalog pada perangkat.

## Lapisan aplikasi

| Bagian | Tanggung jawab |
|---|---|
| `lib/main.dart` | Inisialisasi Supabase, memuat state awal, dan membuat root aplikasi. |
| `lib/config/supabase_config.dart` | URL project dan publishable key Supabase untuk client. |
| `lib/data/supabase_service.dart` | Anonymous Auth, mengambil resep aktif, membaca state, dan melakukan upsert state pengguna. |
| `lib/data/meal_mate_data.dart` | State aplikasi, pemilihan menu, budget, pantry, sinkronisasi daftar belanja, riwayat, dan persistensi lokal/cloud. |
| `lib/models/recipe.dart` | Model resep, bahan, harga, metadata estimasi, dan nutrisi opsional. |
| `lib/models/meal_plan_record.dart` | Snapshot riwayat meal plan. |
| `lib/utils/ingredient_quantity.dart` | Normalisasi dan kalkulasi takaran bahan yang bisa dikenali. |
| `lib/screens/` | Splash, home, pengaturan budget/pantry/target, meal plan, detail resep, daftar belanja, estimasi biaya, profil, dan riwayat. |
| `lib/widgets/` | Komponen antarmuka yang digunakan ulang. |

## Alur pemuatan data

1. `main.dart` menginisialisasi Supabase.
2. `MealMateData.load()` memuat SharedPreferences dan cache katalog resep yang sebelumnya berhasil diambil dari Supabase.
3. Aplikasi mencoba memperbarui katalog dari `public.recipes` dengan filter `is_active = true`.
4. Jika katalog pertama kali belum tersedia dan tidak ada cache valid, aplikasi menampilkan layar koneksi/kesalahan dan menyediakan aksi coba lagi. Katalog contoh tidak digunakan sebagai fallback.
5. State pengguna dimuat dari `public.user_meal_mate_state` berdasarkan `auth.uid()`.

## Alur penyimpanan

- Perubahan state dijadwalkan secara berurutan melalui antrean penyimpanan di `MealMateData`.
- SharedPreferences ditulis terlebih dahulu.
- Jika Supabase terinisialisasi dan sesi anonim tersedia, snapshot yang sama dikirim ke Supabase dengan `upsert` berdasarkan `user_id`.
- Primary key `user_meal_mate_state.user_id` memastikan satu baris state aktif per identitas pengguna.
- Riwayat meal plan merupakan snapshot terpisah di dalam state pengguna; daftar riwayat dibatasi di logika aplikasi.

## Rekomendasi menu

Menu dibentuk dari katalog resep aktif yang valid. Penilaian mempertimbangkan target pengguna, biaya per porsi, variasi, dan kecocokan dengan bahan pantry. Data protein numerik digunakan hanya saat nilai protein tersedia untuk seluruh kandidat yang dibandingkan; nilai nutrisi `NULL` tidak dianggap nol.

## Daftar belanja

Daftar belanja menggabungkan bahan manual pengguna dengan bahan otomatis dari meal plan aktif. Nama bahan dinormalisasi untuk mendeteksi item yang setara. Kuantitas yang satuan/formatnya dapat dikenali diproses oleh `ingredient_quantity.dart`; takaran ambigu atau gabungan tetap ditandai agar tidak menghasilkan konversi palsu.

Mengganti resep melalui `changeRecipe()` langsung menyinkronkan ulang daftar belanja dan menjadwalkan penyimpanan. Menyimpan Meal Plan juga membuat snapshot riwayat.
