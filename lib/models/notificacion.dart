enum TipoNotificacion { reserva, recordatorio, mensaje, pago, general }

class Notificacion {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final bool leida;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.leida = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuarioId': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo.name,
        'leida': leida,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'],
        usuarioId: json['usuarioId'],
        titulo: json['titulo'],
        mensaje: json['mensaje'],
        tipo: TipoNotificacion.values.firstWhere((t) => t.name == json['tipo']),
        leida: json['leida'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Notificacion copyWith({bool? leida}) {
    return Notificacion(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      leida: leida ?? this.leida,
      createdAt: createdAt,
    );
  }
}
