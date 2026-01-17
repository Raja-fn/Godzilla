part of 'permissions_bloc.dart';

abstract class PermissionsEvent extends Equatable {
  const PermissionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthPermissions extends PermissionsEvent {
  const LoadHealthPermissions();
}

class TogglePermissionSelection extends PermissionsEvent {
  final HealthDataPermission permission;
  final bool isSelected;

  const TogglePermissionSelection({
    required this.permission,
    required this.isSelected,
  });

  @override
  List<Object?> get props => [permission, isSelected];
}

class RequestSelectedPermissions extends PermissionsEvent {
  final List<HealthDataPermission> permissions;

  const RequestSelectedPermissions(this.permissions);

  @override
  List<Object?> get props => [permissions];
}

class ClearAllPermissions extends PermissionsEvent {
  const ClearAllPermissions();
}

class SelectAllPermissions extends PermissionsEvent {
  const SelectAllPermissions();
}

class SearchPermissions extends PermissionsEvent {
  final String query;

  const SearchPermissions(this.query);

  @override
  List<Object?> get props => [query];
}
