import 'package:ai_health/features/auth/pages/login_page.dart';
import 'package:ai_health/features/form/pages/form_page.dart';
import 'package:ai_health/features/home/pages/home_page.dart';
import 'package:ai_health/utils/toast_shadcn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart' as auth_bloc;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate Name
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Name is required';
      });
      isValid = false;
    } else if (name.length < 2) {
      setState(() {
        _nameError = 'Name must be at least 2 characters';
      });
      isValid = false;
    }

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

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Please confirm password';
      });
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      isValid = false;
    }

    return isValid;
  }

  void _handleSignUp() {
    if (!_validateInputs()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.read<auth_bloc.AuthBloc>().add(
      auth_bloc.AuthSignUpWithEmail(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  void _showErrorDialog(String message) {
    print('🔴 _showErrorDialog called with: $message');

    String helpText = '';

    // Provide helpful hints for common errors
    if (message.toLowerCase().contains('already registered')) {
      helpText =
          '\n\nThis email is already registered. Please try logging in instead.';
    } else if (message.toLowerCase().contains('weak password')) {
      helpText =
          '\n\nPlease use a stronger password (at least 8 characters recommended).';
    } else if (message.toLowerCase().contains('invalid email')) {
      helpText = '\n\nPlease enter a valid email address.';
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
        title: const Text('Signup Error'),
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Please verify your email before logging in. Check your inbox for the verification link.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BlocListener<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      listenWhen: (previous, current) {
        print(
          '🔴 SignupPage BlocListener: Previous: ${previous.runtimeType}, Current: ${current.runtimeType}',
        );
        return current is auth_bloc.AuthError ||
            current is auth_bloc.AuthAuthenticated;
      },
      listener: (context, state) {
        print(
          '🔴 SignupPage listener triggered with state: ${state.runtimeType}',
        );
        if (state is auth_bloc.AuthError) {
          print('🔴 SignupPage: Got AuthError - ${state.message}');
          _showErrorDialog(state.message);
        } else if (state is auth_bloc.AuthAuthenticated) {
          print('🔴 SignupPage: Got AuthAuthenticated');
          //   _showSuccessDialog(); [TODO] Uncommetn when email validate
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => FormPage()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ),
        body: BlocBuilder<auth_bloc.AuthBloc, auth_bloc.AuthState>(
          builder: (context, state) {
            bool isLoading = state is auth_bloc.AuthLoading;

            return SafeArea(
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
                              'Create Account',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign up to get started',
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

                        // Name Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Full Name',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                errorText: _nameError,
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
                              keyboardType: TextInputType.name,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                                  color: Theme.of(context).colorScheme.outline,
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
                                hintText: 'Create a password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline,
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
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Password',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confirmPasswordController,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                hintText: 'Confirm your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: !isLoading
                                      ? () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        }
                                      : null,
                                  child: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                errorText: _confirmPasswordError,
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
                              obscureText: _obscureConfirmPassword,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Sign Up Button
                        FilledButton(
                          onPressed: isLoading ? null : _handleSignUp,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                        const SizedBox(height: 24),
                        if (state is auth_bloc.AuthError)
                          Center(
                            child: Text(
                              state.message,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        // Sign In Link
                        Center(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
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
            );
          },
        ),
      ),
    );
  }
}
