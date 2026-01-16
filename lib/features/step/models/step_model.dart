import 'package:equatable/equatable.dart';

class StepModel extends Equatable {
  final DateTime date;
  final int steps;

  const StepModel({required this.date, required this.steps});

  @override
  List<Object> get props => [date, steps];
}
