import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

Random _bestEffortRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}

String generateSalt({int bytes = 16}) {
  final rand = _bestEffortRandom();
  final data = List<int>.generate(bytes, (_) => rand.nextInt(256));
  return base64UrlEncode(data);
}

String hashPassword({required String password, required String salt}) {
  final bytes = utf8.encode('$salt:$password');
  final digest = sha256.convert(bytes);
  return digest.toString();
}

bool verifyPassword({
  required String password,
  required String salt,
  required String expectedHash,
}) {
  if (salt.isEmpty || expectedHash.isEmpty) return false;
  final actual = hashPassword(password: password, salt: salt);
  return actual == expectedHash;
}

String generateNumericCode({int length = 6}) {
  final rand = _bestEffortRandom();
  final max = pow(10, length).toInt();
  final code = rand.nextInt(max);
  return code.toString().padLeft(length, '0');
}
