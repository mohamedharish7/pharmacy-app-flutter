import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class SalesLogScreen extends StatefulWidget {
  const SalesLogScreen({super.key});

  @override
  State<SalesLogScreen> createState() => _SalesLogScreenState();
}

class _SalesLogScreenState extends State<SalesLogScreen> {
  final _api = ApiService();
  List<Sale> _sales = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sales = await _api.getSales();
      setState(() {
        _sales = sales;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales log')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text("Couldn't load sales log.\n$_error", textAlign: TextAlign.center));
    }
    if (_sales.isEmpty) {
      return const Center(child: Text('No sales recorded yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sales.length,
        separatorBuilder: (_, __) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final s = _sales[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('MMM d, yyyy \u00b7 h:mm a').format(s.saleDate.toLocal())} \u00b7 ${s.quantitySold} unit(s) @ \u20b9${s.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Text(
                '\u20b9${s.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          );
        },
      ),
    );
  }
}
