part of 'permissions_bloc.dart';

abstract class PermissionsState extends Equatable {
  const PermissionsState();

  @override
  List<Object?> get props => [];
}

class PermissionsInitial extends PermissionsState {
  const PermissionsInitial();
}

class PermissionsLoading extends PermissionsState {
  const PermissionsLoading();
}

class PermissionsLoaded extends PermissionsState {
  final Map<HealthDataTypeCategory, List<HealthDataPermission>>
  permissionsByCategory;
  final List<HealthDataPermission> selectedPermissions;
  final String searchQuery;
  final Map<HealthDataPermission, PermissionStatus> permissionStatuses;

  const PermissionsLoaded({
    required this.permissionsByCategory,
    required this.selectedPermissions,
    this.searchQuery = '',
    required this.permissionStatuses,
  });

  /// Get filtered permissions based on search query
  Map<HealthDataTypeCategory, List<HealthDataPermission>>
  getFilteredPermissions() {
    if (searchQuery.isEmpty) {
      return permissionsByCategory;
    }

    final filtered = <HealthDataTypeCategory, List<HealthDataPermission>>{};
    permissionsByCategory.forEach((category, permissions) {
      final filteredPerms = permissions
          .where(
            (p) =>
                p.toString().toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
      if (filteredPerms.isNotEmpty) {
        filtered[category] = filteredPerms;
      }
    });
    return filtered;
  }

  /// Check if a permission is selected
  bool isPermissionSelected(HealthDataPermission permission) {
    return selectedPermissions.contains(permission);
  }

  /// Get the status of a specific permission
  PermissionStatus? getPermissionStatus(HealthDataPermission permission) {
    return permissionStatuses[permission];
  }

  @override
  List<Object?> get props => [
    permissionsByCategory,
    selectedPermissions,
    searchQuery,
    permissionStatuses,
  ];
}

class PermissionsRequesting extends PermissionsState {
  final int totalPermissions;
  final int processedPermissions;

  const PermissionsRequesting({
    required this.totalPermissions,
    required this.processedPermissions,
  });

  double get progress =>
      totalPermissions > 0 ? processedPermissions / totalPermissions : 0;

  @override
  List<Object?> get props => [totalPermissions, processedPermissions];
}

class PermissionsRequestSuccess extends PermissionsState {
  final Map<HealthDataPermission, PermissionStatus> grantedPermissions;
  final List<HealthDataPermission> deniedPermissions;

  const PermissionsRequestSuccess({
    required this.grantedPermissions,
    required this.deniedPermissions,
  });

  @override
  List<Object?> get props => [grantedPermissions, deniedPermissions];
}

class PermissionsError extends PermissionsState {
  final String message;
  final String? code;

  const PermissionsError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
