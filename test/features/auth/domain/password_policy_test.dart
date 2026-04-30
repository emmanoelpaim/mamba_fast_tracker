import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/auth/domain/password_policy.dart';

void main() {
  group('PasswordPolicyResult.evaluate', () {
    test('empty password fails all rules', () {
      final r = PasswordPolicyResult.evaluate('');
      expect(r.minLengthMet, false);
      expect(r.hasUppercase, false);
      expect(r.hasSpecial, false);
      expect(r.isValid, false);
    });

    test('valid password meets all rules', () {
      final r = PasswordPolicyResult.evaluate('Abcdef1!');
      expect(r.minLengthMet, true);
      expect(r.hasUppercase, true);
      expect(r.hasSpecial, true);
      expect(r.isValid, true);
    });

    test('missing uppercase', () {
      final r = PasswordPolicyResult.evaluate('abcdef1!');
      expect(r.hasUppercase, false);
      expect(r.isValid, false);
    });

    test('missing special', () {
      final r = PasswordPolicyResult.evaluate('Abcdefgh');
      expect(r.hasSpecial, false);
      expect(r.isValid, false);
    });

    test('underscore counts as special', () {
      final r = PasswordPolicyResult.evaluate('Abcdefg_');
      expect(r.hasSpecial, true);
    });
  });
}
