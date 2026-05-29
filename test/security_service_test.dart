import 'package:flutter_test/flutter_test.dart';
import 'package:nanys_care/services/security_service.dart';

void main() {
  final security = SecurityService();

  group('SecurityService - hashing PBKDF2', () {
    test('verifica la contraseña correcta', () {
      final hash = security.hashPassword('Sup3rSecret');
      expect(security.verifyPassword('Sup3rSecret', hash), isTrue);
    });

    test('rechaza una contraseña incorrecta', () {
      final hash = security.hashPassword('Sup3rSecret');
      expect(security.verifyPassword('otra-clave', hash), isFalse);
    });

    test('nunca almacena la contraseña en texto plano', () {
      final hash = security.hashPassword('MiClave123');
      expect(hash.contains('MiClave123'), isFalse);
      expect(security.isHashed(hash), isTrue);
    });

    test('genera una sal distinta en cada hash', () {
      final a = security.hashPassword('MiClave123');
      final b = security.hashPassword('MiClave123');
      expect(a == b, isFalse); // mismo password, hashes distintos
    });

    test('isHashed distingue texto plano de hash', () {
      expect(security.isHashed('123456'), isFalse);
    });
  });

  group('SecurityService - validaciones', () {
    test('valida la robustez de contraseñas', () {
      expect(SecurityService.validarPassword('abc'), isNotNull);
      expect(SecurityService.validarPassword('todominuscula1'), isNotNull);
      expect(SecurityService.validarPassword('SINMINUS1'), isNotNull);
      expect(SecurityService.validarPassword('SinNumeros'), isNotNull);
      expect(SecurityService.validarPassword('Valida123'), isNull);
    });

    test('valida el formato de correo', () {
      expect(SecurityService.emailValido('user@dominio.com'), isTrue);
      expect(SecurityService.emailValido('malo@'), isFalse);
      expect(SecurityService.emailValido('sin-arroba.com'), isFalse);
    });

    test('sanitiza caracteres de control y recorta extremos', () {
      // Elimina tab/salto de línea; conserva el espacio interno normal.
      expect(SecurityService.sanitizar('\t hola\nmundo '), 'holamundo');
      expect(SecurityService.sanitizar('  hola mundo  '), 'hola mundo');
    });
  });
}
