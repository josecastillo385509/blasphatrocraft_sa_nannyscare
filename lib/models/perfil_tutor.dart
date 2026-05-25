class Hijo {
  final String nombre;
  final int edad;
  final String? necesidadesEspeciales;

  Hijo({
    required this.nombre,
    required this.edad,
    this.necesidadesEspeciales,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'edad': edad,
        'necesidadesEspeciales': necesidadesEspeciales,
      };

  factory Hijo.fromJson(Map<String, dynamic> json) => Hijo(
        nombre: json['nombre'],
        edad: json['edad'],
        necesidadesEspeciales: json['necesidadesEspeciales'],
      );
}

class PerfilTutor {
  final String userId;
  final String direccion;
  final List<Hijo> hijos;
  final String necesidadesGenerales;

  PerfilTutor({
    required this.userId,
    required this.direccion,
    required this.hijos,
    required this.necesidadesGenerales,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'direccion': direccion,
        'hijos': hijos.map((h) => h.toJson()).toList(),
        'necesidadesGenerales': necesidadesGenerales,
      };

  factory PerfilTutor.fromJson(Map<String, dynamic> json) => PerfilTutor(
        userId: json['userId'],
        direccion: json['direccion'],
        hijos: (json['hijos'] as List).map((h) => Hijo.fromJson(h)).toList(),
        necesidadesGenerales: json['necesidadesGenerales'],
      );
}
