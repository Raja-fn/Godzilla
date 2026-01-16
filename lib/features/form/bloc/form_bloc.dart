import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_health/features/form/repo/form_repository.dart';
import 'package:ai_health/features/form/models/survey_model.dart';

part 'form_event.dart';
part 'form_state.dart';

class FormBloc extends Bloc<FormEvent, AppFormState> {
  final FormRepository _formRepository;

  FormBloc({required FormRepository formRepository})
    : _formRepository = formRepository,
      super(FormInitial()) {
    // Profile Form Events
    on<LoadProfileQuestions>((event, emit) async {
      emit(FormLoading());
      try {
        final profileData = ProfileData.defaultQuestions();
        emit(ProfileFormState(questions: profileData.questions));
      } catch (e) {
        emit(FormFailure(e.toString()));
      }
    });

    on<ProfileAnswerChanged>((event, emit) {
      if (state is ProfileFormState) {
        final currentState = state as ProfileFormState;
        final updatedQuestions = currentState.questions.map((q) {
          if (q.id == event.questionId) {
            return q.copyWith(selectedAnswer: event.answer);
          }
          return q;
        }).toList();
        emit(ProfileFormState(questions: updatedQuestions));
      }
    });

    on<ProfileFormSubmitted>((event, emit) async {
      if (state is ProfileFormState) {
        final currentState = state as ProfileFormState;
        if (!currentState.isCompleted) {
          emit(const FormFailure('Please answer all questions'));
          return;
        }

        emit(FormLoading());
        try {
          // Convert questions to ProfileData
          final profileData = ProfileData(questions: currentState.questions);
          await _formRepository.saveProfileData(profileData);
          emit(FormSuccess());
        } catch (e) {
          emit(FormFailure(e.toString()));
        }
      }
    });

    on<CheckProfileCompletion>((event, emit) async {
      emit(FormLoading());
      try {
        final profileData = await _formRepository.getProfileData();
        final surveyData = await _formRepository.getSurveyData();

        if (profileData != null && surveyData != null) {
          emit(AllDataCompleted());
        } else if (profileData != null) {
          emit(ProfileAlreadyCompleted());
        } else {
          final defaultProfile = ProfileData.defaultQuestions();
          emit(ProfileFormState(questions: defaultProfile.questions));
        }
      } catch (e) {
        emit(FormFailure(e.toString()));
      }
    });

    // Survey Events
    on<LoadSurvey>((event, emit) async {
      emit(SurveyLoading());
      try {
        final surveyQuestions = await _formRepository.getSurveyQuestions();
        emit(
          SurveyDataState(
            questions: surveyQuestions,
            selectedAnswers: List<String?>.filled(surveyQuestions.length, null),
          ),
        );
      } catch (e) {
        emit(FormFailure(e.toString()));
      }
    });

    on<SurveyAnswerChanged>((event, emit) {
      if (state is SurveyDataState) {
        final currentState = state as SurveyDataState;
        final updatedAnswers = List<String?>.from(currentState.selectedAnswers);
        if (event.questionId < updatedAnswers.length) {
          updatedAnswers[event.questionId] = event.answer;
        }
        emit(currentState.copyWith(selectedAnswers: updatedAnswers));
      }
    });

    on<SurveySubmitted>((event, emit) async {
      if (state is SurveyDataState) {
        final currentState = state as SurveyDataState;
        if (!currentState.isCompleted) {
          emit(const FormFailure('Please answer all questions'));
          return;
        }

        emit(SurveyLoading());
        try {
          await _formRepository.saveSurveyData(currentState.selectedAnswers);
          emit(SurveySuccess());
        } catch (e) {
          emit(FormFailure(e.toString()));
        }
      }
    });

    on<CheckSurveyCompletion>((event, emit) async {
      emit(SurveyLoading());
      try {
        final surveyData = await _formRepository.getSurveyData();
        if (surveyData != null) {
          emit(ProfileAlreadyCompleted());
        } else {
          final surveyQuestions = await _formRepository.getSurveyQuestions();
          emit(
            SurveyDataState(
              questions: surveyQuestions,
              selectedAnswers: List<String?>.filled(
                surveyQuestions.length,
                null,
              ),
            ),
          );
        }
      } catch (e) {
        emit(FormFailure(e.toString()));
      }
    });
  }
}
