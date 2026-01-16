part of 'permissions_bloc.dart';

abstract class PermissionsEvent extends Equatable {
  const PermissionsEvent();

  @override
  List<Object> get props => [];
}

class RequestHealthPermissions extends PermissionsEvent {
  final List<Permission> permissions;

  const RequestHealthPermissions(this.permissions);

  @override
  List<Object> get props => [permissions];
}
