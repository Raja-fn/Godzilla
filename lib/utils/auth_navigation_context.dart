import 'package:flutter/material.dart';

enum AuthPage { login, signup }

class AuthNavigationContext extends InheritedWidget {
  final AuthPage currentPage;
  final Function(AuthPage) onPageChange;

  const AuthNavigationContext({
    super.key,
    required this.currentPage,
    required this.onPageChange,
    required super.child,
  });

  static AuthNavigationContext of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<AuthNavigationContext>();
    assert(result != null, 'No AuthNavigationContext found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AuthNavigationContext oldWidget) {
    return oldWidget.currentPage != currentPage;
  }
}
