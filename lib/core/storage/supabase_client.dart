import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Lazy singleton wrapper around the Supabase client.
///
/// NOTE: supabase_flutter was removed from pubspec because it pulled in
/// passkeys_web, which crashed Chrome on startup. This wrapper is now
/// a stub — it logs a warning when accessed. When we actually migrate
/// to Supabase in Phase 3, we'll either:
///   (a) Re-add supabase_flutter and properly include the passkeys
///       bundle.js in web/index.html, OR
///   (b) Use the lower-level `supabase` package and skip passkeys.
class SupabaseClientWrapper {
  SupabaseClientWrapper._();

  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return url.isNotEmpty &&
        anonKey.isNotEmpty &&
        url.startsWith('https://');
  }

  static bool get isActive {
    return isConfigured && (dotenv.env['USE_SUPABASE'] == 'true');
  }

  /// Throws — Supabase is not currently wired up.
  static dynamic get client {
    AppLogger.error(
        'Supabase client accessed but supabase_flutter is not in pubspec. '
        'Re-add it (and configure passkeys bundle.js) to enable.');
    throw StateError(
        'Supabase not configured. Re-add supabase_flutter to pubspec.yaml '
        'and configure passkeys bundle.js in web/index.html to enable.');
  }
}
