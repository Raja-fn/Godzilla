import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_connector/health_connector.dart';
import 'package:health_connector/health_connector_internal.dart';
import 'dart:developer' as developer;

part 'permissions_event.dart';
part 'permissions_state.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final HealthConnector healthConnector;

  List<HealthDataPermission> allPermissions = [];
  List<HealthDataPermission> selectedPermissions = [];
  Map<HealthDataPermission, PermissionStatus> permissionStatuses = {};

  PermissionsBloc({required this.healthConnector})
    : super(const PermissionsInitial()) {
    on<LoadHealthPermissions>(_onLoadHealthPermissions);
    on<TogglePermissionSelection>(_onTogglePermissionSelection);
    on<RequestSelectedPermissions>(_onRequestSelectedPermissions);
    on<ClearAllPermissions>(_onClearAllPermissions);
    on<SelectAllPermissions>(_onSelectAllPermissions);
    on<SearchPermissions>(_onSearchPermissions);
  }

  /// Load all available health permissions from health connector
  Future<void> _onLoadHealthPermissions(
    LoadHealthPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    emit(const PermissionsLoading());

    try {
      developer.log('PermissionsBloc: Loading health permissions');

      // Get all permissions for the current platform
      final permissions = HealthDataType.values
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
        'PermissionsBloc: Found ${permissions.length} permissions for platform ${healthConnector.healthPlatform}',
      );

      allPermissions = permissions;

      // Group permissions by category
      final permissionsByCategory =
          <HealthDataTypeCategory, List<HealthDataPermission>>{};

      for (final permission in allPermissions) {
        final category = permission.dataType.category;
        permissionsByCategory.putIfAbsent(category, () => []).add(permission);
      }

      // Get current permission statuses
      final statuses = <HealthDataPermission, PermissionStatus>{};
      for (final permission in allPermissions) {
        try {
          final status = await healthConnector.getPermissionStatus(permission);
          statuses[permission] = status;
          developer.log(
            'PermissionsBloc: Permission $permission status: $status',
          );
        } catch (e) {
          developer.log(
            'PermissionsBloc: Error checking permission status: $e',
            error: e,
          );
          // Default status if error
          statuses[permission] = PermissionStatus.denied;
        }
      }

      permissionStatuses = statuses;

      emit(
        PermissionsLoaded(
          permissionsByCategory: permissionsByCategory,
          selectedPermissions: selectedPermissions,
          permissionStatuses: permissionStatuses,
        ),
      );

      developer.log('PermissionsBloc: Permissions loaded successfully');
    } catch (e) {
      developer.log('PermissionsBloc: Error loading permissions: $e', error: e);
      emit(PermissionsError('Failed to load permissions: $e'));
    }
  }

  /// Toggle selection of a specific permission
  Future<void> _onTogglePermissionSelection(
    TogglePermissionSelection event,
    Emitter<PermissionsState> emit,
  ) async {
    developer.log(
      'PermissionsBloc: Toggling permission ${event.permission}, selected: ${event.isSelected}',
    );

    if (event.isSelected) {
      if (!selectedPermissions.contains(event.permission)) {
        selectedPermissions.add(event.permission);
      }
    } else {
      selectedPermissions.remove(event.permission);
    }

    if (state is PermissionsLoaded) {
      final currentState = state as PermissionsLoaded;
      emit(
        PermissionsLoaded(
          permissionsByCategory: currentState.permissionsByCategory,
          selectedPermissions: selectedPermissions,
          searchQuery: currentState.searchQuery,
          permissionStatuses: permissionStatuses,
        ),
      );
    }
  }

  /// Request the selected permissions from the system
  Future<void> _onRequestSelectedPermissions(
    RequestSelectedPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    developer.log(
      'PermissionsBloc: Requesting ${event.permissions.length} permissions',
    );

    try {
      emit(
        PermissionsRequesting(
          totalPermissions: event.permissions.length,
          processedPermissions: 0,
        ),
      );

      // Request permissions from health connector (opens Health Connect app)
      developer.log(
        'PermissionsBloc: Calling healthConnector.requestPermissions() - This will open Health Connect app',
      );
      await healthConnector.requestPermissions(event.permissions);
      developer.log(
        'PermissionsBloc: Permission request completed, Health Connect app returned',
      );

      final grantedPermissions = <HealthDataPermission, PermissionStatus>{};
      final deniedPermissions = <HealthDataPermission>[];

      // Check the status of each permission after the request
      for (int i = 0; i < event.permissions.length; i++) {
        final permission = event.permissions[i];

        try {
          developer.log(
            'PermissionsBloc: Checking status of permission $permission',
          );

          // Get the current status after request
          final status = await healthConnector.getPermissionStatus(permission);
          permissionStatuses[permission] = status;

          developer.log(
            'PermissionsBloc: Permission $permission status after request: $status',
          );

          if (status == PermissionStatus.granted) {
            grantedPermissions[permission] = status;
          } else {
            deniedPermissions.add(permission);
          }
        } catch (e) {
          developer.log(
            'PermissionsBloc: Error checking permission $permission status: $e',
            error: e,
          );
          deniedPermissions.add(permission);
        }

        // Update progress
        emit(
          PermissionsRequesting(
            totalPermissions: event.permissions.length,
            processedPermissions: i + 1,
          ),
        );
      }

      emit(
        PermissionsRequestSuccess(
          grantedPermissions: grantedPermissions,
          deniedPermissions: deniedPermissions,
        ),
      );

      developer.log(
        'PermissionsBloc: Request complete - Granted: ${grantedPermissions.length}, Denied: ${deniedPermissions.length}',
      );
    } catch (e) {
      developer.log(
        'PermissionsBloc: Error requesting permissions: $e',
        error: e,
      );
      emit(PermissionsError('Failed to request permissions: $e'));
    }
  }

  /// Clear all selected permissions
  Future<void> _onClearAllPermissions(
    ClearAllPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    developer.log('PermissionsBloc: Clearing all selected permissions');

    selectedPermissions.clear();

    if (state is PermissionsLoaded) {
      final currentState = state as PermissionsLoaded;
      emit(
        PermissionsLoaded(
          permissionsByCategory: currentState.permissionsByCategory,
          selectedPermissions: selectedPermissions,
          searchQuery: currentState.searchQuery,
          permissionStatuses: permissionStatuses,
        ),
      );
    }
  }

  /// Select all available permissions
  Future<void> _onSelectAllPermissions(
    SelectAllPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    developer.log('PermissionsBloc: Selecting all available permissions');

    selectedPermissions = List.from(allPermissions);

    if (state is PermissionsLoaded) {
      final currentState = state as PermissionsLoaded;
      emit(
        PermissionsLoaded(
          permissionsByCategory: currentState.permissionsByCategory,
          selectedPermissions: selectedPermissions,
          searchQuery: currentState.searchQuery,
          permissionStatuses: permissionStatuses,
        ),
      );
    }
  }

  /// Search permissions by query
  Future<void> _onSearchPermissions(
    SearchPermissions event,
    Emitter<PermissionsState> emit,
  ) async {
    developer.log(
      'PermissionsBloc: Searching permissions with query: "${event.query}"',
    );

    if (state is PermissionsLoaded) {
      final currentState = state as PermissionsLoaded;
      emit(
        PermissionsLoaded(
          permissionsByCategory: currentState.permissionsByCategory,
          selectedPermissions: selectedPermissions,
          searchQuery: event.query,
          permissionStatuses: permissionStatuses,
        ),
      );
    }
  }
}
