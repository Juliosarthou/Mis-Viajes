class RubroViaje {
  final int? id;
  final String nombre;
  final String icono;
  final String? createdAt;

  RubroViaje({
    this.id,
    required this.nombre,
    this.icono = 'fas fa-tag',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'created_at': createdAt,
    };
  }

  factory RubroViaje.fromMap(Map<String, dynamic> map) {
    return RubroViaje(
      id: map['id'],
      nombre: map['nombre'],
      icono: map['icono'] ?? 'fas fa-tag',
      createdAt: map['created_at'],
    );
  }
}
