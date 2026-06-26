import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateAccountUiState {
  final String selectedAccountType;
  final bool isLoading;

  const CreateAccountUiState({
    required this.selectedAccountType,
    required this.isLoading,
  });

  factory CreateAccountUiState.initial() => const CreateAccountUiState(
        selectedAccountType: 'Customer',
        isLoading: false,
      );

  CreateAccountUiState copyWith({
    String? selectedAccountType,
    bool? isLoading,
  }) {
    return CreateAccountUiState(
      selectedAccountType: selectedAccountType ?? this.selectedAccountType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreateAccountUiController extends Notifier<CreateAccountUiState> {
  @override
  CreateAccountUiState build() => CreateAccountUiState.initial();

  void selectAccountType(String v) =>
      state = state.copyWith(selectedAccountType: v);

  void setLoading(bool v) => state = state.copyWith(isLoading: v);
}

final createAccountUiControllerProvider = NotifierProvider.autoDispose<
    CreateAccountUiController, CreateAccountUiState>(
  CreateAccountUiController.new,
);

