import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prediction_model.dart';

class ApiService {
  static const String baseUrl = 'https://g721qslc-8000.inc1.devtunnels.ms/api';
  static const Duration _requestTimeout = Duration(seconds: 25);

  Future<List<String>> getCryptos() async {
    final response = await http
        .get(Uri.parse('$baseUrl/cryptos'))
        .timeout(_requestTimeout);
    final data = _decodeResponse(response);
    final cryptos = data['cryptos'] as List<dynamic>? ?? [];
    return cryptos.map((item) => item.toString()).toList();
  }

  Future<List<HistoryItem>> getHistory() async {
    final response = await http
        .get(Uri.parse('$baseUrl/history'))
        .timeout(_requestTimeout);
    final data = _decodeResponse(response);
    final history = data['history'] as List<dynamic>? ?? [];
    return history
        .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PredictResult> getPrediction({
    required String crypto,
    required String targetDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'crypto': crypto, 'target_date': targetDate}),
        )
        .timeout(_requestTimeout);
    final data = _decodeResponse(response);
    return PredictResult.fromJson(data);
  }

  Future<PredictionDetail> getPredictionDetail(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/history/$id'))
        .timeout(_requestTimeout);
    final data = _decodeResponse(response);
    return PredictionDetail.fromJson(data);
  }

  Future<List<ErrorLogItem>> getErrors() async {
    final response = await http
        .get(Uri.parse('$baseUrl/errors'))
        .timeout(_requestTimeout);
    final data = _decodeResponse(response);
    final errors = data['errors'] as List<dynamic>? ?? [];
    return errors
        .map((item) => ErrorLogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Map<String, dynamic> data = _safeJsonMap(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final detail = data['detail'];
    final message = data['message'] ?? detail ?? 'Request failed';
    throw Exception(message.toString());
  }

  Map<String, dynamic> _safeJsonMap(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } on FormatException {
      throw const SocketException('Invalid response received from server.');
    }
  }
}
