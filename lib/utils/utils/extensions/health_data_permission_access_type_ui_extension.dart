import 'package:health_connector/health_connector_internal.dart'
    show HealthDataPermissionAccessType;
import 'package:ai_health/utils/constants/app_texts.dart';

/// Extension to provide UI-related properties.
extension HealthDataPermissionAccessTypeUI on HealthDataPermissionAccessType {
  /// Returns the display name for this access type.
  String get displayName {
    return switch (this) {
      HealthDataPermissionAccessType.read => AppTexts.read,
      HealthDataPermissionAccessType.write => AppTexts.write,
    };
  }
}
