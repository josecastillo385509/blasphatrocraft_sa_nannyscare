import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/perfil_cuidador.dart';
import '../models/perfil_tutor.dart';
import 'storage_service.dart';

class CuidadorConUsuario {
  final AppUser usuario;
  final PerfilCuidador perfil;
  CuidadorConUsuario({required this.usuario, required this.perfil});
}

/// Servicio que centraliza datos de cuidadores y tutores.
/// RF06 (búsqueda), RF03/RF04/RF05 (perfiles).
class DataService extends ChangeNotifier {
  final StorageService _storage;
  DataService(this._storage);

  Future<List<CuidadorConUsuario>> getTodosLosCuidadores() async {
    final users = await _storage.getUsers();
    final perfiles = await _storage.getPerfilesCuidador();
    final List<CuidadorConUsuario> result = [];
    for (final p in perfiles) {
      try {
        final u = users.firstWhere((u) => u.id == p.userId);
        result.add(CuidadorConUsuario(usuario: u, perfil: p));
      } catch (_) {}
    }
    return result;
  }

  /// RF06: búsqueda con filtros
  Future<List<CuidadorConUsuario>> buscarCuidadores({
    String? textoBusqueda,
    String? ubicacion,
    double? precioMin,
    double? precioMax,
    NivelExperiencia? nivelMinimo,
    double? calificacionMinima,
    String? diaDisponible,
  }) async {
    var list = await getTodosLosCuidadores();

    if (textoBusqueda != null && textoBusqueda.isNotEmpty) {
      final q = textoBusqueda.toLowerCase();
      list = list.where((c) {
        return c.usuario.name.toLowerCase().contains(q) ||
            c.perfil.descripcion.toLowerCase().contains(q) ||
            c.perfil.capacidades
                .any((cap) => cap.toLowerCase().contains(q));
      }).toList();
    }

    if (ubicacion != null && ubicacion.isNotEmpty) {
      list = list
          .where((c) =>
              c.perfil.ubicacion.toLowerCase().contains(ubicacion.toLowerCase()))
          .toList();
    }

    if (precioMin != null) {
      list = list.where((c) => c.perfil.tarifaPorHora >= precioMin).toList();
    }
    if (precioMax != null) {
      list = list.where((c) => c.perfil.tarifaPorHora <= precioMax).toList();
    }

    if (nivelMinimo != null) {
      list = list
          .where((c) =>
              c.perfil.nivelExperiencia.index >= nivelMinimo.index)
          .toList();
    }

    if (calificacionMinima != null) {
      list = list
          .where((c) => c.perfil.calificacionPromedio >= calificacionMinima)
          .toList();
    }

    if (diaDisponible != null && diaDisponible.isNotEmpty) {
      list = list
          .where((c) => c.perfil.diasDisponibles.contains(diaDisponible))
          .toList();
    }

    return list;
  }

  Future<PerfilCuidador?> getPerfilCuidador(String userId) async {
    final perfiles = await _storage.getPerfilesCuidador();
    try {
      return perfiles.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<PerfilTutor?> getPerfilTutor(String userId) async {
    final perfiles = await _storage.getPerfilesTutor();
    try {
      return perfiles.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarPerfilCuidador(PerfilCuidador perfil) async {
    await _storage.upsertPerfilCuidador(perfil);
    notifyListeners();
  }

  Future<void> guardarPerfilTutor(PerfilTutor perfil) async {
    await _storage.upsertPerfilTutor(perfil);
    notifyListeners();
  }

  Future<AppUser?> getUsuario(String userId) async {
    final users = await _storage.getUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }
}
