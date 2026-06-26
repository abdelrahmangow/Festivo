import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginUiState {
  final bool obscurePassword;
  final bool isLoading;
  final String selectedRole;

  const LoginUiState({
    required this.obscurePassword,
    required this.isLoading,
    required this.selectedRole,
  });

  factory LoginUiState.initial() => const LoginUiState(
        obscurePassword: true,
        isLoading: false,
        selectedRole: 'Customer',
      );

  LoginUiState copyWith({
    bool? obscurePassword,
    bool? isLoading,
    String? selectedRole,
  }) {
    return LoginUiState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class LoginUiController extends Notifier<LoginUiState> {
  @override
  LoginUiState build() => LoginUiState.initial();

  void setLoading(bool v) => state = state.copyWith(isLoading: v);

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  void selectRole(String role) => state = state.copyWith(selectedRole: role);
}

final loginUiControllerProvider =
    NotifierProvider.autoDispose<LoginUiController, LoginUiState>(
  LoginUiController.new,
);

