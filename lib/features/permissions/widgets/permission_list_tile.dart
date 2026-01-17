import 'package:flutter/material.dart';
import 'package:health_connector/health_connector.dart';

class PermissionListTile extends StatelessWidget {
  final Widget title;
  final bool isSelected;
  final PermissionStatus? permissionStatus;
  final ValueChanged<bool> onChanged;
  final String? description;

  const PermissionListTile({
    required this.title,
    required this.isSelected,
    required this.onChanged,
    this.permissionStatus,
    this.description,
    super.key,
  });

  /// Get the color based on permission status
  Color _getStatusColor(BuildContext context) {
    switch (permissionStatus) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get the status icon based on permission status
  IconData _getStatusIcon() {
    switch (permissionStatus) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Get the status text based on permission status
  String _getStatusText() {
    switch (permissionStatus) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        title: title,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
            if (permissionStatus != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        dense: false,
      ),
    );
  }
}
