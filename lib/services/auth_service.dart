import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/perfil_cuidador.dart';
import 'storage_service.dart';
import 'security_service.dart';

/// Servicio de autenticación. RF01, RF02.
/// Las contraseñas se verifican siempre contra un hash (ver [SecurityService]);
/// nunca se comparan en texto plano salvo para migrar cuentas heredadas.
class AuthService extends ChangeNotifier {
  final StorageService _storage;
  final SecurityService _security;
  AppUser? _currentUser;

  AuthService(this._storage, this._security);

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadSession() async {
    final id = _storage.getCurrentUserId();
    if (id != null) {
      final users = await _storage.getUsers();
      try {
        _currentUser = users.firstWhere((u) => u.id == id);
      } catch (_) {
        _currentUser = null;
      }
      notifyListeners();
    }
  }

  /// RF02: Inicio de sesión
  /// Retorna null si éxito o un string con el mensaje de error.
  Future<String?> login(String email, String password) async {
    final users = await _storage.getUsers();
    AppUser? user;
    try {
      user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return 'No existe una cuenta con este correo';
    }

    if (_security.isHashed(user.password)) {
      if (!_security.verifyPassword(password, user.password)) {
        return 'Contraseña incorrecta';
      }
    } else {
      // Cuenta heredada con contraseña en texto plano: se compara una sola vez
      // y se migra a hash de inmediato para no volver a almacenarla en claro.
      if (user.password != password) {
        return 'Contraseña incorrecta';
      }
      final migrado = user.copyWith(password: _security.hashPassword(password));
      await updateUser(migrado);
      user = migrado;
    }

    _currentUser = user;
    await _storage.setCurrentUserId(user.id);
    notifyListeners();
    return null;
  }

  /// RF01: Registro de nuevo usuario
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    // Validación y saneamiento de entradas antes de tocar el almacenamiento.
    final cleanEmail = SecurityService.sanitizar(email).toLowerCase();
    final cleanName = SecurityService.sanitizar(name);
    if (!SecurityService.emailValido(cleanEmail)) {
      return 'Correo electrónico inválido';
    }
    final pwdError = SecurityService.validarPassword(password);
    if (pwdError != null) return pwdError;

    final users = await _storage.getUsers();

    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      return 'Ya existe una cuenta con este correo';
    }

    final newUser = AppUser(
      id: '${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      password: _security.hashPassword(password), // nunca en texto plano
      name: cleanName,
      role: role,
      phone: phone == null ? null : SecurityService.sanitizar(phone),
      createdAt: DateTime.now(),
    );

    users.add(newUser);
    await _storage.saveUsers(users);

    // HU3/HU4: un cuidador nuevo arranca con un perfil por defecto (nivel
    // principiante y tarifa sugerida) para poder completarlo y aparecer en
    // las búsquedas. Lo edita después desde "Mi Perfil".
    if (role == UserRole.cuidador) {
      await _storage.upsertPerfilCuidador(
        PerfilCuidador(
          userId: newUser.id,
          descripcion: '',
          nivelExperiencia: NivelExperiencia.principiante,
          certificaciones: const [],
          capacidades: const [],
          tarifaPorHora: NivelExperiencia.principiante.tarifaSugeridaPorHora,
          ubicacion: '',
          diasDisponibles: const [],
          horarioDisponible: '',
        ),
      );
    }

    _currentUser = newUser;
    await _storage.setCurrentUserId(newUser.id);
    notifyListeners();
    return null;
  }

  Future<void> updateUser(AppUser updated) async {
    final users = await _storage.getUsers();
    final idx = users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      users[idx] = updated;
      await _storage.saveUsers(users);
      _currentUser = updated;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.setCurrentUserId(null);
    notifyListeners();
  }
}
