enum EstadoCita { pendiente, aceptada, rechazada, completada, cancelada }

extension EstadoCitaExt on EstadoCita {
  String get label {
    switch (this) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.aceptada:
        return 'Aceptada';
      case EstadoCita.rechazada:
        return 'Rechazada';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
    }
  }
}

class Cita {
  final String id;
  final String tutorId;
  final String tutorNombre;
  final String cuidadorId;
  final String cuidadorNombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String direccion;
  final String notas;
  final double tarifaHora;
  final double totalEstimado;
  final EstadoCita estado;
  final DateTime createdAt;

  Cita({
    required this.id,
    required this.tutorId,
    required this.tutorNombre,
    required this.cuidadorId,
    required this.cuidadorNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.direccion,
    required this.notas,
    required this.tarifaHora,
    required this.totalEstimado,
    required this.estado,
    required this.createdAt,
  });

  Duration get duracion => fechaFin.difference(fechaInicio);

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutorId': tutorId,
        'tutorNombre': tutorNombre,
        'cuidadorId': cuidadorId,
        'cuidadorNombre': cuidadorNombre,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'direccion': direccion,
        'notas': notas,
        'tarifaHora': tarifaHora,
        'totalEstimado': totalEstimado,
        'estado': estado.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
        id: json['id'],
        tutorId: json['tutorId'],
        tutorNombre: json['tutorNombre'],
        cuidadorId: json['cuidadorId'],
        cuidadorNombre: json['cuidadorNombre'],
        fechaInicio: DateTime.parse(json['fechaInicio']),
        fechaFin: DateTime.parse(json['fechaFin']),
        direccion: json['direccion'],
        notas: json['notas'],
        tarifaHora: (json['tarifaHora'] as num).toDouble(),
        totalEstimado: (json['totalEstimado'] as num).toDouble(),
        estado: EstadoCita.values.firstWhere((e) => e.name == json['estado']),
        createdAt: DateTime.parse(json['createdAt']),
      );

  Cita copyWith({EstadoCita? estado}) {
    return Cita(
      id: id,
      tutorId: tutorId,
      tutorNombre: tutorNombre,
      cuidadorId: cuidadorId,
      cuidadorNombre: cuidadorNombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      direccion: direccion,
      notas: notas,
      tarifaHora: tarifaHora,
      totalEstimado: totalEstimado,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }
}
