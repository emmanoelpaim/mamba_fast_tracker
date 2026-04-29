import 'package:equatable/equatable.dart';

class MealEntry extends Equatable {
  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.createdAtUtc,
  });

  final String id;
  final String name;
  final int calories;
  final DateTime createdAtUtc;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'createdAtUtc': createdAtUtc.millisecondsSinceEpoch,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAtUtc'];
    final createdAtMs = rawCreatedAt is int ? rawCreatedAt : 0;
    return MealEntry(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      calories: map['calories'] as int? ?? 0,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        createdAtMs,
        isUtc: true,
      ),
    );
  }

  MealEntry copyWith({
    String? id,
    String? name,
    int? calories,
    DateTime? createdAtUtc,
  }) {
    return MealEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  List<Object?> get props => [id, name, calories, createdAtUtc];
}
