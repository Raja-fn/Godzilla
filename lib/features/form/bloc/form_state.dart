part of 'form_bloc.dart';

abstract class AppFormState extends Equatable {
  const AppFormState();

  @override
  List<Object?> get props => [];
}

class FormInitial extends AppFormState {}

class FormLoading extends AppFormState {}

class FormSuccess extends AppFormState {}

class ProfileFormState extends AppFormState {
  final List<ProfileQuestion> questions;

  const ProfileFormState({this.questions = const []});

  bool get isCompleted {
    return questions.isNotEmpty &&
        questions.every((q) {
          if (q.inputType == 'number') {
            return q.selectedAnswer != null && q.selectedAnswer!.isNotEmpty;
          }
          return q.selectedAnswer != null && q.selectedAnswer!.isNotEmpty;
        });
  }

  ProfileFormState copyWith({List<ProfileQuestion>? questions}) {
    return ProfileFormState(questions: questions ?? this.questions);
  }

  ProfileFormState updateAnswer(int questionId, String answer) {
    final updatedQuestions = questions.map((q) {
      if (q.id == questionId) {
        return q.copyWith(selectedAnswer: answer);
      }
      return q;
    }).toList();

    return ProfileFormState(questions: updatedQuestions);
  }

  @override
  List<Object> get props => [questions];
}

class SurveyLoading extends AppFormState {}

class SurveySuccess extends AppFormState {}

class ProfileAlreadyCompleted extends AppFormState {}

class AllDataCompleted extends AppFormState {}

class FormFailure extends AppFormState {
  final String error;

  const FormFailure(this.error);

  @override
  List<Object> get props => [error];
}

class SurveyDataState extends AppFormState {
  final List<Map<String, dynamic>> questions;
  final List<String?> selectedAnswers;

  const SurveyDataState({
    this.questions = const [],
    this.selectedAnswers = const [],
  });

  SurveyDataState copyWith({
    List<Map<String, dynamic>>? questions,
    List<String?>? selectedAnswers,
  }) {
    return SurveyDataState(
      questions: questions ?? this.questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }

  bool get isCompleted {
    return questions.isNotEmpty &&
        selectedAnswers.isNotEmpty &&
        selectedAnswers.every((answer) => answer != null);
  }

  @override
  List<Object> get props => [questions, selectedAnswers];
}
