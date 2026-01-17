import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_health/features/form/bloc/form_bloc.dart';
import 'package:ai_health/features/home/pages/home_page.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  @override
  void initState() {
    super.initState();
    context.read<FormBloc>().add(LoadSurvey());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Survey'),
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<FormBloc, AppFormState>(
          listener: (context, state) {
            if (state is SurveySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Survey submitted successfully!')),
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else if (state is FormFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
            }
          },
          builder: (context, state) {
            if (state is SurveyLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SurveyDataState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please answer the following questions to help us personalize your experience:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ...state.questions.asMap().entries.map((entry) {
                      return _buildQuestionWidget(context, state, entry.key);
                    }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isCompleted
                            ? () => context.read<FormBloc>().add(
                                SurveySubmitted(),
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: state.isCompleted
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                        child: const Text(
                          'Submit Survey',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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

  Widget _buildQuestionWidget(
    BuildContext context,
    SurveyDataState state,
    int index,
  ) {
    final question = state.questions[index];
    final options = List<String>.from(question['options'] ?? []);
    final selectedAnswer = state.selectedAnswers[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}: ${question['question']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...options.map((option) {
            final isSelected = selectedAnswer == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  context.read<FormBloc>().add(
                    SurveyAnswerChanged(index, option),
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
                            color: isSelected ? Colors.blue : Colors.grey[400]!,
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
        ],
      ),
    );
  }
}
