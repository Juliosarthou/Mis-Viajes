import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class ItinerariosScreen extends StatefulWidget {
  const ItinerariosScreen({super.key});

  @override
  State<ItinerariosScreen> createState() => _ItinerariosScreenState();
}

class _ItinerariosScreenState extends State<ItinerariosScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _destinos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _dbService.getProximosDestinos();
    setState(() {
      _destinos = data;
      _isLoading = false;
    });
  }

  void _openGestionItinerario(Map<String, dynamic> destino) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionItinerarioDetail(destino: destino),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_destinos.isEmpty) {
      return const Center(child: Text("No hay destinos próximos para crear itinerarios."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _destinos.length,
      itemBuilder: (context, index) {
        final item = _destinos[index];
        return _buildDestinoItinerarioCard(item);
      },
    );
  }

  Widget _buildDestinoItinerarioCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openGestionItinerario(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nombre'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gestionar Itinerario",
                    style: TextStyle(fontSize: 14, color: AppColors.primary.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class GestionItinerarioDetail extends StatefulWidget {
  final Map<String, dynamic> destino;
  const GestionItinerarioDetail({super.key, required this.destino});

  @override
  State<GestionItinerarioDetail> createState() => _GestionItinerarioDetailState();
}

class _GestionItinerarioDetailState extends State<GestionItinerarioDetail> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _itinerarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItinerarios();
  }

  Future<void> _loadItinerarios() async {
    final data = await _dbService.getItinerariosByDestino(widget.destino['id']);
    setState(() {
      _itinerarios = data;
      _isLoading = false;
    });
  }

  Future<void> _generarItinerarioAutomatico() async {
    await _dbService.syncItinerarios(
      widget.destino['id'],
      widget.destino['fecha_desde'],
      widget.destino['fecha_hasta'],
    );
    _loadItinerarios();
  }

  void _editDia(Map<String, dynamic> itinerario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDiaSheet(
        itinerario: itinerario,
        onSave: (updatedData) async {
          await _dbService.updateItinerario(updatedData);
          _loadItinerarios();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.destino['nombre']),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_itinerarios.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No hay itinerarios para este destino."),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _generarItinerarioAutomatico,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text("Generar Itinerario Automático"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _itinerarios.length,
                      itemBuilder: (context, index) {
                        final item = _itinerarios[index];
                        return _buildDiaCard(item);
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDiaCard(Map<String, dynamic> item) {
    final DateTime start = DateTime.parse(widget.destino['fecha_desde']);
    final DateTime fechaDia = start.add(Duration(days: (item['dia_numero'] as int) - 1));
    final fecha = DateFormat('dd/MM/yyyy').format(fechaDia);
    return GestureDetector(
      onTap: () => _editDia(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
          ],
        ),
        child: ListTile(
          title: Text("Día ${item['dia_numero']} - $fecha",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          subtitle: Text(
            item['detalle'] != null && item['detalle'].toString().isNotEmpty
                ? item['detalle']
                : "Sin detalles asignados",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EditDiaSheet extends StatefulWidget {
  final Map<String, dynamic> itinerario;
  final Function(Map<String, dynamic>) onSave;

  const _EditDiaSheet({required this.itinerario, required this.onSave});

  @override
  State<_EditDiaSheet> createState() => _EditDiaSheetState();
}

class _EditDiaSheetState extends State<_EditDiaSheet> {
  late TextEditingController _detalleController;

  @override
  void initState() {
    super.initState();
    _detalleController = TextEditingController(text: widget.itinerario['detalle']);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Editar Día ${widget.itinerario['dia_numero']}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _detalleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: "Detalle del itinerario",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave({
                  'id': widget.itinerario['id'],
                  'destino_id': widget.itinerario['destino_id'],
                  'dia_numero': widget.itinerario['dia_numero'],
                  'detalle': _detalleController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Guardar Itinerario", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
