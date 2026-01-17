import 'package:ai_health/utils/utils/extensions/health_data_permission_access_type_ui_extension.dart';
import 'package:ai_health/utils/utils/extensions/health_data_type_ui_extension.dart';
import 'package:health_connector/health_connector_internal.dart'
    show HealthDataPermission;
import 'package:ai_health/utils/constants/app_texts.dart';

/// Extension on [HealthDataPermission] to provide UI-related properties.
extension HealthDataPermissionUI on HealthDataPermission {
  /// Returns the display name for this permission.
  ///
  /// Combines the data type display name with the access type.
  String get displayName {
    return '${dataType.displayName} - ${accessType.displayName}';
  }
}
