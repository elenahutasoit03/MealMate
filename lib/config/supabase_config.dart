/// Konfigurasi project Supabase MealMate.
///
/// Publishable key memang ditujukan untuk aplikasi client. Keamanan data tetap
/// wajib dijaga oleh Row Level Security (RLS) pada database.
/// Jangan pernah menaruh service_role atau secret key di file Flutter.
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectUrl =
      'https://dsuuqeyehgsqfpiikuhd.supabase.co';

  static const String publishableKey =
      'sb_publishable_jw5mcssUfVd92k0BZUHKGg_JbIX11os';
}
