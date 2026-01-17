part of 'form_bloc.dart';

abstract class FormEvent extends Equatable {
  const FormEvent();

  @override
  List<Object?> get props => [];
}

// Profile Form Events
class LoadProfileQuestions extends FormEvent {}

class ProfileAnswerChanged extends FormEvent {
  final int questionId;
  final String answer;

  const ProfileAnswerChanged(this.questionId, this.answer);

  @override
  List<Object> get props => [questionId, answer];
}

class ProfileFormSubmitted extends FormEvent {}

class CheckProfileCompletion extends FormEvent {}

// Survey Events
class LoadSurvey extends FormEvent {}

class SurveyAnswerChanged extends FormEvent {
  final int questionId;
  final String answer;

  const SurveyAnswerChanged(this.questionId, this.answer);

  @override
  List<Object> get props => [questionId, answer];
}

class SurveySubmitted extends FormEvent {}

class CheckSurveyCompletion extends FormEvent {}

// Deprecated events (kept for backward compatibility)
class NameChanged extends FormEvent {
  final String name;
  const NameChanged(this.name);
  @override
  List<Object> get props => [name];
}

class AgeChanged extends FormEvent {
  final int age;
  const AgeChanged(this.age);
  @override
  List<Object> get props => [age];
}

class HeightChanged extends FormEvent {
  final double height;
  const HeightChanged(this.height);
  @override
  List<Object> get props => [height];
}

class WeightChanged extends FormEvent {
  final double weight;
  const WeightChanged(this.weight);
  @override
  List<Object> get props => [weight];
}

class BodyTypeChanged extends FormEvent {
  final String bodyType;
  const BodyTypeChanged(this.bodyType);
  @override
  List<Object> get props => [bodyType];
}

class FormSubmitted extends FormEvent {}

class CheckFormCompletion extends FormEvent {}
