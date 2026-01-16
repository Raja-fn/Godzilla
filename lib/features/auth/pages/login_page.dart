import 'package:ai_health/features/auth/pages/signup_page.dart';
import 'package:ai_health/features/home/pages/home_page.dart';
import 'package:ai_health/utils/toast_shadcn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart' as auth_bloc;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      isValid = false;
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      isValid = false;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters';
      });
      isValid = false;
    }

    return isValid;
  }

  void _handleLogin() {
    if (!_validateInputs()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    print('🔐 LoginPage: Submitting login for $email');
    context.read<auth_bloc.AuthBloc>().add(
      auth_bloc.AuthLoginWithEmail(email: email, password: password),
    );
  }

  void _showErrorDialog(String message) {
    print('🔴 _showErrorDialog called with: $message');

    String helpText = '';

    // Provide helpful hints for common errors
    if (message.toLowerCase().contains('email not confirmed')) {
      helpText =
          '\n\nPlease check your email for a confirmation link. If you don\'t see it, try signing up again.';
    } else if (message.toLowerCase().contains('invalid login')) {
      helpText = '\n\nIncorrect email or password. Please try again.';
    } else if (message.toLowerCase().contains('user not found')) {
      helpText = '\n\nNo account found with this email. Please sign up first.';
    }

    // Dismiss any loading dialogs first
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      print('🔴 Dismissing route: ${route.toString()}');
      return route.isFirst;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login Error'),
        content: SingleChildScrollView(child: Text(message + helpText)),
        actions: [
          TextButton(
            onPressed: () {
              print('🔴 Closing error dialog');
              Navigator.of(dialogContext).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      print('🔴 Error dialog dismissed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BlocListener<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      listenWhen: (previous, current) {
        print(
          '🔴 LoginPage BlocListener: Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
        );
        return current is auth_bloc.AuthError ||
            current is auth_bloc.AuthAuthenticated;
      },
      listener: (context, state) {
        print(
          '🔴 LoginPage listener triggered with state: ${state.runtimeType}',
        );
        if (state is auth_bloc.AuthError) {
          print('🔴 LoginPage: Got AuthError - ${state.message}');
          _showErrorDialog(state.message);
        } else if (state is auth_bloc.AuthAuthenticated) {
          print('🔴 LoginPage: Got AuthAuthenticated');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<auth_bloc.AuthBloc, auth_bloc.AuthState>(
          buildWhen: (previous, current) {
            print(
              '🔴 LoginPage BlocBuilder: Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
            );
            return true;
          },
          builder: (context, state) {
            bool isLoading = state is auth_bloc.AuthLoading;
            print(
              '🔴 LoginPage BlocBuilder building with isLoading: $isLoading',
            );

            return Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 20 : 40),
                      child: SizedBox(
                        width: isMobile ? double.infinity : 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Column(
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your account',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(
                                      Icons.mail_outline,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    errorText: _emailError,
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordController,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: !isLoading
                                          ? () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            }
                                          : null,
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                    ),
                                    errorText: _passwordError,
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Sign In Button
                            FilledButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                            const SizedBox(height: 24),

                            if (state is auth_bloc.AuthError)
                              Center(
                                child: Text(
                                  state.message,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),

                            // Sign Up Link
                            Center(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupPage(),
                                          ),
                                        );
                                      },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
