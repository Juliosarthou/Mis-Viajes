import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'screens/destinos_screen.dart';
import 'screens/itinerarios_screen.dart';
import 'services/database_service.dart';
import 'package:intl/intl.dart';
import 'screens/rubros_screen.dart';
import 'screens/gastos_screen.dart';
import 'screens/historial_screen.dart';
import 'package:file_picker/file_picker.dart';

import 'services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Realizar backup automático diario
  await BackupService.checkAndCreateDailyBackup();
  
  runApp(const ViajesApp());
}

class ViajesApp extends StatelessWidget {
  const ViajesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Viajes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      builder: (context, child) {
        return MediaQuery(
          // Limitamos el escalado de texto para evitar que rompa el diseño en fuentes muy grandes
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2)),
          ),
          child: child!,
        );
      },
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<_MainNavigationState> _navKey = GlobalKey();
  
  // Usamos llaves para poder refrescar los estados de las pantallas si es necesario
  final GlobalKey<DestinosScreenState> _destinosKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      DestinosScreen(key: _destinosKey),
      const GastosScreen(),
      const ItinerariosScreen(),
      const RubrosScreen(),
      const HistorialScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildCommonHeader(context),
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),
          _buildFloatingNavbar(),
          if (_selectedIndex == 1) _buildAddDestinoButton(),
        ],
      ),
    );
  }

  Widget _buildCommonHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 15, 
        bottom: 25, 
        left: 24, 
        right: 24
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Anclaje Izquierdo (Avión)
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          // Centro (Título)
          const Expanded(
            child: Text(
              "Mis Viajes",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Anclaje Derecho (Engranaje)
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _showSettingsSheet(context),
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
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
              "Configuración de Datos",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 28),
              title: const Text("Exportar Base de Datos (SQL)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Crea un respaldo con fecha y hora actual en Descargas"),
              onTap: () async {
                Navigator.pop(context);
                final res = await BackupService.createManualBackup();
                if (mounted) {
                  _showResultDialog("Exportación Finalizada", res);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download_rounded, color: AppColors.primary, size: 28),
              title: const Text("Importar Base de Datos (SQL)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Busca un archivo .sql para restaurar datos"),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['sql'],
                );

                if (result != null && result.files.single.path != null) {
                  final res = await BackupService.importSqlFile(result.files.single.path!);
                  if (mounted) {
                    _showResultDialog("Resultado de Importación", res);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavbar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navbarItem(0, Icons.home_rounded, "Inicio"),
            _navbarItem(1, Icons.map_rounded, "Destino"),
            _navbarItem(2, Icons.wallet_rounded, "Gastos"),
            _navbarItem(3, Icons.event_note_rounded, "Itinerarios"),
            _navbarItem(4, Icons.category_rounded, "Rubros"),
            _navbarItem(5, Icons.history_rounded, "Historial"),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDestinoButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100, // Arriba del menu flotante
      right: 20,
      child: FloatingActionButton(
        onPressed: _showAddDestinoSheet,
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void _showAddDestinoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewDestinoSheet(
        onSave: (newData) async {
          await DatabaseService().insertDestino(newData);
          if (_selectedIndex == 1) {
            _destinosKey.currentState?.reload();
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _navbarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewDestinoSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _NewDestinoSheet({required this.onSave});

  @override
  State<_NewDestinoSheet> createState() => _NewDestinoSheetState();
}

class _NewDestinoSheetState extends State<_NewDestinoSheet> {
  final _nombreController = TextEditingController();
  final _detalleController = TextEditingController();
  String _fechaDesde = DateTime.now().toIso8601String().split('T')[0];
  String _fechaHasta = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];

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
            const Text(
              "Nuevo Destino",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                  if (_nombreController.text.isNotEmpty) {
                    final DateTime start = DateTime.parse(_fechaDesde);
                    final DateTime end = DateTime.parse(_fechaHasta);

                    // 0. Debug log
                    await DatabaseService().debugLogDestinos();

                    // 1. Validar orden de fechas
                    if (end.isBefore(start)) {
                      _showAlert("Fecha Inválida", "La fecha de regreso no puede ser anterior a la fecha de inicio.");
                      return;
                    }

                    // 2. Validar superposición de viajes
                    final overlap = await DatabaseService().checkOverlap(_fechaDesde, _fechaHasta);
                    if (overlap != null) {
                      _showAlert("Viaje Superpuesto", "Las fechas coinciden con otro viaje: ${overlap['nombre']}");
                      return;
                    }

                    widget.onSave({
                      'nombre': _nombreController.text,
                      'detalle': _detalleController.text,
                      'fecha_desde': _fechaDesde,
                      'fecha_hasta': _fechaHasta,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Agregar Destino", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
