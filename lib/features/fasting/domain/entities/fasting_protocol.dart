import 'package:equatable/equatable.dart';

class FastingProtocol extends Equatable {
  const FastingProtocol({
    required this.label,
    required this.fastingHours,
    required this.eatingHours,
    this.isCustom = false,
  });

  final String label;
  final int fastingHours;
  final int eatingHours;
  final bool isCustom;

  Duration get fastingDuration => Duration(hours: fastingHours);

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fastingHours': fastingHours,
      'eatingHours': eatingHours,
      'isCustom': isCustom,
    };
  }

  factory FastingProtocol.fromMap(Map<String, dynamic> map) {
    return FastingProtocol(
      label: map['label'] as String? ?? '16:8',
      fastingHours: map['fastingHours'] as int? ?? 16,
      eatingHours: map['eatingHours'] as int? ?? 8,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  static const preset1212 = FastingProtocol(
    label: '12:12',
    fastingHours: 12,
    eatingHours: 12,
  );

  static const preset168 = FastingProtocol(
    label: '16:8',
    fastingHours: 16,
    eatingHours: 8,
  );

  static const preset186 = FastingProtocol(
    label: '18:6',
    fastingHours: 18,
    eatingHours: 6,
  );

  static const defaultProtocol = preset168;

  @override
  List<Object?> get props => [label, fastingHours, eatingHours, isCustom];
}
