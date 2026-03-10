class Destino {
  final int? id;
  final String nombre;
  final String? detalle;
  final String fechaDesde;
  final String fechaHasta;
  final String? createdAt;

  Destino({
    this.id,
    required this.nombre,
    this.detalle,
    required this.fechaDesde,
    required this.fechaHasta,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'detalle': detalle,
      'fecha_desde': fechaDesde,
      'fecha_hasta': fechaHasta,
      'created_at': createdAt,
    };
  }

  factory Destino.fromMap(Map<String, dynamic> map) {
    return Destino(
      id: map['id'],
      nombre: map['nombre'],
      detalle: map['detalle'],
      fechaDesde: map['fecha_desde'],
      fechaHasta: map['fecha_hasta'],
      createdAt: map['created_at'],
    );
  }
}
