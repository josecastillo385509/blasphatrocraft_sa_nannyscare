import '../models/cita.dart';
import '../models/notificacion.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// HU9 / HU14: genera recordatorios automáticos.
///
/// Como la app no tiene backend ni tareas programadas, el patrón es revisar las
/// citas cada vez que la app arranca o se refrescan las notificaciones, y crear
/// un recordatorio para cada cita próxima que aún no tenga uno.
class ReminderService {
  final StorageService _storage;
  final NotificationService _notifications;
  ReminderService(this._storage, this._notifications);

  /// Ventana de anticipación: se recuerda una cita confirmada cuando faltan
  /// 24 horas o menos para su inicio.
  static const Duration _ventana = Duration(hours: 24);

  /// Llamar al iniciar sesión y/o al refrescar el panel de notificaciones.
  Future<void> generarRecordatoriosPendientes() async {
    final ahora = DateTime.now();
    final citas = await _storage.getCitas();
    final existentes = await _storage.getNotificaciones();

    bool yaTiene(String userId, String citaId) => existentes.any((n) =>
        n.tipo == TipoNotificacion.recordatorio &&
        n.usuarioId == userId &&
        n.mensaje.contains('[$citaId]'));

    for (final c in citas) {
      if (c.estado != EstadoCita.aceptada) continue; // solo citas confirmadas
      final faltan = c.fechaInicio.difference(ahora);
      if (faltan.isNegative) continue; // ya ocurrió
      if (faltan > _ventana) continue; // todavía no toca recordar

      final cuando = _fmt(c.fechaInicio);

      if (!yaTiene(c.tutorId, c.id)) {
        await _notifications.enviarNotificacion(
          usuarioId: c.tutorId,
          titulo: 'Recordatorio de cita',
          mensaje: 'Tu cita con ${c.cuidadorNombre} es el $cuando. [${c.id}]',
          tipo: TipoNotificacion.recordatorio,
        );
      }
      if (!yaTiene(c.cuidadorId, c.id)) {
        await _notifications.enviarNotificacion(
          usuarioId: c.cuidadorId,
          titulo: 'Recordatorio de cita',
          mensaje: 'Tienes una cita con ${c.tutorNombre} el $cuando. [${c.id}]',
          tipo: TipoNotificacion.recordatorio,
        );
      }
    }
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
