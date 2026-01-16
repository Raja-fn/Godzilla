import 'package:equatable/equatable.dart';

// ====================================================================
// PROFILE QUESTIONS MODEL (One-time / Rarely Updated)
// ====================================================================

class ProfileQuestion extends Equatable {
  final int id;
  final String question;
  final List<String> options;
  final String? selectedAnswer;
  final String? inputType; // 'radio', 'number', 'checkbox'
  final int? minValue;
  final int? maxValue;

  const ProfileQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.selectedAnswer,
    this.inputType = 'radio',
    this.minValue,
    this.maxValue,
  });

  ProfileQuestion copyWith({
    int? id,
    String? question,
    List<String>? options,
    String? selectedAnswer,
    String? inputType,
    int? minValue,
    int? maxValue,
  }) {
    return ProfileQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      inputType: inputType ?? this.inputType,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'selected_answer': selectedAnswer,
      'input_type': inputType,
    };
  }

  factory ProfileQuestion.fromMap(Map<String, dynamic> map) {
    return ProfileQuestion(
      id: map['id'] ?? 0,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      selectedAnswer: map['selected_answer'],
      inputType: map['input_type'] ?? 'radio',
      minValue: map['min_value'],
      maxValue: map['max_value'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    question,
    options,
    selectedAnswer,
    inputType,
    minValue,
    maxValue,
  ];
}

class ProfileData extends Equatable {
  final List<ProfileQuestion> questions;

  const ProfileData({this.questions = const []});

  bool get isCompleted {
    return questions.isNotEmpty &&
        questions.every((q) {
          if (q.inputType == 'checkbox') {
            return q.selectedAnswer != null && q.selectedAnswer!.isNotEmpty;
          }
          return q.selectedAnswer != null && q.selectedAnswer!.isNotEmpty;
        });
  }

  ProfileData copyWith({List<ProfileQuestion>? questions}) {
    return ProfileData(questions: questions ?? this.questions);
  }

  ProfileData updateAnswer(int questionId, String answer) {
    final updatedQuestions = questions.map((q) {
      if (q.id == questionId) {
        return q.copyWith(selectedAnswer: answer);
      }
      return q;
    }).toList();

    return copyWith(questions: updatedQuestions);
  }

  Map<String, dynamic> toMap() {
    return {
      'age_group': _getAnswerByQuestionId(1),
      'biological_sex': _getAnswerByQuestionId(2),
      'height_cm': int.tryParse(_getAnswerByQuestionId(3) ?? ''),
      'weight_kg': double.tryParse(_getAnswerByQuestionId(4) ?? ''),
      'body_type': _getAnswerByQuestionId(5),
      'primary_health_goal': _getAnswerByQuestionId(6),
      'activity_level': _getAnswerByQuestionId(7),
      'dietary_preference': _getAnswerByQuestionId(8),
      'avg_sleep_duration': _getAnswerByQuestionId(9),
      'medical_conditions': _getAnswerByQuestionId(10)?.split(',') ?? [],
    };
  }

  String? _getAnswerByQuestionId(int questionId) {
    try {
      return questions.firstWhere((q) => q.id == questionId).selectedAnswer;
    } catch (e) {
      return null;
    }
  }

  // Predefined profile questions
  static ProfileData defaultQuestions() {
    return ProfileData(
      questions: [
        ProfileQuestion(
          id: 1,
          question: 'What is your age group?',
          options: ['Under 18', '18–24', '25–34', '35–44', '45–54', '55+'],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 2,
          question: 'What is your biological sex?',
          options: ['Male', 'Female', 'Prefer not to say'],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 3,
          question: 'What is your height? (cm)',
          options: [],
          inputType: 'number',
          minValue: 100,
          maxValue: 250,
        ),
        ProfileQuestion(
          id: 4,
          question: 'What is your weight? (kg)',
          options: [],
          inputType: 'number',
          minValue: 30,
          maxValue: 300,
        ),
        ProfileQuestion(
          id: 5,
          question: 'What is your body type?',
          options: [
            'Ectomorph (lean / skinny)',
            'Mesomorph (athletic / muscular)',
            'Endomorph (higher body fat)',
          ],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 6,
          question: 'What is your primary health goal?',
          options: [
            'Weight loss',
            'Muscle gain',
            'Maintain fitness',
            'Improve endurance',
            'General wellness',
          ],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 7,
          question: 'What is your activity level?',
          options: [
            'Sedentary (little or no exercise)',
            'Light (1–3 days/week)',
            'Moderate (3–5 days/week)',
            'Active (6–7 days/week)',
            'Very active (athlete / labor-intensive)',
          ],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 8,
          question: 'What is your dietary preference?',
          options: [
            'Vegetarian',
            'Vegan',
            'Eggetarian',
            'Non-vegetarian',
            'No specific preference',
          ],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 9,
          question: 'What is your average sleep duration?',
          options: [
            '< 5 hours',
            '5–6 hours',
            '6–7 hours',
            '7–8 hours',
            '> 8 hours',
          ],
          inputType: 'radio',
        ),
        ProfileQuestion(
          id: 10,
          question: 'Do you have any existing medical conditions?',
          options: [
            'None',
            'Diabetes',
            'Hypertension',
            'Thyroid',
            'Heart condition',
            'Other',
          ],
          inputType: 'checkbox',
        ),
      ],
    );
  }

  @override
  List<Object> get props => [questions];
}

// ====================================================================
// SURVEY QUESTIONS MODEL (Periodic / Weekly Surveys)
// ====================================================================

class SurveyQuestion extends Equatable {
  final int id;
  final String question;
  final List<String> options;
  final String? selectedAnswer;

  const SurveyQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.selectedAnswer,
  });

  SurveyQuestion copyWith({
    int? id,
    String? question,
    List<String>? options,
    String? selectedAnswer,
  }) {
    return SurveyQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'selected_answer': selectedAnswer,
    };
  }

  factory SurveyQuestion.fromMap(Map<String, dynamic> map) {
    return SurveyQuestion(
      id: map['id'] ?? 0,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      selectedAnswer: map['selected_answer'],
    );
  }

  @override
  List<Object?> get props => [id, question, options, selectedAnswer];
}

