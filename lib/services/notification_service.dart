import 'package:flutter/foundation.dart';

import '../models/notificacion.dart';
import 'storage_service.dart';

/// Servicio de notificaciones (RF11, RF21, RF22).
/// Simula el envío de correos electrónicos creando notificaciones in-app.
/// En producción se integraría con un servicio SMTP o de push notifications.
class NotificationService extends ChangeNotifier {
  final StorageService _storage;

  NotificationService(this._storage);

  Future<List<Notificacion>> getNotificacionesUsuario(String userId) async {
    final all = await _storage.getNotificaciones();
    final user = all.where((n) => n.usuarioId == userId).toList();
    user.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return user;
  }

  Future<int> getUnreadCount(String userId) async {
    final notifs = await getNotificacionesUsuario(userId);
    return notifs.where((n) => !n.leida).length;
  }

  Future<void> enviarNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    required TipoNotificacion tipo,
  }) async {
    final notif = Notificacion(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      usuarioId: usuarioId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      createdAt: DateTime.now(),
    );
    await _storage.addNotificacion(notif);
    // Aquí se enviaría el correo real (RF21)
    debugPrint('📧 [Correo simulado] Para: $usuarioId | $titulo: $mensaje');
    notifyListeners();
  }

  Future<void> marcarLeida(String notifId) async {
    final all = await _storage.getNotificaciones();
    final idx = all.indexWhere((n) => n.id == notifId);
    if (idx >= 0) {
      all[idx] = all[idx].copyWith(leida: true);
      await _storage.saveNotificaciones(all);
      notifyListeners();
    }
  }

  Future<void> marcarTodasLeidas(String userId) async {
    final all = await _storage.getNotificaciones();
    bool changed = false;
    for (int i = 0; i < all.length; i++) {
      if (all[i].usuarioId == userId && !all[i].leida) {
        all[i] = all[i].copyWith(leida: true);
        changed = true;
      }
    }
    if (changed) {
      await _storage.saveNotificaciones(all);
      notifyListeners();
    }
  }
}
