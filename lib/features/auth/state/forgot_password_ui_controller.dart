import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordUiState {
  final int currentStep;
  final bool isLoading;

  const ForgotPasswordUiState({
    required this.currentStep,
    required this.isLoading,
  });

  factory ForgotPasswordUiState.initial() =>
      const ForgotPasswordUiState(currentStep: 0, isLoading: false);

  ForgotPasswordUiState copyWith({int? currentStep, bool? isLoading}) {
    return ForgotPasswordUiState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ForgotPasswordUiController extends Notifier<ForgotPasswordUiState> {
  @override
  ForgotPasswordUiState build() => ForgotPasswordUiState.initial();

  void setLoading(bool v) => state = state.copyWith(isLoading: v);
  void setStep(int step) => state = state.copyWith(currentStep: step);
}

final forgotPasswordUiControllerProvider = NotifierProvider.autoDispose<
    ForgotPasswordUiController, ForgotPasswordUiState>(
  ForgotPasswordUiController.new,
);

