import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'storage_service.dart';

/// Servicio de autenticación. RF01, RF02.
class AuthService extends ChangeNotifier {
  final StorageService _storage;
  AppUser? _currentUser;

  AuthService(this._storage);

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

    if (user.password != password) {
      return 'Contraseña incorrecta';
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
    final users = await _storage.getUsers();

    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return 'Ya existe una cuenta con este correo';
    }

    final newUser = AppUser(
      id: '${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      password: password,
      name: name,
      role: role,
      phone: phone,
      createdAt: DateTime.now(),
    );

    users.add(newUser);
    await _storage.saveUsers(users);

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
