class Gasto {
  final int? id;
  final int destinoId;
  final int rubroId;
  final double monto;
  final String moneda;
  final String? detalle;
  final String fecha;
  final String? createdAt;

  Gasto({
    this.id,
    required this.destinoId,
    required this.rubroId,
    required this.monto,
    this.moneda = 'ARS',
    this.detalle,
    required this.fecha,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destino_id': destinoId,
      'rubro_id': rubroId,
      'monto': monto,
      'moneda': moneda,
      'detalle': detalle,
      'fecha': fecha,
      'created_at': createdAt,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'],
      destinoId: map['destino_id'],
      rubroId: map['rubro_id'],
      monto: map['monto'] is int ? (map['monto'] as int).toDouble() : map['monto'],
      moneda: map['moneda'],
      detalle: map['detalle'],
      fecha: map['fecha'],
      createdAt: map['created_at'],
    );
  }
}
