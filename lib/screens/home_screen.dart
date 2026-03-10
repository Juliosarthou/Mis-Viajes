import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _itinerarios = [];
  Map<String, dynamic>? _nextDestino;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final itinerarios = await _dbService.getProximosItinerarios();
    final destino = await _dbService.getNextDestino();
    setState(() {
      _itinerarios = itinerarios;
      _nextDestino = destino;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_nextDestino != null) 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildNextDestinoSection(),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Itinerario",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_itinerarios.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: Text("No hay itinerarios registrados.")),
                )
              else
                ..._itinerarios.map((item) => _buildItinerarioCard(item)).toList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextDestinoSection() {
    final df = DateFormat('dd/MM/yyyy');
    final fechaDesde = DateTime.parse(_nextDestino!['fecha_desde']);
    final fechaHasta = DateTime.parse(_nextDestino!['fecha_hasta']);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              const Icon(Icons.flight_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "PRÓXIMO DESTINO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _nextDestino!['nombre'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "${df.format(fechaDesde)} - ${df.format(fechaHasta)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarioCard(Map<String, dynamic> item) {
    final DateTime start = DateTime.parse(item['fecha_desde']);
    final DateTime fecha = start.add(Duration(days: (item['dia_numero'] as int) - 1));
    final DateTime hoy = DateTime.now();
    final bool isPassed = fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isPassed ? AppColors.error : AppColors.success,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Día ${item['dia_numero']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(fecha),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (item['detalle'] != null && item['detalle'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['detalle'] ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
