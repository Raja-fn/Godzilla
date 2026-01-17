import 'package:ai_health/features/home/pages/home_page.dart';
import 'package:ai_health/utils/utils/extensions/display_name_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_connector/health_connector.dart';
import 'dart:developer' as developer;
import '../bloc/permissions_bloc.dart';
import '../widgets/health_data_category_list_view.dart';
import '../widgets/permission_list_tile.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<PermissionsBloc>().add(const LoadHealthPermissions());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data Permissions'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<PermissionsBloc, PermissionsState>(
        listener: (context, state) {
          if (state is PermissionsRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Granted: ${state.grantedPermissions.length}, Denied: ${state.deniedPermissions.length}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Navigate to home after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
            });
          } else if (state is PermissionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PermissionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PermissionsLoaded) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search permissions...',
                    onChanged: (value) {
                      context.read<PermissionsBloc>().add(
                        SearchPermissions(value),
                      );
                    },
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.search),
                    ),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<PermissionsBloc>().add(
                              const SearchPermissions(''),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.select_all),
                          label: const Text('Select All'),
                          onPressed: () {
                            context.read<PermissionsBloc>().add(
                              const SelectAllPermissions(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                          onPressed: () {
                            context.read<PermissionsBloc>().add(
                              const ClearAllPermissions(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Permissions List
                Expanded(child: _buildDataTypePermissions(context, state)),

                // Request Permissions Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(
                        'Request ${state.selectedPermissions.length} Permission${state.selectedPermissions.length != 1 ? 's' : ''}',
                      ),
                      onPressed: state.selectedPermissions.isEmpty
                          ? null
                          : () {
                              developer.log(
                                'PermissionsPage: User tapped Request Permissions button with ${state.selectedPermissions.length} permissions',
                              );
                              developer.log(
                                'PermissionsPage: Selected permissions: ${state.selectedPermissions.map((p) => p.toString().split('.').last).toList()}',
                              );
                              context.read<PermissionsBloc>().add(
                                RequestSelectedPermissions(
                                  state.selectedPermissions,
                                ),
                              );
                              developer.log(
                                'PermissionsPage: RequestSelectedPermissions event added to BLoC',
                              );
                            },
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is PermissionsRequesting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: state.progress),
                  const SizedBox(height: 16),
                  Text(
                    'Requesting permissions...\n${state.processedPermissions}/${state.totalPermissions}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (state is PermissionsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      context.read<PermissionsBloc>().add(
                        const LoadHealthPermissions(),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDataTypePermissions(
    BuildContext context,
    PermissionsLoaded state,
  ) {
    final filteredPermissions = state.getFilteredPermissions();

    if (filteredPermissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No permissions found',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return HealthDataCategoryListView<HealthDataPermission>(
      groupedItems: filteredPermissions,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemSorter: (a, b) => a.toString().compareTo(b.toString()),
      itemBuilder: (context, permission) {
        return PermissionListTile(
          title: Text(permission.displayName),
          isSelected: state.isPermissionSelected(permission),
          permissionStatus: state.getPermissionStatus(permission),
          onChanged: (bool value) {
            context.read<PermissionsBloc>().add(
              TogglePermissionSelection(
                permission: permission,
                isSelected: value,
              ),
            );
          },
        );
      },
    );
  }
}
