import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/core/utils/schema_validator.dart';

void main() {
  group('Unified Password Validation & Strength Policy', () {
    test('rejects passwords below minimum 8 characters and never reports 100%', () {
      const samples = ['Ab1!', 'Pass#1', 'A1b@c2d', '1234567'];
      for (final pwd in samples) {
        final eval = SchemaValidator.evaluatePassword(pwd);
        expect(eval.isValid, isFalse, reason: 'Should reject $pwd');
        expect(eval.percent, lessThan(1.0), reason: 'Should not be 100% for $pwd');
        expect(eval.level, isNot(PasswordStrengthLevel.strong));
        expect(
          () => SchemaValidator.validateStrictPassword(pwd),
          throwsA(isA<SchemaValidationException>()),
        );
      }
    });

    test('accepts any printable special character consistently', () {
      const validSamples = [
        'Spendly#2026',
        'MyPass_1234!',
        'Secure-Pass99',
        'Test@1234',
        'Alpha^Beta1',
      ];
      for (final pwd in validSamples) {
        final eval = SchemaValidator.evaluatePassword(pwd);
        expect(eval.isValid, isTrue, reason: 'Should accept $pwd');
        expect(eval.level, PasswordStrengthLevel.strong);
        expect(eval.percent, 1.0);
        expect(SchemaValidator.validateStrictPassword(pwd), pwd);
      }
    });

    test('CryptoUtils.generateStrongPassword always passes strict validation', () {
      for (int i = 0; i < 30; i++) {
        final generated = CryptoUtils.generateStrongPassword();
        final eval = SchemaValidator.evaluatePassword(generated);
        expect(eval.isValid, isTrue, reason: 'Generated password $generated failed');
        expect(eval.level, PasswordStrengthLevel.strong);
        expect(eval.percent, 1.0);
        expect(SchemaValidator.validateStrictPassword(generated), generated);
      }
    });

    test('never contradicts: Strong (100%) iff validateStrictPassword passes', () {
      const candidates = [
        '',
        'short',
        'alllowercase1!',
        'ALLUPPERCASE1!',
        'NoDigitsHere!',
        'NoSpecial123',
        'Has Space 1A!',
        'ValidPass123!',
        'Another#Good9',
      ];
      for (final pwd in candidates) {
        final eval = SchemaValidator.evaluatePassword(pwd);
        bool validatorPassed = true;
        try {
          SchemaValidator.validateStrictPassword(pwd);
        } on SchemaValidationException {
          validatorPassed = false;
        }
        expect(
          eval.isValid,
          validatorPassed,
          reason: 'Mismatch between evaluatePassword and validateStrictPassword for "$pwd"',
        );
        expect(
          eval.level == PasswordStrengthLevel.strong,
          validatorPassed,
          reason: 'Strong strength reported for invalid "$pwd" or vice versa',
        );
      }
    });
  });
}
