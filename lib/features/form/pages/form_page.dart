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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
            }
          },
          builder: (context, state) {
            if (state is FormLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileFormState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                            ? () => _formBloc.add(ProfileFormSubmitted())
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: state.isCompleted
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                        child: const Text(
                          'Continue to Survey',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
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
          Text(
            question.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                labelText: question.question,
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
