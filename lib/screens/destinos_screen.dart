import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class DestinosScreen extends StatefulWidget {
  const DestinosScreen({super.key});

  @override
  State<DestinosScreen> createState() => DestinosScreenState();
}

class DestinosScreenState extends State<DestinosScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _destinos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() {
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _dbService.getProximosDestinos();
    setState(() {
      _destinos = data;
      _isLoading = false;
    });
  }

  void _editDestino(Map<String, dynamic> destino) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDestinoSheet(
        destino: destino,
        onSave: (updatedData) async {
          if (updatedData.isNotEmpty) {
            await _dbService.updateDestino(updatedData);
          }
          _loadData();
          if (mounted) Navigator.pop(context);
        },
      ),
    ).then((_) => _loadData()); // Refrescar siempre al cerrar el modal
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _destinos.length,
      itemBuilder: (context, index) {
        return _buildDestinoCard(_destinos[index]);
      },
    );
  }

  Widget _buildDestinoCard(Map<String, dynamic> item) {
    final df = DateFormat('dd/MM/yyyy');
    final fechaDesde = DateTime.parse(item['fecha_desde']);
    final fechaHasta = DateTime.parse(item['fecha_hasta']);

    return GestureDetector(
      onTap: () => _editDestino(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['nombre'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              if (item['detalle'] != null && item['detalle'].toString().isNotEmpty)
                Text(
                  item['detalle'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "${df.format(fechaDesde)} - ${df.format(fechaHasta)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDestinoSheet extends StatefulWidget {
  final Map<String, dynamic> destino;
  final Function(Map<String, dynamic>) onSave;

  const _EditDestinoSheet({required this.destino, required this.onSave});

  @override
  State<_EditDestinoSheet> createState() => _EditDestinoSheetState();
}

class _EditDestinoSheetState extends State<_EditDestinoSheet> {
  late TextEditingController _nombreController;
  late TextEditingController _detalleController;
  late String _fechaDesde;
  late String _fechaHasta;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.destino['nombre']);
    _detalleController = TextEditingController(text: widget.destino['detalle']);
    _fechaDesde = widget.destino['fecha_desde'];
    _fechaHasta = widget.destino['fecha_hasta'];
  }

  Future<void> _selectDate(bool start) async {
    final DateTime initialDate = DateTime.parse(start ? _fechaDesde : _fechaHasta);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _fechaDesde = picked.toIso8601String().split('T')[0];
        } else {
          _fechaHasta = picked.toIso8601String().split('T')[0];
        }
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final dbService = DatabaseService();
    final bool hasData = await dbService.hasRelationedData(widget.destino['id']);

    if (hasData) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No se puede eliminar"),
          content: const Text("Este destino tiene gastos o itinerarios asociados. Debes eliminarlos primero."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("¿Eliminar destino?"),
          content: const Text("Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text("Eliminar"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await dbService.deleteDestino(widget.destino['id']);
        if (!mounted) return;
        Navigator.pop(context); // Cierra BottomSheet
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Editar Destino",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Nombre del Destino",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detalleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Detalles",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(true),
                    icon: const Icon(Icons.date_range),
                    label: Text("Desde: ${DateFormat('dd/MM/yy').format(DateTime.parse(_fechaDesde))}"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(false),
                    icon: const Icon(Icons.date_range),
                    label: Text("Hasta: ${DateFormat('dd/MM/yy').format(DateTime.parse(_fechaHasta))}"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  final DateTime start = DateTime.parse(_fechaDesde);
                  final DateTime end = DateTime.parse(_fechaHasta);

                  // 1. Validar orden de fechas
                  if (end.isBefore(start)) {
                    _showAlert("Fecha Inválida", "La fecha de regreso no puede ser anterior a la fecha de inicio.");
                    return;
                  }

                  // 2. Validar superposición (excluyendo este mismo destino)
                  final overlap = await DatabaseService().checkOverlap(
                    _fechaDesde, 
                    _fechaHasta, 
                    excludeId: widget.destino['id']
                  );
                  if (overlap != null) {
                    _showAlert("Viaje Superpuesto", "Las fechas coinciden con otro viaje: ${overlap['nombre']}");
                    return;
                  }

                  final updatedData = {
                    'id': widget.destino['id'],
                    'nombre': _nombreController.text,
                    'detalle': _detalleController.text,
                    'fecha_desde': _fechaDesde,
                    'fecha_hasta': _fechaHasta,
                  };
                  await DatabaseService().updateDestino(updatedData);
                  await DatabaseService().syncItinerarios(
                    widget.destino['id'],
                    _fechaDesde,
                    _fechaHasta,
                  );
                  widget.onSave({}); // Refrescar lista
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Guardar Cambios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
