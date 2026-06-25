import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Hashes a password using SHA-256 to ensure it is secure in the database
  static String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  /// Generates a highly secure strong password
  static String generateStrongPassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    final rand = Random();
    final List<String> password = [];

    // Ensure at least one of each required type
    password.add(uppercase[rand.nextInt(uppercase.length)]);
    password.add(lowercase[rand.nextInt(lowercase.length)]);
    password.add(numbers[rand.nextInt(numbers.length)]);
    password.add(special[rand.nextInt(special.length)]);

    // Fill the rest up to 12 characters
    const allChars = '$uppercase$lowercase$numbers$special';
    for (int i = 0; i < 8; i++) {
      password.add(allChars[rand.nextInt(allChars.length)]);
    }

    // Shuffle the characters
    password.shuffle(rand);
    return password.join();
  }
}
