import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import 'sales_log_screen.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/add_edit_medicine_dialog.dart';
import '../widgets/sell_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();

  List<Medicine> _medicines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meds = await _api.getMedicines(search: search);
      setState(() {
        _medicines = meds;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _openAddEdit({Medicine? medicine}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AddEditMedicineDialog(medicine: medicine),
    );
    if (result == true) {
      _showSnack(medicine == null ? 'Medicine added.' : 'Medicine updated.');
      _loadMedicines(search: _searchController.text);
    }
  }

  Future<void> _openSell(Medicine medicine) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SellDialog(medicine: medicine),
    );
    if (result == true) {
      _showSnack('Sale recorded.');
      _loadMedicines(search: _searchController.text);
    }
  }

  Future<void> _confirmDelete(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove medicine?'),
        content: Text('Remove "${medicine.fullName}" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteMedicine(medicine.id);
        _showSnack('Medicine removed.');
        _loadMedicines(search: _searchController.text);
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('\u211e', style: TextStyle(fontSize: 22, color: Color(0xFF0E6B57), fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Text('ABC Pharmacy'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Sales log',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesLogScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by medicine name or brand\u2026',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
              onChanged: (value) => _loadMedicines(search: value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _legendDot(const Color(0xFFF5E0DD), const Color(0xFFA53F37)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Expiring < 30 days', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ),
                _legendDot(const Color(0xFFFAEED4), const Color(0xFFA67322)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Low stock (< 10)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
    );
  }

  Widget _legendDot(Color fill, Color border) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: Colors.black38),
              const SizedBox(height: 12),
              Text("Couldn't reach the server.\n$_error", textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _loadMedicines(search: _searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_medicines.isEmpty) {
      return const Center(child: Text('No medicines match your search.'));
    }
    return RefreshIndicator(
      onRefresh: () => _loadMedicines(search: _searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
        itemCount: _medicines.length,
        itemBuilder: (context, index) {
          final med = _medicines[index];
          return MedicineTile(
            medicine: med,
            onSell: () => _openSell(med),
            onEdit: () => _openAddEdit(medicine: med),
            onDelete: () => _confirmDelete(med),
          );
        },
      ),
    );
  }
}
