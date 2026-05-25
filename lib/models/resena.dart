class Resena {
  final String id;
  final String citaId;
  final String autorId;
  final String autorNombre;
  final String destinatarioId;
  final double calificacion;
  final String comentario;
  final bool esPrivada; // RF15: las notas del cuidador son privadas
  final DateTime createdAt;

  Resena({
    required this.id,
    required this.citaId,
    required this.autorId,
    required this.autorNombre,
    required this.destinatarioId,
    required this.calificacion,
    required this.comentario,
    required this.esPrivada,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'citaId': citaId,
        'autorId': autorId,
        'autorNombre': autorNombre,
        'destinatarioId': destinatarioId,
        'calificacion': calificacion,
        'comentario': comentario,
        'esPrivada': esPrivada,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        id: json['id'],
        citaId: json['citaId'],
        autorId: json['autorId'],
        autorNombre: json['autorNombre'],
        destinatarioId: json['destinatarioId'],
        calificacion: (json['calificacion'] as num).toDouble(),
        comentario: json['comentario'],
        esPrivada: json['esPrivada'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
