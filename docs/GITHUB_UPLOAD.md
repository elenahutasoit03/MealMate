# Menyiapkan repository GitHub

## Sebelum membuat repository

1. Terapkan file dari paket GitHub Prep ke root project.
2. Hapus `README-BUDGET-AWARE-PATCH.md` karena file tersebut menjelaskan patch lama, bukan dokumentasi project.
3. Hentikan Flutter/Chrome, lalu hapus folder cache `.dart_tool` dan `build` jika masih ada. Keduanya dibuat ulang oleh Flutter saat diperlukan.
4. Jangan menghapus `pubspec.lock`; file ini perlu di-commit untuk mengunci versi dependensi aplikasi.
5. Pastikan `.gitignore` terbaru sudah berada di root project, sejajar dengan `pubspec.yaml`.

## File yang tidak boleh diunggah

- `.dart_tool/` (termasuk `.dart_tool/chrome-device/`, yang dapat berisi profil browser seperti Cookies, Login Data, dan History).
- `build/` dan `coverage/`.
- `android/local.properties` (berisi path SDK lokal mesin pengembang).
- `.env` atau file environment lokal.
- `android/key.properties`, file `.jks`, `.keystore`, `.p12`, atau private key.
- Password database, Supabase `service_role`, atau `sb_secret` key.

Jangan mengunggah ZIP project mentah melalui GitHub web uploader. Gunakan Git agar aturan `.gitignore` diterapkan.

## Pemeriksaan dengan Git

Jalankan dari root folder yang berisi `pubspec.yaml`:

```bash
git init
git status --short
```

Periksa daftar file yang akan masuk repository. Pastikan `.dart_tool`, `build`, `android/local.properties`, dan file rahasia tidak muncul.

Jika daftar sudah aman:

```bash
git add .
git status --short
git commit -m "Initial MealMate project"
```

Buat repository kosong di GitHub, lalu ikuti perintah `git remote add origin`, `git branch -M main`, dan `git push -u origin main` yang ditampilkan GitHub untuk repository tersebut.

## Public atau private?

Jika dosen tidak mewajibkan repository publik, mulai dengan **Private** dan undang dosen sebagai collaborator. Ubah menjadi Public hanya jika memang diminta dan hak distribusi seluruh asset/data sudah jelas. Repository ini belum memiliki file `LICENSE`, jadi jangan menambahkan lisensi open-source tanpa keputusan pemilik project.
