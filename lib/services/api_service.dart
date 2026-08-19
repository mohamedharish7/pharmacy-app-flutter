import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/medicine.dart';
import '../models/sale.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$apiBaseUrl/api$path').replace(queryParameters: query);
  }

  Future<List<Medicine>> getMedicines({String? search}) async {
    final query = (search != null && search.trim().isNotEmpty)
        ? {'search': search.trim()}
        : null;
    final res = await http.get(_uri('/medicines', query));
    _checkOk(res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Medicine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Medicine> addMedicine(Medicine medicine) async {
    final res = await http.post(
      _uri('/medicines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(medicine.toRequestJson()),
    );
    _checkOk(res, okCodes: const [200, 201]);
    return Medicine.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Medicine> updateMedicine(String id, Medicine medicine) async {
    final res = await http.put(
      _uri('/medicines/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(medicine.toRequestJson()),
    );
    _checkOk(res);
    return Medicine.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteMedicine(String id) async {
    final res = await http.delete(_uri('/medicines/$id'));
    _checkOk(res, okCodes: const [200, 204]);
  }

  Future<List<Sale>> getSales() async {
    final res = await http.get(_uri('/sales'));
    _checkOk(res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Sale> recordSale({required String medicineId, required int quantitySold}) async {
    final res = await http.post(
      _uri('/sales'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'medicineId': medicineId, 'quantitySold': quantitySold}),
    );
    _checkOk(res, okCodes: const [200, 201]);
    return Sale.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _checkOk(http.Response res, {List<int> okCodes = const [200]}) {
    if (okCodes.contains(res.statusCode)) return;

    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      } else if (body is Map && body['errors'] != null) {
        final errors = body['errors'] as Map;
        message = errors.values.expand((v) => (v as List)).join(' ');
      }
    } catch (_) {
      // Response body wasn't JSON — keep the default message.
    }
    throw ApiException(message);
  }
}
