import 'package:flutter/foundation.dart';

import '../models/cita.dart';
import '../models/notificacion.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// Gestiona las reservas/citas: creación, aceptación, rechazo, consulta. RF10, RF12, RF25.
class CitaService extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notifications;

  CitaService(this._storage, this._notifications);

  /// Todas las citas donde participa el usuario (como tutor o cuidador)
  Future<List<Cita>> getCitasUsuario(String userId) async {
    final all = await _storage.getCitas();
    final mine = all
        .where((c) => c.tutorId == userId || c.cuidadorId == userId)
        .toList();
    mine.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return mine;
  }

  Future<List<Cita>> getCitasParaCuidador(String cuidadorId) async {
    final all = await _storage.getCitas();
    return all.where((c) => c.cuidadorId == cuidadorId).toList();
  }

  Future<List<Cita>> getCitasDelTutor(String tutorId) async {
    final all = await _storage.getCitas();
    return all.where((c) => c.tutorId == tutorId).toList();
  }

  /// RF10: Agendar una nueva cita
  Future<Cita> crearCita({
    required String tutorId,
    required String tutorNombre,
    required String cuidadorId,
    required String cuidadorNombre,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String direccion,
    required String notas,
    required double tarifaHora,
  }) async {
    final horas = fechaFin.difference(fechaInicio).inMinutes / 60.0;
    final total = horas * tarifaHora;

    final cita = Cita(
      id: 'cita-${DateTime.now().millisecondsSinceEpoch}',
      tutorId: tutorId,
      tutorNombre: tutorNombre,
      cuidadorId: cuidadorId,
      cuidadorNombre: cuidadorNombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      direccion: direccion,
      notas: notas,
      tarifaHora: tarifaHora,
      totalEstimado: total,
      estado: EstadoCita.pendiente,
      createdAt: DateTime.now(),
    );

    await _storage.addCita(cita);

    // RF21: notificación al cuidador
    await _notifications.enviarNotificacion(
      usuarioId: cuidadorId,
      titulo: 'Nueva solicitud de cuidado',
      mensaje:
          '$tutorNombre ha solicitado tus servicios para el ${_fmt(fechaInicio)}.',
      tipo: TipoNotificacion.reserva,
    );

    // Confirmación al tutor
    await _notifications.enviarNotificacion(
      usuarioId: tutorId,
      titulo: 'Solicitud enviada',
      mensaje:
          'Tu solicitud para $cuidadorNombre está pendiente de confirmación.',
      tipo: TipoNotificacion.reserva,
    );

    notifyListeners();
    return cita;
  }

  /// RF12: aceptar o rechazar cita
  Future<void> responderCita(String citaId, bool aceptar) async {
    final all = await _storage.getCitas();
    final idx = all.indexWhere((c) => c.id == citaId);
    if (idx < 0) return;

    final cita = all[idx];
    final nuevoEstado = aceptar ? EstadoCita.aceptada : EstadoCita.rechazada;
    final actualizada = cita.copyWith(estado: nuevoEstado);
    await _storage.updateCita(actualizada);

    // RF21: notificar al tutor
    await _notifications.enviarNotificacion(
      usuarioId: cita.tutorId,
      titulo: aceptar ? '¡Cita aceptada!' : 'Cita rechazada',
      mensaje: aceptar
          ? '${cita.cuidadorNombre} aceptó tu solicitud para el ${_fmt(cita.fechaInicio)}.'
          : '${cita.cuidadorNombre} no podrá atender tu solicitud del ${_fmt(cita.fechaInicio)}.',
      tipo: TipoNotificacion.reserva,
    );

    notifyListeners();
  }

  Future<void> cancelarCita(String citaId) async {
    final all = await _storage.getCitas();
    final idx = all.indexWhere((c) => c.id == citaId);
    if (idx < 0) return;
    final cita = all[idx];
    await _storage.updateCita(cita.copyWith(estado: EstadoCita.cancelada));

    await _notifications.enviarNotificacion(
      usuarioId: cita.cuidadorId,
      titulo: 'Cita cancelada',
      mensaje:
          '${cita.tutorNombre} canceló la cita del ${_fmt(cita.fechaInicio)}.',
      tipo: TipoNotificacion.reserva,
    );
    notifyListeners();
  }

  Future<void> marcarCompletada(String citaId) async {
    final all = await _storage.getCitas();
    final idx = all.indexWhere((c) => c.id == citaId);
    if (idx < 0) return;
    await _storage
        .updateCita(all[idx].copyWith(estado: EstadoCita.completada));
    notifyListeners();
  }

  String _fmt(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
