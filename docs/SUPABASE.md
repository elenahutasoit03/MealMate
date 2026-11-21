# Supabase MealMate

## Project yang terhubung

Source saat ini mengarah ke project Supabase bernama `MealMate`. URL dan publishable key client dikonfigurasi di `lib/config/supabase_config.dart`.

## Tabel runtime

### `public.recipes`

Katalog resep. Aplikasi hanya membaca resep aktif (`is_active = true`). RLS policy mengizinkan `SELECT` untuk role `anon` dan `authenticated`, dengan syarat `is_active = true`. Role aplikasi tidak diberi privilege `INSERT`, `UPDATE`, atau `DELETE` pada tabel ini.

Kolom penting yang dipakai aplikasi meliputi identitas/nama resep, deskripsi, waktu memasak, biaya per porsi, jumlah porsi batch, gambar, bahan, langkah, metadata estimasi biaya, dan empat nilai nutrisi opsional.

### `public.user_meal_mate_state`

Menyimpan satu snapshot JSONB per user. `user_id` menjadi primary key dan foreign key ke `auth.users(id)`. Policy `SELECT`, `INSERT`, dan `UPDATE` menggunakan `auth.uid() = user_id` untuk role `authenticated`. Anonymous Auth Supabase juga memakai role Postgres `authenticated`; policy tetap membatasi setiap sesi ke baris miliknya sendiri.

Role aplikasi hanya memperoleh privilege `SELECT`, `INSERT`, dan `UPDATE`. Akses `DELETE` tidak diberikan kepada client aplikasi.

### `public.recipe_import_staging`

Tabel kerja internal untuk proses impor/kurasi data resep. Tabel ini bukan bagian dari alur runtime aplikasi. RLS aktif dan tidak ada policy untuk client; privilege `anon` dan `authenticated` telah dicabut. Jangan menambahkan policy publik untuk tabel ini.

## Supabase Storage

Bucket `meal-recipe-images` pada project aktif disetel public untuk pembacaan gambar resep, dengan batas 5 MB dan MIME type JPEG, PNG, serta WebP. Tidak ada policy upload untuk role aplikasi; pengelolaan gambar dilakukan oleh pihak yang berwenang, bukan dari client MealMate.

## Menyiapkan project Supabase baru

> Langkah ini hanya untuk database baru yang memang disiapkan terpisah. Jangan menjalankan bootstrap `schema.sql` begitu saja pada database aktif karena file tersebut juga menambahkan data resep starter.

1. Buat project Supabase baru.
2. Aktifkan Anonymous Sign-Ins pada pengaturan Auth.
3. Jalankan `supabase/schema.sql` pada project baru.
4. Jika tabel lama sudah ada dan belum memiliki kolom nutrisi, jalankan `supabase/add_recipe_nutrition_columns.sql`.
5. Pastikan URL dan publishable key pada `lib/config/supabase_config.dart` menunjuk ke project yang dimaksud.
6. Masukkan katalog resep yang telah dikurasi dan memiliki sumber/izin penggunaan yang sesuai.

`schema.sql` membuat struktur runtime minimum, bucket gambar, policy, dan tujuh resep starter. File tersebut bukan dump lengkap dari project Supabase aktif dan tidak membuat tabel staging internal.

## Migration privilege minimum

`migrations/20261119153247_tighten_mealmate_table_privileges.sql` mencatat migration yang sudah diterapkan pada project Supabase MealMate tanggal 19 November 2026. Isinya membatasi privilege client sebagai berikut:

- `recipes`: hanya `SELECT` untuk `anon` dan `authenticated`.
- `user_meal_mate_state`: `SELECT`, `INSERT`, dan `UPDATE` untuk `authenticated`.
- `recipe_import_staging`: tidak dapat diakses oleh `anon` atau `authenticated`.

Migration tersebut idempotent dan tidak menghapus data. Project aktif sudah menerapkannya; file disimpan di repository agar perubahan database terdokumentasi.

## Catatan autentikasi anonim

Anonymous Auth cocok untuk penggunaan tanpa form pendaftaran, tetapi identitas anonim tidak dapat dipulihkan otomatis setelah pengguna sign out, menghapus data lokal/browser, atau berpindah perangkat. Untuk penggunaan jangka panjang lintas perangkat, aplikasi kelak perlu menambahkan alur linking identity ke akun permanen dan mekanisme pemulihan yang sesuai.

## Pemeriksaan keamanan project aktif (19 November 2026)

- RLS aktif pada tabel runtime.
- Performance Advisor dan Health Advisor tidak melaporkan temuan pada pemeriksaan saat itu.
- Security Advisor masih menampilkan catatan Anonymous Sign-Ins (sesuai desain saat ini), RLS enabled/no policy pada tabel staging (sengaja dikunci), dan Leaked Password Protection belum aktif. Peringatan proteksi password perlu ditangani sebelum autentikasi berbasis password digunakan.
- Jangan pernah menaruh `service_role` key atau `sb_secret_...` pada aplikasi Flutter atau repository.
