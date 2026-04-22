import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:testtask/features/kanban/domain/models/kanban_task.dart';

class KpiDriveApi {
  static const _token = '5c3964b8e3ee4755f2cc0febb851e2f8';
  static const _authUserId = '40';
  static const _getUrl =
      'https://api.dev.kpi-drive.ru/_api/indicators/get_mo_indicators';
  static const _saveUrl =
      'https://api.dev.kpi-drive.ru/_api/indicators/save_indicator_instance_field';
  static const _webProxyBaseUrl = String.fromEnvironment(
    'WEB_PROXY_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  Map<String, String> get _headers => {'Authorization': 'Bearer $_token'};

  Future<List<KanbanTask>> fetchTasks() async {
    final requestUrl = kIsWeb ? '$_webProxyBaseUrl/api/get_mo_indicators' : _getUrl;
    final request = http.MultipartRequest('POST', Uri.parse(requestUrl));
    request.headers.addAll(_headers);
    request.fields.addAll({
      'period_start': '2026-04-01',
      'period_end': '2026-04-30',
      'period_key': 'month',
      'requested_mo_id': '42',
      'behaviour_key': 'task,kpi_task',
      'with_result': 'false',
      'response_fields': 'name,indicator_to_mo_id,parent_id,order',
      'auth_user_id': _authUserId,
    });

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('HTTP ${streamed.statusCode}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Неожиданный формат ответа сервера');
    }

    final status = '${decoded['STATUS'] ?? ''}'.toLowerCase();
    if (status != 'ok') {
      throw Exception(decoded['MESSAGE']?.toString() ?? 'Сервер вернул ошибку');
    }

    final data = decoded['DATA'];
    final rows = switch (data) {
      Map<String, dynamic>() => data['rows'],
      List() => data,
      _ => null,
    };

    if (rows is! List) {
      throw Exception('Неожиданный формат ответа сервера');
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(KanbanTask.fromJson)
        .where((task) => task.name.isNotEmpty)
        .toList();
  }

  Future<void> saveTaskField({
    required int indicatorToMoId,
    required String fieldName,
    required String fieldValue,
  }) async {
    final requestUrl =
        kIsWeb ? '$_webProxyBaseUrl/api/save_indicator_instance_field' : _saveUrl;
    final request = http.MultipartRequest('POST', Uri.parse(requestUrl));
    request.headers.addAll(_headers);
    request.fields.addAll({
      'period_start': '2026-04-01',
      'period_end': '2026-04-30',
      'period_key': 'month',
      'indicator_to_mo_id': '$indicatorToMoId',
      'field_name': fieldName,
      'field_value': fieldValue,
      'auth_user_id': _authUserId,
    });

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('HTTP ${streamed.statusCode}');
    }

    final decoded = jsonDecode(body);
    final status = decoded is Map<String, dynamic> ? '${decoded['STATUS']}' : '';
    if (status.toLowerCase() != 'ok') {
      throw Exception(
        decoded is Map<String, dynamic>
            ? (decoded['MESSAGE']?.toString() ?? 'Сервер вернул ошибку')
            : 'Сервер вернул ошибку',
      );
    }
  }
}
