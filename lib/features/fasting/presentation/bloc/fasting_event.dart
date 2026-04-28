import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';

abstract class FastingEvent extends Equatable {
  const FastingEvent();

  @override
  List<Object?> get props => [];
}

class FastingInitialized extends FastingEvent {
  const FastingInitialized();
}

class FastingProtocolSelected extends FastingEvent {
  const FastingProtocolSelected(this.protocol);

  final FastingProtocol protocol;

  @override
  List<Object?> get props => [protocol];
}

class FastingStarted extends FastingEvent {
  const FastingStarted();
}

class FastingPaused extends FastingEvent {
  const FastingPaused();
}

class FastingResumed extends FastingEvent {
  const FastingResumed();
}

class FastingStopped extends FastingEvent {
  const FastingStopped();
}

class FastingTicked extends FastingEvent {
  const FastingTicked();
}
