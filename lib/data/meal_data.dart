import '../models/recipe.dart';

// Katalog resep tidak lagi ditanam di aplikasi.
// Semua resep aktif wajib berasal dari Supabase atau cache hasil sinkronisasi Supabase.
const recipes = <Recipe>[];

// Persediaan dapur dimulai kosong agar aplikasi tidak menganggap
// pengguna memiliki bahan yang belum mereka masukkan sendiri.
const initialIngredients = <String>[];
