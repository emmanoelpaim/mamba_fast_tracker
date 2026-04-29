import 'package:equatable/equatable.dart';

class DailyGoals extends Equatable {
  const DailyGoals({
    required this.caloriesGoal,
    required this.fastingHoursGoal,
  });

  final int caloriesGoal;
  final int fastingHoursGoal;

  static const defaults = DailyGoals(caloriesGoal: 2000, fastingHoursGoal: 16);

  Map<String, dynamic> toMap() {
    return {'caloriesGoal': caloriesGoal, 'fastingHoursGoal': fastingHoursGoal};
  }

  factory DailyGoals.fromMap(Map<String, dynamic> map) {
    return DailyGoals(
      caloriesGoal: map['caloriesGoal'] as int? ?? defaults.caloriesGoal,
      fastingHoursGoal:
          map['fastingHoursGoal'] as int? ?? defaults.fastingHoursGoal,
    );
  }

  DailyGoals copyWith({int? caloriesGoal, int? fastingHoursGoal}) {
    return DailyGoals(
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      fastingHoursGoal: fastingHoursGoal ?? this.fastingHoursGoal,
    );
  }

  @override
  List<Object?> get props => [caloriesGoal, fastingHoursGoal];
}
