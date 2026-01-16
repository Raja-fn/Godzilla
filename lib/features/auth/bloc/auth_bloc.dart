import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient supabase;
  late final StreamSubscription _authStateSubscription;
  bool _isProcessingLogin = false;
  bool _isProcessingSignup = false;

  AuthBloc({required this.supabase}) : super(AuthInitial()) {
    // Listen to Supabase auth changes
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      print('🔐 Auth state changed: ${event.name}');

      // Only auto-check status for token refresh and sign out
      // Login/signup are handled explicitly in their handlers
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.signedOut) {
        print('🔐 Auto-triggering AuthCheckStatus for: ${event.name}');
        add(AuthCheckStatus());
      } else if (event == AuthChangeEvent.signedIn) {
        // For sign-in, only auto-check if we're not already processing login/signup
        if (!_isProcessingLogin && !_isProcessingSignup) {
          print('🔐 Auto-triggering AuthCheckStatus for signedIn');
          add(AuthCheckStatus());
        } else {
          print('🔐 Skipping auto-check during login/signup processing');
        }
      }
    });

    on<AuthCheckStatus>(_onAuthCheckStatus);
    on<AuthSignOut>(_onAuthSignOut);
    on<AuthLoginWithEmail>(_onAuthLoginWithEmail);
    on<AuthSignUpWithEmail>(_onAuthSignUpWithEmail);

    // Manually add initial check to establish current status
    add(AuthCheckStatus());
  }

  Future<void> _onAuthCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 _onAuthCheckStatus: Checking current session');
    emit(AuthLoading());
    try {
      final Session? session = supabase.auth.currentSession;
      final User? user = session?.user;

      if (user != null) {
        print('✅ _onAuthCheckStatus: User authenticated: ${user.email}');
        emit(AuthAuthenticated(user));
      } else {
        print('❌ _onAuthCheckStatus: No user session found');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ _onAuthCheckStatus: Error - $e');
      emit(AuthError("Failed to check session status: $e"));
    }
  }

  Future<void> _onAuthLoginWithEmail(
    AuthLoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 _onAuthLoginWithEmail: Attempting login with ${event.email}');
    _isProcessingLogin = true;
    emit(AuthLoading());
    try {
      print('🔐 _onAuthLoginWithEmail: Calling signInWithPassword');
      final response = await supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        print(
          '✅ _onAuthLoginWithEmail: Login successful for ${response.user?.email}',
        );
        emit(AuthAuthenticated(response.user!));
      } else {
        print('❌ _onAuthLoginWithEmail: User is null in response');
        emit(const AuthError("Login failed"));
      }
    } on AuthException catch (e) {
      print('❌ _onAuthLoginWithEmail: AuthException - ${e.message}');
      emit(AuthError(e.message));
    } catch (e) {
      print('❌ _onAuthLoginWithEmail: Exception - $e');
      emit(AuthError("Login error: $e"));
    } finally {
      _isProcessingLogin = false;
    }
  }

  Future<void> _onAuthSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 _onAuthSignUpWithEmail: Attempting signup with ${event.email}');
    _isProcessingSignup = true;
    emit(AuthLoading());
    try {
      print('🔐 _onAuthSignUpWithEmail: Calling signUp');
      final response = await supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        print(
          '✅ _onAuthSignUpWithEmail: Signup successful for ${response.user?.email}',
        );
        emit(AuthAuthenticated(response.user!));
      } else {
        print('❌ _onAuthSignUpWithEmail: User is null in response');
        emit(const AuthError("Sign up failed"));
      }
    } on AuthException catch (e) {
      print('❌ _onAuthSignUpWithEmail: AuthException - ${e.message}');
      emit(AuthError(e.message));
    } catch (e) {
      print('❌ _onAuthSignUpWithEmail: Exception - $e');
      emit(AuthError("Sign up error: $e"));
    } finally {
      _isProcessingSignup = false;
    }
  }

  Future<void> _onAuthSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 _onAuthSignOut: Signing out user');
    emit(AuthLoading());
    try {
      await supabase.auth.signOut();
      print('✅ _onAuthSignOut: Sign out successful');
      // signOut will trigger onAuthStateChange, which will call AuthCheckStatus,
      // but we emit Unauthenticated immediately for responsiveness.
      emit(AuthUnauthenticated());
    } catch (e) {
      print('❌ _onAuthSignOut: Error - $e');
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
