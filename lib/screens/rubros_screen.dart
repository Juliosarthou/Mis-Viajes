import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_icons.dart';

class RubrosScreen extends StatefulWidget {
  const RubrosScreen({super.key});

  @override
  State<RubrosScreen> createState() => _RubrosScreenState();
}

class _RubrosScreenState extends State<RubrosScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _rubros = [];
  bool _isLoading = true;

  final List<IconData> _availableIcons = AppIcons.availableIcons;

  @override
  void initState() {
    super.initState();
    _loadRubros();
  }

  Future<void> _loadRubros() async {
    final data = await _dbService.getRubros();
    setState(() {
      _rubros = data;
      _isLoading = false;
    });
  }

  void _showRubroSheet({Map<String, dynamic>? rubro}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RubroEditSheet(
        rubro: rubro,
        availableIcons: _availableIcons,
        onSave: (data) async {
          if (rubro == null) {
            await _dbService.insertRubro(data);
          } else {
            await _dbService.updateRubro({'id': rubro['id'], ...data});
          }
          _loadRubros();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteRubro(Map<String, dynamic> rubro) async {
    final bool hasExpenses = await _dbService.hasRubroExpenses(rubro['id']);
    
    if (hasExpenses) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No se puede eliminar"),
          content: Text("El rubro '${rubro['nombre']}' tiene gastos asociados. Debes eliminarlos primero."),
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
          title: const Text("¿Eliminar rubro?"),
          content: Text("¿Estás seguro de que quieres eliminar '${rubro['nombre']}'?"),
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
        await _dbService.deleteRubro(rubro['id']);
        _loadRubros();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rubros de Gastos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRubroSheet(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Nuevo"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _rubros.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rubros.length,
                    itemBuilder: (context, index) {
                      final rubro = _rubros[index];
                      return _buildRubroCard(rubro);
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 120), // Espacio para el menu flotante
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "No hay rubros creados",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Crea rubros para organizar tus gastos",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRubroCard(Map<String, dynamic> rubro) {
    IconData iconData = AppIcons.getIcon(rubro['icono']?.toString());

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(iconData, color: AppColors.primary),
        ),
        title: Text(
          rubro['nombre'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showRubroSheet(rubro: rubro),
              color: AppColors.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => _deleteRubro(rubro),
              color: AppColors.error.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _RubroEditSheet extends StatefulWidget {
  final Map<String, dynamic>? rubro;
  final List<IconData> availableIcons;
  final Function(Map<String, dynamic>) onSave;

  const _RubroEditSheet({
    this.rubro,
    required this.availableIcons,
    required this.onSave,
  });

  @override
  State<_RubroEditSheet> createState() => _RubroEditSheetState();
}

class _RubroEditSheetState extends State<_RubroEditSheet> {
  late TextEditingController _nombreController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.rubro?['nombre'] ?? '');
    
    _selectedIcon = AppIcons.getIcon(widget.rubro?['icono']?.toString());
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
            Text(
              widget.rubro == null ? "Nuevo Rubro" : "Editar Rubro",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Nombre del Rubro",
                hintText: "Comida, Transporte...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            const Text(
              "Seleccionar Icono",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: widget.availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = widget.availableIcons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_nombreController.text.isNotEmpty) {
                    widget.onSave({
                      'nombre': _nombreController.text,
                      'icono': _selectedIcon.codePoint.toString(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Guardar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
