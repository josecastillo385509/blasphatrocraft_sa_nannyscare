import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Servicio de seguridad y protección de datos.
///
/// Responsabilidades:
///  - Derivar y verificar contraseñas con PBKDF2-HMAC-SHA256 + sal aleatoria,
///    de modo que nunca se almacene la contraseña en texto plano.
///  - Validar la robustez de las contraseñas y el formato de los correos.
///  - Sanitizar entradas de texto para evitar caracteres de control.
///
/// El formato persistido es:  `pbkdf2$<iter>$<salt_b64>$<hash_b64>`
class SecurityService {
  /// Iteraciones de PBKDF2. En producción conviene >100k; aquí se usa un valor
  /// moderado para no penalizar el arranque del demo educativo.
  static const int _iterations = 12000;
  static const int _saltBytes = 16; // 128 bits de sal
  static const int _keyLength = 32; // 256 bits de salida
  static const String _algoTag = 'pbkdf2';

  final Random _rng = Random.secure();

  /// Genera el hash seguro de una contraseña con una sal nueva (o la indicada).
  String hashPassword(String password, {Uint8List? salt}) {
    final usedSalt = salt ?? _randomBytes(_saltBytes);
    final hash = _pbkdf2(utf8.encode(password), usedSalt, _iterations, _keyLength);
    return '$_algoTag\$$_iterations\$${base64Encode(usedSalt)}\$${base64Encode(hash)}';
  }

  /// Verifica una contraseña contra un valor previamente almacenado.
  /// La comparación es en tiempo constante para evitar ataques de temporización.
  bool verifyPassword(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != _algoTag) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(password), salt, iterations, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  /// ¿El valor almacenado ya está hasheado con este servicio?
  /// Permite migrar cuentas heredadas que tuvieran la contraseña en texto plano.
  bool isHashed(String value) => value.startsWith('$_algoTag\$');

  /// Valida la robustez de una contraseña. Devuelve `null` si es válida
  /// o un mensaje de error en caso contrario.
  static String? validarPassword(String pwd) {
    if (pwd.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) return 'Incluye al menos una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(pwd)) return 'Incluye al menos una minúscula';
    if (!RegExp(r'[0-9]').hasMatch(pwd)) return 'Incluye al menos un número';
    return null;
  }

  /// Validación de formato de correo electrónico.
  static bool emailValido(String email) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email.trim());

  /// Elimina caracteres de control y espacios sobrantes de una entrada de texto.
  static String sanitizar(String input) =>
      input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();

  // ==================== Implementación PBKDF2 ====================

  Uint8List _pbkdf2(
      List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final output = BytesBuilder();
    var blockIndex = 1;
    while (output.length < keyLength) {
      output.add(_pbkdf2Block(hmac, salt, iterations, blockIndex));
      blockIndex++;
    }
    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  List<int> _pbkdf2Block(
      Hmac hmac, List<int> salt, int iterations, int blockIndex) {
    final intBlock = [
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];
    var u = hmac.convert([...salt, ...intBlock]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List.generate(n, (_) => _rng.nextInt(256)));

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
