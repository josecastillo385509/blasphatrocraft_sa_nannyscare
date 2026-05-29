import 'package:flutter/foundation.dart';

import '../models/resena.dart';
import 'storage_service.dart';

/// Gestiona reseñas y calificaciones.
///  - HU11: el tutor califica al cuidador (reseña pública) y se recalcula su
///    promedio automáticamente.
///  - HU12 / RF15: el cuidador deja una evaluación privada del tutor, visible
///    solo para él.
class ResenaService extends ChangeNotifier {
  final StorageService _storage;
  ResenaService(this._storage);

  /// Reseñas PÚBLICAS recibidas por un usuario (para mostrar en su perfil).
  Future<List<Resena>> getResenasPublicas(String destinatarioId) async {
    final all = await _storage.getResenas();
    final list = all
        .where((r) => r.destinatarioId == destinatarioId && !r.esPrivada)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Notas PRIVADAS escritas por un autor (HU12 / RF15).
  Future<List<Resena>> getNotasPrivadas(String autorId) async {
    final all = await _storage.getResenas();
    final list = all.where((r) => r.autorId == autorId && r.esPrivada).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Evita duplicados: ¿el autor ya calificó esta cita?
  Future<bool> yaCalifico(String citaId, String autorId) async {
    final all = await _storage.getResenas();
    return all.any((r) => r.citaId == citaId && r.autorId == autorId);
  }

  /// Crea una reseña. Si es pública, recalcula el promedio del destinatario.
  Future<void> crearResena(Resena resena) async {
    await _storage.addResena(resena);
    if (!resena.esPrivada) {
      await _storage.recalcularCalificacionCuidador(resena.destinatarioId);
    }
    notifyListeners();
  }
}
