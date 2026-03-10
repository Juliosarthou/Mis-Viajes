class Itinerario {
  final int? id;
  final int destinoId;
  final int diaNumero;
  final String? detalle;
  final String? fechaEspecifica;
  final String? createdAt;

  Itinerario({
    this.id,
    required this.destinoId,
    required this.diaNumero,
    this.detalle,
    this.fechaEspecifica,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destino_id': destinoId,
      'dia_numero': diaNumero,
      'detalle': detalle,
      'fecha_especifica': fechaEspecifica,
      'created_at': createdAt,
    };
  }

  factory Itinerario.fromMap(Map<String, dynamic> map) {
    return Itinerario(
      id: map['id'],
      destinoId: map['destino_id'],
      diaNumero: map['dia_numero'],
      detalle: map['detalle'],
      fechaEspecifica: map['fecha_especifica'],
      createdAt: map['created_at'],
    );
  }
}
