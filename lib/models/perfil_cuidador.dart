enum NivelExperiencia { principiante, intermedio, avanzado, experto }

extension NivelExperienciaExt on NivelExperiencia {
  String get label {
    switch (this) {
      case NivelExperiencia.principiante:
        return 'Principiante (0-1 años)';
      case NivelExperiencia.intermedio:
        return 'Intermedio (1-3 años)';
      case NivelExperiencia.avanzado:
        return 'Avanzado (3-5 años)';
      case NivelExperiencia.experto:
        return 'Experto (5+ años)';
    }
  }

  // RF04: Tarifas asociadas al nivel de experiencia
  double get tarifaSugeridaPorHora {
    switch (this) {
      case NivelExperiencia.principiante:
        return 80.0;
      case NivelExperiencia.intermedio:
        return 120.0;
      case NivelExperiencia.avanzado:
        return 180.0;
      case NivelExperiencia.experto:
        return 250.0;
    }
  }
}

class PerfilCuidador {
  final String userId;
  final String descripcion;
  final NivelExperiencia nivelExperiencia;
  final List<String> certificaciones;
  final List<String> capacidades; // Ej: RCP, primeros auxilios, idiomas, etc.
  final double tarifaPorHora;
  final String ubicacion;
  final List<String> diasDisponibles; // ['Lunes', 'Martes'...]
  final String horarioDisponible; // Ej: '08:00 - 18:00'
  final double calificacionPromedio;
  final int totalServicios;
  final bool verificado;

  PerfilCuidador({
    required this.userId,
    required this.descripcion,
    required this.nivelExperiencia,
    required this.certificaciones,
    required this.capacidades,
    required this.tarifaPorHora,
    required this.ubicacion,
    required this.diasDisponibles,
    required this.horarioDisponible,
    this.calificacionPromedio = 0.0,
    this.totalServicios = 0,
    this.verificado = false,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'descripcion': descripcion,
        'nivelExperiencia': nivelExperiencia.name,
        'certificaciones': certificaciones,
        'capacidades': capacidades,
        'tarifaPorHora': tarifaPorHora,
        'ubicacion': ubicacion,
        'diasDisponibles': diasDisponibles,
        'horarioDisponible': horarioDisponible,
        'calificacionPromedio': calificacionPromedio,
        'totalServicios': totalServicios,
        'verificado': verificado,
      };

  PerfilCuidador copyWith({
    double? calificacionPromedio,
    int? totalServicios,
    bool? verificado,
  }) {
    return PerfilCuidador(
      userId: userId,
      descripcion: descripcion,
      nivelExperiencia: nivelExperiencia,
      certificaciones: certificaciones,
      capacidades: capacidades,
      tarifaPorHora: tarifaPorHora,
      ubicacion: ubicacion,
      diasDisponibles: diasDisponibles,
      horarioDisponible: horarioDisponible,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
      totalServicios: totalServicios ?? this.totalServicios,
      verificado: verificado ?? this.verificado,
    );
  }

  factory PerfilCuidador.fromJson(Map<String, dynamic> json) => PerfilCuidador(
        userId: json['userId'],
        descripcion: json['descripcion'],
        nivelExperiencia: NivelExperiencia.values
            .firstWhere((n) => n.name == json['nivelExperiencia']),
        certificaciones: List<String>.from(json['certificaciones']),
        capacidades: List<String>.from(json['capacidades']),
        tarifaPorHora: (json['tarifaPorHora'] as num).toDouble(),
        ubicacion: json['ubicacion'],
        diasDisponibles: List<String>.from(json['diasDisponibles']),
        horarioDisponible: json['horarioDisponible'],
        calificacionPromedio:
            (json['calificacionPromedio'] as num?)?.toDouble() ?? 0.0,
        totalServicios: json['totalServicios'] ?? 0,
        verificado: json['verificado'] ?? false,
      );
}
