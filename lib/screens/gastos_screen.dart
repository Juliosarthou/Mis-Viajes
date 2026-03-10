import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import 'package:intl/intl.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _nextDestino;
  List<Map<String, dynamic>> _gastos = [];
  List<Map<String, dynamic>> _rubros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final destino = await _dbService.getNextDestino();
    final rubros = await _dbService.getRubros();
    
    if (destino != null) {
      final gastos = await _dbService.getGastosByDestino(destino['id']);
      setState(() {
        _nextDestino = destino;
        _gastos = gastos;
        _rubros = rubros;
        _isLoading = false;
      });
    } else {
      setState(() {
        _nextDestino = null;
        _rubros = rubros;
        _isLoading = false;
      });
    }
  }

  void _showGastoSheet({Map<String, dynamic>? gasto}) {
    if (_nextDestino == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("Sin Viaje Activo"),
            ],
          ),
          content: const Text("No hay un viaje próximo configurado para registrar gastos. Crea un destino primero."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (_rubros.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Text("Faltan Rubros"),
            ],
          ),
          content: const Text("Primero debes crear rubros poder registrar gastos."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GastoEditSheet(
        gasto: gasto,
        rubros: _rubros,
        destino: _nextDestino!,
        onDelete: gasto == null ? null : () async {
          await _dbService.deleteGasto(gasto['id']);
          _loadData();
          if (mounted) Navigator.pop(context);
        },
        onSave: (data) async {
          if (gasto == null) {
            await _dbService.insertGasto({
              ...data,
              'destino_id': _nextDestino!['id'],
            });
          } else {
            await _dbService.updateGasto({
              'id': gasto['id'],
              'destino_id': _nextDestino!['id'],
              ...data
            });
          }
          _loadData();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showSummaryByRubro() {
    if (_gastos.isEmpty) return;

    // Calcular totales por rubro
    Map<String, Map<String, dynamic>> resumen = {};
    double totalGeneral = 0;

    for (var gasto in _gastos) {
      String rubro = gasto['rubro_nombre'];
      double monto = gasto['monto'] as double;
      totalGeneral += monto;

      if (!resumen.containsKey(rubro)) {
        resumen[rubro] = {
          'total': 0.0,
          'icono': gasto['rubro_icono'],
        };
      }
      resumen[rubro]!['total'] = (resumen[rubro]!['total'] as double) + monto;
    }

    final sortedKeys = resumen.keys.toList()
      ..sort((a, b) => (resumen[b]!['total'] as double).compareTo(resumen[a]!['total'] as double));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen por Rubros",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final rubro = sortedKeys[index];
                  final data = resumen[rubro]!;
                  final monto = data['total'] as double;
                  final porcentaje = (monto / totalGeneral) * 100;

                  IconData iconData = AppIcons.getIcon(data['icono']?.toString());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Icon(iconData, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(rubro, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    NumberFormat.currency(symbol: r'$').format(monto),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: porcentaje / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: AppColors.primary.withOpacity(0.7),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${porcentaje.toStringAsFixed(1)}% del total",
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL VIAJE", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                Text(
                  NumberFormat.currency(symbol: r'$').format(totalGeneral),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSummary(),
          Expanded(
            child: _nextDestino == null
                ? _buildNoTripState()
                : _gastos.isEmpty
                    ? _buildEmptyState()
                    : _buildGastosList(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Gastos de Viaje",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                if (_nextDestino != null)
                  Row(
                    children: [
                      Text(
                        _nextDestino!['nombre'],
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showSummaryByRubro,
                        icon: const Icon(Icons.pie_chart_rounded, size: 20, color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        tooltip: "Ver resumen por rubros",
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_nextDestino != null)
            TextButton.icon(
              onPressed: () => _showGastoSheet(),
              icon: const Icon(Icons.add_card_rounded, size: 20),
              label: const Text("Nuevo Gasto"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    if (_gastos.isEmpty) return const SizedBox.shrink();
    
    double total = _gastos.fold(0, (sum, item) => sum + (item['monto'] as double));
    
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL GASTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(
            NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(total),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGastosList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _gastos.length,
      itemBuilder: (context, index) {
        final gasto = _gastos[index];
        return _buildGastoCard(gasto);
      },
    );
  }

  Widget _buildGastoCard(Map<String, dynamic> gasto) {
    final df = DateFormat('dd/MM/yyyy');
    final fecha = DateTime.parse(gasto['fecha']);
    
    IconData iconData = AppIcons.getIcon(gasto['rubro_icono']?.toString());

    return Dismissible(
      key: Key(gasto['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _dbService.deleteGasto(gasto['id']);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          onTap: () => _showGastoSheet(gasto: gasto),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Icon(iconData, color: AppColors.primary, size: 24),
          ),
          title: Text(gasto['detalle']?.isEmpty ?? true ? gasto['rubro_nombre'] : gasto['detalle'], 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            "${df.format(fecha)} • ${gasto['rubro_nombre']}",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Text(
            NumberFormat.currency(symbol: r'$').format(gasto['monto']),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTripState() {
    return const Center(child: Text("No hay viajes próximos activos."));
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No has registrado gastos en este viaje."));
  }
}

class _GastoEditSheet extends StatefulWidget {
  final Map<String, dynamic>? gasto;
  final List<Map<String, dynamic>> rubros;
  final Map<String, dynamic> destino; // Pasamos el destino para las fechas
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete; // Callback opcional para borrar

  const _GastoEditSheet({
    this.gasto, 
    required this.rubros, 
    required this.destino,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_GastoEditSheet> createState() => _GastoEditSheetState();
}

class _GastoEditSheetState extends State<_GastoEditSheet> {
  final _montoController = TextEditingController();
  final _detalleController = TextEditingController();
  int? _rubroId;
  String _fecha = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    if (widget.gasto != null) {
      _montoController.text = widget.gasto!['monto'].toString();
      _detalleController.text = widget.gasto!['detalle'] ?? '';
      _rubroId = widget.gasto!['rubro_id'];
      _fecha = widget.gasto!['fecha'];
    } else {
      _rubroId = widget.rubros.isNotEmpty ? widget.rubros.first['id'] : null;
      
      final hoy = DateTime.now();
      final hoyStr = hoy.toIso8601String().split('T')[0];
      final hoyDate = DateTime.parse(hoyStr);
      
      final inicioViaje = DateTime.parse(widget.destino['fecha_desde']);
      final finViaje = DateTime.parse(widget.destino['fecha_hasta']);

      // Si hoy está fuera del rango del viaje, usamos la fecha inicial.
      // Si hoy está dentro, usamos hoy.
      if (hoyDate.isBefore(inicioViaje) || hoyDate.isAfter(finViaje)) {
        _fecha = widget.destino['fecha_desde'];
      } else {
        _fecha = hoyStr;
      }
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar gasto?"),
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

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
      ),
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.gasto == null ? "Nuevo Gasto" : "Editar Gasto", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)
                ),
                if (widget.gasto != null)
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: "Monto", prefixText: r"$ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _rubroId,
              decoration: InputDecoration(labelText: "Rubro", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              items: widget.rubros.map((r) => DropdownMenuItem<int>(value: r['id'], child: Text(r['nombre']))).toList(),
              onChanged: (val) => setState(() => _rubroId = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detalleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Detalle (Opcional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final DateTime inicioViaje = DateTime.parse(widget.destino['fecha_desde']);
                final DateTime finViaje = DateTime.parse(widget.destino['fecha_hasta']);
                
                DateTime currentSelected = DateTime.parse(_fecha);
                
                // Ajustar currentSelected si por alguna razón está fuera del rango del viaje
                if (currentSelected.isBefore(inicioViaje)) currentSelected = inicioViaje;
                if (currentSelected.isAfter(finViaje)) currentSelected = finViaje;

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: currentSelected,
                  firstDate: inicioViaje,
                  lastDate: finViaje,
                  helpText: "Selecciona la fecha del gasto",
                );
                if (picked != null) {
                  setState(() {
                    _fecha = picked.toIso8601String().split('T')[0];
                  });
                }
              },
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text("Fecha del Gasto: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_fecha))}"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final monto = double.tryParse(_montoController.text);
                  if (monto != null && _rubroId != null) {
                    widget.onSave({
                      'monto': monto,
                      'rubro_id': _rubroId,
                      'detalle': _detalleController.text,
                      'fecha': _fecha,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Guardar Gasto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
