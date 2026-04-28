import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
  });

  final String uid;
  final String email;
  final String name;

  @override
  List<Object?> get props => [uid, email, name];
}
