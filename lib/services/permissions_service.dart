import 'package:health_connector/health_connector.dart';
import 'dart:developer' as developer;

class PermissionsService {
  final HealthConnector healthConnector;

  PermissionsService({required this.healthConnector});

  /// Check if all available permissions are granted
  /// Returns true if all permissions are granted, false otherwise
  Future<bool> areAllPermissionsGranted() async {
    try {
      developer.log(
        'PermissionsService.areAllPermissionsGranted - Checking all permissions',
      );

      // Get all permissions for the current platform
      final allPermissions = HealthDataType.values
          .expand(
            (dataType) =>
                dataType.permissions.whereType<HealthDataPermission>(),
          )
          .where(
            (permission) => permission.supportedHealthPlatforms.contains(
              healthConnector.healthPlatform,
            ),
          )
          .toList();

      developer.log(
        'PermissionsService.areAllPermissionsGranted - Found ${allPermissions.length} permissions to check',
      );

      if (allPermissions.isEmpty) {
        developer.log(
          'PermissionsService.areAllPermissionsGranted - No permissions available',
        );
        return true; // No permissions to grant
      }

      // Check each permission
      int grantedCount = 0;
      for (final permission in allPermissions) {
        try {
          final status = await healthConnector.getPermissionStatus(permission);
          developer.log(
            'PermissionsService.areAllPermissionsGranted - Permission $permission status: $status',
          );

          if (status == PermissionStatus.granted) {
            grantedCount++;
          }
        } catch (e) {
          developer.log(
            'PermissionsService.areAllPermissionsGranted - Error checking permission: $e',
            error: e,
          );
          // If we can't check the permission, consider it not granted
        }
      }

      final allGranted = grantedCount == allPermissions.length;
      developer.log(
        'PermissionsService.areAllPermissionsGranted - All granted: $allGranted ($grantedCount/${allPermissions.length})',
      );

      return allGranted;
    } catch (e) {
      developer.log(
        'PermissionsService.areAllPermissionsGranted - Error: $e',
        error: e,
      );
      return false;
    }
  }

  /// Get count of granted permissions
  /// Returns a map with total and granted count
  Future<Map<String, int>> getPermissionStats() async {
    try {
      developer.log(
        'PermissionsService.getPermissionStats - Getting permission statistics',
      );

      // Get all permissions for the current platform
      final allPermissions = HealthDataType.values
          .expand(
            (dataType) =>
                dataType.permissions.whereType<HealthDataPermission>(),
          )
          .where(
            (permission) => permission.supportedHealthPlatforms.contains(
              healthConnector.healthPlatform,
            ),
          )
          .toList();

      int grantedCount = 0;
      int deniedCount = 0;
      int pendingCount = 0;

      for (final permission in allPermissions) {
        try {
          final status = await healthConnector.getPermissionStatus(permission);

          if (status == PermissionStatus.granted) {
            grantedCount++;
          } else if (status == PermissionStatus.denied) {
            deniedCount++;
          } else {
            pendingCount++;
          }
        } catch (e) {
          developer.log(
            'PermissionsService.getPermissionStats - Error checking permission: $e',
            error: e,
          );
          pendingCount++;
        }
      }

      final stats = {
        'total': allPermissions.length,
        'granted': grantedCount,
        'denied': deniedCount,
        'pending': pendingCount,
      };

      developer.log('PermissionsService.getPermissionStats - Stats: $stats');

      return stats;
    } catch (e) {
      developer.log(
        'PermissionsService.getPermissionStats - Error: $e',
        error: e,
      );
      return {'total': 0, 'granted': 0, 'denied': 0, 'pending': 0};
    }
  }
}
