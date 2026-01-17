import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_health/features/form/models/survey_model.dart';
import 'dart:developer' as developer;

class FormRepository {
  final SupabaseClient _supabaseClient;

  FormRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  // ====================================================================
  // PROFILE DATA METHODS
  // ====================================================================

  Future<ProfileData?> getProfileData() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      developer.log('getProfileData - Current user: ${user?.id}');

      if (user == null) {
        developer.log('getProfileData - User is null, returning null');
        return null;
      }

      developer.log('getProfileData - Fetching profile for user: ${user.id}');

      final response = await _supabaseClient
          .from('user_profile_answers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        developer.log('getProfileData - No profile found for user');
        return null;
      }

      developer.log('getProfileData - Profile found: ${response.toString()}');

      // Map response to ProfileData
      final profileData = ProfileData(
        questions: [
          ProfileQuestion(
            id: 1,
            question: 'What is your age group?',
            options: ['Under 18', '18–24', '25–34', '35–44', '45–54', '55+'],
            selectedAnswer: response['age_group'],
            inputType: 'radio',
          ),
          ProfileQuestion(
            id: 2,
            question: 'What is your biological sex?',
            options: ['Male', 'Female', 'Prefer not to say'],
            selectedAnswer: response['biological_sex'],
            inputType: 'radio',
          ),
          ProfileQuestion(
            id: 3,
            question: 'What is your height? (cm)',
            options: [],
            selectedAnswer: response['height_cm']?.toString(),
            inputType: 'number',
            minValue: 100,
            maxValue: 250,
          ),
          ProfileQuestion(
            id: 4,
            question: 'What is your weight? (kg)',
            options: [],
            selectedAnswer: response['weight_kg']?.toString(),
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
            selectedAnswer: response['body_type'],
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
            selectedAnswer: response['primary_health_goal'],
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
            selectedAnswer: response['activity_level'],
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
            selectedAnswer: response['dietary_preference'],
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
            selectedAnswer: response['avg_sleep_duration'],
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
            selectedAnswer: (response['medical_conditions'] as List?)?.join(
              ',',
            ),
            inputType: 'checkbox',
          ),
        ],
      );

