# Pengujian MealMate

## Unit dan regression tests

| File | Cakupan | Jumlah pada snapshot ini |
|---|---|---:|
| `test/meal_mate_data_test.dart` | Rekomendasi, perubahan state, budget, pantry, sinkronisasi, penyimpanan, dan riwayat | 20 |
| `test/recipe_test.dart` | Parsing/serialisasi resep, metadata porsi, biaya, dan nutrisi | 5 |
| `test/ingredient_quantity_test.dart` | Konversi satuan, pecahan, faktor porsi, dan takaran ambigu/gabungan | 4 |
| `test/shopping_list_deduplication_test.dart` | Deduplikasi bahan, pantry, status checklist, dan bahan manual | 4 |
| **Total** |  | **33** |

Jalankan dari root project:

```bash
flutter pub get
flutter test
flutter analyze
```

Hasil validasi yang dilaporkan pemilik project pada snapshot ini adalah `33: All tests passed!` dan `No issues found!` dari `flutter analyze`.

## Pengujian manual sebelum penyerahan

1. Jalankan aplikasi dengan F5 pada device yang dipakai.
2. Muat katalog resep dari Supabase.
3. Ubah jumlah orang dan pastikan rekomendasi/estimasi diperbarui.
4. Generate menu tujuh hari.
5. Ganti satu resep dan pastikan daftar belanja otomatis disinkronkan.
6. Pastikan bahan pantry tidak dimasukkan sebagai kebutuhan belanja.
7. Periksa bahan yang sama, takaran, dan estimasi biaya.
8. Simpan Meal Plan dan pastikan riwayat tercatat.
9. Tutup dan buka kembali aplikasi; pastikan state lokal/cloud dapat dimuat.

Pengujian manual tambahan tetap diperlukan setelah perubahan source, SQL, atau konfigurasi Supabase.
