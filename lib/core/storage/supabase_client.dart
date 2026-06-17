import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Lazy singleton wrapper around the Supabase client.
///
/// Init is deferred until first use so the app doesn't crash on startup
/// if Supabase isn't configured yet (we're in the middle of the gradual
/// Firebase -> Supabase migration).
///
/// To activate Supabase, add to .env:
///   SUPABASE_URL=https://yourproject.supabase.co
///   SUPABASE_ANON_KEY=eyJhbGc...
///   USE_SUPABASE=true
///
/// Then run the SQL in supabase/schema.sql via the Supabase dashboard.
class SupabaseClientWrapper {
  SupabaseClientWrapper._();

  static bool _initialized = false;
  static SupabaseClient? _client;

  /// True if Supabase env vars are present.
  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return url.isNotEmpty &&
        anonKey.isNotEmpty &&
        url.startsWith('https://');
  }

  /// True if the USE_SUPABASE feature flag is on AND Supabase is configured.
  static bool get isActive {
    return isConfigured && (dotenv.env['USE_SUPABASE'] == 'true');
  }

  /// The singleton client. Throws if not configured.
  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
          'Supabase not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env');
    }
    if (!_initialized) {
      _initialize();
    }
    return _client!;
  }

  static void _initialize() {
    try {
      Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        debug: dotenv.env['NODE_ENV'] != 'production',
      );
      _client = Supabase.instance.client;
      _initialized = true;
      AppLogger.info('Supabase client initialized');
    } catch (e, stack) {
      AppLogger.error('Supabase init failed', e, stack);
      // Don't rethrow — let the app continue with Firebase as fallback.
    }
  }
}
