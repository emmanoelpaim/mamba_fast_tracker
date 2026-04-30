class PasswordPolicyResult {
  const PasswordPolicyResult({
    required this.minLengthMet,
    required this.hasUppercase,
    required this.hasSpecial,
  });

  final bool minLengthMet;
  final bool hasUppercase;
  final bool hasSpecial;

  bool get isValid => minLengthMet && hasUppercase && hasSpecial;

  int get rulesMetCount {
    var n = 0;
    if (minLengthMet) n++;
    if (hasUppercase) n++;
    if (hasSpecial) n++;
    return n;
  }

  static final _upper = RegExp(r'[A-Z]');
  static final _special = RegExp(r'[^a-zA-Z0-9\s]');

  static PasswordPolicyResult evaluate(String password) {
    return PasswordPolicyResult(
      minLengthMet: password.length >= 8,
      hasUppercase: _upper.hasMatch(password),
      hasSpecial: _special.hasMatch(password),
    );
  }

  static String missingRulesMessage(PasswordPolicyResult r) {
    final parts = <String>[];
    if (!r.minLengthMet) {
      parts.add('pelo menos 8 caracteres');
    }
    if (!r.hasUppercase) {
      parts.add('uma letra maiúscula');
    }
    if (!r.hasSpecial) {
      parts.add('um caractere especial');
    }
    if (parts.isEmpty) {
      return '';
    }
    return 'A senha precisa de: ${parts.join(', ')}.';
  }

  static String strengthLabel(PasswordPolicyResult r) {
    final c = r.rulesMetCount;
    if (c == 0) {
      return 'Fraca';
    }
    if (c < 3) {
      return 'Média';
    }
    return 'Forte';
  }
}