      return profileData;
    } on PostgrestException catch (e) {
      developer.log(
        'getProfileData - PostgrestException: ${e.message}',
        error: e,
      );
      if (e.code == 'PGRST116') {
        developer.log('getProfileData - No rows found (normal for new user)');
        return null;
      }
      rethrow;
    } catch (e) {
      developer.log('getProfileData - Unexpected error: $e', error: e);
      rethrow;
    }
  }

  Future<void> saveProfileData(ProfileData profileData) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      developer.log('saveProfileData - Current user: ${user?.id}');

      if (user == null) {
        throw Exception('User not logged in');
      }

      final data = {
        'user_id': user.id,
        'age_group': profileData.questions[0].selectedAnswer,
        'biological_sex': profileData.questions[1].selectedAnswer,
        'height_cm': int.tryParse(
          profileData.questions[2].selectedAnswer ?? '',
        ),
        'weight_kg': double.tryParse(
          profileData.questions[3].selectedAnswer ?? '',
        ),
        'body_type': profileData.questions[4].selectedAnswer,
        'primary_health_goal': profileData.questions[5].selectedAnswer,
        'activity_level': profileData.questions[6].selectedAnswer,
        'dietary_preference': profileData.questions[7].selectedAnswer,
        'avg_sleep_duration': profileData.questions[8].selectedAnswer,
        'medical_conditions':
            profileData.questions[9].selectedAnswer?.split(',') ?? [],
        'completed_at': DateTime.now().toIso8601String(),
      };

      developer.log('saveProfileData - Saving data: ${data.toString()}');

      await _supabaseClient.from('user_profile_answers').upsert(data);

      developer.log('saveProfileData - Profile saved successfully');
    } on PostgrestException catch (e) {
      developer.log(
        'saveProfileData - PostgrestException: ${e.message}',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log('saveProfileData - Error: $e', error: e);
      rethrow;
    }
  }

  // ====================================================================
  // SURVEY QUESTIONS METHODS
  // ====================================================================

  Future<List<Map<String, dynamic>>> getSurveyQuestions() async {
    try {
      developer.log('getSurveyQuestions - Loading survey questions');

      final questions = [
        {
          'id': 0,
          'question': 'How often do you exercise?',
          'options': [
            'Never',
            '1–2 times/week',
            '3–4 times/week',
            '5+ times/week',
          ],
        },
        {
          'id': 1,
          'question': 'How would you rate your daily energy levels?',
          'options': ['Very low', 'Low', 'Moderate', 'High', 'Very high'],
        },
        {
          'id': 2,
          'question': 'How balanced is your diet?',
          'options': ['Very poor', 'Poor', 'Average', 'Good', 'Excellent'],
        },
        {
          'id': 3,
          'question': 'How many glasses of water do you drink daily?',
          'options': ['< 4', '4–6', '6–8', '8–10', '10+'],
        },
        {
          'id': 4,
          'question': 'How would you describe your stress levels?',
          'options': ['Very high', 'High', 'Moderate', 'Low', 'Very low'],
        },
        {
          'id': 5,
          'question': 'How well do you sleep?',
          'options': ['Very poorly', 'Poorly', 'Average', 'Well', 'Very well'],
        },
        {
          'id': 6,
          'question': 'Do you experience frequent body pain?',
          'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
        },
        {
          'id': 7,
          'question': 'How often do you consume junk or fast food?',
          'options': [
            'Daily',
            '3–4 times/week',
            '1–2 times/week',
            'Rarely',
            'Never',
          ],
        },
        {
          'id': 8,
          'question': 'How often do you feel mentally refreshed?',
          'options': ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
        },
        {
          'id': 9,
          'question': 'Overall, how would you rate your health?',
          'options': ['Very poor', 'Poor', 'Average', 'Good', 'Excellent'],
        },
      ];

      developer.log(
        'getSurveyQuestions - Loaded ${questions.length} questions',
      );
      return questions;
    } catch (e) {
      developer.log('getSurveyQuestions - Error: $e', error: e);
      rethrow;
    }
  }

  Future<void> saveSurveyData(List<String?> answers) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      developer.log('saveSurveyData - Current user: ${user?.id}');
      developer.log('saveSurveyData - Answers: $answers');

      if (user == null) {
        throw Exception('User not logged in');
      }

      final data = {
        'user_id': user.id,
        'exercise_frequency': answers[0],
        'energy_levels': answers[1],
        'diet_balance': answers[2],
        'water_intake': answers[3],
        'stress_levels': answers[4],
        'sleep_quality': answers[5],
        'body_pain_frequency': answers[6],
        'junk_food_frequency': answers[7],
        'mental_refreshment': answers[8],
        'health_rating': answers[9],
        'created_at': DateTime.now().toIso8601String(),
      };

      developer.log('saveSurveyData - Saving data: ${data.toString()}');

      final response = await _supabaseClient
          .from('user_survey_responses')
          .insert(data);

      developer.log('saveSurveyData - Survey saved successfully: $response');
    } on PostgrestException catch (e) {
      developer.log(
        'saveSurveyData - PostgrestException: ${e.message}',
        error: e,
      );
      developer.log(
        'saveSurveyData - Error details: ${e.code} - ${e.details}',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log('saveSurveyData - Error: $e', error: e);
      rethrow;
    }
  }

  Future<List<String?>?> getSurveyData() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      developer.log('getSurveyData - Current user: ${user?.id}');

      if (user == null) {
        return null;
      }

      final response = await _supabaseClient
          .from('user_survey_responses')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        developer.log('getSurveyData - No survey data found');
        return null;
      }

      developer.log(
        'getSurveyData - Survey data found: ${response.toString()}',
      );

      final answers = <String?>[
        response['exercise_frequency'] as String?,
        response['energy_levels'] as String?,
        response['diet_balance'] as String?,
        response['water_intake'] as String?,
        response['stress_levels'] as String?,
        response['sleep_quality'] as String?,
        response['body_pain_frequency'] as String?,
        response['junk_food_frequency'] as String?,
        response['mental_refreshment'] as String?,
        response['health_rating'] as String?,
      ];

      return answers;
    } on PostgrestException catch (e) {
      developer.log(
        'getSurveyData - PostgrestException: ${e.message}',
        error: e,
      );
      return null;
    } catch (e) {
      developer.log('getSurveyData - Error: $e', error: e);
      return null;
    }
  }
}