class SurveyData extends Equatable {
  final List<SurveyQuestion> questions;

  const SurveyData({this.questions = const []});

  bool get isCompleted {
    return questions.isNotEmpty &&
        questions.every((q) => q.selectedAnswer != null);
  }

  SurveyData copyWith({List<SurveyQuestion>? questions}) {
    return SurveyData(questions: questions ?? this.questions);
  }

  SurveyData updateAnswer(int questionId, String answer) {
    final updatedQuestions = questions.map((q) {
      if (q.id == questionId) {
        return q.copyWith(selectedAnswer: answer);
      }
      return q;
    }).toList();

    return copyWith(questions: updatedQuestions);
  }

  Map<String, dynamic> toMap() {
    return {'questions': questions.map((q) => q.toMap()).toList()};
  }

  factory SurveyData.fromMap(Map<String, dynamic> map) {
    return SurveyData(
      questions:
          (map['questions'] as List?)
              ?.map((q) => SurveyQuestion.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Predefined survey questions (Periodic/Weekly)
  static SurveyData defaultQuestions() {
    return SurveyData(
      questions: [
        SurveyQuestion(
          id: 1,
          question: 'How often do you exercise?',
          options: [
            'Never',
            '1–2 times/week',
            '3–4 times/week',
            '5+ times/week',
          ],
        ),
        SurveyQuestion(
          id: 2,
          question: 'How would you rate your daily energy levels?',
          options: ['Very low', 'Low', 'Moderate', 'High', 'Very high'],
        ),
        SurveyQuestion(
          id: 3,
          question: 'How balanced is your diet?',
          options: ['Very poor', 'Poor', 'Average', 'Good', 'Excellent'],
        ),
        SurveyQuestion(
          id: 4,
          question: 'How many glasses of water do you drink daily?',
          options: ['< 4', '4–6', '6–8', '8–10', '10+'],
        ),
        SurveyQuestion(
          id: 5,
          question: 'How would you describe your stress levels?',
          options: ['Very high', 'High', 'Moderate', 'Low', 'Very low'],
        ),
        SurveyQuestion(
          id: 6,
          question: 'How well do you sleep?',
          options: ['Very poorly', 'Poorly', 'Average', 'Well', 'Very well'],
        ),
        SurveyQuestion(
          id: 7,
          question: 'Do you experience frequent body pain?',
          options: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
        ),
        SurveyQuestion(
          id: 8,
          question: 'How often do you consume junk or fast food?',
          options: [
            'Daily',
            '3–4 times/week',
            '1–2 times/week',
            'Rarely',
            'Never',
          ],
        ),
        SurveyQuestion(
          id: 9,
          question: 'How often do you feel mentally refreshed?',
          options: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
        ),
        SurveyQuestion(
          id: 10,
          question: 'Overall, how would you rate your health?',
          options: ['Very poor', 'Poor', 'Average', 'Good', 'Excellent'],
        ),
      ],
    );
  }

  @override
  List<Object> get props => [questions];
}

// ====================================================================
// WELLNESS SCORES MODEL
// ====================================================================

class WellnessScores extends Equatable {
  final int physicalHealthScore;
  final int mentalHealthScore;
  final int lifestyleScore;
  final int overallWellnessIndex;

  const WellnessScores({
    required this.physicalHealthScore,
    required this.mentalHealthScore,
    required this.lifestyleScore,
    required this.overallWellnessIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'physical_health_score': physicalHealthScore,
      'mental_health_score': mentalHealthScore,
      'lifestyle_score': lifestyleScore,
      'overall_wellness_index': overallWellnessIndex,
    };
  }

  factory WellnessScores.fromMap(Map<String, dynamic> map) {
    return WellnessScores(
      physicalHealthScore: map['physical_health_score'] ?? 0,
      mentalHealthScore: map['mental_health_score'] ?? 0,
      lifestyleScore: map['lifestyle_score'] ?? 0,
      overallWellnessIndex: map['overall_wellness_index'] ?? 0,
    );
  }

  @override
  List<Object> get props => [
    physicalHealthScore,
    mentalHealthScore,
    lifestyleScore,
    overallWellnessIndex,
  ];
}
