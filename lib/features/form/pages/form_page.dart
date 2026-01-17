import 'package:ai_health/features/form/pages/survey_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_health/features/form/bloc/form_bloc.dart';
import 'package:ai_health/features/form/models/survey_model.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  late FormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = context.read<FormBloc>();
    _formBloc.add(LoadProfileQuestions());
  }

  /// Validate all form fields before submission
  String? _validateAllFields(List<ProfileQuestion> questions) {
    // Check Question 1: Age Group (required)
    if (questions[0].selectedAnswer == null ||
        questions[0].selectedAnswer!.isEmpty) {
      return 'Please select your age group';
    }

    // Check Question 2: Biological Sex (required)
    if (questions[1].selectedAnswer == null ||
        questions[1].selectedAnswer!.isEmpty) {
      return 'Please select your biological sex';
    }

    // Check Question 3: Height (required, range 100-250)
    if (questions[2].selectedAnswer == null ||
        questions[2].selectedAnswer!.isEmpty) {
      return 'Please enter your height';
    }
    final height = int.tryParse(questions[2].selectedAnswer!);
    if (height == null) {
      return 'Height must be a valid number';
    }
    if (height < 100 || height > 250) {
      return 'Height must be between 100 and 250 cm';
    }

    // Check Question 4: Weight (required, range 30-300)
    if (questions[3].selectedAnswer == null ||
        questions[3].selectedAnswer!.isEmpty) {
      return 'Please enter your weight';
    }
    final weight = double.tryParse(questions[3].selectedAnswer!);
    if (weight == null) {
      return 'Weight must be a valid number';
    }
    if (weight < 30 || weight > 300) {
      return 'Weight must be between 30 and 300 kg';
    }

    // Check Question 5: Body Type (required)
    if (questions[4].selectedAnswer == null ||
        questions[4].selectedAnswer!.isEmpty) {
      return 'Please select your body type';
    }

    // Check Question 6: Primary Health Goal (required)
    if (questions[5].selectedAnswer == null ||
        questions[5].selectedAnswer!.isEmpty) {
      return 'Please select your primary health goal';
    }

    // Check Question 7: Activity Level (required)
    if (questions[6].selectedAnswer == null ||
        questions[6].selectedAnswer!.isEmpty) {
      return 'Please select your activity level';
    }

    // Check Question 8: Dietary Preference (required)
    if (questions[7].selectedAnswer == null ||
        questions[7].selectedAnswer!.isEmpty) {
      return 'Please select your dietary preference';
    }

    // Check Question 9: Sleep Duration (required)
    if (questions[8].selectedAnswer == null ||
        questions[8].selectedAnswer!.isEmpty) {
      return 'Please select your average sleep duration';
    }

    // Check Question 10: Medical Conditions (optional, but if selected should be valid)
    // This one is optional, so we just return null if everything passes

    return null; // All validations passed
  }

  /// Handle form submission with validation
  void _handleSubmit(ProfileFormState state) {
    final validationError = _validateAllFields(state.questions);

    if (validationError != null) {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // All validations passed, submit the form
    _formBloc.add(ProfileFormSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Your Profile'),
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<FormBloc, AppFormState>(
          listener: (context, state) {
            if (state is FormSuccess) {
              // Profile saved successfully, navigate to survey
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SurveyPage()),
              );
            } else if (state is FormFailure) {
              print(state.error);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FormLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileFormState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Please answer all questions to continue',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ...state.questions.asMap().entries.map((entry) {
                        final question = entry.value;
                        return _buildQuestionWidget(context, question);
                      }),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isCompleted
                              ? () => _handleSubmit(state)
                              : () => _handleSubmit(state),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: state.isCompleted
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                          child: SizedBox(
                            child: Text(
                              'Continue to Survey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, ProfileQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (question.inputType != 'checkbox')
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.end,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (question.inputType == 'radio') ...[
            ...question.options.map((option) {
              final isSelected = question.selectedAnswer == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    context.read<FormBloc>().add(
                      ProfileAnswerChanged(question.id, option),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.blue[50] : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: isSelected
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else if (question.inputType == 'number') ...[
            TextFormField(
              initialValue: question.selectedAnswer,
              decoration: InputDecoration(
                labelText:
                    '${question.question} (${question.minValue} - ${question.maxValue})',
                hintText: 'Enter value',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final numValue = double.tryParse(value);
                  if (numValue != null &&
                      numValue >= (question.minValue ?? 0) &&
                      numValue <= (question.maxValue ?? 999)) {
                    context.read<FormBloc>().add(
                      ProfileAnswerChanged(question.id, value),
                    );
                    setState(() {});
                  }
                }
              },
            ),
          ] else if (question.inputType == 'checkbox') ...[
            ...question.options.map((option) {
              final selectedAnswers = question.selectedAnswer?.split(',') ?? [];
              final isSelected = selectedAnswers.contains(option);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    final List<String> updated = [...selectedAnswers];
                    if (isSelected) {
                      updated.remove(option);
                    } else {
                      updated.add(option);
                    }
                    context.read<FormBloc>().add(
                      ProfileAnswerChanged(question.id, updated.join(',')),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.blue[50] : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
