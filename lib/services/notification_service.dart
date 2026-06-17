import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
class NotificationService {
  bool _initialized = false;
  Future<void> initialize() async { if (_initialized) return; _initialized = true; AppLogger.info('Notification service initialized'); }
}
