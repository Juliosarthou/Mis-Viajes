import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _viajes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    final data = await _dbService.getHistorialViajes();
    setState(() {
      _viajes = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Viajes Finalizados",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          Expanded(
            child: _viajes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _viajes.length,
                    itemBuilder: (context, index) => _buildViajeCard(_viajes[index]),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
        ],
      ),
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final df = DateFormat('dd/MM/yyyy');
    final start = DateTime.parse(viaje['fecha_desde']);
    final end = DateTime.parse(viaje['fecha_hasta']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _viewDetalleViaje(viaje),
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(viaje['nombre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text("${df.format(start)} - ${df.format(end)}", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text("Ver detalles", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _viewDetalleViaje(Map<String, dynamic> viaje) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleHistorialSheet(viaje: viaje),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No hay viajes en el historial", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _DetalleHistorialSheet extends StatefulWidget {
  final Map<String, dynamic> viaje;
  const _DetalleHistorialSheet({required this.viaje});

  @override
  State<_DetalleHistorialSheet> createState() => _DetalleHistorialSheetState();
}

class _DetalleHistorialSheetState extends State<_DetalleHistorialSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _itinerarios = [];
  List<Map<String, dynamic>> _gastos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetalles();
  }

  Future<void> _loadDetalles() async {
    final iti = await _dbService.getItinerariosByDestino(widget.viaje['id']);
    final gas = await _dbService.getGastosByDestino(widget.viaje['id']);
    setState(() {
      _itinerarios = iti;
      _gastos = gas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: "ITINERARIO", icon: Icon(Icons.event_note_rounded)),
              Tab(text: "GASTOS", icon: Icon(Icons.payments_rounded)),
            ],
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItinerarioList(),
                    _buildGastosView(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40, height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.viaje['nombre'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(widget.viaje['detalle'] ?? "", style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItinerarioList() {
    if (_itinerarios.isEmpty) return const Center(child: Text("Sin itinerario"));
    final start = DateTime.parse(widget.viaje['fecha_desde']);
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _itinerarios.length,
      itemBuilder: (context, index) {
        final item = _itinerarios[index];
        final fecha = start.add(Duration(days: item['dia_numero'] - 1));
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text("Día ${item['dia_numero']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(DateFormat('dd/MM').format(fecha), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(item['detalle']?.isEmpty ?? true ? "Sin actividades registradas" : item['detalle'], 
                  style: const TextStyle(fontSize: 15, height: 1.4)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGastosView() {
    if (_gastos.isEmpty) return const Center(child: Text("Sin gastos registrados"));
    
    // Calcular datos para el resumen
    Map<String, Map<String, dynamic>> resumen = {};
    double total = 0.0;
    
    for (var g in _gastos) {
      String rubro = g['rubro_nombre'];
      double monto = g['monto'] as double;
      total += monto;

      if (!resumen.containsKey(rubro)) {
        resumen[rubro] = {
          'total': 0.0,
          'icono': g['rubro_icono'],
        };
      }
      resumen[rubro]!['total'] = (resumen[rubro]!['total'] as double) + monto;
    }

    final sortedItems = resumen.entries.toList()
      ..sort((a, b) => (b.value['total'] as double).compareTo(a.value['total'] as double));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Card de Total Premium (Ajustada a menor tamaño)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "GASTO TOTAL",
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(symbol: r'$').format(total),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${_gastos.length} transacciones registradas",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        const Text(
          "DISTRIBUCIÓN POR RUBRO",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        
        // Listado de Rubros con Porcentaje
        ...sortedItems.map((e) {
          final monto = e.value['total'] as double;
          final porcentaje = total > 0 ? (monto / total * 100) : 0.0;
          final iconData = AppIcons.getIcon(e.value['icono']?.toString());
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            NumberFormat.currency(symbol: r'$').format(monto),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${porcentaje.toStringAsFixed(1)}% del gasto total",
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 24),

        const Text(
          "DETALLE CRONOLÓGICO",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        
        // Lista de gastos detallada
        ..._gastos.map((g) {
          final iconData = AppIcons.getIcon(g['rubro_icono']?.toString());
          final dt = DateTime.parse(g['fecha']);
          final fechaFormat = DateFormat('dd MMM, yyyy • HH:mm').format(dt);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: AppColors.primary.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['detalle']?.isEmpty ?? true ? g['rubro_nombre'] : g['detalle'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$fechaFormat • ${g['rubro_nombre']}",
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: r'$').format(g['monto']),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 40),
      ],
    );
  }
}
